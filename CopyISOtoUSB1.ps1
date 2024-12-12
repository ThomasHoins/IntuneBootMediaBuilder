# Enhanced PowerShell Script for USB Preparation

# Function to handle user confirmation with explicit yes/no
function Confirm-Action {
    param (
        [string]$Message
    )
    do {
        $response = Read-Host "$Message (Type 'yes' to confirm, 'no' to cancel)"
        if ($response -eq 'yes') {
            return $true
        } elseif ($response -eq 'no') {
            Write-Host "Operation canceled." -ForegroundColor Yellow
            return $false
        } else {
            Write-Host "Invalid input. Please type 'yes' or 'no'." -ForegroundColor Red
        }
    } while ($true)
}

# Get USB drive details
$usbDrive = Get-Disk | Where-Object { $_.Bustype -eq 'USB' -and $_.OperationalStatus -eq 'Online' }
if (-not $usbDrive) {
    Write-Host "No USB drives found or USB drive is not online. Exiting." -ForegroundColor Red
    Exit
}

$usbDriveNumber = $usbDrive.Number
$usbDriveName = $usbDrive.FriendlyName

# Confirm with the user
if (-not (Confirm-Action "Are you sure you want to format and delete all data on ""$($usbDriveName)""?")) {
    Exit
}

# Safety check before formatting
if ($null -eq $usbDriveNumber) {
    Write-Host "Unable to retrieve USB drive number. Exiting." -ForegroundColor Red
    Exit
}

# Format the USB drive
Write-Host "Formatting USB drive..." -ForegroundColor Cyan
try {
    Clear-Disk -Number $usbDriveNumber -RemoveData -Confirm:$false -ErrorAction Stop
    New-Partition -DiskNumber $usbDriveNumber -Size 2048MB -IsActive -DriveLetter P | Format-Volume -FileSystem FAT32 -NewFileSystemLabel "WinPE" -Confirm:$false
    New-Partition -DiskNumber $usbDriveNumber -UseMaximumSize -DriveLetter I | Format-Volume -FileSystem NTFS -NewFileSystemLabel "Images" -Confirm:$false
} catch {
    Write-Host "Error during disk preparation: $_" -ForegroundColor Red
    Exit
}

# Install boot sector
Write-Host "Installing boot sector..." -ForegroundColor Cyan
try {
    bootsect.exe /nt60 P: /force /mbr
} catch {
    Write-Host "Failed to install boot sector: $_" -ForegroundColor Red
    Exit
}

# Select ISO file using File Open Dialog
Write-Host "Please select an ISO file to copy." -ForegroundColor Cyan
Add-Type -AssemblyName System.Windows.Forms
$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$OpenFileDialog.Title = "Select ISO file to copy"
$OpenFileDialog.InitialDirectory = "C:\"
$OpenFileDialog.Filter = 'ISO Files (*.iso)|*.iso'
if ($OpenFileDialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
    Write-Host "No file selected. Exiting." -ForegroundColor Yellow
    Exit
}

$isoPath = $OpenFileDialog.FileName
if (-not (Test-Path $isoPath)) {
    Write-Host "Selected file does not exist. Exiting." -ForegroundColor Red
    Exit
}

# Mount the ISO file
Write-Host "Mounting ISO file..." -ForegroundColor Cyan
try {
    $mountResult = Mount-DiskImage -ImagePath $isoPath -PassThru -ErrorAction Stop
    $isoDriveLetter = ($mountResult | Get-Volume).DriveLetter
} catch {
    Write-Host "Failed to mount ISO file: $_" -ForegroundColor Red
    Exit
}

# Ensure drive letters are used correctly
if (-not $isoDriveLetter) {
    Write-Host "Unable to determine ISO drive letter. Exiting." -ForegroundColor Red
    Exit
}
$isoDrivePath = "$isoDriveLetter`:\"

# Copy files to the USB
Write-Host "Copying files from ISO to USB..." -ForegroundColor Cyan
try {
    robocopy "$isoDrivePath" "P:\" /s /z /np /xf install.wim
    Write-Host "Copying install.wim..." -ForegroundColor Cyan
    Copy-Item "$isoDrivePath\sources\install.wim" "I:\install.wim" -ErrorAction Stop
} catch {
    Write-Host "Error during file copy: $_" -ForegroundColor Red
    Exit
}

# Clean up: Unmount the ISO and unmount USB drives
Write-Host "Cleaning up and unmounting drives..." -ForegroundColor Cyan
try {
    # Use PowerShell cmdlets to remove drive letters
    Get-Partition -DriveLetter P |Remove-PartitionAccessPath -AccessPath "P:\" -ErrorAction SilentlyContinue
    Get-Partition -DriveLetter I |Remove-PartitionAccessPath -AccessPath "I:\" -ErrorAction SilentlyContinue
    Dismount-DiskImage -ImagePath $isoPath -ErrorAction Stop
} catch {
    Write-Host "Error during cleanup: $_" -ForegroundColor Red
}

Write-Host "Operation completed successfully." -ForegroundColor Green
