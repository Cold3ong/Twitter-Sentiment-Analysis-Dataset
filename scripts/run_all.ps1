<#
Run the end-to-end preprocess & baseline training pipeline on Windows PowerShell.

This is a convenience wrapper which:
 - Optionally ensures dependencies via `setup_and_run.ps1` (only installs pip requirements if asked)
 - Runs PySpark preprocess script to create `data/processed/v1/` artifacts
 - Runs baseline training pipeline to generate model and metrics

Usage:
  # Run everything using the current Python and available Spark configuration
  .\scripts\run_all.ps1

  # Build environment with Conda (if desired) and run preprocessing + baseline
  .\scripts\run_all.ps1 -CreateCondaEnv -EnvName bigdata

#>

param(
    [switch] $CreateCondaEnv,
    [string] $EnvName = 'bigdata',
    [switch] $InstallPipRequirements
)

Write-Host 'Running end-to-end pipeline: setup -> preprocess -> baseline' -ForegroundColor Green

if ($CreateCondaEnv -or $InstallPipRequirements) {
    $cmd = "./setup_and_run.ps1"
    if ($CreateCondaEnv) { $cmd += ' -CreateCondaEnv -EnvName ' + $EnvName }
    if ($InstallPipRequirements) { $cmd += ' -InstallPipRequirements' }
    Write-Host "Calling: $cmd" -ForegroundColor Cyan
    & pwsh -NoProfile -Command $cmd
}

# Run PySpark preprocessing
Write-Host 'Running PySpark preprocessing...' -ForegroundColor Green
& python scripts/preprocess_pyspark.py --input data/stock_market_crash_2022.csv --out-dir data/processed
if ($LASTEXITCODE -ne 0) { throw 'Preprocessing failed' }

# Run baseline training pipeline
Write-Host 'Running baseline model training...' -ForegroundColor Green
& python scripts/run_baseline_pyspark.py --train data/processed/v1/train.parquet --test data/processed/v1/test.parquet --out-dir .
if ($LASTEXITCODE -ne 0) { throw 'Baseline training failed' }

Write-Host 'End-to-end run finished. Check data/processed/v1/ and results/ for artifacts' -ForegroundColor Green
