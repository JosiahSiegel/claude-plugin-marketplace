# PBIR Format Deep Dive

Reference for the Power BI Enhanced Report Format: rollout timeline, full project structure, byPath/byConnection references, annotations, validation, and limitations.

## 2026 Rollout Timeline (as of April 2026)

| Milestone | Date | Status |
|-----------|------|--------|
| PBIR public preview in Desktop | 2024 | Preview |
| PBIR default in Power BI Service (new reports) | January 25, 2026 | Rolling out |
| PBIR automatic upgrade of existing Service reports | January -- end of April 2026 | Rolling out (gradual, by report size -- reports with <100 visuals first) |
| PBIR default in Power BI Desktop | May 2026 release | Planned (delayed from March 2026) |
| PBIP (PBIR + TMDL) GA | 2026 | Planned |
| PBIR-Legacy deprecation | At PBIR GA | Planned ("PBIR-Legacy will no longer be supported") |

**Current state (April 2026):** PBIR is the default for all newly created reports in the Power BI Service. Existing Service reports are being auto-upgraded as they are edited. Power BI Desktop still requires the preview feature toggle, but that changes in the May 2026 release. PBIR-Legacy remains supported during the transition.

**Admin opt-out:** Tenants can temporarily opt out via the tenant setting "Automatically convert and store reports in the Power BI enhanced metadata format (PBIR)", but this opt-out will be removed at GA.

**Service restore:** When an existing report is auto-upgraded in the Service, a **PBIR-Legacy backup is retained for 28 days**. Restore via Report Settings > "Restore as PBIR-Legacy". Desktop upgrades keep a **30-day backup** in `%USERPROFILE%\AppData\Local\Microsoft\Power BI Desktop\TempSaves\Backups` (or the Store app equivalent).

**Sovereign Clouds:** PBIR will NOT be automatically upgraded in Sovereign Clouds prior to GA. Sovereign Cloud customers can still test PBIR via the Desktop preview feature.

**PBIR on Report Server:** Not supported. Report Server continues to use the legacy PBIX binary format only.

## PBIP Project Structure (2026)

A PBIP project is a folder containing a `.pbip` entry file, one `*.Report/` folder, and one `*.SemanticModel/` folder (historically called `*.Dataset/`). The modern naming is **SemanticModel**; Desktop writes the new name by default.

```text
MyProject.pbip                          # Entry file (JSON, double-click to open)
├── MyProject.Report/
│   ├── definition.pbir                # Required -- report definition entry
│   ├── definition/                    # PBIR folder (replaces legacy report.json)
│   │   ├── report.json                # Report-level settings, theme, filters
│   │   ├── version.json               # PBIR schema version
│   │   ├── reportExtensions.json      # Optional -- report-level measures
│   │   ├── pages/
│   │   │   ├── pages.json             # Page order and active page
│   │   │   ├── <pageName>/
│   │   │   │   ├── page.json          # Page metadata, filters
│   │   │   │   └── visuals/
│   │   │   │       └── <visualName>/
│   │   │   │           ├── visual.json     # Visual definition (query, formatting)
│   │   │   │           └── mobile.json     # Optional -- mobile layout override
│   │   └── bookmarks/
│   │       ├── bookmarks.json         # Bookmark order and groups
│   │       └── <bookmarkName>.bookmark.json
│   ├── CustomVisuals/                 # Private .pbiviz packages
│   ├── StaticResources/
│   │   └── RegisteredResources/       # Custom themes, images
│   ├── semanticModelDiagramLayout.json
│   ├── mobileState.json               # Report-level mobile state (not editable externally)
│   ├── .pbi/
│   │   └── localSettings.json         # User-specific, gitignored
│   └── .platform                      # Fabric Git integration system file
├── MyProject.SemanticModel/
│   ├── definition.pbism               # Required -- semantic model entry
│   ├── definition/                    # TMDL folder (replaces model.bim)
│   │   ├── database.tmdl
│   │   ├── model.tmdl
│   │   ├── relationships.tmdl
│   │   ├── expressions.tmdl
│   │   ├── tables/
│   │   │   └── *.tmdl
│   │   ├── roles/
│   │   ├── cultures/
│   │   └── perspectives/
│   ├── diagramLayout.json
│   └── .pbi/
│       ├── localSettings.json         # Gitignored
│       └── cache.abf                  # Gitignored (local data cache)
└── .gitignore
```

**Key points:**
- `definition.pbir` (singular, at report root) is required. `report.json` at the root is the **legacy** PBIR-Legacy file; `definition/report.json` is the **new** PBIR report-level settings file.
- `version.json` inside `definition/` declares the PBIR schema version.
- By default, PBIR folder names for pages/visuals/bookmarks are 20-character GUIDs like `90c2e07d8e84e7d5c026`. They can be renamed, but the object `name` property inside the JSON must remain unique; restart Desktop after renaming.
- For Fabric REST API deployment, `definition.pbir` must use a `byConnection` reference (not `byPath`) with a `connectionString` containing `semanticmodelid=<guid>`.
- PBIR supports up to **1,000 pages per report, 1,000 visuals per page, 300 MB per report** (service-enforced).

## Definition.pbir -- byPath vs byConnection

```json
{
  "$schema": "https://developer.microsoft.com/json-schemas/fabric/item/report/definitionProperties/2.0.0/schema.json",
  "version": "4.0",
  "datasetReference": {
    "byPath": { "path": "../MyProject.SemanticModel" }
  }
}
```

For remote (live-connect) semantic models, use `byConnection`. When deploying via the Fabric REST API, only the `semanticmodelid` is required:

```json
{
  "$schema": "https://developer.microsoft.com/json-schemas/fabric/item/report/definitionProperties/2.0.0/schema.json",
  "version": "4.0",
  "datasetReference": {
    "byConnection": {
      "connectionString": "semanticmodelid=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    }
  }
}
```

You can have **multiple `*.pbir` files** in the same Report folder (e.g., `definition.pbir` + `definition-liveConnect.pbir`). Fabric Git integration only processes `definition.pbir`; the others are preserved but ignored.

## PBIR Report JSON Schema

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

## Programmatic PBIR Manipulation

Since PBIR files are schema-validated JSON, you can create or modify reports with any language. Every file includes a `$schema` URL pointing to the public JSON schema, so VS Code, PyCharm, and other editors provide full IntelliSense and validation while editing.

Common scenarios enabled by the file-per-object layout:
- Copy pages, visuals, or bookmarks between reports (file copy, no Desktop required)
- Batch-update a property across every visual (e.g., hide filter pane on all visuals)
- Script-generate entire pages from a data-driven template
- Find-and-replace field references across an entire report for a rename refactor

For complete Python examples (add page, batch update all visuals, copy visual between reports), see `pbir-schema-reference.md`.

## PBIR Annotations (Custom Deployment Metadata)

You can embed name-value annotations inside `report.json`, `page.json`, or `visual.json`. Power BI Desktop ignores them, but deployment scripts can read them as configuration:

```json
{
  "$schema": "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/report/1.0.0/schema.json",
  "themeCollection": {
    "baseTheme": {"name": "CY24SU06", "type": "SharedResources"}
  },
  "annotations": [
    {"name": "defaultPage", "value": "c2d9b4b1487b2eb30e98"},
    {"name": "deploymentTier", "value": "production"},
    {"name": "owner", "value": "analytics-team@contoso.com"}
  ]
}
```

## Self-Validation of Generated PBIR

**Before committing or deploying any PBIR you've generated**, validate it locally. Every PBIR file embeds a `$schema` URL pointing to the official Microsoft schema in [microsoft/json-schemas](https://github.com/microsoft/json-schemas), which means standard JSON Schema validators (Python `jsonschema`, VS Code) catch syntax errors offline.

Three layers to run on every PBIR change:

1. **JSON schema** -- `python -m jsonschema` against each `*.json` file using the embedded `$schema` URL
2. **Rules** -- `PBI-InspectorV2` (Fab Inspector) v2.3+ runs the rules-based PBIR/PBIP validator with the `-fabricitem` switch and supports the new enhanced PBIR format (the original PBI-Inspector repo only handles PBIR-Legacy)
3. **Lineage** -- a custom Python walker that verifies bookmarks reference real pages, drillthrough targets exist, and theme files are present

For full recipes including a GitHub Actions CI gate template, see the `powerbi-master:validation-testing` skill.

## PBIR Limitations to Know

- **Large reports (>500 files)** can experience authoring performance issues in Desktop (viewing is not affected).
- **Filter pane must be expanded at least once** for automatic visual filters to persist to `visual.json`.
- **Bookmarks capture visual state** from the original page; copying a bookmark to a report without the source visuals drops invalid visual state.
- **pageBinding.name must be unique** across the report (used for drillthrough/tooltip pages). After June 2024, new `pageBinding` names are GUIDs by default to avoid collisions.
- **Renaming folders** requires a Desktop restart and preserves the original name on save unless you also update the `name` property inside the JSON.
- **Not supported in Template App workspaces.**
