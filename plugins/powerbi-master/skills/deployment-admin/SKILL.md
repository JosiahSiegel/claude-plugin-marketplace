---
name: deployment-admin
description: |
  This skill should be used when the user asks about "Power BI deployment pipeline",
  "CI/CD for Power BI", "GitHub Actions Power BI", "Azure DevOps Power BI",
  "workspace management", "row-level security", "RLS", "object-level security",
  "OLS", "capacity management", "Premium", "PPU", "Fabric SKU",
  "tenant settings", "governance", "Power BI Report Server",
  "service principal setup", or "Power BI administration".
---

# Deployment and Administration

## Overview

Power BI deployment spans from development to production across workspaces, capacities, and environments. This skill covers deployment pipelines, CI/CD automation, security configuration, capacity management, and governance best practices.

## Deployment Pipelines

Built-in Power BI feature for promoting content through environments:

| Stage | Purpose | Typical Use |
|-------|---------|-------------|
| Development | Build and iterate | Developers test changes |
| Test | Validation | QA reviews, user acceptance |
| Production | End users | Live reports and dashboards |

**Requirements:** Premium, PPU, or Fabric capacity on all stage workspaces.

**Deployment rules:**
- Content types deployed: reports, semantic models, dataflows, paginated reports
- Parameterization rules handle environment-specific values (server names, databases)
- Backward deployment (prod to dev) is supported but use with caution
- Auto-bind connects deployed reports to the correct semantic model in each stage

### Pipeline Automation via REST API

```bash
# Get deployment pipelines
GET https://api.powerbi.com/v1.0/myorg/pipelines

# Deploy all content from stage 0 (Dev) to stage 1 (Test)
POST https://api.powerbi.com/v1.0/myorg/pipelines/{pipelineId}/deployAll
{
  "sourceStageOrder": 0,
  "options": {
    "allowOverwriteArtifact": true,
    "allowCreateArtifact": true,
    "allowOverwriteTargetArtifactLabel": true
  },
  "note": "Automated deployment from CI/CD"
}
```

## CI/CD with GitHub Actions

### PBIP-Based Deployment

```yaml
name: Power BI Deploy
on:
  push:
    branches: [main]
    paths: ['reports/**']

permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Azure Login (Service Principal)
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Get Access Token
        id: token
        run: |
          TOKEN=$(az account get-access-token \
            --resource https://analysis.windows.net/powerbi/api \
            --query accessToken -o tsv)
          echo "::add-mask::$TOKEN"
          echo "token=$TOKEN" >> $GITHUB_OUTPUT

      - name: Deploy via Fabric REST API
        run: |
          # Import PBIP to workspace using Fabric Git integration
          # or use deployment pipeline API
          curl -X POST \
            "https://api.powerbi.com/v1.0/myorg/pipelines/${{ secrets.PIPELINE_ID }}/deployAll" \
            -H "Authorization: Bearer ${{ steps.token.outputs.token }}" \
            -H "Content-Type: application/json" \
            -d '{
              "sourceStageOrder": 0,
              "options": {
                "allowOverwriteArtifact": true,
                "allowCreateArtifact": true
              }
            }'
```

### Validation Step (Best Practice Analyzer)

```yaml
      - name: Run Tabular Editor BPA
        run: |
          # Install Tabular Editor CLI
          dotnet tool install -g TabularEditor.TOMWrapper
          # Run Best Practice Analyzer
          tabulareditor model.bim -A BPARules.json -V
```

## CI/CD with Azure DevOps

```yaml
trigger:
  branches:
    include: [main]
  paths:
    include: ['reports/*']

pool:
  vmImage: 'ubuntu-latest'

steps:
  - task: PowerBIActions@5
    displayName: 'Deploy to Test'
    inputs:
      PowerBIServiceConnection: 'PowerBI-ServicePrincipal'
      Action: 'Publish'
      WorkspaceName: 'Sales-Test'
      PbixFile: '$(Build.SourcesDirectory)/reports/*.pbix'
      OverWrite: true

  - task: PowerBIActions@5
    displayName: 'Refresh Dataset'
    inputs:
      PowerBIServiceConnection: 'PowerBI-ServicePrincipal'
      Action: 'DatasetRefresh'
      WorkspaceName: 'Sales-Test'
      DatasetName: 'SalesModel'
```

**Azure DevOps extension:** Install "Power BI Actions" from the Visual Studio Marketplace for native pipeline tasks.

## Fabric Git Integration

Native source control integration (GA since late 2023):

1. **Connect workspace to repo:** Workspace settings > Git integration > Connect
2. **Supported repos:** Azure DevOps Repos, GitHub (2025+)
3. **Sync direction:** Workspace to repo (commit) or repo to workspace (update)
4. **Supported items:** Reports, semantic models, notebooks, pipelines, lakehouses

**Branching strategy:**
- Main branch connected to Production workspace
- Feature branches for development
- PR-based review and merge
- Auto-sync on merge to main

## Security

### Row-Level Security (RLS)

Define in Power BI Desktop (Modeling > Manage Roles):

```dax
// Static RLS - filter by specific values
[Region] = "West"

// Dynamic RLS - filter by logged-in user
[Email] = USERPRINCIPALNAME()

// Dynamic RLS with lookup table
[ManagerEmail] = USERPRINCIPALNAME()
|| PATHCONTAINS([ManagerPath], LOOKUPVALUE(
    Employees[EmployeeID],
    Employees[Email], USERPRINCIPALNAME()
))
```

**Testing:**
- Desktop: Modeling > View as > select role (does not support USERPRINCIPALNAME)
- Service: semantic model settings > Security > test role with specific user
- Embedded: generate embed token with effective identity

**Rules:**
- RLS applies to Viewers only; Admins/Members/Contributors bypass RLS
- Must add users/groups to roles in the Power BI Service
- Service Principal can test RLS by generating tokens with EffectiveIdentity
- RLS filters propagate through relationships (single-direction)
- With bidirectional filtering, test carefully for security leaks

### Object-Level Security (OLS)

Restrict access to specific tables/columns for certain roles. Configured via:
- Tabular Editor (recommended)
- TOM/.NET SDK
- XMLA endpoint with TMSL

```json
// TMSL to add OLS
{
  "createOrReplace": {
    "object": { "database": "model", "role": "RestrictedUser" },
    "role": {
      "name": "RestrictedUser",
      "tablePermissions": [{
        "name": "Employees",
        "columnPermissions": [{
          "name": "Salary",
          "metadataPermission": "none"
        }]
      }]
    }
  }
}
```

## Capacity Management

| SKU Type | Use Case | Features |
|----------|----------|----------|
| Power BI Pro | Individual collaboration | 1GB model, 8 refreshes/day |
| Power BI Premium Per User (PPU) | Per-user premium features | 100GB model, 48 refreshes/day, XMLA, deployment pipelines |
| Power BI Premium (P SKUs) | Organization-wide, deprecated in favor of Fabric F SKUs | Dedicated capacity |
| Fabric F SKUs | Modern capacity | F2 to F2048, replaces P/A/EM SKUs |
| Power BI Embedded (A/EM SKUs) | App embedding, deprecated for F SKUs | API-driven |

**Fabric F-SKU equivalency (2026):**
| F-SKU | Equivalent Legacy | CUs | PBI Content Viewing |
|-------|------------------|-----|---------------------|
| F2 | EM1 | 2 | No (API only) |
| F4 | EM2 | 4 | No |
| F8 | EM3 | 8 | No |
| F16 | P1 (partial) | 16 | No |
| F32 | P1 (partial) | 32 | No |
| F64 | P1 | 64 | Yes (unlimited users) |
| F128 | P2 | 128 | Yes |
| F256 | P3 | 256 | Yes |

**Key rule:** F64 is the minimum Fabric SKU that includes Power BI content viewing rights for users without Pro/PPU licenses.

## Workspace Management

| Workspace Role | Permissions |
|---------------|-------------|
| Admin | Full control, add/remove members, delete workspace |
| Member | Publish, edit content, share, manage permissions |
| Contributor | Create/edit content, cannot share or manage permissions |
| Viewer | View content only, subject to RLS |

**Best practices:**
- Use security groups for role assignment (not individual users)
- Separate workspaces per environment (Dev/Test/Prod)
- Use apps for end-user content distribution
- Limit Admin role to 2-3 people per workspace
- Enable audit logging for governance

## Power BI Report Server (On-Premises)

For comprehensive Report Server guidance, see **`references/report-server-detail.md`**.
Key facts: requires SQL Server Enterprise SA or Premium license; uses PBIX only (no PBIR); release cycle January/May/September; latest version January 2026.

## Fabric Git Integration Updates (2025-2026)

Git integration enhancements since initial GA:
- GitHub support added alongside Azure DevOps Repos (2025)
- Real-time intelligence items (Eventstream, KQL DB, Data Activator) now support Git integration
- Dataflow Gen2 supports CI/CD and Git integration
- Deployment pipelines support Git-triggered automation
- Improved conflict resolution for PBIR-format reports (per-visual file granularity)

## Additional Resources

### Reference Files
- **`references/governance-checklist.md`** -- Tenant settings, audit logging, sensitivity labels, data loss prevention, and compliance checklist
- **`references/report-server-detail.md`** -- Power BI Report Server on-premises: versions, feature comparison, REST API, security, deployment architecture
