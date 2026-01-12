<#
PowerShell helper to install winutils.exe and set HADOOP_HOME on Windows

USAGE: Run from PowerShell with elevated rights if you want system-wide setx changes.
  .\scripts\setup_winutils.ps1

This script will:
 - Check for an existing HADOOP_HOME with winutils in bin
 - Offer to download a prebuilt winutils.exe into C:\hadoop\bin (user must confirm URL)
 - Set HADOOP_HOME environment variable and update PATH (permanent via setx)

WARNING: Downloading prebuilt executables from a third party is not officially supported by Apache. Only proceed if you trust the URL.
If you prefer, install WSL/Ubuntu and run Spark there (no winutils required).
#>

param(
    [string]$HadoopHome = "C:\hadoop",
    [string]$DefaultUrl = "https://github.com/steveloughran/winutils/raw/master/hadoop-3.1.3/bin/winutils.exe"
)

function Test-WinUtils($path) {
    return Test-Path (Join-Path $path 'bin\winutils.exe')
}

if (Test-WinUtils $HadoopHome) {
    Write-Host "winutils.exe already found in $HadoopHome\bin\winutils.exe" -ForegroundColor Green
    exit 0
}

$useDefault = Read-Host "No winutils found. Download default winutils from $DefaultUrl? (y/n)"
if ($useDefault -notin @('y','Y')) {
    $url = Read-Host "Provide URL to winutils.exe (blank to cancel)"
    if ([string]::IsNullOrWhiteSpace($url)) { Write-Host "Canceled"; exit 1 }
} else {
    $url = $DefaultUrl
}

Write-Host "Creating $HadoopHome\bin folder" -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path (Join-Path $HadoopHome 'bin') | Out-Null

$target = Join-Path $HadoopHome 'bin\winutils.exe'
Write-Host "Downloading $url to $target ..." -ForegroundColor Yellow
try {
    Invoke-WebRequest -Uri $url -OutFile $target -UseBasicParsing
    Write-Host "Downloaded winutils.exe" -ForegroundColor Green
} catch {
    Write-Host "Failed to download: $_" -ForegroundColor Red
    exit 1
}

Write-Host "Setting HADOOP_HOME and PATH environment variables (current session and system)" -ForegroundColor Yellow
[Environment]::SetEnvironmentVariable('HADOOP_HOME', $HadoopHome, 'User')
[Environment]::SetEnvironmentVariable('PATH', [Environment]::GetEnvironmentVariable('PATH', 'User') + ";$HadoopHome\bin", 'User')
setx HADOOP_HOME $HadoopHome
setx PATH "$($env:PATH);$HadoopHome\bin"

Write-Host "Done. Restart PowerShell (or sign out/in) to apply system environment variable changes." -ForegroundColor Green
