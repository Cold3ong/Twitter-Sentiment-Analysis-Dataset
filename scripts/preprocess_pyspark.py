#!/usr/bin/env python3
"""
PySpark-based preprocessing script for the project.

Features:
- Read CSV into Spark DataFrame with robust CSV options
- Clean text (NFKC, lowercasing, URL/user/ticker replacement) with a Spark UDF
- Deduplicate by cleaned text
- Extract features (counts, VADER scores) using pandas UDF
- Create stratified 80/20 split by label using `sampleBy` and save Parquet
- Save metadata artifacts to `results/` per PRD
"""
from __future__ import annotations

import argparse
import json
import logging
import os
from pathlib import Path

import pandas as pd
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, lit, pandas_udf
from pyspark.sql.functions import PandasUDFType
from pyspark.sql.types import StructType, StructField, StringType, IntegerType, DoubleType, BooleanType

LOG = logging.getLogger("preprocess_pyspark")


def init_spark(app_name: str = "preprocess") -> SparkSession:
    from pyspark.sql import SparkSession

    spark = (
        SparkSession.builder.appName(app_name)
        .config("spark.sql.shuffle.partitions", "8")
        .getOrCreate()
    )
    return spark


def clean_text_py(s: pd.Series) -> pd.Series:
    import re
    import unicodedata

    URL_RE = re.compile(r"https?://\S+|www\.\S+")
    MENTION_RE = re.compile(r"@\w+")
    TICKER_RE = re.compile(r"\$[A-Za-z]+")

    def norm(x: str) -> str:
        if pd.isna(x):
            return ""
        x = str(x)
        try:
            x = unicodedata.normalize("NFKC", x)
        except Exception:
            pass
        x = URL_RE.sub(" <URL> ", x)
        x = MENTION_RE.sub(" <USER> ", x)
        x = TICKER_RE.sub(" <TICKER> ", x)
        x = re.sub(r"\s+", " ", x)
        return x.strip()

    return s.apply(norm)


def features_py(s: pd.Series) -> pd.DataFrame:
    import re
    from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer

    vader = SentimentIntensityAnalyzer()

    def compute(row: str):
        if pd.isna(row):
            row = ""
        char_count = len(row)
        word_count = len(row.split())
        hashtag_count = row.count('#')
        mention_count = len(re.findall(r"@\w+", row))
        ticker_count = len(re.findall(r"\$[A-Za-z]+", row))
        caps_ratio = sum(1 for c in row if c.isupper()) / (chars + 1e-9)
        emoji_count = sum(1 for c in row if ord(c) > 10000)
        has_nonascii = any(ord(c) > 127 for c in row)
        vader_scores = vader.polarity_scores(row)
        return (
            char_count,
            word_count,
            hashtag_count,
            mention_count,
            ticker_count,
            caps_ratio,
            emoji_count,
            has_nonascii,
            vader_scores.get("compound", 0.0),
            vader_scores.get("pos", 0.0),
            vader_scores.get("neu", 0.0),
            vader_scores.get("neg", 0.0),
        )

    df = s.apply(compute)
    return pd.DataFrame(df.tolist(), columns=[
        'char_count','word_count','hashtag_count','mention_count','ticker_count','caps_ratio',
        'emoji_count','has_nonascii','vader_compound','vader_pos','vader_neu','vader_neg'
    ])


def run_preprocess_spark(csv_path: str, out_dir: str, seed: int = 42, test_size: float = 0.2):
    spark = init_spark("preprocess-pyspark")
    LOG.info("Reading CSV from %s", csv_path)
    df = spark.read.options(header=True, multiLine=True, escape='"').csv(csv_path)

    # ensure consistent column names
    cols = df.columns
    # Preserve text_sentiment column; also create 'label' for ML if needed
    if 'text_sentiment' not in cols and 'label' in cols:
        # create a text_sentiment column from label if missing
        df = df.withColumnRenamed('label', 'text_sentiment')
    if cols[0] != 'text':
        df = df.withColumnRenamed(cols[0], 'text')

    # Clean text (pandas UDF vectorized)
    # wrap pandas UDFs using decorator with explicit return types to satisfy Spark's signature checks
    @pandas_udf(StringType())
    def clean_udf(s):
        return clean_text_py(s)

    # keep naming consistent with the notebook: `clean_text_sample`
    df = df.withColumn('clean_text_sample', clean_udf(col('text')))

    # Deduplicate
    before = df.count()
    df = df.dropDuplicates(['clean_text_sample'])
    after = df.count()
    LOG.info('Dropped %d duplicates', before - after)

    # Extract features via pandas_udf returning a struct
    def features_schema():
        return StructType([
            StructField('char_count', IntegerType()),
            StructField('word_count', IntegerType()),
            StructField('hashtag_count', IntegerType()),
            StructField('mention_count', IntegerType()),
            StructField('ticker_count', IntegerType()),
            StructField('caps_ratio', DoubleType()),
            StructField('emoji_count', IntegerType()),
            StructField('has_nonascii', BooleanType()),
            StructField('vader_compound', DoubleType()),
            StructField('vader_pos', DoubleType()),
            StructField('vader_neu', DoubleType()),
            StructField('vader_neg', DoubleType()),
        ])

    @pandas_udf(features_schema())
    def feats_udf(s):
        return features_py(s)

    df_feats = df.withColumn('features_struct', feats_udf(col('clean_text_sample')))
    # expand struct to columns
    for f in features_schema().fieldNames():
        df_feats = df_feats.withColumn(f, col('features_struct.' + f))
    df = df_feats.drop('features_struct')

    # Save label_map and combined_counts
    # Maintain label/label counts using the original `text_sentiment` column
    if 'text_sentiment' in df.columns:
        label_counts = df.groupBy('text_sentiment').count().toPandas().set_index('text_sentiment')['count'].to_dict()
    elif 'label' in df.columns:
        label_counts = df.groupBy('label').count().toPandas().set_index('label')['count'].to_dict()
    else:
        label_counts = {}
    results_dir = Path('results')
    results_dir.mkdir(parents=True, exist_ok=True)
    with open(results_dir / 'label_map.json', 'w', encoding='utf-8') as f:
        json.dump(label_counts, f, indent=2)
    df.groupBy('label').count().orderBy('label').toPandas().to_csv(results_dir / 'combined_counts.csv', index=False)

    # Stratified split - sampleBy for test set
    # For stratified sampling, create a deterministic integer label column for stratify (use 'label')
    if 'label' not in df.columns and 'text_sentiment' in df.columns:
        df = df.withColumn('label', col('text_sentiment').cast('int'))
    labels = [int(r['label']) for r in df.select('label').distinct().collect()]
    fractions = {lab: test_size for lab in labels}
    sample_df = df.stat.sampleBy('label', fractions, seed)
    # Compute test index by unique id; add monotonically_increasing_id
    from pyspark.sql.functions import monotonically_increasing_id
    df_idx = df.withColumn('_idx', monotonically_increasing_id())
    test_with_idx = sample_df.withColumn('_idx', monotonically_increasing_id())

    # better approach: use join
    test_idx = test_with_idx.select('_idx').rdd.flatMap(lambda x: x).collect()
    # But we may prefer using a left_anti join to get train
    test_df = df.join(sample_df.select('clean_text_sample'), on='clean_text_sample', how='inner')
    train_df = df.join(sample_df.select('clean_text_sample'), on='clean_text_sample', how='left_anti')

    # Save sample index map (store monotonically_increasing_id for reproducibility)
    idx_df = df.withColumn('_orig_index', monotonically_increasing_id())
    # prefer text_sentiment if present
    if 'text_sentiment' in df.columns:
        idx_df.select('_orig_index', 'text', 'clean_text_sample', 'text_sentiment').toPandas().to_csv(results_dir / 'sample_index_map.csv', index=False)
    else:
        idx_df.select('_orig_index', 'text', 'clean_text_sample', 'label').toPandas().to_csv(results_dir / 'sample_index_map.csv', index=False)

    # Persist parquet outputs
    processed_dir = Path(out_dir) / 'v1'
    processed_dir.mkdir(parents=True, exist_ok=True)
    # Save selected columns following the notebook's conventions
    columns_to_save = ['text', 'text_sentiment', 'clean_text_sample', 'hashtag_count', 'mention_count', 'ticker_count', 'emoji_count']
    # rename chars/words to char_count/word_count
    if 'char_count' not in df.columns and 'chars' in df.columns:
        df = df.withColumnRenamed('chars', 'char_count')
    if 'word_count' not in df.columns and 'words' in df.columns:
        df = df.withColumnRenamed('words', 'word_count')
    columns_to_save += ['char_count', 'word_count', 'vader_compound', 'caps_ratio']
    # include lda topics if present
    if 'lda_topics' in df.columns:
        columns_to_save.append('lda_topics')
    train_df.select(*columns_to_save).write.mode('overwrite').parquet(str(processed_dir / 'train.parquet'))
    test_df.select(*columns_to_save).write.mode('overwrite').parquet(str(processed_dir / 'test.parquet'))

    LOG.info('Saved train.parquet and test.parquet')
    spark.stop()


def parse_cli():
    p = argparse.ArgumentParser()
    p.add_argument('--input', '-i', default='data/stock_market_crash_2022.csv')
    p.add_argument('--out-dir', '-o', default='data/processed')
    p.add_argument('--seed', type=int, default=42)
    p.add_argument('--test-size', type=float, default=0.2)
    return p.parse_args()


def main():
    logging.basicConfig(format='%(asctime)s %(levelname)s: %(message)s', level=logging.INFO)
    args = parse_cli()
    run_preprocess_spark(args.input, args.out_dir, seed=args.seed, test_size=args.test_size)


if __name__ == '__main__':
    main()
