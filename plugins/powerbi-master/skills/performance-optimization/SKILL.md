---
name: performance-optimization
description: Power BI performance optimization for slow reports, models, and queries. PROACTIVELY activate for: (1) report is slow or visuals take forever to load, (2) DAX Studio and VertiPaq Analyzer profiling, (3) Performance Analyzer in Power BI Desktop, (4) optimizing slow DAX measures, (5) slow visuals diagnosis, (6) aggregations and composite-model tuning, (7) query reduction techniques (visual settings, top N), (8) model size reduction (cardinality, calculated columns, summary tables), (9) VertiPaq compression tuning, (10) Direct Lake performance and fallback rules, (11) large-dataset (10GB+) optimization. Provides: profiling workflow with DAX Studio, VertiPaq compression checklist, aggregation-table patterns, model-size reduction techniques, and end-to-end performance investigation playbook.
---

# Performance Optimization

## Overview

Power BI performance depends on data model design, DAX efficiency, visual configuration, and infrastructure. This skill covers diagnostic tools, optimization techniques, and best practices for achieving fast, responsive reports.

## Diagnostic Tools

### Performance Analyzer (Built-in)

Enable in Power BI Desktop: View > Performance Analyzer > Start recording

| Metric | Meaning | Action if Slow |
|--------|---------|----------------|
| DAX query | Time to execute the DAX | Optimize measure, check filter context |
| Visual display | Time to render the result | Reduce data points, simplify visual |
| Other | Miscellaneous overhead | Usually minor, ignore unless dominant |

**Workflow:**
1. Start recording
2. Clear visual cache (click "Refresh visuals")
3. Interact with the report (change slicers, navigate pages)
4. Copy DAX query from slow visuals
5. Paste into DAX Studio for deeper analysis

### DAX Studio

Free external tool for deep DAX performance analysis:

**Key features:**
- Execute DAX queries with timing
- Server Timings: shows Storage Engine (SE) vs Formula Engine (FE) time
- Query Plan: view logical and physical query plans
- VertiPaq Analyzer: model size and compression analysis
- All Queries trace: capture all queries sent by a report

**Server Timings breakdown:**

| Engine | What It Does | Optimization Target |
|--------|-------------|---------------------|
| Storage Engine (SE) | Scans VertiPaq data, retrieves rows | Reduce cardinality, columns scanned |
| Formula Engine (FE) | Evaluates DAX formulas | Simplify DAX, avoid nested iterators |

**Ideal ratio:** SE should be 80-90% of total time. High FE % means DAX is doing too much computation.

**Common DAX Studio workflow:**
1. Connect to Power BI Desktop (or XMLA endpoint)
2. Enable Server Timings (Query > Server Timings)
3. Paste the DAX query from Performance Analyzer
4. Execute and analyze timing breakdown
5. Look for:
   - Many SE queries (indicates materialization issues)
   - CallbackDataID in SE queries (data sent to FE for processing -- avoid)
   - High FE time (DAX too complex)
   - Large SE row counts (too much data scanned)

### VertiPaq Analyzer

Analyze model size and compression in DAX Studio: Advanced > View Metrics

| Metric | What to Check | Target |
|--------|--------------|--------|
| Table size (bytes) | Identify largest tables | Reduce columns, remove unused |
| Column cardinality | High cardinality = poor compression | Reduce distinct values, group rare values |
| Column size | Disproportionately large columns | Remove or move to dimension |
| Dictionary size | Large string dictionaries | Shorten strings, use keys |
| Relationship size | Memory for relationship mapping | Normal, cannot optimize directly |
| Hierarchy size | Hidden auto date/time hierarchies | Disable auto date/time |

## Data Model Optimization

### Column Optimization

| Technique | Impact | How |
|-----------|--------|-----|
| Remove unused columns | High | Delete columns not used in any visual, measure, or relationship |
| Reduce column cardinality | High | Group rare values (bottom 5% into "Other") |
| Use integer keys | High | Replace text foreign keys with integer surrogates |
| Split date/time | Medium | Separate DateTime into Date (date) and Time (time) columns |
| Round decimals | Medium | Round to 2 decimal places instead of 15 |
| Avoid calculated columns | Medium | Use measures instead (query-time vs storage) |
| Disable auto date/time | Medium | Options > Data Load > uncheck |
| Remove text from facts | High | Move descriptions to dimension tables |

### Relationship Optimization

- Use single-direction cross-filtering (avoid bidirectional)
- Enable "Assume Referential Integrity" for DirectQuery relationships
- Remove unused or redundant relationships
- Use integer key columns for relationships

### Partition Strategy

For large tables, partition by date range:
- Historical partitions (yearly/quarterly) -- refresh rarely
- Recent partition (current month/week) -- refresh frequently
- Use incremental refresh to automate partition management

## DAX Optimization

### High-Impact Patterns

**Use variables to avoid repeated calculations:**
```dax
// BAD: Calculates [Total Sales] three times
Margin % = DIVIDE([Total Sales] - [Total Cost], [Total Sales])

// GOOD: Single calculation, reuse via variable
Margin % =
VAR Sales = [Total Sales]
VAR Cost = [Total Cost]
RETURN DIVIDE(Sales - Cost, Sales)
```

**Avoid FILTER with large tables in CALCULATE:**
```dax
// BAD: Scans entire table
CALCULATE([Sales], FILTER(ALL(Products), Products[Category] = "Electronics"))

// GOOD: Column filter (optimized)
CALCULATE([Sales], Products[Category] = "Electronics")
```

**Avoid nested iterators:**
```dax
// BAD: O(n^2) complexity
SUMX(Products,
    SUMX(FILTER(Sales, Sales[ProductID] = Products[ProductID]),
        Sales[Amount]))

// GOOD: Use relationship + simple aggregation
SUMX(Products, [Total Sales])
```

**Use DISTINCTCOUNT instead of COUNTROWS(DISTINCT(...)):**
```dax
// BAD
COUNTROWS(DISTINCT(Sales[CustomerID]))

// GOOD
DISTINCTCOUNT(Sales[CustomerID])
```

**Avoid FORMAT() in measures (returns text, kills sort):**
```dax
// BAD: Returns text, cannot sort
MonthLabel = FORMAT([Date], "MMMM yyyy")

// GOOD: Use a pre-computed column in the Date table for display
// And a numeric sort column for ordering
```

### Measure Complexity Guidelines

| Complexity | Acceptable For | Performance Concern |
|-----------|---------------|---------------------|
| Simple aggregation (SUM, COUNT) | Any visual | No |
| CALCULATE with column filter | Any visual | No |
| Single iterator (SUMX) | Most visuals | Watch row count |
| CALCULATE with FILTER(table) | Limited visuals | Yes, if table is large |
| Nested iterators | Avoid | Yes, always |
| CALCULATE inside SUMX | Use carefully | Context transition cost |

## Visual Optimization

### Reduce Visual Count

| Problem | Impact | Fix |
|---------|--------|-----|
| 20+ visuals on one page | Each visual sends DAX query | Keep to 8-12 visuals per page |
| Visuals with many data points | Large result sets | Use Top N, aggregation |
| Many slicers | Each slicer change re-queries all visuals | Use "Apply" button |

### Query Reduction

Enable query reduction features:
1. **Report settings > Query reduction > Add Apply button to slicers** -- users click "Apply" after all slicer changes
2. **Reduce number of queries sent by > Disable cross-highlighting by default** -- reduces inter-visual queries

### Conditional Formatting

Avoid complex DAX-based conditional formatting on large tables. Use simple column references or measures with limited computation.

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

## Performance Checklist

### Data Model
- [ ] Star schema design (fact + dimension tables)
- [ ] Auto date/time disabled
- [ ] No unused columns
- [ ] Integer keys for relationships
- [ ] Single-direction cross-filtering
- [ ] Text columns only in dimension tables
- [ ] Calculated columns converted to measures where possible
- [ ] High-cardinality columns addressed

### DAX
- [ ] Variables used for repeated expressions
- [ ] No FILTER on large tables in CALCULATE
- [ ] No nested iterators
- [ ] DISTINCTCOUNT preferred over COUNTROWS(DISTINCT(...))
- [ ] No FORMAT in measures used for sorting
- [ ] Measures return numeric types (not text)

### Visuals
- [ ] 8-12 visuals per page maximum
- [ ] Apply button on slicers
- [ ] Top N applied on large tables
- [ ] Cross-highlighting minimized for heavy pages
- [ ] Conditional formatting uses simple expressions

### Infrastructure
- [ ] Correct capacity size for workload
- [ ] Premium/Fabric for large models (>1GB)
- [ ] Gateway optimized (sufficient RAM, SSD, close to data source)
- [ ] Incremental refresh for large tables
- [ ] Aggregations for DirectQuery heavy queries

### Direct Lake (if applicable)
- [ ] V-Order enabled on delta table writes
- [ ] Framing scheduled at appropriate frequency
- [ ] File/row-group counts within capacity guardrails
- [ ] Fallback behavior configured and monitored
- [ ] Calculated columns tested for fallback impact

### Report Server (if applicable)
- [ ] Report server DB isolated from PBIRS process
- [ ] Sufficient CPU cores for peak concurrent users
- [ ] SSD storage with high IOPS for DB
- [ ] Report caching configured for popular reports
- [ ] Scale-out with NLB if >50 concurrent users

## Additional Resources

### Reference Files
- **`references/dax-studio-walkthrough.md`** -- Step-by-step DAX Studio analysis guide with query plan interpretation and latest DAX Studio features
