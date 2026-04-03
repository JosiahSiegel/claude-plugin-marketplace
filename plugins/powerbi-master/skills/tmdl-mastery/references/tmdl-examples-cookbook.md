# TMDL Examples Cookbook

Complete, copy-pasteable TMDL examples for every object type. All examples follow correct indentation (single tab per level) and TMDL syntax conventions.

## Complete Model Definition

### database.tmdl

```tmdl
database AdventureWorks
    compatibilityLevel: 1601
```

### model.tmdl

```tmdl
model Model
    culture: en-US
    defaultPowerBIDataSourceVersion: powerBI_V3
    discourageImplicitMeasures
    sourceQueryCulture: en-US

ref table Calendar
ref table Product
ref table Customer
ref table Sales
ref table 'Sales Targets'

ref culture en-US
ref culture pt-PT

ref role 'Regional Manager'
ref role Administrator

ref perspective SalesView
```

### relationships.tmdl

```tmdl
/// Sales to Product (many-to-one)
relationship 550e8400-e29b-41d4-a716-446655440000
    fromColumn: Sales.'Product Key'
    toColumn: Product.'Product Key'

/// Sales to Customer (many-to-one)
relationship 6ba7b810-9dad-11d1-80b4-00c04fd430c8
    fromColumn: Sales.'Customer Key'
    toColumn: Customer.'Customer Key'

/// Sales to Calendar via OrderDate (active)
relationship 6ba7b811-9dad-11d1-80b4-00c04fd430c8
    fromColumn: Sales.'Order Date'
    toColumn: Calendar.Date
    isActive

/// Sales to Calendar via ShipDate (inactive)
relationship 6ba7b812-9dad-11d1-80b4-00c04fd430c8
    fromColumn: Sales.'Ship Date'
    toColumn: Calendar.Date
    isActive: false

/// Bidirectional relationship
relationship 6ba7b813-9dad-11d1-80b4-00c04fd430c8
    fromColumn: Sales.'Store Key'
    toColumn: Store.'Store Key'
    crossFilteringBehavior: bothDirections
    securityFilteringBehavior: bothDirections

/// Many-to-many relationship
relationship 6ba7b814-9dad-11d1-80b4-00c04fd430c8
    fromColumn: 'Bridge Table'.'Tag ID'
    toColumn: Tags.'Tag ID'
    fromCardinality: many
    toCardinality: many
    crossFilteringBehavior: bothDirections

/// DirectQuery with referential integrity
relationship 6ba7b815-9dad-11d1-80b4-00c04fd430c8
    fromColumn: FactSales.ProductKey
    toColumn: DimProduct.ProductKey
    relyOnReferentialIntegrity
```

### expressions.tmdl

```tmdl
expression Server = "sql-server.database.windows.net" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]

expression Database = "AdventureWorksDW" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]

expression 'Shared Date Query' =
        let
            Source = Sql.Database(Server, Database),
            DimDate = Source{[Schema="dbo",Item="DimDate"]}[Data]
        in
            DimDate
    queryGroup: 'Shared Queries'
```

### functions.tmdl (DAX UDFs)

```tmdl
function AddTax = (amount : NUMERIC) => amount * 1.1

function CalcMargin = (revenue : NUMERIC, cost : NUMERIC) =>
        DIVIDE(revenue - cost, revenue)
```

## Table with Columns, Measures, and Partitions

### tables/Sales.tmdl

```tmdl
/// Core sales transaction table
/// Contains all order-level data with incremental refresh
table Sales
    lineageTag: a1b2c3d4-e5f6-7890-abcd-ef1234567890

    /// --- Partitions ---

    partition 'Sales-Current' = m
        mode: import
        source =
            let
                Source = Sql.Database(Server, Database),
                Sales = Source{[Schema="dbo",Item="FactSales"]}[Data],
                Filtered = Table.SelectRows(Sales, each [OrderDate] >= RangeStart and [OrderDate] < RangeEnd)
            in
                Filtered

    /// --- Key Columns ---

    column 'Sales Key'
        dataType: int64
        isKey
        isHidden
        sourceColumn: SalesKey
        summarizeBy: none
        lineageTag: 11111111-aaaa-bbbb-cccc-dddddddddddd

    column 'Product Key'
        dataType: int64
        isHidden
        sourceColumn: ProductKey
        summarizeBy: none

    column 'Customer Key'
        dataType: int64
        isHidden
        sourceColumn: CustomerKey
        summarizeBy: none

    /// --- Date Columns ---

    column 'Order Date'
        dataType: dateTime
        formatString: yyyy-MM-dd
        sourceColumn: OrderDate
        summarizeBy: none

    column 'Ship Date'
        dataType: dateTime
        formatString: yyyy-MM-dd
        sourceColumn: ShipDate
        summarizeBy: none
        isHidden

    /// --- Fact Columns ---

    column Quantity
        dataType: int64
        sourceColumn: Quantity
        summarizeBy: sum

    column Amount
        dataType: decimal
        formatString: $ #,##0.00
        sourceColumn: Amount
        summarizeBy: sum

    column 'Unit Price'
        dataType: decimal
        formatString: $ #,##0.00
        sourceColumn: UnitPrice
        summarizeBy: none
        isHidden

    column 'Unit Cost'
        dataType: decimal
        formatString: $ #,##0.00
        sourceColumn: UnitCost
        summarizeBy: none
        isHidden

    /// --- Calculated Column ---

    column 'Profit Margin %' = DIVIDE(Sales[Amount] - Sales[Quantity] * Sales[Unit Cost], Sales[Amount])
        dataType: double
        formatString: 0.00%
        summarizeBy: none
        displayFolder: Calculated
        isDataTypeInferred

    /// --- Measures ---

    /// Total revenue across all product lines
    measure 'Sales Amount' = SUM(Sales[Amount])
        formatString: $ #,##0.00
        displayFolder: Revenue
        lineageTag: 22222222-aaaa-bbbb-cccc-dddddddddddd

    /// Total units sold
    measure 'Total Quantity' = SUM(Sales[Quantity])
        formatString: #,##0
        displayFolder: Volume

    /// Year-over-year sales growth
    measure 'YoY Growth %' =
            VAR CurrentSales = [Sales Amount]
            VAR PYSales = CALCULATE([Sales Amount], SAMEPERIODLASTYEAR('Calendar'[Date]))
            RETURN DIVIDE(CurrentSales - PYSales, PYSales)
        formatString: 0.00%
        displayFolder: Growth

    /// Rolling 12-month total
    measure 'Rolling 12M Sales' =
            CALCULATE(
                [Sales Amount],
                DATESINPERIOD('Calendar'[Date], MAX('Calendar'[Date]), -12, MONTH)
            )
        formatString: $ #,##0.00
        displayFolder: Revenue

    /// Year-to-date sales
    measure 'Sales YTD' =
            TOTALYTD([Sales Amount], 'Calendar'[Date])
        formatString: $ #,##0.00
        displayFolder: Revenue

    /// Count of distinct customers
    measure '# Customers' = DISTINCTCOUNT(Sales[Customer Key])
        formatString: #,##0
        displayFolder: Counts

    /// Average order value
    measure 'Avg Order Value' =
            AVERAGEX(
                VALUES(Sales[Sales Key]),
                [Sales Amount]
            )
        formatString: $ #,##0.00
        displayFolder: Revenue

    /// Dynamic format string measure
    measure 'Sales Formatted' = [Sales Amount]

        formatStringDefinition =
                IF(
                    [Sales Amount] >= 1000000,
                    "$ #,##0,,.0 M",
                    IF([Sales Amount] >= 1000, "$ #,##0,.0 K", "$ #,##0.00")
                )
        displayFolder: Revenue

    /// Detail rows definition for drill-through
    measure 'Sales with Detail' = [Sales Amount]

        detailRowsDefinition =
                SELECTCOLUMNS(
                    Sales,
                    "Order Date", Sales[Order Date],
                    "Product", RELATED(Product[Product Name]),
                    "Amount", Sales[Amount],
                    "Quantity", Sales[Quantity]
                )

    /// --- Annotations ---

    annotation PBI_ResultType = Table

    annotation PBI_NavigationStepName = Navigation

    annotation CustomRefreshInfo = ```
        {
            "refreshType": "incremental",
            "retentionPeriodYears": 3,
            "incrementalPeriodMonths": 1
        }
        ```
```

## Calendar Table (Calculated)

### tables/Calendar.tmdl

```tmdl
/// Standard date dimension table
table Calendar
    dataCategory: Time
    lineageTag: 33333333-aaaa-bbbb-cccc-dddddddddddd

    partition 'Calendar-Partition' = calculated
        source =
            CALENDAR(DATE(2020, 1, 1), DATE(2030, 12, 31))

    column Date
        dataType: dateTime
        isKey
        formatString: yyyy-MM-dd
        summarizeBy: none
        sourceColumn: [Date]

    column Year = YEAR('Calendar'[Date])
        dataType: int64
        formatString: 0
        summarizeBy: none

    column 'Month Number' = MONTH('Calendar'[Date])
        dataType: int64
        formatString: 0
        summarizeBy: none
        isHidden

    column 'Month Name' = FORMAT('Calendar'[Date], "MMMM")
        dataType: string
        sortByColumn: 'Month Number'
        summarizeBy: none

    column Quarter = "Q" & FORMAT('Calendar'[Date], "Q")
        dataType: string
        summarizeBy: none

    column 'Year-Month' = FORMAT('Calendar'[Date], "YYYY-MM")
        dataType: string
        summarizeBy: none
        sortByColumn: Date

    column 'Day of Week' = FORMAT('Calendar'[Date], "dddd")
        dataType: string
        summarizeBy: none

    column 'Is Weekend' = IF(WEEKDAY('Calendar'[Date], 2) > 5, TRUE(), FALSE())
        dataType: boolean
        summarizeBy: none

    hierarchy 'Date Hierarchy'

        level Year
            column: Year

        level Quarter
            column: Quarter

        level 'Month Name'
            column: 'Month Name'

        level Date
            column: Date
```

## Product Table with Display Folders

### tables/Product.tmdl

```tmdl
table Product
    lineageTag: 44444444-aaaa-bbbb-cccc-dddddddddddd

    partition 'Product-Partition' = m
        mode: import
        source =
            let
                Source = Sql.Database(Server, Database),
                Product = Source{[Schema="dbo",Item="DimProduct"]}[Data]
            in
                Product

    column 'Product Key'
        dataType: int64
        isKey
        isHidden
        sourceColumn: ProductKey
        summarizeBy: none

    column 'Product Name'
        dataType: string
        isDefaultLabel
        sourceColumn: ProductName
        summarizeBy: none
        displayFolder: Description

    column Category
        dataType: string
        sourceColumn: Category
        summarizeBy: none
        displayFolder: Classification

    column Subcategory
        dataType: string
        sourceColumn: Subcategory
        summarizeBy: none
        displayFolder: Classification

    column Brand
        dataType: string
        sourceColumn: Brand
        summarizeBy: none
        displayFolder: Classification

    column Color
        dataType: string
        sourceColumn: Color
        summarizeBy: none
        displayFolder: Attributes

    column 'Unit Price'
        dataType: decimal
        formatString: $ #,##0.00
        sourceColumn: UnitPrice
        summarizeBy: none
        displayFolder: Pricing

    column 'Unit Cost'
        dataType: decimal
        formatString: $ #,##0.00
        sourceColumn: UnitCost
        summarizeBy: none
        displayFolder: Pricing

    column 'Product Image URL'
        dataType: string
        sourceColumn: ImageURL
        dataCategory: ImageUrl
        isHidden

    measure '# Products' = COUNTROWS(Product)
        formatString: #,##0

    measure 'Avg Unit Price' = AVERAGE(Product[Unit Price])
        formatString: $ #,##0.00

    hierarchy 'Product Hierarchy'
        displayFolder: Hierarchies

        level Category
            column: Category

        level Subcategory
            column: Subcategory

        level 'Product Name'
            column: 'Product Name'
```

## Calculation Groups

### Time Intelligence Calculation Group

```tmdl
createOrReplace

table 'Time Intelligence'
    calculationGroup
        precedence: 1

    calculationItem Current = SELECTEDMEASURE()
        ordinal: 0

    calculationItem YTD =
            CALCULATE(SELECTEDMEASURE(), DATESYTD('Calendar'[Date]))
        ordinal: 1

    calculationItem QTD =
            CALCULATE(SELECTEDMEASURE(), DATESQTD('Calendar'[Date]))
        ordinal: 2

    calculationItem MTD =
            CALCULATE(SELECTEDMEASURE(), DATESMTD('Calendar'[Date]))
        ordinal: 3

    calculationItem PY =
            CALCULATE(SELECTEDMEASURE(), SAMEPERIODLASTYEAR('Calendar'[Date]))
        ordinal: 4

    calculationItem 'YoY %' =
            VAR CurrentValue = SELECTEDMEASURE()
            VAR PriorYear = CALCULATE(SELECTEDMEASURE(), SAMEPERIODLASTYEAR('Calendar'[Date]))
            RETURN DIVIDE(CurrentValue - PriorYear, PriorYear)
        formatStringDefinition = "0.00%"
        ordinal: 5

    calculationItem 'YoY Abs' =
            VAR CurrentValue = SELECTEDMEASURE()
            VAR PriorYear = CALCULATE(SELECTEDMEASURE(), SAMEPERIODLASTYEAR('Calendar'[Date]))
            RETURN CurrentValue - PriorYear
        ordinal: 6

    column 'Time Calculation'
        dataType: string
        sourceColumn: Name
        sortByColumn: Ordinal

    column Ordinal
        dataType: int64
        sourceColumn: Ordinal
        summarizeBy: none
        isHidden
```

### Currency Conversion Calculation Group

```tmdl
createOrReplace

table 'Currency Conversion'
    calculationGroup
        precedence: 2

    calculationItem 'Local Currency' = SELECTEDMEASURE()
        ordinal: 0

    calculationItem USD =
            SELECTEDMEASURE() * SELECTEDVALUE('Exchange Rates'[USD Rate], 1)
        formatStringDefinition = "$ #,##0.00"
        ordinal: 1

    calculationItem EUR =
            SELECTEDMEASURE() * SELECTEDVALUE('Exchange Rates'[EUR Rate], 1)
        formatStringDefinition = "#,##0.00 EUR"
        ordinal: 2

    column 'Currency Display'
        dataType: string
        sourceColumn: Name

    column Ordinal
        dataType: int64
        sourceColumn: Ordinal
        summarizeBy: none
        isHidden
```

## Field Parameters

```tmdl
table 'Revenue Metric'

    column 'Revenue Metric'
        dataType: string
        isHidden
        sourceColumn: Name
        sortByColumn: 'Revenue Metric Order'

    column 'Revenue Metric Fields'
        dataType: string
        isHidden
        sourceColumn: Name
        isDataTypeInferred

    column 'Revenue Metric Order'
        dataType: int64
        isHidden
        sourceColumn: Ordinal
        summarizeBy: none

    partition 'Revenue Metric-Partition' = calculated
        source = ```
            {
                ("Revenue", NAMEOF([Sales Amount]), 0),
                ("Profit", NAMEOF([Gross Profit]), 1),
                ("Margin %", NAMEOF([Gross Margin %]), 2),
                ("Units", NAMEOF([Total Quantity]), 3)
            }
            ```

    annotation ParameterMetadata = ```
        {"version":3,"kind":2}
        ```
```

## Roles with RLS

### roles/RegionalManager.tmdl

```tmdl
/// Regional manager can only see their own region's data
role 'Regional Manager'
    modelPermission: read
    description: Row-level security for regional managers

    tablePermission Sales = Sales[Region] = USERPRINCIPALNAME()

    tablePermission 'Sales Targets' = 'Sales Targets'[Region] = USERPRINCIPALNAME()

    member 'alice@contoso.com'
    member 'bob@contoso.com'
    member 'regional-managers@contoso.com' = group
```

### roles/Administrator.tmdl

```tmdl
role Administrator
    modelPermission: readRefresh
    description: Full read and refresh access

    member 'admin-team@contoso.com' = group
    member 'service-principal-id' = auto
```

### Role with OLS (Object-Level Security)

```tmdl
role 'Limited Access'
    modelPermission: read

    tablePermission Sales = TRUE()

    columnPermission Sales.'Unit Cost' = none
    columnPermission Sales.'Profit Margin %' = none
```

## Perspectives

### perspectives/SalesView.tmdl

```tmdl
perspective SalesView

    perspectiveTable Sales
        perspectiveMeasure 'Sales Amount'
        perspectiveMeasure 'Total Quantity'
        perspectiveMeasure 'YoY Growth %'
        perspectiveColumn Amount
        perspectiveColumn Quantity
        perspectiveColumn 'Order Date'

    perspectiveTable Product
        perspectiveMeasure '# Products'
        perspectiveColumn 'Product Name'
        perspectiveColumn Category
        perspectiveColumn Subcategory
        perspectiveHierarchy 'Product Hierarchy'

    perspectiveTable Calendar
        perspectiveColumn Date
        perspectiveColumn Year
        perspectiveColumn 'Month Name'
        perspectiveColumn Quarter
        perspectiveHierarchy 'Date Hierarchy'

    perspectiveTable Customer
        perspectiveColumn 'Customer Name'
        perspectiveColumn Region
```

## Cultures / Translations

### cultures/en-US.tmdl

```tmdl
culture en-US

    linguisticMetadata =
        {
            "Version": "1.0.0",
            "Language": "en-US"
        }
```

### cultures/pt-PT.tmdl

```tmdl
culture pt-PT
    translations
        model Model
            caption: Modelo
            description: Modelo de dados de vendas
        table Sales
            caption: Vendas
            measure 'Sales Amount'
                caption: Total de Vendas
                displayFolder: Receita
            measure 'Total Quantity'
                caption: Quantidade Total
                displayFolder: Volume
            column Amount
                caption: Valor
            column 'Order Date'
                caption: Data do Pedido
        table Product
            caption: Produto
            column 'Product Name'
                caption: Nome do Produto
            column Category
                caption: Categoria
            hierarchy 'Product Hierarchy'
                caption: Hierarquia de Produto
        table Calendar
            caption: Calendario
            column Date
                caption: Data
            column Year
                caption: Ano
            column 'Month Name'
                caption: Nome do Mes
        table Customer
            caption: Cliente
            column 'Customer Name'
                caption: Nome do Cliente

    linguisticMetadata =
        {
            "Version": "1.0.0",
            "Language": "pt-PT"
        }
```

## KPI Measure

```tmdl
measure Revenue = SUM(Sales[Amount])
    formatString: $ #,##0.00

    kpi
        targetExpression = 1500000
        statusExpression =
            VAR x = DIVIDE([Revenue], [Revenue KPI Target])
            RETURN
                IF(x < 0.5, -1, IF(x < 0.85, 0, 1))
        trendExpression =
            VAR CurrentVal = [Revenue]
            VAR PriorVal = CALCULATE([Revenue], DATEADD('Calendar'[Date], -1, MONTH))
            RETURN
                IF(CurrentVal < PriorVal, -1, IF(CurrentVal = PriorVal, 0, 1))
        statusGraphic: "Three Symbols UnCircled Colored"
        trendGraphic: "Three Symbols UnCircled Colored"
```

## DirectQuery Table

```tmdl
table 'Live Sales'
    lineageTag: 55555555-aaaa-bbbb-cccc-dddddddddddd

    partition 'Live-Sales-DQ' = m
        mode: directQuery
        source =
            let
                Source = Sql.Database("live-server.database.windows.net", "SalesDB"),
                Sales = Source{[Schema="dbo",Item="vw_LiveSales"]}[Data]
            in
                Sales

    column OrderID
        dataType: int64
        sourceColumn: OrderID
        summarizeBy: none

    column Amount
        dataType: decimal
        formatString: $ #,##0.00
        sourceColumn: Amount
        summarizeBy: sum
```

## Dual Mode Table (Composite Model)

```tmdl
table 'Product Lookup'

    partition 'Product-Dual' = m
        mode: dual
        source =
            let
                Source = Sql.Database(Server, Database),
                Result = Source{[Schema="dbo",Item="DimProduct"]}[Data]
            in
                Result

    column ProductKey
        dataType: int64
        isKey
        sourceColumn: ProductKey
        summarizeBy: none
```

## Incremental Refresh Configuration

```tmdl
table Sales

    partition 'Sales-Incremental' = m
        mode: import
        source =
            let
                Source = Sql.Database(Server, Database),
                Filtered = Table.SelectRows(
                    Source{[Schema="dbo",Item="FactSales"]}[Data],
                    each [OrderDate] >= RangeStart and [OrderDate] < RangeEnd
                )
            in
                Filtered

        refreshPolicy
            incrementalGranularity: day
            incrementalPeriods: 30
            rollingWindowGranularity: month
            rollingWindowPeriods: 36
            pollingExpression =
                let
                    Source = Sql.Database(Server, Database),
                    MaxDate = List.Max(Source{[Schema="dbo",Item="FactSales"]}[Data][OrderDate])
                in
                    MaxDate
            sourceExpression =
                let
                    Source = Sql.Database(Server, Database),
                    Filtered = Table.SelectRows(
                        Source{[Schema="dbo",Item="FactSales"]}[Data],
                        each [OrderDate] >= RangeStart and [OrderDate] < RangeEnd
                    )
                in
                    Filtered
```

## createOrReplace Script Examples

### Add Measures to Existing Table

```tmdl
createOrReplace

    ref table Sales
        measure 'New KPI' =
                VAR Target = 1000000
                VAR Actual = [Sales Amount]
                RETURN DIVIDE(Actual, Target)
            formatString: 0.0%
            displayFolder: KPIs

        measure 'Filtered Sales' =
                CALCULATE([Sales Amount], Product[Category] = "Electronics")
            formatString: $ #,##0.00
            displayFolder: Revenue
```

### Replace Full Table Definition

```tmdl
createOrReplace

    table 'Exchange Rates'

        partition 'Exchange-Rates-Part' = m
            mode: import
            source =
                let
                    Source = Web.Contents("https://api.exchangerates.io/latest"),
                    Data = Json.Document(Source)
                in
                    Record.ToTable(Data[rates])

        column Name
            dataType: string
            sourceColumn: Name
            summarizeBy: none

        column Value
            dataType: double
            sourceColumn: Value
            summarizeBy: none
```

### Create Perspective via Script

```tmdl
createOrReplace

    perspective 'Executive Summary'

        perspectiveTable Sales
            perspectiveMeasure 'Sales Amount'
            perspectiveMeasure 'YoY Growth %'
            perspectiveMeasure 'Sales YTD'

        perspectiveTable Calendar
            perspectiveColumn Year
            perspectiveColumn Quarter
            perspectiveHierarchy 'Date Hierarchy'
```

### Switch Storage Mode via Script

```tmdl
createOrReplace

    table Product

        partition 'Product-Partition' = m
            mode: directQuery
            source =
                let
                    Source = Sql.Database(Server, Database),
                    Product = Source{[Schema="dbo",Item="DimProduct"]}[Data]
                in
                    Product

        column 'Product Key'
            dataType: int64
            isKey
            sourceColumn: ProductKey
            summarizeBy: none

        column 'Product Name'
            dataType: string
            sourceColumn: ProductName
            summarizeBy: none
```
