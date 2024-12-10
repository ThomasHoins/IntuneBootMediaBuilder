<#
.SYNOPSIS
Creates a bootable USB media or ISO file using the Windows ADK Preinstallation Environment (PE).

.DESCRIPTION
This script creates a bootable Windows PE image by downloading, installing, and configuring the Windows ADK. It integrates drivers and components and adds a custom startup script that runs when the PE boots. The final image can be saved as an ISO file or written directly to a USB stick. It is designed specifically for Intune Autopilot deployments.

.PARAMETER PEPath
Specifies the path where the PE files will be cached.

.PARAMETER IsoPath
Specifies the target path for the ISO file. If no path is provided, the ISO will be saved in the working directory.

.PARAMETER TempFolder
Specifies the path to the temporary folder. Default is `C:\Temp`.

.PARAMETER OutputFolder
Specifies the target folder where the final image will be saved.

.PARAMETER StartScriptSource
Specifies the URL of the startup script to be downloaded and executed by the PE.

.PARAMETER DriverFolder
Specifies the source folder for drivers to be injected into the PE image.

.PARAMETER ADKPath
Specifies the installation path of the Windows ADK. If the ADK is not installed, it will be downloaded and installed automatically.

.PARAMETER ADKVersion
Specifies the version of the Windows ADK to be installed. The default is `10.1.22621.1`. This version should match the version of the installed operating system.

.INPUTS
This script does not accept piped inputs.

.OUTPUTS
The script creates either a bootable USB media or an ISO file.

.EXAMPLE
PS> .\IntuneBootMediaBuilder.ps1 -PEPath "C:\WinPE" -IsoPath "C:\Images\Boot.iso" -DriverFolder "C:\Drivers"

Creates an ISO file with the integrated PE image and drivers.

.EXAMPLE
PS> .\IntuneBootMediaBuilder.ps1 -TempFolder "D:\Temp" -OutputFolder "D:\Output" -StartScriptSource "https://example.com/Start.ps1"

Uses custom temp and output folders and downloads a custom startup script.

.EXAMPLE
PS> .\IntuneBootMediaBuilder.ps1 -PEPath "C:\WinPE" -DriverFolder "C:\Drivers" -ADKVersion "10.1.22000.1"

Creates a PE image using a specified ADK version.

.LINK
[IntuneInstall](https://github.com/ThomasHoins/IntuneInstall)

.NOTES
- The script requires administrative privileges.
- A USB stick with at least 8 GB of storage is required.
- The ADK version should match the installed Windows version.

	Version: 0.1
	Author: Thomas Hoins (Datagroup OIT)
 	Creation Date:
	Last Change: 10.12.2024
 	Change: Minor changes
#>

Param (
	[string]$PEPath,
	[string]$IsoPath,
	[string]$TempFolder="C:\Temp",
	[string]$OutputFolder,
	[string]$StartScriptSource="https://raw.githubusercontent.com/ThomasHoins/IntuneInstall/refs/heads/main/Start.ps1",
	[string]$DriverFolder="C:\Temp\Drivers",
	[string]$ADKPath="C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit",
	[string]$ADKVersion="10.1.22621.1"
	)	

$userPrincipal = (New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent()))
if (!($userPrincipal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator))){
	Write-Host "Admin permissions required!"
	Exit
	}

	if ((get-disk | Where-Object bustype -eq 'usb'|Get-Partition).Size -lt 7516192768){
	Write-Host "This USB stick is too small!"
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

#Get FIDO and download Windows 11 installation ISO
Invoke-Webrequest "https://raw.githubusercontent.com/pbatard/Fido/refs/heads/master/Fido.ps1" -Outfile "$WorkPath\Fido.ps1"
$W11URL=& $WorkPath\Fido.ps1" -geturl

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
    Add-WindowsPackage -Path $MountPath -PackagePath $Path -IgnoreCheck
} 
Get-WindowsPackage -Path $MountPath |Format-Table -AutoSize

# Add new Start Script
Remove-Item "$MountPath\Windows\System32\startnet.cmd" -Force -ErrorAction SilentlyContinue
$startnetText = @"
@ ECHO OFF
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
		"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe"
		# Check if $IsoPath ends with ".iso"
		if ($IsoPath -notmatch "\.iso$") {
			Write-Host "ERROR: destination needs to be an .ISO file." -ForegroundColor Red
			Clear-Path
			exit 1
		}

		# Check if the IsoPathination file exists
		if (-Not (Test-Path $IsoPath)) {
			$BOOTDATA = "2#p0,e,b`"$PEPath\fwfiles\etfsboot.com`"#pEF,e,b`"$PEPath\fwfiles\efisys.bin`""
		}

		try {
			Remove-Item -Path $IsoPath -Force -ErrorAction Stop
			Write-Host "Deleted existing ISO file: $IsoPath"
		} catch {
			Write-Host "ERROR: Failed to delete $IsoPath." -ForegroundColor Red
			Clear-Path
			exit 1
		}

		$BOOTDATA = "2#p0,e,b`"$PEPath\fwfiles\etfsboot.com`"#pEF,e,b`"$PEPath\fwfiles\efisys.bin`""

		# Create the ISO file using the appropriate OSCDImg command
		Write-Host "Creating $IsoPath..."
		$oscdimgCmd = "`"$ADKPath\Deployment Tools\amd64\Oscdimg\oscdimg.exe`" -bootdata:$BOOTDATA -u1 -udfver102 `"$PEPath\media`" `"$IsoPath`""
		$OSCDResult=Invoke-Expression $oscdimgCmd -PassThru

		# Check the result of the command
		if ($OSCDResult -ne 0) {
			Write-Host "ERROR: Failed to create $IsoPath file." -ForegroundColor Red
			Clear-Path
			exit 1
		}

     }
    U {
    	$usbDrive = (get-disk | Where-Object bustype -eq 'usb')
        $usbDriveNumber = $usbDrive.Number
        # Format the USB drive
        Clear-Disk -Number $usbDriveNumber -RemoveData     
		New-Partition -DiskNumber $usbDriveNumber -Size 2048MB -IsActive -DriveLetter P | Format-Volume -FileSystem FAT32 -NewFileSystemLabel "WinPE" 
		New-Partition -DiskNumber $usbDriveNumber -UseMaximumSize        -DriveLetter I | Format-Volume -FileSystem NTFS -NewFileSystemLabel "Images" 
		bootsect.exe /nt60 P: /force /mbr 
        Copy-Item -Path "$PEPath\media\*" -IsoPathination "P:" -Recurse
      }
    C {
		Clear-Path
		exit 0
	  }
}
function Clear-Path{
	# Clean Up
	Write-Host "Cleaning Up files"
	Remove-Item $PEPath -Recurse -Force -ErrorAction SilentlyContinue
	Remove-Item $MountPath -Recurse -Force -ErrorAction SilentlyContinue
}
