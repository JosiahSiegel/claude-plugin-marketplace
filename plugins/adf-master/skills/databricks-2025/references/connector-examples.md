# ADF 2025 Connector JSON Examples

## ServiceNow V2 Connector

**CRITICAL: ServiceNow V1 connector is at End of Support stage. Migrate to V2 immediately!**

**Copy Activity Example:**
```json
{
  "name": "CopyFromServiceNowV2",
  "type": "Copy",
  "inputs": [
    {
      "referenceName": "ServiceNowV2Source",
      "type": "DatasetReference"
    }
  ],
  "outputs": [
    {
      "referenceName": "AzureSqlSink",
      "type": "DatasetReference"
    }
  ],
  "typeProperties": {
    "source": {
      "type": "ServiceNowV2Source",
      "query": "sysparm_query=active=true^priority=1^sys_created_on>=javascript:gs.dateGenerate('2025-01-01')",
      "httpRequestTimeout": "00:01:40"  // 100 seconds
    },
    "sink": {
      "type": "AzureSqlSink",
      "writeBehavior": "upsert",
      "upsertSettings": {
        "useTempDB": true,
        "keys": ["sys_id"]
      }
    },
    "enableStaging": true,
    "stagingSettings": {
      "linkedServiceName": {
        "referenceName": "AzureBlobStorage",
        "type": "LinkedServiceReference"
      }
    }
  }
}
```

**Linked Service (OAuth2 - Recommended):**
```json
{
  "name": "ServiceNowV2LinkedService",
  "type": "Microsoft.DataFactory/factories/linkedservices",
  "properties": {
    "type": "ServiceNowV2",
    "typeProperties": {
      "endpoint": "https://dev12345.service-now.com",
      "authenticationType": "OAuth2",
      "clientId": "your-oauth-client-id",
      "clientSecret": {
        "type": "AzureKeyVaultSecret",
        "store": {
          "referenceName": "AzureKeyVault",
          "type": "LinkedServiceReference"
        },
        "secretName": "servicenow-client-secret"
      },
      "username": "service-account@company.com",
      "password": {
        "type": "AzureKeyVaultSecret",
        "store": {
          "referenceName": "AzureKeyVault",
          "type": "LinkedServiceReference"
        },
        "secretName": "servicenow-password"
      },
      "grantType": "password"
    }
  }
}
```

**Linked Service (Basic Authentication - Legacy):**
```json
{
  "name": "ServiceNowV2LinkedService_Basic",
  "type": "Microsoft.DataFactory/factories/linkedservices",
  "properties": {
    "type": "ServiceNowV2",
    "typeProperties": {
      "endpoint": "https://dev12345.service-now.com",
      "authenticationType": "Basic",
      "username": "admin",
      "password": {
        "type": "AzureKeyVaultSecret",
        "store": {
          "referenceName": "AzureKeyVault",
          "type": "LinkedServiceReference"
        },
        "secretName": "servicenow-password"
      }
    }
  }
}
```

## Enhanced PostgreSQL Connector

```json
{
  "name": "PostgreSQLLinkedService",
  "type": "PostgreSql",
  "typeProperties": {
    "connectionString": "host=myserver.postgres.database.azure.com;port=5432;database=mydb;uid=myuser",
    "password": {
      "type": "AzureKeyVaultSecret",
      "store": { "referenceName": "KeyVault" },
      "secretName": "postgres-password"
    },
    // 2025 enhancement
    "enableSsl": true,
    "sslMode": "Require"
  }
}
```

## Enhanced Snowflake Connector

```json
{
  "name": "SnowflakeLinkedService",
  "type": "Snowflake",
  "typeProperties": {
    "connectionString": "jdbc:snowflake://myaccount.snowflakecomputing.com",
    "database": "mydb",
    "warehouse": "mywarehouse",
    "authenticationType": "KeyPair",
    "username": "myuser",
    "privateKey": {
      "type": "AzureKeyVaultSecret",
      "store": { "referenceName": "KeyVault" },
      "secretName": "snowflake-private-key"
    },
    "privateKeyPassphrase": {
      "type": "AzureKeyVaultSecret",
      "store": { "referenceName": "KeyVault" },
      "secretName": "snowflake-passphrase"
    }
  }
}
```

## Azure Storage Managed Identity

### Azure Table Storage

```json
{
  "name": "AzureTableStorageLinkedService",
  "type": "AzureTableStorage",
  "typeProperties": {
    "serviceEndpoint": "https://mystorageaccount.table.core.windows.net",
    "authenticationType": "ManagedIdentity"
    // Or user-assigned:
    // "credential": {
    //   "referenceName": "UserAssignedManagedIdentity"
    // }
  }
}
```

### Azure Files

```json
{
  "name": "AzureFilesLinkedService",
  "type": "AzureFileStorage",
  "typeProperties": {
    "fileShare": "myshare",
    "accountName": "mystorageaccount",
    "authenticationType": "ManagedIdentity"
  }
}
```

## Managed Identity JSON Examples

**System-Assigned Managed Identity:**
```json
{
  "type": "AzureBlobStorage",
  "typeProperties": {
    "serviceEndpoint": "https://mystorageaccount.blob.core.windows.net",
    "accountKind": "StorageV2"
    // Uses Data Factory's system-assigned identity automatically
  }
}
```

**User-Assigned Managed Identity:**
```json
{
  "type": "AzureBlobStorage",
  "typeProperties": {
    "serviceEndpoint": "https://mystorageaccount.blob.core.windows.net",
    "accountKind": "StorageV2",
    "credential": {
      "referenceName": "UserAssignedManagedIdentityCredential",
      "type": "CredentialReference"
    }
  }
}
```

**Credential Consolidation:**
```json
{
  "name": "ManagedIdentityCredential",
  "type": "Microsoft.DataFactory/factories/credentials",
  "properties": {
    "type": "ManagedIdentity",
    "typeProperties": {
      "resourceId": "/subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/{identity-name}"
    }
  }
}
```

**MFA-Compliant SQL Authentication:**
```json
{
  "type": "AzureSqlDatabase",
  "typeProperties": {
    "server": "myserver.database.windows.net",
    "database": "mydb",
    "authenticationType": "SystemAssignedManagedIdentity"
    // No MFA needed, no secret rotation, passwordless
  }
}
```

## Azure DevOps Server 2022 Support

```json
{
  "name": "DataFactory",
  "properties": {
    "repoConfiguration": {
      "type": "AzureDevOpsGit",
      "accountName": "on-prem-ado-server",
      "projectName": "MyProject",
      "repositoryName": "adf-repo",
      "collaborationBranch": "main",
      "rootFolder": "/",
      "hostName": "https://ado-server.company.com"  // On-premises server
    }
  }
}
```

## Mapping Data Flow Example

```json
{
  "name": "DataFlow1",
  "type": "MappingDataFlow",
  "typeProperties": {
    "sources": [
      {
        "dataset": { "referenceName": "SourceDataset" }
      }
    ],
    "transformations": [
      {
        "name": "Transform1"
      }
    ],
    "sinks": [
      {
        "dataset": { "referenceName": "SinkDataset" }
      }
    ]
  }
}
```
