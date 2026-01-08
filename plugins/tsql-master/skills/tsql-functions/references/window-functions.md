# Window Functions Reference

Complete reference for T-SQL window and ranking functions.

## Ranking Functions

### ROW_NUMBER()
Unique sequential numbers (no ties):
```sql
SELECT Name, Score,
       ROW_NUMBER() OVER (ORDER BY Score DESC) AS RowNum
FROM Students
-- Scores: 100, 95, 95, 90 -> RowNum: 1, 2, 3, 4
```

### RANK()
Same rank for ties, gaps after:
```sql
SELECT Name, Score,
       RANK() OVER (ORDER BY Score DESC) AS Rank
FROM Students
-- Scores: 100, 95, 95, 90 -> Rank: 1, 2, 2, 4
```

### DENSE_RANK()
Same rank for ties, no gaps:
```sql
SELECT Name, Score,
       DENSE_RANK() OVER (ORDER BY Score DESC) AS DenseRank
FROM Students
-- Scores: 100, 95, 95, 90 -> DenseRank: 1, 2, 2, 3
```

### NTILE(n)
Distribute into n equal groups:
```sql
SELECT Name, Score,
       NTILE(4) OVER (ORDER BY Score DESC) AS Quartile
FROM Students
-- Divides into 4 groups (quartiles)
```

## Offset Functions

### LAG()
Access previous row:
```sql
-- Basic usage
SELECT Date, Value,
       LAG(Value) OVER (ORDER BY Date) AS PrevValue
FROM Metrics

-- With offset and default
SELECT Date, Value,
       LAG(Value, 3, 0) OVER (ORDER BY Date) AS Value3DaysAgo
FROM Metrics

-- Calculate change
SELECT Date, Value,
       Value - LAG(Value, 1, Value) OVER (ORDER BY Date) AS DailyChange
FROM Metrics
```

### LEAD()
Access next row:
```sql
SELECT Date, Value,
       LEAD(Value) OVER (ORDER BY Date) AS NextValue,
       LEAD(Value, 7) OVER (ORDER BY Date) AS ValueIn7Days
FROM Metrics
```

### FIRST_VALUE()
First value in window:
```sql
SELECT Name, DeptID, Salary,
       FIRST_VALUE(Name) OVER (
           PARTITION BY DeptID
           ORDER BY Salary DESC
       ) AS HighestPaidInDept
FROM Employees
```

### LAST_VALUE()
Last value in window (requires frame specification):
```sql
SELECT Name, DeptID, Salary,
       LAST_VALUE(Name) OVER (
           PARTITION BY DeptID
           ORDER BY Salary DESC
           ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
       ) AS LowestPaidInDept
FROM Employees
```

**Important:** LAST_VALUE requires explicit frame because default frame is `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`.

## IGNORE NULLS (SQL Server 2022+)

Skip NULL values in offset functions:
```sql
-- Get last non-NULL value
SELECT Date, Value,
       LAST_VALUE(Value) IGNORE NULLS OVER (
           ORDER BY Date
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS LastKnownValue
FROM Measurements

-- Forward-fill missing data
SELECT Date, Value,
       COALESCE(Value,
           LAST_VALUE(Value) IGNORE NULLS OVER (
               ORDER BY Date
               ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
           )
       ) AS FilledValue
FROM SensorData

-- RESPECT NULLS is default (explicit)
SELECT FIRST_VALUE(Value) RESPECT NULLS OVER (ORDER BY Date)
```

## Distribution Functions

### PERCENT_RANK()
Relative rank as percentage (0 to 1):
```sql
SELECT Name, Score,
       PERCENT_RANK() OVER (ORDER BY Score) AS PercentRank
FROM Students
-- Formula: (rank - 1) / (total_rows - 1)
```

### CUME_DIST()
Cumulative distribution:
```sql
SELECT Name, Score,
       CUME_DIST() OVER (ORDER BY Score) AS CumeDist
FROM Students
-- Percentage of rows <= current row
```

### PERCENTILE_CONT()
Continuous percentile (interpolates):
```sql
SELECT DeptID,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Salary)
           OVER (PARTITION BY DeptID) AS MedianSalary
FROM Employees
-- May return value not in dataset (interpolated)
```

### PERCENTILE_DISC()
Discrete percentile (actual value):
```sql
SELECT DeptID,
       PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY Salary)
           OVER (PARTITION BY DeptID) AS MedianSalary
FROM Employees
-- Returns actual value from dataset
```

## Aggregate Window Functions

All aggregate functions can be used with OVER clause:
```sql
-- Running total
SELECT OrderID, Amount,
       SUM(Amount) OVER (ORDER BY OrderDate) AS RunningTotal
FROM Orders

-- Partition aggregates
SELECT DeptID, EmployeeName, Salary,
       AVG(Salary) OVER (PARTITION BY DeptID) AS DeptAvgSalary,
       Salary - AVG(Salary) OVER (PARTITION BY DeptID) AS DiffFromAvg
FROM Employees

-- Count distinct per partition (workaround)
SELECT CustomerID, ProductID,
       DENSE_RANK() OVER (PARTITION BY CustomerID ORDER BY ProductID) +
       DENSE_RANK() OVER (PARTITION BY CustomerID ORDER BY ProductID DESC) - 1
       AS DistinctProductCount
FROM Orders
```

## Window Frame Specifications

### Frame Types
```sql
-- ROWS: Physical row count
ROWS BETWEEN 2 PRECEDING AND CURRENT ROW

-- RANGE: Logical value range (includes ties)
RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW

-- GROUPS (SQL 2022+): Peer group count
GROUPS BETWEEN 1 PRECEDING AND 1 FOLLOWING
```

### Frame Bounds
```sql
UNBOUNDED PRECEDING     -- From start of partition
n PRECEDING             -- n rows/range before current
CURRENT ROW             -- Current row
n FOLLOWING             -- n rows/range after current
UNBOUNDED FOLLOWING     -- To end of partition
```

### Common Frame Patterns
```sql
-- Running total (default for ordered aggregates)
ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW

-- Entire partition
ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING

-- Moving average (7-day)
ROWS BETWEEN 6 PRECEDING AND CURRENT ROW

-- Centered moving average
ROWS BETWEEN 3 PRECEDING AND 3 FOLLOWING

-- Exclude current row from aggregate
ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
```

### ROWS vs RANGE
```sql
-- ROWS counts physical rows
SELECT Date, Value,
       SUM(Value) OVER (ORDER BY Date ROWS 2 PRECEDING) AS RowSum
-- Exactly 3 rows: current + 2 preceding

-- RANGE uses logical values (includes ties)
SELECT Date, Value,
       SUM(Value) OVER (ORDER BY Date RANGE 2 PRECEDING) AS RangeSum
-- All rows with Date within 2 days before current
```

## WINDOW Clause (SQL Server 2022+)

Define reusable window specifications:
```sql
SELECT
    OrderID,
    CustomerID,
    Amount,
    SUM(Amount) OVER w AS RunningTotal,
    AVG(Amount) OVER w AS RunningAvg,
    COUNT(*) OVER w AS RunningCount
FROM Orders
WINDOW w AS (PARTITION BY CustomerID ORDER BY OrderDate)

-- Multiple windows
SELECT
    OrderID,
    SUM(Amount) OVER daily AS DailyTotal,
    SUM(Amount) OVER monthly AS MonthlyTotal
FROM Orders
WINDOW
    daily AS (PARTITION BY CAST(OrderDate AS DATE) ORDER BY OrderID),
    monthly AS (PARTITION BY YEAR(OrderDate), MONTH(OrderDate) ORDER BY OrderID)
```

## Practical Examples

### Running Totals and Averages
```sql
SELECT
    Date,
    Sales,
    SUM(Sales) OVER (ORDER BY Date) AS CumulativeSales,
    AVG(Sales) OVER (ORDER BY Date ROWS 6 PRECEDING) AS MovingAvg7Day,
    AVG(Sales) OVER (
        PARTITION BY YEAR(Date), MONTH(Date)
        ORDER BY Date
    ) AS MTDAverage
FROM DailySales
```

### Year-over-Year Comparison
```sql
SELECT
    Date,
    Sales,
    LAG(Sales, 365) OVER (ORDER BY Date) AS SalesLastYear,
    Sales - LAG(Sales, 365) OVER (ORDER BY Date) AS YoYChange,
    CASE
        WHEN LAG(Sales, 365) OVER (ORDER BY Date) > 0
        THEN (Sales - LAG(Sales, 365) OVER (ORDER BY Date)) * 100.0 /
             LAG(Sales, 365) OVER (ORDER BY Date)
        ELSE NULL
    END AS YoYChangePercent
FROM DailySales
```

### Top N per Group
```sql
-- Top 3 products per category
WITH RankedProducts AS (
    SELECT
        CategoryID,
        ProductName,
        TotalSales,
        ROW_NUMBER() OVER (
            PARTITION BY CategoryID
            ORDER BY TotalSales DESC
        ) AS Rank
    FROM ProductSales
)
SELECT * FROM RankedProducts WHERE Rank <= 3
```

### Gap and Island Detection
```sql
-- Find consecutive date ranges
WITH Grouped AS (
    SELECT
        Date,
        Date - ROW_NUMBER() OVER (ORDER BY Date) * INTERVAL '1 day' AS GroupID
    FROM ActiveDates
)
SELECT
    MIN(Date) AS StartDate,
    MAX(Date) AS EndDate,
    COUNT(*) AS ConsecutiveDays
FROM Grouped
GROUP BY GroupID
```

### Cumulative Distribution
```sql
SELECT
    Score,
    COUNT(*) AS Frequency,
    SUM(COUNT(*)) OVER (ORDER BY Score) AS CumulativeFrequency,
    SUM(COUNT(*)) OVER (ORDER BY Score) * 100.0 /
        SUM(COUNT(*)) OVER () AS CumulativePercent
FROM TestScores
GROUP BY Score
```

## Performance Considerations

1. **Index for ORDER BY column** - Critical for window function performance
2. **ROWS vs RANGE** - ROWS is typically faster (no tie handling)
3. **Multiple window functions** - Same OVER clause shares a single sort
4. **Batch mode** - SQL 2019+ can use batch mode for window functions on rowstore
5. **Memory grants** - Large partitions may spill to disk; monitor for tempdb spills
