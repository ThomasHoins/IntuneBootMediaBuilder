<#
.SYNOPSIS
Creates bootable USB media or an ISO file using Windows ADK Preinstallation Environment (PE).

.DESCRIPTION
This script prepares a Windows PE environment, injects drivers, configures components, and creates bootable media. 
The output can either be an ISO file or a USB stick.

.PARAMETER PEPath
Specifies the path to cache PE files.

.PARAMETER IsoPath
Specifies the destination path for the ISO file. Must end with `.iso`.

.PARAMETER TempFolder
Specifies the path for temporary data (default: `C:\Temp`).

.PARAMETER OutputFolder
Specifies the output folder for final image.

.PARAMETER StartScriptSource
URL of the custom startup script for the PE image.

.PARAMETER DriverFolder
Folder containing drivers to inject into the PE image.

.PARAMETER ADKPath
Path to the Windows ADK installation.

.PARAMETER ADKVersion
Version of the Windows ADK to install if not found locally.

#>

Param (
    [Parameter(Mandatory = $true)][string]$PEPath,
    [Parameter(Mandatory = $false)][string]$IsoPath,
    [string]$TempFolder = "C:\Temp",
    [string]$OutputFolder,
    [string]$StartScriptSource = "https://raw.githubusercontent.com/ThomasHoins/IntuneInstall/refs/heads/main/Start.ps1",
    [string]$DriverFolder = "C:\Temp\Drivers",
    [string]$ADKPath = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit",
    [string]$ADKVersion = "10.1.22621.1"
)

# Ensure admin privileges
if (-not ([Security.Principal.WindowsPrincipal]([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Script requires administrative privileges. Please run as Administrator."
    Exit 1
}

# Function: Validate and prepare paths
function Initialize-Paths {
    param (
        [string]$TempFolder,
        [string]$PEPath
    )
    if (-not (Test-Path $TempFolder)) {
        New-Item -ItemType Directory -Path $TempFolder | Out-Null
    }
    if (-not (Test-Path $PEPath)) {
        New-Item -ItemType Directory -Path $PEPath | Out-Null
    }
}

# Function: Download and install ADK if missing
function Install-ADK {
    param (
        [string]$ADKPath,
        [string]$ADKVersion
    )
    if (-not (Test-Path "$ADKPath\Deployment Tools\DandISetEnv.bat")) {
        Write-Output "Installing Windows ADK version $ADKVersion..."
        winget install Microsoft.WindowsADK --version $ADKVersion
        winget install Microsoft.ADKPEAddon --version $ADKVersion
    }
}

# Function: Create ISO image
function New-Iso {
    param (
        [string]$IsoPath,
        [string]$PEPath,
        [string]$ADKPath
    )
    if ($IsoPath -notmatch "\.iso$") {
        Write-Error "ERROR: IsoPath must end with '.iso'."
        Exit 1
    }

    $BootData = "1#pEF,e,b`"$PEPath\fwfiles\efisys.bin`""
    if (Test-Path "$PEPath\fwfiles\etfsboot.com") {
        $BootData = "2#p0,e,b`"$PEPath\fwfiles\etfsboot.com`"#pEF,e,b`"$PEPath\fwfiles\efisys.bin`""
    }

    $OscdImgPath = "$ADKPath\Deployment Tools\amd64\Oscdimg\oscdimg.exe"
    $Command = "`"$OscdImgPath`" -bootdata:$BootData -u1 -udfver102 `"$PEPath\media`" `"$IsoPath`""
    Write-Output "Running: $Command"
    Invoke-Expression $Command
    Write-Output "ISO created at $IsoPath"
}

# Function: Format USB and copy PE files
function Set-USB {
    param (
        [string]$PEPath
    )
    $UsbDisk = Get-Disk | Where-Object { $_.BusType -eq 'USB' -and $_.PartitionStyle -eq 'MBR' }
    if (-not $UsbDisk) {
        Write-Error "No USB disk detected. Ensure a USB stick is connected."
        Exit 1
    }
    $UsbDisk | Clear-Disk -RemoveData -Confirm:$false
    $Partition = New-Partition -DiskNumber $UsbDisk.Number -UseMaximumSize -IsActive -AssignDriveLetter
    Format-Volume -FileSystem NTFS -DriveLetter $Partition.DriveLetter -Confirm:$false
    Copy-Item -Path "$PEPath\media\*" -Destination "$($Partition.DriveLetter):\" -Recurse
    Write-Output "Bootable USB created at drive $($Partition.DriveLetter):"
}

# Main execution
Initialize-Paths -TempFolder $TempFolder -PEPath $PEPath
Install-ADK -ADKPath $ADKPath -ADKVersion $ADKVersion

$Selection = Read-Host "Select output type: [I]SO, [U]SB, [C]ancel"
switch ($Selection.ToUpper()) {
    "I" { New-Iso -IsoPath $IsoPath -PEPath $PEPath -ADKPath $ADKPath }
    "U" { Set-USB -PEPath $PEPath }
    "C" { Write-Output "Operation canceled."; Exit 0 }
    default { Write-Error "Invalid selection. Exiting."; Exit 1 }
}
