# PBIR Validation Recipes

Complete cookbook for validating PBIR (Power BI Enhanced Report Format) at every layer: JSON schema, structural integrity, lineage cross-references, PBI-InspectorV2 rules, and CI integration. All recipes target the 2026 PBIR rollout (PBIR is the default in the Service from January 25, 2026 and in Desktop from May 2026).

## 1. Layer 1: JSON Schema Validation

Every PBIR file embeds a `$schema` URL pointing to the official Microsoft schema in [microsoft/json-schemas](https://github.com/microsoft/json-schemas/tree/main/fabric/item/report/definition). Use any JSON Schema validator to syntax-check files before they hit Fabric.

### 1a. Python validator with `jsonschema` (online schemas)

```python
import json
from pathlib import Path
import urllib.request
from jsonschema import Draft202012Validator

_SCHEMA_CACHE = {}

def fetch_schema(url: str) -> dict:
    if url not in _SCHEMA_CACHE:
        _SCHEMA_CACHE[url] = json.loads(urllib.request.urlopen(url).read())
    return _SCHEMA_CACHE[url]

def validate_pbir_file(pbir_file: Path) -> list[str]:
    doc = json.loads(pbir_file.read_text(encoding="utf-8"))
    schema_url = doc.get("$schema")
    if not schema_url:
        return [f"{pbir_file}: no $schema declared"]

    schema = fetch_schema(schema_url)
    validator = Draft202012Validator(schema)
    errors = sorted(validator.iter_errors(doc), key=lambda e: list(e.path))
    return [
        f"{pbir_file}#/{'/'.join(map(str, e.absolute_path))}: {e.message}"
        for e in errors
    ]

def validate_pbir_folder(report_root: Path) -> int:
    total_files = 0
    total_errors = []
    for f in report_root.rglob("*.json"):
        total_files += 1
        total_errors.extend(validate_pbir_file(f))

    if total_errors:
        print(f"FAIL: {len(total_errors)} schema violations across {total_files} files")
        for e in total_errors[:50]:
            print(f"  {e}")
        if len(total_errors) > 50:
            print(f"  ... {len(total_errors) - 50} more")
        return 1

    print(f"OK: validated {total_files} PBIR files")
    return 0

if __name__ == "__main__":
    import sys
    sys.exit(validate_pbir_folder(Path(sys.argv[1])))
```

Run with:

```bash
python validate_pbir.py "MyProject.Report/definition"
```

### 1b. Offline validator (CI without internet)

For air-gapped CI, clone the schemas once and resolve references locally.

```bash
git clone https://github.com/microsoft/json-schemas.git ./schemas
```

```python
import json
from pathlib import Path
from referencing import Registry, Resource
from jsonschema import Draft202012Validator

def build_local_registry(schemas_root: Path) -> Registry:
    registry = Registry()
    for schema_file in schemas_root.rglob("schema.json"):
        text = schema_file.read_text(encoding="utf-8")
        doc = json.loads(text)
        if "$id" in doc:
            registry = registry.with_resource(uri=doc["$id"], resource=Resource.from_contents(doc))
    return registry

REGISTRY = build_local_registry(Path("./schemas/fabric/item/report/definition"))

def validate_offline(pbir_file: Path) -> list[str]:
    doc = json.loads(pbir_file.read_text(encoding="utf-8"))
    schema_url = doc["$schema"]
    schema_resource = REGISTRY.get_or_retrieve(schema_url)
    validator = Draft202012Validator(schema_resource.value.contents, registry=REGISTRY)
    return [f"{pbir_file}: {e.message}" for e in validator.iter_errors(doc)]
```

### 1c. VS Code editor-time validation

VS Code already validates JSON against `$schema` URLs out of the box. To enforce explicit schema references for PBIR files, add to `.vscode/settings.json`:

```json
{
  "json.schemas": [
    {
      "fileMatch": ["**/visuals/*/visual.json"],
      "url": "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/visualContainer/1.0.0/schema.json"
    },
    {
      "fileMatch": ["**/pages/*/page.json"],
      "url": "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/page/1.0.0/schema.json"
    },
    {
      "fileMatch": ["**/definition/report.json"],
      "url": "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/report/1.0.0/schema.json"
    },
    {
      "fileMatch": ["**/definition.pbir"],
      "url": "https://developer.microsoft.com/json-schemas/fabric/item/report/definitionProperties/2.0.0/schema.json"
    }
  ]
}
```

Now every PBIR file gets red-squiggle validation while the developer types.

## 2. Layer 2: Structural Validation

Beyond per-file JSON schema, PBIR has structural rules that span multiple files. Catch these with a Python walker.

```python
from pathlib import Path
import json

def validate_pbir_structure(report_root: Path) -> list[str]:
    """
    Validates that a PBIR report folder has the required structure
    and that all required entry files exist.
    """
    errors = []
    definition = report_root / "definition"

    # Required entry files
    required = [
        report_root / "definition.pbir",
        definition / "report.json",
        definition / "version.json",
        definition / "pages" / "pages.json",
    ]
    for r in required:
        if not r.exists():
            errors.append(f"MISSING: {r}")

    # Every page folder must contain a page.json
    pages_dir = definition / "pages"
    if pages_dir.exists():
        for page_dir in pages_dir.iterdir():
            if page_dir.is_dir():
                page_json = page_dir / "page.json"
                if not page_json.exists():
                    errors.append(f"PAGE missing page.json: {page_dir}")

                # Every visual folder under the page must contain visual.json
                visuals_dir = page_dir / "visuals"
                if visuals_dir.exists():
                    for visual_dir in visuals_dir.iterdir():
                        if visual_dir.is_dir() and not (visual_dir / "visual.json").exists():
                            errors.append(f"VISUAL missing visual.json: {visual_dir}")

    # Every bookmark file must end with .bookmark.json
    bookmarks_dir = definition / "bookmarks"
    if bookmarks_dir.exists():
        for f in bookmarks_dir.glob("*.json"):
            if f.name == "bookmarks.json":
                continue
            if not f.name.endswith(".bookmark.json"):
                errors.append(f"BOOKMARK file must end with .bookmark.json: {f}")

    return errors
```

## 3. Layer 4: Lineage / Cross-Reference Linter

The linter that catches what JSON schema cannot: dangling page references in bookmarks, drillthrough targets that don't exist, theme files that aren't checked in.

```python
from pathlib import Path
import json
from collections import defaultdict

def lint_pbir_lineage(report_root: Path) -> list[str]:
    errors = []
    definition = report_root / "definition"
    pages_dir = definition / "pages"

    # Build inventory: page name -> page metadata
    pages_by_name: dict[str, dict] = {}
    visuals_by_name: dict[str, set[str]] = defaultdict(set)  # page_name -> set of visual names

    if pages_dir.exists():
        for page_dir in pages_dir.iterdir():
            if not page_dir.is_dir():
                continue
            page_json_path = page_dir / "page.json"
            if not page_json_path.exists():
                continue
            page_doc = json.loads(page_json_path.read_text(encoding="utf-8"))
            page_name = page_doc.get("name", page_dir.name)
            pages_by_name[page_name] = page_doc

            visuals_dir = page_dir / "visuals"
            if visuals_dir.exists():
                for visual_dir in visuals_dir.iterdir():
                    if visual_dir.is_dir() and (visual_dir / "visual.json").exists():
                        v_doc = json.loads((visual_dir / "visual.json").read_text(encoding="utf-8"))
                        visuals_by_name[page_name].add(v_doc.get("name", visual_dir.name))

    # Check bookmarks reference real pages and visuals
    bookmarks_dir = definition / "bookmarks"
    if bookmarks_dir.exists():
        for bm_file in bookmarks_dir.glob("*.bookmark.json"):
            bm = json.loads(bm_file.read_text(encoding="utf-8"))
            target_page = bm.get("targetSection") or bm.get("displayName")
            if target_page and target_page not in pages_by_name:
                errors.append(f"BOOKMARK '{bm_file.name}' targets missing page '{target_page}'")

            # Check children (visual states)
            for child in bm.get("children", []):
                child_page = child.get("targetSection")
                if child_page and child_page not in pages_by_name:
                    errors.append(f"BOOKMARK '{bm_file.name}' child targets missing page '{child_page}'")

    # Check drillthrough / tooltip pageBindings
    for page_name, page_doc in pages_by_name.items():
        for binding in page_doc.get("pageBindings", []):
            target = binding.get("name")
            if target and target not in pages_by_name:
                errors.append(f"PAGE '{page_name}' pageBinding targets missing page '{target}'")

    # Check report.json defaultPage annotation
    report_json = definition / "report.json"
    if report_json.exists():
        rj = json.loads(report_json.read_text(encoding="utf-8"))
        for ann in rj.get("annotations", []):
            if ann.get("name") == "defaultPage":
                if ann["value"] not in pages_by_name:
                    errors.append(f"report.json defaultPage annotation points to missing page '{ann['value']}'")

    # Check theme references resolve to RegisteredResources
    static_resources = report_root / "StaticResources" / "RegisteredResources"
    if report_json.exists():
        rj = json.loads(report_json.read_text(encoding="utf-8"))
        for theme_loc in ("baseTheme", "customTheme"):
            theme = rj.get("themeCollection", {}).get(theme_loc)
            if theme and theme.get("type") == "RegisteredResources":
                resource_name = theme.get("name", "")
                # Resource files use a UUID prefix; check by suffix
                if static_resources.exists():
                    matches = list(static_resources.glob(f"*{resource_name}*"))
                    if not matches:
                        errors.append(f"Theme references missing RegisteredResource: {resource_name}")

    return errors
```

This catches the four most common PBIR lineage breakages:
1. Bookmark targets a deleted page
2. Drillthrough pageBinding targets a deleted page
3. defaultPage annotation references a deleted page
4. Theme references a missing static resource file

## 4. PBI-InspectorV2 (Fab Inspector) Rules

PBI-InspectorV2 is the canonical rules-based PBIR validator. v2.3+ supports the enhanced PBIR format and all Fabric item types via the `-fabricitem` switch. The original `PBI-Inspector` repo is **PBIR-Legacy only** -- always use v2 for new work.

### 4a. Install and run

```bash
# Native binary (recommended for CI speed)
curl -L -o pbi-inspector.zip https://github.com/NatVanG/PBI-InspectorV2/releases/latest/download/PBIInspectorCLI-linux-x64.zip
unzip pbi-inspector.zip -d ./pbi-inspector
chmod +x ./pbi-inspector/PBIInspectorCLI

# Run against a PBIR folder
./pbi-inspector/PBIInspectorCLI \
    -fabricitem "./MyProject.Report" \
    -rules "./pbi-inspector-rules.json" \
    -formats "GitHub,JSON,HTML" \
    -output "./inspector-results"

# Or via Docker
docker run --rm -v "$PWD:/work" natvang/pbi-inspector-v2:latest \
    -fabricitem /work/MyProject.Report \
    -rules /work/pbi-inspector-rules.json \
    -formats GitHub
```

Exit codes:
- `0` = all rules passed
- `1` = warnings only
- `2` = at least one Error-severity rule failed (should fail CI)

### 4b. Starter rule set

Save as `pbi-inspector-rules.json` and customize:

```json
{
  "Description": "Contoso PBIR baseline rules",
  "Version": "1.0",
  "Rules": [
    {
      "Name": "All visuals must have a title",
      "Description": "Every visual on every page should have a title for accessibility",
      "LogType": "Error",
      "FileType": "VisualJSON",
      "Path": "$.visual.objects.title[0].properties.show.expr.Literal.Value",
      "Test": [{"isEqualTo": "true"}]
    },
    {
      "Name": "Page count must not exceed Fabric limit",
      "Description": "PBIR service limit is 1000 pages per report",
      "LogType": "Error",
      "FileType": "PagesJSON",
      "Path": "$.pageOrder",
      "Test": [{"arrayLengthLessThan": 1000}]
    },
    {
      "Name": "Visuals per page must not exceed Fabric limit",
      "Description": "PBIR service limit is 1000 visuals per page",
      "LogType": "Error",
      "FileType": "PageJSON",
      "Path": "$.visualContainers",
      "Test": [{"arrayLengthLessThan": 1000}]
    },
    {
      "Name": "No PBIR-Legacy report.json at root",
      "Description": "Reports must be in PBIR enhanced format only",
      "LogType": "Error",
      "FileType": "Report",
      "Path": "$.report.json",
      "Test": [{"mustNotExist": true}]
    },
    {
      "Name": "Custom visuals must be approved",
      "Description": "Only allowlisted custom visuals are allowed",
      "LogType": "Error",
      "FileType": "VisualJSON",
      "Path": "$.visual.visualType",
      "Test": [
        {"isOneOf": [
          "barChart","columnChart","pieChart","tableEx","matrix","slicer","textbox",
          "card","multiRowCard","kpi","actionButton","image","shape",
          "ApprovedVisual_AcmeBars","ApprovedVisual_AcmeMaps"
        ]}
      ]
    },
    {
      "Name": "Drillthrough pages must be hidden",
      "Description": "Pages used only for drillthrough should not appear in nav",
      "LogType": "Warning",
      "FileType": "PageJSON",
      "Path": "$",
      "Test": [
        {"if": {"path": "$.filters[?(@.type=='Drillthrough')]", "exists": true}},
        {"then": {"path": "$.visibility", "isEqualTo": 1}}
      ]
    }
  ]
}
```

The `Test` array supports many predicates: `isEqualTo`, `isGreaterThan`, `isLessThan`, `mustExist`, `mustNotExist`, `regex`, `isOneOf`, `arrayLengthLessThan`, `arrayLengthGreaterThan`, `if/then`. See the full list at [PBI-InspectorV2 README](https://github.com/NatVanG/PBI-InspectorV2#rules-format).

### 4c. Disabling rules without deleting

```json
{ "Name": "Slow rule we don't care about right now", "Disabled": true, "..." }
```

The `Disabled: true` flag is the recommended way to suppress a rule temporarily without losing the definition.

## 5. fabric-cicd Pre-Deployment Validation

`fabric-cicd` runs **automatic parameter.yml validation** at the start of every deployment. If `parameter.yml` is missing keys, references unknown environments, or contains malformed YAML, the deployment **fails before any item is published**. This is the cheapest possible CI safety net.

### 5a. Run validation without deploying

```bash
python -m fabric_cicd.devtools.debug_parameterization \
    --repository-directory ./MyProject \
    --environment prod \
    --item-type-in-scope SemanticModel,Report
```

This parses every `*.tmdl`, `*.json`, and `*.pbir` file, applies the `find_replace` and `key_value_replace` transformations, and reports any:
- Unresolved placeholders (e.g., `find_value: "$dev_lakehouse_id"` with no environment-specific replacement)
- YAML syntax errors in `parameter.yml`
- Mismatched environment names (parameter.yml says `prod`, CLI says `production`)
- Empty `replace_value` blocks

### 5b. Use it in CI on every PR

```yaml
- name: Validate fabric-cicd parameters
  run: |
    pip install fabric-cicd
    python -m fabric_cicd.devtools.debug_parameterization \
      --repository-directory . \
      --environment prod \
      --item-type-in-scope SemanticModel,Report
```

Run this on every PR -- not just deployment branches -- so parameter drift is caught at PR review time, not at 3 AM during a release.

## 6. PBIR Visual Type Allowlisting

A specific PBIR linter pattern that catches unapproved custom visuals. Useful in regulated environments where only certain visuals are allowed.

```python
from pathlib import Path
import json

ALLOWED_VISUALS = {
    # Built-ins
    "barChart", "columnChart", "lineChart", "areaChart", "pieChart", "donutChart",
    "tableEx", "matrix", "card", "multiRowCard", "kpi", "slicer", "textbox",
    "actionButton", "image", "shape", "gauge", "scatterChart", "treemap",
    # Approved custom visuals
    "Acme.PowerBI.Visuals.ApprovedBarChart",
    "Microsoft.PowerBI.SankeyDiagram",
}

def lint_visual_types(report_root: Path) -> list[str]:
    errors = []
    for visual_json in (report_root / "definition" / "pages").rglob("visual.json"):
        v = json.loads(visual_json.read_text(encoding="utf-8"))
        vtype = v.get("visual", {}).get("visualType", "")
        if vtype and vtype not in ALLOWED_VISUALS:
            errors.append(f"UNAPPROVED visual type '{vtype}' in {visual_json}")
    return errors
```

## 7. Combined PBIR Validation Pre-Commit Hook

```bash
#!/usr/bin/env bash
set -e

# Find all PBIR JSON files in the staging area
CHANGED_PBIR=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(pbir|json)$' | grep -E '(definition|Report)/' || true)

if [ -z "$CHANGED_PBIR" ]; then
    exit 0
fi

# Layer 1: JSON Schema
python ./scripts/validate_pbir.py "MyProject.Report/definition" || {
    echo "PBIR schema validation FAILED. Fix and recommit."
    exit 1
}

# Layer 2+4: Structure + Lineage
python ./scripts/lint_pbir_lineage.py "MyProject.Report" || {
    echo "PBIR lineage check FAILED. Fix and recommit."
    exit 1
}

# Layer 3: PBI-InspectorV2 (errors block; warnings allowed)
./pbi-inspector/PBIInspectorCLI \
    -fabricitem "./MyProject.Report" \
    -rules "./pbi-inspector-rules.json" \
    -formats GitHub
INSPECTOR_EXIT=$?
if [ $INSPECTOR_EXIT -eq 2 ]; then
    echo "PBI-InspectorV2 ERROR severity rules failed. Fix and recommit."
    exit 1
fi

echo "PBIR validation passed."
exit 0
```

## 8. Common PBIR Validation Failures

| Symptom | Cause | Fix |
|---------|-------|-----|
| `$schema not found` | File missing `$schema` URL | Add the appropriate `$schema` for the file type |
| `additionalProperties not allowed: 'X'` | Hand-edited file uses a property that doesn't exist on the schema | Check schema URL for valid properties; remove the unknown one |
| Bookmark targets missing page | Page deleted but bookmark not updated | Delete the bookmark or recreate the page |
| `pageBinding name not unique` | Two drillthrough pages have the same `pageBinding.name` | Rename one (use a GUID for uniqueness) |
| Visual won't render after PBIR conversion | Missing `query.queryState` after manual edit | Reload from a known-good version; never hand-edit `queryState` |
| `Report has more than 1000 pages` (deploy time) | Service-enforced limit | Split into multiple reports OR archive old pages |
| Bookmarks group references orphaned bookmark | Bookmark file deleted but `bookmarks.json` not updated | Run lineage linter to find and remove the orphan reference |
| Theme not applied after deployment | RegisteredResource file missing or not committed to Git | Verify the file exists in `StaticResources/RegisteredResources/` |
| `definition.pbir` rejected by Fabric Git | Schema version too low | Update to `version: "4.0"` |
| `definition.pbir` byPath doesn't resolve | Relative path wrong (case sensitivity on Linux runners) | Use `./MyProject.SemanticModel` (forward slash, exact case) |
