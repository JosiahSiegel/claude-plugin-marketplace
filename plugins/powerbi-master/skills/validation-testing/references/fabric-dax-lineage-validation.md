# Fabric CI/CD, DAX, and Lineage Validation

Focused recipes for fabric-cicd pre-deployment validation, DAX syntax validation without a server, and lineage / cross-reference validation. SKILL.md keeps core TMDL and PBIR validation layers; this reference holds adjacent validation checks.

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

