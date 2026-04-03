---
name: dax-mastery
description: |
  This skill should be used when the user asks about "DAX formula", "DAX measure",
  "calculated column", "CALCULATE", "filter context", "row context", "context transition",
  "time intelligence", "SAMEPERIODLASTYEAR", "DATEADD", "YTD", "MTD", "TOTALYTD",
  "DAX patterns", "DAX optimization", "SUMX", "FILTER", "ALL", "REMOVEFILTERS",
  "variables in DAX", "VAR RETURN", "calculation groups", "field parameters",
  "DAX user-defined functions", "UDF", "visual calculations", "window functions",
  "WINDOW", "INDEX", "OFFSET", "ORDERBY", "PARTITIONBY", "MATCHBY",
  "INFO functions", "dynamic format strings", "TOTALWTD", "calendar-based time intelligence",
  "TABLEOF", "NAMEOF", or "DAX anti-patterns".
---

# DAX (Data Analysis Expressions) Mastery

## Overview

Complete DAX reference covering evaluation contexts, CALCULATE, time intelligence, iterators, table functions, performance optimization, and advanced patterns. DAX is the formula language for Power BI measures, calculated columns, calculated tables, and RLS filters.

## Evaluation Contexts

### Row Context
- Created by: Calculated columns, iterators (SUMX, FILTER, AVERAGEX, etc.), row-by-row evaluation
- Each row in the table has its own row context
- Access columns directly: `Sales[Amount]`
- Nested iterators create nested row contexts

### Filter Context
- Created by: Slicers, visual filters, page filters, report filters, CALCULATE arguments
- Determines which rows are visible to aggregation functions
- Does NOT provide row-level access (cannot use `Sales[Amount]` directly in a measure without aggregation)

### Context Transition
- CALCULATE converts row context into filter context
- Happens when a measure is referenced inside an iterator
- Each row's column values become filter arguments

```dax
// Context transition example:
Sales Amount = SUM(Sales[Amount])

// Inside SUMX, each row triggers context transition:
Weighted Amount =
SUMX(
    Products,
    Products[Weight] * [Sales Amount]  // [Sales Amount] triggers CALCULATE internally
)
```

## CALCULATE - The Most Important Function

```dax
CALCULATE(<expression>, <filter1>, <filter2>, ...)
```

**Filter argument types:**

| Type | Example | Behavior |
|------|---------|----------|
| Boolean (table filter) | `Products[Color] = "Red"` | Adds filter, keeps existing context |
| Table expression | `FILTER(ALL(Products), Products[Price] > 100)` | Replaces filter on affected columns |
| REMOVEFILTERS | `REMOVEFILTERS(Products[Color])` | Removes existing filter on column |
| ALL | `ALL(Products)` | Removes all filters on table |
| KEEPFILTERS | `KEEPFILTERS(Products[Color] = "Red")` | Intersects with existing filter |
| USERELATIONSHIP | `USERELATIONSHIP(Sales[ShipDate], Date[Date])` | Activates inactive relationship |
| CROSSFILTER | `CROSSFILTER(Sales[ProductID], Products[ID], Both)` | Changes cross-filter direction |

**Critical rules:**
- Boolean filters are syntactic sugar for FILTER(ALL(column), condition)
- Boolean filters REPLACE the existing filter on that column
- Use KEEPFILTERS to ADD to (intersect with) existing filters
- CALCULATE modifiers (ALL, REMOVEFILTERS) execute BEFORE filter arguments

## Time Intelligence Quick Reference

**Prerequisite:** A proper Date table marked as a date table with a continuous date column.

| Function | Purpose | Example |
|----------|---------|---------|
| TOTALYTD | Year-to-date | `TOTALYTD([Sales], Date[Date])` |
| TOTALMTD | Month-to-date | `TOTALMTD([Sales], Date[Date])` |
| TOTALQTD | Quarter-to-date | `TOTALQTD([Sales], Date[Date])` |
| SAMEPERIODLASTYEAR | Same period, prior year | `CALCULATE([Sales], SAMEPERIODLASTYEAR(Date[Date]))` |
| DATEADD | Shift by interval | `CALCULATE([Sales], DATEADD(Date[Date], -1, MONTH))` |
| PARALLELPERIOD | Entire shifted period | `CALCULATE([Sales], PARALLELPERIOD(Date[Date], -1, QUARTER))` |
| DATESYTD | Date table filtered to YTD | `CALCULATE([Sales], DATESYTD(Date[Date]))` |
| DATESBETWEEN | Date range | `CALCULATE([Sales], DATESBETWEEN(Date[Date], start, end))` |
| PREVIOUSMONTH | Entire previous month | `CALCULATE([Sales], PREVIOUSMONTH(Date[Date]))` |
| PREVIOUSYEAR | Entire previous year | `CALCULATE([Sales], PREVIOUSYEAR(Date[Date]))` |

**Common time intelligence patterns:**

```dax
// Year-over-Year Growth %
YoY Growth % =
VAR CurrentSales = [Total Sales]
VAR PriorYearSales = CALCULATE([Total Sales], SAMEPERIODLASTYEAR(Date[Date]))
RETURN
    DIVIDE(CurrentSales - PriorYearSales, PriorYearSales)

// Rolling 12-Month Total
Rolling 12M =
CALCULATE(
    [Total Sales],
    DATESINPERIOD(Date[Date], MAX(Date[Date]), -12, MONTH)
)

// Moving Average (3 months)
3M Moving Avg =
AVERAGEX(
    DATESINPERIOD(Date[Date], MAX(Date[Date]), -3, MONTH),
    CALCULATE([Total Sales])
)
```

## Variables (VAR/RETURN)

Always use variables for readability and performance:

```dax
Profit Margin % =
VAR TotalRevenue = SUM(Sales[Revenue])
VAR TotalCost = SUM(Sales[Cost])
VAR Profit = TotalRevenue - TotalCost
RETURN
    DIVIDE(Profit, TotalRevenue)
```

**Rules:**
- Variables are evaluated once (performance benefit when reused)
- Variables capture filter context at the point of definition
- Variables can hold scalar values or tables
- Use meaningful names (not `x`, `temp`)

## Iterator Functions

Iterators scan a table row by row, creating row context:

| Function | Purpose |
|----------|---------|
| SUMX | Sum of expression evaluated per row |
| AVERAGEX | Average of expression per row |
| MINX / MAXX | Min/Max of expression per row |
| COUNTX | Count of non-blank expression results |
| RANKX | Rank based on expression |
| FILTER | Returns table rows matching condition |
| ADDCOLUMNS | Adds calculated columns to table |
| SELECTCOLUMNS | Returns table with selected/calculated columns |
| GENERATE | Cross-join with row context |

```dax
// Weighted average price
Weighted Avg Price =
SUMX(
    Sales,
    Sales[Quantity] * RELATED(Products[UnitPrice])
) / SUM(Sales[Quantity])
```

## Calculation Groups

Reduce measure sprawl by defining reusable calculation patterns:

```dax
// Instead of creating YTD, PY, YoY for EVERY measure:
// Create ONE calculation group with items:
// - Current: SELECTEDMEASURE()
// - YTD: CALCULATE(SELECTEDMEASURE(), DATESYTD(Date[Date]))
// - PY: CALCULATE(SELECTEDMEASURE(), SAMEPERIODLASTYEAR(Date[Date]))
// - YoY%: VAR Curr = SELECTEDMEASURE()
//         VAR PY = CALCULATE(SELECTEDMEASURE(), SAMEPERIODLASTYEAR(Date[Date]))
//         RETURN DIVIDE(Curr - PY, PY)
```

Create via Tabular Editor, TMDL view in Desktop, or TOM/.NET SDK.

## Field Parameters

Enable users to dynamically switch dimensions or measures in visuals:

```dax
// Created via Modeling tab > New parameter > Fields
// Generates a calculated table:
Parameter =
{
    ("Revenue", NAMEOF(Sales[Total Revenue]), 0),
    ("Profit", NAMEOF(Sales[Total Profit]), 1),
    ("Units", NAMEOF(Sales[Total Units]), 2)
}
```

## User-Defined Functions (September 2025 Preview)

The most significant DAX language update since variables (2015). Define reusable parameterized functions:

```dax
// Define a UDF in DAX query view or model
DEFINE
FUNCTION AddTax = (amount : NUMERIC) => amount * 1.1

// Nest UDFs
FUNCTION AddTaxAndDiscount = (amount : NUMERIC, discount : NUMERIC) =>
    AddTax(amount - discount)

EVALUATE { AddTaxAndDiscount(100, 20) }  // Returns 88
```

**Parameter types:** `NUMERIC`, `Scalar`, `Table`, `AnyVal`, `AnyRef`, `CalendarRef`, `ColumnRef`, `MeasureRef`, `TableRef`

**Parameter modes:** `val` (eager evaluation) or `expr` (lazy/context-sensitive)

**Usage:** Once defined and saved to the model, call UDFs from measures, calculated columns, visual calculations, and other UDFs.

**Enable:** File > Options > Preview features > DAX user-defined functions

## Window Functions (WINDOW, INDEX, OFFSET)

DAX window functions for row-relative and range calculations:

```dax
// Running total using WINDOW
Running Total =
CALCULATE(
    [Total Sales],
    WINDOW(1, ABS, 0, REL, ALLSELECTED(Date[Month]),
        ORDERBY(Date[MonthNumber], ASC))
)

// Previous row value using OFFSET
Previous Month Sales =
CALCULATE(
    [Total Sales],
    OFFSET(-1, ALLSELECTED(Date[Month]),
        ORDERBY(Date[MonthNumber], ASC))
)

// Nth row using INDEX
First Month Sales =
CALCULATE(
    [Total Sales],
    INDEX(1, ALLSELECTED(Date[Month]),
        ORDERBY(Date[MonthNumber], ASC))
)
```

**Key clauses:**
- `ORDERBY` -- sort order within the window
- `PARTITIONBY` -- subset of rows (the "window" partition)
- `MATCHBY` -- identify the current row in ambiguous contexts

## Visual Calculations (2024-2026)

Calculations scoped to the visual matrix, not the data model:

| Function | Purpose |
|----------|---------|
| FIRST | Value from first row of axis |
| LAST | Value from last row of axis |
| PREVIOUS | Value from previous row |
| NEXT | Value from next row |
| LOOKUP | Value with filter (June 2025) |
| LOOKUPWITHTOTALS | Value with filter, respects totals (June 2025) |

Visual calculations are defined per-visual and do not affect the semantic model.

## Calendar-Based Time Intelligence (September 2025 Preview)

Define custom calendars (fiscal, retail, 13-month, lunar) with 8 new week-based functions:

| Function | Purpose |
|----------|---------|
| TOTALWTD | Week-to-date running total |
| CLOSINGBALANCEWEEK | Closing balance for the week |
| OPENINGBALANCEWEEK | Opening balance for the week |
| STARTOFWEEK | First date of current week |
| ENDOFWEEK | Last date of current week |
| NEXTWEEK | Table of dates for next week |
| PREVIOUSWEEK | Table of dates for previous week |
| DATESWTD | Week-to-date date filter |

**Enable:** File > Options > Preview features > Enhanced DAX Time Intelligence

## Dynamic Format Strings

Apply context-dependent formatting without converting to text (GA in Desktop and Report Server Jan 2025+):

```dax
// Dynamic format string for currency
Total Sales =
SUM(Sales[Amount])

// Format string expression (set in measure properties):
// = IF(SELECTEDVALUE(Currency[Code]) = "EUR", "€#,##0.00", "$#,##0.00")
```

**Advantage over FORMAT():** Keeps numeric data type, enabling correct chart rendering and sorting.

## TABLEOF and NAMEOF (February 2026)

Reference model objects that auto-adapt to renames:

```dax
// NAMEOF returns the name of a column/measure/calendar as text
NAMEOF(Sales[Amount])  // Returns "Amount"

// TABLEOF returns a reference to the table of a column/measure
TABLEOF(Sales[Amount])  // Returns reference to Sales table
```

Useful inside UDFs for safer, rename-proof code.

## Common Anti-Patterns

| Anti-Pattern | Problem | Fix |
|-------------|---------|-----|
| `FILTER(table, ...)` as CALCULATE arg | Full table scan, no engine optimization | Use boolean filter: `column = value` |
| Nested CALCULATE | Confusing context overrides | Use single CALCULATE with multiple filters |
| SUMX over entire table for simple sum | Unnecessary iterator | Use SUM() for simple column aggregation |
| FORMAT() in measures for sorting | Returns text, cannot sort numerically | Use separate sort column |
| Calculated columns for aggregation | Stored per row, wastes memory | Use measures instead |
| COUNTROWS(FILTER(table,...)) | Slower than CALCULATE(COUNTROWS(table), filter) | Use CALCULATE with filter |
| Copy-pasting DAX across measures | Hard to maintain, error-prone | Use UDFs (preview) to define reusable logic |
| FORMAT() for conditional display | Returns text, breaks sorting/charts | Use dynamic format strings instead |
| Overusing EARLIER() | Confusing, legacy pattern | Use VAR to capture outer context |
| Ignoring MATCHBY in window functions | Ambiguous row identity | Always specify MATCHBY when partition has duplicates |

## Additional Resources

### Reference Files
- **`references/dax-function-categories.md`** -- Complete function reference organized by category including INFO functions, window functions, and 2025-2026 additions
- **`references/dax-patterns-advanced.md`** -- Advanced patterns: virtual relationships, dynamic segmentation, parent-child hierarchies, basket analysis
