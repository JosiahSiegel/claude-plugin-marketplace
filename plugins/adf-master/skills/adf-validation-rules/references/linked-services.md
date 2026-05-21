# ADF Linked Services Validation (Azure Blob, Azure SQL)

Detailed validation rules and templates for ADF Linked Services: Azure Blob Storage (auth types, key/SAS/managed-identity, network config), Azure SQL Database (auth types, AAD/managed-identity, connection-string patterns). SKILL.md keeps activity nesting rules, resource limits, validation checklists, and the enforcement protocol; this reference holds the linked-service-specific material.

## 📊 Linked Services: Azure Blob Storage

### Authentication Methods

#### 1. Account Key (Basic)
```json
{
  "type": "AzureBlobStorage",
  "typeProperties": {
    "connectionString": {
      "type": "SecureString",
      "value": "DefaultEndpointsProtocol=https;AccountName=<account>;AccountKey=<key>"
    }
  }
}
```
**⚠️ Limitations:**
- Secondary Blob service endpoints are **NOT supported**
- **Security Risk**: Account keys should be stored in Azure Key Vault

#### 2. Shared Access Signature (SAS)
```json
{
  "type": "AzureBlobStorage",
  "typeProperties": {
    "sasUri": {
      "type": "SecureString",
      "value": "https://<account>.blob.core.windows.net/<container>?<SAS-token>"
    }
  }
}
```
**Critical Requirements:**
- Dataset `folderPath` must be **absolute path from container level**
- SAS token expiry **must extend beyond pipeline execution**
- SAS URI path must align with dataset configuration

#### 3. Service Principal
```json
{
  "type": "AzureBlobStorage",
  "typeProperties": {
    "serviceEndpoint": "https://<account>.blob.core.windows.net",
    "accountKind": "StorageV2",  // REQUIRED for service principal
    "servicePrincipalId": "<client-id>",
    "servicePrincipalCredential": {
      "type": "SecureString",
      "value": "<client-secret>"
    },
    "tenant": "<tenant-id>"
  }
}
```
**Critical Requirements:**
- `accountKind` **MUST** be set (StorageV2, BlobStorage, or BlockBlobStorage)
- Service Principal requires **Storage Blob Data Reader** (source) or **Storage Blob Data Contributor** (sink) role
- ❌ **NOT compatible** with soft-deleted blob accounts in Data Flow

#### 4. Managed Identity (Recommended)
```json
{
  "type": "AzureBlobStorage",
  "typeProperties": {
    "serviceEndpoint": "https://<account>.blob.core.windows.net",
    "accountKind": "StorageV2"  // REQUIRED for managed identity
  },
  "connectVia": {
    "referenceName": "AutoResolveIntegrationRuntime",
    "type": "IntegrationRuntimeReference"
  }
}
```
**Critical Requirements:**
- `accountKind` **MUST** be specified (cannot be empty or "Storage")
- ❌ Empty or "Storage" account kind will cause Data Flow failures
- Managed identity must have **Storage Blob Data Reader/Contributor** role assigned
- For Storage firewall: **Must enable "Allow trusted Microsoft services"**

### Common Blob Storage Pitfalls

| Issue | Cause | Solution |
|-------|-------|----------|
| Data Flow fails with managed identity | `accountKind` empty or "Storage" | Set `accountKind` to StorageV2 |
| Secondary endpoint doesn't work | Using account key auth | Not supported - use different auth method |
| SAS token expired during run | Token expiry too short | Extend SAS token validity period |
| Cannot access $logs container | System container not visible in UI | Use direct path reference |
| Soft-deleted blobs inaccessible | Service principal/managed identity | Use account key or SAS instead |
| Private endpoint connection fails | Wrong endpoint for Data Flow | Ensure ADLS Gen2 private endpoint exists |

## 📊 Linked Services: Azure SQL Database

### Authentication Methods

#### 1. SQL Authentication
```json
{
  "type": "AzureSqlDatabase",
  "typeProperties": {
    "server": "<server-name>.database.windows.net",
    "database": "<database-name>",
    "authenticationType": "SQL",
    "userName": "<username>",
    "password": {
      "type": "SecureString",
      "value": "<password>"
    }
  }
}
```
**Best Practice:**
- Store password in Azure Key Vault
- Use connection string with Key Vault reference

#### 2. Service Principal
```json
{
  "type": "AzureSqlDatabase",
  "typeProperties": {
    "server": "<server-name>.database.windows.net",
    "database": "<database-name>",
    "authenticationType": "ServicePrincipal",
    "servicePrincipalId": "<client-id>",
    "servicePrincipalCredential": {
      "type": "SecureString",
      "value": "<client-secret>"
    },
    "tenant": "<tenant-id>"
  }
}
```
**Requirements:**
- Microsoft Entra admin must be configured on SQL server
- Service principal must have contained database user created
- Grant appropriate role: `db_datareader`, `db_datawriter`, etc.

#### 3. Managed Identity
```json
{
  "type": "AzureSqlDatabase",
  "typeProperties": {
    "server": "<server-name>.database.windows.net",
    "database": "<database-name>",
    "authenticationType": "SystemAssignedManagedIdentity"
  }
}
```
**Requirements:**
- Create contained database user for managed identity
- Grant appropriate database roles
- Configure firewall to allow Azure services (or specific IP ranges)

### SQL Database Configuration Best Practices

#### Connection String Parameters
```text
Server=tcp:<server>.database.windows.net,1433;
Database=<database>;
Encrypt=mandatory;          // Options: mandatory, optional, strict
TrustServerCertificate=false;
ConnectTimeout=30;
CommandTimeout=120;
Pooling=true;
ConnectRetryCount=3;
ConnectRetryInterval=10;
```

**Critical Parameters:**
- `Encrypt`: Default is `mandatory` (recommended)
- `Pooling`: Set to `false` if experiencing idle connection issues
- `ConnectRetryCount`: Recommended for transient fault handling
- `ConnectRetryInterval`: Seconds between retries

### Common SQL Database Pitfalls

| Issue | Cause | Solution |
|-------|-------|----------|
| Serverless tier auto-paused | Pipeline doesn't wait for resume | Implement retry logic or keep-alive |
| Connection pool timeout | Idle connections closed | Add `Pooling=false` or configure retry |
| Firewall blocks connection | IP not whitelisted | Add Azure IR IPs or enable Azure services |
| Always Encrypted fails in Data Flow | Not supported for sink | Use service principal/managed identity in copy activity |
| Decimal precision loss | Copy supports up to 28 precision | Use string type for higher precision |
| Parallel copy not working | No partition configuration | Enable physical or dynamic range partitioning |

### Performance Optimization

#### Parallel Copy Configuration
```json
{
  "source": {
    "type": "AzureSqlSource",
    "partitionOption": "PhysicalPartitionsOfTable"  // or "DynamicRange"
  },
  "parallelCopies": 8,  // Recommended: (DIU or IR nodes) × (2 to 4)
  "enableStaging": true,
  "stagingSettings": {
    "linkedServiceName": {
      "referenceName": "AzureBlobStorage",
      "type": "LinkedServiceReference"
    }
  }
}
```

**Partition Options:**
- `PhysicalPartitionsOfTable`: Uses SQL Server physical partitions
- `DynamicRange`: Creates logical partitions based on column values
- `None`: No partitioning (default)

**Staging Best Practices:**
- Always use staging for large data movements (> 1GB)
- Use PolyBase or COPY statement for best performance
- Parquet format recommended for staging files

