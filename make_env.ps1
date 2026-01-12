<#
PowerShell helper to create a reproducible environment for this project on Windows.
This script tries to use conda if available (recommended). Otherwise it creates a venv
with Python 3.10 and installs pinned packages via pip while preferring binary wheels to
avoid building compiled packages from source.

Usage (PowerShell):
  .\make_env.ps1 [-EnvName bigdata] [-Type conda|venv] [-Force]

Examples:
  # Use conda if installed
  .\make_env.ps1 -Type conda

  # Create a venv and install pinned requirements
  .\make_env.ps1 -Type venv

Notes:
  - This script prefers conda for compiled libs (numpy/pandas/pyarrow) to avoid ABI issues.
  - If you have multiple Python versions installed, use the `py -3.10 -m venv` invocation by
    passing -UsePyLauncher to force Python 3.10 as venv base.
  - If pip attempts to build numpy from source (you see build-wheel failures), ensure you are
    running pip from Python 3.10 (not system Python 3.13) or use conda to install binary packages.
#>

param(
    [string] $EnvName = 'bigdata',
    [ValidateSet('conda','venv')]
    [string] $Type = 'conda',
    [switch] $Force,
    [switch] $UsePyLauncher
)

$kernel_name = "${EnvName}-venv"
& $venvDir\Scripts\python.exe -m ipykernel install --user --name $kernel_name --display-name "$kernel_name (PySpark)"

function _CheckExe($exe){
    try {
        $null = Get-Command $exe -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

_WriteLine("Starting environment setup (Type=$Type, EnvName=$EnvName)")

if ($Type -eq 'conda'){
    if (-not (_CheckExe 'conda')){
        _WriteLine('Conda not found in path; falling back to venv. Use -Type venv to explicitly create a venv.')
        $Type = 'venv'
    }
}

if ($Type -eq 'conda'){
    if ($Force){
        _WriteLine('Removing preexisting conda environment (if any)')
        conda env remove -n $EnvName -y | Out-Null
    }
    _WriteLine('Creating conda environment from environment.yml using conda-forge packages...')
    conda env create -f environment.yml -n $EnvName --force
    _WriteLine("To use the environment: 'conda activate $EnvName' and then register the kernel (optional):`n  python -m ipykernel install --user --name $EnvName --display-name \"$EnvName (PySpark)\"`")
    exit 0
}

# Venv path
$venvDir = Join-Path -Path (Get-Location) -ChildPath '.venv310'
if ($Force -and (Test-Path $venvDir)){
    Remove-Item -Recurse -Force $venvDir
}

if ($UsePyLauncher -or _CheckExe 'py'){
    _WriteLine('Using py -3.10 to create venv (explicit)')
    py -3.10 -m venv $venvDir
} else {
    # Create venv with default python executable
    python -m venv $venvDir
}

if (-not (Test-Path $venvDir)){
    _WriteLine('Failed to create venv. If you have multiple Python versions, try: py -3.10 -m venv .venv310')
    exit 1
}

_WriteLine('Activating venv and upgrading pip/tools')
& $venvDir\Scripts\Activate.ps1
& $venvDir\Scripts\python.exe -m pip install --upgrade pip setuptools wheel

_WriteLine('Installing pinned requirements (prefer binary wheels to avoid building from source)')
try{
    & $venvDir\Scripts\python.exe -m pip install --prefer-binary -r requirements.txt
} catch {
    _WriteLine('Failed to install requirements from requirements.txt. Will attempt to install compiled wheels first (numpy/pandas/pyarrow).')
    try {
        & $venvDir\Scripts\python.exe -m pip install --only-binary=:all: numpy==1.24.4 pandas==2.1.3 pyarrow==11.0.0
    } catch {
        _WriteLine('Failed to install prebuilt binary wheels for compiled libs; try using conda or check your Python version (target Python 3.10).')
        throw
    }
    & $venvDir\Scripts\python.exe -m pip install --prefer-binary -r requirements.txt
}

# Extra check: if numpy >= 2.x is present in this venv, warn user and try to re-install pinned numpy<2
try {
    $pip_show = & $venvDir\Scripts\python.exe -m pip show numpy 2>$null
    if ($pip_show) {
        if ($pip_show -match 'Version: (\d+)\.(\d+)') {
            $major = [int]$matches[1]
            if ($major -ge 2) {
                _WriteLine('Detected NumPy major version >= 2 in the venv. This can cause ABI issues with some compiled packages like pyarrow. Attempting to reinstall numpy==1.24.4 and pyarrow==11.0.0 via binary wheels...')
                & $venvDir\Scripts\python.exe -m pip uninstall -y numpy pyarrow pandas | Out-Null
                & $venvDir\Scripts\python.exe -m pip install --only-binary=:all: numpy==1.24.4 pandas==2.1.3 pyarrow==11.0.0
            }
        }
    }
} catch {
    # best-effort, don't fail the script here
}

_WriteLine('Register kernel (optional):')
& $venvDir\Scripts\python.exe -m ipykernel install --user --name $EnvName --display-name "$EnvName (PySpark)"

_WriteLine('Done — please restart your Jupyter kernel or VSCode session to use the new interpreter.')
