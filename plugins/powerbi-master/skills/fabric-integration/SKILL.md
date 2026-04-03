---
name: fabric-integration
description: |
  This skill should be used when the user asks about "Microsoft Fabric",
  "Direct Lake", "Direct Lake mode", "OneLake", "lakehouse Power BI",
  "Fabric warehouse", "Dataflow Gen2", "Fabric notebooks",
  "Fabric workspace", "Fabric capacity", "delta tables Power BI",
  "lakehouse connectivity", "Power BI in Fabric", "Fabric semantic model",
  "medallion architecture", "Semantic Link", "sempy", "V-Order",
  "Eventstream", "KQL Database", "Data Activator",
  or "composite model Direct Lake".
---

# Microsoft Fabric Integration

## Overview

Microsoft Fabric is the unified analytics platform that includes Power BI, Data Factory, Data Engineering, Data Science, Real-Time Intelligence, and Data Warehouse. Power BI is deeply integrated as the visualization and semantic modeling layer of Fabric.

## Direct Lake Mode

Direct Lake is a storage mode exclusive to Fabric that reads data directly from delta tables in OneLake without importing or sending DirectQuery requests.

### How Direct Lake Works

1. **Framing:** On refresh, Direct Lake copies only metadata (Parquet file references) from delta tables -- takes seconds
2. **On-demand loading:** When a query hits the model, data is loaded from Parquet files directly into the VertiPaq engine
3. **No data duplication:** Unlike Import, no copy of data is stored in the semantic model
4. **Near-import performance:** Once loaded into memory, queries run at VertiPaq speed

### Direct Lake vs Import vs DirectQuery

| Feature | Import | DirectQuery | Direct Lake |
|---------|--------|-------------|-------------|
| Data freshness | Snapshot at refresh | Real-time | Near real-time (after framing) |
| Query performance | Fastest (all in memory) | Depends on source | Near-import (on-demand load) |
| Refresh time | Minutes to hours | N/A | Seconds (framing only) |
| Refresh cost | High (full data copy) | None | Very low (metadata only) |
| Data size limit | 10GB (Premium), 1GB (PBIX) | Source limit | Fabric capacity limit |
| DAX support | Full | Limited | Full |
| Calculated columns | Yes | No | Yes |
| Source requirement | Any | Any | OneLake delta tables only |
| Capacity requirement | Any | Any | Fabric F-SKU |

### Direct Lake Variants (2025-2026 GA)

| Variant | Source | Multi-Source | Fallback | Use Case | GA Status |
|---------|--------|-------------|----------|----------|-----------|
| Direct Lake on OneLake (DL/OL) | OneLake delta files | Yes (multiple Fabric items) | NO fallback | Flexible, multiple lakehouses | GA |
| Direct Lake on SQL (DL/SQL) | Fabric SQL endpoint | No (single Fabric item) | Falls back to DirectQuery | SQL-centric, single source | GA |

### Creating a Direct Lake Semantic Model

**In Power BI Desktop (2025+ preview):**
1. Get Data > OneLake data hub
2. Select Fabric lakehouse or warehouse
3. Choose tables (loaded as Direct Lake automatically)
4. Build measures and relationships in Desktop
5. Publish to Fabric workspace

**Via Fabric Service:**
1. Open lakehouse/warehouse in Fabric
2. Click "New semantic model"
3. Select tables to include
4. Open model in web to add measures and relationships

**Programmatically via TOM:**
```csharp
var database = new Database() { Name = "DirectLakeModel" };
var model = new Model() { Name = "DirectLakeModel" };
database.Model = model;

// Direct Lake partition source
var table = new Table() { Name = "Sales" };
table.Partitions.Add(new Partition() {
    Name = "Sales-DL",
    Mode = ModeType.DirectLake,
    Source = new EntityPartitionSource() {
        EntityName = "Sales",
        SchemaName = "dbo",
        ExpressionSource = new ExpressionSource() {
            Expression = "DatabaseQuery"
        }
    }
});
model.Tables.Add(table);
```

**Critical distinction:** DL/OL does NOT fall back to DirectQuery. If data cannot be served from memory, the query fails. This means DL/OL models must be carefully sized within capacity guardrails.

### Direct Lake Guardrails by Capacity

| Guardrail | F2 | F4 | F8 | F16 | F32 | F64 | F128 |
|-----------|----|----|----|----|-----|-----|------|
| Max model size on disk | 2 GB | 4 GB | 8 GB | 16 GB | 32 GB | 64 GB | 128 GB |
| Max rows per table | 300M | 300M | 300M | 1.5B | 3B | 6B | 6B |
| Max files/row groups per table | 1K | 1K | 1K | 1K | 1K | 5K | 5K |
| Concurrent DL queries | 4 | 8 | 16 | 32 | 64 | 128 | 256 |

**Max Memory** is a soft limit for paging -- exceeding it causes performance degradation but not failure.

**Max model size on disk/OneLake** is a hard guardrail -- exceeding causes DQ fallback (DL/SQL) or query failure (DL/OL).

### Direct Lake Fallback Configuration

| Fallback Behavior | Setting | Impact |
|-------------------|---------|--------|
| Automatic fallback to DirectQuery | Default (DL/SQL only) | Query still works but slower |
| Block fallback | `DirectLakeBehavior = DirectLakeOnly` | Query fails if cannot serve from DL |
| No fallback option | Default (DL/OL) | Queries always fail if data unavailable |

**Monitor fallback** in Fabric Capacity Metrics app -- frequent fallback indicates model design issues.

**Common fallback triggers (DL/SQL):**
- Columns not loaded into memory due to capacity limits
- Calculated columns on Direct Lake tables (may trigger DQ fallback)
- Certain DAX patterns that require full table scan
- Stale framing (delta tables changed but model not re-framed)
- File/row-group count exceeding capacity guardrails

### Power BI Embedded with Direct Lake (GA March 2025)

Direct Lake mode is now fully supported for embedded analytics, backed by Microsoft SLA. Generate embed tokens for Direct Lake semantic models using the same embed token API as Import/DirectQuery models.

### Framing (Refresh)

```bash
# Trigger framing via REST API
POST https://api.powerbi.com/v1.0/myorg/groups/{workspaceId}/datasets/{datasetId}/refreshes
{
  "type": "Automatic"
}
```

Framing is extremely fast (seconds) compared to Import refresh (minutes/hours). Schedule frequent framing for near-real-time data.

## OneLake

OneLake is Fabric's unified data lake -- a single store for all analytics data, built on Azure Data Lake Storage Gen2 with delta format.

### OneLake Shortcuts

Connect to external data without copying:

| Shortcut Type | Source | Use Case |
|---------------|--------|----------|
| OneLake | Another Fabric item | Cross-workspace data sharing |
| ADLS Gen2 | Azure Data Lake | Existing Azure data |
| S3 | Amazon S3 | Multi-cloud data |
| GCS | Google Cloud Storage | Multi-cloud data |
| Dataverse | Dynamics 365 | Business app data |

### OneLake File API

Access OneLake data programmatically:
```python
# Using Azure Storage SDK (OneLake supports ADLS Gen2 API)
from azure.storage.filedatalake import DataLakeServiceClient

service_client = DataLakeServiceClient(
    account_url="https://onelake.dfs.fabric.microsoft.com",
    credential=token_credential
)

file_system_client = service_client.get_file_system_client(workspace_id)
directory_client = file_system_client.get_directory_client(f"{lakehouse_name}.Lakehouse/Tables")
```

## Fabric Lakehouse

A lakehouse combines data lake flexibility with warehouse SQL capabilities:

**Power BI connectivity:**
- **SQL Analytics Endpoint:** Read-only SQL endpoint for DirectQuery or Direct Lake
- **Delta tables:** Native format for Direct Lake
- **Notebooks:** Write data from Spark notebooks, read in Power BI

### Lakehouse to Power BI Flow

```
[Data Sources] --> [Fabric Notebooks/Pipelines] --> [Lakehouse Delta Tables]
     |                                                       |
     v                                                       v
[Power Query Dataflows Gen2]                    [Direct Lake Semantic Model]
                                                             |
                                                             v
                                                     [Power BI Reports]
```

## Fabric Warehouse

Fully managed SQL warehouse in Fabric:

- **T-SQL support:** Full DML (INSERT, UPDATE, DELETE, MERGE)
- **Auto-distributed storage:** No index tuning needed
- **Direct Lake compatible:** Tables accessible as Direct Lake sources
- **Cross-database queries:** Query across warehouses and lakehouses

## Dataflow Gen2

Cloud-based ETL in Fabric, evolution of Power BI Dataflows:

| Feature | Dataflow Gen1 | Dataflow Gen2 |
|---------|--------------|---------------|
| Destinations | Power BI dataset only | Lakehouse, Warehouse, KQL DB, Azure SQL, ADLS Gen2, SharePoint |
| Compute | Power Query Online | Power Query Online + Fabric Spark |
| Staging | Optional (Premium) | Always enabled |
| Incremental refresh | Limited | Full support (GA to Lakehouse 2025) |
| Monitoring | Basic | Fabric monitoring hub |
| CI/CD | Not supported | Git integration + deployment pipelines (2025) |
| Variable library | Not supported | Parameterized source paths and expressions (2025) |
| Publish performance | Single-threaded validation | Parallelized query validations (2026) |

**Gen1 deprecation:** Microsoft has announced Gen1 is legacy. Migrate to Gen2 for all new development. Gen2 supports all Gen1 connectors plus Fabric-native destinations.

### Dataflow Gen2 Output Destinations (2025-2026)

| Destination | Protocol |
|-------------|----------|
| Fabric Lakehouse delta tables | Delta/Parquet |
| Fabric Warehouse tables | T-SQL |
| Fabric KQL Database tables | KQL |
| Fabric SQL Database tables | T-SQL |
| Azure SQL Database tables | T-SQL |
| Azure Data Explorer (Kusto) tables | KQL |
| ADLS Gen2 files | File (CSV, Parquet) |
| SharePoint files | File |

### Dataflow Gen2 to Direct Lake Pipeline

1. Create Dataflow Gen2 in Fabric workspace
2. Connect to source (any Power Query connector)
3. Set destination to Lakehouse (creates delta tables)
4. Create semantic model on top of lakehouse tables (Direct Lake)
5. Build reports on the semantic model

## Real-Time Intelligence

Fabric Real-Time Intelligence items now have GA lifecycle management (2025):

| Item | ALM Support | Integration |
|------|-------------|-------------|
| Eventstream | Git + deployment pipelines | Ingests from Event Hubs, Kafka, IoT Hub, custom APIs |
| Eventhouse | Git + deployment pipelines | Houses KQL databases |
| KQL Database | Git + deployment pipelines | DirectQuery from Power BI |
| Real-time Dashboard | Git + deployment pipelines | Native Fabric dashboard for streaming |
| Data Activator | Git + deployment pipelines | Alert/trigger on data conditions |

### Eventstream to Power BI Pipeline

```
[Event Hubs/Kafka/IoT Hub] --> [Eventstream] --> [KQL Database] --> [Power BI DirectQuery]
                                     |
                                     +--> [Lakehouse] --> [Power BI Direct Lake]
```

## Notebooks for Data Prep

Fabric notebooks (PySpark/Spark SQL) write data that Power BI consumes:

```python
# Write DataFrame to lakehouse delta table
df.write.format("delta").mode("overwrite").saveAsTable("Sales")

# Optimized write with partitioning
df.write.format("delta") \
    .partitionBy("Year", "Month") \
    .mode("overwrite") \
    .option("overwriteSchema", "true") \
    .saveAsTable("Sales")

# V-Order optimization (improves Direct Lake read performance)
spark.conf.set("spark.sql.parquet.vorder.enabled", "true")
df.write.format("delta").mode("overwrite").saveAsTable("Sales")
```

**V-Order:** A write-time optimization that orders Parquet data for faster Direct Lake reads. Enable in notebook or pipeline configuration.

## Fabric Items in Power BI Context

| Fabric Item | Power BI Integration |
|-------------|---------------------|
| Lakehouse | Direct Lake, SQL endpoint for DQ |
| Warehouse | Direct Lake, T-SQL queries |
| KQL Database | DirectQuery via KQL connector |
| Notebooks | Data prep, model management via sempy |
| Data Pipelines | Orchestrate refresh, data movement |
| Dataflow Gen2 | ETL to lakehouse for DL consumption |
| Eventstream | Real-time data to KQL, then to PBI |
| ML Models | Score in notebooks, results to lakehouse |

## Semantic Link (sempy)

Python library for Power BI semantic model interaction in Fabric notebooks:

```python
import sempy.fabric as fabric

# List datasets in workspace
datasets = fabric.list_datasets()

# Read data from semantic model using DAX
df = fabric.evaluate_dax(
    dataset="SalesModel",
    dax_string="EVALUATE SUMMARIZECOLUMNS('Date'[Year], 'Product'[Category], \"Sales\", [Total Sales])"
)

# Read model metadata
tables = fabric.list_tables(dataset="SalesModel")
measures = fabric.list_measures(dataset="SalesModel")

# Refresh dataset
fabric.refresh_dataset(dataset="SalesModel")
```

## Composite Models with Direct Lake (2025 Preview)

Mix Direct Lake tables with Import tables in a single semantic model:

| Source Table | Storage Mode | When to Use |
|-------------|-------------|-------------|
| Lakehouse fact table | Direct Lake | Large transaction data |
| Lakehouse dimension | Direct Lake | Shared dimension from gold layer |
| External reference data | Import | Small tables not in Fabric |
| Budget/forecast | Import | Data from Excel or external source |

**Key consideration:** Composite model queries involving both DL and Import tables may have different performance characteristics. Test with production data volumes.

## Additional Resources

### Reference Files
- **`references/fabric-architecture-patterns.md`** -- Medallion architecture, data mesh patterns, and Fabric workspace design strategies
