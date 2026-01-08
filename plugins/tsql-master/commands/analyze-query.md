---
description: Analyze a T-SQL query for optimization opportunities, SARGability issues, and index recommendations
argument-hint: "[paste query or file path]"
---

# Analyze Query

Systematically analyze a T-SQL query for optimization opportunities.

## Process

### Step 1: Get Query

If user provided a file path:
```bash
# Read the query from file
cat "$1"
```

If user pasted query directly, use that.

### Step 2: SARGability Analysis

Check for non-SARGable patterns:

| Pattern | Issue | Fix |
|---------|-------|-----|
| `YEAR(DateCol) = 2024` | Function on column | `DateCol >= '2024-01-01' AND DateCol < '2025-01-01'` |
| `LEFT(Col, 3) = 'ABC'` | Function on column | `Col LIKE 'ABC%'` |
| `Col * 1.1 > 100` | Arithmetic on column | `Col > 100 / 1.1` |
| `ISNULL(Col, 0) = 5` | Function on column | `(Col = 5 OR Col IS NULL)` |
| `@Var = Col` | Variable on left | `Col = @Var` |

### Step 3: Implicit Conversion Check

Look for potential type mismatches:
- VARCHAR column compared to INT value
- NVARCHAR vs VARCHAR comparisons
- Date strings without explicit CAST/CONVERT

### Step 4: Join Analysis

For each JOIN:
- Check if join columns should be indexed
- Identify potential Cartesian products
- Look for inefficient OR conditions across tables

### Step 5: Subquery Analysis

Check for:
- Correlated subqueries that could be JOINs
- IN vs EXISTS optimization opportunities
- Subqueries in SELECT that could use APPLY

### Step 6: Index Recommendations

Based on:
- WHERE clause columns (equality first, then inequality)
- JOIN columns
- ORDER BY columns
- SELECT columns (for covering index)

Suggest CREATE INDEX statement.

### Step 7: Generate Report

```
================================
Query Analysis Report
================================

QUERY:
[First 200 chars of query...]

SARGABILITY ISSUES:
[ ] WHERE YEAR(OrderDate) = 2024
    → Change to: WHERE OrderDate >= '2024-01-01' AND OrderDate < '2025-01-01'

IMPLICIT CONVERSIONS:
[ ] Line 5: VarcharColumn = 123
    → Change to: VarcharColumn = '123'

JOIN OPTIMIZATION:
[✓] CustomerID join column should have index
[ ] Consider EXISTS instead of IN for large subquery

INDEX RECOMMENDATIONS:
CREATE NONCLUSTERED INDEX IX_Orders_CustomerDate
ON Orders(CustomerID, OrderDate)
INCLUDE (Amount, Status);

ESTIMATED IMPACT: High
================================
```

## Usage

```bash
# Analyze pasted query
/analyze-query SELECT * FROM Orders WHERE YEAR(OrderDate) = 2024

# Analyze query from file
/analyze-query queries/slow_report.sql
```

## Tips

- For complex queries, break into CTEs for analysis
- Consider execution plan for actual performance data
- Test changes in non-production first
- Update statistics after adding indexes
