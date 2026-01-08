---
description: Help interpret SQL Server execution plan operators and identify performance issues
argument-hint: "[describe the plan or paste XML]"
---

# Explain Execution Plan

Help understand and optimize SQL Server execution plans.

## Process

### Step 1: Get Plan Information

User can provide:
- Description of operators they see
- Execution plan XML
- Screenshot (describe what you see)

### Step 2: Identify Key Operators

Explain each significant operator:

#### Data Access Operators

| Operator | Description | Performance |
|----------|-------------|-------------|
| **Clustered Index Scan** | Reads entire table | Poor for large tables |
| **Clustered Index Seek** | Direct row lookup | Excellent |
| **Index Scan** | Reads entire index | Poor for large indexes |
| **Index Seek** | Range or point lookup | Good |
| **Key Lookup** | Follows pointer to get extra columns | Overhead - add INCLUDE |
| **RID Lookup** | Heap row lookup | Consider adding clustered index |
| **Table Scan** | Heap full scan | Add index |

#### Join Operators

| Operator | Best For | Characteristics |
|----------|----------|-----------------|
| **Nested Loop** | Small outer, indexed inner | Low memory, many seeks |
| **Merge Join** | Pre-sorted large datasets | Needs sorted input |
| **Hash Match** | Large unsorted datasets | High memory usage |
| **Adaptive Join** | Variable cardinality | IQP feature, auto-selects |

#### Other Important Operators

| Operator | Concern | Solution |
|----------|---------|----------|
| **Sort** | Memory/tempdb spills | Add index with ORDER BY cols |
| **Hash Match (Aggregate)** | Large grouping | Normal for large GROUP BY |
| **Filter** | Late filtering | Move to WHERE if possible |
| **Compute Scalar** | Usually fine | Watch for in loops |
| **Spool (Eager/Lazy)** | Repeated scans | Restructure query |
| **Parallelism** | Check for skew | CXPACKET waits if issues |

### Step 3: Warning Signs

Check for these issues:

**Yellow Warning Icons:**
- Missing index hint
- Implicit conversion
- No join predicate
- Residual predicate

**Thick Arrows:**
- Large row counts flowing between operators
- Compare Estimated vs Actual rows

**Red Indicators:**
- Missing statistics
- Memory grant warnings
- Spills to tempdb

### Step 4: Estimated vs Actual Analysis

```
Estimated Rows: 100
Actual Rows: 100,000

Problem: Statistics are outdated or misleading
Solution: UPDATE STATISTICS TableName WITH FULLSCAN
```

### Step 5: Cost Analysis

- Find highest cost operators (% in graphical plan)
- These are optimization targets
- 0% cost doesn't mean free - check actual metrics

## Common Patterns and Fixes

### Pattern: Scan + Key Lookup

```
[Index Scan] --> [Key Lookup] --> [Nested Loop]
```

**Problem:** Index doesn't cover all columns
**Fix:** Add missing columns to INCLUDE

### Pattern: Sort Operator

```
[Index Seek] --> [Sort] --> [Top]
```

**Problem:** ORDER BY columns not in index
**Fix:** Add ORDER BY columns to index key

### Pattern: Hash Match Join

```
[Table Scan] --> [Hash Match] <-- [Table Scan]
```

**Problem:** No indexes on join columns
**Fix:** Add indexes on join columns

### Pattern: Parallelism with Repartition

```
[Parallelism] --> [Repartition Streams] --> [Hash Match]
```

**Problem:** Data redistribution overhead
**Fix:** May need MAXDOP hint or different approach

## Output Format

```
================================
Execution Plan Analysis
================================

PLAN SUMMARY:
- Estimated Cost: 2.45
- Actual Duration: 1,234 ms
- Parallelism: DOP 4

KEY OPERATORS:

1. [PROBLEM] Clustered Index Scan on Orders (45% cost)
   Estimated: 1,000 rows | Actual: 50,000 rows
   → Large scan indicates missing index or non-SARGable predicate

2. [OK] Index Seek on Customers (5% cost)
   Estimated: 100 rows | Actual: 98 rows
   → Good cardinality estimation

3. [WARNING] Key Lookup on Orders (35% cost)
   → Missing columns: Amount, Status
   → Solution: Add INCLUDE (Amount, Status) to existing index

4. [WARNING] Sort operator present (10% cost)
   → 2MB memory grant, no spill
   → Consider index to eliminate sort

RECOMMENDATIONS:

1. Create covering index:
   CREATE INDEX IX_Orders_Customer_Cover
   ON Orders(CustomerID)
   INCLUDE (Amount, Status, OrderDate);

2. Update statistics:
   UPDATE STATISTICS Orders WITH FULLSCAN;

EXPECTED IMPROVEMENT:
- Eliminate key lookup (35% cost reduction)
- Better cardinality estimates

================================
```

## Usage

```bash
# Describe plan
/explain-plan I see a clustered index scan on Orders taking 80% of the cost

# Paste XML
/explain-plan <ShowPlanXML xmlns=...>

# Ask about specific operator
/explain-plan What does Hash Match Aggregate mean?
```

## Tips

- Enable "Include Actual Execution Plan" in SSMS
- Compare estimated vs actual row counts
- Look at wait stats in SQL 2016+ plans
- Use Query Store for plan history
