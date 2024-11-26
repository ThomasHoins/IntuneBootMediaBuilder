winget install Microsoft.WindowsADK --version 10.1.22621.1
winget install Microsoft.ADKPEAddon --version 10.1.22621.1

Call "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\DandISetEnv.bat"

REM PE Daten vorbereiten
rd C:\Temp\WinPE_admd64 /S /Q
Call copype amd64 C:\Temp\WinPE_admd64

REM Verzeichnis f. das PE Bereitstellen
rd C:\Temp\mount\WinPE_admd64 /S /Q
md C:\Temp\mount\WinPE_admd64

REM Image Mounten
Dism /Mount-Image /ImageFile:"C:\Temp\WinPE_admd64\media\sources\boot.wim" /Index:1 /MountDir:"C:\Temp\mount\WinPE_admd64"

REM "Injecting Drivers"
Dism /Image:"C:\Temp\mount\WinPE_admd64" /Add-Driver /Driver:C:\Temp\Drivers /Recurse

REM PE Komponenten hinzufügen
Dism /Add-Package /Image:"C:\Temp\mount\WinPE_admd64" /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-WMI.cab"
Dism /Add-Package /Image:"C:\Temp\mount\WinPE_admd64" /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\en-us\WinPE-WMI_en-us.cab"
Dism /Add-Package /Image:"C:\Temp\mount\WinPE_admd64" /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-NetFX.cab"
Dism /Add-Package /Image:"C:\Temp\mount\WinPE_admd64" /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\en-us\WinPE-NetFX_en-us.cab"
Dism /Add-Package /Image:"C:\Temp\mount\WinPE_admd64" /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-Scripting.cab"
Dism /Add-Package /Image:"C:\Temp\mount\WinPE_admd64" /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\en-us\WinPE-Scripting_en-us.cab"
Dism /Add-Package /Image:"C:\Temp\mount\WinPE_admd64" /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-PowerShell.cab"
Dism /Add-Package /Image:"C:\Temp\mount\WinPE_admd64" /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\en-us\WinPE-PowerShell_en-us.cab"
Dism /Add-Package /Image:"C:\Temp\mount\WinPE_admd64" /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-StorageWMI.cab"
Dism /Add-Package /Image:"C:\Temp\mount\WinPE_admd64" /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\en-us\WinPE-StorageWMI_en-us.cab"
Dism /Add-Package /Image:"C:\Temp\mount\WinPE_admd64" /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-DismCmdlets.cab"
Dism /Add-Package /Image:"C:\Temp\mount\WinPE_admd64" /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\en-us\WinPE-DismCmdlets_en-us.cab"
Dism /Add-Package /Image:"C:\Temp\mount\WinPE_admd64" /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-Dot3Svc.cab"
Dism /Add-Package /Image:"C:\Temp\mount\WinPE_admd64" /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\en-us\WinPE-Dot3Svc_en-us.cab"

REM Add new Start Script
Del "C:\Temp\mount\WinPE_admd64\Windows\System32\startnet.cmd" /F
echo wpeinit>> "C:\Temp\mount\WinPE_admd64\Windows\System32\startnet.cmd"
echo ping 127.0.0.1 -n 20^>NUL >> "C:\Temp\mount\WinPE_admd64\Windows\System32\startnet.cmd"
echo "X:\Windows\system32\WindowsPowerShell\v1.0\powershell.exe" invoke-webrequest "https://raw.githubusercontent.com/ThomasHoins/IntuneInstall/refs/heads/main/Start.ps1" -Outfile X:\Users\Public\Downloads\Start.ps1>> "C:\Temp\mount\WinPE_admd64\Windows\System32\startnet.cmd"
echo "X:\Windows\system32\WindowsPowerShell\v1.0\powershell.exe" -Executionpolicy Bypass "X:\Users\Public\Downloads\Start.ps1">> "C:\Temp\mount\WinPE_admd64\Windows\System32\startnet.cmd"


REM Unmount Image
Dism /Unmount-Image /MountDir:"C:\Temp\mount\WinPE_admd64" /Commit

choice /m "Create an ISO image or a USB Stick or Cancel?" /c IUC
If ERRORLEVEL=1 Goto ISO
If ERRORLEVEL=2 Goto USB
Exit

:USB
setlocal
for /F "skip=1 tokens=1-10" %%A IN ('wmic logicaldisk get description^, deviceid')DO (
   if "%%A %%B" == "Removable Disk" (
      echo Found Removable Disk %%C
   )
)
choice /m "Do you really want to delete all content on %%C ?" /c yn
if not ERRORLEVEL=1 Exit
makewinpemedia /ufd  C:\Temp\WinPE_admd64 %%C
Exit

:ISO
makewinpemedia /iso C:\Temp\WinPE_admd64 C:\Temp\Install.iso
Exit
