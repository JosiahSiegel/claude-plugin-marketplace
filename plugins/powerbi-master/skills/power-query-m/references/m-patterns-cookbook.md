# M Language Patterns Cookbook

## 1. REST API Pagination

### Offset-Based Pagination
```m
let
    BaseUrl = "https://api.example.com/data",
    PageSize = 100,
    GetPage = (offset as number) =>
        let
            url = BaseUrl & "?limit=" & Number.ToText(PageSize)
                & "&offset=" & Number.ToText(offset),
            response = Json.Document(Web.Contents(url)),
            data = response[results]
        in
            data,
    AllPages = List.Generate(
        () => [i = 0, res = GetPage(0)],
        each List.Count([res]) > 0,
        each [i = [i] + PageSize, res = GetPage([i] + PageSize)],
        each [res]
    ),
    Combined = List.Combine(AllPages),
    AsTable = Table.FromRecords(Combined)
in
    AsTable
```

### Cursor/Token-Based Pagination
```m
let
    BaseUrl = "https://api.example.com/data",
    GetPage = (cursor as nullable text) =>
        let
            queryParams = if cursor = null then "" else "?cursor=" & cursor,
            url = BaseUrl & queryParams,
            response = Json.Document(Web.Contents(url)),
            data = response[items],
            nextCursor = try response[next_cursor] otherwise null
        in
            [Data = data, NextCursor = nextCursor],
    AllPages = List.Generate(
        () => GetPage(null),
        each [Data] <> null and List.Count([Data]) > 0,
        each GetPage([NextCursor]),
        each [Data]
    ),
    Combined = List.Combine(AllPages),
    AsTable = Table.FromRecords(Combined)
in
    AsTable
```

### OData NextLink Pagination
```m
let
    GetPage = (url as text) as table =>
        let
            source = Json.Document(Web.Contents(url)),
            data = Table.FromRecords(source[value]),
            nextLink = try source[#"@odata.nextLink"] otherwise null,
            result = if nextLink <> null
                then Table.Combine({data, @GetPage(nextLink)})
                else data
        in
            result,
    Output = GetPage("https://graph.microsoft.com/v1.0/users?$top=999")
in
    Output
```

## 2. JSON Flattening Patterns

### Nested JSON Records
```m
let
    Source = Json.Document(Web.Contents("https://api.example.com/orders")),
    AsTable = Table.FromRecords(Source),
    // Expand nested record column
    ExpandAddress = Table.ExpandRecordColumn(AsTable, "address",
        {"street", "city", "state", "zip"}),
    // Expand nested list of records
    ExpandItems = Table.ExpandListColumn(ExpandAddress, "items"),
    ExpandItemDetails = Table.ExpandRecordColumn(ExpandItems, "items",
        {"product", "quantity", "price"})
in
    ExpandItemDetails
```

### Dynamic Column Expansion (Unknown Schema)
```m
let
    Source = Json.Document(Web.Contents(url)),
    AsTable = Table.FromRecords(Source),
    // Get all column names from the nested record
    SampleRecord = AsTable{0}[nestedColumn],
    ColumnNames = Record.FieldNames(SampleRecord),
    Expanded = Table.ExpandRecordColumn(AsTable, "nestedColumn", ColumnNames)
in
    Expanded
```

### Deeply Nested JSON
```m
let
    Source = Json.Document(Web.Contents(url)),
    // Navigate to the data: response.data.results[*]
    Data = Source[data][results],
    AsTable = Table.FromRecords(Data),
    // Flatten level by level
    Level1 = Table.ExpandRecordColumn(AsTable, "details",
        Record.FieldNames(AsTable{0}[details])),
    Level2 = Table.ExpandListColumn(Level1, "tags"),
    Level3 = Table.ExpandRecordColumn(Level2, "metadata",
        Record.FieldNames(Level1{0}[metadata]))
in
    Level3
```

## 3. SharePoint Folder Combine Pattern

```m
let
    Source = SharePoint.Files("https://tenant.sharepoint.com/sites/Team", [ApiVersion = 15]),
    // Filter to specific folder and file type
    Filtered = Table.SelectRows(Source, each
        Text.Contains([Folder Path], "Shared Documents/Data/")
        and [Extension] = ".xlsx"),
    // Add custom function to load each file
    AddContent = Table.AddColumn(Filtered, "Data", each
        let
            workbook = Excel.Workbook([Content], true),
            sheet = workbook{[Name="Sheet1"]}[Data]
        in
            sheet),
    // Remove file metadata, keep data
    RemoveCols = Table.SelectColumns(AddContent, {"Name", "Data"}),
    // Expand all tables
    Expanded = Table.ExpandTableColumn(RemoveCols, "Data",
        Table.ColumnNames(RemoveCols{0}[Data]))
in
    Expanded
```

## 4. Incremental Load Pattern (File-Based)

```m
let
    // Parameters: LastRefreshDate (type date)
    Source = Folder.Files("\\server\share\data"),
    // Only load files modified since last refresh
    Filtered = Table.SelectRows(Source, each [Date modified] > LastRefreshDate),
    // Load each CSV
    LoadCSV = Table.AddColumn(Filtered, "Data", each
        Csv.Document([Content], [Delimiter=",", Encoding=65001, QuoteStyle=QuoteStyle.Csv])),
    Combined = Table.ExpandTableColumn(
        Table.SelectColumns(LoadCSV, {"Data"}),
        "Data",
        Table.ColumnNames(LoadCSV{0}[Data])
    ),
    Typed = Table.TransformColumnTypes(Combined, {
        {"Date", type date}, {"Amount", type number}
    })
in
    Typed
```

## 5. Handling Multiple CSV Formats

When CSV files in a folder have different schemas:

```m
let
    Source = Folder.Files("C:\Data\CSVFiles"),
    FilterCSV = Table.SelectRows(Source, each [Extension] = ".csv"),
    LoadWithSchema = Table.AddColumn(FilterCSV, "Data", each
        let
            csv = Csv.Document([Content], [Delimiter=",", Encoding=65001]),
            promoted = Table.PromoteHeaders(csv, [PromoteAllScalars=true]),
            // Standardize column names across different formats
            standardized =
                if Table.HasColumns(promoted, "Revenue") then promoted
                else if Table.HasColumns(promoted, "Sales Amount") then
                    Table.RenameColumns(promoted, {{"Sales Amount", "Revenue"}})
                else promoted
        in
            standardized),
    Combined = Table.Combine(LoadWithSchema[Data])
in
    Combined
```

## 6. Web Scraping with HTML Parsing

```m
let
    Source = Web.Page(Web.Contents("https://example.com/table-page")),
    // Web.Page returns a table of HTML tables found on the page
    DataTable = Source{0}[Data],  // First table on the page
    Promoted = Table.PromoteHeaders(DataTable, [PromoteAllScalars=true]),
    Cleaned = Table.TransformColumnTypes(Promoted, {
        {"Column1", type text}, {"Column2", type number}
    })
in
    Cleaned
```

## 7. Relative Date Filtering

```m
let
    Source = ...,
    // Last N days
    LastNDays = Table.SelectRows(Source, each
        [Date] >= Date.AddDays(DateTime.Date(DateTime.LocalNow()), -30)),

    // Current month
    CurrentMonth = Table.SelectRows(Source, each
        Date.Year([Date]) = Date.Year(DateTime.Date(DateTime.LocalNow()))
        and Date.Month([Date]) = Date.Month(DateTime.Date(DateTime.LocalNow()))),

    // Rolling 12 months
    Rolling12M = Table.SelectRows(Source, each
        [Date] >= Date.AddMonths(DateTime.Date(DateTime.LocalNow()), -12))
in
    Rolling12M
```

## 8. Custom Function Definition and Invocation

```m
// Define a reusable function
let
    CleanText = (input as text) as text =>
        let
            trimmed = Text.Trim(input),
            lower = Text.Lower(trimmed),
            replaced = Text.Replace(lower, "  ", " ")
        in
            replaced,

    Source = ...,
    Applied = Table.TransformColumns(Source, {{"Name", CleanText}})
in
    Applied
```

## 9. Conditional Column with Complex Logic

```m
let
    Source = ...,
    AddCategory = Table.AddColumn(Source, "Category", each
        if [Amount] > 10000 and [Region] = "US" then "High Value US"
        else if [Amount] > 10000 then "High Value International"
        else if [Amount] > 1000 then "Medium Value"
        else if [Amount] > 0 then "Low Value"
        else if [Amount] = 0 then "Zero"
        else "Credit/Return",
        type text)
in
    AddCategory
```

## 10. Cross-Join / Calendar Generation

```m
let
    StartDate = #date(2020, 1, 1),
    EndDate = #date(2026, 12, 31),
    DayCount = Duration.Days(EndDate - StartDate) + 1,
    DateList = List.Dates(StartDate, DayCount, #duration(1, 0, 0, 0)),
    DateTable = Table.FromList(DateList, Splitter.SplitByNothing(), {"Date"}, null, ExtraValues.Error),
    Typed = Table.TransformColumnTypes(DateTable, {{"Date", type date}}),
    AddYear = Table.AddColumn(Typed, "Year", each Date.Year([Date]), Int64.Type),
    AddMonth = Table.AddColumn(AddYear, "Month", each Date.Month([Date]), Int64.Type),
    AddMonthName = Table.AddColumn(AddMonth, "MonthName", each Date.MonthName([Date]), type text),
    AddQuarter = Table.AddColumn(AddMonthName, "Quarter", each "Q" & Number.ToText(Date.QuarterOfYear([Date])), type text),
    AddWeekday = Table.AddColumn(AddQuarter, "Weekday", each Date.DayOfWeekName([Date]), type text),
    AddYearMonth = Table.AddColumn(AddWeekday, "YearMonth", each Date.ToText([Date], "yyyy-MM"), type text),
    AddFiscalYear = Table.AddColumn(AddYearMonth, "FiscalYear", each
        if Date.Month([Date]) >= 7 then Date.Year([Date]) + 1 else Date.Year([Date]), Int64.Type),
    AddIsWeekend = Table.AddColumn(AddFiscalYear, "IsWeekend", each
        Date.DayOfWeek([Date], Day.Monday) >= 5, type logical)
in
    AddIsWeekend
```

## 11. Handling Authentication Headers

```m
let
    // API Key in header
    Source = Json.Document(Web.Contents("https://api.example.com/data", [
        Headers = [
            #"Authorization" = "Bearer " & ApiKey,
            #"Content-Type" = "application/json",
            #"X-Custom-Header" = "value"
        ],
        ManualStatusHandling = {400, 401, 404, 500}
    ])),
    // Check for errors
    StatusCode = Value.Metadata(Source)[Response.Status],
    Result = if StatusCode = 200 then Source else error "API returned " & Number.ToText(StatusCode)
in
    Result
```

## 12. Privacy Levels and Query Folding

Privacy levels can block query folding between sources:

| Level | Description | Impact |
|-------|-------------|--------|
| Private | Isolated, never shared | Blocks folding with other sources |
| Organizational | Shared within org | Folds with other Organizational sources |
| Public | No restrictions | Folds freely |
| None | Inherits from parent | Depends on parent setting |

**Fix folding issues:** Set appropriate privacy levels in Data Source Settings, or set "Ignore Privacy Levels" (development only, not recommended for production) in Options > Privacy.
