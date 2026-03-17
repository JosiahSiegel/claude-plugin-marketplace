# Databricks Job Activity JSON Examples

## Legacy vs Current Pattern

**Old Pattern (Notebook Activity - LEGACY):**
```json
{
  "name": "RunNotebook",
  "type": "DatabricksNotebook",  // DEPRECATED - Migrate to DatabricksJob
  "linkedServiceName": { "referenceName": "DatabricksLinkedService" },
  "typeProperties": {
    "notebookPath": "/Users/user@example.com/MyNotebook",
    "baseParameters": { "param1": "value1" }
  }
}
```

**New Pattern (Databricks Job Activity - CURRENT 2025):**
```json
{
  "name": "RunDatabricksWorkflow",
  "type": "DatabricksJob",  // Correct activity type (NOT DatabricksSparkJob)
  "linkedServiceName": { "referenceName": "DatabricksLinkedService" },
  "typeProperties": {
    "jobId": "123456",  // Reference existing Databricks Workflow Job
    "jobParameters": {  // Pass parameters to the Job
      "param1": "value1",
      "runDate": "@pipeline().parameters.ProcessingDate"
    }
  },
  "policy": {
    "timeout": "0.12:00:00",
    "retry": 2,
    "retryIntervalInSeconds": 30
  }
}
```

## Create Databricks Job (Workspace Side)

```json
{
  "name": "Data Processing Job",
  "tasks": [
    {
      "task_key": "ingest",
      "notebook_task": {
        "notebook_path": "/Notebooks/Ingest",
        "base_parameters": {}
      },
      "job_cluster_key": "small_cluster"
    },
    {
      "task_key": "transform",
      "depends_on": [{ "task_key": "ingest" }],
      "notebook_task": {
        "notebook_path": "/Notebooks/Transform"
      },
      "job_cluster_key": "medium_cluster"
    },
    {
      "task_key": "load",
      "depends_on": [{ "task_key": "transform" }],
      "notebook_task": {
        "notebook_path": "/Notebooks/Load"
      },
      "job_cluster_key": "small_cluster"
    }
  ],
  "job_clusters": [
    {
      "job_cluster_key": "small_cluster",
      "new_cluster": {
        "spark_version": "13.3.x-scala2.12",
        "node_type_id": "Standard_DS3_v2",
        "num_workers": 2
      }
    },
    {
      "job_cluster_key": "medium_cluster",
      "new_cluster": {
        "spark_version": "13.3.x-scala2.12",
        "node_type_id": "Standard_DS4_v2",
        "num_workers": 8
      }
    }
  ]
}
```

## Complete ADF Pipeline with Databricks Job Activity

```json
{
  "name": "PL_Databricks_Serverless_Workflow",
  "properties": {
    "activities": [
      {
        "name": "ExecuteDatabricksWorkflow",
        "type": "DatabricksJob",
        "dependsOn": [],
        "policy": {
          "timeout": "0.12:00:00",
          "retry": 2,
          "retryIntervalInSeconds": 30
        },
        "typeProperties": {
          "jobId": "123456",
          "jobParameters": {
            "input_path": "/mnt/data/input",
            "output_path": "/mnt/data/output",
            "run_date": "@pipeline().parameters.runDate",
            "environment": "@pipeline().parameters.environment"
          }
        },
        "linkedServiceName": {
          "referenceName": "DatabricksLinkedService_Serverless",
          "type": "LinkedServiceReference"
        }
      },
      {
        "name": "LogJobExecution",
        "type": "WebActivity",
        "dependsOn": [
          {
            "activity": "ExecuteDatabricksWorkflow",
            "dependencyConditions": ["Succeeded"]
          }
        ],
        "typeProperties": {
          "url": "@pipeline().parameters.LoggingEndpoint",
          "method": "POST",
          "body": {
            "jobId": "123456",
            "runId": "@activity('ExecuteDatabricksWorkflow').output.runId",
            "status": "Succeeded",
            "duration": "@activity('ExecuteDatabricksWorkflow').output.executionDuration"
          }
        }
      }
    ],
    "parameters": {
      "runDate": {
        "type": "string",
        "defaultValue": "@utcnow()"
      },
      "environment": {
        "type": "string",
        "defaultValue": "production"
      },
      "LoggingEndpoint": {
        "type": "string"
      }
    }
  }
}
```

## Linked Service Configuration

**Serverless Linked Service (Recommended - No Cluster Configuration):**
```json
{
  "name": "DatabricksLinkedService_Serverless",
  "type": "Microsoft.DataFactory/factories/linkedservices",
  "properties": {
    "type": "AzureDatabricks",
    "typeProperties": {
      "domain": "https://adb-123456789.azuredatabricks.net",
      "authentication": "MSI"  // Managed Identity (recommended 2025)
      // NO existingClusterId or newClusterNodeType needed for serverless!
      // The Databricks Job activity automatically uses serverless compute
    }
  }
}
```

**Alternative: Access Token Authentication:**
```json
{
  "name": "DatabricksLinkedService_Token",
  "type": "Microsoft.DataFactory/factories/linkedservices",
  "properties": {
    "type": "AzureDatabricks",
    "typeProperties": {
      "domain": "https://adb-123456789.azuredatabricks.net",
      "accessToken": {
        "type": "AzureKeyVaultSecret",
        "store": {
          "referenceName": "AzureKeyVault",
          "type": "LinkedServiceReference"
        },
        "secretName": "databricks-access-token"
      }
    }
  }
}
```

**CRITICAL: For Databricks Job activity, DO NOT specify cluster properties in the linked service. The job configuration in Databricks workspace controls compute resources.**
