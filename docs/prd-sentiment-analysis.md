# PRD — Sentiment Analysis Decision Support System

## 1. Title
Sentiment Analysis Decision Support System — Group Project for DSAI4205

## 2. Summary
Develop a robust decision support system that classifies business text data by sentiment. The system will demonstrate a baseline logistic regression model and evaluate improvements using multiple models (traditional ML and embeddings-based models). Visualizations and a comprehensive evaluation (with the dataset’s required split and metric) will support the conclusions.

## 3. Problem Statement
Users need an automated, high-quality way to classify text sentiment in the provided business dataset to support data-driven decisions.

## 4. Objectives / Success Criteria
- Build a reproducible baseline model (logistic regression) and report its performance on the canonical evaluation metric **macro-F1**.
- Compare and evaluate at least 5 other models (N = 5, number of group members) including both traditional models and modern embeddings-based approaches. Example models to include: Random Forest, LightGBM/XGBoost, SVM + TF-IDF, fastText, and a transformer (e.g., DistilBERT / RoBERTa). Additionally evaluate at least one semantic sentence embedding approach (e.g., SBERT or USE) and at least one rule/lexicon-based method (VADER) as complementary signals.
- Improve the baseline using techniques such as model ensembling, hyperparameter optimization, feature engineering (lexical + topic features), and embedding-based fine-tuning. Include a fallback strategy for heavy transformer training (use precomputed embeddings or smaller variants such as DistilBERT).
- Produce a final deliverable with visual data exploration, reproduction-ready Jupyter Notebook code, a 2-page Word report, and a presentation including summary metrics, visualizations, and top recommendations.
- Deliverables must use the SAME data splitting and canonical **macro-F1** evaluation metric defined by the dataset and maintain reproducibility (document seeds, environment, and runs in `requirements.txt` and `run.sh`).

Target success metrics (examples):
- Improve baseline accuracy/F1 by >= 5 percentage points (customize target depending on baseline)
- Achieve robust performance on holdout (or test) split as specified by the dataset

## 5. Scope
In scope:
- Data exploration and cleaning (text preprocessing, tokenization, handling missing values, class balancing)
- Model development: baseline logistic regression, 3+ traditional models, 2+ embedding-based models
 - Visualization: at least 5 statistical visualizations (word clouds, class distribution, feature importance, confusion matrix)
- Hyperparameter tuning (grid search or Bayesian optimization)
- An ensemble or fine-tuned model improving baseline
- Reproducible notebook and short report (2 pages)

Out of scope:
- Productionizing a real-time service or deployment (unless added as extra credit)
- Using external datasets without instructor approval

## 6. Assumptions
- The dataset is provided as a single CSV; we will create a canonical **Stratified 80/20 Split** (Seed 42) to be used by all experiments.
- N = number of group members (replace the placeholder). **Resolved value:** 5
- Timeline constraints: submission on 23 Nov 2025 23:55 HK Time.
- All team members must contribute a work distribution file for submission.
 - Dataset path: `data/stock_market_crash_2022.csv` (confirmed and copied into `data/` folder)

## 7. Users / Personas
 The dataset will provide a standardized train/test split and a single evaluation metric. If the assignment doesn't explicitly specify, we will default to **macro-F1** as the metric used for model comparison and selection.
 N = number of group members (resolved value: 5).
 Timeline constraints: submission on 23 Nov 2025 23:55 HK Time.
 All team members must contribute a work distribution file for submission.
 Compute resource availability: GPU is available for model training and fine-tuning where applicable.
## 9. Data Cleaning & Preprocessing Strategy
This project requires reproducible preprocessing that preserves the provided train/test split and produces human-readable/analysis-ready artifacts. Below is a dataset-informed cleaning strategy and acceptance criteria.

### 9.1 EDA Summary (sample/confirmed)
- Total rows: 1698
- Label distribution: 0 (575 / 33.9%), 1 (627 / 36.9%), 2 (496 / 29.2%) — roughly balanced across the three classes
- Average text length: ~150 characters (median 139), max ~448 chars
- Non-ASCII rows: 162 (~9.5%) — multilingual content present (Hindi/Arabic/Spanish/other scripts)
- Duplicate texts: few (~9 duplicates across dataset)
- Most frequent hashtags: `#stockmarketcrash` (~1008 occurrences), `#bearmarket` (~683), `#stockmarket`, `#crypto`, `#bitcoin`
- Frequent tickers: `$SPY`, `$BTC`, `$ETH`, `$TSLA`, `$QQQ`

### 9.2 Cleaning & Feature extraction steps (ordered & reproducible)
1. EDA & sanity checks
   - Confirm no missing `text` values on the train/test splits and check for duplicates.
   - Save a quick snapshot of class distribution (`results/label_map.json` and `results/combined_counts.csv`).
2. Basic normalization (safe to apply to all targets)
   - Lowercase, Unicode NFKC normalization, and unescape HTML entities.
   - Replace URLs with token `<URL>` and user handles with `<USER>` to remove PII while preserving signal.
   - Normalize currency tickers to uppercase (`$USD`, `$BTC` -> `$BTC`) and optionally map them to standardized tokens (`<TICKER>`).
   - Remove or normalize repeated whitespace and non-printable characters. Keep emojis and emoticon information as they contain sentiment clues.
3. Preservation vs. removal decisions (modeling-specific)
   - **Hashtags**: do not remove; keep them as features (either as tokens in the text or dedicated features like `hashtag_count` and `top_hashtag_flag`), since they are strong signals (e.g., `#stockmarketcrash`).
   - **Mentions** (`@user`), **Tickers** (`$TSLA`) and **Emojis**: keep as features (dedicated flags or tokenized so embeddings or TF-IDF can use them).
   - **Non-ASCII / multi-lingual text**: keep raw text and add an indicator `has_nonascii` and optionally split into rows for language-specific handling. For simple baseline work, normalize to UTF-8 and keep tokens - do not drop.
4. Tokenization & model-specific transformations
   - Classical models (SVM / TF-IDF / LogisticRegression / Tree models): use stop-word removal, lemmatization (optional), char-level and word n-gram TF-IDF.
   - Embedding models (Word2Vec / SBERT / DistilBERT): do not remove stopwords - feed raw normalized text; precompute embeddings and store them.
5. Feature engineering
   - Numeric features: text length (#words, #chars), #hashtags, #mentions, #tickers, #emoji_count, #caps_ratio.
   - Lexicon features: VADER polarity, positive/neutral/negative probability, or other lexicons.
   - Topic features: LDA topic distributions for extra context.
   - Metadata: day-of-week/hour features if available, geolocation if present (not provided here).
6. Splitting & pipeline rules
   - **Splitting Strategy**: Use **Stratified Random Split** (80% Train / 20% Test) with fixed `seed=42`. This preserves class balance, maximizing the baseline Logistic Regression's ability to learn minority classes.
   - Always fit vectorizers/embedders/Word2Vec/LDA on **training set only** and then transform both train and test using those fit artifacts.
   - Persist preprocessing pipeline to `models/pipelines/` and the processed outputs to `data/processed/v1/`.
7. Validation & QA tests
   - Assert no null or empty text rows remain unless documented (mark as `unknown_text`), and ensure label mapping exists and is complete.
   - Preserve shape: `train.count()`, `test.count()` should remain identical after processing and be reproducible with stored `seed`.
   - Validate label distribution remains consistent (allow minor difference due to filtering or deduplication; record if changed).
   - Save sample index map linking original rows and processed rows in `results/sample_index_map.csv`.

### 9.3 Artifact & logging requirements
- Processed data (parquet): `data/processed/v1/train.parquet` and `data/processed/v1/test.parquet` (versioned)
- Pipeline artifacts: `models/pipelines/cleaning_pipeline_v1/` (serialized pipeline models & vectorizers)
- Precomputed embeddings: `models/embeddings/sbert_v1/`, `models/embeddings/use_v1/` (if used)
- Label map: `results/label_map.json`
- Preprocessing logs: `results/preprocessing-logs/preprocessing_v1.log`

### 9.4 Acceptance criteria for data cleaning
- All processing is reproducible by running `scripts/preprocess.py` (or `notebooks/00_data_preprocessing.ipynb`) with documented `seed` and results match saved artifacts.
- No null/empty text rows remain (unless intentionally flagged and recorded).
- Label mapping and class distribution saved and verified; total row counts unchanged after processing (except intentional filters, with a summary report saved).
- Top 10 hashtags, mentions, tickers and presence of non-ASCII content verified post-cleaning and recorded.
- All preprocessing steps must be represented in the project's README and PRD.

## 8. Requirements
Functional Requirements (FR):
2. FR-02: Include a baseline logistic regression model and at least 5 other models.
3. FR-03: Present performance results on test set only using the supplied evaluation metric.
4. FR-04: Visualize data using at least 5 charts/statistics.
5. FR-05: Deliver a 2-page Word report summarizing approach and results.
 Product Owner / PM: Name1 — coordinates tasks, ensures requirements are satisfied; PRD owner
 Data Engineer: Name2 — data loading, preprocessing, and baseline model implementation
 Architect / Model Lead: architech — embedding strategy and BERT fine-tuning
 ML Engineer: Name3 — gradient boosting, model ensembling, hyperparameter tuning
 Analyst: Name4 — visualizations, performance analysis, evaluation reporting
 QA/Reviewer: Name5 — final checks, reproducibility validation, and submission readiness
3. NFR-03: Clear documentation and comments in the notebook
4. NFR-04: Use standardized evaluation metric and split per dataset (no deviation)
 Confirm dataset path (currently unspecified) — defaulting to `unspecified`, using **macro-F1** as evaluation metric by default
 Fill exact team member information and student IDs; placeholders created for missing members
 Confirm compute setup (GPU: yes)
 Option: Run an interactive brainstorming session (workflow: `brainstorming`) to generate creative modeling approaches and novel improvements
   - Basic cleaning: casing, punctuation removal, stopwords, simple normalization
   - Tokenization strategy: experiment with bag-of-words, TF-IDF and embeddings
 1. Notebook: Runs end-to-end and reproduces reported test-set macro-F1 scores using documented random seeds and same data split.
 2. Report: 2 pages summarizing approach, key metrics, best model, and top 3 recommendations.
 3. Slides: 8–10 slides demonstrating the problem, approach, results, and suggested actions.
 4. Work Distribution: A per-student Word file indicating contribution percentages.

2. Baseline Model (Logistic Regression)
   - Feature extraction: TF-IDF or n-grams (PySpark HashingTF/IDF in baseline)
   - Evaluate baseline and record metric

3. Comparative Models
   - Traditional: Decision Tree, Random Forest, Gradient Boosting (e.g., XGBoost/LightGBM)
   - Embedding-based: Word2Vec + simple classifier, pre-trained BERT fine-tuning
   - At least 5 additional models across these categories

   - Extended / Optional Models (Recommended Experiments):
     - SVM + TF-IDF (linear but robust on short noisy text)
     - fastText (super-fast embeddings & classifier built-in; good for social media text)
     - Sentence-BERT (SBERT) or other sentence-transformer embeddings + simple classifier (semantic embeddings)
     - Universal Sentence Encoder (USE) + classifier — lightweight semantic embedding from TF2 for short sentences
     - DistilBERT / RoBERTa (efficient transformer alternatives to BERT)
     - mBERT or XLM-R (for multilingual tweets or mixed-language samples)
     - VADER / lexicon or rule-based features to complement ML models (lexical sentiment scores, emoji analysis)
     - Doc2Vec (useful for longer texts or aggregated posts)
     - Topic modeling features (LDA topic distribution) as auxiliary context features
     - Ensemble / stacking strategies combining complementary models above
 GPU available: Yes (use for BERT and heavy model fine-tuning)
 Create a `requirements.txt` with pinned library versions for reproducibility
 Notebook must be runnable on a standard Conda/Pip environment (documented in the repo)
 Recommended extra libraries for extended experiments:
 - `sentence-transformers` (SBERT)
 - `fasttext` (Facebook fastText) or `gensim` for fastText embedding wrapper
 - `tensorflow` or `tensorflow_hub` for USE
 - `transformers` / `huggingface` (DistilBERT / RoBERTa / mBERT / XLM-R)
 - `nltk` / `vaderSentiment` for lexicon and VADER rule-based sentiment
 - `gensim` for Doc2Vec, LDA topic modeling

4. Improvements to Baseline
 Use this checklist before final submission
- [ ] Notebook reproduces reported metrics using documented seeds and provided split
- [ ] All experiments use the same evaluation metric (macro-F1) and given split
- [ ] Visualizations confirm class distributions and model results (confusion matrix, PR curve)
- [ ] 2-page report prepared and uploaded (Word)
- [ ] Slides prepared and ready for presentation (PowerPoint)
- [ ] Work distribution file uploaded for each student
   - Hyperparameter tuning: Randomized search or tuning approaches using Spark MLlib where possible (or local GridSearch for small models)
   - Ensemble models or stacking
   - BERT/GPT embeddings with fine-tuning to maximize performance

5. Visualization & Reporting
   - Provide at least 5 visualizations: class distribution, word distributions, confusion matrices, AUC curves or precision/recall as applicable
   - Compile final results and insights into the report and presentation

## 10. Milestones & Timeline (based on final submission: 23 Nov 2025)
This plan assumes 4 days remaining (Nov 19–22 + final polishing on 23 Nov):
- Day 0 (Nov 19): Project kickoff, confirm dataset and roles, data exploration, select methods
- Day 1 (Nov 20): Implement baseline & quick evaluation; preliminary data visualizations
- Day 2 (Nov 21): Implement additional models; start hyperparameter tuning
- Day 3 (Nov 22): Run embeddings-based models (BERT), ensemble; analyze results
- Day 4 (Nov 23): Finalize Notebook, write 2-page report, prepare slides, internal review + submit

## 11. Evaluation / Metrics
- Use **the provided evaluation metric** in the dataset (if unspecified: report both accuracy and macro-F1)
- Compare models on: test-set metric (primary), precision, recall, confusion matrix, and runtime
- Provide clear justification for final model selection

## 12. Deliverables
1. Jupyter Notebook with all code and results (required) — `Notebook.ipynb`
2. Written Report (MS Word, 2 pages max) — summarize approach, top findings, and decisions
3. PowerPoint slides for presentation — highlight the best model and key visualizations
4. Work Distribution Document for each member (required for marking)

## 13. Risks & Mitigations
- Risk: Not enough time to fine-tune BERT properly → Mitigation: Use a pre-trained BERT with limited fine-tuning epochs and strong data augmentation.
- Risk: Class imbalance → Mitigation: Use weighted loss, resampling techniques, and clear reporting of per-class metrics.
- Risk: Data leakage due to wrong splits → Mitigation: Strictly use the provided split and always record dataset sources.

## 14. Team & Responsibilities (Sample Template)
- Product Owner / PM: <Name> — coordinates tasks, ensures requirements are satisfied
- Data Engineer: <Name> — data loading and cleaning
- ML Engineer: <Name> — model training and evaluation
- Analyst: <Name> — visualizations and result presentation
- QA/Reviewer: <Name> — compiling final report and slides

## 15. Additional Notes & Next Steps
- Confirm N (team size) so we can finalize the number of comparative models and visual stats
- Confirm dataset path and the evaluation metrics if the assignment provides an explicit metric
- Fill the team member names and ownership
- Option: Run an interactive brainstorming session (workflow: `brainstorming`) to generate creative modeling approaches and novel improvements

## Where to find the files
 - PRD: `docs/prd-sentiment-analysis.md` (this file)
 - Brainstorming output: `docs/brainstorming-session-results-2025-11-19.md` (contains role-playing session)
 - Action items / tasks: `docs/action_items.md` (task assignments and deadlines)
 - Baseline Notebook (PySpark): `notebooks/Notebook_pyspark.ipynb` (baseline scaffold using PySpark ML)
 - SVM + TF-IDF experiment: `notebooks/02_svm.ipynb`
 - fastText experiment: `notebooks/03_fasttext.ipynb`
 - SBERT/USE experiment: `notebooks/04_sentence_transformers.ipynb`
 - DistilBERT / RoBERTa experiment: `notebooks/05_distilbert.ipynb`
 - VADER / lexicon features: `notebooks/06_vader_features.ipynb`
 - Topic modeling LDA features: `notebooks/07_topic_modeling.ipynb`
 - Ensemble / Stacking: `notebooks/08_ensemble.ipynb`
 - Original Notebook (sklearn): `notebooks/Notebook.ipynb` (kept for legacy reference)

If you want me to generate a `requirements.txt` or start more detailed experiment notebooks for specific models, say `create-reqs` or `scaffold-models`.

## Quick Evaluation Guide (Notebook snippet)
Include the following in the Notebook's evaluation section:
1. Ensure the dataset's provided test set is used directly for final evaluation (do not leak data)
2. Compute the `macro-F1` using sklearn's `f1_score(y_true, y_pred, average='macro')`
3. Generate confusion matrix and per-class precision/recall
4. Save final model predictions and all experiment metrics to `results/` for reproducibility

---

**Prepared for:** DSAI4205 — Big Data Analytics Group Project
**Prepared on:** 2025-11-19
**PRD Owner:** [Replace with your name]
