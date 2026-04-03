# powerbi-master

Complete Power BI expertise plugin for Claude Code, covering everything from DAX and data modeling to programmatic report creation, REST API automation, Fabric integration, and enterprise deployment.

## Components

### Agent

- **powerbi-expert** -- Expert agent for all Power BI tasks. Activates skills automatically based on question topic.

### Skills

| Skill | Coverage |
|-------|----------|
| **powerbi-core** | Data modeling, star schema, relationships, connectivity modes, storage modes, gateways, incremental refresh, common gotchas |
| **dax-mastery** | DAX formulas, CALCULATE, evaluation contexts, time intelligence, iterators, calculation groups, field parameters, anti-patterns |
| **power-query-m** | M language, query folding, transformations, custom connectors, parameters, pagination, error handling |
| **programmatic-development** | PBIR/PBIP format, TOM/.NET SDK, TMDL, Tabular Editor, pbi-tools, ALM Toolkit, code-first reports |
| **deployment-admin** | Deployment pipelines, CI/CD (GitHub Actions, Azure DevOps), RLS/OLS, capacity management, governance, Report Server |
| **rest-api-automation** | REST API endpoints, authentication, embed tokens, push datasets, admin APIs, JavaScript SDK embedding |
| **fabric-integration** | Direct Lake, OneLake, lakehouse/warehouse, Dataflow Gen2, notebooks, Semantic Link (sempy), medallion architecture |
| **performance-optimization** | Performance Analyzer, DAX Studio, VertiPaq Analyzer, aggregations, composite models, optimization checklists |

### Commands

| Command | Purpose |
|---------|---------|
| `/pbi-dax` | Generate a DAX measure or pattern from a business requirement |
| `/pbi-model-review` | Review a data model for best practices and anti-patterns |

## Installation

```bash
/plugin marketplace add JosiahSiegel/claude-plugin-marketplace
/plugin install powerbi-master@JosiahSiegel
```

## Usage Examples

- "Write a DAX measure for year-over-year sales growth"
- "How do I create a Power BI report programmatically using PBIR?"
- "Set up CI/CD for Power BI with GitHub Actions"
- "My report is slow, help me diagnose with DAX Studio"
- "Should I use Direct Lake or Import mode for my Fabric data?"
- "Generate an embed token for a Power BI report using service principal"
- "Review my data model for performance issues"

## License

MIT
