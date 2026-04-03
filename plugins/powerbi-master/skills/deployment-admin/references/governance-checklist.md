# Power BI Governance Checklist

## Tenant Settings (Admin Portal)

### Export and Sharing

| Setting | Recommended | Why |
|---------|-------------|-----|
| Export to Excel | Controlled (specific groups) | Prevent uncontrolled data export |
| Export to CSV | Controlled (specific groups) | Same as Excel |
| Export to PDF/PowerPoint | Enabled | Low risk, presentation use |
| Print dashboards/reports | Enabled | Low risk |
| Share content externally | Disabled or controlled | Prevent data leaks |
| Allow Azure AD B2B guest access | Controlled | External collaboration |
| Publish to web (public) | Disabled | Major security risk |
| Email subscriptions | Enabled | Useful, low risk |
| Allow XMLA endpoints | Controlled (Premium workspaces) | Advanced tool access |

### Content Creation

| Setting | Recommended | Why |
|---------|-------------|-----|
| Create workspaces | Controlled (specific groups) | Prevent workspace sprawl |
| Create template apps | Disabled for most | Niche use case |
| Push apps to end users | Controlled | App governance |
| Create dataflows | Controlled | Resource management |

### Developer Settings

| Setting | Recommended | Why |
|---------|-------------|-----|
| Allow service principals to use Power BI APIs | Enabled (specific groups) | Required for automation |
| Allow service principals to create profiles | Enabled for embedding | Multi-tenant ISV scenarios |
| Embed content in apps | Controlled | Track embedding usage |

### Admin API Settings

| Setting | Recommended | Why |
|---------|-------------|-----|
| Service principals can access admin APIs | Controlled (specific group) | Governance automation |
| Enhance admin API responses with metadata | Enabled | Better admin reporting |
| Enhance admin API responses with DAX/mashup | Controlled | Security review needed |

## Audit Logging

### Enable Unified Audit Log
1. Microsoft 365 Admin Center > Compliance > Audit
2. Ensure audit logging is turned on
3. Power BI activities are logged automatically

### Key Events to Monitor

| Event | Activity Name | Why Monitor |
|-------|--------------|-------------|
| Report viewed | ViewReport | Usage analytics |
| Report shared | ShareReport | Data access tracking |
| Exported to file | ExportReport | Data exfiltration risk |
| Dataset refreshed | RefreshDataset | Data freshness |
| Workspace created | CreateGroup | Governance tracking |
| Admin setting changed | UpdatedAdminFeatureSwitch | Security change |
| RLS role changed | AddRoleMembers, DeleteRoleMembers | Security |
| Published to web | PublishToWebReport | Major security event |
| Gateway data source added | AddDatasourceToGateway | Infrastructure |
| Sensitivity label applied/changed | SensitivityLabelApplied | Compliance |

### Querying Audit Logs

**PowerShell (Exchange Online):**
```powershell
Search-UnifiedAuditLog -StartDate (Get-Date).AddDays(-7) `
    -EndDate (Get-Date) `
    -RecordType PowerBI `
    -ResultSize 5000 |
    Select-Object -ExpandProperty AuditData |
    ConvertFrom-Json |
    Select-Object CreationTime, UserId, Activity, ItemName, WorkspaceName
```

**Power BI Admin API:**
```
GET https://api.powerbi.com/v1.0/myorg/admin/activityevents
    ?startDateTime='2026-01-01T00:00:00Z'
    &endDateTime='2026-01-02T00:00:00Z'
```

## Sensitivity Labels (Microsoft Purview)

Integrate Microsoft Purview Information Protection labels with Power BI:

1. **Enable in Admin Portal:** Tenant settings > Information protection > Allow users to apply sensitivity labels
2. **Label hierarchy:** Public < Internal < Confidential < Highly Confidential
3. **Downstream protection:** Labels propagate from datasets to reports and exports
4. **Mandatory labeling:** Require labels on all new or edited content
5. **Default labels:** Set default label for new content

### Label Behavior

| Action | Label Behavior |
|--------|---------------|
| Create report from labeled dataset | Report inherits dataset label |
| Export to Excel/PDF | Label and protection applied to export |
| Share with external user | Label enforcement applies |
| Copy data to clipboard | Depends on label protection settings |
| Print | Depends on label protection settings |

## Data Loss Prevention (DLP)

Configure DLP policies in Microsoft Purview compliance portal:

1. **Create DLP policy** targeting Power BI workspaces
2. **Define rules** based on sensitivity labels or sensitive info types (SSN, credit card, etc.)
3. **Actions:** Show policy tip, restrict access, alert admins
4. **Scope:** All workspaces or specific workspace groups

## Endorsement (Certification and Promotion)

| Level | Who Can Apply | Meaning |
|-------|--------------|---------|
| Promoted | Content owner | "This is useful, I vouch for it" |
| Certified | Designated certifiers only | "This is official, meets quality standards" |

**Configure certifiers:** Admin Portal > Tenant settings > Certification > Enable certification and specify allowed groups.

## Monitoring and Metrics

### Power BI Usage Metrics

Built-in usage metrics reports per workspace:
- Report views by user, date, platform
- Most viewed reports
- Active users trend
- Distribution method (direct, app, shared)

### Premium/Fabric Capacity Metrics App

Install "Microsoft Fabric Capacity Metrics" app from AppSource:
- CPU utilization by item type
- Overload events and throttling
- Refresh durations and failures
- Query performance trends
- Background vs interactive operations

### Custom Admin Dashboard

Build a custom governance dashboard using:
1. **Activity Events API** for user activity
2. **Scanner API** for workspace/dataset inventory
3. **Admin API** for capacity and workspace metadata
4. Store in a data warehouse or lakehouse for historical analysis

## Backup and Recovery

| Scenario | Recovery Method |
|----------|----------------|
| Accidentally deleted report | Recycle bin (workspace, 30-day retention) |
| Deleted workspace | Microsoft support (limited window) |
| Need to restore dataset | Re-publish from source (PBIP/Git) |
| Roll back to previous version | Git integration (revert commit) |
| Recover from corruption | XMLA endpoint backup (Premium) |

### XMLA Backup Commands

```xml
<!-- Backup -->
<Backup xmlns="http://schemas.microsoft.com/analysisservices/2003/engine">
  <Object>
    <DatabaseID>MySemanticModel</DatabaseID>
  </Object>
  <File>backup.abf</File>
  <AllowOverwrite>true</AllowOverwrite>
</Backup>

<!-- Restore -->
<Restore xmlns="http://schemas.microsoft.com/analysisservices/2003/engine">
  <File>backup.abf</File>
  <DatabaseName>MySemanticModel_Restored</DatabaseName>
  <AllowOverwrite>false</AllowOverwrite>
</Restore>
```

**Note:** XMLA backup/restore requires Premium or PPU workspace with XMLA read/write enabled.
