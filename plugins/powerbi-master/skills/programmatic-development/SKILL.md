---
name: programmatic-development
description: |
  This skill should be used when the user asks about "create Power BI report programmatically",
  "PBIR format", "PBIP developer mode", "Power BI project files", "TOM SDK",
  "Tabular Object Model", ".NET SDK for Power BI", "TMSL", "TMDL",
  "Tabular Editor scripting", "pbi-tools", "generate pbix", "code-first Power BI",
  "semantic model from code", "ALM Toolkit", "Power BI external tools",
  "TMDL basics (for detailed TMDL, load tmdl-mastery)",
  or "programmatic report generation".
---

# Programmatic Power BI Development

## Overview

Power BI supports multiple approaches for creating and managing reports and semantic models through code. The PBIR/PBIP format (2025-2026) is the primary modern approach, complemented by TOM/.NET SDK for semantic models and various open-source tools.

## PBIR - Power BI Enhanced Report Format

PBIR is the modern, publicly documented, JSON-based report format that replaced the legacy binary format. As of January 2026, PBIR is the default format in Power BI Service, and as of March 2026, it is the default in Power BI Desktop.

### PBIR Rollout Timeline

| Milestone | Date | Status |
|-----------|------|--------|
| PBIR default in Power BI Service | January 2026 (rollout through February) | GA |
| PBIR default in Power BI Desktop | March 2026 | GA |
| PBIP (Power BI Projects) GA | 2026 | GA |
| PBIR-only format (legacy deprecated) | Future (post-GA) | Planned |

**Key benefit:** Each visual, page, and bookmark is a separate JSON file, enabling granular Git diff/merge, CI/CD pipelines, and multi-developer collaboration. Public JSON schemas allow VS Code validation.

**PBIR on Report Server:** Not yet supported. Report Server continues to use PBIX format only.

### PBIP Project Structure

```
MyReport.pbip                          # Project entry point
├── MyReport.report/
│   ├── definition.pbir                # Report definition (JSON)
│   ├── report.json                    # Report-level settings
│   └── pages/
│       ├── ReportSection1/
│       │   ├── page.json              # Page metadata
│       │   └── visuals/
│       │       ├── visual1/
│       │       │   └── visual.json    # Visual definition
│       │       └── visual2/
│       │           └── visual.json
│       └── ReportSection2/
│           ├── page.json
│           └── visuals/
│               └── ...
├── MyReport.dataset/
│   ├── definition.pbidataset          # Dataset definition
│   ├── model.bim                      # Tabular model (JSON/TMDL)
│   └── .pbi/
│       └── localSettings.json
└── .gitignore
```

### PBIR Report JSON Schema

Each visual is a separate JSON file with a schema declaration:

```json
{
  "$schema": "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/visualContainer/1.0.0/schema.json",
  "name": "uniqueVisualId",
  "position": {
    "x": 50, "y": 50,
    "width": 400, "height": 300,
    "tabOrder": 0
  },
  "visual": {
    "visualType": "barChart",
    "query": {
      "queryState": {
        "Category": {
          "projections": [{ "queryRef": "Product.Category", "active": true }]
        },
        "Y": {
          "projections": [{ "queryRef": "Sum(Sales.Amount)" }]
        }
      }
    },
    "objects": {
      "legend": [{ "properties": { "show": { "expr": { "Literal": { "Value": "true" } } } } }]
    }
  }
}
```

### Programmatic PBIR Manipulation

Since PBIR files are plain JSON, create or modify reports with any language:

**Python example -- add a page programmatically:**
```python
import json
import os

report_dir = "MyReport.report/pages"
new_page_id = "NewPage1"
os.makedirs(f"{report_dir}/{new_page_id}/visuals", exist_ok=True)

page_config = {
    "displayName": "Sales Overview",
    "displayOption": 0,
    "height": 720,
    "width": 1280
}

with open(f"{report_dir}/{new_page_id}/page.json", "w") as f:
    json.dump(page_config, f, indent=2)
```

**Batch update all visuals:**
```python
import glob, json

for visual_path in glob.glob("MyReport.report/pages/*/visuals/*/visual.json"):
    with open(visual_path) as f:
        visual = json.load(f)
    # Update theme or property across all visuals
    visual.setdefault("objects", {})
    visual["objects"]["general"] = [{
        "properties": {
            "responsive": {"expr": {"Literal": {"Value": "true"}}}
        }
    }]
    with open(visual_path, "w") as f:
        json.dump(visual, f, indent=2)
```

## TMDL - Tabular Model Definition Language

TMDL is the human-readable, source-control-friendly format for semantic model definitions. GA since 2025. For comprehensive TMDL coverage including complete syntax reference, all object types, CI/CD patterns, and deployment workflows, load the dedicated **`powerbi-master:tmdl-mastery`** skill.

Quick example:

```tmdl
table Sales
    measure 'Total Sales' = SUM(Sales[Amount])
        formatString: $ #,##0.00
        displayFolder: Revenue

    partition 'Sales-Partition' = m
        mode: import
        source =
            let
                Source = Sql.Database("server", "db"),
                Sales = Source{[Schema="dbo",Item="Sales"]}[Data]
            in
                Sales

    column Amount
        dataType: decimal
        sourceColumn: Amount
        formatString: $ #,##0.00
```

## TOM - Tabular Object Model (.NET SDK)

The .NET SDK for creating and managing semantic models programmatically via XMLA endpoint.

### Setup

```bash
dotnet add package Microsoft.AnalysisServices.NetCore.retail.amd64
# or for .NET Framework:
# Install-Package Microsoft.AnalysisServices.retail.amd64
```

### Create a Semantic Model

```csharp
using Microsoft.AnalysisServices.Tabular;

// Connect via XMLA endpoint
string connectionString = "DataSource=powerbi://api.powerbi.com/v1.0/myorg/WorkspaceName;";
using var server = new Server();
server.Connect(connectionString);

var database = new Database() { Name = "SalesModel", ID = "SalesModel" };
var model = new Model() { Name = "SalesModel" };
database.Model = model;

// Add a table
var salesTable = new Table() { Name = "Sales" };
salesTable.Columns.Add(new DataColumn() {
    Name = "OrderDate", DataType = DataType.DateTime, SourceColumn = "OrderDate"
});
salesTable.Columns.Add(new DataColumn() {
    Name = "Amount", DataType = DataType.Decimal, SourceColumn = "Amount"
});

// Add a partition (data source)
var partition = new Partition() {
    Name = "Sales-Partition",
    Source = new MPartitionSource() {
        Expression = @"let Source = Sql.Database(""server"", ""db""),
            Sales = Source{[Schema=""dbo"",Item=""Sales""]}[Data]
        in Sales"
    }
};
salesTable.Partitions.Add(partition);

// Add a measure
salesTable.Measures.Add(new Measure() {
    Name = "Total Sales",
    Expression = "SUM(Sales[Amount])",
    FormatString = "$#,##0.00"
});

model.Tables.Add(salesTable);
server.Databases.Add(database);
database.Update(Microsoft.AnalysisServices.UpdateOptions.ExpandFull);
```

### Modify Existing Model

```csharp
var database = server.Databases.FindByName("ExistingModel");
var model = database.Model;

// Add a new measure
var table = model.Tables["Sales"];
table.Measures.Add(new Measure() {
    Name = "YoY Growth",
    Expression = @"
        VAR Current = [Total Sales]
        VAR PY = CALCULATE([Total Sales], SAMEPERIODLASTYEAR('Date'[Date]))
        RETURN DIVIDE(Current - PY, PY)",
    FormatString = "0.00%"
});

// Add a calculation group
var calcGroup = new Table() { Name = "Time Intelligence" };
calcGroup.Columns.Add(new DataColumn() {
    Name = "Time Calc", DataType = DataType.String, SourceColumn = "Name"
});
calcGroup.CalculationGroup = new CalculationGroup();
calcGroup.CalculationGroup.CalculationItems.Add(new CalculationItem() {
    Name = "Current", Expression = "SELECTEDMEASURE()"
});
calcGroup.CalculationGroup.CalculationItems.Add(new CalculationItem() {
    Name = "YTD", Expression = "CALCULATE(SELECTEDMEASURE(), DATESYTD('Date'[Date]))"
});
model.Tables.Add(calcGroup);

model.SaveChanges();
```

### Licensing Requirement
TOM requires XMLA read/write endpoint access: **Premium, PPU, or Fabric F-SKU capacity**.

## Tabular Editor

External tool for advanced semantic model development. Two versions:

| Feature | Tabular Editor 2 (Free) | Tabular Editor 3 (Paid) |
|---------|------------------------|------------------------|
| TOM object editing | Yes | Yes |
| C# scripting | Yes | Yes + enhanced IDE |
| Best Practice Analyzer | Yes | Yes + custom rules |
| DAX debugging | No | Yes |
| TMDL support | Limited | Full |
| Diagram view | No | Yes |
| IntelliSense | Basic | Advanced |
| Calendar support | No | Yes (2025) |
| Calculation group selection expressions | No | Yes (2025) |

### External Tools in Desktop (2025 Update)

As of June 2025, there are no longer any unsupported write operations for external tools. Third-party tools (Tabular Editor, DAX Studio, ALM Toolkit) can now freely modify any aspect of the semantic model hosted in Power BI Desktop, including adding/removing tables and columns, changing data types, and more.

**TMDL view** added in January 2025 Desktop greatly expanded the list of objects supporting write operations from external tools.

### Tabular Editor 3 Updates (2025-2026)

- Improved auto-complete for C# scripts (more context-sensitive)
- Support for calculation group selection expressions (multiple/empty selection)
- Enhanced calendar support for DAX time intelligence
- Better integration with PBIP/TMDL format

### Tabular Editor C# Script Example
```csharp
// Add YTD measure for every measure in "Revenue" folder
foreach (var m in Model.AllMeasures.Where(m => m.DisplayFolder == "Revenue"))
{
    var ytdMeasure = m.Table.AddMeasure(
        m.Name + " YTD",
        $"CALCULATE({m.DaxObjectFullName}, DATESYTD('Date'[Date]))"
    );
    ytdMeasure.DisplayFolder = "Revenue\\YTD";
    ytdMeasure.FormatString = m.FormatString;
}
```

## pbi-tools

Open-source CLI for extracting, serializing, and compiling PBIX files for source control:

```bash
# Extract PBIX to source-control-friendly folder
pbi-tools extract "Report.pbix"

# Compile back to PBIX (report-only, no model)
pbi-tools compile "Report/" -format PBIX -outPath "Report.pbix"

# Deploy to Power BI Service
pbi-tools deploy "Report/" -environment Production
```

**Extracted structure:**
```
Report/
├── .pbixproj.json          # Project settings
├── Model/                  # Tabular model (TMDL or JSON)
│   ├── database.tmdl
│   └── tables/
├── Report/                 # Report layout
│   └── report.json
├── Mashup/                 # Power Query M code
│   └── Package/Formulas/
└── StaticResources/        # Images, custom visuals
```

## ALM Toolkit

Free tool for schema comparison between semantic models:

- Compare local model vs. published model
- Identify differences in tables, columns, measures, relationships
- Deploy changes selectively
- Works with XMLA endpoint (Premium/PPU/Fabric)

## Power BI Desktop Developer Features (2025-2026)

### Developer Mode and Git Integration

Enable developer mode for PBIP/PBIR editing:
1. File > Options > Preview features > "Power BI Project (.pbip) save option"
2. File > Options > Preview features > "Store reports using enhanced metadata format (PBIR)"
3. Save As > Power BI Project (.pbip) to get folder-based files

**Git integration workflow:**
- Save as PBIP locally, commit to Git repository
- PBIR format enables per-visual diff and merge conflict resolution
- Connect Fabric workspace to Git (Azure DevOps or GitHub) for cloud sync
- Feature branches for development, PR-based review, auto-sync on merge to main

### Enhanced Dataset Metadata (GA)

Enhanced metadata format stores dataset information as JSON instead of binary, enabling:
- Source control friendly text-based format
- Programmatic editing and diffing
- Better merge conflict resolution
- Compatibility with TMDL and PBIP workflows

### Sensitivity Labels in Desktop

Apply Microsoft Purview sensitivity labels directly in Power BI Desktop:
- Labels propagate from datasets to reports and exports
- Mandatory labeling can be enforced via tenant settings
- Labels are preserved when publishing to the service
- Export protection (PDF, PowerPoint, Excel) applies based on label

**Note:** Sensitivity labels are NOT supported in Power BI Report Server.

### Desktop Performance Settings

| Setting | Location | Impact |
|---------|----------|--------|
| Background data | Data Load options | Faster development experience |
| Parallel loading of tables | Data Load options | Faster initial load of multi-table models |
| DirectQuery query timeout | DirectQuery options | Prevent long-running queries |
| Auto date/time | Data Load options | Disable for production (saves memory) |
| Auto recovery | Data Load options | Protect against crashes |
| PBIR format | Preview features | Enable for Git-compatible reports |
| UDFs | Preview features | Enable DAX user-defined functions |
| Enhanced time intelligence | Preview features | Enable calendar-based week functions |

## Additional Resources

### Reference Files
- **`references/pbir-schema-reference.md`** -- Complete PBIR JSON schema reference for visuals, pages, and report settings
- **`references/tom-advanced-patterns.md`** -- Advanced TOM patterns: relationships, RLS, partitions, perspectives, translations
