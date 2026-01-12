<#
Check + optional install/uninstall JDK helper for Windows
Non-destructive: prints commands to run, optionally tries to install via winget/choco
Usage examples:
  # Check current java & recommend action
  pwsh.exe -File .\scripts\check_java_and_install_jdk.ps1 -CheckOnly

  # Install using winget (requires admin/permission)
  pwsh.exe -File .\scripts\check_java_and_install_jdk.ps1 -Install -Confirm:$true

  # Set JAVA_HOME to the detected new installation path (persist to user env vars)
  pwsh.exe -File .\scripts\check_java_and_install_jdk.ps1 -SetJavaHome -Path "C:\Program Files\Eclipse Adoptium\jdk-17.0.16.8-hotspot" -Persist
#>

param(
    [switch]$CheckOnly = $false,
    [switch]$Install = $false,
    [switch]$SetJavaHome = $false,
    [string]$Path = "",
    [switch]$Persist = $false,
    [switch]$UninstallOldJava = $false
)

function Write-Note([string]$s){ Write-Host "[NOTE] $s" -ForegroundColor Cyan }
function Write-Warn([string]$s){ Write-Host "[WARN] $s" -ForegroundColor Yellow }
function Write-Err([string]$s){ Write-Host "[ERROR] $s" -ForegroundColor Red }

# Report current java and common properties
Write-Note "Checking current Java installation(s) and environment..."

# Get java version output
$javaVersionRaw = $null
try {
    $javaVersionRaw = & java -version 2>&1 | Out-String
} catch {
    $javaVersionRaw = $null
}

if ($javaVersionRaw) {
    Write-Host "java -version output:`n$javaVersionRaw"
} else {
    Write-Warn "`'java -version`' not available from PATH. You may not have a JDK installed or it's not on PATH."
}

# Show javac if present
$javacRaw = $null
try {
    $javacRaw = & javac -version 2>&1 | Out-String
} catch {
    $javacRaw = $null
}
if ($javacRaw) { Write-Host "javac -version output: $javacRaw" }

# Show current JAVA_HOME
Write-Host "JAVA_HOME: $([Environment]::GetEnvironmentVariable('JAVA_HOME', 'User')) (user)",
Write-Host "JAVA_HOME (machine): $([Environment]::GetEnvironmentVariable('JAVA_HOME', 'Machine')) (machine)",
Write-Host "Current PATH first entries: "
$env:PATH.Split(';') | Select-Object -First 10 | ForEach-Object { Write-Host "  $_" }

# Lists all java executables found on PATH
$javaCmds = (Get-Command java -All -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -Unique)
if ($javaCmds.Length -gt 0) {
    Write-Note "Detected java.exe locations from PATH:"
    $javaCmds | ForEach-Object { Write-Host "  $_" }
} else {
    Write-Warn "No java.exe found on PATH."
}

# Detect installed JDK folders in common locations
$commonCandidates = @( "C:\Program Files\Java", "C:\Program Files (x86)\Java", "C:\Program Files\Eclipse Adoptium", "C:\Program Files\Zulu", "C:\Program Files\Amazon Corretto", "C:\Program Files\BellSoft" )
$installedJDks = @()
foreach ($c in $commonCandidates) {
    if (Test-Path $c) {
        Get-ChildItem $c -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            if ($_ -and $_.Name -match 'jdk|jre|temurin|corretto|zulu') { $installedJDks += $_.FullName }
        }
    }
}

if ($installedJDks.Count -gt 0) {
    Write-Note "Detected installed Java JDK/JRE folders (candidates):"
    $installedJDks | ForEach-Object { Write-Host "  $_" }
} else {
    Write-Warn "No well-known JDK installation directories found in common locations."
}

# Function: attempt to choose a JDK path to set as JAVA_HOME
function Choose-JdkPath {
    param([string]$explicitPath)
    if ($explicitPath -and (Test-Path $explicitPath)) { return (Resolve-Path $explicitPath).Path }
    if ($installedJDks -and $installedJDks.Length -gt 0) { return $installedJDks[0] }
    return $null
}

# Helper: run winget or choco installer if requested
function Install-JdkViaWinget {
    Write-Host "Attempting to install Eclipse Temurin 17 using winget..."
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $winget) { Write-Warn "winget is not available on this system; try using Chocolatey (choco) or install manually from https://adoptium.net/temurin/releases/?version=17"; return $false }
    # Use the exact winget id for Temurin 17; may differ on systems. Use -e for exact match
    $installCmd = "winget install --id Eclipse.Adoptium.Temurin.17.JDK -e --silent"
    Write-Host "Will run: $installCmd" -ForegroundColor Green
    $answer = Read-Host "Continue and run the installation using winget? (requires admin rights) [y/N]"
    if ($answer -ne 'y' -and $answer -ne 'Y') { Write-Warn "Skipping winget install"; return $false }
    # Run winget
    try {
        Start-Process -FilePath winget -ArgumentList 'install', '--id', 'Eclipse.Adoptium.Temurin.17.JDK', '-e', '--silent' -Wait -NoNewWindow -Verb RunAs
        return $true
    } catch {
        Write-Err "winget install failed: $_"; return $false
    }
}

function Install-JdkViaChoco {
    Write-Host "Attempting to install Eclipse Temurin 17 using Chocolatey (choco)..."
    $choco = Get-Command choco -ErrorAction SilentlyContinue
    if (-not $choco) { Write-Warn "choco is not available on this system; consider installing via winget, manual installer, or download from Adoptium."; return $false }
    $installCmd = "choco install temurin17 -y"
    Write-Host "Will run: $installCmd" -ForegroundColor Green
    $answer = Read-Host "Continue and run the installation using Chocolatey? (requires admin rights) [y/N]"
    if ($answer -ne 'y' -and $answer -ne 'Y') { Write-Warn "Skipping choco install"; return $false }
    try {
        Start-Process -FilePath choco -ArgumentList 'install', 'temurin17', '-y' -Wait -NoNewWindow -Verb RunAs
        return $true
    } catch {
        Write-Err "choco install failed: $_"; return $false
    }
}

if ($CheckOnly -and -not $Install -and -not $SetJavaHome) {
    Write-Note "Check-only mode; no changes will be made. Suggested next steps are displayed below."
    Write-Host "If you need to install the JDK, run this script with -Install. To set JAVA_HOME, run with -SetJavaHome -Path '<path>' -Persist."
    exit 0
}

# If installation requested, try to do it
if ($Install -and -not $CheckOnly) {
    Write-Note "User requested install; attempting a best-effort install using winget or Chocolatey"
    $done = $false
    $done = Install-JdkViaWinget
    if (-not $done) { $done = Install-JdkViaChoco }
    if (-not $done) {
        Write-Warn "Automatic install attempts failed. Please install a JDK 17 manually from https://adoptium.net/temurin/releases/?version=17 and re-run this script with -SetJavaHome"
        exit 1
    }
    Write-Note "Installation command completed — you may need to restart PowerShell or log out/in to pick up PATH changes. Please re-run this script with -CheckOnly to verify."
    exit 0
}

# If set JAVA_HOME requested
if ($SetJavaHome) {
    $chosenPath = Choose-JdkPath -explicitPath $Path
    if (-not $chosenPath) { Write-Err "Could not find a JDK path to set. If you have installed one, run again with -Path '<installed_path>'."; exit 1 }
    Write-Host "Setting JAVA_HOME to: $chosenPath" -ForegroundColor Green
    # Set environment variable for current session
    $env:JAVA_HOME = $chosenPath
    $bin = Join-Path $chosenPath 'bin'
    $env:PATH = "$bin;$env:PATH"
    Write-Note "Set for the current session. Run the following to persist the change for your user account (PowerShell as current user):"
    Write-Host "    setx JAVA_HOME \"$chosenPath\"" -ForegroundColor Yellow
    Write-Host "    setx PATH \"$bin;`%PATH%`\"" -ForegroundColor Yellow
    if ($Persist) {
        Write-Note "Writing to persistent user environment variables using setx..."
        try {
            # Persist JAVA_HOME
            & setx JAVA_HOME "$chosenPath" | Out-Null
            # Persist PATH: careful to not duplicate; we will prepend the Java bin to current PATH
            $currentUserPath = [Environment]::GetEnvironmentVariable('PATH', 'User')
            if (-not $currentUserPath) { $currentUserPath = [Environment]::GetEnvironmentVariable('PATH', 'Machine') }
            $newPath = "$bin;$currentUserPath"
            & setx PATH "$newPath" | Out-Null
            Write-Note "Persisted JAVA_HOME and updated PATH in user environment variables; you may need to log out/in for changes to take effect."
        } catch {
            Write-Err "Persisting env var failed: $_"
        }
    }
    # Verify
    try {
        Write-Host "After setting, verify:"
        $ver = & java -version 2>&1 | Out-String
        Write-Host $ver
    } catch { Write-Warn "Could not run java -version right now; you may need to start a new shell session." }
    exit 0
}

# Uninstall old Java isn't implemented (deferred)
if ($UninstallOldJava) {
    Write-Warn "Uninstall functionality needs Windows admin operations and depends on the Java vendor. Use Control Panel -> Programs & Features or winget/choco uninstall commands manually."
    Write-Host "Example winget uninstall: winget uninstall --id Eclipse.Adoptium.Temurin.8.JDK"
    Write-Host "Example choco uninstall: choco uninstall temurin8 -y"
    exit 0
}

# If not a special flag, suggest recommended steps
Write-Host "\nRecommended steps to ensure PySpark + Java compatibility (non-destructive):" -ForegroundColor Cyan
Write-Host "  1) Install JDK 17 (OpenJDK 17) if you don\'t have it; prefer Temurin 17 or Corretto 17."
Write-Host "     - winget install --id Eclipse.Adoptium.Temurin.17.JDK -e --silent (requires winget and admin)" -ForegroundColor Green
Write-Host "     - OR choco install temurin17 -y (requires chocolatey admin)" -ForegroundColor Green
Write-Host "     - OR download from https://adoptium.net/temurin/releases/?version=17 (manual installer)" -ForegroundColor Green
Write-Host "  2) Set JAVA_HOME to the installed JDK path and ensure PATH contains %JAVA_HOME%\bin. Either via Control Panel or from PowerShell: setx JAVA_HOME 'C:\Program Files\Eclipse Adoptium\jdk-17...'" -ForegroundColor Cyan
Write-Host "  3) If you have multiple java versions in PATH (e.g., Java 8), remove older java.exe entries from PATH or uninstall older distributions to avoid mismatches." -ForegroundColor Cyan
Write-Host "  4) Ensure SPARK_HOME is not pointing to a Spark distribution incompatible with your pip pyspark (3.5.7), or point it to the correct Spark version matching the pip wheel." -ForegroundColor Cyan
Write-Host "  5) Optionally set PYSPARK_PYTHON and PYSPARK_DRIVER_PYTHON to the venv python when running local pyspark scripts: e.g." -ForegroundColor Cyan
Write-Host "       $env:PYSPARK_PYTHON = 'C:\Path\To\venv310\Scripts\python.exe'" -ForegroundColor Green
Write-Host "       $env:PYSPARK_DRIVER_PYTHON = 'C:\Path\To\venv310\Scripts\python.exe'" -ForegroundColor Green
Write-Host "  6) Re-run scripts/test_pyspark_version.py and scripts/preprocess_pyspark.py to validate after installing Java 17 and setting env vars." -ForegroundColor Cyan

exit 0
