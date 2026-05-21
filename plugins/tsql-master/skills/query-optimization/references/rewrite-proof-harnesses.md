# Rewrite Proof Harnesses

Use these harnesses to prove that a T-SQL rewrite preserves semantics and improves plan shape. Adapt object and column names before running. Prefer `COUNT_BIG` for large tables.

## Join Removal Proof

Goal: determine whether a join filters rows, multiplies rows, or can be replaced by `EXISTS`.

### 1. Does the join filter rows?

```sql
SELECT COUNT_BIG(*) AS BaseRows
FROM dbo.FactTable AS f;

SELECT COUNT_BIG(*) AS JoinedRows
FROM dbo.FactTable AS f
JOIN dbo.Dimension AS d
  ON d.DimensionID = f.DimensionID;
```

If counts differ, the join filters or multiplies. Continue with duplicate checks.

### 2. Does the join multiply rows?

```sql
SELECT f.DimensionID, COUNT_BIG(*) AS Matches
FROM dbo.FactTable AS f
JOIN dbo.Dimension AS d
  ON d.DimensionID = f.DimensionID
GROUP BY f.DimensionID
HAVING COUNT_BIG(*) > COUNT_BIG(DISTINCT f.PrimaryKeyColumn);
```

A simpler dimension-key duplicate check is often enough:

```sql
SELECT d.DimensionID, COUNT_BIG(*) AS DuplicateRows
FROM dbo.Dimension AS d
GROUP BY d.DimensionID
HAVING COUNT_BIG(*) > 1;
```

### 3. Is there a trusted constraint proof?

```sql
SELECT
    fk.name,
    fk.is_disabled,
    fk.is_not_trusted
FROM sys.foreign_keys AS fk
WHERE fk.parent_object_id = OBJECT_ID(N'dbo.FactTable')
  AND fk.referenced_object_id = OBJECT_ID(N'dbo.Dimension');
```

A trusted FK plus unique referenced key can prove the join does not filter when the FK column is non-null and no dimension predicates are applied.

### 4. Replace join with EXISTS when only existence is needed

```sql
-- Before: may multiply rows if Dimension is not unique on DimensionID
SELECT f.PrimaryKeyColumn, f.Amount
FROM dbo.FactTable AS f
JOIN dbo.Dimension AS d
  ON d.DimensionID = f.DimensionID
WHERE d.Status = 'Active';

-- Safer semi-join shape
SELECT f.PrimaryKeyColumn, f.Amount
FROM dbo.FactTable AS f
WHERE EXISTS
(
    SELECT 1
    FROM dbo.Dimension AS d
    WHERE d.DimensionID = f.DimensionID
      AND d.Status = 'Active'
);
```

Validate with `EXCEPT` in both directions:

```sql
WITH before_query AS
(
    SELECT f.PrimaryKeyColumn, f.Amount
    FROM dbo.FactTable AS f
    JOIN dbo.Dimension AS d
      ON d.DimensionID = f.DimensionID
    WHERE d.Status = 'Active'
),
after_query AS
(
    SELECT f.PrimaryKeyColumn, f.Amount
    FROM dbo.FactTable AS f
    WHERE EXISTS
    (
        SELECT 1
        FROM dbo.Dimension AS d
        WHERE d.DimensionID = f.DimensionID
          AND d.Status = 'Active'
    )
)
SELECT 'before_minus_after' AS DiffType, * FROM before_query
EXCEPT
SELECT 'before_minus_after', * FROM after_query
UNION ALL
SELECT 'after_minus_before', * FROM after_query
EXCEPT
SELECT 'after_minus_before', * FROM before_query;
```

## Temp Table Type Checker

Goal: prove temp or staging columns match source columns used in joins and predicates.

```sql
SELECT
    temp_col.name AS TempColumn,
    temp_type.name AS TempType,
    temp_col.max_length AS TempMaxLength,
    temp_col.precision AS TempPrecision,
    temp_col.scale AS TempScale,
    temp_col.collation_name AS TempCollation,
    source_col.name AS SourceColumn,
    source_type.name AS SourceType,
    source_col.max_length AS SourceMaxLength,
    source_col.precision AS SourcePrecision,
    source_col.scale AS SourceScale,
    source_col.collation_name AS SourceCollation
FROM tempdb.sys.columns AS temp_col
JOIN tempdb.sys.types AS temp_type
  ON temp_type.user_type_id = temp_col.user_type_id
JOIN sys.columns AS source_col
  ON source_col.object_id = OBJECT_ID(N'dbo.SourceTable')
 AND source_col.name = temp_col.name
JOIN sys.types AS source_type
  ON source_type.user_type_id = source_col.user_type_id
WHERE temp_col.object_id = OBJECT_ID(N'tempdb..#StageKeys');
```

Flag mismatches in data type, string length, numeric precision/scale, collation, and nullability. A temp table that stores an `int` key as `nvarchar(50)` can create `CONVERT_IMPLICIT` joins and scans.

## Rewrite Template Selection

### Stage selective keys first

Use when a small, selective predicate can be isolated before joining huge tables.

```sql
SELECT DISTINCT s.KeyColumn
INTO #Keys
FROM dbo.SelectiveSource AS s
WHERE s.FilterDate >= @StartDate
  AND s.FilterDate < @EndDate;

CREATE UNIQUE CLUSTERED INDEX CX_Keys ON #Keys(KeyColumn);

SELECT b.*
FROM #Keys AS k
JOIN dbo.BigTable AS b
  ON b.KeyColumn = k.KeyColumn;
```

### Reduce before joining huge tables

Use when grouping can shrink rows early without changing semantics.

```sql
WITH reduced AS
(
    SELECT DetailKey, SUM(Amount) AS Amount
    FROM dbo.BigDetail
    WHERE TranDate >= @StartDate
      AND TranDate < @EndDate
    GROUP BY DetailKey
)
SELECT h.HeaderID, r.Amount
FROM reduced AS r
JOIN dbo.Header AS h
  ON h.DetailKey = r.DetailKey;
```

### Aggregate early only when grouping keys preserve semantics

Before aggregating early, prove that columns needed later are functionally dependent on grouping keys or are aggregated intentionally.

```sql
SELECT GroupKey, COUNT_BIG(DISTINCT LaterColumn) AS DistinctLaterValues
FROM dbo.BigDetail
GROUP BY GroupKey
HAVING COUNT_BIG(DISTINCT LaterColumn) > 1;
```

### Avoid unsafe partition predicates

Prefer direct range predicates on the partitioning column.

```sql
-- Unsafe if OrderDateTime is the partitioning column: function wraps the column
WHERE CONVERT(date, OrderDateTime) = @OrderDate;

-- Safer range predicate
WHERE OrderDateTime >= @OrderDate
  AND OrderDateTime < DATEADD(day, 1, @OrderDate);
```

If filtering on a related date column instead of the partition key, require a trusted constraint or proof that the columns are equivalent for the target rows.

## Before/After Measurement Template

```sql
SET STATISTICS IO, TIME ON;

-- Run baseline query with representative parameters.
-- Capture actual execution plan.

-- Run candidate rewrite with same parameters.
-- Capture actual execution plan.

SET STATISTICS IO, TIME OFF;
```

Compare logical reads, CPU time, elapsed time, spills, memory grant, actual vs estimated rows, rows read vs rows returned, and result-set equivalence.
