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
- An AzureAD App Registration
  - Add the following API permissions:
    Microsoft Graph -> Application Permissions ->
      - `DeviceManagementConfiguration.ReadWrite.All`
      - `DeviceManagementManagedDevices.ReadWrite.All`
      - `DeviceManagementServiceConfig.ReadWrite.All`
    - Grant admin consent for permissions
- Copy the client ID and Tenant ID and Secret values, and paste to "Settings.ps1" under corresponding variables

During the USB media cration a autounattended.xml will be copied to the Installation media. You can use the "https://schneegans.de/windows/unattend-generator" to modify this.
Make sure that the following entry is added to your script suring the "specialize" phase. Also make sure to modify the "<Order>1</Order>" entry to the appropriate number.

```
<component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <RunSynchronous>
      <RunSynchronousCommand wcm:action="add">
        <Order>1</Order>
        <Path>cmd /q /c "FOR %i IN (C D E F G H I J K L N M O P Q R S T U V W X Y Z) DO IF EXIST %i:\WindowsAutoPilotInfo.ps1 powershell -ExecutionPolicy Bypass -File %i:\WindowsAutoPilotInfo.ps1 -Settings %i:Settings.ps1"</Path>
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
| `TempFolder`      | Specifies the temporary folder path.                                                        | `C:\Temp`                |
| `OutputFolder`    | Specifies the output folder for the final media.                                            | N/A                      |
| `StartScriptSource` | Specifies the URL of the PowerShell startup script to be executed by the WinPE.           | Provided URL             |
| `DriverFolder`    | Specifies the folder containing drivers to be injected into the WinPE image.                | `C:\Temp\Drivers`        |
| `ADKPath`         | Specifies the installation path of the Windows ADK.                                         | `C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit` |
| `ADKVersion`      | Specifies the version of the Windows ADK to be used.                                        | `10.1.22621.1`           |

## Usage

### Example 1: Create an ISO file
```powershell
.\IntuneBootMediaBuilder.ps1 -PEPath "C:\WinPE" -IsoPath "C:\Output\BootImage.iso" -DriverFolder "C:\Drivers"




A collection of useful links:

https://www.osdcloud.com/sandbox/winpe-downloads

Windows 11 22H2 WinRE with KB5026372:

https://winpe.blob.core.windows.net/public/WinPE_Win11_22H2_WinRE_KB5026372.iso

Updates per Powershell

https://www.windowspro.de/wolfgang-sommergut/windows-updates-powershell-pswindowsupdate-auflisten-herunterladen-installieren
https://www.powershellgallery.com/packages/PSWindowsUpdate/2.2.1.5

Surface Treiber:

https://www.catalog.update.microsoft.com/Search.aspx?q=Surface+Driver+%22Windows+11%22+%22Version+22H2%22+-Firmware

Optional Components

https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/winpe-add-packages--optional-components-reference?view=windows-11


https://www.windowspro.de/wolfgang-sommergut/windows-pe-osdcloud-konfigurieren

'$WINPEDriver$'

https://learn.microsoft.com/en-us/troubleshoot/windows-client/setup-upgrade-and-drivers/limitations-dollar-sign-winpedriver-dollar-sign

Windows PE startup sequence explained

https://slightlyovercomplicated.com/2016/11/07/windows-pe-startup-sequence-explained/
