---
description: Suggest optimal indexes for a T-SQL query or table based on query patterns
argument-hint: "[query or table name]"
---

# Suggest Indexes

Generate index recommendations for T-SQL queries or tables.

## Process

### Step 1: Parse Input

If input is a query:
- Extract table names from FROM/JOIN clauses
- Identify WHERE clause predicates
- Note ORDER BY columns
- List SELECT columns

If input is a table name:
- Ask for typical query patterns or
- Use DMV missing index recommendations

### Step 2: Analyze Query Patterns

For each table in query:

**Equality Predicates (=)**
- First candidates for index key columns
- Most selective columns first

**Inequality Predicates (<, >, BETWEEN, LIKE 'x%')**
- After equality columns in key
- Only one inequality benefits from index

**JOIN Columns**
- Foreign key columns
- Should match data types exactly

**ORDER BY Columns**
- Can eliminate sort operation
- Consider ASC/DESC requirements

**SELECT Columns**
- Candidates for INCLUDE clause
- Creates covering index

### Step 3: Generate Recommendations

For each recommended index:

```sql
-- Purpose: [What queries this index supports]
-- Expected benefit: [Seek vs scan, eliminated lookup, etc.]
CREATE NONCLUSTERED INDEX IX_TableName_Columns
ON SchemaName.TableName (KeyColumn1, KeyColumn2)
INCLUDE (IncludeColumn1, IncludeColumn2)
WHERE [FilterCondition];  -- If filtered index recommended
```

### Step 4: Consider Existing Indexes

Query to check existing indexes:
```sql
SELECT
    i.name AS IndexName,
    i.type_desc,
    STUFF((
        SELECT ', ' + c.name + CASE WHEN ic.is_descending_key = 1 THEN ' DESC' ELSE '' END
        FROM sys.index_columns ic
        JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
        WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.is_included_column = 0
        ORDER BY ic.key_ordinal
        FOR XML PATH('')
    ), 1, 2, '') AS KeyColumns,
    STUFF((
        SELECT ', ' + c.name
        FROM sys.index_columns ic
        JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
        WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.is_included_column = 1
        ORDER BY ic.key_ordinal
        FOR XML PATH('')
    ), 1, 2, '') AS IncludedColumns
FROM sys.indexes i
WHERE i.object_id = OBJECT_ID('TableName')
ORDER BY i.index_id;
```

### Step 5: DMV Missing Index Check

```sql
SELECT
    migs.avg_user_impact AS ImpactPercent,
    mid.statement AS TableName,
    mid.equality_columns,
    mid.inequality_columns,
    mid.included_columns,
    migs.user_seeks,
    migs.user_scans
FROM sys.dm_db_missing_index_groups mig
JOIN sys.dm_db_missing_index_group_stats migs ON mig.index_group_handle = migs.group_handle
JOIN sys.dm_db_missing_index_details mid ON mig.index_handle = mid.index_handle
WHERE mid.database_id = DB_ID()
  AND OBJECT_NAME(mid.object_id) = 'TableName'
ORDER BY migs.avg_user_impact DESC;
```

## Output Format

```
================================
Index Recommendations
================================

TABLE: dbo.Orders

QUERY PATTERN ANALYSIS:
- Filters: CustomerID (=), OrderDate (range)
- Joins: CustomerID -> Customers.CustomerID
- Order: OrderDate DESC
- Selects: OrderID, Amount, Status

RECOMMENDED INDEXES:

1. PRIMARY INDEX (High Impact)
   CREATE NONCLUSTERED INDEX IX_Orders_Customer_Date
   ON dbo.Orders (CustomerID, OrderDate DESC)
   INCLUDE (Amount, Status);

   Benefit: Covers filter + order + select columns
   Eliminates: Table scan, sort operation, key lookup

2. FILTERED INDEX (Medium Impact)
   CREATE NONCLUSTERED INDEX IX_Orders_Active_Customer
   ON dbo.Orders (CustomerID, OrderDate)
   WHERE Status = 'Active';

   Benefit: Smaller index for common filter pattern

EXISTING INDEX CONFLICTS:
- IX_Orders_CustomerID overlaps with recommendation 1
  Consider: DROP or keep if other queries need it

MAINTENANCE IMPACT:
- New indexes will slow INSERT/UPDATE by ~5-10%
- Recommended maintenance: Weekly REORGANIZE

================================
```

## Usage

```bash
# From query
/suggest-indexes SELECT * FROM Orders WHERE CustomerID = @ID ORDER BY OrderDate

# From table name
/suggest-indexes Orders

# Multiple tables
/suggest-indexes "Orders JOIN OrderDetails ON Orders.OrderID = OrderDetails.OrderID"
```

## Best Practices

1. **Don't over-index** - Each index adds write overhead
2. **Consider covering indexes** - Eliminate key lookups
3. **Use filtered indexes** - For well-known subsets
4. **Check existing indexes** - Consolidate similar indexes
5. **Test before production** - Verify with actual workload
