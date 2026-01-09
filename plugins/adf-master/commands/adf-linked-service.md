---
name: adf-linked-service
description: Generate ADF linked service JSON for any connector with proper authentication
argument-hint: "<connector-type> <authentication-method>"
allowed-tools:
  - Read
  - Write
  - Glob
---

# ADF Linked Service Generator

Generate Azure Data Factory linked service JSON configurations with proper authentication and best practices.

## Task

Create a complete, valid linked service JSON based on the specified connector type and authentication method.

## Arguments

- `$ARGUMENTS`: Connector type and optional authentication method
  - Example: `blob managed-identity`
  - Example: `azure-sql service-principal`
  - Example: `rest oauth2`
  - Example: `sftp ssh-key`
  - Example: `fabric-lakehouse`

## Supported Connectors

### Storage
- `blob` / `azure-blob` - Azure Blob Storage
- `adls` / `adls-gen2` - Azure Data Lake Storage Gen2
- `azure-files` - Azure File Storage

### Databases
- `azure-sql` / `sql-database` - Azure SQL Database
- `synapse` / `azure-synapse` - Azure Synapse Analytics
- `sql-server` - SQL Server (on-prem or VM)
- `postgresql` - PostgreSQL
- `snowflake` - Snowflake

### Microsoft Fabric
- `fabric-lakehouse` - Microsoft Fabric Lakehouse
- `fabric-warehouse` - Microsoft Fabric Warehouse

### APIs and Services
- `rest` / `rest-api` - REST API
- `http` - HTTP Server
- `sftp` - SFTP Server
- `databricks` - Azure Databricks
- `keyvault` / `key-vault` - Azure Key Vault

### SaaS Connectors
- `servicenow` - ServiceNow (V2)
- `salesforce` - Salesforce

## Authentication Methods

| Method | Description | Applicable To |
|--------|-------------|---------------|
| `managed-identity` / `mi` | System-assigned managed identity (Recommended) | Blob, ADLS, SQL, Synapse, REST, Databricks |
| `service-principal` / `sp` | Azure AD application | Blob, ADLS, SQL, Synapse, REST, Databricks, Fabric |
| `connection-string` / `cs` | Connection string | Blob, SQL |
| `account-key` | Storage account key | Blob, ADLS |
| `sas` | Shared Access Signature | Blob, ADLS |
| `sql-auth` | SQL Server authentication | SQL, Synapse |
| `basic` | Username/password | REST, SFTP |
| `oauth2` | OAuth 2.0 client credentials | REST, ServiceNow |
| `access-token` | Personal access token | Databricks |
| `ssh-key` | SSH public key | SFTP |
| `key-pair` | Key pair authentication | Snowflake |

## Generation Rules

### Naming Convention
`LS_<Connector>_<Purpose>_<AuthMethod>`
- Example: `LS_AzureBlobStorage_DataLake_MI`
- Example: `LS_AzureSql_Staging_SP`

### Required Properties by Auth Method

**Managed Identity (Blob Storage):**
```json
{
  "type": "AzureBlobStorage",
  "typeProperties": {
    "serviceEndpoint": "https://<account>.blob.core.windows.net",
    "accountKind": "StorageV2"  // CRITICAL - REQUIRED for MI!
  }
}
```

**Service Principal:**
```json
{
  "typeProperties": {
    "servicePrincipalId": "<app-id>",
    "servicePrincipalKey": {
      "type": "AzureKeyVaultSecret",
      "store": { "referenceName": "LS_KeyVault", "type": "LinkedServiceReference" },
      "secretName": "<secret-name>"
    },
    "tenant": "<tenant-id>"
  }
}
```

### Best Practices Applied

1. **Never hardcode secrets** - Always use Key Vault references
2. **Use Managed Identity** when possible (most secure)
3. **Include connectVia** for private endpoints or SHIR
4. **Parameterize** for multi-environment deployment
5. **Set accountKind** for Blob Storage with MI/SP

## Output Format

Generate complete JSON with:
1. Linked service definition
2. Comments explaining key properties
3. Required RBAC roles or permissions
4. Key Vault secret requirements (if applicable)
5. Parameter file snippet for CI/CD

```json
// Linked Service: LS_AzureBlobStorage_DataLake_MI
// Required Role: Storage Blob Data Reader (source) or Contributor (sink)
// Pre-requisite: ADF managed identity must be assigned the role
{
  "name": "LS_AzureBlobStorage_DataLake_MI",
  "type": "Microsoft.DataFactory/factories/linkedservices",
  "properties": {
    "type": "AzureBlobStorage",
    "typeProperties": {
      "serviceEndpoint": "https://mystorageaccount.blob.core.windows.net",
      "accountKind": "StorageV2"
    },
    "connectVia": {
      "referenceName": "AutoResolveIntegrationRuntime",
      "type": "IntegrationRuntimeReference"
    }
  }
}
```

## Common Gotchas

1. **Blob + Managed Identity**: MUST include `accountKind`
2. **SQL + Managed Identity**: Must create contained database user
3. **REST + OAuth**: Need both `tokenEndpoint` and `resource`
4. **SFTP**: Consider `skipHostKeyValidation` for dev environments only
5. **Databricks**: Use Job activity (2025) not Notebook for new implementations
