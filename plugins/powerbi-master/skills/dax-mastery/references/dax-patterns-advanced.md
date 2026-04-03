# Advanced DAX Patterns

## 1. Virtual Relationships with TREATAS

Use TREATAS to create virtual relationships without physical model relationships:

```dax
Sales by Budget Category =
CALCULATE(
    [Total Sales],
    TREATAS(
        VALUES(Budget[CategoryID]),
        Sales[CategoryID]
    )
)
```

**When to use:** Connecting tables that share a key but should not have a physical relationship (e.g., budget vs actual from different sources).

## 2. Dynamic Segmentation

Create dynamic segmentation without adding columns to the model:

```dax
// Step 1: Create a disconnected segmentation table
// (using DATATABLE or a calculated table)
Segments = DATATABLE(
    "Segment", STRING, "Min", INTEGER, "Max", INTEGER,
    {
        {"Low", 0, 100},
        {"Medium", 100, 500},
        {"High", 500, 10000}
    }
)

// Step 2: Measure using the segmentation
Sales by Segment =
CALCULATE(
    [Total Sales],
    FILTER(
        ALL(Sales[Amount]),
        VAR CurrentAmount = Sales[Amount]
        VAR SegMin = SELECTEDVALUE(Segments[Min])
        VAR SegMax = SELECTEDVALUE(Segments[Max])
        RETURN CurrentAmount >= SegMin && CurrentAmount < SegMax
    )
)
```

## 3. Parent-Child Hierarchy (Unary Operator)

Flatten a parent-child hierarchy for Power BI:

```dax
// PATH function creates a pipe-delimited path
EmployeePath = PATH(Employee[EmployeeID], Employee[ManagerID])

// PATHLENGTH for depth
Depth = PATHLENGTH(Employee[EmployeePath])

// Extract each level
Level1 = LOOKUPVALUE(
    Employee[EmployeeName],
    Employee[EmployeeID],
    VALUE(PATHITEM(Employee[EmployeePath], 1))
)
Level2 = LOOKUPVALUE(
    Employee[EmployeeName],
    Employee[EmployeeID],
    VALUE(PATHITEM(Employee[EmployeePath], 2))
)

// Rollup measure across hierarchy
Team Sales =
VAR CurrentPath = SELECTEDVALUE(Employee[EmployeePath])
RETURN
CALCULATE(
    [Total Sales],
    FILTER(
        ALL(Employee),
        PATHCONTAINS(Employee[EmployeePath],
            SELECTEDVALUE(Employee[EmployeeID]))
    )
)
```

## 4. Basket Analysis (Products Bought Together)

```dax
// Customers who bought Product A
CustomersWithA =
CALCULATE(
    DISTINCTCOUNT(Sales[CustomerID]),
    FILTER(ALL(Sales), Sales[ProductID] = SELECTEDVALUE(Products[ProductID]))
)

// Customers who bought BOTH Product A and current product
CustomersWith Both =
VAR SelectedProduct = SELECTEDVALUE(Products[ProductID])
RETURN
CALCULATE(
    DISTINCTCOUNT(Sales[CustomerID]),
    FILTER(
        ALL(Sales),
        Sales[CustomerID] IN
            SELECTCOLUMNS(
                FILTER(ALL(Sales), Sales[ProductID] = SelectedProduct),
                "CID", Sales[CustomerID]
            )
    )
)
```

## 5. New vs Returning Customers

```dax
New Customers =
VAR CurrentDate = MAX(Date[Date])
VAR CurrentMonth = EOMONTH(CurrentDate, 0)
VAR MonthStart = EOMONTH(CurrentDate, -1) + 1
RETURN
CALCULATE(
    DISTINCTCOUNT(Sales[CustomerID]),
    FILTER(
        ALL(Sales),
        Sales[OrderDate] >= MonthStart && Sales[OrderDate] <= CurrentMonth
    ),
    FILTER(
        ALL(Sales),
        NOT(
            Sales[CustomerID] IN
            SELECTCOLUMNS(
                FILTER(ALL(Sales), Sales[OrderDate] < MonthStart),
                "CID", Sales[CustomerID]
            )
        )
    )
)

Returning Customers =
[Total Customers] - [New Customers]
```

## 6. ABC Classification (Pareto)

```dax
ABC Category =
VAR TotalSales = CALCULATE([Total Sales], ALL(Products))
VAR ProductSales =
    ADDCOLUMNS(
        ALL(Products[ProductID], Products[ProductName]),
        "ProdSales", [Total Sales]
    )
VAR RankedProducts =
    ADDCOLUMNS(
        ProductSales,
        "RunningTotal",
        SUMX(
            FILTER(ProductSales, [ProdSales] >= EARLIER([ProdSales])),
            [ProdSales]
        )
    )
VAR CurrentRunning =
    MAXX(
        FILTER(RankedProducts,
            [ProductID] = SELECTEDVALUE(Products[ProductID])),
        [RunningTotal]
    )
VAR Percentage = DIVIDE(CurrentRunning, TotalSales)
RETURN
    SWITCH(TRUE(),
        Percentage <= 0.7, "A",
        Percentage <= 0.9, "B",
        "C"
    )
```

## 7. Semi-Additive Measures (Snapshot/Balance)

For measures that should not sum across time (e.g., inventory balance, account balance):

```dax
// Last known balance
Current Balance =
CALCULATE(
    SUM(AccountBalance[Balance]),
    LASTDATE(Date[Date])
)

// Average daily balance
Average Daily Balance =
AVERAGEX(
    VALUES(Date[Date]),
    CALCULATE(SUM(AccountBalance[Balance]))
)

// Opening balance
Opening Balance =
CALCULATE(
    SUM(AccountBalance[Balance]),
    FIRSTDATE(Date[Date])
)
```

## 8. Dynamic Top N with "Others"

```dax
Sales with Others =
VAR TopN = 10
VAR RankVal =
    RANKX(
        ALL(Products[ProductName]),
        [Total Sales],
        ,
        DESC
    )
RETURN
    IF(
        RankVal <= TopN,
        [Total Sales],
        CALCULATE(
            [Total Sales],
            FILTER(
                ALL(Products[ProductName]),
                RANKX(ALL(Products[ProductName]), [Total Sales], , DESC) > TopN
            )
        )
    )
```

## 9. Currency Conversion

```dax
Sales in USD =
SUMX(
    Sales,
    VAR SaleDate = Sales[OrderDate]
    VAR SourceCurrency = RELATED(Region[CurrencyCode])
    VAR ExchangeRate =
        CALCULATE(
            SELECTEDVALUE(ExchangeRates[Rate]),
            ExchangeRates[Date] = SaleDate,
            ExchangeRates[FromCurrency] = SourceCurrency,
            ExchangeRates[ToCurrency] = "USD"
        )
    RETURN Sales[Amount] * ExchangeRate
)
```

## 10. Disconnected Slicer Tables

Create slicers that control measure behavior without filtering data:

```dax
// Disconnected table for metric selection
MetricSelector = DATATABLE(
    "Metric", STRING,
    {{"Revenue"}, {"Profit"}, {"Units"}, {"Margin %"}}
)

// Dynamic measure
Selected Metric =
SWITCH(
    SELECTEDVALUE(MetricSelector[Metric]),
    "Revenue", [Total Revenue],
    "Profit", [Total Profit],
    "Units", [Total Units],
    "Margin %", [Profit Margin %],
    BLANK()
)
```

## 11. Last Non-Blank Value

```dax
Last Reported Value =
CALCULATE(
    SELECTEDVALUE(Metrics[Value]),
    LASTNONBLANK(
        Date[Date],
        CALCULATE(COUNTROWS(Metrics))
    )
)
```

## 12. Cumulative Total

```dax
Cumulative Sales =
CALCULATE(
    [Total Sales],
    FILTER(
        ALL(Date[Date]),
        Date[Date] <= MAX(Date[Date])
    )
)

// More performant version:
Cumulative Sales v2 =
VAR LastDate = MAX(Date[Date])
RETURN
    CALCULATE(
        [Total Sales],
        Date[Date] <= LastDate,
        REMOVEFILTERS(Date[Date])
    )
```

## 13. Percentage of Parent (Visual Totals)

```dax
// % of parent category
% of Category =
DIVIDE(
    [Total Sales],
    CALCULATE([Total Sales], ALLSELECTED(Products[SubCategory]))
)

// % of grand total
% of Grand Total =
DIVIDE(
    [Total Sales],
    CALCULATE([Total Sales], ALL(Products))
)

// % of column total (respecting slicer)
% of Column =
DIVIDE(
    [Total Sales],
    CALCULATE([Total Sales], ALLSELECTED())
)
```

## 14. Handling Many-to-Many Relationships

```dax
// Using bridge table with TREATAS
Sales for Student =
VAR StudentCourses =
    CALCULATETABLE(
        VALUES(StudentCourse[CourseID]),
        TREATAS(VALUES(Students[StudentID]), StudentCourse[StudentID])
    )
RETURN
    CALCULATE(
        [Total Sales],
        TREATAS(StudentCourses, CourseSales[CourseID])
    )
```

## 15. SWITCH with Multiple Conditions

```dax
Customer Tier =
VAR TotalSpend = [Customer Lifetime Value]
VAR OrderCount = [Total Orders]
RETURN
SWITCH(
    TRUE(),
    TotalSpend > 10000 && OrderCount > 50, "Platinum",
    TotalSpend > 5000 && OrderCount > 20, "Gold",
    TotalSpend > 1000 && OrderCount > 5, "Silver",
    "Bronze"
)
```

## 16. Window Functions - Running Total

```dax
Running Total =
CALCULATE(
    [Total Sales],
    WINDOW(1, ABS, 0, REL,
        ALLSELECTED(Date[YearMonth]),
        ORDERBY(Date[YearMonth], ASC)
    )
)
```

## 17. Window Functions - Moving Average

```dax
3M Moving Average =
VAR WindowSize = 3
RETURN
AVERAGEX(
    WINDOW(-WindowSize + 1, REL, 0, REL,
        ALLSELECTED(Date[YearMonth]),
        ORDERBY(Date[YearMonth], ASC)
    ),
    [Total Sales]
)
```

## 18. Window Functions - Rank with PARTITIONBY

```dax
Product Rank in Category =
RANKX(
    ALLSELECTED(Products[ProductName]),
    [Total Sales],
    ,
    DESC
)

// Using RANK function (cleaner for window operations):
Product Rank v2 =
RANK(
    DENSE,
    ALLSELECTED(Products[ProductName]),
    ORDERBY([Total Sales], DESC),
    PARTITIONBY(Products[Category])
)
```

## 19. User-Defined Functions (UDF) Pattern (September 2025 Preview)

```dax
// Define once, reuse across measures
DEFINE
FUNCTION SafeGrowth = (current : NUMERIC, previous : NUMERIC) =>
    IF(previous = 0 || ISBLANK(previous),
        BLANK(),
        DIVIDE(current - previous, ABS(previous))
    )

// Use in multiple measures:
// YoY Growth = SafeGrowth([Total Sales], [PY Sales])
// MoM Growth = SafeGrowth([Total Sales], [PM Sales])
```

**Parameter modes:**
- `val` (eager): Evaluated before function executes -- use for simple scalar inputs
- `expr` (lazy): Evaluated in the function's context -- use for context-sensitive calculations

## 20. Dynamic Format Strings with Calculation Groups

```dax
// Calculation group: Currency Converter
// Calculation item: "Convert to Target"
// Expression:
VAR TargetCurrency = SELECTEDVALUE(CurrencySelector[Currency], "USD")
VAR Rate = LOOKUPVALUE(ExchangeRates[Rate],
    ExchangeRates[ToCurrency], TargetCurrency,
    ExchangeRates[Date], MAX(Date[Date]))
RETURN
    SELECTEDMEASURE() * Rate

// Format string expression:
VAR TargetCurrency = SELECTEDVALUE(CurrencySelector[Currency], "USD")
RETURN
    SWITCH(TargetCurrency,
        "USD", "$#,##0.00",
        "EUR", "€#,##0.00",
        "GBP", "£#,##0.00",
        "JPY", "¥#,##0",
        "#,##0.00"
    )
```

## 21. INFO Functions for Self-Documenting Models

```dax
// Create a calculated table that lists all measures
Model Documentation =
ADDCOLUMNS(
    SELECTCOLUMNS(
        INFO.VIEW.MEASURES(),
        "Measure", [Name],
        "Description", [Description],
        "DAX", [Expression],
        "Format", [FormatString]
    ),
    "Table", RELATED(INFO.VIEW.TABLES()[Name]),
    "Updated", NOW()
)
```

## 22. Calendar-Based Time Intelligence (September 2025 Preview)

```dax
// Week-to-date total using custom calendar
WTD Sales = TOTALWTD([Total Sales], Date[Date])

// Previous week comparison
PW Sales = CALCULATE([Total Sales], PREVIOUSWEEK(Date[Date]))

// Week-over-Week growth
WoW Growth % =
VAR Current = [Total Sales]
VAR PW = CALCULATE([Total Sales], PREVIOUSWEEK(Date[Date]))
RETURN DIVIDE(Current - PW, PW)
```

Requires a calendar defined in the model via Enhanced Time Intelligence preview feature.
