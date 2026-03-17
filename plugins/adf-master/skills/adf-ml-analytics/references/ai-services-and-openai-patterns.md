# Azure AI Services and OpenAI Batch API Patterns

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

## Azure OpenAI Global Batch API (LLM Scoring from ADF)

Use the Azure OpenAI Batch API for large-scale LLM inference at 50% less cost than standard endpoints. Ideal for scoring archived datasets with GPT models -- text classification, summarization, entity extraction, data enrichment.

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
- **Separate quota** -- does not affect real-time workloads
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
