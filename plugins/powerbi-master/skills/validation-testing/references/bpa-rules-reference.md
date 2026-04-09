# Best Practice Analyzer (BPA) Rules Reference

Complete reference for the Tabular Editor / semantic-link-labs Best Practice Analyzer rule system, the standard Microsoft rule set, severity strategy, custom rule authoring, and CI gating patterns.

## What BPA Is

The Best Practice Analyzer is a rules engine that evaluates tabular models against codified anti-patterns. It runs identically in:
- Tabular Editor 2 (free, CLI + UI)
- Tabular Editor 3 (paid, full IDE)
- semantic-link-labs `run_model_bpa` (Python, Fabric notebooks)
- Power BI Desktop **TMDL view > Best Practice Analyzer** (added in 2025)
- Fabric workspace **Settings > Best Practice Analyzer**

The same `BPARules.json` file works across all of them, so you author rules once and run them everywhere.

## The Standard Microsoft Rule Set

[TabularEditor/BestPracticeRules](https://github.com/TabularEditor/BestPracticeRules) is the canonical Microsoft-curated rule set. ~60 rules across 5 categories. **Always pin to a specific commit in CI** -- new rules can break previously-green builds.

```bash
# Pin to a specific commit
RULES_URL="https://raw.githubusercontent.com/TabularEditor/BestPracticeRules/abc1234/BPARules.json"
TabularEditor.exe model -A "$RULES_URL" -V
```

### Categories and Headline Rules

#### Performance (16 rules)

| Rule ID | Severity | What it catches |
|---------|----------|-----------------|
| `MODEL_PERFORMANCE_DISABLE_AUTO_DATETIME` | Warning | Auto date/time creates hidden tables that bloat the model |
| `MODEL_PERFORMANCE_AVOID_BIDIRECTIONAL_RELATIONSHIPS` | Warning | Bidirectional cross-filter degrades query performance |
| `DAX_PERFORMANCE_AVOID_DIVISION_OPERATOR` | Warning | `/` doesn't handle div-by-zero; use `DIVIDE()` |
| `DAX_PERFORMANCE_AVOID_FILTER_AS_FILTER_ARGUMENT` | Warning | `CALCULATE(..., FILTER(table, ...))` is slow vs explicit column filters |
| `DAX_PERFORMANCE_USE_VARIABLES` | Info | Repeated subexpressions should be assigned to VARs |
| `DAX_PERFORMANCE_AVOID_USERELATIONSHIP` | Info | Inactive relationships are slower than separate tables |
| `MODEL_PERFORMANCE_LARGE_TABLE_USE_COLUMNAR_STORAGE` | Warning | High-cardinality columns should not be sorted |
| `MODEL_PERFORMANCE_REDUCE_USAGE_OF_LONG_LENGTH_COLUMNS` | Info | Wide string columns hurt VertiPaq compression |
| `MODEL_PERFORMANCE_OPTIMIZE_RELATIONSHIP_COLUMNS_DATATYPE` | Warning | Use integer relationships, not strings |
| `MODEL_PERFORMANCE_AVOID_FLOATING_POINT_DATATYPES` | Warning | Float types use 64 bits per value, no compression |
| `MODEL_PERFORMANCE_AVOID_HIGH_CARDINALITY_DATETIME_COLUMNS` | Warning | DateTime columns at second precision destroy compression |
| `MODEL_PERFORMANCE_USE_DIRECT_LAKE_FOR_LARGE_FACT_TABLES` | Info | Direct Lake recommended over Import for tables >100M rows |

#### DAX Expressions (12 rules)

| Rule ID | Severity | What it catches |
|---------|----------|-----------------|
| `DAX_PRACTICE_AVOID_FORMAT_FUNCTIONS_IN_NUMERIC_MEASURES` | Warning | `FORMAT()` in a numeric measure breaks the data type |
| `DAX_PRACTICE_USE_TREATAS_INSTEAD_OF_INTERSECT` | Info | TREATAS is faster and more readable |
| `DAX_PRACTICE_USE_COALESCE_INSTEAD_OF_ISBLANK` | Info | `COALESCE(x, 0)` is cleaner than `IF(ISBLANK(x), 0, x)` |
| `DAX_PRACTICE_AVOID_IFERROR` | Warning | `IFERROR` masks bugs; use `DIVIDE`, `CONTAINS`, etc. |
| `DAX_PRACTICE_USE_SELECTEDVALUE_INSTEAD_OF_VALUES` | Info | SELECTEDVALUE is more idiomatic for single-value contexts |

#### Error Prevention (10 rules)

| Rule ID | Severity | What it catches |
|---------|----------|-----------------|
| `ERROR_PREVENTION_PROVIDE_FORMAT_STRING_FOR_MEASURES` | Error | Every measure should have a `formatString` |
| `ERROR_PREVENTION_PROVIDE_FORMAT_STRING_FOR_COLUMNS` | Warning | Numeric/date columns need a format string |
| `ERROR_PREVENTION_PROVIDE_DATA_CATEGORY_FOR_GEOGRAPHY_COLUMNS` | Warning | City/State/Country columns need DataCategory set |
| `ERROR_PREVENTION_AVOID_INVALID_RELATIONSHIPS` | Error | Many-to-many without explicit handling can produce wrong results |
| `ERROR_PREVENTION_USE_THE_DIVIDE_FUNCTION` | Warning | Same as DAX_PERFORMANCE_AVOID_DIVISION_OPERATOR |

#### Maintenance (15 rules)

| Rule ID | Severity | What it catches |
|---------|----------|-----------------|
| `MAINTENANCE_REMOVE_REDUNDANT_PREFIXES_FROM_COLUMNS` | Info | `Sales[Sales Amount]` -> `Sales[Amount]` |
| `MAINTENANCE_HIDE_FOREIGN_KEYS` | Warning | FK columns should be hidden from end users |
| `MAINTENANCE_HIDE_FACT_TABLE_COLUMNS` | Info | Use measures, not raw column drag-and-drop |
| `MAINTENANCE_PROVIDE_DESCRIPTION_FOR_MEASURES` | Info | Documentation rule -- every measure should have a description |
| `MAINTENANCE_AVOID_CALCULATED_COLUMNS_USE_POWER_QUERY` | Info | Calculated columns are slow vs Power Query equivalent |
| `MAINTENANCE_REMOVE_UNUSED_COLUMNS` | Warning | Unreferenced columns waste memory |
| `MAINTENANCE_REMOVE_UNUSED_MEASURES` | Info | Orphan measures clutter the field list |

#### Naming Conventions / Formatting (8 rules)

| Rule ID | Severity | What it catches |
|---------|----------|-----------------|
| `NAMING_OBJECTS_SHOULD_NOT_START_WITH_SPACE` | Error | Leading space in name |
| `NAMING_AVOID_SPECIAL_CHARS_IN_NAMES` | Warning | `&`, `%`, `#` etc. in names break some clients |
| `NAMING_USE_TITLE_CASE_FOR_TABLE_NAMES` | Info | `Sales Order` not `salesOrder` |
| `NAMING_NO_SNAKE_CASE_IN_NAMES` | Info | `total_sales` should be `Total Sales` |
| `FORMATTING_SET_DEFAULT_AGGREGATION_FOR_NUMERIC_COLUMNS` | Info | `summarizeBy: sum` for numeric columns by default |

## BPA Rule File Format

```json
[
  {
    "ID": "MODEL_PERFORMANCE_DISABLE_AUTO_DATETIME",
    "Name": "Disable auto date/time",
    "Category": "Performance",
    "Description": "Auto date/time creates hidden date tables that consume memory and break time intelligence patterns. Always disable and use a proper date dimension.",
    "Severity": 2,
    "Scope": "Model",
    "Expression": "AutoDateTime = false",
    "FixExpression": null,
    "CompatibilityLevel": 1200
  },
  {
    "ID": "ERROR_PREVENTION_PROVIDE_FORMAT_STRING_FOR_MEASURES",
    "Name": "Provide format string for measures",
    "Category": "Error Prevention",
    "Description": "Every measure should set a format string to ensure consistent display.",
    "Severity": 3,
    "Scope": "Measure",
    "Expression": "FormatString <> \"\" and not IsHidden",
    "FixExpression": "FormatString = \"#,##0\""
  }
]
```

### Field Reference

| Field | Required | Purpose |
|-------|----------|---------|
| `ID` | Yes | Unique identifier (uppercase + underscores) |
| `Name` | Yes | Display name in BPA UI |
| `Category` | Yes | Performance / DAX Expressions / Error Prevention / Maintenance / Naming Conventions / Formatting |
| `Description` | Recommended | Multi-line explanation; appears in BPA UI tooltip |
| `Severity` | Yes | 1=Info, 2=Warning, **3=Error (blocks CI)** |
| `Scope` | Yes | Object type the rule applies to (see below) |
| `Expression` | Yes | DAX-like predicate. Returns true if the rule **passes**. |
| `FixExpression` | No | DAX-like assignment that BPA can apply via "Generate Fix Script" |
| `CompatibilityLevel` | No | Minimum compat level the rule applies to |

### Scope Values

- `Model` -- runs once per model
- `Table`
- `Column`
- `CalculatedColumn`
- `DataColumn`
- `Measure`
- `Hierarchy`
- `Level`
- `Partition`
- `Relationship`
- `Role`
- `KPI`
- `Perspective`
- `Culture`
- `CalculationGroup`
- `CalculationItem`
- `NamedExpression`
- `ModelRole`

You can use multiple scopes via comma: `"Scope": "Column, CalculatedColumn"`.

### Expression Language

The Expression field uses a constrained DAX-like syntax that operates on TOM properties of the scoped object. Key things to know:

- Property names match TOM (e.g., `FormatString`, `IsHidden`, `DataType`)
- String comparison is case-sensitive
- LINQ-style methods on collections: `Measures.Any(m => m.IsHidden)`, `Columns.Count(c => c.SortByColumn = null)`
- Boolean operators: `and`, `or`, `not`
- Special functions: `Contains()`, `RegExMatch()`, `Split()`

#### Example: Complex measure rule

```json
{
  "ID": "CONTOSO_MEASURE_FOLDERS",
  "Name": "Measure must have a non-empty display folder",
  "Category": "Maintenance",
  "Severity": 2,
  "Scope": "Measure",
  "Expression": "DisplayFolder <> \"\" or IsHidden"
}
```

#### Example: Cross-object rule using LINQ

```json
{
  "ID": "CONTOSO_NO_ORPHAN_COLUMNS",
  "Name": "Column must be referenced by a measure or relationship",
  "Category": "Maintenance",
  "Severity": 2,
  "Scope": "Column",
  "Expression": "IsHidden or Model.AllMeasures.Any(m => m.Expression.Contains(DaxObjectFullName)) or Model.Relationships.Any(r => r.FromColumn = outerIt or r.ToColumn = outerIt)"
}
```

#### Example: Regex naming rule

```json
{
  "ID": "CONTOSO_FACT_TABLE_NAMING",
  "Name": "Fact tables must start with 'fct_'",
  "Category": "Naming Conventions",
  "Severity": 1,
  "Scope": "Table",
  "Expression": "Not Measures.Any() or RegExMatch(Name, \"^fct_\")"
}
```

## Authoring Custom Rules

### From Tabular Editor 2 UI

1. Tools > Best Practice Analyzer
2. Click "Add new rule"
3. Set Scope, Category, Severity
4. Write the expression in the editor (with autocomplete)
5. Click "Test rule" to preview matches against the loaded model
6. Save -- rule is added to `BPARules.json` in `%APPDATA%\TabularEditor\` (or local file if "Save as project file")

### From semantic-link-labs (Python)

```python
import sempy_labs as labs

# Get the built-in rules as a starting point
rules = labs.model_bpa_rules()

# Add a custom rule
rules.append({
    "ID": "CONTOSO_REQUIRE_FOLDER",
    "Name": "Measure must have a display folder",
    "Category": "Maintenance",
    "Severity": 2,
    "Scope": "Measure",
    "Expression": 'DisplayFolder <> ""',
})

# Save to a JSON file for reuse
import json
with open("contoso-bpa-rules.json", "w") as f:
    json.dump(rules, f, indent=2)
```

## Severity Strategy for CI

The most important BPA decision is **which rules are Error severity**, because Errors fail the pipeline.

### Recommended severity tiers

| Tier | Severity | Use for |
|------|----------|---------|
| **Block PR** | Error (3) | Issues that produce wrong results, deployment failures, or security exposure |
| **Warn PR** | Warning (2) | Performance and maintainability issues that should be fixed but not block |
| **Notify only** | Info (1) | Style preferences, naming conventions, opportunities |

### Suggested Error-tier rules (block PR)

These should always be Error severity because they cause **wrong data** or **failed deploys**:

- `ERROR_PREVENTION_PROVIDE_FORMAT_STRING_FOR_MEASURES`
- `ERROR_PREVENTION_AVOID_INVALID_RELATIONSHIPS`
- `ERROR_PREVENTION_USE_THE_DIVIDE_FUNCTION`
- `NAMING_OBJECTS_SHOULD_NOT_START_WITH_SPACE`
- `MODEL_PERFORMANCE_DISABLE_AUTO_DATETIME` (production models only)
- Any custom rule that enforces RLS or compliance requirements

### Suggested Warning-tier rules

- `MAINTENANCE_HIDE_FOREIGN_KEYS`
- `MAINTENANCE_PROVIDE_DESCRIPTION_FOR_MEASURES`
- `DAX_PERFORMANCE_AVOID_FILTER_AS_FILTER_ARGUMENT`
- `MODEL_PERFORMANCE_OPTIMIZE_RELATIONSHIP_COLUMNS_DATATYPE`

### Per-environment severity overrides

Use different rule files per environment if dev should be lenient and prod should be strict:

```bash
# Dev: warnings only (quick iteration)
te2 model -A bpa-rules-dev.json -V

# Prod: strict
te2 model -A bpa-rules-prod.json -V
```

## Pinning Rules in CI

**Always pin BPA rules to a specific commit** in CI. The Microsoft rule set evolves; an upstream rule addition can break a green pipeline overnight.

```yaml
# .github/workflows/validate.yml
env:
  BPA_RULES_COMMIT: "abc1234567890def"  # pin a specific commit
  BPA_RULES_URL: "https://raw.githubusercontent.com/TabularEditor/BestPracticeRules/${BPA_RULES_COMMIT}/BPARules.json"

steps:
  - name: Run BPA
    run: te2 model -A "${{ env.BPA_RULES_URL }}" -V -G
```

Bump the commit SHA when you intentionally adopt new rules. Treat that as a model-validation change like any other.

## Rule Authoring Tips

1. **Test on a real model** before committing the rule -- BPA expressions are easy to write and easy to get wrong
2. **Use `outerIt`** when writing LINQ expressions on collections to refer to the outer-scope object
3. **Prefer positive expressions** -- write what should be true, not what's wrong (`IsHidden = true` not `IsHidden = false`)
4. **Use `or IsHidden`** as a conventional escape hatch -- hidden objects are usually internal and exempt from style rules
5. **Document the why** in `Description` -- future-you will not remember why you wrote this rule
6. **Test FixExpression carefully** -- it's executed against every matching object when the user clicks "Generate Fix Script"
7. **Avoid network or filesystem access** in expressions -- BPA runs locally on the loaded model only

## Migrating from Legacy `BestPracticeAnalyzer.dll`

The standalone Power BI Best Practice Analyzer DLL (pre-2024) is deprecated. Migrate to the Tabular Editor BPA rule format:

| Legacy | Modern |
|--------|--------|
| BPA DLL with `.bpaRules` files | TabularEditor `BPARules.json` |
| Rule per `.cs` file | Single JSON array |
| Visual Studio dependency | None -- runs in TE2 CLI |
| Power BI Desktop only | Cross-platform (Linux, macOS, Windows, Fabric notebook) |

The legacy rule format is **not** automatically converted. Rewrite the rules in the JSON format above; the rule logic typically translates directly because both engines target TOM properties.

## Troubleshooting BPA Failures

| Symptom | Cause | Fix |
|---------|-------|-----|
| `Expression compile failed: 'X' is not a property` | Property name typo or wrong scope | Check TOM docs for the exact property name; verify scope matches |
| Rule reports false positives on hidden objects | Missing `or IsHidden` escape hatch | Add `or IsHidden` to the expression |
| Rule passes locally but fails in CI | Different BPA rule set version | Pin both local and CI to the same rule set commit |
| Rule never fires | Expression always returns true | Negate the test value or use `not (...)` |
| BPA exits 0 even with violations visible | Severity is Info or Warning -- only Error blocks | Bump to Severity 3 if it should fail CI |
| `RegExMatch is not defined` | Old BPA engine | Update to Tabular Editor 2.17+ or TE3 |
| `outerIt is not defined` | Used outside a LINQ expression | Only valid inside `Any()` / `All()` / `Where()` |
| Custom rule slow on large models | Cross-object LINQ with `Model.AllMeasures.Any(...)` | Cache the result via a Model-scope rule that builds a set |
