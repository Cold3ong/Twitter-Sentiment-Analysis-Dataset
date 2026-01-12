#!/usr/bin/env python3
"""
Preprocess script for Sentiment Analysis project.
1) Runs cleaning & feature extraction per PRD
2) Creates canonical stratified 80/20 split (seed=42)
3) Saves artifacts: train/test parquet, label_map.json, combined_counts.csv, sample_index_map.csv
"""
import argparse
import json
import logging
import os
import re
import sys
from pathlib import Path

import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer


LOG = logging.getLogger("preprocess")


def setup_logging():
    logging.basicConfig(format="%(asctime)s %(levelname)s: %(message)s", level=logging.INFO)


URL_RE = re.compile(r"https?://\S+|www\.\S+")
MENTION_RE = re.compile(r"@\w+")
TICKER_RE = re.compile(r"\$[A-Za-z]+")
HTML_ENTITIES_RE = re.compile(r"&[A-Za-z]+;")


def normalize_text(s: str) -> str:
    if pd.isna(s):
        return ""
    # Unicode normalize (NFKC)
    s = str(s)
    try:
        import unicodedata

        s = unicodedata.normalize("NFKC", s)
    except Exception:
        pass
    # lower-case
    s = s.strip()
    # we keep hashtags, mentions, tickers and emojis
    # replace URLs
    s = URL_RE.sub(" <URL> ", s)
    # replace mentions
    s = MENTION_RE.sub(" <USER> ", s)
    # normalize tickers -> <TICKER>
    s = TICKER_RE.sub(lambda m: " <TICKER> ", s)
    # collapse repeated whitespace
    s = re.sub(r"\s+", " ", s)
    return s.strip()


def features_from_text(text: str) -> dict:
    analyzer = SentimentIntensityAnalyzer()
    s = text or ""
    # basic counts
    chars = len(s)
    words = len(s.split())
    hashtag_count = s.count('#')
    mention_count = bool(MENTION_RE.search(s))
    mention_count = len(MENTION_RE.findall(s))
    ticker_count = len(TICKER_RE.findall(s))
    caps_ratio = sum(1 for c in s if c.isupper()) / (chars + 1e-9)
    # emoji count approximate: unicode symbols outside BMP or specific ranges
    emoji_count = sum(1 for c in s if ord(c) > 10000)
    has_nonascii = any(ord(c) > 127 for c in s)
    # sentiment lexicon
    vader = analyzer.polarity_scores(s)
    return dict(
        chars=chars,
        words=words,
        hashtag_count=hashtag_count,
        mention_count=mention_count,
        ticker_count=ticker_count,
        caps_ratio=caps_ratio,
        emoji_count=emoji_count,
        has_nonascii=has_nonascii,
        vader_compound=vader.get('compound', 0.0),
        vader_pos=vader.get('pos', 0.0),
        vader_neu=vader.get('neu', 0.0),
        vader_neg=vader.get('neg', 0.0),
    )


def run_preprocess(infile: str, out_dir: str, seed: int = 42, test_size: float = 0.2):
    LOG.info("Loading data: %s", infile)
    df = pd.read_csv(infile)
    # Expect columns 'text' and 'text_sentiment' (label)
    if 'text_sentiment' not in df.columns:
        LOG.error("Missing 'text_sentiment' label column. Found: %s", df.columns.tolist())
        sys.exit(1)
    # renaming to consistent column names
    df = df.rename(columns={df.columns[0]: 'text', 'text_sentiment': 'label'}) if df.columns[0] != 'text' else df

    LOG.info("Running EDA & cleaning functions")
    df['clean_text'] = df['text'].astype(str).apply(normalize_text)
    # deduplicate; preserve first occurrence
    before = len(df)
    df = df.drop_duplicates(subset=['clean_text'])
    after = len(df)
    if after < before:
        LOG.info("Dropped %d duplicate cleaned rows", before - after)

    # Add features
    feats = df['clean_text'].apply(features_from_text).apply(pd.Series)
    df = pd.concat([df.reset_index(drop=True), feats.reset_index(drop=True)], axis=1)

    # Create results directories
    out_dir_p = Path(out_dir)
    processed_dir = out_dir_p / 'v1'
    processed_dir.mkdir(parents=True, exist_ok=True)
    results_dir = Path('results') / 'preprocessing-logs'
    results_dir.mkdir(parents=True, exist_ok=True)

    # Save label map and counts
    label_map = df['label'].value_counts().to_dict()
    with open(Path('results') / 'label_map.json', 'w', encoding='utf-8') as f:
        json.dump(label_map, f, indent=2)
    df[['label']].value_counts().to_frame('count').reset_index().to_csv(Path('results') / 'combined_counts.csv', index=False)

    # Stratified split
    X = df
    y = df['label']
    LOG.info('Stratified splitting with seed=%d, test_size=%.2f', seed, test_size)
    train_idx, test_idx = train_test_split(df.index, test_size=test_size, random_state=seed, stratify=y)
    train_df = df.loc[train_idx].reset_index(drop=True)
    test_df = df.loc[test_idx].reset_index(drop=True)

    # Save mapping and artifacts
    sample_map = pd.DataFrame({'orig_index': df.index, 'clean_index': df.reset_index().index, 'label': df['label']})
    sample_map.to_csv(Path('results') / 'sample_index_map.csv', index=False)

    train_out = processed_dir / 'train.parquet'
    test_out = processed_dir / 'test.parquet'
    LOG.info('Writing train to %s, test to %s', train_out, test_out)
    train_df.to_parquet(train_out, index=False)
    test_df.to_parquet(test_out, index=False)

    LOG.info('Preprocessing complete')


def parse_cli():
    p = argparse.ArgumentParser()
    p.add_argument('--input', '-i', default='data/stock_market_crash_2022.csv')
    p.add_argument('--out-dir', '-o', default='data/processed')
    p.add_argument('--seed', type=int, default=42)
    p.add_argument('--test-size', type=float, default=0.2)
    return p.parse_args()


def main():
    setup_logging()
    args = parse_cli()
    run_preprocess(args.input, args.out_dir, seed=args.seed, test_size=args.test_size)


if __name__ == '__main__':
    main()
