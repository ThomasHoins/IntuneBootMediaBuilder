$CatalogUrl  = "https://download.lenovo.com/cdrt/td/catalogv2.xml"
$DownloadDir = "C:\Temp\LenovoPXE"
$ProgressPreferenceDefault = $ProgressPreference
$ProgressPreference = 'SilentlyContinue'

if (-not (Test-Path $DownloadDir)) {
    New-Item -Path $DownloadDir -ItemType Directory | Out-Null
}

Write-Host "Downloading Lenovo driver catalog..."

try {
    # Download as byte array (raw binary)
    $bytes = Invoke-WebRequest -Uri $CatalogUrl -UseBasicParsing -TimeoutSec 60
    $raw = $bytes.Content

    # Convert bytes → string (UTF8)
    $rawText = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::UTF8.GetBytes($raw))

    # Remove possible UTF-8 BOM (ï»¿) or stray invisible chars
    $cleanXml = $rawText -replace "^\xEF\xBB\xBF", "" -replace "^\uFEFF", "" -replace "ï»¿", ""

    # Parse into XML
    [xml]$xml = $cleanXml
}
catch {
    Write-Error "Failed to download or parse catalog: $_"
    return
}

Write-Host "Parsing catalog..."

$products = @()

foreach ($model in $xml.ModelList.Model) {
    $name = $model.name
    #if ($name -notmatch "ThinkPad|IdeaPad|Yoga|Legion|Notebook|Laptop") {continue}
    # Laptop Option
    $types = $model.Types.Type
    
    foreach ($pack in $model.SCCM){
        $os = $pack.os
        If ($os -eq "Win11"){
            $date = $pack.date
            $version = $pack.version
            $driverUrl = $pack.'#text'
            $filename = ($driverUrl -split '/' | Select-Object -Last 1)
            if (-not ($products | Where-Object { $_.FileName -eq $filename})) {
                $products += [PSCustomObject]@{
                    Name  = $name
                    Types = $types
                    OS    = $os
                    Version = $version
                    Date  = $date
                    DriverURL   = $driverUrl
                    FileName = $filename
                }
            }
        }
    }

}


if ($products.Count -eq 0) {
    Write-Warning "No laptop models found in catalog."
    exit
}

try {
    $choice = $products | Sort-Object Name | Out-GridView -Title "Select Lenovo Laptop Model" -PassThru
}
catch {
    Write-Host "Out-GridView not available, showing first 10..."
    $choice = $products | Sort-Object Name | Select-Object -First 10
    $choice | Format-Table -AutoSize
    exit
}

if (-not $choice) {
    Write-Host "No model selected. Exiting."
    exit
}

try{
    $jobs = @()
    $maxParallel = 3
    foreach($Item in $choice) {
        $jobs += Start-Job -Name $Item.Name-ScriptBlock {
            param($Item, $DownloadDir)
            $destFile = Join-Path $DownloadDir $Item.FileName
            $extractPath = Join-Path $DownloadDir ($Item.Name -replace '[^a-zA-Z0-9]', '_')
            
            Write-Output "Downloading driver pack for $($Item.Name)..."
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $Item.DriverURL -OutFile $destFile -UseBasicParsing
            
            Write-Output "Extracting to $extractPath ..."
            #Start-Process -FilePath $destFile -ArgumentList "/VERYSILENT /DIR=$($extractPath)" -Wait
            Write-Output "Drivers extracted to: $extractPath"
            } -ArgumentList $Item, $DownloadDir
        $running = (Get-Job -State Running)
        foreach ($job in $running) {
            Receive-Job -Job $job -Keep| Write-Output 
            }
        while ((Get-Job -State Running).Count -ge $maxParallel) {
            Write-Output "Waiting for a job to complete... "
            Start-Sleep -Seconds 30
            }
        }
    Wait-Job $jobs
    Receive-Job $jobs
    Remove-Job $jobs
    }
catch {
    Write-Error "Failed to download driver pack: $($choice.Name) - $_"
}

$ProgressPreference = $ProgressPreferenceDefault