#Download FIDO
Invoke-Webrequest "https://raw.githubusercontent.com/pbatard/Fido/refs/heads/master/Fido.ps1" -Outfile X:\Users\Public\Downloads\Fido.ps1
#get missing drivers
#Get-WmiObject Win32_PNPEntity | Where-Object{[string]::IsNullOrEmpty($_.ClassGuid)


#Start FIDO
X:\Users\Public\Downloads\Fido.ps1
