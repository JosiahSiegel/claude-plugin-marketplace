# fabric-cicd Advanced Recipes (2026)

Production-grade patterns for deploying Power BI Projects (PBIP) and other Fabric items using `fabric-cicd` -- Microsoft's officially supported Python library for Fabric deployment. This reference complements the SKILL.md quick start and covers multi-environment deployment, dependency ordering, hooks, and troubleshooting.

## Library Overview

```bash
pip install fabric-cicd
```

- **Python support:** 3.9 - 3.13
- **Supported item types (24):** ApacheAirflowJob, CopyJob, DataAgent, DataPipeline, Dataflow, Environment, Eventhouse, Eventstream, GraphQLApi, KQLDashboard, KQLDatabase, KQLQueryset, Lakehouse, MirroredDatabase, MLExperiment, MountedDataFactory, Notebook, Reflex, Report, SemanticModel, SparkJobDefinition, SQLDatabase, UserDataFunction, VariableLibrary, Warehouse
- **Base deployment model:** full deployment every run (no commit diff calculation)
- **Dependencies handled automatically:** SemanticModel deploys before Report; Lakehouse before Notebook that references it
- **Tenant-scoped:** deploys into the tenant of the executing identity

## Core API

```python
from fabric_cicd import (
    FabricWorkspace,
    publish_all_items,
    unpublish_all_orphan_items,
    append_feature_flag,  # experimental feature toggles
)
```

### FabricWorkspace constructor

| Parameter | Type | Description |
|-----------|------|-------------|
| `workspace_name` or `workspace_id` | str | Target workspace -- name or GUID (one required) |
| `repository_directory` | str | Path to the PBIP/source folder |
| `item_type_in_scope` | list[str] | Item types to deploy (e.g., `["SemanticModel", "Report"]`) |
| `environment` | str | Environment key used to resolve `parameter.yml` (e.g., `"dev"`, `"prod"`) |
| `token_credential` | TokenCredential | Azure Identity credential (optional -- defaults to DefaultAzureCredential) |
| `base_api_url` | str | Override Fabric API base URL (for Sovereign Clouds) |

### Publish and cleanup

```python
publish_all_items(target_workspace)
unpublish_all_orphan_items(target_workspace, item_name_exclude_regex=r".*_keep$")
```

`unpublish_all_orphan_items` removes workspace items that no longer exist in the repo. Use `item_name_exclude_regex` to protect items that should never be auto-deleted.

## Authentication Patterns

### Interactive Browser (local dev)

```python
from azure.identity import InteractiveBrowserCredential
credential = InteractiveBrowserCredential()
```

### Azure CLI (local dev after `az login`)

```python
from azure.identity import AzureCliCredential
credential = AzureCliCredential()
```

### Service Principal (CI/CD)

```python
import os
from azure.identity import ClientSecretCredential

credential = ClientSecretCredential(
    tenant_id=os.environ["AZURE_TENANT_ID"],
    client_id=os.environ["AZURE_CLIENT_ID"],
    client_secret=os.environ["AZURE_CLIENT_SECRET"],
)
```

### GitHub OIDC Federated Credentials (CI/CD, keyless)

```python
# No client secret needed -- GitHub Actions provides an OIDC token
from azure.identity import DefaultAzureCredential
credential = DefaultAzureCredential()
```

In the GitHub Actions workflow, configure `azure/login@v2` with a service principal that has a federated identity credential linked to the repo. This avoids storing secrets entirely.

### Managed Identity (Azure-hosted runners)

```python
from azure.identity import ManagedIdentityCredential
credential = ManagedIdentityCredential()
```

## parameter.yml Deep Dive

The `parameter.yml` file lives in `repository_directory` and supports two replacement modes:

### 1. find_replace (text substitution)

Substitutes literal strings anywhere in PBIP definition files:

```yaml
find_replace:
  - find_value: "sql-dev.database.windows.net"
    replace_value:
      dev:  "sql-dev.database.windows.net"
      test: "sql-test.database.windows.net"
      prod: "sql-prod.database.windows.net"
    item_type:
      - SemanticModel
    item_name:
      - SalesModel
    file_path:
      - "SalesModel.SemanticModel/definition/expressions.tmdl"
```

Optional filters narrow the scope of replacement:
- `item_type` -- only in specified item types
- `item_name` -- only in specified items by name
- `file_path` -- only in specified files (glob supported)

### 2. key_value_replace (structured JSON/YAML)

For structured replacements like Direct Lake connection GUIDs:

```yaml
key_value_replace:
  - find_key: "$.datasetReference.byConnection.connectionString"
    replace_value:
      dev:  "semanticmodelid=dev-guid"
      prod: "semanticmodelid=prod-guid"
    item_type:
      - Report
    file_path:
      - "*.Report/definition.pbir"
```

`find_key` is a JSONPath expression.

### Built-in fabric-cicd tokens

Some special tokens get auto-resolved by the library:

```yaml
find_replace:
  - find_value: "$workspace_id"
    replace_value:
      dev:  "{{TARGET_WORKSPACE_ID}}"  # replaced with actual target workspace GUID
      prod: "{{TARGET_WORKSPACE_ID}}"
```

## Multi-Workspace Deployment

Deploy the same source to multiple workspaces (e.g., per business unit) in one run:

```python
from fabric_cicd import FabricWorkspace, publish_all_items

workspaces = [
    ("BU1-Sales-Dev", "bu1_dev"),
    ("BU2-Sales-Dev", "bu2_dev"),
    ("BU3-Sales-Dev", "bu3_dev"),
]

for ws_name, env_name in workspaces:
    print(f"Deploying to {ws_name}...")
    target = FabricWorkspace(
        workspace_name=ws_name,
        environment=env_name,
        repository_directory=".",
        item_type_in_scope=["SemanticModel", "Report"],
        token_credential=credential,
    )
    publish_all_items(target)
```

Keep each environment's overrides in the same `parameter.yml` under different environment keys.

## Selective Deployment by Item Type

Deploy only semantic models (skip reports):

```python
target = FabricWorkspace(
    workspace_name="Sales-Dev",
    environment="dev",
    repository_directory=".",
    item_type_in_scope=["SemanticModel"],  # Reports not deployed
    token_credential=credential,
)
publish_all_items(target)
```

Deploy only specific items by name:

```python
from fabric_cicd import publish_all_items

publish_all_items(
    target,
    items_to_include=["SalesModel", "SalesOverview"],  # Name filter
)
```

## Experimental Feature Flags

Enable preview features via `append_feature_flag`:

```python
from fabric_cicd import append_feature_flag

append_feature_flag("enable_shortcut_publish")       # Lakehouse shortcuts
append_feature_flag("disable_print_diff")             # Suppress diff output
append_feature_flag("enable_experimental_items")      # Allow items not yet in supported list
```

## Pre/Post Hooks via Wrapper Functions

fabric-cicd does not expose native hooks, but you can wrap `publish_all_items` to run arbitrary Python before and after:

```python
def run_bpa_before_deploy(workspace, dataset):
    import sempy_labs as labs
    results = labs.run_model_bpa(dataset=dataset, workspace=workspace)
    errors = results[results["Severity"] == "Error"]
    if len(errors) > 0:
        display(errors)
        raise RuntimeError(f"BPA blocked: {len(errors)} error-severity rules")

def refresh_after_deploy(workspace, dataset):
    import sempy.fabric as fabric
    fabric.refresh_dataset(dataset=dataset, workspace=workspace, refresh_type="Full")

# Wrap
run_bpa_before_deploy("Sales-Dev", "SalesModel")
publish_all_items(target_workspace)
refresh_after_deploy("Sales-Prod", "SalesModel")
```

## Dependency Ordering

fabric-cicd automatically orders deployments based on known dependencies:

1. **Lakehouse** -> Notebooks/SemanticModels that reference it
2. **Warehouse** -> Dataflows/SemanticModels
3. **SemanticModel** -> Reports
4. **Environment** -> Notebooks/Spark jobs that use it
5. **VariableLibrary** -> Items that reference its variables

For custom ordering (e.g., Dataflow Gen2 that must exist before a semantic model), split into two `publish_all_items` calls:

```python
# Stage 1: Foundation
stage1 = FabricWorkspace(..., item_type_in_scope=["Lakehouse", "Dataflow", "Warehouse"])
publish_all_items(stage1)

# Stage 2: Semantic models that depend on foundation
stage2 = FabricWorkspace(..., item_type_in_scope=["SemanticModel"])
publish_all_items(stage2)

# Stage 3: Reports that depend on semantic models
stage3 = FabricWorkspace(..., item_type_in_scope=["Report"])
publish_all_items(stage3)
```

## GitHub Actions with Federated Credentials (Keyless)

Recommended production pattern -- no secrets stored in GitHub:

```yaml
name: Deploy PBIP (OIDC)

on:
  push:
    branches: [main]

permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: '3.12' }

      - name: Azure Login (OIDC)
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          allow-no-subscriptions: true

      - name: Install fabric-cicd
        run: pip install fabric-cicd

      - name: Deploy
        run: |
          python - <<'PY'
          from azure.identity import AzureCliCredential
          from fabric_cicd import FabricWorkspace, publish_all_items, unpublish_all_orphan_items

          target = FabricWorkspace(
              workspace_name="Sales-Prod",
              environment="prod",
              repository_directory=".",
              item_type_in_scope=["SemanticModel", "Report"],
              token_credential=AzureCliCredential(),
          )
          publish_all_items(target)
          unpublish_all_orphan_items(target)
          PY
```

Configure federated credentials on the service principal in Azure AD:
- Issuer: `https://token.actions.githubusercontent.com`
- Subject: `repo:org/repo:ref:refs/heads/main` (or `environment:production` for environment-scoped)
- Audience: `api://AzureADTokenExchange`

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `401 Unauthorized` on deploy | Service principal missing workspace role | Add SP as Contributor/Admin to workspace |
| `403 Forbidden: service principals not enabled` | Tenant setting disabled | Enable "Service principals can call Fabric public APIs" in Admin portal |
| Semantic model deploys but report fails with "dataset not found" | byConnection reference uses wrong semantic model GUID | Either let fabric-cicd resolve `byPath`, or update `parameter.yml` to replace the GUID |
| Deployment hangs on large semantic model | Item import timeout | Split model into smaller sub-models or use Tabular Editor CLI with XMLA endpoint directly |
| `parameter.yml` substitution not applied | Environment key typo | Ensure `environment` parameter matches a key under `replace_value` exactly |
| Orphan cleanup deletes items unexpectedly | Missing items in repo | Use `item_name_exclude_regex` to protect; or avoid `unpublish_all_orphan_items` entirely |
| Direct Lake model loses connection after deploy | Source lakehouse/warehouse GUID not parameterized | Add `find_replace` or `key_value_replace` entries for lakehouse GUIDs |
| `ModuleNotFoundError: No module named 'fabric_cicd'` | Wrong Python environment | Pin Python 3.12 in workflow; use `pip install --upgrade fabric-cicd` |
| Data source credentials prompt after every deploy | First-deploy behavior | Set credentials once in Fabric portal; subsequent deploys reuse them |
| `403 FabricItemNotAuthorized` on Direct Lake | SP missing Viewer role on Lakehouse | Grant SP at least Viewer on the source Lakehouse/Warehouse |
| `CannotOverwriteModifiedItem` error | Item edited in Service since last deploy | Either force overwrite (via feature flag), or commit Service changes back to Git first |

## Comparison: fabric-cicd vs Fabric Deployment Pipelines vs Manual REST

| Feature | fabric-cicd | Fabric Deployment Pipelines (GUI) | Raw REST API |
|---------|-------------|-----------------------------------|--------------|
| Source of truth | Git repo | Dev workspace | Your own |
| Parameterization | `parameter.yml` | Rules engine (GUI) | Custom |
| Multi-item dependencies | Auto-resolved | Auto-resolved | Manual |
| Audit trail | Git history | Fabric portal | Custom |
| Authentication | Azure Identity | User/SP | User/SP |
| Orphan cleanup | Built-in | Manual | Custom |
| Python/CI friendly | Yes | Limited (REST API only) | Yes |
| Zero-code option | No | Yes | No |
| Best for | Code-first teams | Citizen developers | Custom tooling |

## References

- [fabric-cicd documentation](https://microsoft.github.io/fabric-cicd/latest/)
- [fabric-cicd GitHub](https://github.com/microsoft/fabric-cicd)
- [fabric-cicd on PyPI](https://pypi.org/project/fabric-cicd/)
- [Deploy PBIP with fabric-cicd (Microsoft Learn)](https://learn.microsoft.com/en-us/power-bi/developer/projects/projects-deploy-fabric-cicd)
- [Fabric CLI v1.5 GA (deploy command)](https://blog.fabric.microsoft.com/en-US/blog/fabric-cli-v1-5-is-here-generally-available/)
