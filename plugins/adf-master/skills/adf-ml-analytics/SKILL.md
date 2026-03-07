---
name: adf-ml-analytics
description: Machine learning and analytics patterns in Azure Data Factory - orchestrating Azure ML batch endpoints (SDK v2), Azure OpenAI Batch API for LLM scoring, Azure AI Services (Microsoft Foundry), Databricks ML, Azure SQL to Storage archival for analysis, and feature engineering with Data Flows
---

# Azure Data Factory Machine Learning & Analytics Patterns

## Overview

Azure Data Factory orchestrates ML workflows by integrating with Azure Machine Learning, Azure AI Services, Databricks ML, and Azure SQL Database. This skill covers patterns for extracting data from ephemeral sources (like Azure SQL Database), archiving to Azure Storage for long-term analysis, and leveraging ML services for scoring and insights.

## Deprecation Notices & Platform Changes (Current March 2026)

**Azure AI Foundry → Microsoft Foundry (November 2025)**
- At Ignite November 2025, Microsoft renamed Azure AI Foundry to **Microsoft Foundry**.
- Microsoft Foundry is the unified AI platform: agents, workflows, models, and tools under one resource provider.
- ADF is positioned as the **data orchestration layer** within Microsoft Foundry — handling ingestion, transformation, feature preparation, and downstream consumption by models and agents.
- New AI features are primarily landing in **Fabric Data Factory** (Copilot, natural language pipeline generation). ADF classic remains fully supported but receives fewer new features.

**Azure ML SDK v1 - SUPPORT ENDING JUNE 2026**
- Deprecated: March 31, 2025. Support ends: **June 30, 2026 (3 months away).**
- Impact: `AzureMLExecutePipeline` activity uses SDK v1 published pipelines. These will stop working after June 2026.
- Related SDKs also retiring: `azureml-train-core`, `azureml-pipeline`, `azureml-pipeline-core`, `azureml-pipeline-steps`.
- **Migration required:** Use Azure ML SDK v2 batch endpoints via WebActivity (see below).
- All new projects must use batch endpoints, not published pipelines.

**Azure AI Inference SDK - RETIRING MAY 30, 2026**
- The `azure-ai-inference` SDK (Python/JS/.NET) is deprecated.
- **Migrate to the OpenAI SDK** using the `OpenAI/v1` API, which works with both Azure OpenAI and Microsoft Foundry Models.
- This affects any code calling Azure AI model endpoints via the inference SDK.

**Azure SQL Edge - RETIRED September 30, 2025**
- Azure SQL Edge (which included ONNX PREDICT on edge devices) is no longer available.
- Migration: Use Azure SQL Managed Instance enabled by Azure Arc for edge SQL scenarios.

**Cognitive Services for Power BI Dataflows - RETIRED**
- Retired: September 15, 2025. AI Insights in Power BI dataflows no longer works.
- Alternative: Use ADF WebActivity to call Azure AI Services endpoints directly.

**Azure Cognitive Services - REBRANDED**
- "Azure Cognitive Services" → "Azure AI Services" → now part of **Microsoft Foundry**.
- API endpoints remain the same; branding has changed.

**Apache Airflow in ADF - DEPRECATED**
- Deprecated in early 2025 for new customers. Existing deployments continue to function.
- Migration: Use Fabric Data Factory, native ADF pipelines, or standalone Airflow deployments.

---

## Azure Machine Learning Integration

### AzureMLExecutePipeline Activity (Legacy - SDK v1, support ends June 2026)

Executes an Azure Machine Learning published pipeline from ADF. **SDK v1 support ends June 2026.** Migrate to batch endpoints via WebActivity for all new and existing projects.

**Linked Service (Azure ML Workspace):**
```json
{
  "name": "LS_AzureML_Workspace",
  "type": "Microsoft.DataFactory/factories/linkedservices",
  "properties": {
    "type": "AzureMLService",
    "typeProperties": {
      "subscriptionId": "<subscription-id>",
      "resourceGroupName": "<resource-group>",
      "mlWorkspaceName": "<ml-workspace-name>",
      "authentication": "MSI"
    }
  }
}
```

**Execute ML Pipeline Activity:**
```json
{
  "name": "RunMLTrainingPipeline",
  "type": "AzureMLExecutePipeline",
  "dependsOn": [],
  "policy": {
    "timeout": "1.00:00:00",
    "retry": 1,
    "retryIntervalInSeconds": 60
  },
  "typeProperties": {
    "mlPipelineId": "<published-pipeline-id>",
    "experimentName": "training-experiment",
    "mlPipelineParameters": {
      "input_data": "@pipeline().parameters.InputDataPath",
      "output_model": "@pipeline().parameters.OutputModelPath",
      "learning_rate": "0.01",
      "epochs": "100"
    },
    "mlParentRunId": "@pipeline().RunId",
    "dataPathAssignments": {
      "inputDataPath": "@pipeline().parameters.DataPath"
    },
    "continueOnStepFailure": false
  },
  "linkedServiceName": {
    "referenceName": "LS_AzureML_Workspace",
    "type": "LinkedServiceReference"
  }
}
```

**Key Properties:**
- `mlPipelineId`: Published Azure ML pipeline ID (UUID)
- `experimentName`: ML experiment for run tracking (optional)
- `mlPipelineParameters`: Key-value pairs passed to the ML pipeline
- `dataPathAssignments`: Switch data paths at runtime without republishing
- `continueOnStepFailure`: If `true`, pipeline continues even if a step fails (default: `false`)
- `mlParentRunId`: Links ADF run to ML experiment for lineage tracking

**Activity Outputs:**
```
@activity('RunMLTrainingPipeline').output.mlPipelineRunId
@activity('RunMLTrainingPipeline').output.status
```

### Azure ML Batch Endpoints (Recommended — SDK v2)

Batch endpoints replace published pipelines for batch inference. Call them via WebActivity. In SDK v2, published pipelines are replaced by **pipeline component deployments** under batch endpoints, providing better source control and versioning.

**Azure ML REST API version:** `2025-12-01` (latest stable for batch endpoint management).

**Batch Endpoint Scoring via WebActivity:**
```json
{
  "name": "InvokeBatchEndpoint",
  "type": "WebActivity",
  "dependsOn": [],
  "policy": {
    "timeout": "1.00:00:00",
    "retry": 2,
    "retryIntervalInSeconds": 60
  },
  "typeProperties": {
    "url": "https://<endpoint-name>.<region>.inference.ml.azure.com/jobs",
    "method": "POST",
    "headers": {
      "Content-Type": "application/json"
    },
    "body": {
      "properties": {
        "InputData": {
          "mnistinput": {
            "JobInputType": "UriFolder",
            "Uri": "@concat('https://', pipeline().parameters.StorageAccount, '.blob.core.windows.net/', pipeline().parameters.InputContainer, '/', pipeline().parameters.InputPath)"
          }
        },
        "OutputData": {
          "score_output": {
            "JobOutputType": "UriFolder",
            "Uri": "@concat('https://', pipeline().parameters.StorageAccount, '.blob.core.windows.net/', pipeline().parameters.OutputContainer, '/scores/', formatDateTime(utcnow(), 'yyyyMMdd'))"
          }
        }
      }
    },
    "authentication": {
      "type": "MSI",
      "resource": "https://ml.azure.com"
    }
  }
}
```

**Poll Batch Job Completion (Until Loop):**
```json
{
  "name": "WaitForBatchJob",
  "type": "Until",
  "dependsOn": [
    { "activity": "InvokeBatchEndpoint", "dependencyConditions": ["Succeeded"] }
  ],
  "typeProperties": {
    "expression": {
      "value": "@or(equals(variables('JobStatus'), 'Completed'), equals(variables('JobStatus'), 'Failed'))",
      "type": "Expression"
    },
    "timeout": "1.00:00:00",
    "activities": [
      {
        "name": "CheckJobStatus",
        "type": "WebActivity",
        "typeProperties": {
          "url": "@concat('https://<endpoint-name>.<region>.inference.ml.azure.com/jobs/', activity('InvokeBatchEndpoint').output.id)",
          "method": "GET",
          "authentication": {
            "type": "MSI",
            "resource": "https://ml.azure.com"
          }
        }
      },
      {
        "name": "SetJobStatus",
        "type": "SetVariable",
        "dependsOn": [
          { "activity": "CheckJobStatus", "dependencyConditions": ["Succeeded"] }
        ],
        "typeProperties": {
          "variableName": "JobStatus",
          "value": {
            "value": "@activity('CheckJobStatus').output.properties.status",
            "type": "Expression"
          }
        }
      },
      {
        "name": "WaitBeforeCheck",
        "type": "Wait",
        "dependsOn": [
          { "activity": "SetJobStatus", "dependencyConditions": ["Succeeded"] }
        ],
        "typeProperties": {
          "waitTimeInSeconds": 60
        }
      }
    ]
  }
}
```

### Azure ML Online Endpoints (Real-Time Scoring)

For real-time scoring of individual records or small batches, call managed online endpoints.

**Real-Time Scoring via WebActivity:**
```json
{
  "name": "ScoreRecord",
  "type": "WebActivity",
  "typeProperties": {
    "url": "https://<endpoint-name>.<region>.inference.ml.azure.com/score",
    "method": "POST",
    "headers": {
      "Content-Type": "application/json",
      "azureml-model-deployment": "<deployment-name>"
    },
    "body": {
      "input_data": {
        "columns": ["feature1", "feature2", "feature3"],
        "data": [
          ["@{activity('LookupRecord').output.firstRow.feature1}", "@{activity('LookupRecord').output.firstRow.feature2}", "@{activity('LookupRecord').output.firstRow.feature3}"]
        ]
      }
    },
    "authentication": {
      "type": "MSI",
      "resource": "https://ml.azure.com"
    }
  }
}
```

---

## Azure SQL In-Database ML Scoring

### T-SQL PREDICT Function

For fast, in-database scoring without leaving Azure SQL. Supports ONNX models loaded into the database.

**Stored Procedure Activity calling PREDICT:**
```json
{
  "name": "InDatabaseMLScoring",
  "type": "SqlServerStoredProcedure",
  "linkedServiceName": {
    "referenceName": "LS_AzureSql",
    "type": "LinkedServiceReference"
  },
  "typeProperties": {
    "storedProcedureName": "dbo.usp_ScoreWithPredict",
    "storedProcedureParameters": {
      "ModelName": { "value": "@pipeline().parameters.ModelName", "type": "String" },
      "InputTable": { "value": "@pipeline().parameters.InputTable", "type": "String" },
      "OutputTable": { "value": "@pipeline().parameters.OutputTable", "type": "String" }
    }
  }
}
```

**SQL Stored Procedure using PREDICT:**
```sql
CREATE PROCEDURE dbo.usp_ScoreWithPredict
    @ModelName NVARCHAR(100),
    @InputTable NVARCHAR(128),
    @OutputTable NVARCHAR(128)
AS
BEGIN
    DECLARE @model VARBINARY(MAX) = (
        SELECT model_data FROM dbo.MLModels WHERE model_name = @ModelName
    );

    -- T-SQL PREDICT scores data in-place without external calls
    DECLARE @sql NVARCHAR(MAX) = N'
        INSERT INTO ' + QUOTENAME(@OutputTable) + '
        SELECT d.*, p.Score
        FROM PREDICT(MODEL = @mdl, DATA = ' + QUOTENAME(@InputTable) + ' AS d)
        WITH (Score FLOAT) AS p';

    EXEC sp_executesql @sql, N'@mdl VARBINARY(MAX)', @mdl = @model;
END
```

**Benefits of T-SQL PREDICT:**
- No data movement required (scoring happens in-database)
- Low latency (milliseconds per batch)
- Supports ONNX models (exported from scikit-learn, PyTorch, TensorFlow)

**⚠️ Availability — PREDICT is NOT available in Azure SQL Database:**
| Platform | PREDICT Support |
|----------|----------------|
| SQL Server 2017+ | ✅ RevoScaleR/revoscalepy models |
| Azure SQL Managed Instance | ✅ RevoScaleR/revoscalepy models |
| Azure Synapse Analytics | ✅ ONNX models |
| Azure SQL Database | ❌ Not supported |
| Azure SQL Edge | ❌ Retired September 2025 |

For Azure SQL Database users: Use ADF to extract data, then score externally via Databricks, Azure ML batch endpoints, or Azure OpenAI Batch API, and write predictions back.

### sp_execute_external_script (SQL Managed Instance)

For running Python/R scripts directly inside SQL. Available on Azure SQL Managed Instance with Machine Learning Services enabled.

**Stored Procedure Activity:**
```json
{
  "name": "RunPythonInSql",
  "type": "SqlServerStoredProcedure",
  "linkedServiceName": {
    "referenceName": "LS_SqlManagedInstance",
    "type": "LinkedServiceReference"
  },
  "typeProperties": {
    "storedProcedureName": "dbo.usp_PythonMLScoring",
    "storedProcedureParameters": {
      "BatchDate": { "value": "@formatDateTime(utcnow(), 'yyyy-MM-dd')", "type": "String" }
    }
  }
}
```

**SQL Procedure with External Script:**
```sql
CREATE PROCEDURE dbo.usp_PythonMLScoring @BatchDate NVARCHAR(10)
AS
BEGIN
    EXEC sp_execute_external_script
        @language = N'Python',
        @script = N'
import pandas as pd
import pickle

# InputDataSet is auto-populated from @input_data_1
model = pickle.loads(model_bytes)
predictions = model.predict(InputDataSet[["feature1", "feature2", "feature3"]])
OutputDataSet = InputDataSet.copy()
OutputDataSet["prediction"] = predictions
OutputDataSet["score_date"] = batch_date
',
        @input_data_1 = N'SELECT * FROM dbo.ScoringData WHERE batch_date = @dt',
        @params = N'@dt NVARCHAR(10), @model_bytes VARBINARY(MAX)',
        @dt = @BatchDate,
        @model_bytes = (SELECT model_data FROM dbo.MLModels WHERE is_active = 1);
END
```

**When to Use In-Database ML vs External ML:**
| Scenario | Use In-Database (PREDICT/sp_execute) | Use External (Databricks/Azure ML) |
|----------|--------------------------------------|-------------------------------------|
| Data volume | Small-medium (<1M rows) | Large (>1M rows) |
| Latency | Real-time scoring needed | Batch is acceptable |
| Model complexity | Simple models (regression, trees) | Deep learning, ensemble |
| Data movement | Must avoid (compliance, perf) | Acceptable |
| Compute | SQL is sufficient | GPU/distributed compute needed |

---

## Azure SQL Database to Storage Account (Archival & Analysis)

### Pattern: Ephemeral SQL to Long-Term Storage

For Azure SQL databases with ephemeral data, archive to Azure Storage before the data is lost, then analyze from storage.

**Complete Archive Pipeline:**
```json
{
  "name": "PL_SqlArchive_ForAnalysis",
  "properties": {
    "activities": [
      {
        "name": "GetTablesToArchive",
        "type": "Lookup",
        "typeProperties": {
          "source": {
            "type": "AzureSqlSource",
            "sqlReaderQuery": "SELECT TABLE_SCHEMA, TABLE_NAME, (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS c WHERE c.TABLE_NAME = t.TABLE_NAME AND c.TABLE_SCHEMA = t.TABLE_SCHEMA) as ColumnCount FROM INFORMATION_SCHEMA.TABLES t WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_SCHEMA NOT IN ('sys') ORDER BY TABLE_SCHEMA, TABLE_NAME"
          },
          "dataset": {
            "referenceName": "DS_AzureSql_Source",
            "type": "DatasetReference"
          },
          "firstRowOnly": false
        }
      },
      {
        "name": "ForEach_ArchiveTable",
        "type": "ForEach",
        "dependsOn": [
          { "activity": "GetTablesToArchive", "dependencyConditions": ["Succeeded"] }
        ],
        "typeProperties": {
          "items": {
            "value": "@activity('GetTablesToArchive').output.value",
            "type": "Expression"
          },
          "isSequential": false,
          "batchCount": 10,
          "activities": [
            {
              "name": "ArchiveTableToParquet",
              "type": "Copy",
              "typeProperties": {
                "source": {
                  "type": "AzureSqlSource",
                  "sqlReaderQuery": {
                    "value": "@concat('SELECT * FROM [', item().TABLE_SCHEMA, '].[', item().TABLE_NAME, ']')",
                    "type": "Expression"
                  }
                },
                "sink": {
                  "type": "ParquetSink",
                  "storeSettings": {
                    "type": "AzureBlobStorageWriteSettings"
                  },
                  "formatSettings": {
                    "type": "ParquetWriteSettings"
                  }
                },
                "enableStaging": false,
                "parallelCopies": 4,
                "dataIntegrationUnits": 4
              },
              "inputs": [
                {
                  "referenceName": "DS_AzureSql_Parameterized",
                  "type": "DatasetReference",
                  "parameters": {
                    "SchemaName": "@item().TABLE_SCHEMA",
                    "TableName": "@item().TABLE_NAME"
                  }
                }
              ],
              "outputs": [
                {
                  "referenceName": "DS_Blob_Parquet_Partitioned",
                  "type": "DatasetReference",
                  "parameters": {
                    "FolderPath": {
                      "value": "@concat('archive/', pipeline().parameters.SourceDatabase, '/', item().TABLE_SCHEMA, '/', item().TABLE_NAME, '/snapshot_date=', formatDateTime(utcnow(), 'yyyy-MM-dd'))",
                      "type": "Expression"
                    },
                    "FileName": {
                      "value": "@concat(item().TABLE_NAME, '_', formatDateTime(utcnow(), 'yyyyMMddHHmmss'), '.parquet')",
                      "type": "Expression"
                    }
                  }
                }
              ]
            }
          ]
        }
      },
      {
        "name": "LogArchiveCompletion",
        "type": "WebActivity",
        "dependsOn": [
          { "activity": "ForEach_ArchiveTable", "dependencyConditions": ["Succeeded"] }
        ],
        "typeProperties": {
          "url": "@pipeline().parameters.LoggingEndpoint",
          "method": "POST",
          "body": {
            "status": "ARCHIVED",
            "database": "@pipeline().parameters.SourceDatabase",
            "tablesArchived": "@activity('GetTablesToArchive').output.count",
            "archivePath": "@concat('archive/', pipeline().parameters.SourceDatabase)",
            "timestamp": "@utcnow()"
          }
        }
      }
    ],
    "parameters": {
      "SourceDatabase": { "type": "string" },
      "LoggingEndpoint": { "type": "string" }
    }
  }
}
```

### Pattern: Incremental Archive with Watermark

For databases where data changes over time, use watermark-based incremental extraction.

```json
{
  "name": "PL_IncrementalArchive",
  "properties": {
    "activities": [
      {
        "name": "GetLastWatermark",
        "type": "Lookup",
        "typeProperties": {
          "source": {
            "type": "AzureSqlSource",
            "sqlReaderQuery": "SELECT MAX(ArchiveTimestamp) as LastArchive FROM dbo.ArchiveWatermark WHERE TableName = '@{pipeline().parameters.TableName}'"
          },
          "dataset": { "referenceName": "DS_AzureSql_Control", "type": "DatasetReference" },
          "firstRowOnly": true
        }
      },
      {
        "name": "GetCurrentWatermark",
        "type": "Lookup",
        "dependsOn": [
          { "activity": "GetLastWatermark", "dependencyConditions": ["Succeeded"] }
        ],
        "typeProperties": {
          "source": {
            "type": "AzureSqlSource",
            "sqlReaderQuery": {
              "value": "@concat('SELECT MAX(ModifiedDate) as CurrentWatermark FROM ', pipeline().parameters.TableName)",
              "type": "Expression"
            }
          },
          "dataset": { "referenceName": "DS_AzureSql_Source", "type": "DatasetReference" },
          "firstRowOnly": true
        }
      },
      {
        "name": "CopyIncrementalToStorage",
        "type": "Copy",
        "dependsOn": [
          { "activity": "GetCurrentWatermark", "dependencyConditions": ["Succeeded"] }
        ],
        "typeProperties": {
          "source": {
            "type": "AzureSqlSource",
            "sqlReaderQuery": {
              "value": "@concat('SELECT * FROM ', pipeline().parameters.TableName, ' WHERE ModifiedDate > ''', activity('GetLastWatermark').output.firstRow.LastArchive, ''' AND ModifiedDate <= ''', activity('GetCurrentWatermark').output.firstRow.CurrentWatermark, '''')",
              "type": "Expression"
            }
          },
          "sink": {
            "type": "ParquetSink",
            "storeSettings": { "type": "AzureBlobStorageWriteSettings" }
          }
        },
        "inputs": [{ "referenceName": "DS_AzureSql_Source", "type": "DatasetReference" }],
        "outputs": [{
          "referenceName": "DS_Blob_Parquet_Partitioned",
          "type": "DatasetReference",
          "parameters": {
            "FolderPath": "@concat('incremental/', pipeline().parameters.TableName, '/', formatDateTime(utcnow(), 'yyyy/MM/dd'))",
            "FileName": "@concat(pipeline().parameters.TableName, '_incremental_', formatDateTime(utcnow(), 'yyyyMMddHHmmss'), '.parquet')"
          }
        }]
      },
      {
        "name": "UpdateWatermark",
        "type": "SqlServerStoredProcedure",
        "dependsOn": [
          { "activity": "CopyIncrementalToStorage", "dependencyConditions": ["Succeeded"] }
        ],
        "linkedServiceName": { "referenceName": "LS_AzureSql_Control", "type": "LinkedServiceReference" },
        "typeProperties": {
          "storedProcedureName": "dbo.usp_UpdateWatermark",
          "storedProcedureParameters": {
            "TableName": { "value": "@pipeline().parameters.TableName", "type": "String" },
            "NewWatermark": { "value": "@activity('GetCurrentWatermark').output.firstRow.CurrentWatermark", "type": "DateTime" }
          }
        }
      }
    ],
    "parameters": {
      "TableName": { "type": "string" }
    }
  }
}
```

### ADLS Gen2 Alternative for ML Data Lake

For larger-scale ML workloads, use Azure Data Lake Storage Gen2 instead of Blob Storage. ADLS Gen2 provides hierarchical namespace, better performance for analytics, and native integration with Databricks and Synapse.

**ADLS Gen2 Linked Service:**
```json
{
  "name": "LS_ADLS_ML",
  "properties": {
    "type": "AzureBlobFS",
    "typeProperties": {
      "url": "https://mldatalake.dfs.core.windows.net"
    }
  }
}
```

**ADLS Gen2 Parquet Dataset:**
```json
{
  "name": "DS_ADLS_Parquet_ML",
  "properties": {
    "type": "Parquet",
    "linkedServiceName": {
      "referenceName": "LS_ADLS_ML",
      "type": "LinkedServiceReference"
    },
    "typeProperties": {
      "location": {
        "type": "AzureBlobFSLocation",
        "fileSystem": "ml",
        "folderPath": {
          "value": "@dataset().FolderPath",
          "type": "Expression"
        }
      },
      "compressionCodec": "snappy"
    },
    "parameters": {
      "FolderPath": { "type": "String" }
    }
  }
}
```

**ADLS Gen2 path format for Databricks:**
```
abfss://ml@mldatalake.dfs.core.windows.net/training-data/model-name/version=1/
```

**When to use Blob Storage vs ADLS Gen2:**
| Feature | Blob Storage | ADLS Gen2 |
|---------|-------------|-----------|
| Cost | Lower for simple storage | Slightly higher |
| Hierarchical namespace | No (flat) | Yes |
| Databricks integration | Wasbs:// | Abfss:// (preferred) |
| Analytics performance | Good | Better (optimized for Spark) |
| ACL-level permissions | Container level | File/folder level |

### Storage Account Organization for ML Analysis

**Recommended folder structure for archived data and ML artifacts:**
```
storage-account/
  archive/                          # Archived SQL data
    <database-name>/
      <schema>/<table>/
        snapshot_date=YYYY-MM-DD/
          table_YYYYMMDDHHMMSS.parquet
  incremental/                      # Incremental extracts
    <table>/
      YYYY/MM/DD/
        table_incremental_*.parquet
  ml/                               # ML artifacts
    training-data/                  # Curated training datasets
      <model-name>/
        version=<N>/
          train.parquet
          test.parquet
          validation.parquet
    models/                         # Serialized models
      <model-name>/
        version=<N>/
          model.pkl
          metadata.json
    scores/                         # Scoring results
      <model-name>/
        YYYY/MM/DD/
          predictions.parquet
    feature-store/                  # Engineered features
      <feature-set>/
        features.parquet
```

---

## Azure AI Services Integration

### Pattern: Call Azure AI Services from ADF

Use WebActivity to call Azure AI Services (formerly Cognitive Services) for text analytics, anomaly detection, vision, and language tasks.

**Text Analytics (Sentiment Analysis):**
```json
{
  "name": "AnalyzeSentiment",
  "type": "WebActivity",
  "typeProperties": {
    "url": "@concat('https://', pipeline().parameters.CognitiveServicesEndpoint, '/language/:analyze-text?api-version=2025-11-15-preview')",
    "method": "POST",
    "headers": {
      "Content-Type": "application/json",
      "Ocp-Apim-Subscription-Key": {
        "value": "@activity('GetApiKey').output.value",
        "type": "Expression"
      }
    },
    "body": {
      "kind": "SentimentAnalysis",
      "parameters": { "modelVersion": "latest" },
      "analysisInput": {
        "documents": [
          {
            "id": "1",
            "language": "en",
            "text": "@activity('LookupFeedback').output.firstRow.FeedbackText"
          }
        ]
      }
    }
  }
}
```

**Anomaly Detection (Multivariate):**
```json
{
  "name": "DetectAnomalies",
  "type": "WebActivity",
  "typeProperties": {
    "url": "@concat('https://', pipeline().parameters.AnomalyDetectorEndpoint, '/anomalydetector/v1.1/multivariate/models/', pipeline().parameters.ModelId, ':detect-last')",
    "method": "POST",
    "headers": {
      "Content-Type": "application/json",
      "Ocp-Apim-Subscription-Key": {
        "value": "@activity('GetAnomalyKey').output.value",
        "type": "Expression"
      }
    },
    "body": {
      "variables": [
        {
          "variable": "temperature",
          "timestamps": "@activity('LookupTimeSeries').output.value",
          "values": "@activity('LookupValues').output.value"
        }
      ],
      "topContributorCount": 5
    }
  }
}
```

**Get Key Vault Secret for API Keys:**
```json
{
  "name": "GetApiKey",
  "type": "WebActivity",
  "typeProperties": {
    "url": "@concat('https://', pipeline().parameters.KeyVaultName, '.vault.azure.net/secrets/', pipeline().parameters.SecretName, '?api-version=7.3')",
    "method": "GET",
    "authentication": {
      "type": "MSI",
      "resource": "https://vault.azure.net"
    }
  }
}
```

### Pattern: Batch Scoring Azure SQL Data Through AI Services

Process records from SQL in batches through Azure AI Services.

**IMPORTANT:** Lookup activity returns max 5,000 rows and 4 MB. For larger datasets, use pagination (TOP/OFFSET) or Copy Activity to stage data first, then process from storage.

```json
{
  "name": "PL_BatchAIScoring",
  "properties": {
    "activities": [
      {
        "name": "GetRecordBatches",
        "type": "Lookup",
        "typeProperties": {
          "source": {
            "type": "AzureSqlSource",
            "sqlReaderQuery": "SELECT id, text_content FROM dbo.UnprocessedRecords WHERE scored = 0 ORDER BY id"
          },
          "dataset": { "referenceName": "DS_AzureSql", "type": "DatasetReference" },
          "firstRowOnly": false
        }
      },
      {
        "name": "ForEach_ScoreBatch",
        "type": "ForEach",
        "dependsOn": [
          { "activity": "GetRecordBatches", "dependencyConditions": ["Succeeded"] }
        ],
        "typeProperties": {
          "items": { "value": "@activity('GetRecordBatches').output.value", "type": "Expression" },
          "isSequential": true,
          "activities": [
            {
              "name": "CallAIService",
              "type": "WebActivity",
              "typeProperties": {
                "url": "@concat('https://', pipeline().parameters.AIEndpoint, '/language/:analyze-text?api-version=2025-11-15-preview')",
                "method": "POST",
                "headers": {
                  "Content-Type": "application/json",
                  "Ocp-Apim-Subscription-Key": "@pipeline().parameters.AIKey"
                },
                "body": {
                  "kind": "SentimentAnalysis",
                  "analysisInput": {
                    "documents": [{ "id": "@{item().id}", "language": "en", "text": "@{item().text_content}" }]
                  }
                }
              }
            },
            {
              "name": "WriteScoreBack",
              "type": "SqlServerStoredProcedure",
              "dependsOn": [
                { "activity": "CallAIService", "dependencyConditions": ["Succeeded"] }
              ],
              "linkedServiceName": { "referenceName": "LS_AzureSql", "type": "LinkedServiceReference" },
              "typeProperties": {
                "storedProcedureName": "dbo.usp_UpdateSentiment",
                "storedProcedureParameters": {
                  "RecordId": { "value": "@item().id", "type": "Int32" },
                  "Sentiment": { "value": "@activity('CallAIService').output.results.documents[0].sentiment", "type": "String" },
                  "ConfidencePositive": { "value": "@activity('CallAIService').output.results.documents[0].confidenceScores.positive", "type": "Double" }
                }
              }
            }
          ]
        }
      }
    ],
    "parameters": {
      "AIEndpoint": { "type": "string" },
      "AIKey": { "type": "string" }
    }
  }
}
```

---

## Azure OpenAI Global Batch API (LLM Scoring from ADF)

Use the Azure OpenAI Batch API for large-scale LLM inference at 50% less cost than standard endpoints. Ideal for scoring archived datasets with GPT models — text classification, summarization, entity extraction, data enrichment.

### Pattern: Submit Batch Job via WebActivity

**Step 1: Upload JSONL input file to storage (via prior Copy Activity)**

Prepare a JSONL file where each line is an API request:
```jsonl
{"custom_id": "row-1", "method": "POST", "url": "/chat/completions", "body": {"model": "gpt-4o", "messages": [{"role": "system", "content": "Classify sentiment as positive/negative/neutral."}, {"role": "user", "content": "Great product, fast delivery!"}]}}
{"custom_id": "row-2", "method": "POST", "url": "/chat/completions", "body": {"model": "gpt-4o", "messages": [{"role": "system", "content": "Classify sentiment as positive/negative/neutral."}, {"role": "user", "content": "Item arrived damaged, very disappointed."}]}}
```

**Step 2: Upload file to Azure OpenAI**
```json
{
  "name": "UploadBatchInput",
  "type": "WebActivity",
  "typeProperties": {
    "url": "@concat('https://', pipeline().parameters.OpenAIEndpoint, '/openai/files?api-version=2025-03-01-preview')",
    "method": "POST",
    "headers": {
      "api-key": {
        "value": "@activity('GetOpenAIKey').output.value",
        "type": "Expression"
      }
    },
    "body": {
      "purpose": "batch",
      "file": "@activity('ReadBatchFile').output"
    }
  }
}
```

**Step 3: Create batch job**
```json
{
  "name": "CreateBatchJob",
  "type": "WebActivity",
  "dependsOn": [
    { "activity": "UploadBatchInput", "dependencyConditions": ["Succeeded"] }
  ],
  "typeProperties": {
    "url": "@concat('https://', pipeline().parameters.OpenAIEndpoint, '/openai/batches?api-version=2025-03-01-preview')",
    "method": "POST",
    "headers": {
      "Content-Type": "application/json",
      "api-key": {
        "value": "@activity('GetOpenAIKey').output.value",
        "type": "Expression"
      }
    },
    "body": {
      "input_file_id": "@activity('UploadBatchInput').output.id",
      "endpoint": "/chat/completions",
      "completion_window": "24h"
    }
  }
}
```

**Step 4: Poll for completion (Until loop)**
```json
{
  "name": "WaitForBatchCompletion",
  "type": "Until",
  "dependsOn": [
    { "activity": "CreateBatchJob", "dependencyConditions": ["Succeeded"] }
  ],
  "typeProperties": {
    "expression": {
      "value": "@or(equals(variables('BatchStatus'), 'completed'), or(equals(variables('BatchStatus'), 'failed'), equals(variables('BatchStatus'), 'expired')))",
      "type": "Expression"
    },
    "timeout": "1.00:00:00",
    "activities": [
      {
        "name": "CheckBatchStatus",
        "type": "WebActivity",
        "typeProperties": {
          "url": "@concat('https://', pipeline().parameters.OpenAIEndpoint, '/openai/batches/', activity('CreateBatchJob').output.id, '?api-version=2025-03-01-preview')",
          "method": "GET",
          "headers": {
            "api-key": {
              "value": "@activity('GetOpenAIKey').output.value",
              "type": "Expression"
            }
          }
        }
      },
      {
        "name": "SetBatchStatus",
        "type": "SetVariable",
        "dependsOn": [
          { "activity": "CheckBatchStatus", "dependencyConditions": ["Succeeded"] }
        ],
        "typeProperties": {
          "variableName": "BatchStatus",
          "value": "@activity('CheckBatchStatus').output.status"
        }
      },
      {
        "name": "WaitBeforePoll",
        "type": "Wait",
        "dependsOn": [
          { "activity": "SetBatchStatus", "dependencyConditions": ["Succeeded"] }
        ],
        "typeProperties": { "waitTimeInSeconds": 300 }
      }
    ]
  }
}
```

**Key Benefits:**
- **50% cheaper** than standard Azure OpenAI endpoints
- **Separate quota** — does not affect real-time workloads
- **24-hour turnaround** target
- Supports GPT-4o, GPT-4o-mini, and other deployed models
- Ideal for: sentiment analysis, text classification, summarization, entity extraction, data enrichment on archived datasets

**When to Use:**
| Pattern | Use Case |
|---------|----------|
| Azure OpenAI Batch API | LLM-based text analysis on archived data (classification, summarization) |
| Azure ML Batch Endpoints | Traditional ML models (regression, classification, custom models) |
| Azure AI Services | Pre-built AI tasks (sentiment, language detection, anomaly detection) |
| Databricks ML | Custom training, distributed deep learning, MLflow |

---

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

---

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

---

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

---

## Best Practices

### Data Architecture
1. **Archive first, analyze later** - Copy ephemeral SQL data to Storage as Parquet before running ML
2. **Use Parquet format** - Columnar format is optimal for ML workloads (compression, column pruning)
3. **Date-partition storage** - Use `snapshot_date=YYYY-MM-DD` partitioning for versioned archives
4. **Separate containers** - Use distinct containers for raw archives, features, models, and scores

### ML Orchestration
1. **Databricks Job activity** for complex ML (training, MLflow, distributed compute)
2. **WebActivity + Azure ML batch endpoints** for managed ML inference (SDK v2)
3. **WebActivity + Azure OpenAI Batch API** for LLM scoring at 50% cost (text analysis, enrichment)
4. **WebActivity + Azure AI Services** for pre-built AI capabilities (NLP, vision, anomaly detection)
5. **Data Flows** for feature engineering when Spark-based transformations are needed
6. **Execute Pipeline pattern** to modularize archive -> feature -> train -> score steps
7. **T-SQL PREDICT** for in-database scoring (SQL Server/Managed Instance/Synapse only — not Azure SQL Database)

### Security
1. **Managed Identity** for all Azure service connections (ML workspace, Storage, SQL)
2. **Key Vault** for API keys (Azure AI Services, external endpoints)
3. **Never hardcode** secrets, connection strings, or API keys in pipeline JSON
4. **Least privilege** - Grant only required roles (Blob Data Contributor for storage, ML workspace roles for ML)

### Cost Optimization
1. **Use General Purpose compute** for Data Flows unless memory-intensive
2. **Databricks serverless** compute for variable ML workloads
3. **Set appropriate timeouts** on ML activities (training can be long-running)
4. **Batch scoring** over real-time when latency allows (cheaper, more efficient)
5. **Incremental extraction** from SQL to avoid re-copying unchanged data

## Resources

- [ADF + Azure ML Execute Pipeline](https://learn.microsoft.com/azure/data-factory/transform-data-using-machine-learning)
- [Azure ML Batch Endpoints](https://learn.microsoft.com/azure/machine-learning/how-to-use-batch-endpoint)
- [Run Batch Endpoints from ADF](https://learn.microsoft.com/azure/machine-learning/how-to-use-batch-azure-data-factory)
- [Migrate SDK v1 Pipeline Endpoints to v2 Batch Endpoints](https://learn.microsoft.com/azure/machine-learning/migrate-to-v2-deploy-pipelines)
- [Azure OpenAI Global Batch API](https://learn.microsoft.com/azure/foundry/openai/how-to/batch)
- [ADF Web Activity](https://learn.microsoft.com/azure/data-factory/control-flow-web-activity)
- [ADF Mapping Data Flows](https://learn.microsoft.com/azure/data-factory/concepts-data-flow-overview)
- [Azure AI Services](https://learn.microsoft.com/azure/ai-services/)
- [Microsoft Foundry](https://learn.microsoft.com/azure/foundry/foundry-models/concepts/endpoints)
- [Databricks Job Activity](https://learn.microsoft.com/azure/data-factory/transform-data-using-databricks-spark-job)
- [Migrate AI Inference SDK to OpenAI SDK](https://learn.microsoft.com/azure/ai-foundry/how-to/model-inference-to-openai-migration)
