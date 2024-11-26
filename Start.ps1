#Download FIDO
Invoke-Webrequest "https://raw.githubusercontent.com/pbatard/Fido/refs/heads/master/Fido.ps1" -Outfile "X:\Users\Public\Downloads\Fido.ps1"
#Invoke-Webrequest "https://catalog.s.download.windowsupdate.com/c/msdownload/update/driver/drvs/2024/09/3e4f6712-9575-4960-98a5-9dfd6e19ee7f_7b36505e0cb7e03b1838f13d2b4453193599030d.cab" -Outfile "X:\Users\Public\Downloads\Surface_HIDClass_3.98.10.0.cab"

#md X:\Users\Public\Downloads\Surface4
#expand.exe "X:\Users\Public\Downloads\Surface_HIDClass_3.98.10.0.cab" -F:* "X:\Users\Public\Downloads\Surface4"
#Get-ChildItem -Path "X:\Users\Public\Downloads\Surface4" -Filter *.inf -Recurse -ErrorAction SilentlyContinue -Force | %{ drvload $_.FullName}

#"get missing drivers
Get-WmiObject Win32_PNPEntity | Where-Object{[string]::IsNullOrEmpty($_.ClassGuid)}|select Caption, CreationClassName, HardwareID |ft


#Start FIDO
$URL=& "X:\Users\Public\Downloads\Fido.ps1" -geturl
Invoke-Webrequest $URL -Outfile X:\Install.iso
Start X:\Install.iso

