# Fabric Warehouse JSON Examples

## Linked Service Configuration

**Using Service Principal:**
```json
{
  "name": "FabricWarehouseLinkedService",
  "type": "Microsoft.DataFactory/factories/linkedservices",
  "properties": {
    "type": "Warehouse",
    "typeProperties": {
      "endpoint": "myworkspace.datawarehouse.fabric.microsoft.com",
      "warehouse": "MyWarehouse",
      "authenticationType": "ServicePrincipal",
      "servicePrincipalId": "<app-registration-id>",
      "servicePrincipalKey": {
        "type": "AzureKeyVaultSecret",
        "store": {
          "referenceName": "AzureKeyVault",
          "type": "LinkedServiceReference"
        },
        "secretName": "fabric-warehouse-sp-key"
      },
      "tenant": "<tenant-id>"
    }
  }
}
```

**Using System-Assigned Managed Identity (Recommended):**
```json
{
  "name": "FabricWarehouseLinkedService_SystemMI",
  "type": "Microsoft.DataFactory/factories/linkedservices",
  "properties": {
    "type": "Warehouse",
    "typeProperties": {
      "endpoint": "myworkspace.datawarehouse.fabric.microsoft.com",
      "warehouse": "MyWarehouse",
      "authenticationType": "SystemAssignedManagedIdentity"
    }
  }
}
```

**Using User-Assigned Managed Identity:**
```json
{
  "name": "FabricWarehouseLinkedService_UserMI",
  "type": "Microsoft.DataFactory/factories/linkedservices",
  "properties": {
    "type": "Warehouse",
    "typeProperties": {
      "endpoint": "myworkspace.datawarehouse.fabric.microsoft.com",
      "warehouse": "MyWarehouse",
      "authenticationType": "UserAssignedManagedIdentity",
      "credential": {
        "referenceName": "UserAssignedManagedIdentityCredential",
        "type": "CredentialReference"
      }
    }
  }
}
```

## Copy Activity to Fabric Warehouse

**Bulk Insert Pattern:**
```json
{
  "name": "CopyToFabricWarehouse",
  "type": "Copy",
  "inputs": [
    {
      "referenceName": "AzureSqlSource",
      "type": "DatasetReference"
    }
  ],
  "outputs": [
    {
      "referenceName": "FabricWarehouseSink",
      "type": "DatasetReference"
    }
  ],
  "typeProperties": {
    "source": {
      "type": "AzureSqlSource",
      "sqlReaderQuery": "SELECT * FROM dbo.FactSales WHERE OrderDate >= '@{pipeline().parameters.StartDate}'"
    },
    "sink": {
      "type": "WarehouseSink",
      "preCopyScript": "TRUNCATE TABLE staging.FactSales",
      "writeBehavior": "insert",
      "writeBatchSize": 10000,
      "tableOption": "autoCreate",  // Auto-create table if doesn't exist
      "disableMetricsCollection": false
    },
    "enableStaging": true,
    "stagingSettings": {
      "linkedServiceName": {
        "referenceName": "AzureBlobStorage",
        "type": "LinkedServiceReference"
      },
      "path": "staging/fabric-warehouse",
      "enableCompression": true
    },
    "parallelCopies": 4,
    "dataIntegrationUnits": 8
  }
}
```

**Upsert Pattern:**
```json
{
  "sink": {
    "type": "WarehouseSink",
    "writeBehavior": "upsert",
    "upsertSettings": {
      "useTempDB": true,
      "keys": ["customer_id"],
      "interimSchemaName": "staging"
    },
    "writeBatchSize": 10000
  }
}
```

## Stored Procedure Activity

```json
{
  "name": "ExecuteFabricWarehouseStoredProcedure",
  "type": "SqlServerStoredProcedure",
  "linkedServiceName": {
    "referenceName": "FabricWarehouseLinkedService",
    "type": "LinkedServiceReference"
  },
  "typeProperties": {
    "storedProcedureName": "dbo.usp_ProcessSalesData",
    "storedProcedureParameters": {
      "StartDate": {
        "value": "@pipeline().parameters.StartDate",
        "type": "DateTime"
      },
      "EndDate": {
        "value": "@pipeline().parameters.EndDate",
        "type": "DateTime"
      }
    }
  }
}
```

## Script Activity

```json
{
  "name": "ExecuteFabricWarehouseScript",
  "type": "Script",
  "linkedServiceName": {
    "referenceName": "FabricWarehouseLinkedService",
    "type": "LinkedServiceReference"
  },
  "typeProperties": {
    "scripts": [
      {
        "type": "Query",
        "text": "DELETE FROM staging.FactSales WHERE LoadDate < DATEADD(day, -30, GETDATE())"
      },
      {
        "type": "Query",
        "text": "UPDATE dbo.FactSales SET ProcessedFlag = 1 WHERE OrderDate = '@{pipeline().parameters.ProcessDate}'"
      }
    ],
    "scriptBlockExecutionTimeout": "02:00:00"
  }
}
```
