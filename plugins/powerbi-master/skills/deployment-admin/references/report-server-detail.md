# Power BI Report Server (On-Premises) - Detailed Reference

Standalone server for organizations that cannot use cloud:
- Deploys .pbix reports, paginated reports (.rdl), KPIs, Excel, mobile reports
- Requires SQL Server Enterprise license with Software Assurance, or Power BI Premium
- Release cycle: January, May, September (three releases per year)
- No real-time Service features (dataflows, apps, streaming, dashboards)
- Gateway not required (data sources are direct from server)

## Latest Version: January 2026

Build 1.25.9508.3237 (January 21, 2026):
- Added support for SQL Server 2025 Enterprise Core Product ID
- New advanced server property `DisableMSRBConnect` (default: True) to restrict Connected mode from Report Builder
- 64-bit only Power BI Desktop for Report Server (starting September 2025, 32-bit deprecated)

## Strategic Change: SSRS Consolidation

Starting with SQL Server 2025, Microsoft consolidates all on-premises reporting under Power BI Report Server. No new versions of SQL Server Reporting Services (SSRS) will be released. PBIRS is the default on-premises reporting solution.

## Report Server vs. Service Feature Comparison

| Feature | Report Server | Service | Notes |
|---------|:------------:|:-------:|-------|
| Power BI reports (.pbix) | Yes | Yes | Report Server uses optimized Desktop version |
| Paginated reports (.rdl) | Yes | Yes | |
| Dashboards | No | Yes | Service-only feature |
| Apps (content distribution) | No | Yes | |
| Bookmarks | No | Yes | |
| Q&A natural language | No | Yes | |
| Quick insights | No | Yes | |
| Email subscriptions (PBI) | No | Yes | Paginated report email works on both |
| Real-time streaming | No | Yes | |
| Composite models | No | Yes | |
| Dynamic M query parameters | No | Yes | |
| R/Python visuals | No | Yes | |
| Sensitivity labels | No | Yes | |
| Cross-report drillthrough | No | Yes | |
| Analyze in Excel | No | Yes | |
| Personalize visuals | No | Yes | |
| Automatic page refresh | No | Yes | |
| Template apps | No | Yes | |
| Row-level security (RLS) | Yes | Yes | |
| Power BI mobile apps | Yes | Yes | |
| Paginated report email subscriptions | Yes | Yes | |
| Power BI custom visuals | Yes | Yes | |
| ArcGIS for Power BI | Yes | Yes | |
| Full-screen mode | Yes | Yes | |
| Many-to-many relationships | Yes | Yes | |

## Report Server REST API

PBIRS exposes a REST API for programmatic management:
```
Base URL: https://reportserver/reports/api/v2.0/
```

| Endpoint | Purpose |
|----------|---------|
| GET /CatalogItems | List reports, data sources, folders |
| GET /Reports({Id})/Content/$value | Download report content |
| POST /CatalogItems | Upload a report |
| GET /Folders | List folders |
| POST /Subscriptions | Create scheduled delivery |
| GET /System | Server information |
| PATCH /DataSources({Id}) | Update data source credentials |

## Report Server Security

| Layer | Configuration |
|-------|---------------|
| Authentication | Windows, NTLM, Kerberos, custom security extension |
| Authorization | Role-based: Browser, Content Manager, Publisher, Report Builder, My Reports, System Administrator, System User |
| Transport | HTTPS with TLS certificate (strongly recommended) |
| Data source | Windows integrated, stored credentials, or prompt |
| RLS | Supported in .pbix reports with standard RLS definitions |
| Encryption | Symmetric key for stored credentials and connection strings |

## Report Server Deployment Architecture

```
[Users/Browsers] --> [Load Balancer / NLB]
                         |
             +-----------+-----------+
             |                       |
     [PBIRS Instance 1]     [PBIRS Instance 2]
             |                       |
             +-----------+-----------+
                         |
                [Report Server DB]
                (SQL Server)
```

**Scale-out:** Multiple PBIRS instances share one Report Server Database. Use NLB or Azure Traffic Manager for traffic distribution.

**Upgrade path:** PBIRS January 2026 supports in-place upgrade from previous PBIRS versions and migration from SSRS.
