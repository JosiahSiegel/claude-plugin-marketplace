# Fabric Architecture Patterns for Power BI

## Medallion Architecture (Bronze/Silver/Gold)

The most common data architecture pattern in Fabric for Power BI:

```
[Raw Sources] --> [Bronze Lakehouse] --> [Silver Lakehouse] --> [Gold Lakehouse] --> [Semantic Model] --> [Reports]
                  (raw, as-is)          (cleaned, typed)       (business-ready)    (Direct Lake)
```

### Bronze Layer
- Raw data ingested as-is from sources
- Minimal transformation (schema-on-read)
- Full history preserved
- Ingestion via: Data Pipeline, Dataflow Gen2, Notebooks, Eventstream

### Silver Layer
- Cleaned, deduplicated, typed data
- Business logic applied (join reference tables, handle nulls)
- Delta format with Z-Order optimization on query columns
- Incremental processing (merge/upsert patterns)

```python
# Silver layer notebook example
from delta.tables import DeltaTable

# Read bronze
bronze_df = spark.read.format("delta").table("bronze.raw_sales")

# Clean and transform
silver_df = bronze_df \
    .dropDuplicates(["OrderID"]) \
    .withColumn("Amount", col("Amount").cast("decimal(18,2)")) \
    .withColumn("OrderDate", to_date(col("OrderDate"), "yyyy-MM-dd")) \
    .filter(col("Amount") > 0)

# Upsert to silver
silver_table = DeltaTable.forName(spark, "silver.sales")
silver_table.alias("target").merge(
    silver_df.alias("source"),
    "target.OrderID = source.OrderID"
).whenMatchedUpdateAll() \
 .whenNotMatchedInsertAll() \
 .execute()
```

### Gold Layer
- Business-ready aggregations and dimensions
- Optimized for Power BI Direct Lake consumption
- Star schema structure (fact + dimension tables)
- V-Order enabled for optimal read performance

```python
# Gold layer - create star schema tables
spark.conf.set("spark.sql.parquet.vorder.enabled", "true")

# Fact table
fact_sales = spark.sql("""
    SELECT
        s.OrderID, s.OrderDate, s.CustomerID, s.ProductID,
        s.Quantity, s.Amount, s.DiscountAmount
    FROM silver.sales s
""")
fact_sales.write.format("delta").mode("overwrite").saveAsTable("gold.fact_sales")

# Dimension tables
dim_product = spark.sql("""
    SELECT DISTINCT ProductID, ProductName, Category, SubCategory
    FROM silver.products
""")
dim_product.write.format("delta").mode("overwrite").saveAsTable("gold.dim_product")

dim_date = spark.sql("""
    SELECT DISTINCT
        OrderDate as Date,
        year(OrderDate) as Year,
        month(OrderDate) as Month,
        quarter(OrderDate) as Quarter,
        dayofweek(OrderDate) as DayOfWeek
    FROM silver.sales
""")
dim_date.write.format("delta").mode("overwrite").saveAsTable("gold.dim_date")
```

### Direct Lake on Gold Layer

The semantic model sits on top of the gold layer lakehouse:

1. Create semantic model from gold lakehouse SQL endpoint
2. All gold tables available as Direct Lake tables
3. Add DAX measures, calculation groups, hierarchies
4. Reports connect to this single semantic model

## Data Mesh Pattern

For large organizations with multiple domains:

```
[Domain: Sales]                    [Domain: Marketing]
  ├── Sales Lakehouse                ├── Marketing Lakehouse
  ├── Sales Semantic Model           ├── Marketing Semantic Model
  └── Sales Reports                  └── Marketing Reports
         │                                    │
         └──── OneLake Shortcuts ────────────┘
                      │
              [Cross-Domain Reports]
```

**Key principles:**
- Each domain owns its data products (lakehouse + semantic model + reports)
- Cross-domain access via OneLake shortcuts (no data copying)
- Central governance via Fabric Admin, sensitivity labels, endorsement
- Shared semantic models promoted/certified for cross-domain use

## Workspace Design Strategies

### Strategy 1: Environment-Based (Small Teams)

```
Sales-Dev     (workspace, dev capacity)
Sales-Test    (workspace, test capacity)
Sales-Prod    (workspace, prod capacity)
```

Connected via deployment pipeline: Dev > Test > Prod.

### Strategy 2: Domain + Environment (Medium Orgs)

```
Sales-Dev, Sales-Test, Sales-Prod
Marketing-Dev, Marketing-Test, Marketing-Prod
Finance-Dev, Finance-Test, Finance-Prod
SharedData-Dev, SharedData-Test, SharedData-Prod
```

Each domain has its own pipeline. SharedData contains cross-domain semantic models.

### Strategy 3: Separate Model and Report Workspaces (Enterprise)

```
Sales-DataModel-Prod     (semantic model only)
Sales-Reports-Prod       (reports using live connection to model)
Sales-Dashboards-Prod    (dashboards, apps)
Sales-DataModel-Dev      (development semantic model)
Sales-Reports-Dev        (development reports)
```

**Benefits:** Independent security for data models vs reports. Model team and report team can have different access.

## End-to-End Fabric Pipeline for Power BI

```
1. DATA INGESTION
   ├── Data Pipeline (scheduled, for batch sources)
   ├── Dataflow Gen2 (for sources needing Power Query transforms)
   ├── Eventstream (for real-time streaming sources)
   └── Notebooks (for complex/custom ingestion)
         │
         v
2. DATA STORAGE (Bronze Lakehouse)
   └── Raw delta tables, full history
         │
         v
3. DATA TRANSFORMATION
   ├── Notebooks (PySpark for complex transforms)
   ├── Data Pipeline (orchestration)
   └── Dataflow Gen2 (simple transforms)
         │
         v
4. DATA MODELING (Gold Lakehouse)
   └── Star schema delta tables, V-Ordered
         │
         v
5. SEMANTIC LAYER
   └── Semantic Model (Direct Lake)
       ├── DAX measures
       ├── Calculation groups
       ├── Relationships
       ├── RLS/OLS
       └── Hierarchies
         │
         v
6. PRESENTATION
   ├── Power BI Reports
   ├── Power BI Dashboards
   ├── Paginated Reports
   ├── Power BI Embedded (apps)
   └── Excel (connected via Analyze in Excel)
```

## Capacity Sizing for Fabric + Power BI

| Workload | F2 | F4 | F8 | F16 | F32 | F64 | F128 |
|----------|----|----|----|----|-----|-----|------|
| Power BI reports (viewers) | API only | API only | API only | API only | API only | Unlimited | Unlimited |
| Direct Lake max model size | 2 GB | 4 GB | 8 GB | 16 GB | 32 GB | 64 GB | 128 GB |
| Max DL table rows (per table) | 300M | 300M | 300M | 1.5B | 3B | 6B | 6B |
| Max files/row groups per table | 1K | 1K | 1K | 1K | 1K | 5K | 5K |
| Concurrent DL queries | 4 | 8 | 16 | 32 | 64 | 128 | 256 |
| Dataflow Gen2 compute | Basic | Basic | Standard | Standard | Enhanced | Enhanced | Enhanced |
| Notebook Spark cores | 8 | 16 | 32 | 64 | 128 | 256 | 512 |

**Scaling guidance:**
- Start with F64 for production (includes viewer access for users without Pro/PPU)
- Use F2-F32 for development/testing (API access only, no interactive viewing)
- Monitor with Capacity Metrics app for CPU, memory, and throttling
- Enable autoscale for burst scenarios
- Consider multiple capacities for isolation (dev vs prod)
- DL/OL models must stay within guardrails -- no DQ fallback available

## Data Activator (Alerts and Triggers)

Fabric feature that triggers actions based on data changes:

```
[Semantic Model] --> [Data Activator Reflex] --> [Action]
                                                    ├── Send email
                                                    ├── Teams notification
                                                    ├── Power Automate flow
                                                    └── Custom webhook
```

**Use cases:**
- Alert when KPI drops below threshold
- Notify manager when sales target achieved
- Trigger pipeline when data quality issue detected
- Send daily summary if metrics changed significantly

## Migration from Existing Power BI to Fabric

### Phase 1: Assessment
- Inventory all workspaces, datasets, reports
- Identify datasets suitable for Direct Lake (large Import datasets)
- Assess gateway dependencies
- Review Premium/PPU licensing

### Phase 2: Lakehouse Setup
- Create Fabric workspace and lakehouse
- Migrate data sources to lakehouse tables
- Implement medallion architecture
- Enable V-Order optimization

### Phase 3: Semantic Model Migration
- Recreate semantic models with Direct Lake on gold tables
- Migrate DAX measures, relationships, RLS
- Use ALM Toolkit or Tabular Editor for comparison
- Validate measure results match original

### Phase 4: Report Migration
- Rebind existing reports to new semantic models
- Test all visuals and interactions
- Update scheduled refreshes (framing instead of full refresh)
- Migrate deployment pipelines

### Phase 5: Governance
- Update tenant settings for Fabric
- Configure sensitivity labels
- Set up Capacity Metrics monitoring
- Train admins on Fabric-specific features
