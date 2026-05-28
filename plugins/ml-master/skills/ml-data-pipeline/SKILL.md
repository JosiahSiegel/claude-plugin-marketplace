---
name: ml-data-pipeline
description: |
  This skill should be used when the user asks to ingest, clean, validate, transform, version, monitor, or serve ML data and features. PROACTIVELY activate for: (1) data ingestion, preprocessing, feature engineering, leakage prevention, train/serving skew, (2) Spark, Dask, Polars, pandas, Ray Data, streaming pipelines, (3) Great Expectations, TFDV, Deequ, data quality and validation, (4) DVC, lakehouse tables, dataset versioning, lineage, reproducibility, (5) Feast, Tecton, Hopsworks feature stores, point-in-time joins, online/offline features. Provides: scalable, reproducible, leakage-safe ML data pipeline design.
---

# ML Data Pipeline

## Overview

Use this skill for data ingestion, validation, preprocessing, feature engineering, dataset versioning, feature stores, batch and streaming pipelines, and data-quality monitoring. In ML, data pipeline correctness is often more important than model sophistication. A pipeline must produce leakage-safe training data and consistent serving features.

## Data Data Pipeline Invariants

- Raw data is immutable or snapshot-addressable.
- Schemas, statistics, and quality expectations are validated before training and serving.
- Transformations are versioned and reproducible.
- Splits are created before leakage-prone operations such as oversampling, target encoding, feature selection, or normalization.
- Time-dependent features use only information available at prediction time.
- Offline training features match online serving features.
- Sensitive data is minimized, access-controlled, encrypted, and audited.

## Ingestion and Storage

Choose storage based on data shape and access pattern. Object storage with Parquet/Arrow is a strong default for tabular batch ML. Delta Lake, Apache Iceberg, or Hudi add ACID tables, schema evolution, and time travel. Use warehouses for governed SQL features, vector stores for embedding retrieval, and streaming logs for online behavior. Store raw, cleaned, feature, and model-ready layers separately. For Azure Storage pointer blobs used by ADF to pass Azure ML code asset versions, load `ml-azureml-adf-automation`.

For large datasets, prefer columnar formats, partitioning by time or high-level domain, compression, predicate pushdown, and manifest files. Avoid many tiny files; compact when necessary. Record dataset snapshot identifiers in every training run.

## Feast Feature Store Blueprint

Feast is a modular feature store for maintaining online-offline feature consistency.

### 1. Feature Store Configuration (`feature_store.yaml`)
```yaml
project: fraud_detection
registry: data/registry.db
provider: local
online_store:
  type: redis
  connection_string: "localhost:6379"
offline_store:
  type: file
```

### 2. Feature Definitions (`features.py`)
```python
from datetime import timedelta
from feast import Entity, FeatureView, Field, FileSource, ValueType
from feast.types import Float32, Int64

user = Entity(name="user_id", value_type=ValueType.INT64, join_keys=["user_id"])

user_transactions_source = FileSource(
    path="data/user_transactions.parquet",
    event_timestamp_column="timestamp",
    created_timestamp_column="created_timestamp",
)

user_transactions_fv = FeatureView(
    name="user_transactions_feature_view",
    entities=[user],
    ttl=timedelta(days=90),
    schema=[
        Field(name="transaction_count_30d", dtype=Int64),
        Field(name="total_amount_30d", dtype=Float32),
    ],
    online=True,
    source=user_transactions_source,
)
```

## Processing Engines

| Engine | Best fit |
|---|---|
| pandas | Small to medium in-memory exploration and simple pipelines |
| Polars | Fast local/lazy columnar processing, larger-than-pandas workloads |
| Spark | Large distributed ETL, lakehouse workflows, SQL + MLlib integration |
| Dask | Python-native distributed arrays/dataframes and custom workloads |
| Ray Data | ML-centric distributed preprocessing integrated with Ray Train/Tune/Serve |
| Beam/Flink/Spark Streaming | Streaming or unified batch/stream dataflows |
| Airflow/Prefect/Dagster | Orchestration, scheduling, retries, lineage, and dependency management |

### High-Performance Polars Lazy Aggregation Pipeline
Polars lazy evaluation optimizes the execution plan using predicate and projection pushdowns.
```python
import polars as pl

def compute_rolling_user_features(transactions_path: str):
    lazy_df = (
        pl.scan_parquet(transactions_path)
        # Cast timestamp for windowing
        .with_columns(pl.col("timestamp").str.strptime(pl.Datetime))
        .sort("timestamp")
        # Define rolling calculation window
        .group_by_dynamic(
            index_column="timestamp",
            every="1d",
            period="30d",
            group_by="user_id"
        )
        .agg([
            pl.col("amount").count().alias("transaction_count_30d"),
            pl.col("amount").sum().alias("total_amount_30d"),
            pl.col("amount").mean().alias("avg_amount_30d")
        ])
        .filter(pl.col("user_id").is_not_null())
    )
    # Collect executes the query optimization and loads results into memory
    return lazy_df.collect()
```

### Spark Dataframe Optimization Recipes
Prevent typical distributed training bottlenecks such as data skew and excessive shuffle overhead.

#### 1. Salting to Prevent Skewed Joins
```python
from pyspark.sql import functions as F

# Adding a salt column to distribute skewed key values evenly across partitions
skewed_df = skewed_df.with_columns(
    (F.rand() * 10).cast("int").alias("salt")
)
lookup_df = lookup_df.with_columns(
    F.explode(F.array([F.lit(i) for i in range(10)])).alias("salt")
)

# Join on key AND salt to distribute the workload
joined_df = skewed_df.join(lookup_df, ["join_key", "salt"], "inner").drop("salt")
```

#### 2. Broadcast Join for Lookup Tables
```python
from pyspark.sql.functions import broadcast

# Explicitly broadcast small dimension dataframe to executors to avoid shuffling large fact table
optimized_joined = large_fact_df.join(broadcast(small_lookup_df), "entity_id", "inner")
```

## Data Validation

Validate at ingestion, feature generation, training, and serving. Check schema, types, ranges, nulls, uniqueness, duplicates, categorical domains, cardinality, label distribution, timestamp monotonicity, referential integrity, text/image/audio validity, and embedding norms. Tools include Great Expectations, TensorFlow Data Validation, Deequ, pandera, dbt tests, and custom assertions.

Quality checks should fail fast for contract violations and warn for distribution changes that need investigation. Store validation reports with training artifacts. For production, monitor both raw features and post-transform model inputs.

## Feature Engineering

Feature engineering should be tied to the prediction time. For temporal data, compute rolling windows with correct cutoffs, delays, and late-arriving data handling. For target encoding, fit encoders inside cross-validation folds and use smoothing. For categorical features, choose native categorical support, one-hot, hashing, embeddings, or target encoding based on cardinality and model type. For text, version tokenizers and vocabularies. For images/audio, store preprocessing parameters and augmentations.

Prevent leakage by asking: would this feature be known at the moment the model makes the prediction? If not, exclude it or redesign the target and prediction time.

## DVC (Data Version Control) Ingest Workflow

DVC tags large datasets to Git commits via lightweight metadata files, avoiding bloat.

### 1. Initialize and Add Storage
```bash
dvc init
dvc remote add -d myremote s3://my-dvc-bucket/raw-data
```

### 2. Track a New Dataset Version
```bash
# Add dataset to DVC tracking (creates data.parquet.dvc)
dvc add data/raw_transactions.parquet

# Commit DVC metadata file to Git
git add data/raw_transactions.parquet.dvc data/.gitignore
git commit -m "Track transactions dataset v1.0.0 via DVC"

# Push raw binaries to remote cloud storage
dvc push
```

### 3. Retrieve Tracked Version on Another Worker
```bash
git pull
dvc pull
```

## Streaming and Online Pipelines

Streaming ML pipelines need event-time handling, watermarks, deduplication, ordering strategy, late data behavior, exactly-once or at-least-once semantics, and replayability. Separate online feature updates from training-label generation. Keep a path to backfill or replay from durable logs when feature logic changes.

## Security and Privacy

Minimize sensitive fields, tokenize or hash identifiers where appropriate, and preserve joinability only when needed. Apply access controls by data layer. Avoid exporting raw PII into experiment trackers or model artifacts. Document retention and deletion policies.

## Common Pipeline Failures

- Train/serving skew from separate preprocessing implementations.
- Future leakage in rolling features, aggregates, or target encoders.
- Silent schema drift that coerces strings, nulls, or categories incorrectly.
- Duplicate entities across train and validation.
- Oversampling or normalization before splitting.
- Non-versioned datasets causing irreproducible training.
- Streaming features that cannot be backfilled for training.

## Sources

- Great Expectations documentation: https://docs.greatexpectations.io/
- TensorFlow Data Validation documentation: https://www.tensorflow.org/tfx/data_validation
- Feast documentation: https://docs.feast.dev/
- DVC documentation: https://dvc.org/doc
- Apache Spark MLlib and SQL docs: https://spark.apache.org/docs/latest/
- Polars documentation: https://docs.pola.rs/
