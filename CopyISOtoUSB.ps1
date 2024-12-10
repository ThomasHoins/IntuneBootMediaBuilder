$usbDrive = (get-disk | Where-Object bustype -eq 'usb')
$usbDriveNumber = $usbDrive.Number
$usbDriveName = $usbDrive.FriendlyName
$confirmation = Read-Host "Are you Sure You Want To Proceed and delete all Data on ""$($usbDriveName)""?"
#Exit if not confirmed
if ($confirmation -ne 'y') {Exit}

# Format the USB drive
Clear-Disk -Number $usbDriveNumber -RemoveData
New-Partition -DiskNumber $usbDriveNumber -Size 2048MB -IsActive -DriveLetter P | Format-Volume -FileSystem FAT32 -NewFileSystemLabel "WinPE" 
New-Partition -DiskNumber $usbDriveNumber -UseMaximumSize        -DriveLetter I | Format-Volume -FileSystem NTFS -NewFileSystemLabel "Images" 
bootsect.exe /nt60 P: /force /mbr 

# Mount the ISO file
Add-Type -AssemblyName System.Windows.Forms
$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$OpenFileDialog.Title = "Select ISO file to copy"
$OpenFileDialog.InitialDirectory = "c:\\"
$OpenFileDialog.filter = 'ISO Files (*.iso)|*.*'
[void] $OpenFileDialog.ShowDialog()
$isoPath = $OpenFileDialog.FileName
$mountResult = Mount-DiskImage -ImagePath $isoPath -PassThru
$isoDriveLetter = ($mountResult | Get-Volume).DriveLetter

# Copy files to the USB
robocopy "$($isoDriveLetter):\" "P:\"  /s /z /NP /xf Install.wim
Write-Host "Copying Install.wim"
Copy-Item "$($isoDriveLetter):\sources\install.wim" "I:\install.wim"


# Clean up: Unmount the ISO
mountvol I: /P
mountvol P: /P
Dismount-DiskImage -ImagePath $isoPath

