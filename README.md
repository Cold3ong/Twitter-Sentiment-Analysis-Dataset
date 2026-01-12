# Twitter Sentiment Analysis — Big Data Group Project

## Overview
This project implements a scalable sentiment analysis pipeline for Twitter data using PySpark and machine learning. The goal is to classify tweet sentiment and compare multiple models, providing reproducible results and clear evaluation metrics. The project is designed for the DSAI4205 - Big Data Analytics course (Instructor: Dr. Ken FONG).

## Features
- End-to-end pipeline: data preprocessing, feature extraction, model training, and evaluation
- Baseline and advanced models (Logistic Regression, Random Forest, SVM, and more)
- Reproducible environment setup (Conda, pip, PowerShell scripts)
- Artifacts and results saved for reproducibility and analysis
- Modular scripts and Jupyter notebook for exploration

## Project Structure

```
├── data/                  # Raw and processed data (input CSV, train/test splits)
├── models/                # Saved ML pipelines and embeddings
├── notebooks/             # Jupyter notebooks (main: 00_data_preprocessing.ipynb)
├── results/               # Metrics, figures, label maps, logs
├── scripts/               # Python and PowerShell scripts for automation
├── environment.yml        # Conda environment definition
├── requirements.txt       # Python package requirements
├── setup_and_run.ps1      # Main setup and workflow script (PowerShell)
├── README.md              # Project overview (this file)
├── README_SETUP.md        # Detailed setup instructions
└── ...
```

## Setup & Installation

### Prerequisites
- Windows PowerShell (pwsh.exe recommended)
- Python 3.10+
- (Recommended) Conda (Miniconda/Anaconda)
- Optional: Local Spark distribution (or use PySpark's built-in)

### Quick Start
1. **Clone the repository** and open PowerShell at the repo root.
2. **Create Conda environment** (recommended):
	 ```powershell
	 ./setup_and_run.ps1 -CreateCondaEnv -EnvName bigdata
	 conda activate bigdata
	 ```
3. **Install pip requirements and run preprocessing:**
	 ```powershell
	 ./setup_and_run.ps1 -InstallPipRequirements -RunPySparkPreprocess
	 ```
4. **(Optional) Run the notebook automatically:**
	 ```powershell
	 ./setup_and_run.ps1 -RunNotebook
	 ```
5. **Artifacts and results** will be saved under `data/processed/v1/` and `results/`.

For more details and troubleshooting, see [README_SETUP.md](README_SETUP.md).

## Data & Preprocessing
- **Input:** `data/stock_market_crash_2022.csv` (Twitter dataset)
- **Preprocessing:**
	- Cleans and normalizes text (NFKC, HTML unescape, URL/handle/ticker normalization)
	- Feature extraction: hashtags, mentions, tickers, emojis, text length, VADER sentiment
	- Tokenization and vectorization (TF-IDF, embeddings)
	- Train/test split and label mapping
- **Artifacts:**
	- Processed data: `data/processed/v1/train.parquet`, `test.parquet`
	- Pipelines: `models/pipelines/`
	- Metrics/results: `results/metrics/`, `results/label_map.json`, etc.

## Modeling & Evaluation
- **Baseline:** Logistic Regression (PySpark ML)
- **Additional models:** Random Forest, SVM, VADER features, and more
- **Evaluation:** Macro-F1 and confusion matrices on test set
- **Results:**
	- Metrics and confusion matrices in `results/metrics/`
	- Model artifacts in `models/pipelines/`

## Usage

### End-to-End Pipeline (PowerShell)
```powershell
./scripts/run_all.ps1
```
This script runs preprocessing and baseline model training, saving all outputs to the appropriate folders.

### Manual Steps
- Run preprocessing: `python scripts/preprocess_pyspark.py --input data/stock_market_crash_2022.csv --out-dir data/processed`
- Train baseline: `python scripts/run_baseline_pyspark.py --train data/processed/v1/train.parquet --test data/processed/v1/test.parquet --out-dir .`
- Explore and extend in `notebooks/00_data_preprocessing.ipynb`

## Key Files & Scripts
- `setup_and_run.ps1`: Main setup and workflow script
- `scripts/preprocess_pyspark.py`: PySpark preprocessing
- `scripts/run_baseline_pyspark.py`: Baseline model training
- `notebooks/00_data_preprocessing.ipynb`: Full EDA, preprocessing, and modeling notebook
- `README_SETUP.md`: Detailed environment and troubleshooting guide

## Team & Credits
- **Instructor:** Dr. Ken FONG
- **Course:** DSAI4205 - Big Data Analytics
- **Team Roles:**
	- Wong Keng Wa Kovey
    ....

## License
For academic use only. See course policies for details.
"# Twitter-Sentiment-Analysis-Dataset" 
