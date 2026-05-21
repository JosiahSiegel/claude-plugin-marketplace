# Partition Alignment Analysis

Use this reference when recommending indexes or rewrites for partitioned SQL Server tables. Partitioning improves manageability and can improve performance only when predicates, indexes, and constraints allow elimination or aligned maintenance.

## Required Facts

Collect:

- Partition function name, data type, boundary values, and `RANGE LEFT` vs `RANGE RIGHT`.
- Partition scheme and destination filegroups.
- Table partitioning column and whether clustered and nonclustered indexes are aligned.
- Query predicates and parameter data types.
- Actual or estimated partition access evidence.
- Operational requirements: sliding-window loads, partition switching, compression, archival, online rebuild support.

## Metadata Queries

```sql
SELECT
    pf.name AS PartitionFunction,
    pf.boundary_value_on_right,
    prv.boundary_id,
    SQL_VARIANT_PROPERTY(prv.value, 'BaseType') AS BoundaryType,
    prv.value AS BoundaryValue
FROM sys.partition_functions AS pf
JOIN sys.partition_range_values AS prv
  ON prv.function_id = pf.function_id
ORDER BY pf.name, prv.boundary_id;
```

```sql
SELECT
    t.name AS TableName,
    i.name AS IndexName,
    i.index_id,
    ps.name AS PartitionScheme,
    c.name AS PartitionColumn,
    p.partition_number,
    p.rows
FROM sys.tables AS t
JOIN sys.indexes AS i
  ON i.object_id = t.object_id
JOIN sys.partitions AS p
  ON p.object_id = i.object_id
 AND p.index_id = i.index_id
JOIN sys.data_spaces AS ds
  ON ds.data_space_id = i.data_space_id
LEFT JOIN sys.partition_schemes AS ps
  ON ps.data_space_id = ds.data_space_id
LEFT JOIN sys.index_columns AS ic
  ON ic.object_id = i.object_id
 AND ic.index_id = i.index_id
 AND ic.partition_ordinal = 1
LEFT JOIN sys.columns AS c
  ON c.object_id = ic.object_id
 AND c.column_id = ic.column_id
WHERE t.object_id = OBJECT_ID(N'dbo.PartitionedTable')
ORDER BY i.index_id, p.partition_number;
```

## Alignment Checks

An index is aligned when it uses the same partition scheme and compatible partitioning column as the base table. Alignment matters for partition switching, partition-level maintenance, and predictable elimination.

Check:

- Clustered index or heap partitioned on the expected column.
- Nonclustered indexes either aligned for partition maintenance or intentionally nonaligned for targeted query needs.
- Unique indexes on partitioned tables include the partitioning column when required by SQL Server.
- Incremental statistics are configured where useful for large partitioned tables.

## Predicate Safety

Safe elimination patterns usually compare the partition column directly with typed boundaries:

```sql
WHERE FactDate >= @StartDate
  AND FactDate < @EndDate;
```

Risky patterns:

```sql
WHERE CONVERT(date, FactDateTime) = @DateValue;
WHERE DATEDIFF(day, FactDateTime, @DateValue) = 0;
WHERE FactDateString >= '20260101';
WHERE RelatedDate >= @StartDate AND RelatedDate < @EndDate;
WHERE FactDate = @DateValue OR @DateValue IS NULL;
```

Risk reasons include functions on the partitioning column, data type mismatches, filtering a non-partition column, catch-all predicates, and conversions from string literals.

## Elimination Proof

Use actual execution plans when possible. In plan properties, inspect actual partitions accessed or partition count. In ShowPlan XML, search for partition-related properties as described in `../../execution-plan-analysis/references/showplan-xml-checklist.md`.

If plan evidence is unavailable, estimate with partition metadata and boundary logic, but label it unverified.

## Index Recommendation Guidance

For partitioned tables:

- Put equality predicates before range predicates unless partition maintenance or ordered scans require a different design.
- Include the partitioning column in keys when needed for alignment, switching, uniqueness, or elimination proof.
- Avoid adding a large nonaligned index unless the performance gain justifies maintenance and switch limitations.
- Consider filtered indexes for hot partitions only when predicates are stable and query predicates imply the filter.
- For columnstore, order data by common elimination and segment-elimination columns when supported and appropriate.

## Reporting Template

```text
Partition alignment finding:
- Partition function/scheme: pf_FactDate / ps_FactDate, RANGE RIGHT, date boundaries monthly.
- Base table partition column: FactDate date.
- Query predicate: CONVERT(date, FactDateTime) = @d; not on partition column.
- Evidence: actual plan accessed 24 partitions, not 1.
- Recommendation: rewrite predicate to direct FactDate range or add verified constraint/computed column strategy; do not assume partition elimination from RelatedDate.
```
