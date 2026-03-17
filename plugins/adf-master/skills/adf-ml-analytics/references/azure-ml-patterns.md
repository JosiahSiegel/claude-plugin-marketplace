# Azure Machine Learning Integration Patterns

## AzureMLExecutePipeline Activity (Legacy - SDK v1, support ends June 2026)

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

## Azure ML Batch Endpoints (Recommended -- SDK v2)

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

## Azure ML Online Endpoints (Real-Time Scoring)

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
