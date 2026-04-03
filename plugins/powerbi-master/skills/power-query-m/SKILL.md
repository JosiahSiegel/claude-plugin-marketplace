---
name: power-query-m
description: |
  This skill should be used when the user asks about "Power Query", "M language",
  "M code", "query folding", "data transformation", "custom connector",
  "Power Query parameters", "dynamic source", "query optimization",
  "Table.TransformColumns", "List.Generate", "error handling in M",
  "Power Query performance", "mashup engine", "advanced editor",
  "ETL", "merge queries", "append tables", "pivot columns", "unpivot",
  "remove duplicates", "split column", "combine files", "folder source",
  "Power Query Online", "Dataflow Gen2 M code", "refresh optimization",
  or "data transformation".
---

# Power Query (M Language)

## Overview

Power Query is the data transformation engine in Power BI, using the M functional language. It handles ETL (Extract, Transform, Load) from sources to the data model. Understanding query folding, step optimization, and M syntax is critical for performant data refresh.

## Query Folding

Query folding translates M steps into native source queries (SQL, OData, etc.), pushing computation to the source instead of the mashup engine.

**How to check folding:**
1. Right-click a step in Applied Steps > "View Native Query" -- if grayed out, folding broke
2. Use Query Diagnostics (Tools > Start Diagnostics) to see what queries are sent

**Steps that fold (common):**
| Operation | SQL Translation |
|-----------|----------------|
| Remove columns | SELECT (column list) |
| Filter rows | WHERE clause |
| Sort rows | ORDER BY |
| Group by | GROUP BY |
| Rename columns | Column aliases |
| Change type (basic) | CAST |
| Merge queries (database) | JOIN |
| Top N rows | TOP / LIMIT |
| Remove duplicates | DISTINCT |

**Steps that break folding:**
| Operation | Why |
|-----------|-----|
| Add custom column (complex) | M expression cannot translate to SQL |
| Pivot/Unpivot (sometimes) | Depends on source capability |
| Merge with non-foldable source | Cannot push cross-source joins |
| Table.Buffer | Explicitly materializes in memory |
| Reorder after custom step | Once broken, subsequent steps cannot fold |
| Date/time transforms (some) | Source-specific function differences |

**Golden rule:** Put foldable steps BEFORE non-foldable steps. Once folding breaks, all subsequent steps run in the mashup engine.

## M Language Essentials

### Let Expression (Query Structure)

Every Power Query query is a `let...in` expression:

```m
let
    Source = Sql.Database("server", "database"),
    Filtered = Table.SelectRows(Source, each [Status] = "Active"),
    Renamed = Table.RenameColumns(Filtered, {{"OldName", "NewName"}}),
    Typed = Table.TransformColumnTypes(Renamed, {{"Amount", type number}})
in
    Typed
```

### Data Types

| M Type | Description |
|--------|-------------|
| `type text` | String/text |
| `type number` | Decimal number |
| `Int64.Type` | Whole number (64-bit integer) |
| `type date` | Date only |
| `type datetime` | Date and time |
| `type datetimezone` | Date, time, and timezone |
| `type duration` | Time duration |
| `type logical` | Boolean (true/false) |
| `type binary` | Binary data |
| `type null` | Null value |
| `Currency.Type` | Fixed decimal (4 places) |
| `Percentage.Type` | Percentage |

### Common Table Functions

```m
// Filter rows
Table.SelectRows(table, each [Column] > 100)

// Add column
Table.AddColumn(table, "NewCol", each [Col1] * [Col2], type number)

// Remove columns
Table.RemoveColumns(table, {"Col1", "Col2"})

// Select columns (keep only these)
Table.SelectColumns(table, {"Col1", "Col2", "Col3"})

// Rename columns
Table.RenameColumns(table, {{"Old1", "New1"}, {"Old2", "New2"}})

// Change types
Table.TransformColumnTypes(table, {{"Col1", type number}, {"Col2", type text}})

// Replace values
Table.ReplaceValue(table, "old", "new", Replacer.ReplaceText, {"Column"})

// Group by
Table.Group(table, {"GroupCol"}, {
    {"Sum", each List.Sum([Amount]), type number},
    {"Count", each Table.RowCount(_), Int64.Type}
})

// Merge (JOIN)
Table.NestedJoin(left, {"KeyCol"}, right, {"KeyCol"}, "Merged", JoinKind.LeftOuter)

// Expand merged columns
Table.ExpandTableColumn(merged, "Merged", {"Col1", "Col2"})

// Pivot
Table.Pivot(table, List.Distinct(table[PivotCol]), "PivotCol", "ValueCol")

// Unpivot
Table.UnpivotOtherColumns(table, {"KeepCol1", "KeepCol2"}, "Attribute", "Value")

// Sort
Table.Sort(table, {{"Col1", Order.Ascending}, {"Col2", Order.Descending}})

// Remove duplicates
Table.Distinct(table, {"KeyCol1", "KeyCol2"})

// Combine/Append tables
Table.Combine({table1, table2, table3})

// Buffer (force materialization)
Table.Buffer(table)
```

### List Functions

```m
// Generate a sequence
{1..100}
List.Numbers(1, 100)
List.Dates(#date(2024,1,1), 365, #duration(1,0,0,0))

// Transform
List.Transform({1,2,3}, each _ * 2)

// Filter
List.Select({1,2,3,4,5}, each _ > 3)

// Aggregate
List.Sum(list), List.Average(list), List.Min(list), List.Max(list)

// Generate with custom logic (pagination pattern)
List.Generate(
    () => [Page = 0, Data = GetPage(0)],
    each [Data] <> null,
    each [Page = [Page] + 1, Data = GetPage([Page] + 1)],
    each [Data]
)
```

## Parameters and Dynamic Sources

Create parameters for environment-specific connections:

```m
// Define parameter in Power Query UI or M:
// Name: ServerName, Type: Text, Current Value: "prod-server.database.windows.net"

// Use in query:
let
    Source = Sql.Database(ServerName, DatabaseName),
    ...
```

**Dynamic source pattern:**
```m
let
    BaseUrl = "https://api.example.com/v2/",
    Endpoint = BaseUrl & "data?page=",
    GetPage = (pageNum as number) =>
        let
            url = Endpoint & Number.ToText(pageNum),
            response = Json.Document(Web.Contents(url))
        in
            response[results],
    AllPages = List.Generate(
        () => [i = 1, res = GetPage(1)],
        each List.Count([res]) > 0,
        each [i = [i] + 1, res = GetPage([i] + 1)],
        each [res]
    ),
    Combined = List.Combine(AllPages),
    AsTable = Table.FromList(Combined, Record.FieldValues,
        type table [id = Int64.Type, name = text, value = number])
in
    AsTable
```

## Error Handling

```m
// Try/otherwise pattern
let
    result = try SomeRiskyOperation() otherwise "default"
in
    result

// Try with error record inspection
let
    attempt = try Number.FromText("abc"),
    output = if attempt[HasError]
        then "Error: " & attempt[Error][Message]
        else attempt[Value]
in
    output

// Replace errors in a column
Table.ReplaceErrorValues(table, {{"Column1", null}, {"Column2", 0}})

// Remove error rows
Table.RemoveRowsWithErrors(table, {"Column1", "Column2"})
```

## Custom Connectors

Build custom Power Query connectors using the Power Query SDK:

1. Install Power Query SDK (VS Code extension)
2. Create a `.mproj` project with `DataConnector.pq` file
3. Implement the data source function with authentication
4. Package as `.mez` file
5. Deploy to `Documents\Power BI Desktop\Custom Connectors` or gateway

**Basic connector structure:**
```m
section MyConnector;

[DataSource.Kind="MyConnector", Publish="MyConnector.Publish"]
shared MyConnector.Contents = (url as text) =>
    let
        source = Web.Contents(url),
        json = Json.Document(source)
    in
        json;

MyConnector = [
    Authentication = [
        Key = [],
        OAuth = [...]
    ],
    Label = "My Custom Connector"
];

MyConnector.Publish = [
    Beta = true,
    Category = "Other",
    ButtonText = {"My Connector", "Connect to My Service"}
];
```

## Performance Optimization

| Technique | Impact |
|-----------|--------|
| Put foldable steps first | High -- pushes work to source |
| Remove unused columns early | High -- reduces data volume |
| Filter early, before joins | High -- reduces row count |
| Avoid Table.Buffer unless needed | Medium -- prevents unnecessary materialization |
| Use native queries when folding fails | High -- bypass mashup engine |
| Disable "Include in report refresh" for staging queries | Medium -- skips unnecessary refresh |
| Use Table.Partition for parallel loading | Medium -- parallelizes large tables |
| Set Privacy Levels correctly | Medium -- incorrect levels block folding |

## Additional Resources

### Reference Files
- **`references/m-patterns-cookbook.md`** -- Common M patterns: web API pagination, incremental load, JSON flattening, CSV handling, SharePoint folder combine
