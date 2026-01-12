# Environment Setup & Run Instructions (Windows / PowerShell)

This document explains how to create a reproducible Python + Spark environment for this project, validates the environment, and runs preprocessing and optional notebook execution.

Overview
 - The repository contains tools to run preprocessing using both PySpark (`scripts/preprocess_pyspark.py`) and a pure-Python (pandas/sklearn) implementation (`scripts/preprocess.py`).
 - `setup_and_run.ps1` is a PowerShell helper that performs checks and runs preprocessing.
 - Use `scripts/check_deps.py` to validate pinned dependencies, and `scripts/test_pyspark_version.py` to test PySpark startup.

Prerequisites
 - Windows PowerShell (pwsh.exe recommended)
 - Python 3.10+ (compatible with the environment.yml / requirements.txt)
 - Optionally, Conda (Miniconda/Anaconda) if creating the environment through `environment.yml`.
 - Optional: Spark distribution installed and `SPARK_HOME` set (if you want a local Spark distribution), otherwise the PySpark package will use a local distribution shipped with the package.

Quick Start (recommended)
 - From PowerShell at repo root, create a conda environment:
   ```powershell
   # Create or update the conda environment named 'bigdata' from environment.yml
   ./setup_and_run.ps1 -CreateCondaEnv -EnvName bigdata
   ```
 - Activate the environment in PowerShell:
   ```powershell
   conda activate bigdata
   ```
 - Run the helper to install any pip requirements and run preprocessing:
   ```powershell
   ./setup_and_run.ps1 -InstallPipRequirements -RunPySparkPreprocess
   ```

If you prefer not to use Conda
 - Install packages using pip with your current Python interpreter:
   ```powershell
   ./setup_and_run.ps1 -InstallPipRequirements
   ```

Run the Notebook (optional)
 - To run the `notebooks/00_data_preprocessing.ipynb` automatically (headless), run:
   ```powershell
   ./setup_and_run.ps1 -RunNotebook
   ```
 - This will use `papermill` (installed if missing) and save an executed copy to `notebooks/00_data_preprocessing.executed.ipynb`.

Notes and Safety
 - The script tries to be conservative and avoid modifying your global environment unless `-CreateCondaEnv` is used.
 - `SPARK_HOME` validation is only a convenience check; it will print warnings for mismatches but not automatically modify the variable.
 - If the project uses a separate local Spark installation, set `SPARK_HOME` to that path before running the script.

Artifacts
 - Preprocessing results are saved under `data/processed/v1/` (train.parquet, test.parquet).
 - Results and metrics are saved under `results/` (label_map.json, combined_counts.csv, sample_index_map.csv, metrics/)

Troubleshooting
 - If `papermill` or other packages fail to install inside Windows runtime due to C extensions, create a fresh environment (Conda recommended) and re-run.
 - Check `results/deps_check.json` for dependency mismatch details from `scripts/check_deps.py`.

If you want me to: I can also create a `setup_and_run.sh` for Unix or add steps to automatically configure `SPARK_HOME` if you want — tell me which you'd prefer.
