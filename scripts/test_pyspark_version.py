"""
Test that PySpark can start and runs the expected version (3.5.7 expected in this project).
Run with the venv Python: 
C:/Users/swkan/Downloads/VSCode/Big Data Group Project/.venv310/Scripts/python.exe scripts\test_pyspark_version.py
"""
from __future__ import annotations
from pathlib import Path
import os

try:
    from pyspark.sql import SparkSession
except Exception as e:
    print('ERROR: Could not import pyspark:', e)
    raise SystemExit(1)

# create a minimal local session and print version info
if __name__ == '__main__':
    # Unset conflicting env vars that cause Py4J constructor errors
    for env_var in ['SPARK_HOME', 'HADOOP_HOME', 'CLASSPATH', 'HADOOP_CLASSPATH', 'SPARK_DIST_CLASSPATH']:
        if env_var in os.environ:
            print(f"Unsetting {env_var} ({os.environ[env_var]}) to avoid conflicts.")
            del os.environ[env_var]

    os.environ.setdefault('SPARK_LOCAL_IP', '127.0.0.1')
    
    # Set python executable for worker to avoid "python3" not found on Windows
    import sys
    os.environ['PYSPARK_PYTHON'] = sys.executable
    os.environ['PYSPARK_DRIVER_PYTHON'] = sys.executable

    from pyspark.sql import SparkSession
    spark = SparkSession.builder.master('local[2]').appName('test-pyspark-version').getOrCreate()
    print('PySpark package version:', __import__('pyspark').__version__)
    print('Spark session version:', spark.version)

    # quick check: simple DataFrame op
    df = spark.range(3).toDF('id')
    print('Spark range count:', df.count())

    # check Python used by worker
    try:
        # use sc.getConf() to show driver/worker PYSPARK_PYTHON
        sc = spark.sparkContext
        driver_py = sc.getConf().get('spark.executorEnv.PYSPARK_PYTHON') or 'not set'
        print('spark.executorEnv.PYSPARK_PYTHON:', driver_py)
    except Exception:
        pass

    spark.stop()
