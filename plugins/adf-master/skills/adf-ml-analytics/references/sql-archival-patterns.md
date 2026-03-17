# Azure SQL Scoring and Storage Archival Patterns

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

**Availability -- PREDICT is NOT available in Azure SQL Database:**
| Platform | PREDICT Support |
|----------|----------------|
| SQL Server 2017+ | RevoScaleR/revoscalepy models |
| Azure SQL Managed Instance | RevoScaleR/revoscalepy models |
| Azure Synapse Analytics | ONNX models |
| Azure SQL Database | Not supported |
| Azure SQL Edge | Retired September 2025 |

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
