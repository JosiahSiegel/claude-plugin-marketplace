# DAX Function Categories Reference

## Aggregation Functions

| Function | Syntax | Purpose |
|----------|--------|---------|
| SUM | `SUM(column)` | Sum of column values |
| AVERAGE | `AVERAGE(column)` | Average of column values |
| MIN | `MIN(column)` or `MIN(expr1, expr2)` | Minimum value |
| MAX | `MAX(column)` or `MAX(expr1, expr2)` | Maximum value |
| COUNT | `COUNT(column)` | Count of numeric non-blank values |
| COUNTA | `COUNTA(column)` | Count of non-blank values (any type) |
| COUNTBLANK | `COUNTBLANK(column)` | Count of blank values |
| COUNTROWS | `COUNTROWS(table)` | Count of rows in table |
| DISTINCTCOUNT | `DISTINCTCOUNT(column)` | Count of distinct non-blank values |
| DISTINCTCOUNTNOBLANK | `DISTINCTCOUNTNOBLANK(column)` | Count distinct including BLANK |
| PRODUCT | `PRODUCT(column)` | Product (multiplication) of values |
| MEDIAN | `MEDIAN(column)` | Median value |
| PERCENTILE.INC | `PERCENTILE.INC(column, percentile)` | Inclusive percentile |
| PERCENTILE.EXC | `PERCENTILE.EXC(column, percentile)` | Exclusive percentile |

## Iterator (X) Functions

| Function | Syntax | Purpose |
|----------|--------|---------|
| SUMX | `SUMX(table, expression)` | Sum of expression per row |
| AVERAGEX | `AVERAGEX(table, expression)` | Average of expression per row |
| MINX | `MINX(table, expression)` | Min of expression per row |
| MAXX | `MAXX(table, expression)` | Max of expression per row |
| COUNTX | `COUNTX(table, expression)` | Count non-blank expression results |
| RANKX | `RANKX(table, expression[, value[, order[, ties]]])` | Rank based on expression |
| PRODUCTX | `PRODUCTX(table, expression)` | Product of expression per row |
| CONCATENATEX | `CONCATENATEX(table, expression, delimiter[, orderBy[, order]])` | Concatenate expression results |

## Filter Functions

| Function | Syntax | Purpose |
|----------|--------|---------|
| CALCULATE | `CALCULATE(expression, filter1, ...)` | Evaluate in modified filter context |
| CALCULATETABLE | `CALCULATETABLE(table, filter1, ...)` | Return table in modified context |
| FILTER | `FILTER(table, condition)` | Return rows matching condition |
| ALL | `ALL(table/column)` | Remove all filters |
| ALLEXCEPT | `ALLEXCEPT(table, column1, ...)` | Remove all filters except specified |
| ALLSELECTED | `ALLSELECTED([column])` | Restore filters to query context |
| REMOVEFILTERS | `REMOVEFILTERS([table/column])` | Remove filters (clearer than ALL) |
| KEEPFILTERS | `KEEPFILTERS(filter)` | Intersect with existing filter |
| SELECTEDVALUE | `SELECTEDVALUE(column[, alternateResult])` | Return value if single selection |
| HASONEVALUE | `HASONEVALUE(column)` | True if single value in context |
| HASONEFILTER | `HASONEFILTER(column)` | True if single filter on column |
| ISFILTERED | `ISFILTERED(column)` | True if column is filtered |
| ISCROSSFILTERED | `ISCROSSFILTERED(column)` | True if column is cross-filtered |
| VALUES | `VALUES(column/table)` | Distinct values respecting filters |
| DISTINCT | `DISTINCT(column/table)` | Distinct values respecting filters |
| FILTERS | `FILTERS(column)` | Table of filter values |
| EARLIER | `EARLIER(column[, number])` | Value in outer row context |
| EARLIEST | `EARLIEST(column)` | Value in outermost row context |

## Table Functions

| Function | Syntax | Purpose |
|----------|--------|---------|
| ADDCOLUMNS | `ADDCOLUMNS(table, name, expression, ...)` | Add calculated columns |
| SELECTCOLUMNS | `SELECTCOLUMNS(table, name, expression, ...)` | Project columns |
| SUMMARIZE | `SUMMARIZE(table, groupCol, ...)` | Group by with optional extensions |
| SUMMARIZECOLUMNS | `SUMMARIZECOLUMNS(groupCol, ..., filterTable, ..., name, expression, ...)` | Optimized group by (preferred) |
| GROUPBY | `GROUPBY(table, groupCol, ..., name, CURRENTGROUP(), ...)` | Group with current group access |
| CROSSJOIN | `CROSSJOIN(table1, table2, ...)` | Cartesian product |
| UNION | `UNION(table1, table2, ...)` | Combine tables (append rows) |
| INTERSECT | `INTERSECT(table1, table2)` | Common rows between tables |
| EXCEPT | `EXCEPT(table1, table2)` | Rows in table1 not in table2 |
| NATURALINNERJOIN | `NATURALINNERJOIN(table1, table2)` | Inner join on common columns |
| NATURALLEFTOUTERJOIN | `NATURALLEFTOUTERJOIN(table1, table2)` | Left join on common columns |
| GENERATE | `GENERATE(table1, table2Expression)` | Cross apply (row context) |
| GENERATEALL | `GENERATEALL(table1, table2Expression)` | Cross apply (preserves blanks) |
| ROW | `ROW(name, expression, ...)` | Single-row table |
| DATATABLE | `DATATABLE(name, type, ...)` | Inline table definition |
| TREATAS | `TREATAS(table, column1, ...)` | Apply table as filter on columns |
| TOPN | `TOPN(n, table, expression[, order])` | Top N rows by expression |

## Time Intelligence Functions

| Function | Syntax | Purpose |
|----------|--------|---------|
| DATESYTD | `DATESYTD(dateColumn[, yearEndDate])` | Date table filtered YTD |
| DATESMTD | `DATESMTD(dateColumn)` | Date table filtered MTD |
| DATESQTD | `DATESQTD(dateColumn)` | Date table filtered QTD |
| TOTALYTD | `TOTALYTD(expression, dateColumn[, filter[, yearEndDate]])` | Year-to-date total |
| TOTALMTD | `TOTALMTD(expression, dateColumn[, filter])` | Month-to-date total |
| TOTALQTD | `TOTALQTD(expression, dateColumn[, filter])` | Quarter-to-date total |
| SAMEPERIODLASTYEAR | `SAMEPERIODLASTYEAR(dateColumn)` | Same dates, prior year |
| PREVIOUSMONTH | `PREVIOUSMONTH(dateColumn)` | Entire previous month |
| PREVIOUSQUARTER | `PREVIOUSQUARTER(dateColumn)` | Entire previous quarter |
| PREVIOUSYEAR | `PREVIOUSYEAR(dateColumn)` | Entire previous year |
| NEXTMONTH | `NEXTMONTH(dateColumn)` | Entire next month |
| NEXTQUARTER | `NEXTQUARTER(dateColumn)` | Entire next quarter |
| NEXTYEAR | `NEXTYEAR(dateColumn)` | Entire next year |
| DATEADD | `DATEADD(dateColumn, intervals, interval)` | Shift dates |
| DATESINPERIOD | `DATESINPERIOD(dateColumn, startDate, intervals, interval)` | Date range |
| DATESBETWEEN | `DATESBETWEEN(dateColumn, startDate, endDate)` | Date range (explicit) |
| PARALLELPERIOD | `PARALLELPERIOD(dateColumn, intervals, interval)` | Entire shifted period |
| OPENINGBALANCEMONTH | `OPENINGBALANCEMONTH(expression, dateColumn[, filter])` | Opening balance |
| CLOSINGBALANCEMONTH | `CLOSINGBALANCEMONTH(expression, dateColumn[, filter])` | Closing balance |
| FIRSTDATE | `FIRSTDATE(dateColumn)` | First date in context |
| LASTDATE | `LASTDATE(dateColumn)` | Last date in context |
| STARTOFMONTH | `STARTOFMONTH(dateColumn)` | First day of month |
| ENDOFMONTH | `ENDOFMONTH(dateColumn)` | Last day of month |
| STARTOFQUARTER | `STARTOFQUARTER(dateColumn)` | First day of quarter |
| ENDOFQUARTER | `ENDOFQUARTER(dateColumn)` | Last day of quarter |
| STARTOFYEAR | `STARTOFYEAR(dateColumn[, yearEndDate])` | First day of year |
| ENDOFYEAR | `ENDOFYEAR(dateColumn[, yearEndDate])` | Last day of year |

## Logical Functions

| Function | Syntax | Purpose |
|----------|--------|---------|
| IF | `IF(condition, trueResult[, falseResult])` | Conditional |
| SWITCH | `SWITCH(expression, value1, result1, ...[, else])` | Multi-branch |
| AND | `AND(cond1, cond2)` or `cond1 && cond2` | Logical AND |
| OR | `OR(cond1, cond2)` or `cond1 \|\| cond2` | Logical OR |
| NOT | `NOT(condition)` | Logical NOT |
| TRUE | `TRUE()` | Boolean true |
| FALSE | `FALSE()` | Boolean false |
| COALESCE | `COALESCE(expr1, expr2, ...)` | First non-blank |
| IFERROR | `IFERROR(expression, alternateResult)` | Error handling |

## Text Functions

| Function | Syntax | Purpose |
|----------|--------|---------|
| CONCATENATE | `CONCATENATE(text1, text2)` | Join two strings |
| FORMAT | `FORMAT(value, formatString)` | Format as text |
| LEFT | `LEFT(text, numChars)` | Left substring |
| RIGHT | `RIGHT(text, numChars)` | Right substring |
| MID | `MID(text, startPos, numChars)` | Middle substring |
| LEN | `LEN(text)` | String length |
| UPPER | `UPPER(text)` | Uppercase |
| LOWER | `LOWER(text)` | Lowercase |
| TRIM | `TRIM(text)` | Remove extra spaces |
| SUBSTITUTE | `SUBSTITUTE(text, oldText, newText[, instance])` | Replace text |
| SEARCH | `SEARCH(findText, withinText[, startPos])` | Find position (case-insensitive) |
| FIND | `FIND(findText, withinText[, startPos])` | Find position (case-sensitive) |
| BLANK | `BLANK()` | Return blank value |
| ISBLANK | `ISBLANK(value)` | Test for blank |
| COMBINEVALUES | `COMBINEVALUES(delimiter, value1, ...)` | Concatenate with delimiter |
| CONTAINSSTRING | `CONTAINSSTRING(withinText, findText)` | Case-insensitive contains |
| CONTAINSSTRINGEXACT | `CONTAINSSTRINGEXACT(withinText, findText)` | Case-sensitive contains |

## Math and Statistical Functions

| Function | Syntax | Purpose |
|----------|--------|---------|
| DIVIDE | `DIVIDE(numerator, denominator[, alternateResult])` | Safe division |
| ABS | `ABS(number)` | Absolute value |
| ROUND | `ROUND(number, digits)` | Round |
| ROUNDUP | `ROUNDUP(number, digits)` | Round up |
| ROUNDDOWN | `ROUNDDOWN(number, digits)` | Round down |
| INT | `INT(number)` | Integer (floor) |
| MOD | `MOD(number, divisor)` | Modulo |
| POWER | `POWER(number, power)` | Exponentiation |
| SQRT | `SQRT(number)` | Square root |
| LN | `LN(number)` | Natural logarithm |
| LOG | `LOG(number[, base])` | Logarithm |
| RAND | `RAND()` | Random 0-1 |
| SIGN | `SIGN(number)` | Sign (-1, 0, 1) |

## Relationship Functions

| Function | Syntax | Purpose |
|----------|--------|---------|
| RELATED | `RELATED(column)` | Value from related table (many-to-one) |
| RELATEDTABLE | `RELATEDTABLE(table)` | Related rows (one-to-many) |
| USERELATIONSHIP | `USERELATIONSHIP(column1, column2)` | Activate inactive relationship |
| CROSSFILTER | `CROSSFILTER(col1, col2, direction)` | Change cross-filter |
| LOOKUPVALUE | `LOOKUPVALUE(resultColumn, searchColumn, searchValue, ...)` | Lookup without relationship |
| TREATAS | `TREATAS(table, column, ...)` | Virtual relationship |

## Window Functions (2023+)

| Function | Syntax | Purpose |
|----------|--------|---------|
| WINDOW | `WINDOW(from, from_type, to, to_type[, relation][, orderBy][, blanks][, partitionBy][, matchBy][, reset])` | Return rows within a window range |
| INDEX | `INDEX(n[, relation][, orderBy][, blanks][, partitionBy][, matchBy])` | Return the nth row |
| OFFSET | `OFFSET(delta[, relation][, orderBy][, blanks][, partitionBy][, matchBy])` | Return row offset from current |
| RANK | `RANK([ties][, relation][, orderBy][, blanks][, partitionBy][, matchBy][, reset])` | Rank in partition |
| ROWNUMBER | `ROWNUMBER([relation][, orderBy][, blanks][, partitionBy][, matchBy][, reset])` | Unique row number in partition |
| ORDERBY | `ORDERBY(column[, order], ...)` | Define sort order for window |
| PARTITIONBY | `PARTITIONBY(column, ...)` | Define partition columns for window |
| MATCHBY | `MATCHBY(column, ...)` | Identify current row in window |

## Visual Calculation Functions (2024-2026)

| Function | Syntax | Purpose |
|----------|--------|---------|
| FIRST | `FIRST(expression[, axis][, blanks][, reset])` | Value from first row of axis |
| LAST | `LAST(expression[, axis][, blanks][, reset])` | Value from last row of axis |
| PREVIOUS | `PREVIOUS(expression[, axis][, blanks][, reset])` | Value from previous row |
| NEXT | `NEXT(expression[, axis][, blanks][, reset])` | Value from next row |
| LOOKUP | `LOOKUP(expression, filter1, value1, ...)` | Filtered lookup in visual matrix (June 2025) |
| LOOKUPWITHTOTALS | `LOOKUPWITHTOTALS(expression, filter1, value1, ...)` | Filtered lookup respecting totals (June 2025) |

## New Functions (2025-2026)

| Function | Syntax | Purpose | Added |
|----------|--------|---------|-------|
| TABLEOF | `TABLEOF(column/measure/calendar)` | Table reference that auto-adapts to renames | Feb 2026 |
| TOTALWTD | `TOTALWTD(expression, dateColumn[, filter])` | Week-to-date total | Sep 2025 |
| CLOSINGBALANCEWEEK | `CLOSINGBALANCEWEEK(expression, dateColumn[, filter])` | Closing balance for the week | Sep 2025 |
| OPENINGBALANCEWEEK | `OPENINGBALANCEWEEK(expression, dateColumn[, filter])` | Opening balance for the week | Sep 2025 |
| STARTOFWEEK | `STARTOFWEEK(dateColumn)` | First date of current week | Sep 2025 |
| ENDOFWEEK | `ENDOFWEEK(dateColumn)` | Last date of current week | Sep 2025 |
| NEXTWEEK | `NEXTWEEK(dateColumn)` | Table of dates for next week | Sep 2025 |
| PREVIOUSWEEK | `PREVIOUSWEEK(dateColumn)` | Table of dates for previous week | Sep 2025 |
| DATESWTD | `DATESWTD(dateColumn)` | Week-to-date date filter | Sep 2025 |
| LINEST / LINESTX | See **Statistical Functions** below | Linear regression (least squares) | Feb 2023 |

## Statistical Functions

| Function | Syntax | Purpose |
|----------|--------|---------|
| LINEST | `LINEST(table, yColumn, xColumn, ...)` | Least-squares linear regression |
| LINESTX | `LINESTX(table, yExpression, xExpression, ...)` | Least-squares with expressions per row |

## Information Functions

| Function | Syntax | Purpose |
|----------|--------|---------|
| ISBLANK | `ISBLANK(value)` | Test blank |
| ISERROR | `ISERROR(value)` | Test error |
| ISLOGICAL | `ISLOGICAL(value)` | Test boolean |
| ISNUMBER | `ISNUMBER(value)` | Test number |
| ISTEXT | `ISTEXT(value)` | Test text |
| ISNONTEXT | `ISNONTEXT(value)` | Test non-text |
| USERPRINCIPALNAME | `USERPRINCIPALNAME()` | Current user UPN (for RLS) |
| USERNAME | `USERNAME()` | Current user (domain\user or UPN) |
| SELECTEDMEASURE | `SELECTEDMEASURE()` | Current measure (calculation groups) |
| SELECTEDMEASURENAME | `SELECTEDMEASURENAME()` | Name of current measure |
| NAMEOF | `NAMEOF(column/measure/calendar)` | Name as text string |
| TABLEOF | `TABLEOF(column/measure/calendar)` | Table reference (Feb 2026) |

## INFO DAX Functions (Model Metadata)

INFO functions return metadata about the semantic model as tables. They replace DMVs with native DAX capability.

### INFO.VIEW Functions (Usable in calculated tables, columns, measures, and DAX queries)

| Function | Returns |
|----------|---------|
| `INFO.VIEW.TABLES()` | All tables (name, description, storage mode, hidden) |
| `INFO.VIEW.COLUMNS()` | All columns (name, data type, hidden, table) |
| `INFO.VIEW.MEASURES()` | All measures (name, expression, format string) |
| `INFO.VIEW.RELATIONSHIPS()` | All relationships (from/to table/column, cardinality, direction) |

### INFO Functions (DAX query view only, require semantic model admin permissions)

| Function | Returns |
|----------|---------|
| `INFO.TABLES()` | All tables (schema rowset format) |
| `INFO.COLUMNS()` | All columns (schema rowset format) |
| `INFO.MEASURES()` | All measures (schema rowset format) |
| `INFO.RELATIONSHIPS()` | All relationships (schema rowset format) |
| `INFO.PARTITIONS()` | All partitions |
| `INFO.ROLES()` | All security roles |
| `INFO.ROLEMEMBERSHIPS()` | Role membership details |
| `INFO.TABLEPERMISSIONS()` | Table-level permissions |
| `INFO.COLUMNPERMISSIONS()` | Column-level permissions (OLS) |
| `INFO.CALCULATIONGROUPS()` | Calculation group definitions |
| `INFO.CALCULATIONITEMS()` | Calculation items in groups |
| `INFO.EXPRESSIONS()` | M expressions (partitions) |
| `INFO.HIERARCHIES()` | Hierarchy definitions |
| `INFO.LEVELS()` | Hierarchy level details |
| `INFO.CULTURES()` | Translation cultures |
| `INFO.PERSPECTIVES()` | Perspectives |
| `INFO.FUNCTIONS()` | Available DAX functions |
| `INFO.USERDEFINEDFUNCTIONS()` | User-defined functions (March 2026) |
| `INFO.STORAGETABLES()` | In-memory table statistics |
| `INFO.STORAGETABLECOLUMNS()` | In-memory column statistics |
| `INFO.STORAGETABLECOLUMNSEGMENTS()` | Column segment storage info |
| `INFO.ANNOTATIONS()` | Model annotations |
| `INFO.DATASOURCES()` | Data source definitions |
| `INFO.REFRESHPOLICIES()` | Incremental refresh policies |
| `INFO.FORMATSTRINGDEFINITIONS()` | Dynamic format string definitions |
| `INFO.DEPENDENCIES()` | Calculation dependency graph |

**Example -- self-documenting model:**
```dax
// Create a calculated table that lists all measures
EVALUATE
ADDCOLUMNS(
    SELECTCOLUMNS(
        INFO.VIEW.MEASURES(),
        "Measure", [Name],
        [Description],
        "DAX Formula", [Expression],
        "State", [State]
    ),
    "Model name", "My Semantic Model",
    "As of date", NOW()
)
```
