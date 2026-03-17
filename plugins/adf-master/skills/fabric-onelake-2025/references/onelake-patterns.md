# OneLake Integration Patterns

## Pattern 1: Azure Data Lake Gen2 to OneLake via Shortcuts

**Concept:** Use OneLake shortcuts instead of copying data

OneLake shortcuts allow you to reference data in Azure Data Lake Gen2 without physically copying it:

1. In Fabric Lakehouse, create shortcut to ADLS Gen2 container
2. Data appears in OneLake immediately (zero-copy)
3. Use ADF to orchestrate transformations on shortcut data
4. Write results back to OneLake

**Benefits:**
- Zero data duplication
- Real-time data access
- Reduced storage costs
- Single source of truth

**ADF Pipeline Pattern:**
```json
{
  "name": "PL_Process_Shortcut_Data",
  "activities": [
    {
      "name": "TransformShortcutData",
      "type": "ExecuteDataFlow",
      "typeProperties": {
        "dataFlow": {
          "referenceName": "DF_Transform",
          "type": "DataFlowReference"
        },
        "compute": {
          "coreCount": 8,
          "computeType": "General"
        }
      }
    },
    {
      "name": "WriteToCuratedZone",
      "type": "Copy",
      "typeProperties": {
        "source": {
          "type": "ParquetSource"
        },
        "sink": {
          "type": "LakehouseTableSink",
          "tableActionOption": "overwrite"
        }
      }
    }
  ]
}
```

## Pattern 2: Incremental Load to Fabric Lakehouse

```json
{
  "name": "PL_Incremental_Load_To_Fabric",
  "activities": [
    {
      "name": "GetLastWatermark",
      "type": "Lookup",
      "typeProperties": {
        "source": {
          "type": "LakehouseTableSource",
          "query": "SELECT MAX(LoadTimestamp) as LastLoad FROM ControlTable"
        }
      }
    },
    {
      "name": "CopyIncrementalData",
      "type": "Copy",
      "dependsOn": [
        {
          "activity": "GetLastWatermark",
          "dependencyConditions": ["Succeeded"]
        }
      ],
      "typeProperties": {
        "source": {
          "type": "AzureSqlSource",
          "sqlReaderQuery": "SELECT * FROM dbo.Orders WHERE ModifiedDate > '@{activity('GetLastWatermark').output.firstRow.LastLoad}'"
        },
        "sink": {
          "type": "LakehouseTableSink",
          "tableActionOption": "append"
        }
      }
    },
    {
      "name": "UpdateWatermark",
      "type": "Script",
      "dependsOn": [
        {
          "activity": "CopyIncrementalData",
          "dependencyConditions": ["Succeeded"]
        }
      ],
      "linkedServiceName": {
        "referenceName": "FabricLakehouseLinkedService",
        "type": "LinkedServiceReference"
      },
      "typeProperties": {
        "scripts": [
          {
            "type": "Query",
            "text": "INSERT INTO ControlTable VALUES ('@{utcnow()}')"
          }
        ]
      }
    }
  ]
}
```

## Pattern 3: Cross-Platform Pipeline with Invoke Pipeline

**Invoke Pipeline Activity for Cross-Platform Calls**

```json
{
  "name": "PL_ADF_Orchestrates_Fabric_Pipeline",
  "activities": [
    {
      "name": "PrepareDataInADF",
      "type": "Copy",
      "typeProperties": {
        "source": {
          "type": "AzureSqlSource"
        },
        "sink": {
          "type": "LakehouseTableSink"
        }
      }
    },
    {
      "name": "InvokeFabricPipeline",
      "type": "InvokePipeline",
      "dependsOn": [
        {
          "activity": "PrepareDataInADF",
          "dependencyConditions": ["Succeeded"]
        }
      ],
      "typeProperties": {
        "workspaceId": "12345678-1234-1234-1234-123456789abc",
        "pipelineId": "87654321-4321-4321-4321-cba987654321",
        "waitOnCompletion": true,
        "parameters": {
          "processDate": "@pipeline().parameters.RunDate",
          "environment": "production"
        }
      }
    }
  ]
}
```
