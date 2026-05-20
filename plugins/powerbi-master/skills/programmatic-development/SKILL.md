---
name: programmatic-development
description: |
  Programmatic Power BI development with PBIR, PBIP, TMDL, TOM, and fabric-cicd.
  PROACTIVELY activate for: (1) creating Power BI reports programmatically (PBIR enhanced report format), (2) PBIR vs PBIR-Legacy selection (2026 default), (3) PBIP developer mode and Power BI project files, (4) Tabular Object Model (TOM) / .NET SDK scripting, (5) Tabular Editor scripting (C# scripts, advanced scripting), (6) pbi-tools workflows, (7) fabric-cicd Python deployments (FabricWorkspace, publish_all_items), (8) Fabric CLI (fab deploy), (9) Semantic Link / sempy / semantic-link-labs, (10) generating PBIX programmatically, (11) parameter.yml for environment-specific deployments, (12) ALM Toolkit.
  Provides: PBIR/PBIP project templates, fabric-cicd deploy.py, Tabular Editor scripting recipes, parameter.yml patterns, and end-to-end programmatic workflows.
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

## Reference Map

Detailed material lives in `references/`. Load only what the current task needs.

| Topic | File | When to load |
|-------|------|--------------|
| PBIR rollout timeline, full PBIP folder structure, byPath/byConnection, annotations, validation, limitations | `references/pbir-format-deep-dive.md` | Authoring PBIR by hand, debugging definition.pbir, validating generated PBIR, understanding 2026 rollout state |
| PBIR JSON schema (visuals, pages, report settings) with Python manipulation examples | `references/pbir-schema-reference.md` | Scripting PBIR with Python: add page, batch-update visuals, copy between reports |
| TOM/Tabular Editor/fabric-cicd/Fabric CLI/semantic-link/pbi-tools/ALM Toolkit -- setup, examples, Desktop developer features | `references/tools-and-tabular-editor.md` | Choosing a tool, deploying, scripting TOM, running C# scripts, configuring Desktop |
| TOM advanced patterns (RLS, OLS, partitions, perspectives, translations, calc groups, SP auth) | `references/tom-advanced-patterns.md` | Writing complex TOM .NET code beyond basic measure/table edits |
| fabric-cicd advanced recipes (multi-workspace, hooks, GitHub Actions/Azure DevOps pipelines, parameter patterns, troubleshooting) | `references/fabric-cicd-recipes.md` | Production CI/CD workflows, multi-environment promotion, OIDC federated credentials |

## PBIR - Power BI Enhanced Report Format

PBIR is Microsoft's modern, publicly documented, folder-based, JSON report format. It replaces the opaque `report.json` blob (now called PBIR-Legacy) with one file per visual, page, and bookmark, enabling proper Git diff/merge, code review, and schema-validated editing in VS Code.

**Current state (April 2026):** PBIR is the default for newly created reports in the Service. Existing Service reports are being auto-upgraded gradually. Desktop still needs the preview toggle until the **May 2026** release, when PBIR becomes the Desktop default. PBIR-Legacy will be deprecated at PBIP GA.

For the full 2026 rollout timeline, admin opt-out, Service/Desktop restore policies, Sovereign Cloud caveats, complete project structure, byPath vs byConnection examples, annotations, self-validation procedure, and limitations, see `references/pbir-format-deep-dive.md`.

**Quick PBIP structure (essentials only):**

```text
MyProject.pbip                          # Entry JSON
├── MyProject.Report/
│   ├── definition.pbir                # Required entry; uses byPath or byConnection
│   └── definition/                    # PBIR folder (one file per page/visual/bookmark)
└── MyProject.SemanticModel/
    ├── definition.pbism
    └── definition/                    # TMDL folder
```

## TMDL - Tabular Model Definition Language

TMDL is the human-readable, source-control-friendly format for semantic model definitions. GA since 2025. For comprehensive TMDL coverage including complete syntax reference, all object types, CI/CD patterns, and deployment workflows, load the dedicated `powerbi-master:tmdl-mastery` skill.

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

## Core Workflow

1. **Pick the source format** — PBIP (modern, TMDL + PBIR) for new work; legacy PBIX only for Report Server or pre-PBIP projects.
2. **Edit programmatically** — VS Code for PBIR/TMDL JSON; Tabular Editor for model authoring; semantic-link-labs for Fabric notebooks; TOM .NET for custom apps.
3. **Validate locally** — JSON schema, PBI-InspectorV2, lineage walker, BPA. See `powerbi-master:validation-testing` skill.
4. **Parameterize** — `parameter.yml` for environment-specific GUIDs/connection strings.
5. **Deploy** — `fabric-cicd` (Python library, primary) or `fab deploy` (CLI wrapper). Both consume the same `parameter.yml`. First deploy requires manual data-source credential entry in the Fabric portal.
6. **Diff and promote** — ALM Toolkit for schema diff; Fabric Deployment Pipelines or scripted multi-workspace deploy for promotion.

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

## Tool Quick-Pick

| Need | Load reference | Tool |
|------|---------------|------|
| Modify a measure on a deployed model | `tools-and-tabular-editor.md` | TOM or semantic-link-labs |
| Auto-generate measures across folders | `tools-and-tabular-editor.md` | Tabular Editor C# script |
| Deploy PBIP from CI | `fabric-cicd-recipes.md` | fabric-cicd + parameter.yml |
| Generate PBIR pages from a template | `pbir-schema-reference.md` | Python + JSON schema validation |
| RLS/OLS in .NET | `tom-advanced-patterns.md` | TOM |
| Extract legacy PBIX for diff | `tools-and-tabular-editor.md` | pbi-tools |

## Related Skills

- `powerbi-master:tmdl-mastery` -- Deep TMDL language reference and syntax
- `powerbi-master:validation-testing` -- Validate generated PBIR / TMDL / DAX before deploy
- `powerbi-master:rest-api-automation` -- Raw Fabric REST API endpoints when fabric-cicd doesn't cover a scenario
- `powerbi-master:deployment-admin` -- Fabric Deployment Pipelines, workspace management, RLS at deploy time
- `powerbi-master:fabric-integration` -- Direct Lake, OneLake, Lakehouse/Warehouse integration

## Official Microsoft References (2026)

- [Deploy PBIP with fabric-cicd](https://learn.microsoft.com/en-us/power-bi/developer/projects/projects-deploy-fabric-cicd)
- [Power BI enhanced report format (PBIR)](https://learn.microsoft.com/en-us/power-bi/developer/projects/projects-report)
- [Fabric CLI v1.5 GA](https://blog.fabric.microsoft.com/en-US/blog/fabric-cli-v1-5-is-here-generally-available/)
- [PBIR will become the default Power BI Report Format](https://powerbi.microsoft.com/en-us/blog/pbir-will-become-the-default-power-bi-report-format-get-ready-for-the-transition/)
- [fabric-cicd GitHub](https://github.com/microsoft/fabric-cicd) and [docs](https://microsoft.github.io/fabric-cicd/latest/)
- [semantic-link-labs GitHub](https://github.com/microsoft/semantic-link-labs)
- [PBIR JSON schemas](https://github.com/microsoft/json-schemas/tree/main/fabric/item/report/definition)
