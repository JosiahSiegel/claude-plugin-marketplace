# Tooling: TOM, Tabular Editor, fabric-cicd, Fabric CLI, semantic-link, pbi-tools, ALM Toolkit

Reference for the full Power BI programmatic tooling stack: when to pick each tool, setup, and usage examples.

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

For complete TOM patterns (creating models from scratch, relationships, RLS, OLS, partitions, incremental refresh, perspectives, translations, calculation groups, service principal auth, Azure AD token auth), see `tom-advanced-patterns.md`.

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

### C# Script Example: Auto-Generate YTD Measures

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

For complete CI/CD workflow examples (GitHub Actions with OIDC federated credentials, Azure DevOps pipelines, multi-workspace deploy, pre/post hooks, troubleshooting), see `fabric-cicd-recipes.md`.

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

For complete semantic-link-labs recipes (calc groups, incremental refresh, RLS, OLS, Direct Lake, BPA CI gates, TMDL export/import, pythonnet fallback), see the `powerbi-master:tmdl-mastery` skill's `references/tmdl-programmatic-python.md`.

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

```text
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
