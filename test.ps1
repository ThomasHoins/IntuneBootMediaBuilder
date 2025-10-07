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
    $types = $model.Types.Type
    
    foreach ($pack in $model.SCCM) {
        $os = $pack.os
        If ($os -eq "Win11"){
        $driverUrl = $pack.'#text'
    
            $products += [PSCustomObject]@{
                Name  = $name
                Types = $types
                OS    = $os
                DriverURL   = $driverUrl
                FileName = ($driverUrl -split '/' | Select-Object -Last 1)
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

$destFile = "$DownloadDir\$($choice.FileName)"
$extractPath = Join-Path $DownloadDir ($choice.Name -replace '[^a-zA-Z0-9]', '_')
try{
    Write-Host "Downloading driver pack for $($choice.Name)..."
    Invoke-WebRequest -Uri $choice.DriverURL -OutFile $destFile -UseBasicParsing

    Write-Host "Extracting to $extractPath ..."
    Start-Process -FilePath $destFile -ArgumentList "/VERYSILENT /DIR=$($extractPath)" -Wait
    Write-Host "Done. Drivers extracted to: $extractPath"
    }
catch {
    Write-Error "Failed to download driver pack: $($choice.Name) - $_"
}

$ProgressPreference = $ProgressPreferenceDefault