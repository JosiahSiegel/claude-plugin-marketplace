# PBIR JSON Schema Reference

## Report Definition (definition.pbir)

```json
{
  "version": "1.0",
  "datasetReference": {
    "byPath": {
      "path": "../MyReport.dataset"
    },
    "byConnection": null
  }
}
```

When connecting to a remote (published) semantic model:
```json
{
  "version": "1.0",
  "datasetReference": {
    "byPath": null,
    "byConnection": {
      "connectionString": "Data Source=powerbi://api.powerbi.com/v1.0/myorg/WorkspaceName;Initial Catalog=SemanticModelName",
      "pbiServiceModelId": null,
      "pbiModelVirtualServerName": "sobe_wowvirtualserver",
      "pbiModelDatabaseName": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
      "name": "EntityDataSource",
      "connectionType": "pbiServiceXmlaStyleLive"
    }
  }
}
```

## Page Definition (page.json)

```json
{
  "$schema": "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/page/1.0.0/schema.json",
  "name": "ReportSection1",
  "displayName": "Sales Overview",
  "displayOption": 0,
  "height": 720,
  "width": 1280,
  "filters": [],
  "ordinal": 0,
  "visibility": 0
}
```

**Display options:**
| Value | Mode |
|-------|------|
| 0 | Fit to page (default) |
| 1 | Fit to width |
| 2 | Actual size |

**Visibility:**
| Value | State |
|-------|-------|
| 0 | Visible |
| 1 | Hidden |

## Visual Definition (visual.json)

### Basic Structure

```json
{
  "$schema": "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/visualContainer/1.0.0/schema.json",
  "name": "abc123def456",
  "position": {
    "x": 50,
    "y": 50,
    "z": 0,
    "width": 400,
    "height": 300,
    "tabOrder": 1000
  },
  "visual": {
    "visualType": "clusteredBarChart",
    "query": { ... },
    "objects": { ... },
    "drillFilterOtherVisuals": true
  },
  "filters": [ ... ]
}
```

### Common Visual Types

| visualType | Description |
|-----------|-------------|
| `barChart` | Stacked bar chart |
| `clusteredBarChart` | Clustered bar chart |
| `columnChart` | Stacked column chart |
| `clusteredColumnChart` | Clustered column chart |
| `lineChart` | Line chart |
| `areaChart` | Area chart |
| `lineStackedColumnComboChart` | Line and column combo |
| `lineClusteredColumnComboChart` | Line and clustered column combo |
| `pieChart` | Pie chart |
| `donutChart` | Donut chart |
| `treemap` | Treemap |
| `waterfallChart` | Waterfall chart |
| `funnel` | Funnel chart |
| `card` | Single-value card |
| `multiRowCard` | Multi-row card |
| `kpi` | KPI visual |
| `slicer` | Slicer |
| `tableEx` | Table |
| `pivotTable` | Matrix |
| `map` | Map (Bing) |
| `filledMap` | Filled map (choropleth) |
| `shapeMap` | Shape map |
| `azureMap` | Azure Map |
| `gauge` | Gauge |
| `scatterChart` | Scatter plot |
| `ribbonChart` | Ribbon chart |
| `decompositionTreeVisual` | Decomposition tree |
| `keyInfluencers` | Key influencers |
| `qnaVisual` | Q&A visual |
| `smartNarrativeVisual` | Smart narrative |
| `actionButton` | Button |
| `bookmarkNavigator` | Bookmark navigator |
| `pageNavigator` | Page navigator |
| `textbox` | Text box |
| `image` | Image |
| `shape` | Shape |

### Query State Structure

```json
{
  "queryState": {
    "Category": {
      "projections": [
        {
          "queryRef": "Product.Category",
          "active": true
        }
      ]
    },
    "Y": {
      "projections": [
        {
          "queryRef": "Sum(Sales.Amount)",
          "active": true
        }
      ]
    },
    "Series": {
      "projections": [
        {
          "queryRef": "Date.Year",
          "active": true
        }
      ]
    }
  }
}
```

**Query buckets by visual type:**
| Visual | Buckets |
|--------|---------|
| Bar/Column chart | Category, Y, Series, Tooltips |
| Line chart | Category, Y, Series, Tooltips |
| Pie/Donut | Category, Y, Tooltips |
| Table | Values |
| Matrix | Rows, Columns, Values |
| Card | Fields |
| Slicer | Fields |
| Map | Location, Legend, Size, Tooltips |
| Scatter | X, Y, Size, Details, Legend |

### Visual Objects (Formatting)

```json
{
  "objects": {
    "title": [{
      "properties": {
        "show": { "expr": { "Literal": { "Value": "true" } } },
        "text": { "expr": { "Literal": { "Value": "'Sales by Category'" } } },
        "fontSize": { "expr": { "Literal": { "Value": "14D" } } },
        "fontColor": { "solid": { "color": { "expr": { "Literal": { "Value": "'#333333'" } } } } }
      }
    }],
    "legend": [{
      "properties": {
        "show": { "expr": { "Literal": { "Value": "true" } } },
        "position": { "expr": { "Literal": { "Value": "'Right'" } } }
      }
    }],
    "dataLabels": [{
      "properties": {
        "show": { "expr": { "Literal": { "Value": "false" } } }
      }
    }],
    "categoryAxis": [{
      "properties": {
        "show": { "expr": { "Literal": { "Value": "true" } } }
      }
    }],
    "valueAxis": [{
      "properties": {
        "show": { "expr": { "Literal": { "Value": "true" } } },
        "start": { "expr": { "Literal": { "Value": "0D" } } }
      }
    }]
  }
}
```

### Filter Definitions

**Visual-level filter:**
```json
{
  "filters": [
    {
      "name": "Filter_abc123",
      "expression": {
        "Column": {
          "Expression": { "SourceRef": { "Entity": "Sales" } },
          "Property": "Status"
        }
      },
      "type": "Categorical",
      "filter": {
        "Version": 2,
        "From": [{ "Name": "s", "Entity": "Sales", "Type": 0 }],
        "Where": [{
          "Condition": {
            "In": {
              "Expressions": [{ "Column": { "Expression": { "SourceRef": { "Source": "s" } }, "Property": "Status" } }],
              "Values": [[{ "Literal": { "Value": "'Active'" } }]]
            }
          }
        }]
      }
    }
  ]
}
```

## Report Settings (report.json)

```json
{
  "$schema": "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/report/1.0.0/schema.json",
  "themeCollection": {
    "baseTheme": {
      "name": "CY24SU06",
      "reportVersionAtImport": "5.53",
      "type": 2
    }
  },
  "activeSectionIndex": 0,
  "settings": {
    "filterPaneEnabled": true,
    "navContentPaneEnabled": true,
    "useStylableVisualContainerHeader": true,
    "exportDataMode": 1,
    "queryLimitOption": 3
  },
  "resourcePackages": []
}
```

## Programmatic Report Generation Template (Python)

Complete template for generating a multi-page PBIR report:

```python
import json
import os
import uuid

def create_report(report_name, dataset_path, pages):
    """Generate a complete PBIR report structure."""
    base_dir = f"{report_name}.report"
    os.makedirs(base_dir, exist_ok=True)

    # definition.pbir
    with open(f"{base_dir}/definition.pbir", "w") as f:
        json.dump({
            "version": "1.0",
            "datasetReference": {
                "byPath": {"path": f"../{dataset_path}"},
                "byConnection": None
            }
        }, f, indent=2)

    # report.json
    with open(f"{base_dir}/report.json", "w") as f:
        json.dump({
            "$schema": "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/report/1.0.0/schema.json",
            "themeCollection": {"baseTheme": {"name": "CY24SU06", "type": 2}},
            "activeSectionIndex": 0,
            "settings": {"filterPaneEnabled": True}
        }, f, indent=2)

    # Pages
    for i, page in enumerate(pages):
        page_id = page.get("id", f"ReportSection{i}")
        page_dir = f"{base_dir}/pages/{page_id}"
        os.makedirs(f"{page_dir}/visuals", exist_ok=True)

        with open(f"{page_dir}/page.json", "w") as f:
            json.dump({
                "$schema": "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/page/1.0.0/schema.json",
                "name": page_id,
                "displayName": page["name"],
                "displayOption": 0,
                "height": 720,
                "width": 1280,
                "ordinal": i
            }, f, indent=2)

        for visual in page.get("visuals", []):
            vid = visual.get("id", uuid.uuid4().hex[:12])
            visual_dir = f"{page_dir}/visuals/{vid}"
            os.makedirs(visual_dir, exist_ok=True)
            with open(f"{visual_dir}/visual.json", "w") as f:
                json.dump(visual["definition"], f, indent=2)

# Usage
create_report("SalesReport", "SalesReport.dataset", [
    {
        "name": "Overview",
        "visuals": [
            {
                "definition": {
                    "$schema": "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/visualContainer/1.0.0/schema.json",
                    "name": "card_revenue",
                    "position": {"x": 50, "y": 50, "width": 200, "height": 100},
                    "visual": {
                        "visualType": "card",
                        "query": {"queryState": {"Fields": {"projections": [{"queryRef": "Sum(Sales.Revenue)"}]}}}
                    }
                }
            }
        ]
    }
])
```
