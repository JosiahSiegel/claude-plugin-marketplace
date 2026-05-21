# Power BI Advanced Performance Patterns

Detailed guidance for aggregations, composite models, Direct Lake performance, large dataset optimization (10GB+ semantic models), Power BI Desktop performance settings, Power BI Report Server tuning, and bookmark/filter optimization. SKILL.md keeps diagnostic tools, model optimization, DAX optimization, visual optimization, and the checklist.

## Aggregations

Pre-aggregated tables that Power BI queries instead of the detail table:

### Setup

1. Create an aggregation table (Import) with pre-computed aggregates:
```sql
SELECT
    ProductCategory,
    CAST(OrderDate AS DATE) AS OrderDate,
    SUM(Amount) AS TotalAmount,
    COUNT(*) AS OrderCount
FROM Sales
GROUP BY ProductCategory, CAST(OrderDate AS DATE)
```

2. In Power BI, set up aggregation mappings:
   - Table > Manage aggregations
   - Map: `TotalAmount` summarization `Sum` to detail column `Sales[Amount]`
   - Map: `OrderCount` summarization `Count` to detail table `Sales`
   - Map: `ProductCategory` group-by to `Sales[ProductCategory]`
   - Map: `OrderDate` group-by to `Sales[OrderDate]`

3. Hide the aggregation table from report view

**Power BI automatically routes queries:**
- Queries at aggregation grain -> hit the small Import table (fast)
- Queries at detail grain -> hit the DirectQuery detail table (slower but accurate)

### Automatic Aggregations (Premium/Fabric)

Premium and Fabric capacities support automatic aggregation training:
- System analyzes query patterns
- Automatically creates and maintains agg tables
- No manual configuration required
- Enable in dataset settings

## Composite Models

Mix Import and DirectQuery tables in one model:

| Table | Storage Mode | Why |
|-------|-------------|-----|
| Date dimension | Import | Small, used everywhere, fast |
| Product dimension | Import | Small, frequent filtering |
| Customer dimension | Import or Dual | Medium size |
| Sales fact | DirectQuery | Too large for Import |
| Aggregation table | Import | Pre-computed summaries |

**Dual mode:** Table exists as both Import and DirectQuery. Engine chooses based on query context:
- If all tables in query are Import, uses Import mode (VertiPaq)
- If any table requires DirectQuery, uses DirectQuery for dual tables too

**Set storage mode:** Model view > select table > Properties > Storage mode

**Composite models with Direct Lake (2025 Preview):**
- Mix Direct Lake tables with Import tables in a single model
- Direct Lake tables load from OneLake delta files; Import tables from traditional sources
- Enables extending a Fabric lakehouse model with additional reference data
- Monitor fallback behavior -- DL/SQL tables may fall back to DirectQuery under load

## Direct Lake Performance

Direct Lake provides near-Import query speed without data duplication:

| Aspect | Guidance |
|--------|----------|
| V-Order | Enable in Spark notebooks/pipelines for optimal Parquet read performance |
| Framing frequency | Schedule frequent framing for near-real-time freshness (seconds cost) |
| Column count | Minimize columns -- each column still consumes memory when paged in |
| Guardrails | Monitor file/row-group counts per table (varies by F-SKU capacity) |
| Fallback (DL/SQL) | Set `DirectLakeBehavior = DirectLakeOnly` to block DQ fallback and force optimization |
| Fallback (DL/OL) | No DQ fallback -- queries fail if data cannot be served; optimize model size |
| Memory paging | Max Memory is soft limit -- excess paging degrades performance |
| Calculated columns | Supported but may trigger DQ fallback on DL/SQL; test impact |
| Modeling perf | Desktop 2025+ provides 50%+ improvement for live Direct Lake editing |

## Large Dataset Optimization (10GB+ Models)

| Technique | Impact |
|-----------|--------|
| Remove unused columns aggressively | High -- every column adds VertiPaq memory |
| Split DateTime into Date + Time | High -- reduces cardinality significantly |
| Use integer surrogate keys | High -- 4-byte integers compress far better than text |
| Reduce decimal precision | Medium -- ROUND to 2 places |
| Implement aggregation tables | High -- 100x fewer rows for summary queries |
| Use incremental refresh with partitioning | High -- only refresh changed partitions |
| Enable automatic aggregations (Premium/Fabric) | Medium -- system optimizes query routing |
| Consider Direct Lake for Fabric data | High -- eliminates Import refresh entirely |
| Disable auto date/time | Medium -- removes hidden tables |
| Archive cold data to separate model | Medium -- reduce active model footprint |

## Power BI Desktop Performance Settings

| Setting | Location | Recommendation |
|---------|----------|----------------|
| Auto date/time | Options > Data Load | Disable for production models |
| Background data | Options > Data Load | Enable for faster development |
| Parallel loading | Options > Data Load | Enable for multi-table models |
| DirectQuery query timeout | Options > DirectQuery | Increase for slow sources (default 10 min) |
| Query reduction for slicers | Report settings | Enable "Add Apply button" |
| Auto recovery | Options > Data Load | Enable to prevent work loss |
| Report storage mode | Options > Preview | PBIR format for git-friendly development |

## Power BI Report Server Performance Tuning

Report Server has different performance characteristics from the cloud service:

| Area | Guidance |
|------|----------|
| CPU | Most critical resource at peak load -- add cores first |
| Memory/RAM | Increase allocated memory for better query caching |
| Storage | Use SSDs with high IOPS for the report server database |
| Database isolation | Host report server DB on separate machine from PBIRS |
| Scale-out | Deploy multiple PBIRS instances sharing one report server DB |
| Load balancing | Use NLB or Azure Traffic Manager across instances |
| High availability | Passive standby VM in another region for business continuity |
| Caching | Configure report execution caching for frequently viewed reports |
| Data source proximity | Place gateway/PBIRS close to data sources to reduce latency |
| Concurrent users | Monitor with performance counters; scale out at 50+ concurrent |

## Bookmark and Filter Optimization

| Problem | Solution |
|---------|----------|
| Too many bookmarks loading data | Use report-level filters instead of bookmark-captured filters |
| Bookmarks causing full re-query | Minimize bookmark-captured visual states |
| Complex cross-page drillthrough | Use drillthrough instead of bookmarks for page navigation |
| Slicer cascades on page load | Set default slicer values to reduce initial query count |

