# DAX Studio Performance Analysis Walkthrough

## Installation and Connection

### Install
Download from https://daxstudio.org. Free, open-source tool by SQLBI.

### Latest Features (2025-2026)
- UDF (user-defined functions) support in code completion and Functions tab
- Custom calendar support in code completion
- Parquet file export for query results
- Support for SSAS 2025
- Totals in Power BI Performance Data view
- RequestID tracing in server timings
- Enhanced tooltip display with event endtime and calculated duration
- Improved clipboard handling and UI enhancements

### Connect to Power BI Desktop
1. Open Power BI Desktop with your report
2. Open DAX Studio
3. Select your PBIX file from the connection dialog (auto-detected)

### Connect to Power BI Service (XMLA)
1. Requires Premium, PPU, or Fabric capacity
2. Connection string: `powerbi://api.powerbi.com/v1.0/myorg/WorkspaceName`
3. Initial Catalog: `SemanticModelName`
4. Authentication: Azure AD (Microsoft Entra ID)

## Step 1: Capture the Slow Query

### From Performance Analyzer
1. In Power BI Desktop: View > Performance Analyzer > Start recording
2. Click "Refresh visuals" to clear cache
3. Wait for report to render
4. Find the slow visual in the Performance Analyzer pane
5. Click "Copy query" on the slow visual
6. Paste into DAX Studio

### Query format from Performance Analyzer
```dax
// Query for a bar chart visual
DEFINE
  VAR __DS0Core =
    SUMMARIZECOLUMNS(
      'Product'[Category],
      "SumAmount", CALCULATE(SUM('Sales'[Amount]))
    )
  VAR __DS0PrimaryWindowed =
    TOPN(10, __DS0Core, [SumAmount], DESC)
EVALUATE
  __DS0PrimaryWindowed
ORDER BY [SumAmount] DESC
```

## Step 2: Enable Server Timings

1. Query menu > Server Timings (or Ctrl+Shift+T)
2. This enables detailed engine-level timing

### Server Timings Tab Columns

| Column | Meaning |
|--------|---------|
| Line | Query plan line number |
| Event Subclass | VertiPaq Scan (SE) or DAX Formula Engine (FE) |
| Duration | Time in milliseconds |
| CPU Time | CPU milliseconds consumed |
| Rows | Number of rows returned by this operation |
| KB | Data size in kilobytes |
| Query | The xmSQL query sent to Storage Engine |

## Step 3: Analyze Server Timings

### Reading the Results

After executing the query with Server Timings enabled:

**Bottom of Server Timings pane shows totals:**
- **Total:** Overall query time
- **SE (Storage Engine):** Time scanning data
- **FE (Formula Engine):** Time computing DAX
- **SE Queries:** Number of SE queries generated
- **SE Cache:** Number of SE queries served from cache

### Interpreting Results

| Scenario | SE% | FE% | SE Queries | Diagnosis |
|----------|-----|-----|------------|-----------|
| Fast query | 90% | 10% | 1-3 | Healthy |
| Complex DAX | 30% | 70% | Few | DAX too complex, simplify |
| Materialization | 50% | 50% | Many (10+) | Too many SE queries, reorganize |
| Large scan | 95% | 5% | 1 but slow | Table too large, filter earlier |
| CallbackDataID | Varies | High | Has callbacks | Data sent to FE for processing |

### Red Flags in SE Queries

**CallbackDataID:** When you see `CallbackDataID()` in an SE query, the Storage Engine is asking the Formula Engine to evaluate an expression for each row. This is extremely slow.

```
// BAD SE query with CallbackDataID
WITH $Expr0 := (PFCAST([Sales].[Amount] AS INT) + CallbackDataID())
SELECT $Expr0 FROM [Sales]
```

**Fix:** Restructure DAX to avoid forcing SE to call back to FE. Common causes:
- Complex expressions in FILTER that cannot be pushed to SE
- Non-supported functions in VertiPaq scan
- Mixing row context and filter context incorrectly

**Too many SE queries:** Each SE query has overhead. More than 10-15 SE queries for a single visual indicates materialization issues.

**Fix:** Simplify the DAX, reduce the number of CALCULATE context changes, use variables.

## Step 4: VertiPaq Analyzer

### Access
Advanced menu > View Metrics (or connect and go to Advanced > View Metrics)

### Model Summary

| Metric | What to Look For |
|--------|-----------------|
| Total Size | Overall model memory footprint |
| # Tables | Number of tables (less is often better) |
| # Columns | Total columns (remove unused) |
| # Rows | Data volume |

### Table Analysis

Sort tables by size (descending) to find the biggest:

| Column | Target |
|--------|--------|
| Table Size | Fact tables should be largest, dimensions small |
| Rows | Verify expected row counts |
| Columns | Look for tables with too many columns |
| Dictionary Size | Large = high cardinality strings |
| Data Size | Actual compressed data |

### Column Analysis (Most Important)

Sort columns by size (descending):

| Finding | Problem | Fix |
|---------|---------|-----|
| Large text column in fact table | Destroys compression | Move to dimension |
| High cardinality column | Poor compression ratio | Group, reduce precision |
| Column not in any measure/visual | Wasted space | Remove |
| Multiple date columns, each with auto date table | Bloat | Disable auto date/time |
| Large dictionary, small data | Many unique strings | Hash, shorten, or group |

### Compression Ratio

```
Compression Ratio = Data Size / Uncompressed Size
```

| Ratio | Quality |
|-------|---------|
| 10:1 or better | Excellent (integer keys, low cardinality) |
| 5:1 to 10:1 | Good (typical dimensional data) |
| 2:1 to 5:1 | Poor (high cardinality or text-heavy) |
| <2:1 | Very poor (review column necessity) |

## Step 5: Query Plan Analysis

### Enable Query Plan
Query menu > Query Plan

### Logical Query Plan
Shows what the engine plans to do at a high level:

| Operator | Meaning |
|----------|---------|
| Sum_Vertipaq | Simple sum, pushed to SE |
| GroupBy_Vertipaq | Grouping pushed to SE |
| Filter_Vertipaq | Filter pushed to SE |
| Sum_Formula | Sum evaluated in FE |
| CrossApply | Nested evaluation (potential perf issue) |
| AddColumns | Column computation |
| Cache | Caching intermediate result |

### Physical Query Plan
Shows actual execution:

| Operator | Meaning |
|----------|---------|
| VertiPaq (scan) | SE scanning data -- good |
| SpoolLookup | Looking up cached data -- neutral |
| SpoolIterator | Iterating over spooled data -- watch count |
| Extend_Lookup | Extending result with lookup -- neutral |

### Red flags in query plans:
- **Many SpoolIterator nodes:** Indicates excessive materialization
- **CrossApply with large cardinality:** Nested loops
- **No VertiPaq scan operators:** Everything in FE, model not being used efficiently

## Common Optimization Recipes

### Recipe 1: Slow CALCULATE with FILTER

**Before (slow):**
```dax
High Value Sales =
CALCULATE(
    SUM(Sales[Amount]),
    FILTER(Sales, Sales[Amount] > 1000)
)
```

**After (fast):**
```dax
High Value Sales =
CALCULATE(
    SUM(Sales[Amount]),
    Sales[Amount] > 1000
)
```

**Why:** Boolean filter generates optimized SE scan. FILTER(Sales,...) forces full table materialization in FE.

### Recipe 2: SUMX with RELATED

**Before (slow for large tables):**
```dax
Revenue =
SUMX(Sales, Sales[Quantity] * RELATED(Products[Price]))
```

**After (faster):**
```dax
-- Add Amount column in Power Query (source-side calculation)
-- Then use simple SUM
Revenue = SUM(Sales[Amount])
```

**Why:** Pre-computing in Power Query avoids iterator overhead. If this is not possible, the SUMX version is acceptable but monitor SE timing.

### Recipe 3: Counting with conditions

**Before (slow):**
```dax
Active Customers =
COUNTROWS(FILTER(Customers, Customers[Status] = "Active"))
```

**After (fast):**
```dax
Active Customers =
CALCULATE(COUNTROWS(Customers), Customers[Status] = "Active")
```

**Why:** CALCULATE with boolean filter is optimized. FILTER + COUNTROWS materializes the filtered table.

### Recipe 4: Multiple IF conditions

**Before (slow for many conditions):**
```dax
Category =
IF([Amount] > 10000, "Premium",
    IF([Amount] > 5000, "Gold",
        IF([Amount] > 1000, "Silver", "Bronze")))
```

**After (marginally faster, more readable):**
```dax
Category =
SWITCH(TRUE(),
    [Amount] > 10000, "Premium",
    [Amount] > 5000, "Gold",
    [Amount] > 1000, "Silver",
    "Bronze"
)
```

### Recipe 5: Year-over-Year with variables

**Before (calculates measure twice):**
```dax
YoY % =
DIVIDE(
    [Total Sales] - CALCULATE([Total Sales], SAMEPERIODLASTYEAR(Date[Date])),
    CALCULATE([Total Sales], SAMEPERIODLASTYEAR(Date[Date]))
)
```

**After (single PY calculation):**
```dax
YoY % =
VAR CurrentSales = [Total Sales]
VAR PYSales = CALCULATE([Total Sales], SAMEPERIODLASTYEAR(Date[Date]))
RETURN DIVIDE(CurrentSales - PYSales, PYSales)
```

**Why:** Variables are evaluated once and cached. Without VAR, PY calculation runs twice.

## Benchmarking Protocol

1. **Clear cache:** In DAX Studio, clear the SE cache before benchmarking
   - Right-click database > Clear Cache (requires admin on XMLA)
   - Or disconnect and reconnect
2. **Run warm:** Execute query once (cold), then again (warm)
3. **Compare:** Focus on warm timings for user experience
4. **Iterate:** Make one change at a time, re-measure
5. **Document:** Record before/after timings for each optimization

## VertiPaq Analyzer Updates (2025-2026)

VertiPaq Analyzer v2.1.3 (January 2026):
- Added support for functions metadata
- v2.1.2 (May 2025): Added support for multiple/empty selection DAX expressions in calculation groups
- Fully integrated into DAX Studio Advanced > View Metrics

### Using INFO Functions for Model Analysis

As an alternative to VertiPaq Analyzer, use INFO DAX functions directly in DAX query view:

```dax
// Get storage statistics for all tables
EVALUATE INFO.STORAGETABLES()

// Get column-level storage details
EVALUATE INFO.STORAGETABLECOLUMNS()

// Get segment-level detail (most granular)
EVALUATE INFO.STORAGETABLECOLUMNSEGMENTS()
```

These INFO functions return the same underlying data that VertiPaq Analyzer uses but are accessible directly from DAX query view without external tools.

## Direct Lake Performance Diagnostics

For Direct Lake models, standard DAX Studio Server Timings still apply. Additional diagnostics:

| Metric | Where to Check | What to Look For |
|--------|---------------|-----------------|
| Fallback events | Fabric Capacity Metrics app | Frequent DQ fallback = model design issue |
| Framing duration | Refresh history via REST API | Should be seconds; long framing = delta log bloat |
| Memory paging | Capacity Metrics | Excessive paging = model too large for capacity |
| File/row group count | INFO.PARTITIONS() | Exceeding guardrails triggers fallback |
| Column transcoding | Server Timings | First query after framing may show cold-load time |

**Optimization recipe for Direct Lake:**
1. Enable V-Order writes in Spark notebooks
2. Compact small delta files (OPTIMIZE command)
3. Remove unused columns from gold layer tables
4. Monitor with `INFO.STORAGETABLES()` for memory footprint
5. Set `DirectLakeBehavior = DirectLakeOnly` to surface issues early
