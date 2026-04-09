# TMDL Validation Recipes

Complete cookbook for validating TMDL files at every layer: syntax parser, TOM schema, BPA, lineage, and DAX/M syntax. Recipes target the 2026 toolchain (TmdlSerializer in Microsoft.AnalysisServices.Tabular, Tabular Editor 2/3, semantic-link-labs).

## 1. Layer 1+2: TmdlSerializer Round-Trip (.NET)

Smallest possible validator. One C# file, one NuGet package, no project required (use `dotnet script` or a single-file compile).

### 1a. Single-file C# script

```csharp
#r "nuget: Microsoft.AnalysisServices.NetCore.retail.amd64, 19.84.1"

using System;
using Microsoft.AnalysisServices.Tabular;
using Microsoft.AnalysisServices.Tabular.Tmdl;

if (Args.Count == 0)
{
    Console.Error.WriteLine("Usage: validate-tmdl <folder>");
    return 1;
}

string folder = Args[0];
try
{
    var db = TmdlSerializer.DeserializeDatabaseFromFolder(folder);

    Console.WriteLine($"OK: TMDL parsed");
    Console.WriteLine($"  CompatibilityLevel = {db.CompatibilityLevel}");
    Console.WriteLine($"  Tables             = {db.Model.Tables.Count}");
    Console.WriteLine($"  Measures           = {db.Model.Tables.Sum(t => t.Measures.Count)}");
    Console.WriteLine($"  Relationships      = {db.Model.Relationships.Count}");

    // Layer 2 deeper check: TOM Validate()
    var validation = db.Model.Validate();
    if (validation.Errors.Count > 0)
    {
        Console.Error.WriteLine($"VALIDATE ERRORS  ({validation.Errors.Count})");
        foreach (var e in validation.Errors)
            Console.Error.WriteLine($"  - {e.Object?.GetType().Name}: {e.Message}");
        return 3;
    }
    return 0;
}
catch (TmdlFormatException fx)
{
    Console.Error.WriteLine($"SYNTAX ERROR  {fx.Document}:{fx.Line}");
    Console.Error.WriteLine($"  {fx.LineText}");
    Console.Error.WriteLine($"  -> {fx.Message}");
    return 1;
}
catch (TmdlSerializationException sx)
{
    Console.Error.WriteLine($"METADATA ERROR  {sx.Document}:{sx.Line}");
    Console.Error.WriteLine($"  {sx.Message}");
    return 2;
}
```

Run with:

```bash
dotnet script validate-tmdl.csx -- "MyProject.SemanticModel/definition"
```

### 1b. Why both `TmdlFormatException` AND `TmdlSerializationException`?

| Exception | Layer | What it catches |
|-----------|-------|-----------------|
| `TmdlFormatException` | Parser (text -> tokens) | Bad indentation, invalid keyword, malformed expression delimiter, missing colon |
| `TmdlSerializationException` | Object builder (tokens -> TOM) | Property name doesn't exist on object type, value doesn't match property type, required parent missing |
| `model.Validate()` returns `Errors` | TOM semantic | Measure references undefined column, sortByColumn invalid, calculation group precedence collision, role expression syntax |

Always catch all three and report them with distinct exit codes so CI can route different failure types to different log streams.

## 2. Layer 1+2: TmdlSerializer from Python (pythonnet)

When you need TMDL parsing inside a Python pipeline (Fabric notebook, Airflow, GitLab CI), `pythonnet` lets Python load the .NET TOM assembly directly. semantic-link-labs uses this internally.

```python
%pip install pythonnet -q

import clr
import os
clr.AddReference(os.path.join(os.path.dirname(__file__), "Microsoft.AnalysisServices.Tabular.dll"))

from Microsoft.AnalysisServices.Tabular import Database
from Microsoft.AnalysisServices.Tabular.Tmdl import TmdlSerializer, TmdlFormatException, TmdlSerializationException

def validate_tmdl_folder(folder: str) -> dict:
    try:
        db = TmdlSerializer.DeserializeDatabaseFromFolder(folder)
        result = {
            "ok": True,
            "compat_level": db.CompatibilityLevel,
            "tables": db.Model.Tables.Count,
            "measures": sum(t.Measures.Count for t in db.Model.Tables),
        }
        validation = db.Model.Validate()
        if validation.Errors.Count > 0:
            result["ok"] = False
            result["validation_errors"] = [e.Message for e in validation.Errors]
        return result
    except TmdlFormatException as fx:
        return {"ok": False, "type": "syntax", "document": fx.Document, "line": fx.Line, "message": fx.Message}
    except TmdlSerializationException as sx:
        return {"ok": False, "type": "metadata", "document": sx.Document, "line": sx.Line, "message": sx.Message}

print(validate_tmdl_folder("./MyProject.SemanticModel/definition"))
```

Inside a Fabric notebook the assembly is already on the runtime, so the explicit `AddReference` becomes:

```python
import sempy.fabric  # implicitly loads Microsoft.AnalysisServices.Tabular
from Microsoft.AnalysisServices.Tabular.Tmdl import TmdlSerializer
```

## 3. Tabular Editor 2 CLI Validation

The free Tabular Editor 2 CLI is the recommended runner for any CI pipeline that doesn't have a .NET project.

### 3a. Parse-only validation (no BPA, no deploy)

```bash
# Linux / macOS via mono
mono TabularEditor.exe "MyProject.SemanticModel/definition" -B "/tmp/out.bim"

# Windows
TabularEditor.exe "MyProject.SemanticModel\definition" -B "C:\temp\out.bim"
```

The `-B` switch (bim output) forces a TmdlSerializer round-trip plus a TOM validation. Any failure exits non-zero with a precise error message.

### 3b. Parse + BPA + custom script

```bash
TabularEditor.exe "MyProject.SemanticModel/definition" \
  -S "Scripts/validate-naming.csx" \
  -A "https://raw.githubusercontent.com/TabularEditor/BestPracticeRules/master/BPARules.json" \
  -V \
  -G
```

| Switch | Effect |
|--------|--------|
| `-S <file>` | Run a C# script before BPA. Use this for custom validation that BPA can't express. |
| `-A <url\|file>` | Run BPA with the rules at the given location. |
| `-V` | Verbose: list every BPA violation, not just counts. |
| `-G` | GitHub Actions / Azure DevOps log format -- groups violations by category and renders file paths as clickable links in CI logs. |

### 3c. Custom validation C# script (Scripts/validate-naming.csx)

Tabular Editor C# scripts run with `Model` pre-bound to the loaded TOM model. Use this for validation rules that BPA cannot express because they need procedural logic.

```csharp
// Fail if any measure name uses snake_case (we want PascalCase or 'Spaced Name')
foreach (var m in Model.AllMeasures)
{
    if (m.Name.Contains("_"))
    {
        Error($"Measure '{m.Name}' uses snake_case. Use PascalCase or 'Spaced Name'.");
    }
}

// Fail if any table has zero measures AND zero relationships AND is not hidden
foreach (var t in Model.Tables.Where(t => !t.IsHidden))
{
    var hasMeasures = t.Measures.Any();
    var inRel = Model.Relationships.Any(r => r.FromTable == t || r.ToTable == t);
    if (!hasMeasures && !inRel)
        Error($"Table '{t.Name}' is orphaned (no measures, no relationships, not hidden).");
}

// Fail if any calculation group has overlapping precedence
var precedenceMap = new Dictionary<int, string>();
foreach (var t in Model.Tables.Where(t => t.CalculationGroup != null))
{
    var p = t.CalculationGroup.Precedence;
    if (precedenceMap.ContainsKey(p))
        Error($"Calc groups '{t.Name}' and '{precedenceMap[p]}' both use precedence {p}.");
    else
        precedenceMap[p] = t.Name;
}
```

The `Error()` function in a Tabular Editor C# script causes the CLI to exit non-zero, blocking the deploy.

### 3d. Exit code reference

| Code | Meaning |
|------|---------|
| 0 | Success: parsed, BPA passed, script passed |
| 1 | Warnings only (BPA Warning severity) |
| 2 | Errors (BPA Error severity, or `Error()` called in C# script) |
| 4 | Deploy failed (only relevant when using `-D`) |

Pin Tabular Editor 2 to a specific release (e.g., `2.25.0`) in CI. Newer releases sometimes add stricter validation that breaks previously-green builds.

## 4. semantic-link-labs Validation (Fabric Notebooks)

For pipelines that already live inside Fabric (notebooks, Spark jobs, Data Factory), `semantic-link-labs` is the path of least resistance.

### 4a. Run BPA against a deployed model

```python
%pip install semantic-link-labs -q
import sempy_labs as labs

results = labs.run_model_bpa(
    dataset="SalesModel",
    workspace="Sales-Dev",
    extended=True,        # Adds VertiPaq Analyzer stats so performance rules can fire
    return_dataframe=True,
)

# Filter to only failing Error-severity rules
failures = results[(results["Severity"] >= 3)]
display(failures)

if len(failures) > 0:
    raise Exception(f"BPA failed: {len(failures)} Error-severity violations")
```

### 4b. Run BPA against every model in a workspace, write to delta

```python
labs.run_model_bpa_bulk(
    workspace="Sales-Dev",
    extended=True,
)

# Results land in the lakehouse-attached notebook at:
#   Tables/modelbparesults
df = spark.table("modelbparesults")
df.filter("Severity >= 3").show()
```

This is the pattern for **scheduled BPA reporting** -- run it daily against every workspace, write to delta, build a Power BI report on top showing trends and per-team owners.

### 4c. Custom rule set

```python
import sempy_labs as labs

# Start from the built-in ~60 rules, then add or override
my_rules = labs.model_bpa_rules()  # built-in rules as a list of dicts

my_rules.append({
    "ID": "CONTOSO_NO_AUTO_DATETIME",
    "Name": "Auto date/time must be disabled",
    "Category": "Performance",
    "Severity": 3,
    "Scope": "Model",
    "Expression": "AutoDateTime = false",
    "FixExpression": None,
    "CompatibilityLevel": 1200,
})

my_rules.append({
    "ID": "CONTOSO_MEASURE_FOLDER",
    "Name": "Every measure must have a display folder",
    "Category": "Maintenance",
    "Severity": 2,
    "Scope": "Measure",
    "Expression": "DisplayFolder <> ''",
})

results = labs.run_model_bpa(
    dataset="SalesModel",
    workspace="Sales-Dev",
    rules=my_rules,
)
```

### 4d. Offline TMDL validation from Python

`semantic-link-labs` can also load a TMDL folder **without connecting** to a workspace, using the embedded TmdlSerializer wrapper. This is the way to run validation in a notebook before publishing.

```python
import sempy_labs as labs
from sempy_labs.tom import import_model_from_tmdl

# Load TMDL files from a local path (or attached lakehouse) as an in-memory TOM database
db = import_model_from_tmdl(folder="./MyProject.SemanticModel/definition")

# Run TOM Validate()
errors = db.Model.Validate().Errors
if errors.Count > 0:
    for e in errors:
        print(f"  - {e.Object.Name}: {e.Message}")
    raise Exception(f"{errors.Count} TOM validation errors")

# Run BPA against the in-memory model (no deploy required)
results = labs.run_model_bpa(model=db.Model, extended=False)
display(results[results["Severity"] >= 3])
```

This is the **best path** for "validate this TMDL folder I just generated, without ever talking to Power BI".

## 5. INFO DAX Functions (Live Model Introspection)

For models already deployed, the 2026-preferred way to introspect metadata is the `INFO.*` DAX function family. These are far more agent-friendly than DMVs because they return tables you can query like any other DAX expression.

```dax
// All measures with their tables, expressions, and folders
EVALUATE
SELECTCOLUMNS(
    INFO.MEASURES(),
    "Table",       LOOKUPVALUE(INFO.TABLES()[Name], INFO.TABLES()[ID], [TableID]),
    "Measure",     [Name],
    "Expression",  [Expression],
    "Folder",      [DisplayFolder]
)

// Find measures referencing a missing column
EVALUATE
FILTER(
    INFO.MEASURES(),
    SEARCH("Sales[NonExistentColumn]", [Expression], 1, 0) > 0
)

// Find columns with no measures referencing them (candidates for hiding)
EVALUATE
VAR Referenced =
    SUMMARIZE(
        FILTER(INFO.MEASURES(), [Expression] <> ""),
        [Name]
    )
RETURN
    EXCEPTALL(INFO.COLUMNS(), Referenced)
```

Use `semantic-link.evaluate_dax` from a Fabric notebook to run these against any deployed model.

## 6. Combined Validation Pre-Commit Hook

A combined `.git/hooks/pre-commit` script that runs all three TMDL validation layers locally before allowing a commit.

```bash
#!/usr/bin/env bash
set -e

CHANGED_TMDL=$(git diff --cached --name-only --diff-filter=ACM | grep '\.tmdl$' || true)

if [ -z "$CHANGED_TMDL" ]; then
    exit 0
fi

# Layer 1+2: TmdlSerializer parse + TOM Validate via Tabular Editor
echo "Validating TMDL syntax and TOM metadata..."
mono ~/te2/TabularEditor.exe "MyProject.SemanticModel/definition" -B /tmp/check.bim > /tmp/te2-out.txt 2>&1 || {
    cat /tmp/te2-out.txt
    echo
    echo "Pre-commit hook FAILED: TMDL syntax or metadata error."
    echo "Fix the errors above and commit again."
    exit 1
}

# Layer 3: BPA (errors block; warnings allowed)
echo "Running Best Practice Analyzer..."
mono ~/te2/TabularEditor.exe "MyProject.SemanticModel/definition" \
    -A "https://raw.githubusercontent.com/TabularEditor/BestPracticeRules/master/BPARules.json" \
    -V > /tmp/bpa-out.txt 2>&1
BPA_EXIT=$?

if [ $BPA_EXIT -eq 2 ]; then
    cat /tmp/bpa-out.txt
    echo
    echo "Pre-commit hook FAILED: BPA Error-severity violations."
    exit 1
fi

if [ $BPA_EXIT -eq 1 ]; then
    cat /tmp/bpa-out.txt
    echo "BPA warnings present but allowed. Continuing."
fi

echo "TMDL validation passed."
exit 0
```

Save as `.git/hooks/pre-commit` and `chmod +x` it. Skip with `git commit --no-verify` only when explicitly intended.

## 7. Troubleshooting Validation Failures

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `TmdlFormatException` mentioning indentation | Mixed tabs and spaces | Convert all indentation to single tabs (TMDL spec mandates tabs) |
| `TmdlFormatException: invalid keyword 'X'` | Object type misspelled or wrong casing on serialize | Use camelCase for object types and properties |
| `TmdlSerializationException: property 'Y' is not valid on Z` | Property exists on a newer compatibility level | Bump `database.tmdl` `compatibilityLevel` |
| `model.Validate()` reports orphaned column | Column has `sourceColumn` referencing a non-existent source field | Fix `sourceColumn` or remove the column |
| `model.Validate()` reports DAX error | Measure references undefined column or syntax error | Run DaxFormatter API on the expression to localize the issue |
| BPA `MODEL_PERFORMANCE_AVOID_AUTO_DATETIME` fires | Auto date/time enabled in PBIP project | Set `autoDateTime: false` in `model.tmdl` |
| BPA `DAX_PERFORMANCE_AVOID_DIVISION_OPERATOR` fires | DAX uses `/` instead of DIVIDE() | Replace with `DIVIDE(numerator, denominator, 0)` |
| Tabular Editor CLI exits 0 but Power BI Service deploy fails | Service-only validation (e.g., role member doesn't exist in tenant) | These can only be caught at deploy time |
| `semantic-link-labs` says `connect_semantic_model: not found` | Workspace name has spaces or special chars | Use the workspace ID (GUID) instead of the name |
