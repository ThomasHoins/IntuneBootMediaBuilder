# IntuneBootMediaBuilder

A PowerShell script to create bootable USB media or ISO files with a customized Windows Preinstallation Environment (WinPE). This script is designed to streamline the deployment of Windows devices with Intune and Autopilot.

## Features

- Downloads and installs the Windows ADK if not already available.
- Creates a bootable Windows PE image.
- Injects custom drivers and components into the WinPE image.
- Modifies the startup script (`startnet.cmd`) to download and run a custom PowerShell script for Intune Autopilot deployment.
- Supports both ISO file creation and direct USB flash drive preparation.

## Prerequisites

- Windows operating system.
- Administrator privileges to execute the script.
- [Windows ADK](https://learn.microsoft.com/en-us/windows-hardware/get-started/adk-install) compatible with your operating system version.
- Internet connection for downloading the startup script and ADK, if not already installed.
- A USB flash drive with at least 8 GB capacity (if creating a bootable USB).
- Exported Wifi profile (optional)
    1. Create a local folder for the exported Wi-Fi profiles, such as c:\WiFi.
    2. Open a command prompt as an administrator.
    3. Run the `netsh wlan show profiles` command. Note the name of the profile you want to export.
    4. Run the `netsh wlan export profile name="ContosoWiFi" folder=c:\Wifi` command. This command creates a Wi-Fi profile file named Wi-Fi-ContosoWiFi.xml in your target folder.
- An AzureAD App Registration (https://learn.microsoft.com/en-us/mem/intune/developer/intune-graph-apis; https://endusersupports.com/index.php/2023/08/13/app-registration-for-intune/)
  - Add the following API permissions:
    Microsoft Graph -> Application Permissions ->
      - `DeviceManagementConfiguration.ReadWrite.All`
      - `DeviceManagementManagedDevices.ReadWrite.All`
      - `DeviceManagementServiceConfig.ReadWrite.All`
    - Grant admin consent for permissions
- Copy the client ID and Tenant ID and Secret values, and paste to "Settings.ps1" on the installation media under corresponding variables. 

During the USB media cration a autounattended.xml will be copied to the Installation media. You can use the "https://schneegans.de/windows/unattend-generator" to modify this.
Make sure that the following entry is added to your script suring the "specialize" phase. Also make sure to modify the "<Order>1</Order>" entry to the appropriate number.

```
<component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <RunSynchronous>
      <RunSynchronousCommand wcm:action="add">
        <Order>10</Order>
        <Path>cmd /q /c "FOR %i IN (C D E F G H I J K L N M O P Q R S T U V W X Y Z) DO IF EXIST %i:\UploadAutopilotInfo.ps1 powershell -ExecutionPolicy Bypass -File %i:\UploadAutopilotInfo.ps1 -Settings %i:Settings.ps1"</Path>
        <Description>Run AutoPilot script</Description>
      </RunSynchronousCommand>
    </RunSynchronous>
</component>
```




## Parameters

| Parameter         | Description                                                                                 | Default Value            |
|--------------------|---------------------------------------------------------------------------------------------|--------------------------|
| `PEPath`          | Specifies the path where the WinPE files will be cached.                                    | N/A                      |
| `IsoPath`         | Specifies the target path for the ISO file.                                                 | Working directory        |
| `MultiParitionUSB`| Possibility to create a multi partition USB installation media for large Images             | `$false`        |
| `TempFolder`      | Specifies the temporary folder path.                                                        | `C:\Temp`                |
| `OutputFolder`    | Specifies the output folder for the final media.                                            | N/A                      |
| `StartScriptSource` | Specifies the URL of the PowerShell startup script to be executed by the WinPE.           | Provided URL             |
| `DriverFolder`    | Specifies the folder containing drivers to be injected into the WinPE image.                | `C:\Temp\Drivers`        |
| `ADKPath`         | Specifies the installation path of the Windows ADK.                                         | `C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit` |
| `ADKVersion`      | Specifies the version of the Windows ADK to be used.                                        | `10.1.22621.1`           |
| `WindowsEdition`  | The edition of Windows to be downloaded (e.g., Windows 11 Home/Pro/Edu).                    | `Windows 11 Home/Pro/Edu`|
| `WindowsVersion`  | The Version of Windows to be selected during installation (e.g., Windows 11 Pro).           | `Windows 11 Pro`         |
| `InstallLanguage` | The language of the Windows installation (e.g., English)                                    | `English`                |
| `Locale`          | The Locale of the Windows installation (e.g., en-US)                                        | `en-US`                  |
| `DownloadISO`     | The URL to download the Windows installation ISO.                                           | N/A                      |
| `AutocreateWifiProfile`| If you want the Wifi Profile to be autocreated, based on your 1st Wifi Profile         | `$true`                  |
| `MediaSelection`  | The type of media to create (e.g., 'I' for ISO, 'U' for USB Stick).                         | N/A                      |
| `AutounattendFile`| The path to the autounattend.xml file to be integrated. (don't use together withAutocreateWifiProfile)| N/A            |
| `AppId`           | The AppID you created to log in into Intune                                                 | N/A                      |
| `TenantID`        | The ID of your O365 Tenant                                                                  | N/A                      |
| `AppSecret`       | The AppSecret you created to log in into Intune                                             | N/A                      |
| `ProfileID`       | The ProfileID you created to log in into Intune                                             | N/A                      |



## Usage

### Example 1: Create an ISO file
```powershell
.\IntuneBootMediaBuilder.ps1 -PEPath "C:\WinPE" -IsoPath "C:\Output\BootImage.iso" -DriverFolder "C:\Drivers"


## A collection of useful links:

https://github.com/bokkoman/IntuneAutoPilot/blob/main/README.md

https://schneegans.de/windows/unattend-generator"

https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/update-windows-settings-and-scripts-create-your-own-answer-file-sxs?view=windows-11

https://endusersupports.com/index.php/2023/08/13/app-registration-for-intune/

https://www.osdcloud.com/sandbox/winpe-downloads

### Windows 11 22H2 WinRE with KB5026372:

https://winpe.blob.core.windows.net/public/WinPE_Win11_22H2_WinRE_KB5026372.iso

### Updates per Powershell

https://www.windowspro.de/wolfgang-sommergut/windows-updates-powershell-pswindowsupdate-auflisten-herunterladen-installieren
https://www.powershellgallery.com/packages/PSWindowsUpdate/2.2.1.5

### Surface Dreiver:

https://www.catalog.update.microsoft.com/Search.aspx?q=Surface+Driver+%22Windows+11%22+%22Version+22H2%22+-Firmware

#### Optional Components

https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/winpe-add-packages--optional-components-reference?view=windows-11


https://www.windowspro.de/wolfgang-sommergut/windows-pe-osdcloud-konfigurieren

'$WINPEDriver$'

https://learn.microsoft.com/en-us/troubleshoot/windows-client/setup-upgrade-and-drivers/limitations-dollar-sign-winpedriver-dollar-sign

Windows PE startup sequence explained

https://slightlyovercomplicated.com/2016/11/07/windows-pe-startup-sequence-explained/
