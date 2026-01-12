# Action Items — Sentiment Analysis Project

This document assigns clear tasks, owners, and deadlines that came out of the Role Playing session.

| Phase | ID | Task | Owner | Due | Status | Notes |
|-------|----|------|-------|-----|--------|-------|
| **1. Data** | A1 | Confirm dataset path and upload sample to repo; create `DATA.md` with schema and sample preview | Name2 (Data Engineer) | 2025-11-20 (EOD) | Done | Dataset copied to `data/stock_market_crash_2022.csv`. |
| **1. Data** | A1.1 | **Execute Data Preprocessing Workflow**: Run `scripts/preprocess_pyspark.py` to generate cleaned parquet files, features, and precomputed embeddings using PySpark. | Name2 (Data Engineer) | 2025-11-20 (EOD) | Done | Completed with `.venv310` Python & `PYSPARK_PYTHON` pointing to venv; artifacts saved in `data/processed/v1/` (train.parquet & test.parquet), seed=42. See `results/label_map.json`, `results/combined_counts.csv`, and `results/sample_index_map.csv`. |
| **1. Data** | A1.2 | **Create Canonical Stratified Split**: Generate stratified 80% train / 20% test split with `seed=42` and save `train.parquet` / `test.parquet` to `data/processed/v1/`. | Name2 (Data Engineer) | 2025-11-20 (EOD) | Done | Created `data/processed/v1/train.parquet` (1335 rows) and `data/processed/v1/test.parquet` (351 rows) using seed=42. Persisted `results/sample_index_map.csv`. |
| **2. Baseline** | A2 | Implement baseline logistic regression pipeline (TF-IDF + logistic) using PySpark ML (Notebook: `notebooks/00_data_preprocessing.ipynb`) with **default parameters** | Name3 (ML Engineer) | 2025-11-20 (EOD) | Done | Baseline implemented and executed in `notebooks/00_data_preprocessing.ipynb`; artifacts saved to `models/pipelines/baseline_logreg_default` and `results/metrics/baseline_logreg_default.json` (accuracy/macro/weighted F1 & confusion CSV). |
| **2. Baseline** | A2.1 | **Improve Baseline**: Tune Logistic Regression hyperparameters (regParam, elasticNetParam) to beat default baseline | Name3 (ML Engineer) | 2025-11-21 | Done | TrainValidationSplit-based tuning implemented in `notebooks/00_data_preprocessing.ipynb`; tuned pipeline saved to `models/pipelines/baseline_logreg_tuned` and tuned metrics to `results/metrics/baseline_logreg_tuned.json`. |
| **2. Baseline** | A8 | Implement SVM with TF-IDF pipeline and compare with baseline | Name3 (ML Engineer) | 2025-11-21 | Done | SVM pipeline added in `notebooks/00_data_preprocessing.ipynb` (TF-IDF -> LinearSVC with OneVsRest for multiclass). Model saved to `models/pipelines/svm_tfidf_default` and metrics to `results/metrics/svm_tfidf_default.json`. |
| **2. Baseline** | A12 | Add VADER / Lexicon features + emoji processing as feature augmentation and compare impact | Name2 (Data Engineer) | 2025-11-21 | Done | Implemented in `notebooks/00_data_preprocessing.ipynb` — TF-IDF + numeric VADER/emoji features (VectorAssembler) pipeline trained & saved to `models/pipelines/baseline_vader_features_default` and metrics to `results/metrics/baseline_vader_features_default.json`. |
| **3. Models** | A3 | Set up traditional model scaffolding: RandomForest, LightGBM/XGBoost; add hyperparameter tuning pipeline | Name3 (ML Engineer) | 2025-11-21 | Done | RandomForest TF-IDF scaffolding implemented and tuned in `notebooks/00_data_preprocessing.ipynb`. Baseline & tuned models saved to `models/pipelines/randomforest_tfidf_default` and `models/pipelines/randomforest_tfidf_tuned`. Metrics saved to `results/metrics/` and class-level comparison/visuals to `results/metrics/plots/confusion_baseline_vs_rf_tuned.png` and `results/metrics/comparison_baseline_rf_tuned_class_metrics.json`. Next: Add LightGBM/XGBoost or ensemble experiments. |
| **3. Models** | A9 | Implement fastText classification & embeddings experiments | architech (Architect) | 2025-11-21 | Done | Implemented a gensim fastText experiment in `notebooks/00_data_preprocessing.ipynb` as an additional cell (A9). Trained embeddings & classifier saved to `models/pipelines/fasttext_default` (gensim model) and `results/metrics/fasttext_default.json` + `fasttext_confusion_default.csv`. |
| **3. Models** | A10 | Implement Semantic Embeddings (SBERT/USE) + classifier experiments | Name3 (ML Engineer) | 2025-11-21 | TODO | Notebook: `notebooks/04_sentence_transformers.ipynb` — include multilingual tests if needed. |
| **3. Models** | A11 | Implement DistilBERT / RoBERTa fine-tuning and compare with BERT baseline | architech (Architect) | 2025-11-22 | TODO | Notebook: `notebooks/05_distilbert.ipynb` — include fallback to feature-extraction if GPU limited. |
| **3. Models** | A4 | Prepare BERT fine-tuning plan, plus a fallback to precomputed sentence-transformer embeddings if needed | architech (Architect) | 2025-11-21 | TODO | Includes expected resource usage & epoch caps. |
| **4. Advanced** | A13 | Topic modeling (LDA) to produce topic distribution features and use them in models | Name4 (Analyst) | 2025-11-22 | TODO | Notebook: `notebooks/07_topic_modeling.ipynb` — document topic interpretation. |
| **4. Advanced** | A14 | Create ensemble / stacked model strategy combining top-performing methods and validate improvements | Name3 (ML Engineer) | 2025-11-22 | TODO | Notebook: `notebooks/08_ensemble.ipynb` — include stacking and model-averaging. |
| **5. Report** | A5 | Create the visualization templates and generate sample figures: class distribution, word cloud, confusion matrix, PR curve, and feature importance | Name4 (Analyst) | 2025-11-21 | TODO | Add example code snippets & templates to `report-assets/`. |
| **5. Report** | A6 | Add reproducibility environment: `requirements.txt`, `run.sh` for notebook, and a final checklist for submission readiness | Name5 (QA/Reviewer) | 2025-11-22 | TODO | Include random seeds & environment reproducibility instructions. |
| **5. Report** | A7 | Finalize Notebook (combine all experiments), create 2-page Word report draft, and prepare slides | Name1 (Product Owner) | 2025-11-23 (EOD) | TODO | PM consolidates ownership and checks acceptance criteria. |
| **5. Report** | A15 | **Create Work Distribution Document**: Compile contribution percentages and task ownership for all members. | Name1 (Product Owner) | 2025-11-23 (EOD) | TODO | Required for submission. |

## How to mark progress
- Change `Status` to `In Progress` or `Done` as you execute.  
- Add PR/commit links to the `Notes` column to provide traceability.  
- For assistance, open an issue and @ mention the assigned owner. 

---

**Prepared:** 2025-11-19  
**PRD Owner:** Name1
