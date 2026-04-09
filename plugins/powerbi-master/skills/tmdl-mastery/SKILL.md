---
name: tmdl-mastery
description: |
  This skill should be used when the user asks about "TMDL", "Tabular Model Definition Language",
  "TMDL syntax", "TMDL file structure", "TMDL folder", "TMDL serialization", "TmdlSerializer",
  "TMDL view in Power BI Desktop", "TMDL vs TMSL", "TMDL vs BIM", "model.tmdl", "database.tmdl",
  "relationships.tmdl", "TMDL expressions", "TMDL tables folder", "TMDL roles", "TMDL perspectives",
  "TMDL cultures", "TMDL translations", "TMDL annotations", "TMDL calculation groups",
  "TMDL CI/CD", "TMDL Git integration", "TMDL deployment", "createOrReplace TMDL",
  "TMDL scripts", "TMDL partitions", "TMDL hierarchies", "TMDL ref keyword",
  "convert BIM to TMDL", "TMDL format Power BI project", "PBIP TMDL",
  "semantic model source control", "TMDL indentation", "TMDL object declaration",
  "TMDL extended properties", "TMDL field parameters", "TMDL KPI",
  "TMDL VS Code extension", or "Tabular Editor TMDL".
---

# TMDL (Tabular Model Definition Language) Mastery

## Overview

Complete TMDL reference covering language syntax, folder structure, object types, expressions, serialization API, CI/CD integration, and deployment patterns. TMDL is the human-readable, source-control-friendly format for defining Power BI and Analysis Services semantic models at compatibility level 1200+.

## 2026 Status Snapshot

| Aspect | Status (as of April 2026) |
|--------|---------------------------|
| TMDL language GA | GA since August 2024 -- no longer preview |
| TMDL view in Power BI Desktop | GA -- includes semantic highlighting, autocomplete, code actions, diff preview, compatibility-level upgrade prompts |
| TMDL as default PBIP semantic-model format | Default -- `model.bim` is the legacy BIM format; new PBIP projects write `definition/*.tmdl` files |
| Fabric Git integration | Exports semantic models as **TMDL** (not TMSL/BIM) |
| TMSL / BIM | **Not deprecated** -- still supported for XMLA scripting commands and tools that require JSON. Use TMDL for source control, TMSL for XMLA `createOrReplace` command scripting |
| Compatibility level | 1550+ recommended; 1601+ required for some newer properties (e.g., `formatStringDefinition`, calculation group multi/empty selection expressions) |
| Tabular Editor 2 (free) | TMDL read/write support (2.17+) |
| Tabular Editor 3 (paid) | Full TMDL IDE with DAX debugger and diagram view |
| VS Code TMDL extensions | Microsoft `analysis-services.TMDL` and the richer community `CPIM.TMDL-language-support` (DAX + M semantic highlighting, code actions, formatting, breadcrumb navigation) |
| Report Server | **No TMDL support** -- continues to use legacy PBIX binary format |

**Bottom line:** For any new Power BI / Fabric semantic model under source control, use TMDL. Retain TMSL only for XMLA command scripting scenarios or tools that still require `model.bim`.

## TMDL vs TMSL vs BIM

| Aspect | TMDL (.tmdl folder) | TMSL / BIM (model.bim) |
|--------|---------------------|------------------------|
| Format | YAML-like text, indentation-based | Single JSON file |
| Files | One file per table, role, culture, perspective | One monolithic file |
| Git friendliness | Excellent -- granular diffs, minimal merge conflicts | Poor -- entire model in one diff |
| Human readability | High -- minimal delimiters, DAX/M inline | Low -- escaped JSON strings |
| Tooling | VS Code extension, TMDL view in Desktop, Tabular Editor 3 | Any JSON editor, Tabular Editor 2/3 |
| API | TmdlSerializer (.NET) | JsonSerializer (.NET), TMSL commands |
| Migration | Can convert from BIM via Tabular Editor or Desktop | Default legacy format |

**When to use TMDL:** Any new project requiring source control, CI/CD, or team collaboration. Prefer TMDL for all PBIP projects.

**When to use TMSL/BIM:** Legacy projects, Report Server (no TMDL support), or tools that only accept BIM.

## Object Declaration Syntax

Declare objects by specifying the TOM object type followed by its name:

```tmdl
model Model
    culture: en-US

table Sales

    measure 'Sales Amount' = SUM(Sales[Amount])
        formatString: $ #,##0

    column 'Product Key'
        dataType: int64
        sourceColumn: ProductKey
        summarizeBy: none
```

**Key rules:**
- Enclose names in single quotes if they contain dot, equals, colon, single quote, or whitespace
- Escape single quotes within names by doubling them: `'My ''Special'' Table'`
- Child objects are implicitly nested under their parent via indentation (no explicit collections)
- Child objects need not be contiguous -- columns and measures can interleave freely

## Property Syntax

Properties use colon delimiter; expressions use equals delimiter:

```tmdl
column Category
    dataType: string          /// colon for non-expression properties
    sortByColumn: 'Cat Order' /// colon for object references
    isHidden                  /// boolean shortcut (true implied)
    isAvailableInMdx: false   /// explicit boolean

measure Total = SUM(Sales[Amount])   /// equals for default expression
    formatString: $ #,##0            /// colon for properties after expression
```

**Text property values:** Leading/trailing double-quotes optional and auto-stripped. Required if value has leading/trailing whitespace. Escape internal double-quotes by doubling them.

## Default Properties by Object Type

| Object Type | Default Property | Language |
|-------------|-----------------|----------|
| measure | Expression | DAX |
| calculatedColumn | Expression | DAX |
| calculationItem | Expression | DAX |
| partition (M) | Expression | M |
| partition (calculated) | Expression | DAX |
| tablePermission | FilterExpression | DAX |
| namedExpression | Expression | M |
| annotation | Value | Text |
| jsonExtendedProperty | Value | JSON |

Default properties use equals (`=`) on the same line or as multi-line expression on the following lines.

## Expressions -- Single-Line and Multi-Line

```tmdl
/// Single-line expression
measure 'Sales Amount' = SUM(Sales[Amount])

/// Multi-line expression (indented one level deeper than parent properties)
measure 'YoY Growth %' =
        VAR CurrentSales = [Sales Amount]
        VAR PYSales = CALCULATE([Sales Amount], SAMEPERIODLASTYEAR('Date'[Date]))
        RETURN DIVIDE(CurrentSales - PYSales, PYSales)
    formatString: 0.00%

/// Triple-backtick block for verbatim content (preserves whitespace exactly)
partition 'Sales-Part' = m
    mode: import
    source = ```
        let
            Source = Sql.Database("server", "db"),
            Sales = Source{[Schema="dbo",Item="Sales"]}[Data]
        in
            Sales
        ```
```

**Expression rules:**
- Multi-line expressions must be indented one level deeper than parent object properties
- Trailing blank lines and whitespace are stripped (unless using triple-backtick blocks)
- Triple-backtick enclosing preserves exact whitespace; end delimiter sets left boundary

## Descriptions (/// Syntax)

```tmdl
/// This table contains all sales transactions
/// Updated daily via incremental refresh
table Sales

    /// Total revenue across all product lines
    measure 'Sales Amount' = SUM(Sales[Amount])
```

Triple-slash comments directly above an object become its TOM `Description` property. No whitespace allowed between the description block and the object type keyword.

## Ref Keyword

Reference another TMDL object or define collection ordering:

```tmdl
/// In model.tmdl -- defines table ordering for deterministic roundtrips
model Model
    culture: en-US

ref table Calendar
ref table Sales
ref table Product
ref table Customer

ref culture en-US
ref culture pt-PT

ref role 'Regional Manager'
```

**Rules:** Objects referenced but missing their file are ignored on deserialization. Objects with files but no ref are appended to collection end.

## TMDL Folder Structure

```
definition/
  database.tmdl           # Database properties (compatibilityLevel, etc.)
  model.tmdl              # Model properties, ref declarations
  relationships.tmdl      # All relationships
  expressions.tmdl        # Shared/named expressions (Power Query parameters)
  functions.tmdl          # DAX user-defined functions
  dataSources.tmdl        # Legacy data sources
  tables/
    Sales.tmdl            # Table + all its columns, measures, partitions, hierarchies
    Product.tmdl
    Calendar.tmdl
  roles/
    RegionalManager.tmdl  # Role definition with permissions and members
    Admin.tmdl
  cultures/
    en-US.tmdl            # Translations for all objects in this culture
    pt-PT.tmdl
  perspectives/
    SalesView.tmdl        # Perspective definition
```

One file per table, role, culture, and perspective. All inner metadata (columns, measures, partitions, hierarchies) lives inside the parent table file.

## TMDL Scripts (createOrReplace)

Apply changes to a live semantic model using the TMDL view in Power BI Desktop:

```tmdl
createOrReplace

    table 'Time Intelligence'
        calculationGroup
            precedence: 1

        calculationItem Current = SELECTEDMEASURE()

        calculationItem YTD =
                CALCULATE(SELECTEDMEASURE(), DATESYTD('Calendar'[Date]))

        calculationItem PY =
                CALCULATE(SELECTEDMEASURE(), SAMEPERIODLASTYEAR('Calendar'[Date]))

        column 'Time Calc'
            dataType: string
            sourceColumn: Name
            sortByColumn: Ordinal

        column Ordinal
            dataType: int64
            sourceColumn: Ordinal
            summarizeBy: none
```

Only one command verb per script execution. The `createOrReplace` command creates or replaces specified objects and all descendants.

## Indentation Rules

TMDL uses strict whitespace indentation with a default single **tab** per level:

- **Level 1:** Object declaration (`table`, `measure`, `column`)
- **Level 2:** Object properties (`dataType`, `formatString`)
- **Level 3:** Multi-line expressions (DAX/M code)

Database-level and model-level direct children (`table`, `relationship`, `role`, `culture`, `perspective`, `expression`) do not require indentation since they are implicitly under the root. Incorrect indentation produces a `TmdlFormatException`.

## Casing and Whitespace

- Serialization uses **camelCase** for object types, keywords, and enum values
- Deserialization is **case-insensitive**
- Property value leading/trailing whitespace is trimmed
- Expression trailing blank lines are dropped
- Blank whitespace-only lines within expressions are preserved as empty lines

## TMDL Serialization API (.NET)

```csharp
using Microsoft.AnalysisServices.Tabular;

// Serialize model to TMDL folder
TmdlSerializer.SerializeDatabaseToFolder(database, @"C:\output\model-tmdl");

// Deserialize TMDL folder back to TOM
var db = TmdlSerializer.DeserializeDatabaseFromFolder(@"C:\output\model-tmdl");

// Serialize single object to string
string tmdl = TmdlSerializer.SerializeObject(table.Measures["Total Sales"]);
```

**NuGet package:** `Microsoft.AnalysisServices.NetCore.retail.amd64` (or .NET Framework equivalent)

**Error types:** `TmdlFormatException` (invalid syntax) and `TmdlSerializationException` (valid syntax but invalid TOM metadata). Both include `Document`, `Line`, and `LineText` properties.

## Self-Validation

**Before deploying any TMDL you've generated**, run the four-layer validation pipeline from the **`powerbi-master:validation-testing`** skill:

1. **Syntax** -- `TmdlSerializer.DeserializeDatabaseFromFolder` catches `TmdlFormatException` (bad indentation, invalid keywords)
2. **Metadata** -- the same call catches `TmdlSerializationException` (invalid property combinations) and `model.Validate()` catches dangling references
3. **Best practice** -- Tabular Editor 2 CLI `-A` switch or `semantic-link-labs.run_model_bpa` runs the standard Microsoft BPA rule set
4. **Lineage** -- `model.Validate().Errors` plus custom Tabular Editor C# scripts catch sortByColumn / measure-references-column issues

The validation-testing skill provides ready-to-run recipes (C#, Python, GitHub Actions YAML) for each layer. **Always validate before recommending a deploy.**

## TMDL View in Power BI Desktop (2026)

The TMDL view is an integrated code editor inside Power BI Desktop for scripting semantic-model changes. As of the 2026 release wave its feature set includes:

- **Semantic highlighting, autocomplete (Ctrl+Space), tooltips on hover, and code actions** (generate lineage tags, correct property misspellings)
- **Code formatting** via Shift+Alt+F or ribbon Format button (including "Format Selection" from the context menu)
- **Error diagnostics** with a dedicated Problems pane
- **Preview diff** -- side-by-side or inline TMDL diff of the model before and after executing the script, navigable via toolbar (previewing runs only valid TMDL)
- **Compatibility level upgrade prompt** -- if the script uses a property above the current model compatibility level (e.g., 1550 -> 1601 for `formatStringDefinition`), Desktop prompts to upgrade automatically
- **Multi-tab scripts**, saved into `TMDLScripts/` folder in PBIP projects (one file per tab)
- **Drag objects** from the Data pane onto the editor to script them as `createOrReplace`; multi-select with Ctrl before dragging
- **Right-click > Script TMDL** to a new tab or clipboard
- **Apply** button applies metadata-only changes (no data refresh); renaming a column via TMDL decouples it from `sourceColumn` (Power Query editor still shows the source name)
- **Bulk rename via regex find-and-replace** -- common pattern for prefix removal (`fact_`, `dim_`) or case changes

**Limitation:** Desktop does not hot-reload TMDL files changed externally. After editing `.tmdl` files in VS Code, restart Power BI Desktop to pick up the changes.

## Semantic Link Labs (Python TOM from Fabric Notebooks)

For scripting semantic models from Python without a .NET toolchain, use `semantic-link-labs` (PyPI: `semantic-link-labs`) inside a Fabric notebook. It provides a Pythonic wrapper over TOM:

```python
%pip install semantic-link-labs -q

import sempy_labs as labs
from sempy_labs.tom import connect_semantic_model

with connect_semantic_model(dataset="SalesModel", workspace="Sales-Dev", readonly=False) as tom:
    # Add a measure
    tom.add_measure(
        table_name="Sales",
        measure_name="Sales Amount",
        expression="SUM(Sales[Amount])",
        format_string="$ #,##0.00",
        display_folder="Revenue",
    )

    # Add an incremental refresh policy
    tom.add_incremental_refresh_policy(
        table_name="Sales",
        column_name="OrderDate",
        start_date="2020-01-01T00:00:00",
        end_date="2025-12-31T00:00:00",
        incremental_granularity="Day",
        incremental_periods=30,
        rolling_window_granularity="Month",
        rolling_window_periods=36,
    )

    # tom.save_changes() is called automatically on context exit
```

See `references/tmdl-programmatic-python.md` for a full cookbook.

## Additional Resources

### Reference Files
- **`references/tmdl-syntax-reference.md`** -- Complete TMDL syntax and grammar reference with all object types, properties, and expression rules
- **`references/tmdl-examples-cookbook.md`** -- Copy-pasteable TMDL examples for every object type: tables, columns, measures, partitions, relationships, roles, perspectives, cultures, calculation groups, hierarchies, KPIs, annotations, and field parameters
- **`references/tmdl-cicd-patterns.md`** -- CI/CD pipelines, Git integration, deployment patterns, Tabular Editor CLI, Azure DevOps and GitHub Actions workflows, and merge conflict strategies
- **`references/tmdl-programmatic-python.md`** -- semantic-link-labs / SemPy TOM scripting from Fabric Python notebooks: measures, calc groups, incremental refresh, RLS, Direct Lake, BPA, and model export patterns

### Related Skills
- **`powerbi-master:validation-testing`** -- Validate TMDL artifacts before deployment: TmdlSerializer parser, TOM Validate, BPA via Tabular Editor CLI / semantic-link-labs, custom C# rule scripts

### Official Microsoft Learn References (2026)
- [Announcing general availability of TMDL](https://powerbi.microsoft.com/en-us/blog/announcing-general-availability-of-tabular-model-definition-language-tmdl/) -- TMDL GA announcement
- [Use the TMDL view in Power BI Desktop](https://learn.microsoft.com/en-us/power-bi/transform-model/desktop-tmdl-view) -- Feature walkthrough with scenarios
- [Power BI Desktop project semantic model folder](https://learn.microsoft.com/en-us/power-bi/developer/projects/projects-dataset) -- TMDL inside PBIP
- [TMDL scripts reference (Microsoft Learn)](https://learn.microsoft.com/en-us/analysis-services/tmdl/tmdl-scripts) -- `createOrReplace` command documentation
