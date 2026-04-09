---
name: validation-testing
description: |
  This skill should be used when the user asks about "validate TMDL", "validate PBIR",
  "check TMDL syntax", "check PBIR schema", "lint TMDL", "lint PBIR",
  "TmdlSerializer error", "TmdlFormatException", "TmdlSerializationException",
  "Best Practice Analyzer", "BPA rules", "BPA CLI", "Tabular Editor BPA",
  "PBI-Inspector", "PBI-InspectorV2", "Fab Inspector", "PBIR JSON schema",
  "PBIR schema validation", "validate semantic model before deploy",
  "pre-deployment validation", "fabric-cicd parameter.yml validation",
  "verify semantic model", "verify report", "model validation", "report validation",
  "DAX syntax check", "M syntax check", "DaxFormatter", "lineage check",
  "validate measures", "check bookmarks", "circular reference",
  "CI gate Power BI", "fail PR on BPA", "rules.json BPA",
  "validate TMDL folder", "validate PBIR folder", "validate PBIP",
  "agent self-validation TMDL", "self-check generated PBIR",
  "validate before fabric-cicd deploy", "load model without deploy",
  "headless validation Power BI", or "agent quality gate semantic model".
---

# Power BI Validation and Self-Testing

## Overview

Validation skill for any TMDL, PBIR, DAX, or M artifact a developer (or Claude) generates. The goal: catch syntax, schema, and best-practice errors **locally** before a Fabric REST deploy fails. This skill is essential for the powerbi-expert agent's **Self-Validation Protocol** -- whenever the agent writes TMDL or PBIR, it should describe (or run) the matching validation step from this skill.

As of 2026, Power BI validation has four distinct layers, each catching a different class of error:

| Layer | TMDL Tool | PBIR Tool | What it catches |
|-------|-----------|-----------|-----------------|
| **1. Syntax / parser** | `TmdlSerializer.DeserializeDatabaseFromFolder` (.NET) | JSON schema validation (`$schema` URLs) | Indentation errors, invalid keywords, malformed JSON |
| **2. Object / schema** | `TmdlSerializer` -> `TmdlSerializationException` (valid syntax, invalid TOM metadata) | PBIR JSON schemas in `microsoft/json-schemas` repo | Invalid property combinations, type mismatches, missing required properties |
| **3. Best practice (BPA)** | Tabular Editor BPA rules (`BPARules.json`) or `semantic-link-labs.run_model_bpa` | PBI-InspectorV2 rules (`Base-rules.json`) | Anti-patterns, missing display folders, ambiguous relationships, naming conventions |
| **4. Lineage / cross-reference** | DAX measure references resolve, sortByColumn exists, calculation group precedence | Bookmarks reference real pages, drillthrough targets exist, theme files present | Dangling references, broken bookmarks, missing visuals |

**The cardinal rule:** never deploy without passing layers 1 and 2; never merge to main without passing layer 3.

## 2026 Validation Tooling Snapshot

| Tool | Validates | Runtime | Status |
|------|-----------|---------|--------|
| `TmdlSerializer` (Microsoft.AnalysisServices.Tabular) | TMDL syntax + TOM schema | .NET / pythonnet | GA |
| `Tabular Editor 2 CLI` (free) | TMDL load + BPA + custom C# scripts | .NET CLI | GA, free |
| `Tabular Editor 3 CLI` (paid) | Same + advanced rules + DAX debugger | .NET CLI | GA, commercial |
| `semantic-link-labs.run_model_bpa` | TMDL/TOM model BPA from Python | Fabric notebook (Python) | GA, ~60 rules built in |
| `semantic-link-labs.run_model_bpa_bulk` | BPA across all models in workspace | Fabric notebook | GA |
| `PBI-InspectorV2` ("Fab Inspector") | PBIR / PBIP / Fabric item rules | .NET CLI / Docker | v2.3+, GA |
| `pbi-tools` | PBIX extract/compile + basic TMDL | .NET CLI | Stable for TMDL, evolving for PBIR |
| `fabric-cicd` (built-in) | `parameter.yml` + repo structure pre-deployment | Python | GA |
| `DaxFormatter` API | DAX syntax | HTTP | GA |
| Microsoft TMDL VS Code extension | TMDL syntax in editor | VS Code | GA |
| Community `CPIM.TMDL-language-support` | TMDL + DAX + M semantic highlighting | VS Code | GA |
| INFO DAX functions | Live model introspection (replaces DMVs) | XMLA / Desktop | GA |

## Self-Validation Protocol (For Generated Artifacts)

When generating TMDL or PBIR artifacts inside an agent loop, follow this minimum protocol:

1. **Before writing files** -- mentally validate the structure: every object reference must resolve, every required property must be set.
2. **After writing files** -- run a syntax-level parse (TmdlSerializer for TMDL; JSON schema validation for PBIR).
3. **Before suggesting deployment** -- run a BPA pass (Tabular Editor CLI or semantic-link-labs).
4. **Report results inline** -- never silently swallow validation errors. Surface line numbers, file paths, and the specific rule that failed.

A valid agent response that generates a 50-line TMDL measure block should always be followed by either:
- (a) A validation script the user can paste, OR
- (b) An inline Bash/PowerShell/Python validation invocation if the environment supports it.

## TMDL Validation -- Layer 1 (Syntax Parser)

The fastest, lowest-dependency TMDL syntax check is `TmdlSerializer.DeserializeDatabaseFromFolder`. It throws:

- **`TmdlFormatException`** -- the TMDL text has invalid syntax (bad keyword, wrong indentation, malformed expression). Includes `Document`, `Line`, and `LineText` properties pointing to the exact location.
- **`TmdlSerializationException`** -- the TMDL text parses but produces invalid TOM metadata (e.g., a `column` references a `dataType` that doesn't exist, or a `partition` references an unknown data source).

**Minimal C# validator (.NET 8):**

```csharp
using Microsoft.AnalysisServices.Tabular;
using Microsoft.AnalysisServices.Tabular.Tmdl;

string folder = args[0];
try
{
    var db = TmdlSerializer.DeserializeDatabaseFromFolder(folder);
    Console.WriteLine($"OK: TMDL parsed. CompatLevel={db.CompatibilityLevel}, Tables={db.Model.Tables.Count}");
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

**One-liner via Tabular Editor 2 CLI** (no C# project required):

```bash
# Loads TMDL folder; non-zero exit on parse failure
TabularEditor.exe "MyProject.SemanticModel/definition" -B "MyProject.bim"
```

The `-B` (bim output) switch forces a deserialize + reserialize round-trip. Any parse failure exits non-zero with the error written to stderr.

For full scripted patterns and Python equivalents, see `references/tmdl-validation-recipes.md`.

## TMDL Validation -- Layer 3 (Best Practice Analyzer)

The Best Practice Analyzer (BPA) is the canonical anti-pattern checker for tabular models. It is the same engine in Tabular Editor 2, Tabular Editor 3, semantic-link-labs, and `Fabric > Workspace settings > Best Practice Analyzer`.

**Tabular Editor 2 CLI (free, recommended for CI):**

```bash
# Run BPA against a TMDL folder using the official Microsoft rule set
TabularEditor.exe "MyProject.SemanticModel/definition" \
  -A "https://raw.githubusercontent.com/TabularEditor/BestPracticeRules/master/BPARules.json" \
  -V \
  -G

# Exit codes:
#   0 = no violations
#   1 = warnings only
#   2 = errors found (any rule with Severity >= 3) -- pipeline should FAIL
```

**Switches that matter for CI/CD:**

| Switch | Purpose |
|--------|---------|
| `-A <rules.json>` | Run BPA with the specified rules file (URL or local path) |
| `-V` | Verbose output (lists each violation) |
| `-G` | GitHub Actions / Azure Pipelines log format (group sections, file paths) |
| `-D <conn>` | Deploy after passing BPA |
| `-S <script>` | Run a C# script before BPA (custom validation) |

**Severity-driven failure:** when a BPA rule is set to `Error` (level 3), the CLI **immediately stops and exits non-zero**. Set BPA rules to Error severity for any anti-pattern that should block a PR; set to Warning for advisory-only rules.

**Standard Microsoft rule set:** [TabularEditor/BestPracticeRules](https://github.com/TabularEditor/BestPracticeRules) -- ~60 rules covering performance, error prevention, DAX, maintenance, and naming. Always pin to a specific commit in CI.

For a complete BPA rule reference (every Microsoft rule explained, plus how to author custom rules), see `references/bpa-rules-reference.md`.

## TMDL Validation from Python (semantic-link-labs)

```python
%pip install semantic-link-labs -q
import sempy_labs as labs

# Run the default BPA against a deployed model
results = labs.run_model_bpa(
    dataset="SalesModel",
    workspace="Sales-Dev",
    extended=True,        # adds VertiPaq Analyzer stats for performance rules
)
results.head(20)

# Run BPA against every model in a workspace and store to delta
labs.run_model_bpa_bulk(
    workspace="Sales-Dev",
    extended=True,
)

# Custom rule set from a JSON file in the lakehouse
my_rules = labs.model_bpa_rules()  # built-in rule definitions
my_rules.append({
    "ID": "AVOID_AUTO_DATE",
    "Name": "Disable auto date/time",
    "Category": "Performance",
    "Severity": 3,
    "Scope": "Model",
    "Expression": "DiscourageImplicitMeasures and not AutoDateTime",
})
labs.run_model_bpa(dataset="SalesModel", rules=my_rules)
```

`semantic-link-labs` is the **Python path** for layer 3. Use it inside Fabric notebooks, scheduled BPA runs, or Spark pipelines. See `references/tmdl-validation-recipes.md` for the full Python validation cookbook including offline TMDL parse from a local folder.

## PBIR Validation -- Layer 1 (JSON Schema)

Every PBIR file embeds a `$schema` URL pointing to the official Microsoft schema in [microsoft/json-schemas](https://github.com/microsoft/json-schemas/tree/main/fabric/item/report/definition). This means **any** JSON Schema validator can syntax-check PBIR files locally.

**Python `jsonschema` validator:**

```python
import json
import urllib.request
from pathlib import Path
from jsonschema import Draft202012Validator, RefResolver

def validate_pbir_file(pbir_file: Path) -> list[str]:
    doc = json.loads(pbir_file.read_text(encoding="utf-8"))
    schema_url = doc.get("$schema")
    if not schema_url:
        return [f"{pbir_file}: no $schema declared"]

    schema = json.loads(urllib.request.urlopen(schema_url).read())
    validator = Draft202012Validator(schema)
    errors = sorted(validator.iter_errors(doc), key=lambda e: e.path)
    return [f"{pbir_file}#{'/'.join(map(str, e.path))}: {e.message}" for e in errors]

# Walk the entire PBIR folder
report_root = Path("MyProject.Report/definition")
all_errors = []
for f in report_root.rglob("*.json"):
    all_errors.extend(validate_pbir_file(f))

if all_errors:
    print(f"FAIL: {len(all_errors)} schema violations")
    for e in all_errors[:50]:
        print(f"  {e}")
    raise SystemExit(1)
print(f"OK: validated {sum(1 for _ in report_root.rglob('*.json'))} PBIR files")
```

**Cache the schemas locally** for offline CI: `git clone https://github.com/microsoft/json-schemas.git` once, then point `RefResolver` at the local copy. Stops your CI from making 1000+ HTTP calls per build.

## PBIR Validation -- Layer 3 (PBI-InspectorV2 / Fab Inspector)

[NatVanG/PBI-InspectorV2](https://github.com/NatVanG/PBI-InspectorV2) (also known as **Fab Inspector**) is the canonical rules-based PBIR/PBIP validator. v2.3+ supports all Fabric item types (semantic models, reports, notebooks, lakehouses) via the `-fabricitem` switch and the new PBIR enhanced format (the original `PBI-Inspector` repo only handles PBIR-Legacy).

**Install (cross-platform .NET tool):**

```bash
# Download the latest release from https://github.com/NatVanG/PBI-InspectorV2/releases
# Or use the published Docker image
docker pull natvang/pbi-inspector-v2:latest
```

**Run against a PBIP folder:**

```bash
PBIInspectorCLI \
  -fabricitem "./MyProject.Report" \
  -rules "./pbi-inspector-rules.json" \
  -formats "JSON,HTML,GitHub" \
  -output "./inspector-results"

# Exit codes:
#   0 = all rules passed
#   1 = warnings only
#   2 = at least one Error-severity rule failed
```

**Rules format** -- start from [Base-rules.json](https://github.com/NatVanG/PBI-InspectorV2/blob/main/Rules/Base-rules.json) and customize. Each rule has:
- `Name` (display)
- `Description`
- `LogType` (Error / Warning / Info)
- `Disabled` (skip without deleting)
- `Path` (JSONPath into PBIR file)
- `Test` (one of `isEqualTo`, `isGreaterThan`, `isLessThan`, `mustExist`, `mustNotExist`, `regex`, etc.)

**Common rules to enforce on every PBIR PR:**

```json
[
  {
    "Name": "All visuals have a title",
    "LogType": "Error",
    "Path": "$.visual.objects.title[0].properties.show.expr.Literal.Value",
    "Test": "isEqualTo",
    "Expected": "true"
  },
  {
    "Name": "Page count under limit",
    "LogType": "Error",
    "Path": "$.pages",
    "Test": "arrayLengthLessThan",
    "Expected": 1000
  },
  {
    "Name": "Bookmarks reference real pages",
    "LogType": "Error",
    "Path": "$.children[?(@.targetSection)].targetSection",
    "Test": "mustResolveToPage"
  }
]
```

Full rule examples and CI gating patterns in `references/pbir-validation-recipes.md`.

## fabric-cicd Pre-Deployment Validation

`fabric-cicd` runs **automatic parameter.yml validation** before publishing. If `parameter.yml` is malformed or contains an unknown environment, the deployment **fails before touching the workspace**. This is the cheapest possible CI safety net.

**Trigger validation manually** without deploying:

```bash
# Use the debug script shipped in the fabric-cicd devtools folder
python debug_parameterization.py \
  --repository-directory ./MyProject \
  --environment prod \
  --item-type-in-scope SemanticModel,Report
```

This parses every `*.tmdl`, `*.json`, and `*.pbir` file, applies the `find_replace` and `key_value_replace` transformations, and reports any unresolved placeholder. **Run this in CI on every PR**, regardless of whether the PR actually deploys.

## DAX Syntax Validation (No Server Required)

The free **DaxFormatter API** parses DAX text and reports formatting + syntax errors:

```python
import requests

def check_dax(expression: str) -> tuple[bool, str]:
    r = requests.post(
        "https://www.daxformatter.com/api/daxformatter/DaxRichFormat",
        json={
            "dax": f"EVALUATE ROW(\"x\", {expression})",
            "maxLineLenght": 120,
            "skipSpaceAfterFunctionName": "BestPractice",
        },
    )
    body = r.json()
    return ("error" not in body, body.get("formatted", body.get("error", "")))

ok, formatted = check_dax("CALCULATE([Total Sales], DATESYTD('Date'[Date]))")
```

For an offline DAX parser, Tabular Editor 2's `-S` C# script switch can call `Microsoft.AnalysisServices.Tabular.DAXLexer` directly. Recipe in `references/tmdl-validation-recipes.md`.

## Lineage and Cross-Reference Validation

Beyond syntax and BPA, an agent generating a model should verify:

1. **Every measure references columns/measures that exist**
2. **Every `sortByColumn` resolves**
3. **Every relationship endpoint is a real column**
4. **Every PBIR bookmark `targetSection` exists in `pages.json`**
5. **Every PBIR drillthrough/tooltip `pageBinding` resolves**
6. **No circular relationships or measure references**

The simplest tool: **load the model with TmdlSerializer, then run** `model.Validate()` (TOM method) which returns `ValidationResult.Errors`. For PBIR, walk the JSON tree comparing `name` references against the page/visual inventory.

A complete cross-reference linter (Python, ~80 lines) lives in `references/pbir-validation-recipes.md`.

## CI Gate Pattern (GitHub Actions)

Minimum gate to put on every PR that touches a PBIP project:

```yaml
name: Power BI Validation Gate

on:
  pull_request:
    paths:
      - "**/*.tmdl"
      - "**/*.pbir"
      - "**/*.json"
      - "MyProject.SemanticModel/**"
      - "MyProject.Report/**"

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup .NET
        uses: actions/setup-dotnet@v4
        with:
          dotnet-version: '8.0'

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'

      - name: Install validators
        run: |
          pip install jsonschema fabric-cicd
          curl -L -o te2.zip https://github.com/TabularEditor/TabularEditor/releases/latest/download/TabularEditor.Portable.zip
          unzip te2.zip -d te2

      # Layer 1+2: TMDL parser + TOM schema
      - name: Validate TMDL syntax and metadata
        run: |
          mono te2/TabularEditor.exe "MyProject.SemanticModel/definition" -B "/tmp/check.bim"

      # Layer 3: BPA
      - name: Run BPA (fails on Error severity)
        run: |
          mono te2/TabularEditor.exe "MyProject.SemanticModel/definition" \
            -A "https://raw.githubusercontent.com/TabularEditor/BestPracticeRules/master/BPARules.json" \
            -V -G

      # Layer 1: PBIR JSON schemas
      - name: Validate PBIR schemas
        run: python ./scripts/validate_pbir.py "MyProject.Report/definition"

      # Layer 3: PBIR rules
      - name: Run PBI-InspectorV2
        run: |
          docker run --rm -v "$PWD:/work" natvang/pbi-inspector-v2:latest \
            -fabricitem /work/MyProject.Report \
            -rules /work/pbi-inspector-rules.json \
            -formats GitHub

      # fabric-cicd parameter.yml + structure
      - name: Validate fabric-cicd parameters
        run: python -m fabric_cicd.debug_parameterization --repository-directory . --environment prod
```

This gate runs in under 3 minutes for a typical PBIP and catches ~95% of issues that would otherwise fail at deploy time.

## Common Errors Catalog (What Each Tool Catches)

| Error Class | Caught by |
|-------------|-----------|
| Indentation / keyword typo in TMDL | `TmdlSerializer` (TmdlFormatException), Tabular Editor CLI `-B` |
| Unknown property on a TMDL object | `TmdlSerializer` (TmdlSerializationException) |
| Measure references undefined column | TOM `model.Validate()`, BPA, semantic-link-labs |
| sortByColumn points to missing column | TOM `model.Validate()`, BPA |
| DAX syntax error | DaxFormatter API, Tabular Editor (any deploy/load) |
| M syntax error | Power Query engine on first refresh; partial check via Tabular Editor `-S` |
| Implicit measures used | BPA `DAX_PERFORMANCE_AVOID_IMPLICIT_MEASURES` |
| Auto date/time enabled | BPA `MODEL_PERFORMANCE_DISABLE_AUTO_DATETIME` |
| Many-to-many relationship without explicit intent | BPA `MODEL_PRACTICE_AVOID_MANY_TO_MANY` |
| PBIR file fails JSON schema | `jsonschema` Python library, VS Code with `$schema` IntelliSense |
| PBIR visual missing required field | PBI-InspectorV2 `mustExist` rules |
| PBIR bookmark references deleted page | PBI-InspectorV2 lineage rule, custom Python linter |
| PBIR page count > 1000 | PBI-InspectorV2 `arrayLengthLessThan`, fabric-cicd at deploy |
| `parameter.yml` references unknown env | fabric-cicd built-in pre-deployment validation |
| Connection string still has dev GUID after parameterization | fabric-cicd `debug_parameterization.py` |
| Service principal lacks workspace role | Caught only at deploy -- no static check |

## What Validation CANNOT Catch (Run-Time Checks)

These categories require an actual deploy or refresh and cannot be statically validated:

- Data source credentials (gateway, Key Vault, OAuth tokens)
- Direct Lake fallback to DirectQuery under load
- DAX query timeouts on large data
- Refresh failures on source schema drift
- Visual rendering bugs in specific browsers
- Mobile layout overflow

For these, rely on Fabric Deployment Pipeline test stages, scheduled refresh alerts, and `semantic-link-labs.run_dax` smoke-test queries after deploy.

## Additional Resources

### Reference Files
- **`references/tmdl-validation-recipes.md`** -- Full TMDL validation cookbook: TmdlSerializer C# patterns, Python pythonnet wrapper, Tabular Editor C# scripts, INFO DAX introspection, offline parsing
- **`references/pbir-validation-recipes.md`** -- PBIR JSON schema validation, PBI-InspectorV2 rule examples, lineage cross-reference linter, GitHub Actions integration
- **`references/bpa-rules-reference.md`** -- The standard Microsoft BPA ruleset summary, rule authoring guide, severity strategy, and pinning recipes

### Related Skills
- **`powerbi-master:tmdl-mastery`** -- TMDL syntax reference (use this when generating TMDL; come back here to validate it)
- **`powerbi-master:programmatic-development`** -- PBIR generation (use this when generating PBIR; come back here to validate it)
- **`powerbi-master:performance-optimization`** -- For run-time validation via DAX Studio, VertiPaq Analyzer, Performance Analyzer

### Official 2026 References
- [TmdlSerializer Class (Microsoft Learn)](https://learn.microsoft.com/en-us/dotnet/api/microsoft.analysisservices.tabular.tmdlserializer)
- [TmdlFormatException Class (Microsoft Learn)](https://learn.microsoft.com/en-us/dotnet/api/microsoft.analysisservices.tabular.tmdl.tmdlformatexception)
- [Tabular Editor BPA documentation](https://docs.tabulareditor.com/common/using-bpa.html)
- [TabularEditor/BestPracticeRules (official Microsoft rule set)](https://github.com/TabularEditor/BestPracticeRules)
- [NatVanG/PBI-InspectorV2 (Fab Inspector)](https://github.com/NatVanG/PBI-InspectorV2)
- [semantic-link-labs Best Practice Analyzer](https://semantic-link-labs.readthedocs.io/en/stable/sempy_labs.html)
- [microsoft/json-schemas (PBIR official JSON schemas)](https://github.com/microsoft/json-schemas/tree/main/fabric/item/report/definition)
- [fabric-cicd parameterization](https://microsoft.github.io/fabric-cicd/latest/how_to/parameterization/)
