---
name: adf-expression
description: Generate ADF expressions for date manipulation, string operations, and dynamic content
argument-hint: "<what-you-need> [examples: yesterday-date, file-partition-path, conditional-query]"
allowed-tools:
  - Read
---

# ADF Expression Generator

Generate Azure Data Factory expressions for common scenarios.

## Task

Create valid ADF expressions based on the described requirement.

## Arguments

- `$ARGUMENTS`: Description of what the expression should do
  - Example: `yesterday's date in yyyy-MM-dd format`
  - Example: `partition path like year=2025/month=01/day=15`
  - Example: `first day of current month`
  - Example: `extract filename from full path`
  - Example: `check if weekday`
  - Example: `conditional SQL query based on parameter`

## Expression Syntax Rules

### Basic Syntax
- Expressions start with `@` prefix
- Use `@{expression}` for string interpolation
- Nested functions: `@function1(function2(value))`

### Expression vs String Interpolation
```json
// Full expression (returns typed value)
"value": "@utcnow()"

// String interpolation (returns string)
"value": "Date is @{utcnow()}"

// Explicit expression type
{
  "value": "@concat('prefix_', pipeline().parameters.Name)",
  "type": "Expression"
}
```

## Common Expression Patterns

### Date/Time

**Yesterday's Date:**
```
@formatDateTime(adddays(utcnow(), -1), 'yyyy-MM-dd')
```

**First Day of Month:**
```
@formatDateTime(startOfMonth(utcnow()), 'yyyy-MM-dd')
```

**Last Day of Previous Month:**
```
@formatDateTime(adddays(startOfMonth(utcnow()), -1), 'yyyy-MM-dd')
```

**Date Partition Path (year/month/day):**
```
@concat(
  formatDateTime(utcnow(), 'yyyy'), '/',
  formatDateTime(utcnow(), 'MM'), '/',
  formatDateTime(utcnow(), 'dd')
)
```

**Hive Partition Path:**
```
@concat(
  'year=', formatDateTime(pipeline().parameters.ProcessDate, 'yyyy'),
  '/month=', formatDateTime(pipeline().parameters.ProcessDate, 'MM'),
  '/day=', formatDateTime(pipeline().parameters.ProcessDate, 'dd')
)
```

**Is Weekday Check:**
```
@and(greater(dayOfWeek(utcnow()), 0), less(dayOfWeek(utcnow()), 6))
```

**N Days Ago:**
```
@formatDateTime(adddays(utcnow(), -7), 'yyyy-MM-dd')
```

### String Operations

**Extract Filename from Path:**
```
@substring(
  variables('FilePath'),
  add(lastIndexOf(variables('FilePath'), '/'), 1),
  sub(length(variables('FilePath')), add(lastIndexOf(variables('FilePath'), '/'), 1))
)
```

**Remove File Extension:**
```
@substring(
  item().name,
  0,
  lastIndexOf(item().name, '.')
)
```

**Build Dynamic Table Name:**
```
@concat(pipeline().parameters.Schema, '.', pipeline().parameters.Table)
```

**Safe Property Access:**
```
@coalesce(activity('Lookup').output.firstRow.Value, 'default')
```

### Conditional Logic

**Conditional SQL Query:**
```
@if(
  equals(pipeline().parameters.FullLoad, true),
  'SELECT * FROM dbo.Table',
  concat('SELECT * FROM dbo.Table WHERE Date >= ''', pipeline().parameters.LastDate, '''')
)
```

**Conditional File Path:**
```
@if(
  equals(pipeline().parameters.Environment, 'prod'),
  'production/data/',
  'development/data/'
)
```

### Collections

**Array to Comma-Separated String:**
```
@join(activity('Lookup').output.value, ',')
```

**Check Array Not Empty:**
```
@greater(length(activity('Lookup').output.value), 0)
```

**Get First N Items:**
```
@take(activity('Lookup').output.value, 10)
```

**Skip First N Items:**
```
@skip(activity('Lookup').output.value, 10)
```

### Pipeline/Activity References

**Current Pipeline Info:**
```
@pipeline().Pipeline          // Pipeline name
@pipeline().DataFactory       // Data factory name
@pipeline().RunId             // Current run ID
@pipeline().TriggerName       // Trigger name
@pipeline().TriggerType       // 'Manual', 'Schedule', 'Tumbling'
```

**Activity Output:**
```
@activity('LookupConfig').output.firstRow.ColumnName
@activity('CopyData').output.rowsCopied
@activity('CopyData').output.rowsRead
@activity('WebCall').output.Response
```

**Tumbling Window:**
```
@trigger().outputs.windowStartTime
@trigger().outputs.windowEndTime
```

**Blob Event Trigger:**
```
@trigger().outputs.body.fileName
@trigger().outputs.body.folderPath
```

### ForEach Item Access

**Inside ForEach:**
```
@item()                       // Current item
@item().tableName             // Property access
@item()['property-with-dash'] // Bracket notation for special chars
```

## Format Specifiers

| Specifier | Output | Example |
|-----------|--------|---------|
| yyyy | 4-digit year | 2025 |
| yy | 2-digit year | 25 |
| MM | 2-digit month | 01 |
| M | Month (no zero) | 1 |
| MMMM | Full month | January |
| dd | 2-digit day | 15 |
| d | Day (no zero) | 15 |
| dddd | Full day | Wednesday |
| HH | 24-hour | 14 |
| hh | 12-hour | 02 |
| mm | Minutes | 30 |
| ss | Seconds | 45 |
| tt | AM/PM | PM |
| fff | Milliseconds | 123 |

## Output Format

Provide:
1. The complete expression
2. Example output value
3. Where to use it (parameter, activity property, etc.)
4. Any caveats or limitations
