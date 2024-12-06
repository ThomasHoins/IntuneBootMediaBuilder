Param (
	[string]$PEPath = "",
	[string]$IsoPath = "",
	[string]$TempFolder = "C:\Temp",
	[string]$OutputFolder = "",
	[string]$StartScriptSource = "https://raw.githubusercontent.com/ThomasHoins/IntuneInstall/refs/heads/main/Start.ps1",
	[string]$DriverFolder = "C:\Temp\Drivers",
	[string]$ADKPath= "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit",
	[string]$ADKVersion = "10.1.22621.1"
	)

<#
        .SYNOPSIS
        Creates an USB Boot Media or ISO File from the Default Windows ADK PE
        #https://learn.microsoft.com/de-de/powershell/scripting/developer/help/examples-of-comment-based-help?view=powershell-7.4

        .DESCRIPTION
        Downloads and installs the Windows ADK for PE Creates a Boot Image and injects drivers and Components. 
        The Startnet.cmd will be modified to download and run a Start.ps1 Script from the web. To install a Windows OS and join via Autopilot to Intune.
        A USB flash drive with minimum 8 GB and max 32 GB is required. 

        .PARAMETER PEPath
        Specifies the path where the PE wil be cached.

        .PARAMETER IsoPath
        Specifies the path, where the ISO file will be stored at the end. If no path is supplied, the ISO will be saved in the workdir. 

        .PARAMETER TempFolder
        Specifies the path to the Temp folder. Default = C:\Temp

        .PARAMETER OutputFolder
        Specifies the Output folder

        .PARAMETER StartScriptSource
        Specifies the internet path to the Start script. 

        .PARAMETER DriverFolder
        Specifies source folder for the drivers that shall be injected

        .PARAMETER ADKPath
        Specifies the Path to the ADK environment. If not installed it will be downloaded.
        
        .PARAMETER ADKVersion
        Specifies the ADK Version to be installed. Default is 10.1.22621.1 the version should match the version of the installed OS. 

        .INPUTS
        None. You can't pipe objects to Install.ps1

        .OUTPUTS
        Creates an USB installation media or an ISO file.

        .EXAMPLE
        PS> Add-Extension -name "File"
        File.txt

        .EXAMPLE
        PS> Add-Extension -name "File" -extension "doc"
        File.doc

        .EXAMPLE
        PS> Add-Extension "File" "doc"
        File.doc

        .LINK
        Online version: http://www.fabrikam.com/add-extension.html

        .LINK
        Set-Item
    #>
	


$userPrincipal = (New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent()))
if (!($userPrincipal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator))){
	Write-Host "Admin permissions required!"
	Exit
	}

If (!(Test-Path -Path "$ADKPath\Deployment Tools\DandISetEnv.bat")) {
	winget install Microsoft.WindowsADK --version $ADKVersion
	winget install Microsoft.ADKPEAddon --version $ADKVersion
	}


#create Path environment
If (!(Test-Path -Path $TempFolder)) {
	New-Item -ItemType Directory -Path $TempFolder
	}
$random = (Get-Random -Maximum 1000 ).ToString('0000')
$date =(get-date -format yyyyMMddmmss).ToString()
$TempPath = "$date-$random"
$WorkPath = "$TempFolder\$TempPath"
New-Item -ItemType Directory -Path $WorkPath

$PEPath = "$WorkPath\WinPE_admd64"
$MountPath = "$WorkPath\mount\WinPE_admd64"

# prepare PE data
$env:DandIRoot="$ADKPath\Deployment Tools"
$env:WinPERoot="$ADKPath\Windows Preinstallation Environment"
$env:WinPERootNoArch="$ADKPath\Windows Preinstallation Environment"
$env:OSCDImgRoot="$env:DandIRoot\$($env:PROCESSOR_ARCHITECTURE)\Oscdimg"
Remove-Item $PEPath -Recurse -Force -ErrorAction SilentlyContinue
Start-Process -FilePath "$ADKPath\Windows Preinstallation Environment\copype.cmd" -ArgumentList amd64,$PEPath -NoNewWindow -Wait -PassThru

# prepare directory f. PE
Remove-Item $MountPath -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $MountPath

# mount Boot Image
Mount-WindowsImage -ImagePath "$PEPath\media\sources\boot.wim" -Index:1 -Path $MountPath

# Inject Drivers
Add-WindowsDriver -Path $MountPath -Driver $DriverFolder -Recurse

# Add Components
$Components= @("*WinPE-WMI*","*WinPE-NetFX*","*WinPE-Scripting*","*WinPE-PowerShell*","*WinPE-StorageWM*","*WinPE-DismCmdlet*","*WinPE-Dot3Svc*")
$ComponetsPaths = (Get-ChildItem -Path "$ADKPath\Windows Preinstallation Environment\amd64\WinPE_OCs\*" -include $Components).FullName
$ComponetsPathsEn = (Get-ChildItem -Path "$ADKPath\Windows Preinstallation Environment\amd64\WinPE_OCs\en-us\*" -include $Components).FullName

ForEach ($Path in $ComponetsPaths+$ComponetsPathsEn){
    Add-WindowsPackage -Path $MountPath -PackagePath $Path
} 
Get-WindowsPackage -Path $MountPath |ft -AutoSize

# Add new Start Script
Remove-Item "$MountPath\Windows\System32\startnet.cmd" -Force -ErrorAction SilentlyContinue
$startnetText = @"
wpeinit
ping 127.0.0.1 -n 20 >NUL
"X:\Windows\system32\WindowsPowerShell\v1.0\powershell.exe" invoke-webrequest "$StartScriptSource" -Outfile X:\Users\Public\Downloads\Start.ps1
"X:\Windows\system32\WindowsPowerShell\v1.0\powershell.exe" -Executionpolicy Bypass "X:\Users\Public\Downloads\Start.ps1"
"@
Add-Content -Path "$MountPath\Windows\System32\startnet.cmd" -Value $startnetText

# Unmount Image
Dismount-WindowsImage -Path $MountPath -Save
Get-WindowsImage -Mounted | Dismount-WindowsImage -Discard -ErrorAction SilentlyContinue


#Create Media
$Selection = Read-Host "Create an ISO image or a USB Stick or Cancel? [I,U,C]"


Switch ($Selection){
    I {
       Start-Process -FilePath "$ADKPath\Windows Preinstallation Environment\MakeWinPEMedia.cmd" /iso $PEPath "$WorkPath\Install.iso" -Wait
     }
    U {
    	$usbDrive = (get-disk | where bustype -eq 'usb')
        $usbDriveNumber = $usbDrive.Number
        $usbDriveName = $usbDrive.FriendlyName
        # Format the USB drive
        Clear-Disk -Number $usbDriveNumber -RemoveData 
        New-Partition -DiskNumber $usbDriveNumber -UseMaximumSize -IsActive -DriveLetter P | Format-Volume -FileSystem FAT32 -NewFileSystemLabel "WinPE" 
        bootsect.exe /nt60 P: /force /mbr 
        Copy-Item -Path "$PEPath\media" -Destination "P:" -Recurse -PassThru 
      }
    C {Exit}
}
# Clean Up
Remove-Item $PEPath -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item $MountPath -Recurse -Force -ErrorAction SilentlyContinue
