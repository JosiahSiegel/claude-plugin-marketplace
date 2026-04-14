---
name: adf-ml-analytics
description: ADF + Azure ML and analytics integrations. PROACTIVELY activate for: (1) Azure ML batch endpoints invoked from ADF, (2) Azure OpenAI Batch API pipeline patterns, (3) ADF ML scoring orchestration, (4) SQL to Storage archival pipelines, (5) AI Services integration via REST connector, (6) Databricks notebook execution from ADF, (7) Data Flow feature engineering, (8) Synapse / Fabric integration from ADF, (9) Cognitive Search indexer triggers, (10) Power BI dataset refresh via REST. Provides: REST connector recipes, Databricks linked service setup, Data Flow templates, and end-to-end ML scoring pipelines.
---

# Azure Data Factory Machine Learning & Analytics Patterns

## Overview

Azure Data Factory orchestrates ML workflows by integrating with Azure Machine Learning, Azure AI Services, Databricks ML, and Azure SQL Database. This skill covers patterns for extracting data from ephemeral sources (like Azure SQL Database), archiving to Azure Storage for long-term analysis, and leveraging ML services for scoring and insights.

## Deprecation Notices & Platform Changes (Current March 2026)

**Azure AI Foundry -> Microsoft Foundry (November 2025)**
- At Ignite November 2025, Microsoft renamed Azure AI Foundry to **Microsoft Foundry**.
- Microsoft Foundry is the unified AI platform: agents, workflows, models, and tools under one resource provider.
- ADF is positioned as the **data orchestration layer** within Microsoft Foundry -- handling ingestion, transformation, feature preparation, and downstream consumption by models and agents.
- New AI features are primarily landing in **Fabric Data Factory** (Copilot, natural language pipeline generation). ADF classic remains fully supported but receives fewer new features.

**Azure ML SDK v1 - SUPPORT ENDING JUNE 2026**
- Deprecated: March 31, 2025. Support ends: **June 30, 2026 (3 months away).**
- Impact: `AzureMLExecutePipeline` activity uses SDK v1 published pipelines. These will stop working after June 2026.
- Related SDKs also retiring: `azureml-train-core`, `azureml-pipeline`, `azureml-pipeline-core`, `azureml-pipeline-steps`.
- **Migration required:** Use Azure ML SDK v2 batch endpoints via WebActivity (see `references/azure-ml-patterns.md`).
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
- "Azure Cognitive Services" -> "Azure AI Services" -> now part of **Microsoft Foundry**.
- API endpoints remain the same; branding has changed.

**Apache Airflow in ADF - DEPRECATED**
- Deprecated in early 2025 for new customers. Existing deployments continue to function.
- Migration: Use Fabric Data Factory, native ADF pipelines, or standalone Airflow deployments.

---

## Integration Patterns Quick Reference

| Pattern | Activity Type | Summary | Details |
|---------|--------------|---------|---------|
| **Azure ML (Legacy SDK v1)** | AzureMLExecutePipeline | Execute published ML pipelines via SDK v1 linked service. Support ends June 2026 -- migrate to batch endpoints. | See `references/azure-ml-patterns.md` |
| **Azure ML Batch Endpoints (SDK v2)** | WebActivity | Recommended approach for batch inference. Submit jobs to batch endpoints via REST, poll for completion with Until loop. | See `references/azure-ml-patterns.md` |
| **Azure ML Online Endpoints** | WebActivity | Real-time scoring of individual records or small batches via managed online endpoints with MSI auth. | See `references/azure-ml-patterns.md` |
| **T-SQL PREDICT** | SqlServerStoredProcedure | In-database ONNX model scoring. Available on SQL Server 2017+, SQL MI, and Synapse -- **not** Azure SQL Database. | See `references/sql-archival-patterns.md` |
| **sp_execute_external_script** | SqlServerStoredProcedure | Run Python/R scripts inside SQL Managed Instance with ML Services enabled. Good for small-medium datasets. | See `references/sql-archival-patterns.md` |
| **SQL to Storage Archival** | Copy (ForEach) | Archive ephemeral SQL data to Parquet in Blob/ADLS Gen2. Includes full-snapshot and incremental watermark patterns. | See `references/sql-archival-patterns.md` |
| **Azure AI Services** | WebActivity | Call pre-built AI (sentiment, anomaly detection, vision) via REST. Use Key Vault for API keys. Batch scoring with ForEach. | See `references/ai-services-and-openai-patterns.md` |
| **Azure OpenAI Batch API** | WebActivity | LLM scoring at 50% less cost. Upload JSONL, create batch job, poll for completion. Ideal for text classification and enrichment. | See `references/ai-services-and-openai-patterns.md` |
| **Databricks ML** | DatabricksJob | Orchestrate ML training and batch scoring via Databricks Jobs with MLflow tracking. Extract from SQL, score, write back. | See `references/databricks-ml-and-e2e-patterns.md` |
| **Data Flow Features** | ExecuteDataFlow | Spark-based feature engineering with window functions, derived columns, pivots, and filters before ML scoring. | See `references/databricks-ml-and-e2e-patterns.md` |
| **End-to-End ML Pipeline** | ExecutePipeline + Switch | Modular pipeline: archive -> feature engineering -> train or score (Switch activity) using Databricks sub-pipelines. | See `references/databricks-ml-and-e2e-patterns.md` |

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
7. **T-SQL PREDICT** for in-database scoring (SQL Server/Managed Instance/Synapse only -- not Azure SQL Database)

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

## Additional Reference Files

Detailed JSON examples and implementation patterns are in the `references/` directory:

- **`references/azure-ml-patterns.md`** - Azure ML ExecutePipeline (legacy SDK v1), batch endpoints (SDK v2), and online endpoints with complete activity JSON
- **`references/sql-archival-patterns.md`** - T-SQL PREDICT, sp_execute_external_script, full/incremental SQL archival pipelines, ADLS Gen2 configuration, and storage organization
- **`references/ai-services-and-openai-patterns.md`** - Azure AI Services (sentiment, anomaly detection), Azure OpenAI Batch API (JSONL upload, job creation, polling), and batch scoring patterns
- **`references/databricks-ml-and-e2e-patterns.md`** - Databricks ML training/scoring pipelines, Data Flow feature engineering, and end-to-end ML pipeline with Switch activity
