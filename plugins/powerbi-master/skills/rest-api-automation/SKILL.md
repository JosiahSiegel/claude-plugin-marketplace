---
name: rest-api-automation
description: |
  This skill should be used when the user asks about "Power BI REST API",
  "Power BI API", "embed token", "service principal Power BI",
  "Power BI authentication", "dataset refresh API", "push dataset",
  "admin API", "Power BI Embedded", "JavaScript SDK", "embed report",
  "export to file API", "Power BI automation", "app registration",
  "Power BI API endpoint", "Power BI PowerShell", "MicrosoftPowerBIMgmt",
  "refresh dataset programmatically", "scanner API", "export report API",
  "clone report API", "workspace REST API", or "admin API".
---

# Power BI REST API and Automation

## Overview

The Power BI REST API provides programmatic access for embedding, administration, dataset management, and automation. The base URL is `https://api.powerbi.com/v1.0/myorg/` for user context or `https://api.powerbi.com/v1.0/myorg/groups/{workspaceId}/` for workspace context.

## Authentication

### Service Principal (Recommended for Automation)

1. **Register app in Azure AD:** Azure Portal > App registrations > New registration
2. **Create client secret:** Certificates & secrets > New client secret
3. **Grant Power BI permissions:** API permissions > Add > Power BI Service
4. **Enable in Power BI Admin:** Tenant settings > Allow service principals to use APIs > add security group
5. **Add SP to workspace:** Workspace > Access > Add the app as Member or Contributor

**Get access token:**
```bash
curl -X POST "https://login.microsoftonline.com/{tenantId}/oauth2/v2.0/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials&client_id={clientId}&client_secret={secret}&scope=https://analysis.windows.net/powerbi/api/.default"
```

**PowerShell:**
```powershell
$body = @{
    grant_type    = "client_credentials"
    client_id     = $clientId
    client_secret = $clientSecret
    scope         = "https://analysis.windows.net/powerbi/api/.default"
}
$token = (Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" `
    -Method Post -Body $body).access_token
```

### Master User (Legacy, Not Recommended)
Uses a real user account with username/password grant. Requires Pro/PPU license. Subject to MFA and Conditional Access issues. Avoid for production.

## API Operation Groups

| Group | Base Path | Purpose |
|-------|-----------|---------|
| Datasets | `/datasets` | Manage semantic models, refresh, parameters |
| Reports | `/reports` | Get, clone, export, rebind reports |
| Dashboards | `/dashboards` | Get dashboards and tiles |
| Groups (Workspaces) | `/groups` | Workspace CRUD, membership |
| Imports | `/imports` | Upload PBIX/XLSX files |
| Pipelines | `/pipelines` | Deployment pipeline automation |
| Admin | `/admin` | Tenant-wide operations (scanner, activity) |
| EmbedToken | `/GenerateToken` | Create embed tokens |
| Gateways | `/gateways` | Gateway and data source management |
| Dataflows | `/dataflows` | Dataflow management |
| Apps | `/apps` | App management |
| Capacities | `/capacities` | Capacity management |
| Goals | `/goals` | Scorecards and goals |

## Common API Operations

### Refresh a Semantic Model

```bash
POST https://api.powerbi.com/v1.0/myorg/groups/{workspaceId}/datasets/{datasetId}/refreshes
Authorization: Bearer {token}
Content-Type: application/json

{
  "notifyOption": "MailOnFailure",
  "retryCount": 2,
  "type": "Full",
  "commitMode": "transactional",
  "applyRefreshPolicy": true
}
```

**Enhanced refresh (selective tables/partitions):**
```json
{
  "type": "Full",
  "commitMode": "transactional",
  "objects": [
    { "table": "Sales", "partition": "Sales_Current" },
    { "table": "Products" }
  ]
}
```

### Get Refresh History

```bash
GET https://api.powerbi.com/v1.0/myorg/groups/{workspaceId}/datasets/{datasetId}/refreshes?$top=10
```

### Import a PBIX File

```bash
POST https://api.powerbi.com/v1.0/myorg/groups/{workspaceId}/imports?datasetDisplayName=SalesReport&nameConflict=CreateOrOverwrite
Authorization: Bearer {token}
Content-Type: multipart/form-data

[PBIX file as form data]
```

**Python:**
```python
import requests

url = f"https://api.powerbi.com/v1.0/myorg/groups/{workspace_id}/imports"
params = {"datasetDisplayName": "SalesReport", "nameConflict": "CreateOrOverwrite"}
headers = {"Authorization": f"Bearer {token}"}

with open("SalesReport.pbix", "rb") as f:
    response = requests.post(url, params=params, headers=headers,
        files={"file": ("SalesReport.pbix", f, "application/octet-stream")})
```

### Export Report to File

```bash
# Initiate export
POST https://api.powerbi.com/v1.0/myorg/groups/{workspaceId}/reports/{reportId}/ExportTo
{
  "format": "PDF",
  "powerBIReportConfiguration": {
    "pages": [
      { "pageName": "ReportSection1" }
    ],
    "defaultBookmark": { "name": "BookmarkName" }
  }
}

# Poll for completion
GET https://api.powerbi.com/v1.0/myorg/groups/{workspaceId}/reports/{reportId}/exports/{exportId}

# Download when status is "Succeeded"
GET https://api.powerbi.com/v1.0/myorg/groups/{workspaceId}/reports/{reportId}/exports/{exportId}/file
```

**Supported formats:** PDF, PPTX, PNG, XLSX, CSV, XML, MHTML, IMAGE, ACCESSIBLEPDF

### Update Dataset Parameters

```bash
POST https://api.powerbi.com/v1.0/myorg/groups/{workspaceId}/datasets/{datasetId}/Default.UpdateParameters
{
  "updateDetails": [
    { "name": "ServerName", "newValue": "prod-server.database.windows.net" },
    { "name": "DatabaseName", "newValue": "ProdDB" }
  ]
}
```

### Take Over a Dataset

```bash
POST https://api.powerbi.com/v1.0/myorg/groups/{workspaceId}/datasets/{datasetId}/Default.TakeOver
```

### Update Data Source Credentials

```bash
PATCH https://api.powerbi.com/v1.0/myorg/gateways/{gatewayId}/datasources/{datasourceId}
{
  "credentialDetails": {
    "credentialType": "OAuth2",
    "credentials": "{\"credentialData\":[{\"name\":\"accessToken\",\"value\":\"...\"}]}",
    "encryptedConnection": "Encrypted",
    "encryptionAlgorithm": "None",
    "privacyLevel": "Organizational"
  }
}
```

## Push Datasets (Real-Time)

Create and push data to datasets via API for real-time dashboards:

```bash
# Create push dataset
POST https://api.powerbi.com/v1.0/myorg/groups/{workspaceId}/datasets
{
  "name": "RealTimeMetrics",
  "defaultMode": "Push",
  "tables": [
    {
      "name": "Metrics",
      "columns": [
        { "name": "Timestamp", "dataType": "DateTime" },
        { "name": "Sensor", "dataType": "String" },
        { "name": "Value", "dataType": "Double" },
        { "name": "Status", "dataType": "String" }
      ]
    }
  ]
}

# Push rows
POST https://api.powerbi.com/v1.0/myorg/groups/{workspaceId}/datasets/{datasetId}/tables/Metrics/rows
{
  "rows": [
    { "Timestamp": "2026-04-03T10:30:00Z", "Sensor": "Temp-01", "Value": 23.5, "Status": "Normal" },
    { "Timestamp": "2026-04-03T10:30:00Z", "Sensor": "Temp-02", "Value": 45.2, "Status": "Warning" }
  ]
}

# Clear table
DELETE https://api.powerbi.com/v1.0/myorg/groups/{workspaceId}/datasets/{datasetId}/tables/Metrics/rows
```

## Embed Tokens (Power BI Embedded)

### Generate Embed Token for Report

```bash
POST https://api.powerbi.com/v1.0/myorg/groups/{workspaceId}/reports/{reportId}/GenerateToken
{
  "accessLevel": "View",
  "identities": [
    {
      "username": "user@domain.com",
      "roles": ["RegionManager"],
      "datasets": ["{datasetId}"]
    }
  ]
}
```

### Generate Token for Multiple Items

```bash
POST https://api.powerbi.com/v1.0/myorg/GenerateToken
{
  "datasets": [
    { "id": "{datasetId}" }
  ],
  "reports": [
    { "id": "{reportId}", "allowEdit": false }
  ],
  "targetWorkspaces": [
    { "id": "{workspaceId}" }
  ],
  "identities": [
    {
      "username": "user@domain.com",
      "roles": ["ViewerRole"],
      "datasets": ["{datasetId}"]
    }
  ]
}
```

### JavaScript SDK Embedding

```html
<div id="reportContainer" style="height:600px;"></div>
<script src="https://cdn.jsdelivr.net/npm/powerbi-client/dist/powerbi.min.js"></script>
<script>
  const embedConfig = {
    type: 'report',
    id: reportId,
    embedUrl: embedUrl,
    accessToken: embedToken,
    tokenType: models.TokenType.Embed,  // Use Embed for app-owns-data
    settings: {
      panes: {
        filters: { visible: false },
        pageNavigation: { visible: true }
      },
      bars: { statusBar: { visible: false } }
    }
  };

  const container = document.getElementById('reportContainer');
  const report = powerbi.embed(container, embedConfig);

  // Token refresh handler
  report.on('tokenExpired', async () => {
    const newToken = await fetchNewToken();  // Call your backend
    await report.setAccessToken(newToken);
  });

  // Event handlers
  report.on('loaded', () => console.log('Report loaded'));
  report.on('rendered', () => console.log('Report rendered'));
  report.on('error', (event) => console.error(event.detail));
</script>
```

## Admin APIs

### Scan Workspaces (Inventory)

```bash
# Initiate scan
POST https://api.powerbi.com/v1.0/myorg/admin/workspaces/getInfo
{
  "workspaces": ["{workspaceId1}", "{workspaceId2}"],
  "datasetExpressions": true,
  "datasetSchema": true,
  "datasourceDetails": true,
  "getArtifactUsers": true
}

# Get scan results
GET https://api.powerbi.com/v1.0/myorg/admin/workspaces/scanResult/{scanId}
```

### Activity Events (Audit)

```bash
GET https://api.powerbi.com/v1.0/myorg/admin/activityevents?startDateTime='2026-04-01T00:00:00Z'&endDateTime='2026-04-02T00:00:00Z'&$filter=Activity eq 'ViewReport'
```

### List All Datasets in Tenant

```bash
GET https://api.powerbi.com/v1.0/myorg/admin/datasets?$top=100
```

## Additional Resources

### Reference Files
- **`references/api-endpoints-complete.md`** -- Complete API endpoint reference with all parameters, response schemas, and error codes
