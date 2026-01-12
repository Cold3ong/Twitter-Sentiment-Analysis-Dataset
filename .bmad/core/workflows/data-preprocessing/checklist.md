# Preprocessing Checklist

- [ ] Verify dataset `data/stock_market_crash_2022.csv` path and header
- [ ] EDA performed and counts logged (combined_counts.csv)
- [ ] Normalization applied and logged
- [ ] Hashtag, mention, ticker, emoji features created
- [ ] TF-IDF pipeline fitted on train set only and saved
- [ ] SBERT embeddings precomputed if GPU available
- [ ] LDA topics fitted on train and added to features (optional)
- [ ] All artifacts (parquet, pipelines, embeddings) persisted with checksums
- [ ] QA tests (no empty text, counts preserved) passed
- [ ] PRD updated and saved as `docs/prd-sentiment-analysis_v2.md`
- [ ] Results and figures saved to `results/` and `results/figures/`

