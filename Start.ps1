#Download FIDO
Invoke-Webrequest "https://raw.githubusercontent.com/pbatard/Fido/refs/heads/master/Fido.ps1" -Outfile "X:\Users\Public\Downloads\Fido.ps1"
#Download InstallDrivers
#Invoke-Webrequest "https://raw.githubusercontent.com/ThomasHoins/IntuneInstall/refs/heads/main/InstallDrivers.ps1" -Outfile "X:\Users\Public\Downloads\InstallDrivers.ps1"


#get missing drivers
Get-WmiObject Win32_PNPEntity | Where-Object{[string]::IsNullOrEmpty($_.ClassGuid)

#Install Drivers
#"X:\Users\Public\Downloads\InstallDrivers.ps1"


#Start FIDO
"X:\Users\Public\Downloads\Fido.ps1"
