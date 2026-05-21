---
name: index-strategies
description: |
  This skill should be used when the user asks to design, review, add, drop, consolidate, or tune SQL Server indexes. PROACTIVELY activate for clustered vs nonclustered design, covering indexes and INCLUDE columns, filtered indexes, columnstore indexes, missing-index DMV interpretation, duplicate or unused indexes, index maintenance, fragmentation, fill factor, compression, partition-aligned indexes, partition elimination proof, huge-table index constraints, online/resumable rebuilds, and index changes for slow T-SQL queries.
  Provides: index-design decision tree, workload-aware tradeoff checklist, DMV interpretation guidance, and maintenance/rebuild patterns.
---

# Index Strategies

Comprehensive guide to SQL Server index design and optimization. Index advice must be workload-aware and constraint-aware: the best index for one query can be harmful for writes, storage, maintenance, partition switching, or other critical queries.

## Mandatory Intake

Before recommending index DDL, collect or mark unknown:

- SQL Server version, edition, compatibility level, and Azure SQL tier.
- Query text, representative parameters, actual plan, row counts, and predicate selectivity.
- Existing clustered, nonclustered, filtered, columnstore, unique, disabled, duplicate, and overlapping indexes.
- Table DDL, constraints, data types, computed columns, compression, partitioning, and statistics.
- Write workload: insert/update/delete frequency, bulk loads, maintenance window, storage budget.
- Change constraints: can new indexes be added, can huge-table indexes be changed, is online/resumable index creation allowed, is partition switching required, are staging tables allowed, and who approves write overhead.

Use `../_shared/optimization-intake.md` and `../_shared/assumption-tracker.md`. Do not present missing-index DMV output as final design without existing-index and workload review.

## Quick Reference

| Type | Best for | Cautions |
|---|---|---|
| Clustered | Primary table order, range access, narrow stable key | Expensive to change; clustering key is included in nonclustered indexes. |
| Nonclustered | Query-specific seeks, joins, ordering | Adds write and storage overhead. |
| Covering | Avoiding repeated key lookups | INCLUDE bloat can hurt cache and writes. |
| Filtered | Stable, selective subsets | Query predicate must imply filter; parameters can block use. |
| Columnstore | Analytics, scans, aggregations, compression | Small updates and singleton lookups can suffer. |
| Unique | Enforcing business rules and optimizer proof | Must match real semantics. |

## Index Design Workflow

### 1. Start from Query Shape

Map query columns by role:

| Role | Index design implication |
|---|---|
| Equality predicates | Usually first key columns, ordered by selectivity and workload reuse. |
| Join keys | Useful as seek keys and join order support. |
| Range predicates | Usually after equality keys; only one range can be deeply seekable. |
| `ORDER BY` / `GROUP BY` | Consider key order to avoid sorts or stream aggregates. |
| Selected columns | INCLUDE only when lookup cost justifies storage/write cost. |

Example:

```sql
CREATE NONCLUSTERED INDEX IX_Orders_CustomerDate
ON dbo.Orders(CustomerID, OrderDate)
INCLUDE (Status, TotalAmount);
```

### 2. Validate Data Types and SARGability

An index cannot fully help if predicates are non-SARGable or types mismatch. Confirm parameter, temp-table, and source column types before adding indexes. Fix `CONVERT_IMPLICIT` on join/filter columns first when possible.

### 3. Compare Existing Indexes

Before adding a new index:

- Check whether an existing index can be extended safely.
- Merge overlapping missing-index requests.
- Identify duplicates with same leading keys.
- Evaluate lookup count and selected columns before adding INCLUDE columns.
- Consider whether filtered or narrower indexes solve the hot path with less write cost.

### 4. Account for Change Constraints

Classify the recommendation:

| Constraint | Safer response |
|---|---|
| Cannot add indexes | Query rewrite, stats, hints, temp staging, or Query Store hints. |
| Cannot change huge-table indexes | Add narrow filtered index, indexed staging table, or reduce rows before touching table. |
| Online index not allowed | Plan maintenance window and blocking risk; consider resumable where supported. |
| Partition switching required | Prefer aligned indexes; avoid nonaligned indexes unless explicitly accepted. |
| Heavy write workload | Minimize key width and INCLUDE list; prove read benefit. |
| Storage constrained | Consolidate duplicates and avoid speculative covering indexes. |

## Clustered Index Guidelines

Ideal clustered keys are narrow, unique, static, and usually ever-increasing for OLTP insert patterns.

```sql
CREATE CLUSTERED INDEX CIX_Orders ON dbo.Orders(OrderID);
```

Avoid wide composite clustered keys unless they match a deliberate access pattern and write trade-off. Random GUID clustering can cause page splits; consider `NEWSEQUENTIALID()`, a surrogate key, or fill-factor strategy when appropriate.

## Covering Indexes

Covering indexes avoid lookups when the lookup cost is significant.

```sql
CREATE NONCLUSTERED INDEX IX_Orders_CustomerID_Cover
ON dbo.Orders(CustomerID)
INCLUDE (OrderDate, TotalAmount, Status);
```

Use INCLUDE columns for output-only columns, not for filtering or ordering. Keep INCLUDE lists minimal; wide includes can be worse than occasional lookups.

## Filtered Indexes

Filtered indexes are strong for stable subsets:

```sql
CREATE NONCLUSTERED INDEX IX_Orders_Open_ByCustomer
ON dbo.Orders(CustomerID, OrderDate)
WHERE Status = 'Open';
```

Requirements:

- Query predicate must imply the filter.
- Parameterized queries may need recompilation or literal-specific dynamic SQL to match reliably.
- Filter column may need to be included when it is not obvious to the optimizer.
- Validate parameter sniffing risk and plan cache behavior.

## Columnstore Indexes

Use columnstore for analytic scans, aggregations, and compression.

```sql
CREATE CLUSTERED COLUMNSTORE INDEX CCI_FactSales
ON dbo.FactSales;

CREATE NONCLUSTERED COLUMNSTORE INDEX NCCI_Orders_Analysis
ON dbo.Orders(OrderDate, ProductID, Quantity, Amount)
WHERE Status = 'Completed';
```

Best practices:

1. Load batches of at least 102,400 rows where possible.
2. Order data by common elimination columns for better segment elimination.
3. Use `REORGANIZE` to compress delta rowgroups and merge rowgroups.
4. Avoid high-frequency singleton updates on pure columnstore designs.
5. Pair with partitioning for manageability when large fact tables require sliding windows.

## Partition Alignment Checks

For partitioned tables, index design must account for elimination and maintenance.

Verify:

- Partition function/scheme, boundary type, and `RANGE LEFT` vs `RANGE RIGHT`.
- Base partitioning column vs query predicate column.
- Whether each important nonclustered index is aligned or intentionally nonaligned.
- Whether unique indexes include the partitioning column when required.
- Actual partition elimination from the execution plan.
- Unsafe predicates: functions on partition column, mismatched types, filtering a related non-partition date, OR catch-all predicates, or remote sources.

Do not claim partition elimination from a date filter unless it targets the partitioning column in a compatible, SARGable form or a trusted constraint proves equivalence. See `references/partition-alignment-analysis.md`.

## Maintenance and Operations

Fragmentation rules are workload-dependent, but a common starting point is:

| Fragmentation | Typical action |
|---|---|
| Less than 5% | No action. |
| 5-30% | Reorganize if page count and workload justify it. |
| More than 30% | Rebuild if maintenance window, edition, and blocking allow it. |

```sql
ALTER INDEX IX_Orders_CustomerID ON dbo.Orders REORGANIZE;

ALTER INDEX IX_Orders_CustomerID ON dbo.Orders
REBUILD WITH (ONLINE = ON, RESUMABLE = ON, MAX_DURATION = 60);
```

Update statistics after meaningful index changes when auto-created stats or sampled stats are insufficient:

```sql
UPDATE STATISTICS dbo.Orders IX_Orders_CustomerID WITH FULLSCAN;
```

## Useful Diagnostics

Index usage since last restart or database attach:

```sql
SELECT
    OBJECT_SCHEMA_NAME(i.object_id) AS SchemaName,
    OBJECT_NAME(i.object_id) AS TableName,
    i.name AS IndexName,
    ius.user_seeks,
    ius.user_scans,
    ius.user_lookups,
    ius.user_updates
FROM sys.indexes AS i
LEFT JOIN sys.dm_db_index_usage_stats AS ius
  ON i.object_id = ius.object_id
 AND i.index_id = ius.index_id
 AND ius.database_id = DB_ID()
WHERE OBJECTPROPERTY(i.object_id, 'IsUserTable') = 1
ORDER BY COALESCE(ius.user_seeks, 0) + COALESCE(ius.user_scans, 0) DESC;
```

Missing-index candidates:

```sql
SELECT
    migs.avg_user_impact AS ImpactPercent,
    mid.statement AS TableName,
    mid.equality_columns,
    mid.inequality_columns,
    mid.included_columns
FROM sys.dm_db_missing_index_groups AS mig
JOIN sys.dm_db_missing_index_group_stats AS migs
  ON mig.index_group_handle = migs.group_handle
JOIN sys.dm_db_missing_index_details AS mid
  ON mig.index_handle = mid.index_handle
WHERE mid.database_id = DB_ID()
ORDER BY migs.avg_user_impact DESC;
```

## Recommendation Format

Provide:

1. **Evidence**: plan operator, reads, lookups, estimates, missing-index request, or workload metric.
2. **DDL**: proposed index with schema-qualified name and minimal keys/includes.
3. **Why**: access path, ordering, coverage, or elimination benefit.
4. **Cost**: storage, writes, blocking, maintenance, partition implications.
5. **Validation**: before/after plan, logical reads, CPU, elapsed time, write impact.
6. **Rollback or alternative**: especially for huge tables.

## References

- `../_shared/optimization-intake.md` - pre-optimization intake.
- `../_shared/assumption-tracker.md` - assumption status tracking.
- `references/partition-alignment-analysis.md` - partition scheme and elimination analysis.
