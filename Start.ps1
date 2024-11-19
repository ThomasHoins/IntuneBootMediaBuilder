#Download FIDO
Invoke-Webrequest "https://raw.githubusercontent.com/pbatard/Fido/refs/heads/master/Fido.ps1" -Outfile X:\Users\Public\Downloads\Fido.ps1
#get missing drivers
#Get-WmiObject Win32_PNPEntity | Where-Object{[string]::IsNullOrEmpty($_.ClassGuid)

#Register Windows Update Service
$UpdateSvc = New-Object -ComObject Microsoft.Update.ServiceManager            
$UpdateSvc.AddService2("7971f918-a847-4430-9279-4a52d1efe18d",7,"")  

#Search and list all missing Drivers
$Session = New-Object -ComObject Microsoft.Update.Session           
$Searcher = $Session.CreateUpdateSearcher() 

$Searcher.ServiceID = '7971f918-a847-4430-9279-4a52d1efe18d'
$Searcher.SearchScope =  1 # MachineOnly
$Searcher.ServerSelection = 3 # Third Party
          
$Criteria = "IsInstalled=0 and Type='Driver'"
Write-Host('Searching Driver-Updates...') -Fore Green     
$SearchResult = $Searcher.Search($Criteria)          
$Updates = $SearchResult.Updates
	
#Show available Drivers...
$Updates | select Title, DriverModel, DriverVerDate, Driverclass, DriverManufacturer | fl

#Download the Drivers
$UpdatesToDownload = New-Object -Com Microsoft.Update.UpdateColl
$Updates | % { $UpdatesToDownload.Add($_) | out-null }
Write-Host('Downloading Drivers...')  -Fore Green
$UpdateSession = New-Object -Com Microsoft.Update.Session
$Downloader = $UpdateSession.CreateUpdateDownloader()
$Downloader.Updates = $UpdatesToDownload
$Downloader.Download()

$UpdatesToInstall = New-Object -Com Microsoft.Update.UpdateColl
$updates | % { if($_.IsDownloaded) { $UpdatesToInstall.Add($_) | out-null } }

#Install the Drivers
Write-Host('Installing Drivers...')  -Fore Green
$Installer = $UpdateSession.CreateUpdateInstaller()
$Installer.Updates = $UpdatesToInstall
$InstallationResult = $Installer.Install()
if($InstallationResult.RebootRequired) { 
  Write-Host('Reboot required! please reboot now..') -Fore Red
  } 
else { 
  Write-Host('Done..') -Fore Green 
  }
#Start FIDO
X:\Users\Public\Downloads\Fido.ps1
