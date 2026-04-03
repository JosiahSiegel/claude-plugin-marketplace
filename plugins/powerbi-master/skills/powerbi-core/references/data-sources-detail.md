# Data Sources - Detailed Configuration

## SQL Server Family

### SQL Server (on-premises)
```
Server: servername\instancename
Database: DatabaseName
Authentication: Windows | SQL Server | Azure AD
Gateway: Required (standard or personal)
Connectivity: Import or DirectQuery
```

**Connection string format:**
```
Data Source=server\instance;Initial Catalog=dbname;Integrated Security=True
```

**Query folding:** Fully supported. Native SQL query passthrough available.

### Azure SQL Database
```
Server: servername.database.windows.net
Database: DatabaseName
Authentication: SQL Server | Azure AD | Managed Identity (for dataflows)
Gateway: Not required (cloud-to-cloud)
Connectivity: Import or DirectQuery
```

**Best practice:** Use Azure AD authentication with conditional access policies. Enable "Assume Referential Integrity" for DirectQuery.

### Azure Synapse Analytics (Dedicated SQL Pool)
```
Server: workspacename.sql.azuresynapse.net
Database: PoolName
Authentication: SQL | Azure AD
Connectivity: Import or DirectQuery (preferred for large datasets)
```

**DirectQuery recommended** for Synapse due to massive data volumes. Synapse handles query distribution across nodes.

### Azure Synapse Analytics (Serverless SQL Pool)
```
Server: workspacename-ondemand.sql.azuresynapse.net
Database: DatabaseName (or master for ad-hoc)
Connectivity: DirectQuery strongly recommended
```

**Warning:** Import mode against serverless pool charges per TB scanned on every refresh. Use DirectQuery or build views for controlled access.

## Azure Data Services

### Azure Cosmos DB
```
Connector: Azure Cosmos DB v2 (recommended)
Connection: AccountEndpoint=https://account.documents.azure.com:443/;AccountKey=...
Container: collection name
Connectivity: Import only (no DirectQuery)
```

**Limitations:**
- Flattening nested JSON can be complex in Power Query
- Large datasets may timeout -- use incremental refresh or pre-aggregate
- RU consumption during refresh can be significant

### Azure Data Explorer (Kusto)
```
Cluster: https://clustername.region.kusto.windows.net
Database: DatabaseName
Authentication: Azure AD
Connectivity: Import or DirectQuery
```

**DirectQuery is preferred** for Kusto -- it translates DAX to KQL efficiently. Native KQL passthrough supported.

### Azure Blob Storage / Data Lake Storage Gen2
```
Account: https://accountname.blob.core.windows.net (Blob)
         https://accountname.dfs.core.windows.net (ADLS Gen2)
Authentication: Account Key | SAS Token | Azure AD
File formats: CSV, JSON, Parquet, Excel, XML
Connectivity: Import only
```

**Best practice for ADLS Gen2:** Use Parquet format for best performance. Organize files with partitioned folder structure (year/month/day).

## Cloud Databases

### Snowflake
```
Server: account.region.snowflakecomputing.com
Warehouse: WAREHOUSE_NAME
Database: DATABASE_NAME
Schema: SCHEMA_NAME
Authentication: Username/Password | Azure AD SSO
Connectivity: Import or DirectQuery
```

**Query folding:** Supported for most operations. Snowflake handles transformation pushdown efficiently.

**DirectQuery:** Supported but test performance. Snowflake auto-suspend can cause initial query delays.

### Databricks (SQL Warehouse)
```
Server hostname: adb-workspace-id.azuredatabricks.net
HTTP Path: /sql/1.0/warehouses/warehouse-id
Authentication: Personal Access Token | Azure AD
Connectivity: Import or DirectQuery
```

**Best practice:** Use Databricks SQL Warehouse (not cluster) for Power BI connectivity. SQL Warehouse is optimized for BI queries.

### Google BigQuery
```
Project: project-id
Authentication: Google Account | Service Account
Connectivity: Import or DirectQuery
Billing: Charged per query in DirectQuery mode
```

**Warning:** DirectQuery with BigQuery charges per TB scanned. Use Import or create materialized views.

### Amazon Redshift
```
Server: cluster.region.redshift.amazonaws.com:5439
Database: database_name
Authentication: Username/Password
Connectivity: Import or DirectQuery
```

## Files

### Excel
```
Source: Local file, SharePoint, OneDrive
Supported: .xlsx, .xls, .xlsm
Load: Tables, Named Ranges, Sheets
```

**Best practice:** Always use Excel Tables (Ctrl+T) for clean data loading. Avoid named ranges that include headers inconsistently.

### CSV / Delimited Text
```
Encoding: UTF-8 (default), UTF-16, ASCII, others
Delimiter: Comma, Tab, Semicolon, Pipe, custom
Header: First row as header (default)
```

**Query folding:** Not supported. All transformations happen in the mashup engine.

### Parquet
```
Source: Local file, Azure Blob, ADLS Gen2, S3
Schema: Embedded in file metadata
Types: Preserved from Parquet schema
```

**Best performance** for file-based sources. Column pruning and predicate pushdown supported in some connectors.

### JSON
```
Source: Local file, Web API, Azure Blob
Expansion: Record/List expansion in Power Query
Pagination: Manual implementation required for APIs
```

## Web and API Sources

### OData Feed
```
URL: https://service/odata/v4/EntitySet
Authentication: Anonymous | Basic | OAuth2 | Azure AD
Query folding: Supported (OData $filter, $select, $expand translated)
```

**Query folding with OData:** Many Power Query steps fold to OData query parameters. Check "View Native Query" to verify.

### Web / REST API
```
URL: https://api.example.com/endpoint
Method: GET (default), POST via Web.Contents options
Authentication: Anonymous | Basic | API Key | OAuth2
Pagination: Implement manually using List.Generate or recursive functions
```

**Pagination pattern (M code):**
```m
let
    GetPage = (url) =>
        let
            response = Json.Document(Web.Contents(url)),
            data = response[value],
            nextLink = try response[#"@odata.nextLink"] otherwise null,
            allData = if nextLink <> null
                then data & GetPage(nextLink)
                else data
        in allData,
    result = GetPage("https://api.example.com/data")
in
    result
```

### SharePoint
```
Site URL: https://tenant.sharepoint.com/sites/SiteName
Authentication: Microsoft Account | Azure AD
Lists: SharePoint List connector
Files: SharePoint Folder connector
```

**Best practice:** Use SharePoint List connector for structured data. For files, use SharePoint Folder connector and filter early in Power Query.

## Streaming and Real-Time

### Streaming Datasets (Push)
Push data via REST API for real-time dashboards:

```
POST https://api.powerbi.com/v1.0/myorg/datasets/{datasetId}/rows
Content-Type: application/json
Authorization: Bearer {token}

{
  "rows": [
    { "Timestamp": "2026-01-15T10:30:00Z", "Value": 42.5 }
  ]
}
```

**Types of streaming datasets:**
| Type | History | Tiles | Full Reports |
|------|---------|-------|--------------|
| Push dataset | Yes (stored) | Yes | Yes |
| Streaming dataset | No (transient) | Yes | No |
| PubNub streaming | No | Yes | No |
| Hybrid (push + streaming) | Yes | Real-time tiles + reports | Yes |

### Azure Stream Analytics
```
Output: Power BI (streaming dataset)
Configuration: Set in Stream Analytics job output
Real-time: Yes, sub-second latency
History: Configurable retention
```

## Fabric Data Sources (2025-2026)

### Fabric Lakehouse
```
Connection: SQL Analytics Endpoint or Direct Lake
Server: workspace-guid.datawarehouse.fabric.microsoft.com
Authentication: Azure AD / Workspace Identity
Connectivity: Direct Lake (preferred) or DirectQuery via SQL endpoint
```

**Direct Lake:** Zero-copy access to delta tables in OneLake. No gateway needed. Framing (metadata refresh) completes in seconds.

### Fabric Warehouse
```
Connection: SQL Analytics Endpoint or Direct Lake
Server: workspace-guid.datawarehouse.fabric.microsoft.com
Authentication: Azure AD / Workspace Identity
Connectivity: Direct Lake (preferred) or DirectQuery
T-SQL: Full DML support (INSERT, UPDATE, DELETE, MERGE)
```

### KQL Database (Real-Time Intelligence)
```
Cluster: https://clustername.kusto.fabric.microsoft.com
Database: DatabaseName
Authentication: Azure AD
Connectivity: DirectQuery via KQL connector
```

**Use case:** Real-time event data from Eventstream, IoT Hub, or Event Hubs ingested into KQL, then queried by Power BI.

### Eventstream
```
Integration: Eventstream -> KQL Database -> Power BI DirectQuery
             Eventstream -> Lakehouse -> Power BI Direct Lake
Sources: Azure Event Hubs, Kafka, IoT Hub, custom REST
```

**Real-Time Intelligence pipeline:** Events flow through Eventstream to KQL Database or Lakehouse, then Power BI queries the destination.

## Connector Updates (2025-2026)

| Connector | Update |
|-----------|--------|
| PostgreSQL | Added Microsoft Entra ID authentication support |
| Snowflake | Enhanced SSO with Azure AD, improved DirectQuery performance |
| Databricks | M2M OAuth with service principal (May 2025+ Desktop required) |
| Spark / Cloudera Impala | Improved connectivity and performance |
| Salesforce | Updated API version support |
| Google BigQuery | Improved metadata retrieval performance |
| Azure Cosmos DB | v2 connector improvements for nested JSON |
| Dataverse | OneLake shortcut support for Dynamics 365 data |

## Gateway Requirements Summary

| Source | Gateway Needed? |
|--------|----------------|
| Cloud services (Azure SQL, Snowflake, etc.) | No |
| On-premises databases | Yes (standard) |
| Local files | Yes (personal or standard) |
| SharePoint Online | No |
| SharePoint On-premises | Yes |
| Web/REST APIs (public) | No |
| Web/REST APIs (internal) | Yes |
| Virtual Network data gateway | For VNet-connected Azure sources |
| Fabric Lakehouse/Warehouse | No (cloud-native) |
| KQL Database | No (cloud-native) |
