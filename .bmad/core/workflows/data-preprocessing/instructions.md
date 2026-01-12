# Data Preprocessing Workflow Instructions

This workflow will guide the execution of reproducible dataset EDA and preprocessing for `data/stock_market_crash_2022.csv`.

Steps:
1. Confirm dataset path and schema.
2. Run EDA: label distribution, missing values, duplicates, text lengths, top hashtags/mentions/tickers and non-ASCII counts.
3. Design and run normalization: NFKC, HTML unescape, URL replacement, handle replacement, ticker normalization, and whitespace collapse.
4. Extract features: counts (hashtags, mentions, tickers, emojis), lengths, caps ratio; compute lexicon features (VADER) if available.
5. Tokenization and transform: implement separate classical pipeline (TF-IDF) and embedding precompute pipeline (SBERT/USE), ensure fitted only on training set.
6. Optional: perform LDA topic modeling and include topic distributions as features.
7. Persist processed datasets to `data/processed/v1/`, pipelines to `models/pipelines/cleaning_pipeline_v1/`, and embeddings to `models/embeddings/*`.
8. Run QA checks: no nulls, counts preserved, label mapping saved, reproducibility report saved in `results`.
9. Update PRD: section 9 with EDA and final preprocessing choices, create `docs/prd-sentiment-analysis_v2.md`.

Notes:
- Avoid using test set information when fitting transformers.
- Keep all code in `notebooks/00_data_preprocessing.ipynb` and `scripts/preprocess.py` or equivalent for reproducibility.
