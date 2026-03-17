# Databricks ML and End-to-End Pipeline Patterns

## Databricks ML Integration

### Pattern: ML Training and Scoring via DatabricksJob

Use the Databricks Job activity (the current standard) to orchestrate ML workflows defined in Databricks, including MLflow experiment tracking.

**ML Training Pipeline:**
```json
{
  "name": "PL_ML_Training_Databricks",
  "properties": {
    "activities": [
      {
        "name": "ArchiveTrainingData",
        "type": "Copy",
        "typeProperties": {
          "source": {
            "type": "AzureSqlSource",
            "sqlReaderQuery": "SELECT * FROM dbo.TrainingFeatures WHERE FeatureDate BETWEEN '@{pipeline().parameters.StartDate}' AND '@{pipeline().parameters.EndDate}'"
          },
          "sink": {
            "type": "ParquetSink",
            "storeSettings": { "type": "AzureBlobStorageWriteSettings" }
          }
        },
        "inputs": [{ "referenceName": "DS_AzureSql_Source", "type": "DatasetReference" }],
        "outputs": [{
          "referenceName": "DS_Blob_Parquet",
          "type": "DatasetReference",
          "parameters": {
            "FolderPath": "@concat('ml/training-data/', pipeline().parameters.ModelName, '/version=', pipeline().parameters.ModelVersion)",
            "FileName": "train.parquet"
          }
        }]
      },
      {
        "name": "RunMLTraining",
        "type": "DatabricksJob",
        "dependsOn": [
          { "activity": "ArchiveTrainingData", "dependencyConditions": ["Succeeded"] }
        ],
        "policy": {
          "timeout": "0.12:00:00",
          "retry": 1,
          "retryIntervalInSeconds": 60
        },
        "typeProperties": {
          "jobId": "@pipeline().parameters.TrainingJobId",
          "jobParameters": {
            "training_data_path": "@concat('abfss://ml@', pipeline().parameters.StorageAccount, '.dfs.core.windows.net/training-data/', pipeline().parameters.ModelName, '/version=', pipeline().parameters.ModelVersion)",
            "model_name": "@pipeline().parameters.ModelName",
            "model_version": "@pipeline().parameters.ModelVersion",
            "experiment_name": "@concat('/Shared/experiments/', pipeline().parameters.ModelName)",
            "hyperparams": "@pipeline().parameters.Hyperparameters"
          }
        },
        "linkedServiceName": {
          "referenceName": "LS_Databricks_Serverless",
          "type": "LinkedServiceReference"
        }
      },
      {
        "name": "LogTrainingResult",
        "type": "WebActivity",
        "dependsOn": [
          { "activity": "RunMLTraining", "dependencyConditions": ["Succeeded"] }
        ],
        "typeProperties": {
          "url": "@pipeline().parameters.LoggingEndpoint",
          "method": "POST",
          "body": {
            "model": "@pipeline().parameters.ModelName",
            "version": "@pipeline().parameters.ModelVersion",
            "runId": "@activity('RunMLTraining').output.runId",
            "runPageUrl": "@activity('RunMLTraining').output.runPageUrl",
            "status": "TrainingComplete"
          }
        }
      }
    ],
    "parameters": {
      "ModelName": { "type": "string", "defaultValue": "sales_forecast" },
      "ModelVersion": { "type": "string", "defaultValue": "1" },
      "TrainingJobId": { "type": "string" },
      "StorageAccount": { "type": "string" },
      "StartDate": { "type": "string" },
      "EndDate": { "type": "string" },
      "Hyperparameters": { "type": "string", "defaultValue": "{}" },
      "LoggingEndpoint": { "type": "string" }
    }
  }
}
```

**ML Batch Scoring Pipeline:**
```json
{
  "name": "PL_ML_Scoring_Databricks",
  "properties": {
    "activities": [
      {
        "name": "ExtractScoringData",
        "type": "Copy",
        "typeProperties": {
          "source": {
            "type": "AzureSqlSource",
            "sqlReaderQuery": "SELECT * FROM dbo.ScoringFeatures WHERE ScoredDate IS NULL"
          },
          "sink": {
            "type": "ParquetSink",
            "storeSettings": { "type": "AzureBlobStorageWriteSettings" }
          }
        },
        "inputs": [{ "referenceName": "DS_AzureSql_Source", "type": "DatasetReference" }],
        "outputs": [{
          "referenceName": "DS_Blob_Parquet",
          "type": "DatasetReference",
          "parameters": {
            "FolderPath": "@concat('ml/scoring-input/', formatDateTime(utcnow(), 'yyyy/MM/dd'))",
            "FileName": "scoring_input.parquet"
          }
        }]
      },
      {
        "name": "RunBatchScoring",
        "type": "DatabricksJob",
        "dependsOn": [
          { "activity": "ExtractScoringData", "dependencyConditions": ["Succeeded"] }
        ],
        "typeProperties": {
          "jobId": "@pipeline().parameters.ScoringJobId",
          "jobParameters": {
            "input_path": "@concat('abfss://ml@', pipeline().parameters.StorageAccount, '.dfs.core.windows.net/scoring-input/', formatDateTime(utcnow(), 'yyyy/MM/dd'), '/scoring_input.parquet')",
            "output_path": "@concat('abfss://ml@', pipeline().parameters.StorageAccount, '.dfs.core.windows.net/scores/', pipeline().parameters.ModelName, '/', formatDateTime(utcnow(), 'yyyy/MM/dd'))",
            "model_name": "@pipeline().parameters.ModelName",
            "model_stage": "Production"
          }
        },
        "linkedServiceName": {
          "referenceName": "LS_Databricks_Serverless",
          "type": "LinkedServiceReference"
        }
      },
      {
        "name": "LoadScoresBackToSql",
        "type": "Copy",
        "dependsOn": [
          { "activity": "RunBatchScoring", "dependencyConditions": ["Succeeded"] }
        ],
        "typeProperties": {
          "source": {
            "type": "ParquetSource",
            "storeSettings": {
              "type": "AzureBlobStorageReadSettings",
              "recursive": true,
              "wildcardFileName": "*.parquet"
            }
          },
          "sink": {
            "type": "AzureSqlSink",
            "writeBehavior": "upsert",
            "upsertSettings": {
              "useTempDB": true,
              "keys": ["RecordId"]
            },
            "writeBatchSize": 10000
          }
        },
        "inputs": [{
          "referenceName": "DS_Blob_Parquet",
          "type": "DatasetReference",
          "parameters": {
            "FolderPath": "@concat('ml/scores/', pipeline().parameters.ModelName, '/', formatDateTime(utcnow(), 'yyyy/MM/dd'))"
          }
        }],
        "outputs": [{ "referenceName": "DS_AzureSql_Predictions", "type": "DatasetReference" }]
      }
    ],
    "parameters": {
      "ModelName": { "type": "string" },
      "ScoringJobId": { "type": "string" },
      "StorageAccount": { "type": "string" }
    }
  }
}
```

## Data Flow Feature Engineering

Use Mapping Data Flows for feature engineering before ML scoring.

### Feature Engineering Data Flow Pattern

**Execute Data Flow Activity:**
```json
{
  "name": "RunFeatureEngineering",
  "type": "ExecuteDataFlow",
  "typeProperties": {
    "dataFlow": {
      "referenceName": "DF_FeatureEngineering",
      "type": "DataFlowReference",
      "parameters": {
        "WindowDays": "30",
        "MinTransactions": "5"
      }
    },
    "compute": {
      "coreCount": 16,
      "computeType": "MemoryOptimized"
    },
    "staging": {
      "linkedService": {
        "referenceName": "LS_AzureBlobStorage",
        "type": "LinkedServiceReference"
      },
      "folderPath": "staging/dataflows"
    }
  }
}
```

**Common Feature Engineering Transformations:**
```
# Data Flow Script (DFS) patterns for ML features

# Aggregate window features
source1
  window(over(customer_id),
    asc(transaction_date, true),
    rolling_avg_30d = avg(amount, 30),
    rolling_sum_7d = sum(amount, 7),
    transaction_count = count(1),
    max_amount = max(amount)
  )

# Derived columns for categorical encoding
  derive(
    is_weekend = dayOfWeek(transaction_date) >= 6,
    hour_of_day = hour(transaction_date),
    day_of_week = dayOfWeek(transaction_date),
    month = month(transaction_date),
    amount_log = log(amount + 1),
    days_since_first = datediff(first_transaction_date, transaction_date)
  )

# Pivot categorical to one-hot
  pivot(groupBy(customer_id),
    pivotBy(category),
    category_count = count(1)
  )

# Filter and validate
  filter(
    !isNull(customer_id) &&
    amount > 0 &&
    transaction_count >= $MinTransactions
  )
```

## End-to-End ML Pipeline Pattern

### Complete: SQL Archive -> Feature Engineering -> Train -> Score -> Write Back

```json
{
  "name": "PL_EndToEnd_ML_Workflow",
  "properties": {
    "activities": [
      {
        "name": "ArchiveSourceData",
        "type": "ExecutePipeline",
        "typeProperties": {
          "pipeline": { "referenceName": "PL_SqlArchive_ForAnalysis", "type": "PipelineReference" },
          "waitOnCompletion": true,
          "parameters": {
            "SourceDatabase": "@pipeline().parameters.SourceDatabase"
          }
        }
      },
      {
        "name": "EngineerFeatures",
        "type": "ExecuteDataFlow",
        "dependsOn": [
          { "activity": "ArchiveSourceData", "dependencyConditions": ["Succeeded"] }
        ],
        "typeProperties": {
          "dataFlow": { "referenceName": "DF_FeatureEngineering", "type": "DataFlowReference" },
          "compute": { "coreCount": 16, "computeType": "MemoryOptimized" }
        }
      },
      {
        "name": "SwitchTrainOrScore",
        "type": "Switch",
        "dependsOn": [
          { "activity": "EngineerFeatures", "dependencyConditions": ["Succeeded"] }
        ],
        "typeProperties": {
          "on": { "value": "@pipeline().parameters.Mode", "type": "Expression" },
          "cases": [
            {
              "value": "train",
              "activities": [
                {
                  "name": "RunTraining",
                  "type": "ExecutePipeline",
                  "typeProperties": {
                    "pipeline": { "referenceName": "PL_ML_Training_Databricks", "type": "PipelineReference" },
                    "waitOnCompletion": true,
                    "parameters": {
                      "ModelName": "@pipeline().parameters.ModelName",
                      "ModelVersion": "@pipeline().parameters.ModelVersion",
                      "TrainingJobId": "@pipeline().parameters.DatabricksJobId",
                      "StorageAccount": "@pipeline().parameters.StorageAccount"
                    }
                  }
                }
              ]
            },
            {
              "value": "score",
              "activities": [
                {
                  "name": "RunScoring",
                  "type": "ExecutePipeline",
                  "typeProperties": {
                    "pipeline": { "referenceName": "PL_ML_Scoring_Databricks", "type": "PipelineReference" },
                    "waitOnCompletion": true,
                    "parameters": {
                      "ModelName": "@pipeline().parameters.ModelName",
                      "ScoringJobId": "@pipeline().parameters.DatabricksJobId",
                      "StorageAccount": "@pipeline().parameters.StorageAccount"
                    }
                  }
                }
              ]
            }
          ],
          "defaultActivities": [
            {
              "name": "FailInvalidMode",
              "type": "Fail",
              "typeProperties": {
                "message": "@concat('Invalid mode: ', pipeline().parameters.Mode, '. Expected: train or score')",
                "errorCode": "INVALID_MODE"
              }
            }
          ]
        }
      }
    ],
    "parameters": {
      "SourceDatabase": { "type": "string" },
      "Mode": { "type": "string", "defaultValue": "score" },
      "ModelName": { "type": "string" },
      "ModelVersion": { "type": "string", "defaultValue": "1" },
      "DatabricksJobId": { "type": "string" },
      "StorageAccount": { "type": "string" }
    }
  }
}
```
