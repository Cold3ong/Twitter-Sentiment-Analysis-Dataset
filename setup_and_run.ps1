<#
PowerShell script: setup_and_run.ps1

Purpose: Performs reproducible environment and workspace checks for the project and runs preprocessing workflows.

Usage examples (PowerShell):
  # Create Conda env and install dependencies using environment.yml
  ./setup_and_run.ps1 -CreateCondaEnv -EnvName bigdata

  # Install pip requirements into currently-active python environment
  ./setup_and_run.ps1 -SkipConda -InstallPipRequirements

  # Run PySpark preprocessing pipeline after checks
  ./setup_and_run.ps1 -RunPySparkPreprocess

  # Execute notebook via papermill (optional; requires papermill installed)
  ./setup_and_run.ps1 -RunNotebook

Notes:
  - The script prefers Conda environment creation if flagged. If conda is missing it falls back to pip.
  - The script does not automatically modify the user's global environment variables without confirmation.
  - This is a helper script; use carefully if running in existing environments.
#>

param(
    [switch] $CreateCondaEnv,
    [string] $EnvName = 'bigdata',
    [switch] $RunPySparkPreprocess = $true,
    [switch] $RunNotebook = $false,
    [switch] $InstallPipRequirements = $false,
    [string] $InputCSV = 'data/stock_market_crash_2022.csv',
    [string] $OutDir = 'data/processed',
    [switch] $Force = $false
)

function Write-Header([string] $msg) {
    Write-Host "=========================================" -ForegroundColor Green
    Write-Host $msg -ForegroundColor Green
    Write-Host "=========================================" -ForegroundColor Green
}

Write-Header "Project Setup & Run Helper"

# Helper: run a command and show output; if $Force, stop on error
function Run-Command($cmd, [switch] $ExitOnError) {
    Write-Host "Running: $cmd" -ForegroundColor Cyan
    & pwsh -NoProfile -Command $cmd
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Command failed (exit code $LASTEXITCODE): $cmd" -ForegroundColor Red
        if ($ExitOnError -or $Force) { throw "Command aborted due to failure" }
    }
}

# 1) Optionally create Conda env
if ($CreateCondaEnv) {
    if (-not (Get-Command conda -ErrorAction SilentlyContinue)) {
        Write-Host "Conda not found on PATH. Please install Miniconda/Anaconda, or use the -InstallPipRequirements flag." -ForegroundColor Yellow
    }
    else {
        Write-Host "Creating or updating conda env '$EnvName' from environment.yml..." -ForegroundColor Green
        $cmd = "conda env create -f environment.yml -n $EnvName 2>$null; if ($LASTEXITCODE -ne 0) { conda env update -f environment.yml -n $EnvName }"
        Run-Command $cmd -ExitOnError
        Write-Host "Conda environment creation/update complete; activate it with:" -ForegroundColor Green
        Write-Host "conda activate $EnvName" -ForegroundColor Green
    }
}

# 2) Optionally install pip requirements into active interpreter
if ($InstallPipRequirements) {
    Write-Host "Installing pip requirements from requirements.txt into the current active python environment..." -ForegroundColor Green
    Run-Command "python -m pip install -r requirements.txt" -ExitOnError
}

# 3) Run dependency checks (scripts/check_deps.py)
if (Test-Path scripts/check_deps.py) {
    Write-Host 'Checking installed Python package versions vs pinned versions (scripts/check_deps.py)...' -ForegroundColor Green
    & python scripts/check_deps.py
    if ($LASTEXITCODE -ne 0) { Write-Host 'Dependency check raised issues — please inspect results/deps_check.json' -ForegroundColor Yellow }
}
else { Write-Host 'No scripts/check_deps.py found — skipping dependency pinned version checks' -ForegroundColor Yellow }

# 4) Validate PySpark environment
if (Test-Path scripts/test_pyspark_version.py) {
    Write-Host 'Running PySpark smoke test (scripts/test_pyspark_version.py)...' -ForegroundColor Green
    & python scripts/test_pyspark_version.py
    if ($LASTEXITCODE -ne 0) { Write-Host 'PySpark smoke test failed. See output for details.' -ForegroundColor Red }
}

# 5) Validate SPARK_HOME with simple Python snippet (safe checks)
Write-Host 'Validating SPARK_HOME against the installed PySpark package version...' -ForegroundColor Green
Write-Host 'Validating SPARK_HOME and collecting environment details into results/spark_check.json...' -ForegroundColor Green
$validatePy = @'
import os
import re
from pathlib import Path
import sys
try:
    import pyspark
    pyspark_ver = getattr(pyspark, '__version__', None)
except Exception as e:
    pyspark_ver = None
sp = os.environ.get('SPARK_HOME')
def _extract_jars_ver(jars_path: Path):
    try:
        if not jars_path.exists():
            return None
        for j in jars_path.glob('*.jar'):
            m = re.search(r'spark-(?:core|sql).*-(\d+\.\d+\.\d+)', j.name)
            if m:
                return m.group(1)
    except Exception:
        return None
    return None
if not sp:
    print('No SPARK_HOME set. Please set SPARK_HOME to your Spark distribution if using a standalone Spark install.')
    sys.exit(0)
sp_path = Path(sp)
jar_ver = _extract_jars_ver(sp_path / 'jars')
# write output to JSON
import json
out = {
    'spark_home': sp,
    'jars_version': jar_ver,
    'pyspark_package_version': pyspark_ver,
}
print('Detected SPARK_HOME:', sp)
print('Detected jars version under SPARK_HOME:', jar_ver)
print('Installed pyspark package version:', pyspark_ver)
Path('results').mkdir(parents=True, exist_ok=True)
with open(Path('results') / 'spark_check.json', 'w', encoding='utf-8') as fh:
    json.dump(out, fh, indent=2)
if pyspark_ver and jar_ver and pyspark_ver != jar_ver:
    print('WARNING: pyspark package version does not match jars under SPARK_HOME. Consider unsetting SPARK_HOME or point to a matching Spark distribution.')
    sys.exit(2)
sys.exit(0)
'@ | python -
if ($LASTEXITCODE -ne 0) { Write-Host 'SPARK_HOME validation had warnings or mismatch' -ForegroundColor Yellow }

# 6) Optionally run the PySpark preprocessing script
if ($RunPySparkPreprocess) {
    if (-not (Test-Path scripts/preprocess_pyspark.py)) {
        Write-Host 'PySpark preprocessing script not found in scripts/preprocess_pyspark.py' -ForegroundColor Red
    }
    else {
        # Ensure the dataset exists
        if (-not (Test-Path $InputCSV)) {
            Write-Host "Input CSV $InputCSV not found. Attempting to locate it under the repository..." -ForegroundColor Yellow
            # fallback search (check data folder)
            if (Test-Path data/stock_market_crash_2022.csv) {
                $InputCSV = "data/stock_market_crash_2022.csv"
            }
            else {
                Write-Host 'Could not find dataset — aborting preprocessing.' -ForegroundColor Red
                exit 1
            }
        }

        Write-Host "Starting PySpark preprocessing (input=$InputCSV out=$OutDir) ..." -ForegroundColor Green
        & python scripts/preprocess_pyspark.py --input $InputCSV --out-dir $OutDir
        if ($LASTEXITCODE -ne 0) {
            Write-Host 'Preprocessing failed. See output logs for details.' -ForegroundColor Red
        }
        else { Write-Host 'Preprocessing finished.' -ForegroundColor Green }
    }
}

# 7) Optionally run the notebook using papermill for reproducibility
if ($RunNotebook) {
    Write-Host 'Executing notebook using papermill (notebooks/00_data_preprocessing.ipynb) ...' -ForegroundColor Green
    if (-not (Get-Command papermill -ErrorAction SilentlyContinue)) {
        Write-Host 'papermill not found. Installing papermill in the current Python environment...' -ForegroundColor Yellow
        Run-Command "python -m pip install papermill" -ExitOnError
    }
    $out_nb = "notebooks/00_data_preprocessing.executed.ipynb"
    & papermill notebooks/00_data_preprocessing.ipynb $out_nb -p input $InputCSV -p out_dir $OutDir
    if ($LASTEXITCODE -ne 0) { Write-Host 'Notebook execution failed.' -ForegroundColor Red }
    else { Write-Host ("Notebook executed; output notebook saved to " + $out_nb) -ForegroundColor Green }
}

Write-Host 'Done. Check results, models, and data/processed/v1 outputs for artifacts.' -ForegroundColor Green
