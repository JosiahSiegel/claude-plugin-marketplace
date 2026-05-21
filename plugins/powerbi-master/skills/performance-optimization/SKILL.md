---
name: performance-optimization
description: |
  Power BI performance optimization for slow reports, models, and queries.
  PROACTIVELY activate for: (1) report is slow or visuals take forever to load, (2) DAX Studio and VertiPaq Analyzer profiling, (3) Performance Analyzer in Power BI Desktop, (4) optimizing slow DAX measures, (5) slow visuals diagnosis, (6) aggregations and composite-model tuning, (7) query reduction techniques (visual settings, top N), (8) model size reduction (cardinality, calculated columns, summary tables), (9) VertiPaq compression tuning, (10) Direct Lake performance and fallback rules, (11) large-dataset (10GB+) optimization.
  Provides: profiling workflow with DAX Studio, VertiPaq compression checklist, aggregation-table patterns, model-size reduction techniques, and end-to-end performance investigation playbook.
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

## Advanced Capacity and Model Patterns

Detailed guidance for aggregations, composite models, Direct Lake performance, large dataset optimization (10GB+ semantic models), Power BI Desktop performance settings, Power BI Report Server tuning, and bookmark/filter optimization lives in `references/advanced-capacity-patterns.md`. Load that reference when tuning enterprise-scale models beyond basic DAX/model/visual improvements.

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
