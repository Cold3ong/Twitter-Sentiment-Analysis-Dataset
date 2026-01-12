# Setup script for project environment (PowerShell)
param(
    [string]$PythonPath = "C:\Users\swkan\AppData\Local\Programs\Python\Python310\python.exe",
    [string]$VenvPath = ".venv310",
    [string]$Requirements = "requirements.txt"
)

Write-Host "Creating venv at $VenvPath using $PythonPath"
& $PythonPath -m venv $VenvPath

$venvPython = Join-Path $VenvPath "Scripts\python.exe"
Write-Host "Upgrading pip in venv ($venvPython)"
& $venvPython -m pip install -U pip

if (Test-Path $Requirements) {
    Write-Host "Installing requirements: $Requirements"
    & $venvPython -m pip install -r $Requirements
} else {
    Write-Host "Requirements file $Requirements not found in repo; skipping."
}

Write-Host "Done. Activate the venv with: .\$VenvPath\Scripts\Activate.ps1"
