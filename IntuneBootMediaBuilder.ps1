

<#
.SYNOPSIS
	Creates a bootable USB media or ISO file using the Windows ADK Preinstallation Environment (PE).

.DESCRIPTION
	This script creates a bootable Windows PE image by downloading, installing, and configuring the Windows ADK. 
	It integrates drivers and components and adds a custom startup script that runs when the PE boots. 
	The final image can be saved as an ISO file or written directly to a USB stick. It is designed specifically for Intune Autopilot deployments.
	You can create a "binschonda.txt" file in one of your Working Directories (The ones with DATE-RND name)

	- The script requires administrative privileges.
	- A USB stick with at least 8 GB of storage is required.
	- The ADK version should match the installed Windows version.

.NOTES

	Version:		0.1
	Author: 		Thomas Hoins 
					Datagroup OIT
 	initial Date:	10.12.2024
 	Changes: 		12.12. 2024	Minor changes

.LINK
	[IntuneInstall](https://github.com/ThomasHoins/IntuneInstall)

.COMPONENT
	Requires Modules Microsoft.Graph.Authentication

.PARAMETER PEPath
Specifies the path where the PE files will be cached.

.PARAMETER IsoPath
Specifies the target path for the ISO file. If no path is provided, the ISO will be saved in the working directory.

.PARAMETER DownloadISO
Specifies the the source, where the installation ISO will be donloaded. If not supplied, it will try to use the FIDO Tool to download one from Microsoft.

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

.PARAMETER TenantID
Speciefies the Tenant ID of your Entra ID.
This can be aquired at the Overview page of your Entra 

.PARAMETER ProfileID
Specifies the ProfileID that is requied to select the Autopilot Profile. Can be aqired with the following command after connecting to Graph. 
(Invoke-MGGraphRequest -Uri "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeploymentProfiles" -Method Get).Value

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

#>

#Requires -Modules Microsoft.Graph.Authentication

Param (
	[string]$PEPath,
	[string]$IsoPath,
	[string]$DownloadISO="https://software.download.prss.microsoft.com/dbazure/Win11_24H2_English_x64.iso?t=c72f70cf-7301-4521-b6e0-cddc763307ad&P1=1733998547&P2=601&P3=2&P4=OWu2bEtKuDNqmD1JeMY8Hm7STgcabVRJRBYg4TgYR1wsowNOTfZdgq5OviDXnzYdT6oDIcvtUxubquHq27LzTwXO37MB5wTIXVAcRY5KKvLM2zt58Eo8TNR1SCfw1j4zvxZc1vRTDtB%2bNVvfZK4QTCvFIHNwqwOOyw8YNJuzcIJZh14QQZGlxFtg70fzqtzJycIwgjQwvle3ZYMaC2remsn%2bWaH3mA4ZxQNcsf6RDE4imRTt3l3xojIp2T6sVln7v7Cra3NwnrpaOmEyBmGACDNR%2bpgcp7DYvymF4GElE1VjntIkmqKpBZC5mPULeTJJkoBTeN0Tjtmb2UlxmKKYZg%3d%3d",
	[string]$TempFolder="C:\Temp",
	[string]$OutputFolder,
	[string]$StartScriptSource="https://raw.githubusercontent.com/ThomasHoins/IntuneInstall/refs/heads/main/Start.ps1",
	[string]$DriverFolder="C:\Temp\Drivers",
	[string]$ADKPath="C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit",
	[string]$ADKVersion="10.1.22621.1",
	[string]$TenantID="22c3b957-8768-4139-8b5e-279747e3ecbf",
	[string]$ProfileID="41b669f0-86d4-4363-b666-5046469d0611"
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
	Write-Host "No ADK has been found, installing it!"
	winget install Microsoft.WindowsADK --version $ADKVersion
	winget install Microsoft.ADKPEAddon --version $ADKVersion
	}


#create Path environment create new workdir if "binschonda.txt" does not exist
If (!(Test-Path -Path $TempFolder)) {
	New-Item -ItemType Directory -Path $TempFolder
	}
$WorkPath = (Get-ChildItem -Path $TempFolder -Include binschonda.txt -File -Recurse -ErrorAction SilentlyContinue).DirectoryName
If (!(Test-Path -Path $WorkPath)) {
	$random = (Get-Random -Maximum 1000 ).ToString('0000')
	$date =(get-date -format yyyyMMddmmss).ToString()
	$TempPath = "$date-$random"
	$WorkPath = "$TempFolder\$TempPath"
	New-Item -ItemType Directory -Path $WorkPath
	}	

If (!([string]::IsNullOrEmpty($PEPath) )){
	$PEPath = "$WorkPath\WinPE_admd64"	
	}
If (!([string]::IsNullOrEmpty($IsoPath) )){
	$IsoPath = $WorkPath	
	}
$BootPath = "$WorkPath\mount\Boot"
$InstWimPath = "$WorkPath\mount\InstWim"

# prepare PE data
$env:DandIRoot="$ADKPath\Deployment Tools"
$env:WinPERoot="$ADKPath\Windows Preinstallation Environment"
$env:WinPERootNoArch="$ADKPath\Windows Preinstallation Environment"
$env:OSCDImgRoot="$env:DandIRoot\$($env:PROCESSOR_ARCHITECTURE)\Oscdimg"
Remove-Item $PEPath -Recurse -Force -ErrorAction SilentlyContinue
Start-Process -FilePath "$ADKPath\Windows Preinstallation Environment\copype.cmd" -ArgumentList amd64,$PEPath -NoNewWindow -Wait -PassThru

#Get FIDO and download Windows 11 installation ISO
If (!([string]::IsNullOrEmpty($DownloadISO) )){
	Invoke-Webrequest "https://raw.githubusercontent.com/pbatard/Fido/refs/heads/master/Fido.ps1" -Outfile "$WorkPath\Fido.ps1"
	$DownloadISO=& "$WorkPath\Fido.ps1" -geturl
	$UseFido=$true
	}
If (!(Test-Path -PathType Leaf "$WorkPath\Installation.iso")){
	Write-Host "Downloading installation ISO please be patient!"
	Start-BitsTransfer -Source $DownloadISO -Destination "$WorkPath\Installation.iso"
	}

If (Test-Path -PathType Leaf $WorkPath\Installation.iso){
	$InstDriveLetter = (Mount-DiskImage -ImagePath $WorkPath\Installation.iso | Get-Volume).DriveLetter
	}
Else{
	Write-Host "$WorkPath\Installation.iso  not found! Exiting"
	Clear-Path
	exit 1
	}

###########################################################
#	Prepareing Boot Image
###########################################################

Write-Host "Preparing Boot Image"

# prepare directory f. PE
Remove-Item $BootPath -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $BootPath

# mount Boot Image
If ($UseFido){
	$BootWimTemp = "$WorkPath\Boot.wim"
	copy-item "$($InstDriveLetter):\sources\boot.wim" $BootWimTemp
	Set-ItemProperty -Path $BootWimTemp -Name IsReadOnly -Value $false
	Mount-WindowsImage -ImagePath $BootWimTemp -Index:1 -Path $BootPath
	}
Else{
	Mount-WindowsImage -ImagePath "$PEPath\media\sources\boot.wim" -Index:1 -Path $BootPath
	}

# Inject Drivers to BootImage
Add-WindowsDriver -Path $BootPath -Driver $DriverFolder -Recurse

# Add Components to BootImage
$Components= @("*WinPE-WMI*","*WinPE-NetFX*","*WinPE-Scripting*","*WinPE-PowerShell*","*WinPE-StorageWM*","*WinPE-DismCmdlet*","*WinPE-Dot3Svc*")
$ComponetsPaths = (Get-ChildItem -Path "$ADKPath\Windows Preinstallation Environment\amd64\WinPE_OCs\*" -include $Components).FullName
$ComponetsPathsEn = (Get-ChildItem -Path "$ADKPath\Windows Preinstallation Environment\amd64\WinPE_OCs\en-us\*" -include $Components).FullName

ForEach ($Path in $ComponetsPaths+$ComponetsPathsEn){
    Add-WindowsPackage -Path $MountPath -PackagePath $Path -IgnoreCheck
	} 
Get-WindowsPackage -Path $BootPath |Format-Table -AutoSize

# Add new Start Script to BootImage
Remove-Item "$BootPath\Windows\System32\startnet.cmd" -Force -ErrorAction SilentlyContinue

$startnetText =@"
`@ ECHO OFF
wpeinit
powercfg /s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 
ping 127.0.0.1 -n 20 >NUL
"X:\Windows\system32\WindowsPowerShell\v1.0\powershell.exe" invoke-webrequest "$StartScriptSource" -Outfile X:\Users\Public\Downloads\Start.ps1
"X:\Windows\system32\WindowsPowerShell\v1.0\powershell.exe" -Executionpolicy Bypass X:\Users\Public\Downloads\Start.ps1
"@

Add-Content -Path "$BootPath\Windows\System32\startnet.cmd" -Value $startnetText

# Unmount Boot Image
Dismount-WindowsImage -Path $BootPath -Save
Get-WindowsImage -Mounted | Dismount-WindowsImage -Discard -ErrorAction SilentlyContinue

###########################################################
#	Prepareing Install Image
###########################################################

Write-Host "Preparing Install Image"

# prepare directory f. Install.wim
Remove-Item $InstWimPath -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $InstWimPath

# mount Install Image
$InstWimTemp = "$WorkPath\Install.wim"
copy-item "$($InstDriveLetter):\sources\Install.wim" $InstWimTemp
Set-ItemProperty -Path $InstWimTemp -Name IsReadOnly -Value $false
Mount-WindowsImage -ImagePath $InstWimTemp -Index:1 -Path $InstWimPath

# inject Intune Profile
Connect-MgGraph -TenantId $TenantID -NoWelcome
$ProfileJSON = Get-IntuneJson -id $ProfileID
$ProfileJSON | Set-Content -Encoding Ascii "$InstWimPath\Windows\Provisioning\Autopilot\AutopilotConfigurationFile.json"

# Unmount Install Image
Dismount-WindowsImage -Path $InstWimPath -Save
Get-WindowsImage -Mounted | Dismount-WindowsImage -Discard -ErrorAction SilentlyContinue
copy-item $InstWimTemp I:

###########################################################
#	Creating Boot Media
###########################################################

#Create Media
$Selection = Read-Host "Create an ISO image or a USB Stick or Cancel? [I,U,C]"


Switch ($Selection){
    I {
		# Check if the Destination file exists
		if ((Test-Path $IsoPath)) {
			New-Item -ItemType Directory -Path $IsoPath
		}
		
		$IsoFileName="$IsoPath\IntuneBootMedia.iso"
		# Create the ISO file using the appropriate OSCDImg command
		Write-Host "Creating $IsoFileName..."
		$oscdString = "2#p0,e,b`"$PEPath\fwfiles\etfsboot.com`"#pEF,e,b`"$PEPath\fwfiles\efisys.bin`""
		$oscdimgCmd = "`"$ADKPath\Deployment Tools\amd64\Oscdimg\oscdimg.exe`" -bootdata:$oscdString -u1 -udfver102 `"$PEPath\media`" `"$IsoFileName`""
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
        $AbortYN = Read-Host "All Data on $usbDrive.Model will be deleted ? [Y,N]"
        Switch ($AbortYN){
            Y{
            # Format the USB drive
            Get-Partition $usbDriveNumber | Remove-Partition
		    New-Partition $usbDriveNumber -Size 2048MB -IsActive -DriveLetter P | Format-Volume -FileSystem FAT32 -NewFileSystemLabel "WinPE" 
		    New-Partition $usbDriveNumber -UseMaximumSize        -DriveLetter I | Format-Volume -FileSystem NTFS -NewFileSystemLabel "Images" 
		    bootsect.exe /nt60 P: /force /mbr 
            # Copy BootData to P:
            Copy-Item -Path "$PEPath\media\*" -Destination "P:" -Recurse
            }
            N{
            Clear-Path
            exit 1
            }
		}

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
	Remove-Item $BootPath -Recurse -Force -ErrorAction SilentlyContinue
	
}
function Get-IntuneJson() {
	[cmdletbinding()]
	<#
	.SYNOPSIS
	Gets the Intune Profile and converts it to JSON
	
	.DESCRIPTION
	Input the Profile ID and get back the JSON to include to you installation
	
	.PARAMETER id
	Specifies the Profile ID to use for the installation

	.EXAMPLE
	Get-IntuneJson -id $ID

	.Notes
	Extracted  from here:
	https://github.com/andrew-s-taylor/public/blob/main/Powershell%20Scripts/Intune/create-windows-iso-with-apjson.ps1
	
	-#>
	param
	(
	[string]$id
	
	)
	
	# Defining Variables
	$graphApiVersion = "beta"
	$Resource = "deviceManagement/windowsAutopilotDeploymentProfiles"
	$uri = "https://graph.microsoft.com/$graphApiVersion/$Resource/$id"
	$approfile = Invoke-MGGraphRequest -Uri $uri -Method Get -OutputType PSObject
	
	# Set the org-related info
	$script:TenantOrg = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/organization" -OutputType PSObject).value
	foreach ($domain in $script:TenantOrg.VerifiedDomains) {
		if ($domain.isDefault) {
			$script:TenantDomain = $domain.name
		}
	}
	$oobeSettings = $approfile.outOfBoxExperienceSettings
	
	# Build up properties
	$json = @{}
	$json.Add("Comment_File", "Profile $($approfile.displayName)")
	$json.Add("Version", 2049)
	$json.Add("ZtdCorrelationId", $approfile.id)
	if ($approfile."@odata.type" -eq "#microsoft.graph.activeDirectoryWindowsAutopilotDeploymentProfile") {
		$json.Add("CloudAssignedDomainJoinMethod", 1)
	}
	else {
		$json.Add("CloudAssignedDomainJoinMethod", 0)
	}
	if ($approfile.deviceNameTemplate) {
		$json.Add("CloudAssignedDeviceName", $approfile.deviceNameTemplate)
	}
	
	# Figure out config value
	$oobeConfig = 8 + 256
	if ($oobeSettings.userType -eq 'standard') {
		$oobeConfig += 2
	}
	if ($oobeSettings.hidePrivacySettings -eq $true) {
		$oobeConfig += 4
	}
	if ($oobeSettings.hideEULA -eq $true) {
		$oobeConfig += 16
	}
	if ($oobeSettings.skipKeyboardSelectionPage -eq $true) {
		$oobeConfig += 1024
		if ($_.language) {
			$json.Add("CloudAssignedLanguage", $_.language)
			# Use the same value for region so that screen is skipped too
			$json.Add("CloudAssignedRegion", $_.language)
		}
	}
	if ($oobeSettings.deviceUsageType -eq 'shared') {
		$oobeConfig += 32 + 64
	}
	$json.Add("CloudAssignedOobeConfig", $oobeConfig)
	
	# Set the forced enrollment setting
	if ($oobeSettings.hideEscapeLink -eq $true) {
		$json.Add("CloudAssignedForcedEnrollment", 1)
	}
	else {
		$json.Add("CloudAssignedForcedEnrollment", 0)
	}
	
	$json.Add("CloudAssignedTenantId", $script:TenantOrg.id)
	$json.Add("CloudAssignedTenantDomain", $script:TenantDomain)
	$embedded = @{}
	$embedded.Add("CloudAssignedTenantDomain", $script:TenantDomain)
	$embedded.Add("CloudAssignedTenantUpn", "")
	if ($oobeSettings.hideEscapeLink -eq $true) {
		$embedded.Add("ForcedEnrollment", 1)
	}
	else {
		$embedded.Add("ForcedEnrollment", 0)
	}
	$ztc = @{}
	$ztc.Add("ZeroTouchConfig", $embedded)
	$json.Add("CloudAssignedAadServerData", (ConvertTo-JSON $ztc -Compress))
	
	# Skip connectivity check
	if ($approfile.hybridAzureADJoinSkipConnectivityCheck -eq $true) {
		$json.Add("HybridJoinSkipDCConnectivityCheck", 1)
	}
	
	# Hard-code properties not represented in Intune
	$json.Add("CloudAssignedAutopilotUpdateDisabled", 1)
	$json.Add("CloudAssignedAutopilotUpdateTimeout", 1800000)
	
	# Return the JSON
	ConvertTo-JSON $json
	}
	