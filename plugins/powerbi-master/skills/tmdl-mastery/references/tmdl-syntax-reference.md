# TMDL Complete Syntax and Grammar Reference

## Object Type Hierarchy

TMDL exposes the entire TOM Database object tree (except Server). Every TMDL object maps 1:1 to a TOM class in `Microsoft.AnalysisServices.Tabular`.

### Top-Level Objects (No Indentation Required)

| TMDL Keyword | TOM Class | File Location |
|-------------|-----------|---------------|
| `database` | Database | database.tmdl |
| `model` | Model | model.tmdl |
| `table` | Table | tables/{name}.tmdl |
| `relationship` | SingleColumnRelationship | relationships.tmdl |
| `role` | ModelRole | roles/{name}.tmdl |
| `culture` | Culture | cultures/{name}.tmdl |
| `perspective` | Perspective | perspectives/{name}.tmdl |
| `expression` | NamedExpression | expressions.tmdl |
| `function` | ModelFunction (DAX UDF) | functions.tmdl |
| `dataSource` | DataSource | dataSources.tmdl |

### Table Child Objects (Indented Under Table)

| TMDL Keyword | TOM Class | Default Property |
|-------------|-----------|-----------------|
| `column` | DataColumn | (none) |
| `column` (with `=`) | CalculatedColumn | Expression (DAX) |
| `measure` | Measure | Expression (DAX) |
| `partition` | Partition | SourceType |
| `hierarchy` | Hierarchy | (none) |
| `calculationGroup` | CalculationGroup | (none) |
| `calculationItem` | CalculationItem | Expression (DAX) |
| `annotation` | Annotation | Value (Text) |

### Role Child Objects

| TMDL Keyword | TOM Class | Default Property |
|-------------|-----------|-----------------|
| `tablePermission` | TablePermission | FilterExpression (DAX) |
| `columnPermission` | ColumnPermission | MetadataPermission (Enum) |
| `member` | ExternalModelRoleMember / WindowsModelRoleMember | MemberType |

### Perspective Child Objects

| TMDL Keyword | TOM Class |
|-------------|-----------|
| `perspectiveTable` | PerspectiveTable |
| `perspectiveMeasure` | PerspectiveMeasure |
| `perspectiveColumn` | PerspectiveColumn |
| `perspectiveHierarchy` | PerspectiveHierarchy |

### Culture Child Objects

| TMDL Keyword | Purpose |
|-------------|---------|
| `translations` | Container for all object translations |
| `linguisticMetadata` | JSON linguistic schema content |

## Complete Property Reference by Object Type

### Database Properties

```tmdl
database AdventureWorks
    compatibilityLevel: 1601
    id: AdventureWorks-GUID
```

| Property | Type | Description |
|----------|------|-------------|
| `compatibilityLevel` | integer | TOM compatibility level (1200-1601+) |
| `id` | string | Database unique identifier |

### Model Properties

```tmdl
model Model
    culture: en-US
    defaultPowerBIDataSourceVersion: powerBI_V3
    discourageImplicitMeasures
    sourceQueryCulture: en-US
```

| Property | Type | Description |
|----------|------|-------------|
| `culture` | string | Default culture locale (e.g., en-US) |
| `defaultPowerBIDataSourceVersion` | enum | Power BI data source version |
| `discourageImplicitMeasures` | boolean | Suppress implicit measures in clients |
| `sourceQueryCulture` | string | Culture for source query formatting |
| `defaultMeasure` | reference | Default measure for the model |

### Table Properties

```tmdl
table Sales
    lineageTag: a1b2c3d4-...
    isHidden
    isPrivate
    excludeFromModelRefresh
    dataCategory: Time
    description: Sales transactions table
```

| Property | Type | Description |
|----------|------|-------------|
| `lineageTag` | GUID | Unique identifier for lineage tracking |
| `isHidden` | boolean | Hide table from client tools |
| `isPrivate` | boolean | Mark as private (internal use) |
| `excludeFromModelRefresh` | boolean | Skip during model refresh |
| `dataCategory` | string | Semantic category (Time, Geography, etc.) |

### Column Properties (DataColumn)

```tmdl
column Amount
    dataType: decimal
    formatString: $ #,##0.00
    sourceColumn: Amount
    summarizeBy: sum
    isHidden
    isKey
    isNullable
    isDefaultLabel
    isDefaultImage
    isAvailableInMdx: false
    isUnique
    sortByColumn: 'Amount Sort'
    displayFolder: Financial
    lineageTag: e5f6g7h8-...
    dataCategory: Uncategorized
```

| Property | Type | Description |
|----------|------|-------------|
| `dataType` | enum | `string`, `int64`, `double`, `decimal`, `dateTime`, `boolean`, `binary`, `unknown`, `variant` |
| `formatString` | string | Display format (e.g., `$ #,##0.00`, `0.00%`, `yyyy-MM-dd`) |
| `sourceColumn` | string | Source column name in partition query |
| `summarizeBy` | enum | `sum`, `count`, `min`, `max`, `average`, `distinctCount`, `none` |
| `isHidden` | boolean | Hide from client tools |
| `isKey` | boolean | Mark as table key column |
| `isNullable` | boolean | Allow null values |
| `isDefaultLabel` | boolean | Default label column for table |
| `isDefaultImage` | boolean | Default image column for table |
| `isAvailableInMdx` | boolean | Expose to MDX clients |
| `isUnique` | boolean | Column values are unique |
| `sortByColumn` | reference | Column to sort by |
| `displayFolder` | string | Folder path for client tools |
| `lineageTag` | GUID | Lineage tracking identifier |
| `dataCategory` | string | Semantic annotation (WebUrl, ImageUrl, etc.) |

### Calculated Column Properties

```tmdl
column 'Full Name' = [FirstName] & " " & [LastName]
    dataType: string
    lineageTag: ...
    summarizeBy: none
    isDataTypeInferred
```

Inherits all DataColumn properties plus:

| Property | Type | Description |
|----------|------|-------------|
| (default) `expression` | DAX | DAX expression (after `=`) |
| `isDataTypeInferred` | boolean | Data type inferred from expression |

### Measure Properties

```tmdl
measure 'Total Sales' = SUM(Sales[Amount])
    formatString: $ #,##0.00
    displayFolder: Revenue
    lineageTag: ...
    isHidden
    description: Total sales amount
```

| Property | Type | Description |
|----------|------|-------------|
| (default) `expression` | DAX | Measure DAX expression |
| `formatString` | string | Display format |
| `displayFolder` | string | Folder path for client tools |
| `lineageTag` | GUID | Lineage tracking |
| `isHidden` | boolean | Hide from client tools |
| `kpiStatusExpression` | DAX | KPI status indicator expression |
| `kpiTargetExpression` | DAX | KPI target value expression |
| `kpiTrendExpression` | DAX | KPI trend indicator expression |
| `detailRowsDefinition` | DAX | Detail rows drill-through expression |
| `formatStringDefinition` | DAX | Dynamic format string expression |

### Partition Properties

```tmdl
/// M (Power Query) partition
partition 'Sales-Partition' = m
    mode: import
    source =
        let
            Source = Sql.Database("server", "db"),
            Sales = Source{[Schema="dbo",Item="Sales"]}[Data]
        in
            Sales

/// Calculated partition
partition 'CalcTable-Partition' = calculated
    source =
        CALENDAR(DATE(2020, 1, 1), DATE(2025, 12, 31))

/// Direct Query partition
partition 'DQ-Partition' = m
    mode: directQuery
    source =
        let
            Source = Sql.Database("server", "db"),
            Result = Source{[Schema="dbo",Item="Sales"]}[Data]
        in
            Result
```

| Property | Type | Description |
|----------|------|-------------|
| (default) `sourceType` | enum | `m`, `calculated`, `entity`, `query` |
| `mode` | enum | `import`, `directQuery`, `dual`, `default`, `push` |
| `source` | expression | M or DAX expression for the partition |
| `refreshPolicy` | object | Incremental refresh configuration |

### Relationship Properties

```tmdl
relationship 550e8400-e29b-41d4-a716-446655440000
    fromColumn: Sales.'Product Key'
    toColumn: Product.'Product Key'
    crossFilteringBehavior: oneDirection
    fromCardinality: many
    toCardinality: one
    isActive
    securityFilteringBehavior: oneDirection
    joinOnDateBehavior: datePartOnly
    relyOnReferentialIntegrity
```

| Property | Type | Description |
|----------|------|-------------|
| `fromColumn` | reference | Foreign key column (Table.Column format) |
| `toColumn` | reference | Primary key column (Table.Column format) |
| `crossFilteringBehavior` | enum | `oneDirection`, `bothDirections`, `automatic` |
| `fromCardinality` | enum | `many`, `one`, `none` |
| `toCardinality` | enum | `one`, `many`, `none` |
| `isActive` | boolean | Active relationship (default true) |
| `securityFilteringBehavior` | enum | `oneDirection`, `bothDirections` |
| `joinOnDateBehavior` | enum | `dateAndTime`, `datePartOnly` |
| `relyOnReferentialIntegrity` | boolean | Assume referential integrity (DirectQuery) |

### Role Properties

```tmdl
role 'Regional Manager'
    modelPermission: read
    description: Access to regional sales data only

    tablePermission Sales = Sales[Region] = USERPRINCIPALNAME()
    tablePermission Product = TRUE()

    member 'user@company.com'
    member 'group@company.com' = group
    member 'serviceaccount@company.com' = auto
    member DOMAIN\user1 = activeDirectory
```

| Property | Type | Description |
|----------|------|-------------|
| `modelPermission` | enum | `read`, `readRefresh`, `administrator`, `none` |
| `description` | string | Role description |
| `tablePermission` | DAX | RLS filter expression per table |
| `columnPermission` | enum | OLS metadata permission per column |
| `member` | member declaration | Role members (see member types below) |

**Member type values:** `user` (default, Azure AD user), `group` (Azure AD group), `auto` (Azure AD auto-detect), `activeDirectory` (Windows AD)

### Hierarchy Properties

```tmdl
hierarchy 'Product Hierarchy'
    lineageTag: ...
    displayFolder: Hierarchies

    level Category
        column: Category
        lineageTag: ...

    level Subcategory
        column: Subcategory

    level Product
        column: 'Product Name'
```

| Property | Type | Description |
|----------|------|-------------|
| `lineageTag` | GUID | Lineage tracking |
| `displayFolder` | string | Folder path |
| `isHidden` | boolean | Hide from clients |
| `level` | child object | Hierarchy level (contains `column` reference) |

### Calculation Group Properties

```tmdl
table 'Time Intelligence'
    calculationGroup
        precedence: 1
        multipleOrEmptySelectionExpression =
                SELECTEDMEASURE()
        noSelectionExpression =
                SELECTEDMEASURE()

    calculationItem Current = SELECTEDMEASURE()

    calculationItem YTD =
            CALCULATE(SELECTEDMEASURE(), DATESYTD('Date'[Date]))
        formatStringDefinition = "#,##0.00"
        ordinal: 1

    column 'Time Calc'
        dataType: string
        sourceColumn: Name
        sortByColumn: Ordinal

    column Ordinal
        dataType: int64
        sourceColumn: Ordinal
        summarizeBy: none
```

| Property | Type | Description |
|----------|------|-------------|
| `precedence` | integer | Evaluation order when multiple calc groups exist |
| `multipleOrEmptySelectionExpression` | DAX | Expression when multiple items selected |
| `noSelectionExpression` | DAX | Expression when no item selected |
| `calculationItem` | child object | Individual calculation with DAX expression |
| `formatStringDefinition` | DAX | Dynamic format string for calculation item |
| `ordinal` | integer | Sort order of calculation items |

### Perspective Definition

```tmdl
perspective SalesAnalysis

    perspectiveTable Sales
        perspectiveMeasure 'Sales Amount'
        perspectiveMeasure 'Total Quantity'
        perspectiveColumn Amount
        perspectiveColumn 'Order Date'
        perspectiveHierarchy 'Date Hierarchy'

    perspectiveTable Product
        perspectiveColumn Category
        perspectiveColumn 'Product Name'
```

### Culture / Translation Definition

```tmdl
culture pt-PT
    translations
        model Model
            caption: Modelo
        table Sales
            caption: Vendas
            measure 'Sales Amount'
                caption: Total de Vendas
                displayFolder: Metricas Base
            column Amount
                caption: Valor
        table Product
            caption: Produto
            column Category
                caption: Categoria
            hierarchy 'Product Hierarchy'
                caption: Hierarquia de Produto

    linguisticMetadata =
        {
            "Version": "1.0.0",
            "Language": "pt-PT"
        }
```

Translation properties per object: `caption`, `description`, `displayFolder`.

### Named Expressions (Power Query Parameters)

```tmdl
expression Server = "localhost" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]

expression Database = "AdventureWorks" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]

expression 'Shared Query' =
        let
            Source = Sql.Database(Server, Database),
            Result = Source{[Schema="dbo",Item="DimDate"]}[Data]
        in
            Result
    queryGroup: 'Shared Queries'
```

### Annotations and Extended Properties

```tmdl
table Sales

    annotation PBI_ResultType = Table
    annotation PBI_NavigationStepName = Navigation

    annotation CustomMetadata = ```
        {
            "owner": "data-team",
            "refreshSchedule": "daily"
        }
        ```

    extendedProperty DataAccessOptions = ```
        {
            "LegacyRedirects": true
        }
        ```
```

Annotations use `Value` (Text) as default property. JSON extended properties use `Value` (JSON) as default property. Both support single-line and triple-backtick multi-line values.

### KPI Properties on Measures

```tmdl
measure 'Revenue' = SUM(Sales[Amount])
    formatString: $ #,##0

    kpi
        targetExpression = 1000000
        statusExpression =
            var x = [Revenue] / [Revenue Goal]
            return
                if(x < 0.4, -1, if(x < 0.8, 0, 1))
        trendExpression =
            var x = [Revenue] / CALCULATE([Revenue], DATEADD('Date'[Date], -1, YEAR))
            return
                if(x < 1, -1, if(x = 1, 0, 1))
        statusGraphic: "Three Symbols UnCircled Colored"
        trendGraphic: "Three Symbols UnCircled Colored"
```

### Format String Definition (Dynamic Format Strings)

```tmdl
measure 'Sales Amount' = SUM(Sales[Amount])

    formatStringDefinition = IF(SELECTEDVALUE(Currency[Code]) = "EUR", "#,##0.00 EUR", "$ #,##0.00")
```

This enables context-dependent formatting while preserving the numeric data type.

## Expression Language Mapping

| Object Type | Property | Expression Language |
|-------------|----------|-------------------|
| Measure | Expression | DAX |
| CalculatedColumn | Expression | DAX |
| CalculationItem | Expression | DAX |
| MPartitionSource | Expression | M (Power Query) |
| CalculatedPartitionSource | Expression | DAX |
| QueryPartitionSource | Query | NativeQuery |
| KPI | StatusExpression, TargetExpression, TrendExpression | DAX |
| TablePermission | FilterExpression | DAX |
| FormatStringDefinition | Expression | DAX |
| DataCoverageDefinition | Expression | DAX |
| DetailRowsDefinition | Expression | DAX |
| BasicRefreshPolicy | SourceExpression, PollingExpression | M |
| LinguisticMetadata | Content | XML or JSON |
| JsonExtendedProperty | Value | JSON |
| NamedExpression | Expression | M |

## Partial Declarations

TMDL supports splitting object definitions across multiple files (similar to C# partial classes). A table can be declared in its own file, and additional measures for that table can be declared in a separate file:

```tmdl
/// In measures.tmdl -- additional measures for existing tables
table Sales

    measure 'Sales Amount' = SUM(Sales[Amount])
        formatString: $ #,##0

table Product

    measure '# Products' = COUNTROWS(Product)
        formatString: #,##0
```

The same property cannot be declared twice across files -- this produces a deserialization error.

## Reserved Keywords

All TOM object type names are reserved: `model`, `database`, `table`, `column`, `measure`, `partition`, `relationship`, `role`, `perspective`, `culture`, `expression`, `function`, `hierarchy`, `level`, `annotation`, `extendedProperty`, `calculationGroup`, `calculationItem`, `dataSource`, `member`, `tablePermission`, `columnPermission`, `perspectiveTable`, `perspectiveMeasure`, `perspectiveColumn`, `perspectiveHierarchy`, `kpi`, `ref`, `createOrReplace`.

Object names matching reserved keywords must be enclosed in single quotes.
