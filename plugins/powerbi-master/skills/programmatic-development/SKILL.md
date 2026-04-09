---
name: programmatic-development
description: |
  This skill should be used when the user asks about "create Power BI report programmatically",
  "PBIR format", "PBIR enhanced report format", "PBIR-Legacy vs PBIR", "PBIP developer mode",
  "Power BI project files", "TOM SDK", "Tabular Object Model", ".NET SDK for Power BI",
  "TMSL", "TMDL", "Tabular Editor scripting", "pbi-tools", "fabric-cicd", "Fabric CLI deploy",
  "fab deploy", "semantic-link-labs", "sempy", "Semantic Link", "generate pbix",
  "code-first Power BI", "semantic model from code", "ALM Toolkit", "Power BI external tools",
  "PBIP deployment", "parameter.yml",
  "TMDL basics (for detailed TMDL, load tmdl-mastery)",
  or "programmatic report generation".
---

# Programmatic Power BI Development

## Overview

Power BI supports multiple approaches for creating and managing reports and semantic models through code. As of 2026, the canonical stack is:

- **PBIP** (Power BI Project) as the folder-based source format
- **TMDL** as the semantic-model format inside PBIP (see `tmdl-mastery` skill)
- **PBIR** (Power BI Enhanced Report Format) as the report format inside PBIP
- **fabric-cicd** (Python) or **Fabric CLI `fab deploy`** for deployment
- **TOM / .NET SDK** for advanced programmatic model editing
- **semantic-link-labs** for Python-based scripting from Fabric notebooks

## PBIR - Power BI Enhanced Report Format

PBIR is Microsoft's modern, publicly documented, folder-based, JSON report format. It replaces the opaque `report.json` blob (now called PBIR-Legacy) with one file per visual, page, and bookmark, enabling proper Git diff/merge, code review, and schema-validated editing in VS Code.

### 2026 Rollout Timeline (as of April 2026)

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

### PBIP Project Structure (2026)

A PBIP project is a folder containing a `.pbip` entry file, one `*.Report/` folder, and one `*.SemanticModel/` folder (historically called `*.Dataset/`). The modern naming is **SemanticModel**; Desktop writes the new name by default.

```
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

### Definition.pbir -- byPath vs byConnection

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

Since PBIR files are schema-validated JSON, you can create or modify reports with any language. Every file includes a `$schema` URL pointing to the public JSON schema, so VS Code, PyCharm, and other editors provide full IntelliSense and validation while editing.

Common scenarios enabled by the file-per-object layout:
- Copy pages, visuals, or bookmarks between reports (file copy, no Desktop required)
- Batch-update a property across every visual (e.g., hide filter pane on all visuals)
- Script-generate entire pages from a data-driven template
- Find-and-replace field references across an entire report for a rename refactor

For complete Python examples (add page, batch update all visuals, copy visual between reports), see **`references/pbir-schema-reference.md`**.

### PBIR Annotations (Custom Deployment Metadata)

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

### Self-Validation of Generated PBIR

**Before committing or deploying any PBIR you've generated**, validate it locally. Every PBIR file embeds a `$schema` URL pointing to the official Microsoft schema in [microsoft/json-schemas](https://github.com/microsoft/json-schemas), which means standard JSON Schema validators (Python `jsonschema`, VS Code) catch syntax errors offline.

Three layers to run on every PBIR change:

1. **JSON schema** -- `python -m jsonschema` against each `*.json` file using the embedded `$schema` URL
2. **Rules** -- `PBI-InspectorV2` (Fab Inspector) v2.3+ runs the rules-based PBIR/PBIP validator with the `-fabricitem` switch and supports the new enhanced PBIR format (the original PBI-Inspector repo only handles PBIR-Legacy)
3. **Lineage** -- a custom Python walker that verifies bookmarks reference real pages, drillthrough targets exist, and theme files are present

For full recipes including a GitHub Actions CI gate template, see the **`powerbi-master:validation-testing`** skill.

### PBIR Limitations to Know

- **Large reports (>500 files)** can experience authoring performance issues in Desktop (viewing is not affected).
- **Filter pane must be expanded at least once** for automatic visual filters to persist to `visual.json`.
- **Bookmarks capture visual state** from the original page; copying a bookmark to a report without the source visuals drops invalid visual state.
- **pageBinding.name must be unique** across the report (used for drillthrough/tooltip pages). After June 2024, new `pageBinding` names are GUIDs by default to avoid collisions.
- **Renaming folders** requires a Desktop restart and preserves the original name on save unless you also update the `name` property inside the JSON.
- **Not supported in Template App workspaces.**

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

The .NET SDK for creating and managing semantic models programmatically via XMLA endpoint. Use TOM when you need low-level control over the model graph, custom CI/CD tooling, or integration with non-Python .NET applications.

### Setup

```bash
dotnet add package Microsoft.AnalysisServices.NetCore.retail.amd64
# .NET Framework alternative:
# Install-Package Microsoft.AnalysisServices.retail.amd64
```

### Quick Example: Modify an Existing Model

```csharp
using Microsoft.AnalysisServices.Tabular;

string conn = "DataSource=powerbi://api.powerbi.com/v1.0/myorg/Sales-Dev;" +
              "User ID=app:{clientId}@{tenantId};Password={secret};";

using var server = new Server();
server.Connect(conn);

var db = server.Databases.FindByName("SalesModel");
var model = db.Model;

model.Tables["Sales"].Measures.Add(new Measure() {
    Name = "YoY Growth",
    Expression = @"
        VAR Current = [Total Sales]
        VAR PY = CALCULATE([Total Sales], SAMEPERIODLASTYEAR('Date'[Date]))
        RETURN DIVIDE(Current - PY, PY)",
    FormatString = "0.00%"
});

model.SaveChanges();
```

For complete TOM patterns (creating models from scratch, relationships, RLS, OLS, partitions, incremental refresh, perspectives, translations, calculation groups, service principal auth, Azure AD token auth), see **`references/tom-advanced-patterns.md`**.

### Licensing Requirement

TOM requires XMLA read/write endpoint access: **Premium, PPU, or Fabric F-SKU capacity**.

### When to Pick TOM vs Alternatives

| Scenario | Use |
|----------|-----|
| .NET application or custom tooling | TOM |
| Python notebook inside Fabric | semantic-link-labs (wraps TOM) |
| TMDL folder deployment via CLI | Tabular Editor 2 `-D` switch |
| PBIP project deployment | fabric-cicd |
| Schema diff and selective deploy | ALM Toolkit |

## Tabular Editor

External tool for advanced semantic model development. Two editions:

| Feature | TE2 (Free) | TE3 (Paid) |
|---------|------------|------------|
| TOM object editing, C# scripting, BPA | Yes | Yes (enhanced IDE) |
| TMDL read/write | Yes (2.17+) | Full |
| DAX debugger, diagram view, advanced IntelliSense | No | Yes |
| Calculation group selection expressions | No | Yes |

**2025-2026 external-tool context:** As of June 2025, there are no longer any unsupported write operations for external tools in Desktop -- Tabular Editor, DAX Studio, and ALM Toolkit can freely modify any aspect of the model. The TMDL view (GA in Desktop) further expanded write support for objects that have no UI (calc groups, perspectives, translations, detail row expressions).

**C# script example -- auto-generate YTD measures:**

```csharp
foreach (var m in Model.AllMeasures.Where(m => m.DisplayFolder == "Revenue"))
{
    var ytd = m.Table.AddMeasure(
        m.Name + " YTD",
        $"CALCULATE({m.DaxObjectFullName}, DATESYTD('Date'[Date]))"
    );
    ytd.DisplayFolder = "Revenue\\YTD";
    ytd.FormatString = m.FormatString;
}
```

Tabular Editor 2 can deploy TMDL folders to XMLA endpoints via the `-D` command-line switch, making it a zero-code alternative to fabric-cicd for XMLA-based deployment. See `tmdl-mastery` skill references for full CLI examples.

## fabric-cicd (Python, 2026 Primary Deployment Tool)

`fabric-cicd` is Microsoft's **officially supported, open-source Python library** for deploying Fabric items (including PBIP projects) from source control to workspaces. It is the 2026-recommended path for PBIP deployment and is the engine behind the Fabric CLI `fab deploy` command.

**Key facts:**
- Package: `pip install fabric-cicd` (Python 3.9 - 3.13)
- Supports 24 item types, including `SemanticModel`, `Report`, `Notebook`, `DataPipeline`, `Dataflow`, `Lakehouse`, `Warehouse`, `Environment`, `VariableLibrary`
- Automatic dependency ordering (semantic models before reports; lakehouses before dependent notebooks)
- Parameterization via `parameter.yml` for environment-specific find-and-replace
- Orphan cleanup via `unpublish_all_orphan_items()`
- Authentication via Azure Identity SDK (`InteractiveBrowserCredential`, `AzureCliCredential`, `ClientSecretCredential`, `DefaultAzureCredential`, `ManagedIdentityCredential`)

### Minimal deploy.py

```python
import argparse
from azure.identity import InteractiveBrowserCredential, AzureCliCredential
from fabric_cicd import FabricWorkspace, publish_all_items, unpublish_all_orphan_items

parser = argparse.ArgumentParser()
parser.add_argument("--workspace_name", required=True)
parser.add_argument("--environment", default="dev")
parser.add_argument("--spn-auth", action="store_true")
parser.add_argument("--cleanup-orphans", action="store_true")
args = parser.parse_args()

credential = AzureCliCredential() if args.spn_auth else InteractiveBrowserCredential()

target = FabricWorkspace(
    workspace_name=args.workspace_name,
    environment=args.environment,
    repository_directory=".",
    item_type_in_scope=["SemanticModel", "Report"],
    token_credential=credential,
)

publish_all_items(target)
if args.cleanup_orphans:
    unpublish_all_orphan_items(target)
```

Deployment typically takes 20-30 seconds per item. The **first** deployment requires manually setting data-source credentials in the Fabric portal (`Workspace > Semantic Model > Settings > Data source credentials`); subsequent deployments reuse them.

### Environment Parameterization (parameter.yml)

Place `parameter.yml` at the project root. fabric-cicd find-and-replaces `find_value` with the environment-specific `replace_value` across all PBIP definition files before publishing:

```yaml
find_replace:
  - find_value: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"  # dev lakehouse GUID
    replace_value:
      dev:  "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
      prod: "cccccccc-cccc-cccc-cccc-cccccccccccc"
  - find_value: "sql-dev.database.windows.net"
    replace_value:
      dev:  "sql-dev.database.windows.net"
      prod: "sql-prod.database.windows.net"
```

fabric-cicd also supports `key_value_replace` with JSONPath for structured substitution and per-item filters (`item_type`, `item_name`, `file_path`).

### Service Principal Requirements

1. Tenant setting "Service principals can call Fabric public APIs" must be enabled in the Fabric admin portal
2. Service principal needs Contributor or Admin role on each target workspace
3. For Direct Lake models, the SP also needs at least Viewer on the source Lakehouse/Warehouse

For complete CI/CD workflow examples (GitHub Actions with OIDC federated credentials, Azure DevOps pipelines, multi-workspace deploy, pre/post hooks, troubleshooting), see **`references/fabric-cicd-recipes.md`**.

## Fabric CLI (fab) with fab deploy

Fabric CLI v1.5 (GA March 2026) introduced the **`fab deploy`** command, which wraps fabric-cicd as a single CLI operation. It accepts the same `parameter.yml` files you use with the Python library.

```bash
# Install
pip install ms-fabric-cli

# Authenticate (once)
fab auth login

# Deploy an entire workspace from a local repo
fab deploy \
  --source "./MyProject" \
  --workspace "Sales-Dev" \
  --environment dev \
  --item-types "SemanticModel,Report" \
  --cleanup-orphans

# Run from CI/CD with service principal
fab auth login \
  --tenant $TENANT_ID \
  --service-principal \
  --client-id $CLIENT_ID \
  --client-secret $CLIENT_SECRET
fab deploy --source . --workspace "Sales-Prod" --environment prod
```

The CLI also exposes lower-level item management:

```bash
fab ls /Sales-Dev/                                    # list workspace items
fab get /Sales-Dev/SalesModel.SemanticModel           # get item definition
fab import /Sales-Dev/SalesModel.Report ./report.pbir # import a single item
fab rm /Sales-Dev/OldReport.Report                    # delete an item
```

## Semantic Link / semantic-link-labs (Python)

For scripting semantic models from **Fabric notebooks** (no .NET toolchain required), use:

- **`semantic-link`** (SemPy) -- preinstalled in Fabric runtimes; read/query models, run DAX, use INFO functions
- **`semantic-link-labs`** (`sempy_labs`) -- Microsoft-maintained higher-level library with a TOM context-manager wrapper, BPA, Direct Lake helpers, and deployment APIs

Minimal TOM wrapper example:

```python
%pip install semantic-link-labs -q
from sempy_labs.tom import connect_semantic_model

with connect_semantic_model(dataset="SalesModel", workspace="Sales-Dev") as tom:
    tom.add_measure(
        table_name="Sales",
        measure_name="Sales Amount",
        expression="SUM(Sales[Amount])",
        format_string="$ #,##0.00",
        display_folder="Revenue",
    )
# Changes auto-saved on context exit
```

Also provides: `run_model_bpa`, `deploy_semantic_model`, `export_model_to_tmdl`, `update_direct_lake_model_connection`, `add_incremental_refresh_policy`, `set_rls`, `set_ols`, plus direct access to raw TOM via `tom.model`.

For complete semantic-link-labs recipes (calc groups, incremental refresh, RLS, OLS, Direct Lake, BPA CI gates, TMDL export/import, pythonnet fallback), see the **`powerbi-master:tmdl-mastery`** skill's `references/tmdl-programmatic-python.md`.

## pbi-tools

Open-source CLI for extracting, serializing, and compiling PBIX files for source control. Useful for **legacy PBIX workflows** when PBIP is not yet an option.

**2026 status:** pbi-tools gained TMDL support starting in `1.0.0-rc.3` and is considered stable for TMDL. Full PBIR support is still evolving -- for new projects, prefer native PBIP + fabric-cicd.

```bash
# Extract PBIX to source-control-friendly folder (supports TMDL output)
pbi-tools extract "Report.pbix" -modelFormat TMDL

# Compile back to PBIX
pbi-tools compile "Report/" -format PBIX -outPath "Report.pbix"

# Deploy to Power BI Service
pbi-tools deploy "Report/" -environment Production
```

**Extracted structure (with TMDL):**
```
Report/
├── .pbixproj.json          # Project settings
├── Model/                  # TMDL or JSON BIM (configurable)
│   ├── database.tmdl
│   └── tables/
├── Report/                 # Report layout (PBIR-Legacy JSON)
│   └── report.json
├── Mashup/                 # Power Query M code
│   └── Package/Formulas/
└── StaticResources/        # Images, custom visuals
```

**When to use pbi-tools vs fabric-cicd:**
- **pbi-tools:** Legacy PBIX files, Report Server, older workflows not yet on PBIP
- **fabric-cicd:** New PBIP projects, Fabric workspaces, production CI/CD (recommended)

## ALM Toolkit

Free tool for schema comparison between semantic models:

- Compare local model vs. published model
- Identify differences in tables, columns, measures, relationships
- Deploy changes selectively
- Works with XMLA endpoint (Premium/PPU/Fabric)

## Power BI Desktop Developer Features (2026)

### Developer Mode and Git Integration

As of 2026, PBIP save is GA in the Desktop UI. TMDL is the default semantic-model format inside new PBIP projects. PBIR is behind a preview feature toggle until the May 2026 Desktop release:

1. File > Options > Preview features > "Store reports using enhanced metadata format (PBIR)" (still required in April 2026; becomes default in May)
2. File > Save As > **Power BI Project (.pbip)**

**Git integration workflow:**
- Save as PBIP locally, commit to Git (TMDL and PBIR files are git-friendly)
- Fabric workspace > Settings > Git integration > connect to Azure DevOps or GitHub repo
- Feature branches for development, PR-based review, auto-sync on merge to main
- Fabric workspace sync is bidirectional: edits in the workspace Service can be committed back to the branch

**Important:** When connecting a Fabric workspace to Git, semantic models are now exported as **TMDL** (not TMSL/BIM). Reports are exported in whichever PBIR variant they currently use -- PBIR-Legacy for reports not yet upgraded, PBIR for upgraded reports.

### Enhanced Dataset Metadata (GA)

Enhanced metadata format stores semantic model information as text (TMDL) instead of the binary `model.bim`, enabling:
- Source-control friendly text-based format
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
| PBIR format | Preview features | Still required in April 2026; default in May |
| UDFs | Preview features | Enable DAX user-defined functions |
| Enhanced time intelligence | Preview features | Enable calendar-based week functions |

## Deployment Decision Matrix (2026)

| Scenario | Recommended Tool |
|----------|------------------|
| PBIP project with CI/CD (GitHub Actions / Azure DevOps) | `fabric-cicd` (Python) |
| Local ad-hoc deploy of a PBIP | `fab deploy` (Fabric CLI v1.5+) |
| Fabric notebook-based model editing | `semantic-link-labs` (sempy_labs) |
| Pure semantic model via XMLA | TOM (.NET) via `Microsoft.AnalysisServices.NetCore.retail.amd64` |
| TMDL folder -> XMLA | Tabular Editor 2 CLI (`-D` switch) |
| Legacy PBIX only (no PBIP) | `pbi-tools` |
| Cross-environment promotion (dev/test/prod) | Fabric Deployment Pipelines (GUI) OR `fabric-cicd` with `parameter.yml` |
| Schema diff between two models | ALM Toolkit |

## Additional Resources

### Reference Files
- **`references/pbir-schema-reference.md`** -- Complete PBIR JSON schema reference for visuals, pages, and report settings
- **`references/tom-advanced-patterns.md`** -- Advanced TOM patterns: relationships, RLS, partitions, perspectives, translations
- **`references/fabric-cicd-recipes.md`** -- Advanced fabric-cicd patterns: multi-workspace deployment, custom item ordering, hooks, environment parameter patterns, and troubleshooting

### Related Skills
- **`powerbi-master:tmdl-mastery`** -- Deep TMDL language reference and syntax
- **`powerbi-master:validation-testing`** -- Validate generated PBIR / TMDL / DAX before deploy: jsonschema, PBI-InspectorV2, TmdlSerializer, BPA, fabric-cicd parameter validation
- **`powerbi-master:rest-api-automation`** -- Raw Fabric REST API endpoints when fabric-cicd doesn't cover a scenario
- **`powerbi-master:deployment-admin`** -- Fabric Deployment Pipelines, workspace management, RLS at deploy time
- **`powerbi-master:fabric-integration`** -- Direct Lake, OneLake, Lakehouse/Warehouse integration

### Official Microsoft References (2026)
- [Deploy PBIP with fabric-cicd](https://learn.microsoft.com/en-us/power-bi/developer/projects/projects-deploy-fabric-cicd) -- End-to-end tutorial
- [Power BI enhanced report format (PBIR)](https://learn.microsoft.com/en-us/power-bi/developer/projects/projects-report) -- Complete folder structure and schema docs
- [Fabric CLI v1.5 GA](https://blog.fabric.microsoft.com/en-US/blog/fabric-cli-v1-5-is-here-generally-available/) -- `fab deploy` announcement
- [PBIR will become the default Power BI Report Format](https://powerbi.microsoft.com/en-us/blog/pbir-will-become-the-default-power-bi-report-format-get-ready-for-the-transition/) -- 2026 transition announcement
- [fabric-cicd GitHub](https://github.com/microsoft/fabric-cicd) -- Source and releases
- [fabric-cicd documentation](https://microsoft.github.io/fabric-cicd/latest/) -- Full API reference
- [semantic-link-labs GitHub](https://github.com/microsoft/semantic-link-labs) -- Python TOM wrapper
- [PBIR JSON schemas](https://github.com/microsoft/json-schemas/tree/main/fabric/item/report/definition) -- Public schemas for all PBIR files
