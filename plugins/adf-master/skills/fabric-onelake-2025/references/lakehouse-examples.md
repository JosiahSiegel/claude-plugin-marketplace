# Fabric Lakehouse JSON Examples

## Linked Service Configuration

**Using Service Principal Authentication (Recommended):**
```json
{
  "name": "FabricLakehouseLinkedService",
  "type": "Microsoft.DataFactory/factories/linkedservices",
  "properties": {
    "type": "Lakehouse",
    "typeProperties": {
      "workspaceId": "12345678-1234-1234-1234-123456789abc",
      "artifactId": "87654321-4321-4321-4321-cba987654321",
      "servicePrincipalId": "<app-registration-client-id>",
      "servicePrincipalKey": {
        "type": "AzureKeyVaultSecret",
        "store": {
          "referenceName": "AzureKeyVault",
          "type": "LinkedServiceReference"
        },
        "secretName": "fabric-service-principal-key"
      },
      "tenant": "<tenant-id>"
    }
  }
}
```

**Using Managed Identity Authentication (Preferred 2025):**
```json
{
  "name": "FabricLakehouseLinkedService_ManagedIdentity",
  "type": "Microsoft.DataFactory/factories/linkedservices",
  "properties": {
    "type": "Lakehouse",
    "typeProperties": {
      "workspaceId": "12345678-1234-1234-1234-123456789abc",
      "artifactId": "87654321-4321-4321-4321-cba987654321"
      // Managed identity used automatically - no credentials needed!
    }
  }
}
```

## Dataset Configuration

**For Lakehouse Files:**
```json
{
  "name": "FabricLakehouseFiles",
  "properties": {
    "type": "LakehouseTable",
    "linkedServiceName": {
      "referenceName": "FabricLakehouseLinkedService",
      "type": "LinkedServiceReference"
    },
    "typeProperties": {
      "table": "Files/raw/sales/2025"
    }
  }
}
```

**For Lakehouse Tables:**
```json
{
  "name": "FabricLakehouseTables",
  "properties": {
    "type": "LakehouseTable",
    "linkedServiceName": {
      "referenceName": "FabricLakehouseLinkedService",
      "type": "LinkedServiceReference"
    },
    "typeProperties": {
      "table": "SalesData"  // Table name in Lakehouse
    }
  }
}
```

## Copy Activity Examples

**Copy from Azure SQL to Fabric Lakehouse:**
```json
{
  "name": "CopyToFabricLakehouse",
  "type": "Copy",
  "inputs": [
    {
      "referenceName": "AzureSqlSource",
      "type": "DatasetReference"
    }
  ],
  "outputs": [
    {
      "referenceName": "FabricLakehouseTables",
      "type": "DatasetReference",
      "parameters": {
        "tableName": "DimCustomer"
      }
    }
  ],
  "typeProperties": {
    "source": {
      "type": "AzureSqlSource",
      "sqlReaderQuery": "SELECT * FROM dbo.Customers WHERE ModifiedDate > '@{pipeline().parameters.LastRunTime}'"
    },
    "sink": {
      "type": "LakehouseTableSink",
      "tableActionOption": "append"  // or "overwrite"
    },
    "enableStaging": false,
    "translator": {
      "type": "TabularTranslator",
      "mappings": [
        {
          "source": { "name": "CustomerID" },
          "sink": { "name": "customer_id", "type": "Int32" }
        },
        {
          "source": { "name": "CustomerName" },
          "sink": { "name": "customer_name", "type": "String" }
        }
      ]
    }
  }
}
```

**Copy Parquet Files to Fabric Lakehouse:**
```json
{
  "name": "CopyParquetToLakehouse",
  "type": "Copy",
  "inputs": [
    {
      "referenceName": "AzureBlobParquetFiles",
      "type": "DatasetReference"
    }
  ],
  "outputs": [
    {
      "referenceName": "FabricLakehouseFiles",
      "type": "DatasetReference"
    }
  ],
  "typeProperties": {
    "source": {
      "type": "ParquetSource",
      "storeSettings": {
        "type": "AzureBlobStorageReadSettings",
        "recursive": true,
        "wildcardFolderPath": "raw/sales/2025",
        "wildcardFileName": "*.parquet"
      }
    },
    "sink": {
      "type": "LakehouseFileSink",
      "storeSettings": {
        "type": "LakehouseWriteSettings",
        "copyBehavior": "PreserveHierarchy"
      }
    }
  }
}
```

## Lookup Activity Example

```json
{
  "name": "LookupFabricLakehouseTable",
  "type": "Lookup",
  "typeProperties": {
    "source": {
      "type": "LakehouseTableSource",
      "query": "SELECT MAX(LastUpdated) as MaxDate FROM SalesData"
    },
    "dataset": {
      "referenceName": "FabricLakehouseTables",
      "type": "DatasetReference"
    }
  }
}
```
