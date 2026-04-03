---
name: powerbi-core
description: |
  This skill should be used when the user asks about "Power BI data modeling",
  "star schema design", "relationships", "data sources", "DirectQuery vs Import",
  "Direct Lake mode", "composite models", "incremental refresh", "gateway setup",
  "VNet gateway", "streaming datasets", "Dataflow Gen2", "Power BI gotchas",
  "common pitfalls", "bidirectional filtering", "workspace identity",
  "OAuth2 data source", "service principal authentication", "semantic model",
  "Power BI architecture", "data model review", "Power BI Desktop settings",
  or general Power BI architecture and data connectivity questions.
---

# Power BI Core Concepts and Data Modeling

## Overview

Core Power BI knowledge covering data modeling best practices, connectivity modes, source types, relationships, and common pitfalls. This skill provides the foundational architecture guidance every Power BI developer needs.

## Data Model Design - Star Schema

Always design data models using star schema topology:

| Component | Purpose | Example |
|-----------|---------|---------|
| Fact table | Numeric events/transactions | Sales, Orders, WebVisits |
| Dimension table | Descriptive attributes | Date, Product, Customer, Geography |
| Bridge table | Many-to-many resolution | StudentCourse, OrderProduct |

**Mandatory rules:**
- One fact table at the center, dimensions radiating out
- Relationships flow from dimension (one side) to fact (many side)
- Use surrogate integer keys, not natural/business keys
- Keep fact tables narrow (keys + measures only)
- Denormalize dimensions (flatten snowflake into star)
- Create a dedicated Date dimension table (disable auto date/time)
- Never use bidirectional cross-filtering unless absolutely required and contained

## Storage Modes

| Mode | Data Location | Refresh | Performance | Use When |
|------|--------------|---------|-------------|----------|
| Import | In-memory VertiPaq | Scheduled/on-demand | Fastest queries | Default choice, data under 1GB compressed |
| DirectQuery | Source database | Real-time | Depends on source | Real-time needed, data too large for import |
| Dual | Both | Scheduled + real-time | Best of both | Dimension tables in composite models |
| Direct Lake | OneLake delta tables | Framing (seconds) | Near-import speed | Fabric lakehouse/warehouse scenarios |

**Import mode considerations:**
- 1GB PBIX file size limit (10GB for Premium/PPU in service)
- Data is a snapshot at refresh time; not real-time
- Scheduled refresh limit: 8/day (Pro), 48/day (Premium/PPU)

**DirectQuery limitations:**
- No Power Query transformations applied at query time
- Single source per model (unless composite)
- Performance depends entirely on source query speed
- Many DAX functions unavailable or degraded
- No calculated columns on DirectQuery tables
- Row limit of 1 million rows per visual query

**Direct Lake key considerations (2025-2026 GA):**
- Two variants: Direct Lake on OneLake (DL/OL) and Direct Lake on SQL endpoints (DL/SQL)
- DL/OL does NOT fall back to DirectQuery -- queries fail if data cannot be served
- DL/SQL CAN fall back to DirectQuery via SQL analytics endpoint
- Guardrails vary by capacity: F32 allows up to 1,000 files/row groups per table; F64/P1 allows up to 5,000
- Max Memory is a soft limit for paging, not a hard guardrail -- excess paging hurts performance
- Max model size on disk/OneLake IS a hard guardrail -- exceeding causes DQ fallback (DL/SQL) or failure (DL/OL)
- Full DAX support including calculated columns
- Framing (metadata-only refresh) completes in seconds
- Power BI Embedded with Direct Lake mode is GA since March 2025

**Choosing storage mode decision tree:**
1. Data in Fabric OneLake delta tables? Use Direct Lake
2. Need real-time data, source is fast? Use DirectQuery
3. Data under 1GB, can tolerate refresh lag? Use Import (best performance)
4. Large data + need fast queries? Use composite model (Import dimensions + DQ facts + aggregation tables)

## Relationships

| Property | Options | Default |
|----------|---------|---------|
| Cardinality | One-to-many, Many-to-one, One-to-one, Many-to-many | One-to-many |
| Cross-filter direction | Single, Both | Single |
| Active | Yes/No | Yes (only one active per path) |

**Relationship rules:**
- Only one active relationship between any two tables
- Use USERELATIONSHIP() in DAX to activate inactive relationships
- Avoid bidirectional filtering -- it causes ambiguous filter paths, performance degradation, and unexpected results
- Many-to-many requires a bridge table or composite model many-to-many cardinality
- Referential integrity: set "Assume Referential Integrity" for DirectQuery performance

## Data Sources Quick Reference

| Category | Sources |
|----------|---------|
| Microsoft SQL | SQL Server, Azure SQL, Azure Synapse, SQL Server Analysis Services |
| Azure | Cosmos DB, Data Explorer (Kusto), Blob Storage, Data Lake, Fabric Lakehouse/Warehouse |
| Cloud Databases | Snowflake, Databricks, Google BigQuery, Amazon Redshift, Amazon Athena |
| Files | Excel, CSV/TSV, JSON, XML, Parquet, PDF |
| Services | SharePoint, Dynamics 365, Salesforce, Google Analytics, Azure DevOps |
| Protocols | OData, REST API, ODBC, OLEDB |
| Streaming | Azure Stream Analytics, PubNub, REST API push |

## Incremental Refresh

Configure incremental refresh for large Import tables to avoid full refresh:

1. Create `RangeStart` and `RangeEnd` parameters (type DateTime) in Power Query
2. Apply filter on the date column using these parameters
3. Configure refresh policy: archive period (e.g., 3 years), incremental period (e.g., 30 days)
4. Optionally enable "detect data changes" with a last-modified column
5. Optionally enable real-time data with DirectQuery for the latest partition

**Requirements:** Premium, PPU, or Fabric capacity for more than basic incremental refresh. Pro workspaces support incremental refresh but with limitations.

**2025-2026 improvements:**
- Semantic models with incremental refresh can now be edited directly in Power BI Service (change calculated columns, rename tables, adjust hierarchies) without reopening Desktop
- Enhanced refresh API supports selective partition refresh for finer control
- Improved performance for terabyte-scale datasets with faster partition processing

## Gateway Configuration

On-premises data gateway bridges on-premises sources to Power BI Service:

| Gateway Type | Use Case |
|-------------|----------|
| Standard (enterprise) | Shared by multiple users, centrally managed |
| Personal | Single user, development/testing only |
| Virtual Network (VNet) | Azure VNet-connected sources, no on-prem hardware |

**VNet data gateway (2025-2026):**
- Connects to Azure data sources within a VNet without on-premises hardware
- Managed by Fabric/Power BI Service, no gateway machine maintenance
- Supports Azure SQL, Synapse, Azure Data Explorer, and other VNet-bound services
- Enable in Fabric Admin portal under gateway management

**Gateway releases (2025-2026):**
- Monthly releases throughout 2025-2026 with enhanced caching and query folding
- Improved query performance through optimized connection pooling
- 64-bit only for Power BI Desktop for Report Server starting September 2025

**Common gateway failures:**
- Credentials expired -- update in gateway settings
- Source unreachable -- check firewall, VPN, DNS
- Memory exhaustion -- monitor gateway machine resources
- Mashup engine crash -- check Power Query complexity

## Data Source Authentication

| Method | Use Case | Best For |
|--------|----------|----------|
| OAuth2 | Cloud sources (Azure SQL, Snowflake, Databricks) | Interactive use, SSO |
| Service Principal | Automated refresh, CI/CD pipelines | Unattended operations |
| Workspace Identity | Fabric workspaces (no secret to manage) | Fabric-native models |
| Managed Identity | Dataflows Gen2 to Azure sources | Zero-secret PaaS access |
| Username/Password | Legacy on-prem sources | Gateway-bound sources |

**Workspace Identity (2025-2026):**
- Tied to a Fabric workspace, similar to Azure Managed Identity
- No expiration, no secret or password to manage
- Configure in workspace settings, assign to semantic model data sources
- Preferred over service principal for Fabric-native scenarios

**OAuth2 token limitation:** When set via REST API (not UI), OAuth2 credentials lack a refresh token and expire after 1 hour. Use service principal for long-running automation.

**Connection pooling best practices:**
- Gateway reuses connections where possible -- minimize distinct credential sets
- Set query timeout in data source settings (default 5 min, increase for complex queries)
- Implement retry logic in Power Query for transient source failures using `try/otherwise`

## Common Gotchas and Anti-Patterns

| Pitfall | Impact | Fix |
|---------|--------|-----|
| Auto date/time enabled | Hidden date tables bloat model (one per date column) | Disable in Options > Data Load |
| Implicit measures (drag numeric to visual) | No control over aggregation, no reuse | Create explicit DAX measures |
| Bidirectional cross-filter | Ambiguity, performance degradation, wrong results | Use single-direction, handle in DAX |
| Too many columns in fact tables | Bloated model, slow refresh, wasted memory | Keep facts narrow: keys + numeric values |
| BLANK vs 0 vs null confusion | DAX treats BLANK differently from 0; visuals hide BLANK rows | Use IF/COALESCE to handle explicitly |
| Circular dependency errors | Usually from calculated columns referencing each other or bidirectional filters | Restructure model, break the cycle |
| 1GB PBIX limit | Cannot save file locally | Remove unused columns, optimize cardinality |
| Power BI Service vs Desktop gap | Some features only available in one or the other | Check feature matrix before designing |
| Calculated columns vs measures | Calculated columns consume memory, stored per row | Prefer measures (computed at query time) |
| String columns in fact tables | High cardinality strings destroy VertiPaq compression | Move to dimension table, use key reference |

## Additional Resources

### Reference Files
- **`references/data-sources-detail.md`** -- Detailed connector configuration for all source types
- **`references/gotchas-deep-dive.md`** -- Extended pitfall analysis with examples and resolution patterns
