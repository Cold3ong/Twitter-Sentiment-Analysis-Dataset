#!/usr/bin/env python3
"""
Run a baseline PySpark ML pipeline: HashingTF + IDF + LogisticRegression (default parameters)
Saves:
- model pipeline to `models/pipelines/baseline_logreg_default/`
- metrics JSON to `results/metrics/baseline_default.json`
- confusion matrix CSV to `results/metrics/confusion_baseline_default.csv`
"""
from __future__ import annotations

import argparse
import json
import logging
from pathlib import Path

from pyspark.ml import Pipeline
from pyspark.ml.classification import LogisticRegression
from pyspark.ml.feature import Tokenizer, HashingTF, IDF
from pyspark.sql import SparkSession
from pyspark.sql.functions import col
from pyspark.sql.types import DoubleType

from pyspark.mllib.evaluation import MulticlassMetrics

LOG = logging.getLogger("baseline")


def init_spark(app_name: str = "baseline") -> SparkSession:
    return (
        SparkSession.builder.appName(app_name)
        .config("spark.sql.shuffle.partitions", "8")
        .getOrCreate()
    )


def compute_metrics(predictions):
    # predictions: DataFrame with 'prediction' and 'label'
    pred_and_labels = predictions.select('prediction', 'label').rdd.map(lambda r: (float(r['prediction']), float(r['label'])))
    metrics = MulticlassMetrics(pred_and_labels)
    labels = sorted(list(set(predictions.select('label').rdd.flatMap(lambda x: [x[0]]).collect())))
    # macro f1
    f1_vals = [metrics.fMeasure(float(l)) for l in labels]
    macro_f1 = sum(f1_vals) / (len(f1_vals) if f1_vals else 1.0)
    # accuracy, weighted f1
    accuracy = metrics.accuracy
    weighted_f1 = metrics.weightedFMeasure()
    # confusion matrix
    cm = metrics.confusionMatrix().toArray().tolist()
    return dict(macro_f1=macro_f1, accuracy=accuracy, weighted_f1=weighted_f1, labels=labels, f1_per_label=f1_vals, confusion_matrix=cm)


def run_baseline(train_parquet: str, test_parquet: str, out_dir: str):
    spark = init_spark("baseline_logreg")
    LOG.info("Loading train: %s", train_parquet)
    train = spark.read.parquet(train_parquet)
    test = spark.read.parquet(test_parquet)

    # ensure label column exists as double; prefer `text_sentiment` per notebook
    if 'text_sentiment' in train.columns:
        train = train.withColumn('label', col('text_sentiment').cast(DoubleType()))
    else:
        train = train.withColumn('label', col('label').cast(DoubleType()))
    if 'text_sentiment' in test.columns:
        test = test.withColumn('label', col('text_sentiment').cast(DoubleType()))
    else:
        test = test.withColumn('label', col('label').cast(DoubleType()))

    # Use `clean_text_sample` column produced by preprocessing notebook/script
    tokenizer = Tokenizer(inputCol='clean_text_sample' if 'clean_text_sample' in train.columns else 'clean_text', outputCol='tokens')
    hashing_tf = HashingTF(inputCol='tokens', outputCol='rawFeatures', numFeatures=1 << 16)
    idf = IDF(inputCol='rawFeatures', outputCol='features')
    lr = LogisticRegression(featuresCol='features', labelCol='label')  # default params

    pipeline = Pipeline(stages=[tokenizer, hashing_tf, idf, lr])
    LOG.info('Fitting baseline pipeline on train')
    model = pipeline.fit(train)
    LOG.info('Transforming test set')
    predictions = model.transform(test)

    LOG.info('Computing metrics')
    results = compute_metrics(predictions)

    # Save model and results
    out_models = Path(out_dir) / 'models' / 'pipelines' / 'baseline_logreg_default'
    out_models.mkdir(parents=True, exist_ok=True)
    model.write().overwrite().save(str(out_models))

    results_dir = Path('results') / 'metrics'
    results_dir.mkdir(parents=True, exist_ok=True)
    with open(results_dir / 'baseline_default.json', 'w', encoding='utf-8') as f:
        json.dump(results, f, indent=2)

    # save confusion matrix as CSV
    import pandas as pd

    cm_df = pd.DataFrame(results['confusion_matrix'], index=results['labels'], columns=results['labels'])
    cm_df.index.name = 'label_true'
    cm_df.columns.name = 'label_pred'
    cm_df.to_csv(results_dir / 'confusion_baseline_default.csv')

    LOG.info('Baseline complete; results saved to %s', results_dir)
    print('Baseline metrics:')
    print(json.dumps(results, indent=2))
    spark.stop()


def parse_cli():
    p = argparse.ArgumentParser()
    p.add_argument('--train', default='data/processed/v1/train.parquet')
    p.add_argument('--test', default='data/processed/v1/test.parquet')
    p.add_argument('--out-dir', default='.')
    return p.parse_args()


def main():
    logging.basicConfig(format='%(asctime)s %(levelname)s: %(message)s', level=logging.INFO)
    args = parse_cli()
    run_baseline(args.train, args.test, args.out_dir)


if __name__ == '__main__':
    main()
