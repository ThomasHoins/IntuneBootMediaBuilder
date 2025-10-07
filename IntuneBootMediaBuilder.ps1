<#
.SYNOPSIS
	Creates a bootable USB media or ISO file using the Windows ADK Preinstallation Environment (PE).

.DESCRIPTION
	This script creates a Intune installation media by downloading original installation sources from Microsoft an injecting configuration files to 
    create a fully unattended Autopilot installation.
	It integrates drivers and components and adds a custom startup script that runs when the PE boots. 
	The final image can be saved as an ISO file or written directly to a USB stick. It is designed specifically for Intune Autopilot deployments.
	A "binschonda.txt" file will be created in your Working Directory (The ones with DATE-RND name). if you want multiple Environments, remove that file.
    At the moment Hyper-V VMs with Windwos 11 will not work if you have TPM enabled and did not enable the workarround for incompatibilitys in the autounattend.xml

	- The script requires administrative privileges.
	- A USB stick with at least 8 GB of storage is required.
	- The ADK version should match the installed Windows version.

.NOTES

	Version:		1.3.7
	Author: 		Thomas Hoins 
				Datagroup OIT
 	initial Date:		10.12.2024
 	Changes: 		07.01.2025 first fully functional version
	Changes: 		13.01.2025 Added the possibility to create a new App Registration if no TenantID is available
	Changes: 		31.01.2025 Changed the function to connect to Graph using Connect-Intune now
	Changes: 		04.02.2025 Bug Fixing with Modules and Scopes, removed some unneccesary lines from output
	Changes: 		04.02.2025 Bug Fixing, Tenant settings Missing in Settings.ps1 and Wi-Fi now selectable
	Changes: 		05.02.2025 Automatic Module Loading, Wi-Fi Profile Selection, Bug Fixing
	Changes: 		07.02.2025 Removed unneccesary permissions in App reg.
 				Original Permissions:
					"DeviceManagementConfiguration.ReadWrite.All",
					"DeviceManagementServiceConfig.ReadWrite.All",
					"Directory.ReadWrite.All",
					"Directory.Read.All",
					"Organization.Read.All",
					"User.Read.All"
	Changes: 		07.02.2025 added a scope check for the permissions	
	Changes: 		07.02.2025 addecd Autopilot Profile Selection if no ID is provided
	Changes: 		10.02.2025 Changed the files to json and added a input for the Group Tag
	Changes: 		20.02.2025 Minor changes in the script, added a check for the ADK installation
	Changes: 		21.02.2025 Changed the Settings file to a JSON file
	Changes: 		13.09.2025 More stable USB Disk creation, Group Tag selection, if permission is OK, New TenantDomain parmeter, to avoid "Organization.Read.All" right 
	Changes: 		26.09.2025 Changed the detection of the permissions
	Changes: 		26.09.2025 changed the format parameters for the USB creation
	Changes: 		26.09.2025 Changed the way to install the ADK
	Changes: 		26.09.2025 Added PE Driver Download for Dell and HP
	Changes: 		07.10.2025 Added Driver and Language selection for the ISO download
	Changes: 		07.10.2025 Added Lenovo Driver Download, changed the download for MS Surface Drivers


.LINK
	[IntuneInstall](https://github.com/ThomasHoins/IntuneInstall)

.COMPONENT
	Requires Modules Microsoft.Graph.Authentication, Microsoft.Graph.Applications

.PARAMETER PEPath
Specifies the path where the PE files will be cached.

.PARAMETER IsoPath
Specifies the target path for the ISO file. If no path is provided, the ISO will be saved in the working directory.

.PARAMETER WindowsVersion
Specifies the Windows Version, to extract from the install.wim.

.PARAMETER DownloadISO
Specifies the the source, where the installation ISO will be downloaded. If not supplied, it will try to use the FIDO Tool to download one from Microsoft.

.PARAMETER TempFolder
Specifies the path to the temporary folder. Default is `C:\Temp`.

.PARAMETER OutputFolder
Specifies the target folder where the final image will be saved.

.PARAMETER StartScriptSource
Specifies the URL of the startup script to be downloaded and executed by the PE.

.PARAMETER DriverFolder
Specifies the source folder for drivers to be injected into the PE image.

.PARAMETER AutounattendFile
Specifies the path to the autounattend.xml.
There is an excellent online generator for that file.
"https://schneegans.de/windows/unattend-generator/"

.PARAMETER ADKPath
Specifies the installation path of the Windows ADK. If the ADK is not installed, it will be downloaded and installed automatically.
The ADK will be used for the add ons and if an ISO file is created or if you select a custom install image with the `-DownloadISO` parameter.

.PARAMETER ADKVersion
Specifies the version of the Windows ADK to be installed. The default is `10.1.22621.1`. This version should match the version of the installed operating system.

.PARAMETER TenantID
Specifies the Tenant ID of your Entra ID.
This can be acquired at the Overview page of your Entra.

.PARAMETER ProfileID
Specifies the ProfileID that is required to select the Autopilot Profile. Can be acquired with the following command after connecting to Graph:
(Invoke-MGGraphRequest -Uri "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeploymentProfiles" -Method Get).Value

.PARAMETER InstallLanguage
Specifies the language for the installation. Default is "English".
Arabic, Brazilian Portuguese, Bulgarian, Chinese (Simplified), Chinese (Traditional), 
Croatian, Czech, Danish, Dutch, English, English International, Estonian, Finnish, 
French, French Canadian, German, Greek, Hebrew, Hungarian, Italian, Japanese, Korean, 
Latvian, Lithuanian, Norwegian, Polish, Portuguese, Romanian, Russian, Serbian Latin, 
Slovak, Slovenian, Spanish, Spanish (Mexico), Swedish, Thai, Turkish, Ukrainian	

.PARAMETER WindowsEdition
Specifies the Windows edition to download. Default is "Windows 11 Home/Pro/Edu".

.PARAMETER AutocreateWifiProfile
Specifies whether to automatically create a Wi-Fi profile. Default is $true.

.PARAMETER MultiParitionUSB
Specifies whether to create multiple partitions on the USB stick. Default is $false.

.PARAMETER AppId
Specifies the Application ID for authentication.

.PARAMETER AppSecret
Specifies the Application Secret for authentication.

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


Param (
	[string]$PEPath,
	[string]$IsoPath,
	[string]$DownloadISO, #="https://software.download.prss.microsoft.com/dbazure/Win11_24H2_English_x64.iso?t=23e54b6a-020f-4f2b-ae70-e1e52676ea1c&P1=1734172137&P2=601&P3=2&P4=QToZDn6aVi4krTph%2fkSVvhS9RPAacWYuSb54K3mwuNrDZ6Vkh%2bil6BjCeoqf9bvAXns96krwYEbFjFiqocRaYNiGewxgN0YWFUKIttmo%2fVNNRKoXBlnlIy0omYT1ljweXzYUU17cJXEq3vtVHKT45mxVqbgainFJEDr%2brpEjK32FsfBIPG9FTvrl8dESy%2bhZ1KFyw7N0FXCXt1CaLipsfvkV49fr4a0EYnnVsIzDPIB1Cxpv9rSeOVtYchsPpWufYuq88cGH0tuyJWrK5IrHvDGbjnwBuQtX9WQ7dYPwdIwU7WYoH4SYh3%2fGnDbMfnGQMY4j7ap0qpE%2bIT4cuMriBA%3d%3d",
	[string]$InstallLanguage = "English", #Brazil, Czech, Danish, Dutch, English, Estonian, Finnish, French, French Canadian, German, Greek, anHebrew, Hungarian, Italian, Japanese, Korean, Latvian, Lithuanian, Norwegian, Polish, Portuguese, Romanian, Russian, Serbian Latin, Slovak, Sloveni, Spanish, Swedish, Thai, Turkish, Ukrainian
	#[string]$Locale = "en-US", #en-US, de-DE, fr-FR, es-ES, it-IT, ja-JP, ko-KR, zh-CN, Override the default Locale
	[string]$WindowsEdition = "Windows 11 Home/Pro/Edu", #Download Edition	
	[string]$WindowsVersion = "Windows 11 Pro",	
	[string]$AutocreateWifiProfile = $true,
	[string]$TempFolder = "C:\Temp",
	[string]$OutputFolder,
	[bool]$MultiParitionUSB = $false,
	[string]$StartScriptSource = "https://raw.githubusercontent.com/ThomasHoins/IntuneInstall/refs/heads/main/Start.ps1",
	[string]$DriverVendors, #= "Dell,HP,Lenovo, Microsoft",
	[string]$DriverFolder = "C:\Temp\Drivers",
	[string]$AutounattendFile,
	[string]$ADKPath = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit",
	[string]$ADKVersion,	#  "10.1.22621.1"
	[string]$SecretFile = "$PSScriptRoot\appreg-intune-BootMediaBuilder-Script-ReadWrite-Prod.json",
	[string]$TenantID,
	[string]$TenantDomain,
	[string]$AppId,
	[string]$AppSecret,
	[string]$ApplicationPermissions = "DeviceManagementServiceConfig.ReadWrite.All", 
	[string]$ProfileID	
)	

###########################################################
#	Functions
###########################################################
function Clear-Path {
	# Clean Up
	Write-Host "Cleaning up files"
	Get-WindowsImage -Mounted | Dismount-WindowsImage -Discard -ErrorAction SilentlyContinue
	Disconnect-MgGraph -ErrorAction SilentlyContinue
	If ($PEPath) { Remove-Item $PEPath -Recurse -Force -ErrorAction SilentlyContinue}
	If ($BootPath) { Remove-Item $BootPath -Recurse -Force -ErrorAction SilentlyContinue}
	If ($InstMediaPath) { Remove-Item $InstMediaPath -Recurse -Force -ErrorAction SilentlyContinue}
	If ($InstWimTemp) { Remove-Item $InstWimTemp -Recurse -Force -ErrorAction SilentlyContinue}
}

function Get-IntuneJson() {
	[cmdletbinding()]
	<#
	.SYNOPSIS
	Gets the Intune Profile and converts it to JSON

	.Notes
	Extracted  from here:
	https://github.com/andrew-s-taylor/public/blob/main/Powershell%20Scripts/Intune/create-windows-iso-with-apjson.ps1
	
	-#>
	param
	(
		[string]$id
	)
	
	# get the Autopilot profile
	$graphApiVersion = "beta"
	If ([string]::IsNullOrEmpty($id)) {
		$uri = "https://graph.microsoft.com/$graphApiVersion/deviceManagement/windowsAutopilotDeploymentProfiles/"
		$approfiles = (Invoke-MGGraphRequest -Uri $uri -Method Get -OutputType PSObject).value
		Write-Host "Select the Autopilot Profile to use:"
		$i = 0
		ForEach($approfile in $approfiles) {
			Write-Host "[$i] $($approfile.displayName)"
			$i++
		}
		[int]$selection = Read-Host "Select Profile Number"
		$approfile = $approfiles[$selection]
		Write-Host "Selected $($approfile.displayName)"
	}
	Else {
		$uri = "https://graph.microsoft.com/$graphApiVersion/deviceManagement/windowsAutopilotDeploymentProfiles/$id"
		$approfile = (Invoke-MGGraphRequest -Uri $uri -Method Get -OutputType PSObject)
		Write-Host "Selected $($approfile.displayName)"
	}

	# Set the org-related info
	If (!$script:TenantDomain){
		$Context= Get-MgContext
		if ($context.Account) {$script:TenantDomain = $context.Account.Split("@")[1]}
		if (!$script:TenantDomain){
			$ApplicationPermissions += ", Organization.Read.All"
			$script:TenantOrg = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/organization" -OutputType PSObject).value
			foreach ($domain in $script:TenantOrg.VerifiedDomains) {
				if ($domain.isDefault) {
					$script:TenantDomain = $domain.name
				}
			}
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

function Connect-Intune{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$SecretFile = "$env:Temp\Settings.json",
		[Parameter(Mandatory = $false)]
        [string]$Scopes = "Application.ReadWrite.OwnedBy",
        [Parameter(Mandatory = $false)]
        [string]$AppName = "appreg-inune-BootMediaBuilder-Script-ReadWrite",
		[Parameter(Mandatory = $false)]
		[string[]]$ApplicationPermissions = "DeviceManagementServiceConfig.ReadWrite.All, Organization.Read.All",
		[Parameter(Mandatory = $false)]
		[string[]]$DelegationPermissions = ""

    )
    If (Test-Path -Path $SecretFile){
		Write-Host "Reading Settings file..." -ForegroundColor Yellow
		$SecretSettings = Get-Content -Path $SecretFile | ConvertFrom-Json
		$TenantID = $SecretSettings.TenantID
		$AppID = $SecretSettings.AppID
		$AppSecret = $SecretSettings.AppSecret
		Write-Host "Settings file read successfully." -ForegroundColor Green
		Write-Host "Using App Secret to connect to Tenant: $TenantID" -ForegroundColor Green
		$SecureClientSecret = ConvertTo-SecureString -String $AppSecret -AsPlainText -Force
		$ClientSecretCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $AppId, $SecureClientSecret
		$null = Connect-MgGraph -TenantId $TenantID -ClientSecretCredential $ClientSecretCredential -NoWelcome

    	#Test if Permissions are correct
		$actscopes = (Get-MgContext | Select-Object -ExpandProperty Scopes).Split(" ")
		$IncorrectScopes = ""
		$AppPerms = $ApplicationPermissions.Split(",").Trim()
		foreach ($AppPerm in $AppPerms) {
			if ($actscopes -notcontains $AppPerm) {
				$IncorrectScopes += $AppPerm -join ","
			}
		}
		if ($IncorrectScopes) {
			Write-Host "==========================================" -ForegroundColor Red
			Write-Host " The following permissions are missing:" -ForegroundColor Red
			Write-Host " $IncorrectScopes" -ForegroundColor Green
			Write-Host " Make sure to grant admin consent to your " -ForegroundColor Red
			Write-Host " API permissions in your newly created " -ForegroundColor Red
			Write-Host " App registration !!! " -ForegroundColor Red
			Write-Host "==========================================" -ForegroundColor Red
			Write-Host "https://entra.microsoft.com/#view/Microsoft_AAD_RegisteredApps/ApplicationsListBlade/quickStartType~/null/sourceType/Microsoft_AAD_IAM" -ForegroundColor Green
			Write-Host $Error[0].ErrorDetails
			Exit 1 
		}
		else{
			Write-Host "MS-Graph scopes: $($actscopes -join ", ") are correct" -ForegroundColor Green
		}

		$ErrorActionPreference = "Stop"
		try {
			$null = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceManagement"
		}
		catch {
			Write-Host "==========================================" -ForegroundColor Red
			Write-Host " Make sure to grant admin consent to your " -ForegroundColor Red
			Write-Host " API permissions in your newly created " -ForegroundColor Red
			Write-Host " App registration !!! " -ForegroundColor Red
			Write-Host "==========================================" -ForegroundColor Red
			Write-Host "https://entra.microsoft.com/#view/Microsoft_AAD_RegisteredApps/ApplicationsListBlade/quickStartType~/null/sourceType/Microsoft_AAD_IAM" -ForegroundColor Green
			Write-Host $Error[0].ErrorDetails
			Exit 1  
		}
	}
	Else{
		Write-Host "Settings file not found. Creating a new one..." -ForegroundColor Yellow

		Connect-MgGraph -Scopes $Scopes -NoWelcome

		$TenantData =Get-MgContext
		$TenantID = $TenantData.TenantId

		#Create a new Application
		$AppObj = Get-MgApplication -Filter "DisplayName eq '$AppName'"
		If ($AppObj){
			$AppID = $AppObj.AppId
			Write-Host "App already exists. Updating existing App." -ForegroundColor Yellow
		}
		Else{
			Write-Host "Creating a new Application..." -ForegroundColor Yellow 
			$AppObj = New-MgApplication -DisplayName $AppName
			$AppID = $AppObj.AppId
			If($AppID){
				Write-Host "App created successfully. App ID: $AppID" -ForegroundColor Green
			}
			Else{
				Write-Host "Failed to create the App. Please check the parameters and try again." -ForegroundColor Red
				Exit 1  
			}
		}
		# Define Application and Delegation Permission ids and type in a hash
		$permissions = [ordered]@{}
		If ($ApplicationPermissions){
			$ApplicationPermissions += ",DeviceManagementRBAC.Read.All" #add optional Permission to read the Group Tags
			$AppPermissions = $ApplicationPermissions.Split(",").Trim()
			$PermID = ""
			foreach($APermission in $AppPermissions){
				$PermID = (Find-MgGraphPermission $APermission -PermissionType Application -ExactMatch).Id
				$permissions.add($PermID,"Role")
			}
		}

		If ($DelegationPermissions){
			$DelPermissions = $DelegationPermissions.Split(",").Trim()
			$PermID = ""
			foreach($DPermission in $DelPermissions){
				$PermID = (Find-MgGraphPermission $DPermission -PermissionType Delegated -ExactMatch).Id
				$permissions.add($PermID,"Scope")
			}
		}

		# Build the accessBody for the hash
		$accessBody = [ordered]@{
			value = @(
				@{
					resourceAppId  = "00000003-0000-0000-c000-000000000000"
					resourceAccess = @()
				}
			)
		}

		# Add the  id/type pairs to the resourceAccess array
		foreach ($id in $permissions.Keys) {
			$accessBody.value[0].resourceAccess += @{
				id   = $id
				type = $permissions[$id]
			}
		}

		# Aplly upload the selected permissions via Graph API
		$fileUri = "https://graph.microsoft.com/v1.0/applications/$($AppObj.ID)/RequiredResourceAccess"
		try{
			$null = Invoke-MgGraphRequest -Method PATCH -Uri $fileUri -Body ($accessBody | ConvertTo-Json -Depth 4) 
		}
		catch{
			Write-Host "Failed to update the Required Resource Access. Status code: $($_.Exception.Message)" -ForegroundColor Red
			Exit 1
		}

		$passwordCred = @{
			"displayName" = "Secret-$($AppName)"
			"endDateTime" = (Get-Date).AddMonths(+12)
		}
		$ClientSecret = Add-MgApplicationPassword -ApplicationId  $AppObj.ID -PasswordCredential $passwordCred

		$AppSecret = $ClientSecret.SecretText
		If($AppSecret){
			Write-Host "App Secret ($AppSecret) created successfully." -ForegroundColor Green
		}
		Else{
			Write-Host "Failed to create the App Secret. Please check the parameters and try again." -ForegroundColor Red
			Exit 1
		}

		#Update Settings file with gathered information
		$SecretSettings = [ordered]@{
			Comment1 = "Make sure to keep this secret safe. This secret can be used to connect to your tenant!"
			Comment2 = "The following permissions are granted with this secret:"
			ApplicationPermissions = $ApplicationPermissions
			DelegationPermissions = $DelegationPermissions
			AppName = $AppObj.DisplayName
			CreatedBy = $TenantData.Account
			TenantID = $TenantID
			AppID = $AppID
			AppSecret = $AppSecret
		}
		Out-File -FilePath $SecretFile -InputObject ($SecretSettings | ConvertTo-Json)

		Write-Host ""
		Write-Host "==========================================================" -ForegroundColor Red
		Write-Host " A new App Registration ""$($AppObj.DisplayName)"" " -ForegroundColor Green
		Write-Host " has been created." -ForegroundColor Green
		Write-Host " Make sure to grant admin consent to your " -ForegroundColor Red
		Write-Host " API permissions in your newly created " -ForegroundColor Red
		Write-Host " App registration !!! " -ForegroundColor Red
		Write-Host  "==========================================================" -ForegroundColor Red
		Write-Host " Use this URL to grant consent:" -ForegroundColor Green
		Write-Host "https://entra.microsoft.com/#view/Microsoft_AAD_RegisteredApps/ApplicationsListBlade/quickStartType~/null/sourceType/Microsoft_AAD_IAM" -ForegroundColor Green
		Exit 0
	}
}

###########################################################
#	Main
###########################################################

###########################################################
#region	Preparations
###########################################################
$IsoLanguages = @("Arabic","Brazilian Portuguese","Bulgarian","Chinese (Simplified)","Chinese (Traditional)","Croatian","Czech","Danish","Dutch","English","English International","Estonian","Finnish","French","French Canadian","German","Greek","Hebrew","Hungarian","Italian","Japanese","Korean","Latvian","Lithuanian","Norwegian","Polish","Portuguese","Romanian","Russian","Serbian Latin","Slovak","Slovenian","Spanish","Spanish (Mexico)","Swedish","Thai","Turkish","Ukrainian","Vietnamese")
$DriverVendorsList = @("Dell","HP","Lenovo","Microsoft")

$startTime = Get-Date
$userPrincipal = (New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent()))
If (!($userPrincipal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator))) {
	Write-Host "Admin permissions required!"
	Exit
}

# Check if the required modules are installed
$modules =  'Microsoft.Graph.Authentication','Microsoft.Graph.Applications','Microsoft.Graph.DeviceManagement'
$installed = @((Get-Module $modules -ListAvailable).Name | Select-Object -Unique)
$notInstalled = Compare-Object $modules $installed -PassThru

# At least one module is missing. Install the missing modules now.
if ($notInstalled) { 
	Write-Host "Installing required modules..." -ForegroundColor Yellow
	Install-Module -Scope CurrentUser $notInstalled -Force -AllowClobber
}

Clear-Path

#create Path environment create new workdir if "binschonda.txt" does not exist
If (!(Test-Path -Path $TempFolder)) {
	$null = New-Item -ItemType Directory -Path $TempFolder
}
$WorkPath = (Get-ChildItem -Path $TempFolder -Include binschonda.txt -File -Recurse -ErrorAction SilentlyContinue).DirectoryName
If (([string]::IsNullOrEmpty($WorkPath))) {
	$random = (Get-Random -Maximum 1000 ).ToString('0000')
	$date = (get-date -format yyyyMMddmmss).ToString()
	$TempPath = "$date-$random"
	$WorkPath = "$TempFolder\$TempPath"
	$null = New-Item -ItemType Directory -Path $WorkPath
 	Write-Host "Created an new work folder $WorkPath"
}	

#Adding minimal Drivers from Repository
If (!(Test-Path -PathType Container $DriverFolder)) {
	$null = New-Item -ItemType Directory -Path $DriverFolder
}
#Select Driver Vendors to include
If (!$DriverVendors){
	Write-Host "Select a driver vendor to include:"
	$i = 0
	ForEach($Vendor in $DriverVendorsList) {
			Write-Host "[$i] $Vendor"
			$i++
	}
	do {
		[int]$selection = Read-Host "Select Profile Number (enter to finish)"
		$DriverVendors += "$Vendor[$selection],"
	} while ($selection -ne "")
	Write-Host "Selected $DriverVendors"
}

If ($DriverVendors) {
	$DriverVendors.Split(",") | ForEach-Object {
		$Vendor = $_.Trim()
		Write-Host "Adding Drivers from Vendor $Vendor"
		If (Test-Path -Path "$DriverFolder\$Vendor") {
			Switch ($Vendor) {
				"Dell" {
					$finalTarget  = "$DriverFolder\$Vendor"
					$extractTemp  = "$TempFolder\DellExtract"
					New-Item -Path $finalTarget -ItemType Directory -Force | Out-Null
					$origProgressPreference = $ProgressPreference
					$ProgressPreference = 'SilentlyContinue' #to spped up the download significant
					Invoke-Webrequest "https://raw.githubusercontent.com/ThomasHoins/IntuneBootMediaBuilder/refs/heads/main/DellDrivers.zip.001" -Outfile "$TempFolder\DellDrivers.zip.001"
					Invoke-Webrequest "https://raw.githubusercontent.com/ThomasHoins/IntuneBootMediaBuilder/refs/heads/main/DellDrivers.zip.002" -Outfile "$TempFolder\DellDrivers.zip.002"
					$ProgressPreference = $origProgressPreference
					$parts = Get-ChildItem $TempFolder -Filter "DellDrivers.zip*" | Sort-Object Name
					Get-Content $parts.FullName -Encoding Byte -ReadCount 0 | Set-Content "$TempFolder\DellDrivers.zip" -Encoding Byte
					Expand-Archive -LiteralPath "$TempFolder\DellDrivers.zip" -DestinationPath $extractTemp -Force
					#all filees up one level
					$child= (Get-ChildItem -Path $extractTemp -Directory | Select-Object -First 1).FullName
					Get-ChildItem $child -Directory | % { Copy-Item $_.FullName -Destination "$finalTarget\$($_.Name)" -Recurse }
					Remove-Item "$TempFolder\DellDrivers.zip.001" -Force -ErrorAction SilentlyContinue
					Remove-Item "$TempFolder\DellDrivers.zip.002" -Force -ErrorAction SilentlyContinue
					Remove-Item "$TempFolder\DellDrivers.zip" -Force -ErrorAction SilentlyContinue
					Remove-Item $extractTemp -Recurse -Force -ErrorAction SilentlyContinue
				}
				"HP" { 
					# Variables
					$extractTemp  = "$TempFolder\HPExtract"
					$finalTarget  = "$DriverFolder\$Vendor"

					# Prepare directories
					New-Item -Path $extractTemp -ItemType Directory -Force | Out-Null
					New-Item -Path $finalTarget -ItemType Directory -Force | Out-Null

					# Download the SoftPaq EXE
					$origProgressPreference = $ProgressPreference
					$ProgressPreference = 'SilentlyContinue' #to spped up the download significant
					Invoke-WebRequest -Uri "https://ftp.ext.hp.com/pub/softpaq/sp161501-162000/sp161830.exe" -OutFile "$TempFolder\sp161830.exe"
					$ProgressPreference = $origProgressPreference
					# Silent extraction to temporary folder
					Start-Process -FilePath $downloadFile -ArgumentList "/s /e /f $extractTemp" -Wait

					# Collect all driver files (INF, SYS, CAT, DLL, etc.)
					$driverFiles = Get-ChildItem -Path $extractTemp -Recurse -Include *.inf,*.sys,*.cat,*.dll

					foreach ($file in $driverFiles) {
						# Get the parent directory name (model name)
						$modelName = Split-Path $file.DirectoryName -Leaf

						# Build destination path with model name
						$destPath = Join-Path $finalTarget $modelName

						# Ensure destination folder exists
						if (-Not (Test-Path $destPath)) {
							New-Item -Path $destPath -ItemType Directory -Force | Out-Null
						}

						# Copy the driver file into the model folder
						Copy-Item $file.FullName -Destination $destPath -Force
				}

				Write-Host "Drivers have been extracted and copied into model folders under $finalTarget"
				Remove-Item "$TempFolder\sp161830.exe" -Force -ErrorAction SilentlyContinue
				Remove-Item $extractTemp -Recurse -Force -ErrorAction SilentlyContinue
				}
				"Lenovo" {
					$CatalogUrl  = "https://download.lenovo.com/cdrt/td/catalogv2.xml"
					$DownloadDir = "$DriverFolder\$Vendor"
					$extractTemp  = "$TempFolder\HPExtract"

					$ProgressPreferenceDefault = $ProgressPreference
					$ProgressPreference = 'SilentlyContinue'

					if (-not (Test-Path $DownloadDir)) {
						New-Item -Path $DownloadDir -ItemType Directory | Out-Null
					}

					Write-Host "Downloading Lenovo driver catalog..."

					try {
						# Download as byte array (raw binary)
						$bytes = Invoke-WebRequest -Uri $CatalogUrl -UseBasicParsing -TimeoutSec 60
						$raw = $bytes.Content

						# Convert bytes → string (UTF8)
						$rawText = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::UTF8.GetBytes($raw))

						# Remove possible UTF-8 BOM (ï»¿) or stray invisible chars
						$cleanXml = $rawText -replace "^\xEF\xBB\xBF", "" -replace "^\uFEFF", "" -replace "ï»¿", ""

						# Parse into XML
						[xml]$xml = $cleanXml
					}
					catch {
						Write-Error "Failed to download or parse catalog: $_"
						return
					}

					Write-Host "Parsing catalog..."

					$products = @()

					foreach ($model in $xml.ModelList.Model) {
						$name = $model.name
						$types = $model.Types.Type
						
						foreach ($pack in $model.SCCM) {
							$os = $pack.os
							If ($os -eq "Win11"){
							$driverUrl = $pack.'#text'
						
								$products += [PSCustomObject]@{
									Name  = $name
									Types = $types
									OS    = $os
									DriverURL   = $driverUrl
									FileName = ($driverUrl -split '/' | Select-Object -Last 1)
								}
							}
						}
					}


					if ($products.Count -eq 0) {
						Write-Warning "No laptop models found in catalog."
						exit
					}

					try {
						$choice = $products | Sort-Object Name | Out-GridView -Title "Select Lenovo Laptop Model" -PassThru
					}
					catch {
						Write-Host "Out-GridView not available, showing first 10..."
						$choice = $products | Sort-Object Name | Select-Object -First 10
						$choice | Format-Table -AutoSize
						exit
					}

					if (-not $choice) {
						Write-Host "No model selected. Exiting."
						exit
					}

					$destFile = "$extractTemp\$($choice.FileName)"
					$extractPath = Join-Path $DownloadDir ($choice.Name -replace '[^a-zA-Z0-9]', '_')
					try{
						Write-Host "Downloading driver pack for $($choice.Name)..."
						Invoke-WebRequest -Uri $choice.DriverURL -OutFile $destFile -UseBasicParsing

						Write-Host "Extracting to $extractPath ..."
						Start-Process -FilePath $destFile -ArgumentList "/VERYSILENT /DIR=$($extractPath)" -Wait
						Remove-Item $destFile -Force -ErrorAction SilentlyContinue
						Write-Host "Done. Drivers extracted to: $extractPath"
						}
					catch {
						Write-Error "Failed to download driver pack: $($choice.Name) - $_"
					}
				$ProgressPreference = $ProgressPreferenceDefault
				}
				"Microsoft" { 
					Write-Host "Downloading Minimal Surface driver pack."
					$ProgressPreferenceDefault = $ProgressPreference
					$ProgressPreference = 'SilentlyContinue' #to speed up the download significant
					Invoke-Webrequest "https://raw.githubusercontent.com/ThomasHoins/IntuneBootMediaBuilder/refs/heads/main/Drivers.zip" -Outfile "$TempFolder\Drivers.zip"
					$ProgressPreference = $ProgressPreferenceDefault
					Expand-Archive -LiteralPath "$TempFolder\Drivers.zip" -DestinationPath $TempFolder
					Remove-Item "$TempFolder\Drivers.zip" -Force -ErrorAction SilentlyContinue
				}
			}
		}

	}
}
Else {
	Copy-Item -Path "$TempFolder\Drivers\*" -Destination $DriverFolder -Recurse -Force
}

If (([string]::IsNullOrEmpty($PEPath) )) {
	$PEPath = "$WorkPath\WinPE_admd64"	
}
If (([string]::IsNullOrEmpty($IsoPath) )) {
	$IsoPath = $WorkPath	
}
$BootPath = "$WorkPath\mount\Boot"
$InstWimPath = "$WorkPath\mount\InstWim"
$PackageTemp = "$WorkPath\mount\PackageTemp"

# prepare PE data
If (!([string]::IsNullOrEmpty($DownloadISO)) -or ($MediaSelection -eq "I")) {
	$env:DandIRoot = "$ADKPath\Deployment Tools"
	$env:WinPERoot = "$ADKPath\Windows Preinstallation Environment"
	$env:WinPERootNoArch = "$ADKPath\Windows Preinstallation Environment"
	$env:OSCDImgRoot = "$env:DandIRoot\$($env:PROCESSOR_ARCHITECTURE)\Oscdimg"
	Remove-Item $PEPath -Recurse -Force -ErrorAction SilentlyContinue
	$null=Start-Process -FilePath "$ADKPath\Windows Preinstallation Environment\copype.cmd" -ArgumentList amd64, $PEPath -NoNewWindow -Wait -PassThru
	Copy-Item "$ADKPath\Deployment Tools\amd64\Oscdimg\efisys_noprompt.bin" "$PEPath\fwfiles\efisys.bin" -Force
	Remove-Item "$PEPath\media\Boot\bootfix.bin" -Force 
}

# Connect to Graph
Connect-Intune -SecretFile $SecretFile -Scopes "Application.ReadWrite.All" -ApplicationPermissions $ApplicationPermissions

$ProfileJSON = Get-IntuneJson -id $ProfileID
$ProfileJSON | Set-Content -Encoding Ascii "$WorkPath\AutopilotConfigurationFile.json"

#Ask for media type to build
do {
	$MediaSelection = Read-Host "Create an ISO image or a USB Stick or Cancel? [I,U]"
} while ($MediaSelection -notin @('I', 'U'))

$usbDrive = Get-Disk | Where-Object BusType -eq 'USB' | Select-Object -First 1
If ($usbDrive.Size -lt 7516192768 -and $MediaSelection -eq "U") {
	Write-Host "This USB stick is too small!"
	Exit
} 

# Downloading ADK as we will need it for the components and oscdimg
If (!(Test-Path -Path "$ADKPath\Windows Preinstallation Environment\copype.cmd")) {
	Write-Host "No ADK has been found, installing it!"

	If ($ADKVersion){
		Write-Host "Automatic download of a specific ADK version is not supported yet."
		Write-Host "Please install the ADK manually and try again."
  	} 
	Else{
		# Download-URLs for ADK and WinPE Add-On
		$adkUrl = "https://go.microsoft.com/fwlink/?linkid=2243390"
		$winPEUrl = "https://go.microsoft.com/fwlink/?linkid=2243391"

		# Destination folder for the installation files
		$downloadFolder = "$env:TEMP\ADK_Install"
		New-Item -ItemType Directory -Force -Path $downloadFolder

		# Download of the installation files
		Write-Host "Downloading ADK Setup..."
		Invoke-WebRequest -Uri $adkUrl -OutFile "$downloadFolder\adksetup.exe"
		Write-Host "Downloading WinPE Add-On Setup..."
		Invoke-WebRequest -Uri $winPEUrl -OutFile "$downloadFolder\winpesetup.exe"

		# Installation durchführen
		try {
			Start-Process -FilePath "$downloadFolder\adksetup.exe" -ArgumentList "/quiet /features OptionId.DeploymentTools" -Wait -PassThru
			Start-Process -FilePath "$downloadFolder\winpesetup.exe" -ArgumentList "/quiet" -Wait -PassThru
			Write-Host "Installation abgeschlossen!"
		} catch {
			Write-Host "Fehler bei der Installation: $($_.Exception.Message)" -ForegroundColor Red
			Write-Host "Please install the ADK manually and try again."
			Exit 1
		}

  	} 
}

#Set a Group Tag for the Device
try {
	$graphApiVersion = "beta"
	$uri = "https://graph.microsoft.com/$graphApiVersion/deviceManagement/roleScopeTags"
	$grouptags = (Invoke-MGGraphRequest -Uri $uri -Method Get -OutputType PSObject).value
	Write-Host "Select the Autopilot Profile to use:"
	$i = 0
	ForEach($GroupTag in $grouptags) {
		Write-Host "[$i] $($grouptag.displayName)"
		$i++
	}
	[int]$selection = Read-Host "Select Profile Number"
	$GroupTag = $grouptags[$selection]
	Write-Host "Selected $($grouptag.displayName)"
}
catch {
	$GroupTag = Read-Host "Enter a Group Tag for the Device (Default: "Default")" 
	If([string]::IsNullOrEmpty($GroupTag)){
		$GroupTag = "Default"
	}
}

# Create Wifi Profile (User can select a Profile)
If ($AutocreateWifiProfile) {
	$list=((netsh.exe wlan show profiles) -match ' : ')
	If($list) {
		$ProfileNames = $list.Split(":").Trim()
		If ($list.Count -gt 1) {
			For( $i = 1; $i -lt $ProfileNames.Count; $i +=2) {
				Write-Host "[$(($i+1)/2)] $($ProfileNames[$i]) "
			}
			[int]$selection = Read-Host -Prompt "Select Profile Number"
			$Index = $selection*2-1
			$ProfileName = $ProfileNames[$Index] 
		}
		Else{
			$ProfileName = $ProfileNames[0] 
		}
		Write-Host "Exporting $ProfileName" -ForegroundColor Green
	}
	else {
		Write-Host "No Wifi Profile found!" -ForegroundColor Yellow
		$ProfileName = ""
	}
}
#endregion

###########################################################
#region	Downloading Installation Media
###########################################################

#Get FIDO and download Windows 11 installation ISO
If ([string]::IsNullOrEmpty($DownloadISO) ) {
	#Select a language
	If (!$InstallLanguage){
		Write-Host "Select the ISO language to use:"
		$i = 0
		ForEach($Language in $IsoLanguages) {
			Write-Host "[$i] $($Language)"
			$i++
		}
		[int]$selection = Read-Host "Select Language Number"
		$InstallLanguage = $Language[$selection]
		Write-Host "Selected $($InstallLanguage)"
	}

	Invoke-Webrequest "https://raw.githubusercontent.com/pbatard/Fido/refs/heads/master/Fido.ps1" -Outfile "$WorkPath\Fido.ps1"
	#you can only use the script 3 times and then you have to wait 24h, restrictions of the MS web page.
	if (Test-Path -PathType Leaf "$WorkPath\DownloadIso.txt") {
		If ((Get-Item "$WorkPath\DownloadIso.txt").CreationTime -gt (Get-Date).AddHours(-24)) {
			$DownloadISO = Get-Content "$WorkPath\DownloadIso.txt"
		}
		Else {
			$DownloadISO = & "$WorkPath\Fido.ps1" -Ed $WindowsEdition -Lang $InstallLanguage -geturl
			# Make window visible again (this is sitting crooked, because PS needs it this way)
			Add-Type @"
using System;
using System.Runtime.InteropServices;
public class WinAPI {
	[DllImport("user32.dll")]
	[return: MarshalAs(UnmanagedType.Bool)]
	public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
"@
			$hwnd = (Get-Process -Id $PID).MainWindowHandle
			[WinAPI]::ShowWindow($hwnd, 1) | Out-Null
		}
	}
	Else {
		$DownloadISO = & "$WorkPath\Fido.ps1" -Ed $WindowsEdition -Lang $InstallLanguage -geturl
		Out-File -FilePath "$WorkPath\DownloadIso.txt" -InputObject $DownloadISO
	}
	Out-File -FilePath "$WorkPath\DownloadIso.txt" -InputObject $DownloadISO
}

#Download the ISO file if not already present
If (!(Test-Path -PathType Leaf "$WorkPath\Installation.iso")) {
	Write-Host "Downloading installation ISO please be patient!" -ForegroundColor Red
	$Isostartime = Get-Date
	$origProgressPreference = $ProgressPreference
	$ProgressPreference = 'SilentlyContinue' #to spped up the download significant
    Invoke-Webrequest $DownloadISO -Outfile "$WorkPath\Installation.iso"
	$ProgressPreference = $origProgressPreference
	$Isoendtime = Get-Date
	$time = $Isoendtime - $Isostartime
	$FileSize = (Get-Item -Path "$WorkPath\Installation.iso").Length
	Write-Host "It took $($time.Hours)h:$($time.Minutes)m:$($time.Seconds)s to download the $($FileSize/1GB)GB  Image" -ForegroundColor Magenta
	New-Item "$WorkPath\binschonda.txt"
}

#Mount the ISO and copy the data to the InstMediaPath folder
If (Test-Path -PathType Leaf $WorkPath\Installation.iso) {
	$InstVol = Mount-DiskImage -ImagePath $WorkPath\Installation.iso | Get-Volume
	$InstDriveLetter = "$($InstVol.DriveLetter):"
	$VolName = $InstVol.FileSystemLabel
	$InstMediaPath = "$WorkPath\$VolName"
	Remove-Item $InstMediaPath -Recurse -Force -ErrorAction SilentlyContinue
	$null = New-Item -ItemType Directory -Path $InstMediaPath
	Write-Host "Copying installation data to $InstMediaPath please be patient!" -ForegroundColor Red
	$null = Start-Process "$($env:windir)\System32\Robocopy.exe" "/NP /s /z ""$InstDriveLetter"" ""$InstMediaPath""" -Wait -NoNewWindow
	$null = Dismount-DiskImage -ImagePath $WorkPath\Installation.iso
}
Else {
	Write-Host "$WorkPath\Installation.iso  not found! Exiting"
	Clear-Path
	exit 1
}
#endregion

###########################################################
#region	Preparing Boot Image
###########################################################

Write-Host "Preparing Boot Image"

# prepare directory f. PE
Remove-Item $BootPath -Recurse -Force -ErrorAction SilentlyContinue
$null = New-Item -ItemType Directory -Path $BootPath

# mount Boot Image
Write-Host "Mounting Boot Image"
$BootWimTemp = "$InstMediaPath\sources\Boot.wim"
$null = Set-ItemProperty -Path $BootWimTemp -Name IsReadOnly -Value $false
Mount-WindowsImage -ImagePath $BootWimTemp -Index:2 -Path $BootPath

# Inject Drivers to BootImage
Write-Host "Adding drivers to Boot Image"
$null = Add-WindowsDriver -Path $BootPath -Driver $DriverFolder -Recurse

# Add Components to BootImage
Write-Host "Adding components to Boot Image"
$Components = @("*WinPE-WMI*", "*WinPE-NetFX*", "*WinPE-Scripting*", "*WinPE-PowerShell*", "*WinPE-StorageWM*", "*WinPE-DismCmdlet*", "*WinPE-Dot3Svc*")
$ComponetsPaths = (Get-ChildItem -Path "$ADKPath\Windows Preinstallation Environment\amd64\WinPE_OCs\*" -include $Components).FullName
$ComponetsPathsEn = (Get-ChildItem -Path "$ADKPath\Windows Preinstallation Environment\amd64\WinPE_OCs\en-us\*" -include $Components).FullName

Remove-Item $PackageTemp -Recurse -Force -ErrorAction SilentlyContinue
$null = New-Item -ItemType Directory -Path $PackageTemp

ForEach ($Path in $ComponetsPaths + $ComponetsPathsEn) {
	$null = Copy-Item $Path $PackageTemp
} 
$null = Add-WindowsPackage -Path $BootPath -PackagePath $PackageTemp -IgnoreCheck
Get-WindowsPackage -Path $BootPath | Format-Table -AutoSize | Out-File "$WorkPath\Components.txt"

# Add new Start Script to BootImage
Remove-Item "$BootPath\Windows\System32\startnet.cmd" -Force -ErrorAction SilentlyContinue
Remove-Item "$BootPath\Windows\System32\diskpart.txt" -Force -ErrorAction SilentlyContinue

$DiskpartScript = @"
select disk 0
clean
"@
$null = Add-Content -Path "$BootPath\Windows\System32\diskpart.txt" -Value $DiskpartScript

$startnetText = @"
`@ ECHO OFF
FOR /F "tokens=*" %%g IN ('WMIC DISKDRIVE where Interfacetype="SCSI"') do (SET DISKID=%%g)
IF "%DISKID%"==0 (diskpart /s X:\Windows\System32\diskpart.txt)
powercfg /s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 

ECHO "Unplug and replug USB Network adapter!"
ping 127.0.0.1 -n 20 >NUL


"X:\Windows\system32\WindowsPowerShell\v1.0\powershell.exe" invoke-webrequest "$StartScriptSource" -Outfile X:\Users\Public\Downloads\Start.ps1
"X:\Windows\system32\WindowsPowerShell\v1.0\powershell.exe" -Executionpolicy Bypass X:\Users\Public\Downloads\Start.ps1
wpeinit
"@

$null = Add-Content -Path "$BootPath\Windows\System32\startnet.cmd" -Value $startnetText

# Unmount Boot Image
$null = Dismount-WindowsImage -Path $BootPath -Save
#endregion

###########################################################
#region	Prepareing Install Image
###########################################################

Write-Host "Preparing Install Image"

# prepare directory f. Install.wim
Remove-Item $InstWimPath -Recurse -Force -ErrorAction SilentlyContinue
$null = New-Item -ItemType Directory -Path $InstWimPath

# mount Install Image
$InstWimTemp = "$InstMediaPath\sources\Install.wim"
$InstWimDest = "$InstMediaPath\sources\Dest.wim"
$InstallSWMFile = "$InstMediaPath\sources\Install.swm"
Set-ItemProperty -Path $InstWimTemp -Name IsReadOnly -Value $false
Mount-WindowsImage -ImagePath $InstWimTemp -Name $WindowsVersion -Path $InstWimPath
Write-Host "Adding drivers to Install Image"
$null = Add-WindowsDriver -Path $InstWimPath -Driver $DriverFolder -Recurse


# inject Intune Profile
$ProfileJSON | Set-Content -Encoding Ascii "$InstWimPath\Windows\Provisioning\Autopilot\AutopilotConfigurationFile.json"

# Unmount Install Image
$null = Dismount-WindowsImage -Path $InstWimPath -Save -CheckIntegrity
# Extract selected Windows Version
$null = Export-WindowsImage -SourceImagePath $InstWimTemp -SourceName $WindowsVersion -DestinationImagePath $InstWimDest
Remove-Item $InstWimTemp -Force
Rename-Item $InstWimDest $InstWimTemp

#Add Installation Files to $InstMediaPath
#Invoke-Webrequest "https://raw.githubusercontent.com/ThomasHoins/IntuneBootMediaBuilder/refs/heads/main/Settings.ps1" -Outfile "$InstMediaPath\Settings.ps1"
Invoke-Webrequest "https://raw.githubusercontent.com/ThomasHoins/IntuneBootMediaBuilder/refs/heads/main/UploadAutopilotInfo.ps1" -Outfile "$InstMediaPath\UploadAutopilotInfo.ps1"

# If a $AutounattendFile is supplied, use that, else download it
If ([string]::IsNullOrEmpty($AutounattendFile)){
    Invoke-Webrequest "https://raw.githubusercontent.com/ThomasHoins/IntuneBootMediaBuilder/refs/heads/main/autounattend.xml" -Outfile "$InstMediaPath\autounattend.xml"
}
Else{
    copy-item $AutounattendFile "$InstMediaPath" -Force
}

#Add the Tenant & Wifi Settings to the Settings.ps1
$ProfileFile=((netsh wlan export profile $ProfileName key=clear folder="$InstMediaPath\") -split """")[5]
$WifiName = ($ProfileFile.Split("\")[-1]).Replace(".xml","")

#Update Settings file with gathered information
If (Test-Path -Path $SecretFile){
	Write-Host "Reading Settings file..." -ForegroundColor Yellow
	$SecretSettings = Get-Content -Path $SecretFile | ConvertFrom-Json
	$TenantID = $SecretSettings.TenantID
	$AppID = $SecretSettings.AppID
	$AppSecret = $SecretSettings.AppSecret
}

$SettingsFile = "$InstMediaPath\Settings.json"
$Settings = [ordered]@{
	Wifi = $WifiName
	GroupTag = $GroupTag
	Comment1 = "[Assign] Wait for the Group Tag to be assigned before continuing"
	Assign = $false
	Comment2 = "[AssignedUser] Fill in the UPN of the user who will be assigned to the device"
	AssignedUser = ""
	Comment3 = "[OutputFile] If you want to output the hardware hash somewhere, put a path here"
	OutputFile = ""
	AppName = $AppObj.DisplayName
	TenantID = $TenantID
	AppID = $AppID
	AppSecret = $AppSecret
}
Out-File -FilePath $SettingsFile -InputObject ($Settings | ConvertTo-Json)



#endregion

###########################################################
#region	Creating Installation Media
###########################################################

#Create Media
Switch ($MediaSelection) {
	I {
		#"$ADKPath\Deployment Tools\amd64\Oscdimg\oscdimg.exe" -bootdata:2#p0,e,b"$PEPath\fwfiles\etfsboot.com"#pEF,e,b"$PEPath\fwfiles\efisys.bin" -u1 -udfver102 "$InstMediaPath" "$IsoFileName"
		# Test if all required files are there and create an Installation ISO
		if (!(Test-Path $IsoPath)) {
			New-Item -ItemType Directory -Path $IsoPath
		}
        $oscdimgCmd = "$ADKPath\Deployment Tools\amd64\Oscdimg\oscdimg.exe"
        if (!(Test-Path $oscdimgCmd)) {
            Write-Host "Could not locate $oscdimgCmd" -ForegroundColor Red
        }
		$IsoFileName = "$IsoPath\IntuneBootMedia.iso"
        if (!(Test-Path $InstMediaPath)) {
            Write-Host "Could not locate $ISOSourceFolder" -ForegroundColor Red
        }
        $etfsboot = "$PEPath\fwfiles\etfsboot.com"
        if (!(Test-Path $etfsboot)) {
            Write-Host "Could not locate $etfsboot" -ForegroundColor Red
        }
        $efisys = "$PEPath\fwfiles\efisys.bin"
        if (!(Test-Path $efisys)) {
            Write-Host "Could not locate $efisys" -ForegroundColor Red
        }

        Write-Host "Creating: $ISOFile" -ForegroundColor Cyan
        $data = '2#p0,e,b"{0}"#pEF,e,b"{1}"' -f $etfsboot, $efisys
        $null = Start-Process $oscdimgCmd -args @("-bootdata:$data",'-udfver102',"-u1","-l$VolName","`"$InstMediaPath`"", "`"$IsoFileName`"") -Wait -NoNewWindow


		# Check the result of the command
		if ((Test-Path $IsoFileName)) {
			Write-Host "The installation iso has been created succesfully and can be found here: $IsoPath " -ForegroundColor Green
		}
		Else{
			Write-Host "ERROR: Failed to create $IsoPath file." -ForegroundColor Red
			Clear-Path
		}
		
	}
	U {
		$usbDrive = (Get-Disk | Where-Object Path -like '*usbstor*')
        Write-Host "Formatting $($usbDrive.FriendlyName)" -ForegroundColor Red
        Start-Sleep 5
		$usbDriveNumber = $usbDrive.Number
		Get-Partition $usbDriveNumber | Remove-Partition -Confirm:$false
		If ($MultiParitionUSB) {
			#rework this part, all Setup stuff has to go to I: !
			New-Partition $usbDriveNumber -Size 2048MB | Format-Volume -FileSystem FAT32 -NewFileSystemLabel "WinPE" -Confirm:$false -Force
			New-Partition $usbDriveNumber -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel "Images" -Confirm:$false -Force
			Set-Partition -DiskNumber $usbDriveNumber -Partition 1 -NewDriveLetter P
			Set-Partition -DiskNumber $usbDriveNumber -Partition 2 -NewDriveLetter I
			Set-Partition -DiskNumber $usbDriveNumber -Partition 1 -IsActive $true
			Write-Host "Copying boot data to disk"
			Start-Process "$($env:windir)\System32\Robocopy.exe"  "/NP /s /z ""$InstMediaPath"" P: /max:3800000000" -Wait -NoNewWindow
			New-Item -ItemType Directory -Path "I:\Source"
			Write-Host "Copying Install.wim to disk"
			Copy-Item $InstWimTemp "I:\Source" -Force
		}
		Else {
			If ((get-disk | Where-Object bustype -eq 'usb').Size -lt 2199023255552) {
				New-Partition -DiskNumber $usbDriveNumber -UseMaximumSize | Format-Volume -FileSystem FAT32 -NewFileSystemLabel "WinPE" -Confirm:$false -Force
				Set-Partition -DiskNumber $usbDriveNumber -Partition 1 -NewDriveLetter P
				Set-Partition -DiskNumber $usbDriveNumber -Partition 1 -IsActive $true
				}
			Else {
				New-Partition $usbDriveNumber -Size 2TB | Format-Volume -FileSystem FAT32 -NewFileSystemLabel "WinPE" -Confirm:$false -Force
				Set-Partition -DiskNumber $usbDriveNumber -Partition 1 -NewDriveLetter P
				Set-Partition -DiskNumber $usbDriveNumber -Partition 1 -IsActive $true
			}
			$null = Set-ItemProperty -Path $InstWimTemp -Name IsReadOnly -Value $false
			#Split the install.wim if greater 4GiB
			If ((Get-Item $InstWimTemp).Length -gt 4294967295) {
				$null = Split-WindowsImage -ImagePath "$InstWimTemp" -SplitImagePath $InstallSWMFile -FileSize 4096 -CheckIntegrity
				Remove-Item "$InstWimTemp" -Force
			}
			Start-Process "$($env:windir)\System32\Robocopy.exe"  "/NP /s /z ""$InstMediaPath"" P:" -Wait -NoNewWindow
		}
		Start-Process "$($env:windir)\System32\bootsect.exe" "/nt60 P: /force /mbr" -NoNewWindow -Wait
	}
}
$EndTime = Get-Date
$time = $EndTime - $startTime
Write-Host "It Took $($time.Hours)h:$($time.Minutes)m:$($time.Seconds)s to Build this Media" -ForegroundColor Magenta
Write-Host "We are done!" -ForegroundColor Green

#endregion
