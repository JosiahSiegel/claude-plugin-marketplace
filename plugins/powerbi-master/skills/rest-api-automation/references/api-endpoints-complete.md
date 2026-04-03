# Power BI REST API - Complete Endpoint Reference

## Base URLs

| Context | Base URL |
|---------|----------|
| User (My Workspace) | `https://api.powerbi.com/v1.0/myorg/` |
| Group (Workspace) | `https://api.powerbi.com/v1.0/myorg/groups/{groupId}/` |
| Admin | `https://api.powerbi.com/v1.0/myorg/admin/` |

**Required header for all requests:**
```
Authorization: Bearer {access_token}
Content-Type: application/json
```

## Datasets (Semantic Models)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/datasets` | List datasets |
| GET | `/datasets/{id}` | Get dataset |
| DELETE | `/datasets/{id}` | Delete dataset |
| GET | `/datasets/{id}/datasources` | Get data sources |
| POST | `/datasets/{id}/refreshes` | Trigger refresh |
| GET | `/datasets/{id}/refreshes` | Get refresh history |
| POST | `/datasets/{id}/Default.UpdateParameters` | Update parameters |
| POST | `/datasets/{id}/Default.TakeOver` | Take ownership |
| POST | `/datasets/{id}/Default.SetAllConnections` | Update connections |
| GET | `/datasets/{id}/Default.GetBoundGatewayDatasources` | Get gateway sources |
| POST | `/datasets/{id}/Default.BindToGateway` | Bind to gateway |
| PATCH | `/datasets/{id}` | Update dataset properties |
| POST | `/datasets/{id}/users` | Add dataset user |
| GET | `/datasets/{id}/users` | Get dataset users |
| POST | `/datasets` | Create push dataset |
| POST | `/datasets/{id}/tables/{tableName}/rows` | Push rows |
| DELETE | `/datasets/{id}/tables/{tableName}/rows` | Clear table rows |
| GET | `/datasets/{id}/tables` | Get tables in push dataset |
| PUT | `/datasets/{id}/tables/{tableName}` | Update table schema |

### Refresh Request Body

```json
{
  "notifyOption": "MailOnFailure",
  "retryCount": 2,
  "type": "Full",
  "commitMode": "transactional",
  "maxParallelism": 5,
  "objects": [
    { "table": "TableName" },
    { "table": "TableName", "partition": "PartitionName" }
  ],
  "applyRefreshPolicy": false
}
```

**notifyOption values:** NoNotification, MailOnFailure, MailOnComplete

**type values:** Full, ClearValues, Calculate, DataOnly, Automatic, Defragment

## Reports

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/reports` | List reports |
| GET | `/reports/{id}` | Get report |
| DELETE | `/reports/{id}` | Delete report |
| POST | `/reports/{id}/Clone` | Clone report |
| POST | `/reports/{id}/Rebind` | Rebind to different dataset |
| POST | `/reports/{id}/ExportTo` | Start export to file |
| GET | `/reports/{id}/exports/{exportId}` | Get export status |
| GET | `/reports/{id}/exports/{exportId}/file` | Download exported file |
| GET | `/reports/{id}/pages` | Get report pages |
| GET | `/reports/{id}/pages/{pageName}/visuals` | Get page visuals |
| POST | `/reports/{id}/GenerateToken` | Generate embed token |
| PATCH | `/reports/{id}` | Update report (name, description) |

### Clone Request Body

```json
{
  "name": "Cloned Report Name",
  "targetWorkspaceId": "{workspaceId}",
  "targetModelId": "{datasetId}"
}
```

### Export Request Body

```json
{
  "format": "PDF",
  "powerBIReportConfiguration": {
    "pages": [
      {
        "pageName": "ReportSection1",
        "visualName": "visual123"
      }
    ],
    "reportLevelFilters": [
      {
        "filter": "..."
      }
    ],
    "defaultBookmark": {
      "name": "BookmarkName",
      "state": "bookmarkStateBase64"
    },
    "locale": "en-US"
  },
  "paginatedReportConfiguration": {
    "parameterValues": [
      { "name": "ParamName", "value": "ParamValue" }
    ]
  }
}
```

## Groups (Workspaces)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/groups` | List workspaces user has access to |
| POST | `/groups` | Create workspace |
| DELETE | `/groups/{id}` | Delete workspace |
| GET | `/groups/{id}/users` | Get workspace users |
| POST | `/groups/{id}/users` | Add user to workspace |
| PUT | `/groups/{id}/users` | Update user role |
| DELETE | `/groups/{id}/users/{userId}` | Remove user |
| POST | `/groups/{id}/AssignToCapacity` | Assign to capacity |
| POST | `/groups/{id}/RestoreDeletedGroup` | Restore deleted workspace |

### Create Workspace

```json
{
  "name": "Sales Analytics Prod"
}
```

### Add User

```json
{
  "emailAddress": "user@domain.com",
  "groupUserAccessRight": "Member"
}
```

**Access rights:** Admin, Member, Contributor, Viewer

## Imports

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/imports?datasetDisplayName={name}&nameConflict={action}` | Upload PBIX |
| GET | `/imports/{id}` | Get import status |
| GET | `/imports` | List imports |

**nameConflict values:** Abort, CreateOrOverwrite, GenerateUniqueName, Overwrite, Ignore

## Deployment Pipelines

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/pipelines` | List pipelines |
| POST | `/pipelines` | Create pipeline |
| DELETE | `/pipelines/{id}` | Delete pipeline |
| GET | `/pipelines/{id}/stages` | Get stages |
| POST | `/pipelines/{id}/stages/{stageOrder}/assignWorkspace` | Assign workspace to stage |
| POST | `/pipelines/{id}/deployAll` | Deploy all items |
| POST | `/pipelines/{id}/deploy` | Deploy selective items |
| GET | `/pipelines/{id}/operations/{operationId}` | Get deploy status |

### Deploy All

```json
{
  "sourceStageOrder": 0,
  "isBackwardDeployment": false,
  "newWorkspace": null,
  "options": {
    "allowOverwriteArtifact": true,
    "allowCreateArtifact": true,
    "allowOverwriteTargetArtifactLabel": true,
    "allowPurgeData": false,
    "allowTakeOver": true,
    "allowSkipTilesWithMissingPrerequisites": true
  },
  "note": "Release v2.1.0"
}
```

### Deploy Selective

```json
{
  "sourceStageOrder": 0,
  "datasets": [{ "sourceId": "{datasetId}" }],
  "reports": [{ "sourceId": "{reportId}" }],
  "dashboards": [{ "sourceId": "{dashboardId}" }],
  "options": { "allowOverwriteArtifact": true }
}
```

## Embed Tokens

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/reports/{id}/GenerateToken` | Token for single report |
| POST | `/dashboards/{id}/GenerateToken` | Token for dashboard |
| POST | `/datasets/{id}/GenerateToken` | Token for dataset (Q&A, create report) |
| POST | `/GenerateToken` | Multi-resource token |

### Multi-Resource Token

```json
{
  "datasets": [
    { "id": "{datasetId}", "xmlaPermissions": "ReadOnly" }
  ],
  "reports": [
    { "id": "{reportId}", "allowEdit": true }
  ],
  "targetWorkspaces": [
    { "id": "{workspaceId}" }
  ],
  "identities": [
    {
      "username": "user@domain.com",
      "roles": ["ReaderRole"],
      "datasets": ["{datasetId}"]
    }
  ],
  "lifetimeInMinutes": 60
}
```

## Admin APIs

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/admin/groups` | List all workspaces in tenant |
| GET | `/admin/groups/{id}/users` | Get workspace users |
| POST | `/admin/groups/{id}/users` | Add user to any workspace |
| GET | `/admin/datasets` | List all datasets in tenant |
| GET | `/admin/reports` | List all reports in tenant |
| GET | `/admin/dashboards` | List all dashboards in tenant |
| GET | `/admin/imports` | List all imports |
| GET | `/admin/activityevents` | Get activity events (audit) |
| POST | `/admin/workspaces/getInfo` | Initiate workspace scan |
| GET | `/admin/workspaces/scanResult/{scanId}` | Get scan results |
| GET | `/admin/capacities` | List all capacities |
| POST | `/admin/groups/{id}/AssignToCapacity` | Assign workspace to capacity |
| GET | `/admin/tenantSettings` | Get tenant settings |

## Gateways

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/gateways` | List gateways |
| GET | `/gateways/{id}` | Get gateway |
| GET | `/gateways/{id}/datasources` | List data sources |
| POST | `/gateways/{id}/datasources` | Create data source |
| DELETE | `/gateways/{id}/datasources/{dsId}` | Delete data source |
| PATCH | `/gateways/{id}/datasources/{dsId}` | Update credentials |
| GET | `/gateways/{id}/datasources/{dsId}/status` | Check source status |

## Error Codes

| HTTP Status | Error Code | Meaning |
|-------------|-----------|---------|
| 400 | BadRequest | Invalid request body |
| 401 | Unauthorized | Invalid or expired token |
| 403 | Forbidden | Insufficient permissions |
| 404 | NotFound | Resource not found |
| 409 | Conflict | Name conflict during import |
| 429 | TooManyRequests | Rate limit exceeded (retry after header) |
| 500 | InternalServerError | Service error (retry) |

## Rate Limits

| Operation | Limit |
|-----------|-------|
| General API calls | 200 requests per minute per user |
| Admin APIs | 200 requests per minute per tenant |
| Refresh (Pro) | 8 per day per dataset |
| Refresh (Premium/PPU) | 48 per day per dataset |
| Embed token generation | 600 per hour per workspace |
| Export to file | 5 concurrent per user |
| Import PBIX | 50 MB for shared capacity, 1 GB for Premium |

## SDK Libraries

| Language | Package | Install |
|----------|---------|---------|
| .NET | Microsoft.PowerBI.Api | `dotnet add package Microsoft.PowerBI.Api` |
| Python | azure-mgmt-powerbiembedded | `pip install azure-mgmt-powerbiembedded` |
| JavaScript | powerbi-client | `npm install powerbi-client` |
| PowerShell | MicrosoftPowerBIMgmt | `Install-Module MicrosoftPowerBIMgmt` |
