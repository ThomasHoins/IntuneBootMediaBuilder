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
