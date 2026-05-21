# Power BI Validation CI Gates and Error Catalog

GitHub Actions CI gate patterns, common validation errors mapped to the tool that catches them (TMDL parser, Tabular Editor BPA, PBIR schema validation, PBI-InspectorV2 / Fab Inspector), and a concise list of runtime issues that static validation cannot catch. SKILL.md keeps the toolchain overview and per-layer validation entry points; this reference holds CI wiring and troubleshooting lookup material.

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

