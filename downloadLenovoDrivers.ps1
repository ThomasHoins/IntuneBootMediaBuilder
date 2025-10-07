<#
.SYNOPSIS
    Download Lenovo SCCM/MDT Driver Packs automatically (no login required)

.DESCRIPTION
    - Fetches model list from Lenovo support index page (HT074984)
    - Lets you pick a model interactively
    - Downloads and extracts the driver pack
#>

$DownloadPath = "C:\Temp\LenovoPXE"
$IndexURL = "https://support.lenovo.com/us/en/solutions/ht074984-microsoft-system-center-configuration-manager-sccm-and-microsoft-deployment-toolkit-mdt-package-index"
$CacheFile = "$env:TEMP\lenovo_driver_index.json"

if (-not (Test-Path $DownloadPath)) {
    New-Item -ItemType Directory -Path $DownloadPath | Out-Null
}

function Get-LenovoDriverList {
    Write-Host "Fetching Lenovo driver pack index..."
    try {
        $headers = @{
            "User-Agent"      = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
            "Accept"          = "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8"
            "Accept-Language" = "en-US,en;q=0.9"
            "Referer"         = "https://www.google.com/"
        }
        $page = Invoke-WebRequest -Uri $IndexURL -Headers $headers -UseBasicParsing -TimeoutSec 60
        $pattern = '<a\s+href="([^"]+?driverpack[^"]+\.zip)"[^>]*>([^<]+)</a>'
        $matches = [regex]::Matches($page.Content, $pattern, 'IgnoreCase')

        $models = @()
        foreach ($m in $matches) {
            $url = $m.Groups[1].Value
            $name = $m.Groups[2].Value.Trim()
            if ($url -notmatch "^https?://") {
                $url = "https://support.lenovo.com$url"
            }
            $models += [PSCustomObject]@{
                Name = $name
                Url  = $url
            }
        }

        if ($models.Count -eq 0) {
            throw "No driver packs found on Lenovo page."
        }

        $models | ConvertTo-Json -Depth 4 | Out-File $CacheFile -Encoding UTF8
        return $models
    }
    catch {
        Write-Warning "Failed to fetch index: $_"
        if (Test-Path $CacheFile) {
            Write-Host "Loading cached list..."
            return Get-Content $CacheFile | ConvertFrom-Json
        }
        else {
            throw "No cached list available."
        }
    }
}

# Load list (with cache)
if (Test-Path $CacheFile) {
    $cacheAgeDays = ((Get-Date) - (Get-Item $CacheFile).LastWriteTime).Days
    if ($cacheAgeDays -gt 7) {
        $Models = Get-LenovoDriverList
    } else {
        Write-Host "Using cached model list..."
        $Models = Get-Content $CacheFile | ConvertFrom-Json
    }
} else {
    $Models = Get-LenovoDriverList
}

if (-not $Models) {
    Write-Error "No models found."
    exit
}

# Select model
$Choice = $Models | Sort-Object Name | Out-GridView -Title "Select Lenovo Model" -PassThru
if (-not $Choice) {
    Write-Host "No model selected, exiting."
    exit
}

$ModelName = $Choice.Name
$URL = $Choice.Url
$FileName = Split-Path $URL -Leaf
$Destination = Join-Path $DownloadPath $FileName
$ExtractPath = Join-Path $DownloadPath ($ModelName -replace '[^a-zA-Z0-9]', '_')

Write-Host "Downloading $ModelName..."
Write-Host "URL: $URL"

try {
    Invoke-WebRequest -Uri $URL -OutFile $Destination -UseBasicParsing
    Write-Host "Download complete: $Destination"
}
catch {
    Write-Error "Download failed: $_"
    exit
}

Write-Host "Extracting driver pack..."
try {
    Expand-Archive -Path $Destination -DestinationPath $ExtractPath -Force
    Write-Host "Drivers extracted to: $ExtractPath"
}
catch {
    Write-Error "Extraction failed: $_"
}
