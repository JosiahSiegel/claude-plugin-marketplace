# TOM Advanced Patterns

## Creating Relationships

```csharp
// One-to-many relationship
var relationship = new SingleColumnRelationship() {
    Name = "Sales_to_Product",
    FromTable = model.Tables["Sales"],
    FromColumn = model.Tables["Sales"].Columns["ProductID"],
    ToTable = model.Tables["Products"],
    ToColumn = model.Tables["Products"].Columns["ProductID"],
    FromCardinality = RelationshipEndCardinality.Many,
    ToCardinality = RelationshipEndCardinality.One,
    CrossFilteringBehavior = CrossFilteringBehavior.OneDirection,
    IsActive = true,
    SecurityFilteringBehavior = SecurityFilteringBehavior.OneDirection
};
model.Relationships.Add(relationship);
```

## Row-Level Security (RLS)

```csharp
// Create a role with table filter
var role = new ModelRole() { Name = "RegionManager" };

var tablePermission = new TablePermission() {
    Table = model.Tables["Sales"],
    FilterExpression = "[Region] = USERPRINCIPALNAME()"
};
role.TablePermissions.Add(tablePermission);

model.Roles.Add(role);

// Add a member to the role (requires admin SDK/API, not TOM directly)
// Use REST API: POST /groups/{groupId}/datasets/{datasetId}/users
```

## Object-Level Security (OLS)

```csharp
// Hide columns from specific roles
var role = model.Roles["RestrictedUser"];

var columnPermission = new ColumnPermission() {
    Column = model.Tables["Employees"].Columns["Salary"],
    MetadataPermission = MetadataPermission.None  // Column is invisible
};

var tablePermission = role.TablePermissions["Employees"];
if (tablePermission == null) {
    tablePermission = new TablePermission() { Table = model.Tables["Employees"] };
    role.TablePermissions.Add(tablePermission);
}
tablePermission.ColumnPermissions.Add(columnPermission);
```

## Partitions and Incremental Refresh

```csharp
// Create partitioned table for incremental refresh
var table = model.Tables["Sales"];

// Remove default partition
table.Partitions.Clear();

// Add historical partition (import)
var historicalPartition = new Partition() {
    Name = "Sales_Historical",
    Mode = ModeType.Import,
    Source = new MPartitionSource() {
        Expression = @"
            let
                Source = Sql.Database(""server"", ""db""),
                Sales = Source{[Schema=""dbo"",Item=""Sales""]}[Data],
                Filtered = Table.SelectRows(Sales, each [OrderDate] < #date(2025, 1, 1))
            in Filtered"
    }
};
table.Partitions.Add(historicalPartition);

// Add current partition (could be DirectQuery for real-time)
var currentPartition = new Partition() {
    Name = "Sales_Current",
    Mode = ModeType.Import,
    Source = new MPartitionSource() {
        Expression = @"
            let
                Source = Sql.Database(""server"", ""db""),
                Sales = Source{[Schema=""dbo"",Item=""Sales""]}[Data],
                Filtered = Table.SelectRows(Sales, each [OrderDate] >= #date(2025, 1, 1))
            in Filtered"
    }
};
table.Partitions.Add(currentPartition);
```

## Perspectives

```csharp
// Create a perspective (a view/subset of the model)
var perspective = new Perspective() { Name = "Sales Analysis" };
model.Perspectives.Add(perspective);

// Add tables/columns to perspective
var salesPerspective = new PerspectiveTable() { Table = model.Tables["Sales"] };
perspective.PerspectiveTables.Add(salesPerspective);

// Add specific columns (if you want to exclude some)
salesPerspective.PerspectiveColumns.Add(
    new PerspectiveColumn() { Column = model.Tables["Sales"].Columns["Amount"] }
);

// Add measures
salesPerspective.PerspectiveMeasures.Add(
    new PerspectiveMeasure() { Measure = model.Tables["Sales"].Measures["Total Sales"] }
);
```

## Translations (Localization)

```csharp
// Add a culture/locale
var culture = new Culture() { Name = "es-ES" };
model.Cultures.Add(culture);

// Add translations for table
var tableTranslation = new ObjectTranslation() {
    Object = model.Tables["Sales"],
    Property = TranslatedProperty.Caption,
    Value = "Ventas"
};
culture.ObjectTranslations.Add(tableTranslation);

// Add translations for column
var columnTranslation = new ObjectTranslation() {
    Object = model.Tables["Sales"].Columns["Amount"],
    Property = TranslatedProperty.Caption,
    Value = "Cantidad"
};
culture.ObjectTranslations.Add(columnTranslation);

// Add translations for measure
var measureTranslation = new ObjectTranslation() {
    Object = model.Tables["Sales"].Measures["Total Sales"],
    Property = TranslatedProperty.Caption,
    Value = "Ventas Totales"
};
culture.ObjectTranslations.Add(measureTranslation);
```

## Calculation Groups (TOM)

```csharp
// Create calculation group table
var calcGroupTable = new Table() {
    Name = "Time Intelligence",
    CalculationGroup = new CalculationGroup()
};

// Add the Name column (required)
calcGroupTable.Columns.Add(new DataColumn() {
    Name = "Time Calculation",
    DataType = DataType.String,
    SourceColumn = "Name",
    SortByColumn = model.Tables["Time Intelligence"].Columns.ContainsName("Ordinal")
        ? model.Tables["Time Intelligence"].Columns["Ordinal"] : null
});

// Ordinal column for sort order
calcGroupTable.Columns.Add(new DataColumn() {
    Name = "Ordinal",
    DataType = DataType.Int64,
    SourceColumn = "Ordinal",
    IsHidden = true
});

// Add calculation items
calcGroupTable.CalculationGroup.CalculationItems.Add(new CalculationItem() {
    Name = "Current",
    Expression = "SELECTEDMEASURE()",
    Ordinal = 0
});

calcGroupTable.CalculationGroup.CalculationItems.Add(new CalculationItem() {
    Name = "YTD",
    Expression = "CALCULATE(SELECTEDMEASURE(), DATESYTD('Date'[Date]))",
    Ordinal = 1
});

calcGroupTable.CalculationGroup.CalculationItems.Add(new CalculationItem() {
    Name = "PY",
    Expression = "CALCULATE(SELECTEDMEASURE(), SAMEPERIODLASTYEAR('Date'[Date]))",
    Ordinal = 2
});

calcGroupTable.CalculationGroup.CalculationItems.Add(new CalculationItem() {
    Name = "YoY %",
    Expression = @"
        VAR Current = SELECTEDMEASURE()
        VAR PY = CALCULATE(SELECTEDMEASURE(), SAMEPERIODLASTYEAR('Date'[Date]))
        RETURN DIVIDE(Current - PY, PY)",
    FormatStringDefinition = new FormatStringDefinition() {
        Expression = """0.00%"""
    },
    Ordinal = 3
});

model.Tables.Add(calcGroupTable);
```

## Data Source with Service Principal Authentication

```csharp
var dataSource = new StructuredDataSource() {
    Name = "AzureSQL_ServicePrincipal",
    ConnectionDetails = new ConnectionDetails() {
        Protocol = "tds",
        Address = new ConnectionAddress() {
            Server = "server.database.windows.net",
            Database = "mydb"
        },
        Authentication = null,  // Authentication handled at runtime
        Query = null
    },
    Credential = new Credential() {
        AuthenticationKind = "ServicePrincipal",
        // Actual credentials managed in Power BI Service
    }
};
model.DataSources.Add(dataSource);
```

## Connecting to XMLA Endpoint

### Service Principal Authentication
```csharp
string clientId = "your-app-client-id";
string clientSecret = "your-client-secret";
string tenantId = "your-tenant-id";
string workspaceName = "Your Workspace";

string connectionString =
    $"DataSource=powerbi://api.powerbi.com/v1.0/myorg/{workspaceName};" +
    $"User ID=app:{clientId}@{tenantId};" +
    $"Password={clientSecret};";

using var server = new Server();
server.Connect(connectionString);
```

### Azure AD Token Authentication
```csharp
using Azure.Identity;
using Microsoft.AnalysisServices.Tabular;

var credential = new DefaultAzureCredential();
var token = await credential.GetTokenAsync(
    new Azure.Core.TokenRequestContext(
        new[] { "https://analysis.windows.net/powerbi/api/.default" }
    )
);

string connectionString =
    $"DataSource=powerbi://api.powerbi.com/v1.0/myorg/{workspaceName};" +
    $"Password={token.Token};";

using var server = new Server();
server.Connect(connectionString);
```

## Refresh Operations via TOM

```csharp
// Full refresh of a table
model.Tables["Sales"].RequestRefresh(RefreshType.Full);

// Incremental refresh of a partition
model.Tables["Sales"].Partitions["Sales_Current"].RequestRefresh(RefreshType.Full);

// Process recalc (only recalculate, no data reload)
model.RequestRefresh(RefreshType.Calculate);

// Execute all pending refresh operations
model.SaveChanges();
```

## Best Practice Analyzer Rules (Tabular Editor)

Common rules to enforce model quality:

| Rule | Description |
|------|-------------|
| No implicit measures | All numeric columns should have explicit measures |
| Hide foreign keys | Key columns used in relationships should be hidden |
| Proper naming | Measures should not start with "Sum of" or "Count of" |
| Format strings | All measures should have format strings |
| No bidirectional | Relationships should use single-direction filtering |
| Date table marked | At least one table should be marked as date table |
| Description required | Tables and measures should have descriptions |
| Unused columns | Flag columns not used in any measure, relationship, or visual |
