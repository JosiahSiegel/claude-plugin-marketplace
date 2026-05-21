---
name: data-cloud-2025
description: |
  Salesforce Data Cloud integration patterns and architecture (2025).
  PROACTIVELY activate for: (1) Data Cloud setup and ingestion, (2) Data Streams (cloud, mobile, web SDK, ingestion API), (3) data model objects (DMO) and source objects (DSO), (4) identity resolution and unified profiles, (5) calculated insights and segmentation, (6) activations to Marketing Cloud, advertising platforms, Salesforce CRM, (7) Bring Your Own Lake (BYOL) with Snowflake, BigQuery, Databricks, (8) zero-copy data sharing, (9) Data Cloud + Agentforce grounding, (10) consent management and compliance.
  Provides: data-stream selection matrix, identity resolution rules, segmentation patterns, BYOL configuration, and activation playbook.
---

## CRITICAL GUIDELINES

### Windows File Path Requirements

**MANDATORY: Always Use Backslashes on Windows for File Paths**

When using Edit or Write tools on Windows, you MUST use backslashes (`\`) in file paths, NOT forward slashes (`/`).

Examples:
- WRONG: `D:/repos/project/file.tsx`
- CORRECT: `D:\repos\project\file.tsx`

This applies to:
- Edit tool file_path parameter
- Write tool file_path parameter
- All file operations on Windows systems

### Documentation Guidelines

NEVER create new documentation files unless explicitly requested by the user.

- **Priority**: Update existing README.md files rather than creating new documentation
- **Repository cleanliness**: Keep repository root clean - only README.md unless user requests otherwise
- **Style**: Documentation should be concise, direct, and professional - avoid AI-generated tone
- **User preference**: Only create additional .md files when user specifically asks for documentation

---

# Salesforce Data Cloud Integration Patterns (2025)

## What is Salesforce Data Cloud?

Salesforce Data Cloud is a real-time customer data platform (CDP) that unifies data from any source to create a complete, actionable view of every customer. It powers AI, automation, and analytics across the entire Customer 360 platform.

**Key Capabilities:**
- **Data Ingestion** — Connect 200+ sources (Salesforce, external systems, data lakes)
- **Data Harmonization** — Map disparate data to unified data model
- **Identity Resolution** — Match and merge customer records across sources
- **Real-Time Activation** — Trigger actions based on streaming data
- **Zero Copy Architecture** — Query data in place without moving it
- **AI/ML Ready** — Powers Einstein, Agentforce, and predictive models
- **Vector Database** (GA March 2025) — Store and query unstructured data with semantic search
- **Hybrid Search** (Pilot 2025) — Combine semantic and keyword search for accuracy

## Reference Map

Detailed material lives in `references/`. Load only what the current task needs.

| Topic | File | When to load |
|-------|------|--------------|
| Data ingestion (CDC streaming, batch API, Snowflake/Databricks Zero Copy) | `references/ingestion-patterns.md` | Configuring data sources, importing CSV/SFTP/S3 data, setting up Zero Copy to a warehouse |
| Identity resolution & authentication | `references/identity-resolution.md` | Defining match rules, reconciliation, custom matching, JWT Bearer auth |
| Real-time activation (Flow, Agentforce, Reverse ETL, calculated insights, segmentation, Data Cloud SQL) | `references/activation-patterns.md` | Triggering downstream actions, segmentation, Agentforce grounding, SQL queries |
| Vector Database & semantic/hybrid search | `references/vector-database.md` | Unstructured data indexing, semantic search, Einstein Copilot Search, multi-language search |

## Data Cloud Architecture

```text
┌──────────────────────────────────────────────────────────┐
│                    Data Sources                          │
│  Salesforce CRM │ External Apps │ Data Warehouses │ APIs │
└────────┬─────────────────┬──────────────┬───────────┬────┘
         │                 │              │           │
    ┌────▼─────────────────▼──────────────▼───────────▼────┐
    │         Data Cloud Connectors & Ingestion            │
    │  ├─ Real-time Streaming (Change Data Capture)        │
    │  ├─ Batch Import (scheduled/on-demand)               │
    │  └─ Zero Copy (Snowflake, Databricks, BigQuery)      │
    └────────────────────────┬─────────────────────────────┘
                             │
    ┌────────────────────────▼─────────────────────────────┐
    │            Data Model & Harmonization                │
    │  ├─ Map to Common Data Model (DMO objects)           │
    │  ├─ Identity Resolution (match & merge)              │
    │  └─ Data Transformation (calculated insights)        │
    └────────────────────────┬─────────────────────────────┘
                             │
    ┌────────────────────────▼─────────────────────────────┐
    │         Unified Customer Profile (360° View)         │
    │  ├─ Demographics, Transactions, Behavior, Events     │
    │  └─ Real-time Profile API for instant access         │
    └────────────────────────┬─────────────────────────────┘
                             │
    ┌────────────────────────▼─────────────────────────────┐
    │              Activation & Actions                    │
    │  ├─ Salesforce Flow (real-time automation)           │
    │  ├─ Marketing Cloud (segmentation/journeys)          │
    │  ├─ Agentforce (AI agents)                           │
    │  ├─ Einstein AI (predictions/recommendations)        │
    │  └─ External Systems (reverse ETL)                   │
    └──────────────────────────────────────────────────────┘
```

## Core Workflow

1. **Identify use case** — Ingestion, identity, segmentation, activation, or unstructured/AI search? Pick the matching reference.
2. **Map data sources** — CRM CDC (real-time), external batch (S3/SFTP), or warehouse Zero Copy.
3. **Define DMOs and matching** — Map source fields to Data Model Objects; configure identity resolution match + reconciliation rules.
4. **Build insights / segments** — Calculated insights for KPIs (LTV, churn risk); segments for activation targets.
5. **Activate** — Flow / Platform Events / Agentforce actions / Reverse ETL data actions.
6. **Validate** — Use Data Cloud SQL workbench, check sync logs, monitor identity resolution metrics.

## Best Practices

### Performance
- **Use Zero Copy** for large datasets (>10M records)
- **Batch imports** outside business hours
- **Index frequently queried fields** in Data Cloud
- **Limit real-time triggers** to critical events
- **Cache unified profiles** when possible

### Security
- **Field-level security** applies to Data Cloud queries from Salesforce
- **Data masking** for PII in non-production environments
- **Encryption at rest** and in transit (TLS 1.2+)
- **Audit logging** for all data access
- **Role-based access control** (RBAC) for Data Cloud users

### Data Quality
- **Data validation** before ingestion
- **Deduplication rules** at source and in Data Cloud
- **Data lineage tracking** (know source of each field)
- **Quality scores** for unified profiles
- **Regular data audits** and cleansing

## Resources

- **Data Cloud Documentation:** https://developer.salesforce.com/docs/data/data-cloud-int/guide
- **Zero Copy Partner Network:** https://www.salesforce.com/data/zero-copy/
- **Data Cloud Pricing:** Part of Customer 360 platform, usage-based pricing
- **Trailhead:** "Data Cloud Basics" and "Data Cloud for Developers"
