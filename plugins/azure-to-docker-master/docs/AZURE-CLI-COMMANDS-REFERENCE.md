# Azure CLI Commands Reference for Infrastructure Extraction

Complete reference for extracting Azure infrastructure details for Docker containerization.

## Table of Contents
- [Authentication & Setup](#authentication--setup)
- [Web Apps & App Services](#web-apps--app-services)
- [Databases](#databases)
- [Storage](#storage)
- [Caching](#caching)
- [Key Vault](#key-vault)
- [Monitoring](#monitoring)
- [Networking](#networking)
- [Resource Management](#resource-management)
- [Advanced Queries](#advanced-queries)

---

## Authentication & Setup

### Login to Azure
```bash
# Interactive login (opens browser)
az login

# Login with service principal
az login --service-principal \
    --username <client-id> \
    --password <client-secret> \
    --tenant <tenant-id>

# Login with managed identity (from Azure VM)
az login --identity

# Device code login (for SSH/headless)
az login --use-device-code
```

### Subscription Management
```bash
# List all subscriptions
az account list --output table

# Show current subscription
az account show

# Set default subscription
az account set --subscription "subscription-name-or-id"

# Show subscription details with JSON
az account show --output json
```

### Resource Group Operations
```bash
# List all resource groups
az group list --output table

# Check if resource group exists
az group exists --name <resource-group-name>

# Show resource group details
az group show --name <resource-group-name>

# List all resources in a resource group
az resource list \
    --resource-group <resource-group-name> \
    --output table

# Export resource group as ARM template
az group export \
    --name <resource-group-name> \
    --output json > resource-group-template.json
```

---

## Web Apps & App Services

### List Web Apps
```bash
# List all web apps in subscription
az webapp list --output table

# List web apps in resource group
az webapp list \
    --resource-group <resource-group-name> \
    --output table

# Get web app names only
az webapp list \
    --resource-group <resource-group-name> \
    --query "[].name" \
    --output tsv
```

### Web App Configuration
```bash
# Get complete web app configuration
az webapp show \
    --name <webapp-name> \
    --resource-group <resource-group-name> \
    --output json

# Get runtime stack information
az webapp show \
    --name <webapp-name> \
    --resource-group <resource-group-name> \
    --query "{linuxFx:siteConfig.linuxFxVersion, windowsFx:siteConfig.windowsFxVersion, nodeVersion:siteConfig.nodeVersion, pythonVersion:siteConfig.pythonVersion, phpVersion:siteConfig.phpVersion, javaVersion:siteConfig.javaVersion, netFramework:siteConfig.netFrameworkVersion}"

# Get detailed site configuration
az webapp config show \
    --name <webapp-name> \
    --resource-group <resource-group-name> \
    --output json
```

### Application Settings (Environment Variables)
```bash
# List all app settings
az webapp config appsettings list \
    --name <webapp-name> \
    --resource-group <resource-group-name> \
    --output json

# Get app settings in .env format
az webapp config appsettings list \
    --name <webapp-name> \
    --resource-group <resource-group-name> \
    --query "[].{name:name, value:value}" \
    --output json | jq -r '.[] | "\(.name)=\(.value)"'

# Get specific app setting
az webapp config appsettings list \
    --name <webapp-name> \
    --resource-group <resource-group-name> \
    --query "[?name=='SETTING_NAME'].value" \
    --output tsv
```

### Connection Strings
```bash
# List all connection strings
az webapp config connection-string list \
    --name <webapp-name> \
    --resource-group <resource-group-name> \
    --output json

# Get connection string values
az webapp config connection-string list \
    --name <webapp-name> \
    --resource-group <resource-group-name> \
    --query "{connections: [].{name:name, value:value, type:type}}"
```

### Container Settings
```bash
# Get container configuration (for containerized apps)
az webapp config container show \
    --name <webapp-name> \
    --resource-group <resource-group-name>

# Get container registry settings
az webapp config container show \
    --name <webapp-name> \
    --resource-group <resource-group-name> \
    --query "{registry:dockerRegistryServerUrl, username:dockerRegistryServerUserName, image:linuxFxVersion}"
```

### Deployment Configuration
```bash
# Get deployment source information
az webapp deployment source show \
    --name <webapp-name> \
    --resource-group <resource-group-name>

# List deployment slots
az webapp deployment slot list \
    --name <webapp-name> \
    --resource-group <resource-group-name>

# Download web app content (Kudu API method)
# This requires publishing credentials
az webapp deployment list-publishing-credentials \
    --name <webapp-name> \
    --resource-group <resource-group-name>
```

### Scaling & Performance
```bash
# Get scaling configuration
az webapp config show \
    --name <webapp-name> \
    --resource-group <resource-group-name> \
    --query "{numberOfWorkers:numberOfWorkers, autoHeal:autoHealEnabled, alwaysOn:alwaysOn}"

# Get App Service Plan (for scaling info)
az appservice plan show \
    --name <plan-name> \
    --resource-group <resource-group-name> \
    --query "{sku:sku.name, tier:sku.tier, capacity:sku.capacity, numberOfWorkers:numberOfWorkers}"
```

### Managed Identity & Authentication
```bash
# Get managed identity details
az webapp identity show \
    --name <webapp-name> \
    --resource-group <resource-group-name>

# Get authentication settings
az webapp auth show \
    --name <webapp-name> \
    --resource-group <resource-group-name>
```

### Networking
```bash
# Get VNet integration
az webapp vnet-integration list \
    --name <webapp-name> \
    --resource-group <resource-group-name>

# Get IP restrictions
az webapp config access-restriction show \
    --name <webapp-name> \
    --resource-group <resource-group-name>

# Get outbound IP addresses
az webapp show \
    --name <webapp-name> \
    --resource-group <resource-group-name> \
    --query "{outboundIps:outboundIpAddresses, possibleOutboundIps:possibleOutboundIpAddresses}"
```

### App Service Plans
```bash
# List all App Service Plans
az appservice plan list \
    --resource-group <resource-group-name> \
    --output table

# Get App Service Plan details
az appservice plan show \
    --name <plan-name> \
    --resource-group <resource-group-name> \
    --query "{name:name, sku:sku.name, tier:sku.tier, location:location, kind:kind, numberOfSites:numberOfSites, maximumNumberOfWorkers:maximumNumberOfWorkers}"
```

---

## Databases

### Azure SQL Database

#### List SQL Servers
```bash
# List all SQL servers in resource group
az sql server list \
    --resource-group <resource-group-name> \
    --output table

# Get SQL server details
az sql server show \
    --name <server-name> \
    --resource-group <resource-group-name> \
    --output json
```

#### SQL Server Configuration
```bash
# Get fully qualified domain name
az sql server show \
    --name <server-name> \
    --resource-group <resource-group-name> \
    --query fullyQualifiedDomainName \
    --output tsv

# List firewall rules
az sql server firewall-rule list \
    --server <server-name> \
    --resource-group <resource-group-name> \
    --output table

# Get server connection policy
az sql server conn-policy show \
    --server <server-name> \
    --resource-group <resource-group-name>

# List Active Directory administrators
az sql server ad-admin list \
    --server <server-name> \
    --resource-group <resource-group-name>
```

#### SQL Databases
```bash
# List all databases on a server
az sql db list \
    --server <server-name> \
    --resource-group <resource-group-name> \
    --output table

# List user databases (exclude master)
az sql db list \
    --server <server-name> \
    --resource-group <resource-group-name> \
    --query "[?name!='master']" \
    --output table

# Get database details
az sql db show \
    --name <database-name> \
    --server <server-name> \
    --resource-group <resource-group-name> \
    --output json

# Get database SKU and performance tier
az sql db show \
    --name <database-name> \
    --server <server-name> \
    --resource-group <resource-group-name> \
    --query "{sku:sku.name, tier:sku.tier, capacity:sku.capacity, maxSizeBytes:maxSizeBytes, collation:collation, status:status}"
```

#### Export SQL Database
```bash
# Export database to BACPAC (requires storage account)
az sql db export \
    --name <database-name> \
    --server <server-name> \
    --resource-group <resource-group-name> \
    --admin-user <admin-username> \
    --admin-password <admin-password> \
    --storage-key-type StorageAccessKey \
    --storage-key <storage-key> \
    --storage-uri https://<storage-account>.blob.core.windows.net/backups/<database-name>.bacpac

# Generate connection string
# Format: Server=tcp:<server>.database.windows.net,1433;Initial Catalog=<database>;Persist Security Info=False;User ID=<username>;Password=<password>;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;
```

### PostgreSQL

#### List PostgreSQL Servers
```bash
# List PostgreSQL servers
az postgres server list \
    --resource-group <resource-group-name> \
    --output table

# Get PostgreSQL server details
az postgres server show \
    --name <server-name> \
    --resource-group <resource-group-name> \
    --output json
```

#### PostgreSQL Configuration
```bash
# Get FQDN
az postgres server show \
    --name <server-name> \
    --resource-group <resource-group-name> \
    --query fullyQualifiedDomainName \
    --output tsv

# List firewall rules
az postgres server firewall-rule list \
    --server-name <server-name> \
    --resource-group <resource-group-name> \
    --output table

# List server parameters
az postgres server configuration list \
    --server-name <server-name> \
    --resource-group <resource-group-name> \
    --output table

# Get specific configuration parameter
az postgres server configuration show \
    --server-name <server-name> \
    --resource-group <resource-group-name> \
    --name <parameter-name>

# Get SSL enforcement status
az postgres server show \
    --name <server-name> \
    --resource-group <resource-group-name> \
    --query "{sslEnforcement:sslEnforcement, minTlsVersion:minimalTlsVersion, version:version}"
```

#### PostgreSQL Databases
```bash
# List databases on PostgreSQL server
az postgres db list \
    --server-name <server-name> \
    --resource-group <resource-group-name> \
    --output table

# Get database details
az postgres db show \
    --name <database-name> \
    --server-name <server-name> \
    --resource-group <resource-group-name>

# Connection string format:
# postgresql://<username>@<server-name>:<password>@<server-name>.postgres.database.azure.com:5432/<database>?sslmode=require
```

### MySQL

#### List MySQL Servers
```bash
# List MySQL servers
az mysql server list \
    --resource-group <resource-group-name> \
    --output table

# Get MySQL server details
az mysql server show \
    --name <server-name> \
    --resource-group <resource-group-name> \
    --output json
```

#### MySQL Configuration
```bash
# Get FQDN
az mysql server show \
    --name <server-name> \
    --resource-group <resource-group-name> \
    --query fullyQualifiedDomainName \
    --output tsv

# List firewall rules
az mysql server firewall-rule list \
    --server-name <server-name> \
    --resource-group <resource-group-name> \
    --output table

# List server parameters
az mysql server configuration list \
    --server-name <server-name> \
    --resource-group <resource-group-name> \
    --output table

# Get version and SSL settings
az mysql server show \
    --name <server-name> \
    --resource-group <resource-group-name> \
    --query "{sslEnforcement:sslEnforcement, version:version, sku:sku}"
```

#### MySQL Databases
```bash
# List databases
az mysql db list \
    --server-name <server-name> \
    --resource-group <resource-group-name> \
    --output table

# Get database details
az mysql db show \
    --name <database-name> \
    --server-name <server-name> \
    --resource-group <resource-group-name>
```

### Cosmos DB

#### List Cosmos DB Accounts
```bash
# List Cosmos DB accounts
az cosmosdb list \
    --resource-group <resource-group-name> \
    --output table

# Get Cosmos DB account details
az cosmosdb show \
    --name <account-name> \
    --resource-group <resource-group-name> \
    --output json
```

#### Cosmos DB Configuration
```bash
# Get connection strings
az cosmosdb keys list \
    --name <account-name> \
    --resource-group <resource-group-name> \
    --type connection-strings

# Get account keys
az cosmosdb keys list \
    --name <account-name> \
    --resource-group <resource-group-name> \
    --type keys

# Get read-only keys
az cosmosdb keys list \
    --name <account-name> \
    --resource-group <resource-group-name> \
    --type read-only-keys

# Get capabilities and consistency
az cosmosdb show \
    --name <account-name> \
    --resource-group <resource-group-name> \
    --query "{capabilities:capabilities, consistencyPolicy:consistencyPolicy, kind:kind}"
```

#### Cosmos DB Databases
```bash
# List SQL API databases
az cosmosdb sql database list \
    --account-name <account-name> \
    --resource-group <resource-group-name>

# List containers in a database
az cosmosdb sql container list \
    --account-name <account-name> \
    --resource-group <resource-group-name> \
    --database-name <database-name>

# List MongoDB databases (if using MongoDB API)
az cosmosdb mongodb database list \
    --account-name <account-name> \
    --resource-group <resource-group-name>
```

---

## Storage

### List Storage Accounts
```bash
# List all storage accounts
az storage account list \
    --resource-group <resource-group-name> \
    --output table

# Get storage account details
az storage account show \
    --name <account-name> \
    --resource-group <resource-group-name> \
    --output json
```

### Storage Account Configuration
```bash
# Get storage account keys
az storage account keys list \
    --account-name <account-name> \
    --resource-group <resource-group-name> \
    --output table

# Get connection string
az storage account show-connection-string \
    --name <account-name> \
    --resource-group <resource-group-name> \
    --output tsv

# Get account properties
az storage account show \
    --name <account-name> \
    --resource-group <resource-group-name> \
    --query "{sku:sku.name, kind:kind, location:location, encryption:encryption.services, accessTier:accessTier, enableHttpsTrafficOnly:enableHttpsTrafficOnly}"
```

### Blob Storage
```bash
# List blob containers
az storage container list \
    --account-name <account-name> \
    --auth-mode login \
    --output table

# Or with account key
az storage container list \
    --account-name <account-name> \
    --account-key <account-key> \
    --output table

# Get container properties
az storage container show \
    --name <container-name> \
    --account-name <account-name> \
    --auth-mode login

# List blobs in container
az storage blob list \
    --container-name <container-name> \
    --account-name <account-name> \
    --auth-mode login \
    --output table
```

### Queue Storage
```bash
# List queues
az storage queue list \
    --account-name <account-name> \
    --auth-mode login \
    --output table

# Get queue metadata
az storage queue metadata show \
    --name <queue-name> \
    --account-name <account-name> \
    --auth-mode login
```

### Table Storage
```bash
# List tables
az storage table list \
    --account-name <account-name> \
    --auth-mode login \
    --output table
```

### File Shares
```bash
# List file shares
az storage share list \
    --account-name <account-name> \
    --auth-mode login \
    --output table

# Get file share details
az storage share show \
    --name <share-name> \
    --account-name <account-name> \
    --auth-mode login
```

---

## Caching

### Azure Redis Cache

#### List Redis Caches
```bash
# List all Redis caches
az redis list \
    --resource-group <resource-group-name> \
    --output table

# Get Redis cache details
az redis show \
    --name <cache-name> \
    --resource-group <resource-group-name> \
    --output json
```

#### Redis Configuration
```bash
# Get access keys
az redis list-keys \
    --name <cache-name> \
    --resource-group <resource-group-name>

# Get hostname and port
az redis show \
    --name <cache-name> \
    --resource-group <resource-group-name> \
    --query "{hostName:hostName, port:port, sslPort:sslPort, enableNonSslPort:enableNonSslPort}"

# Get Redis configuration settings
az redis show \
    --name <cache-name> \
    --resource-group <resource-group-name> \
    --query "{sku:sku, redisVersion:redisVersion, redisConfiguration:redisConfiguration}"

# Get firewall rules
az redis firewall-rules list \
    --name <cache-name> \
    --resource-group <resource-group-name>
```

---

## Key Vault

### List Key Vaults
```bash
# List all Key Vaults in resource group
az keyvault list \
    --resource-group <resource-group-name> \
    --output table

# Get Key Vault details
az keyvault show \
    --name <vault-name> \
    --output json
```

### Key Vault Configuration
```bash
# Get vault URI
az keyvault show \
    --name <vault-name> \
    --query properties.vaultUri \
    --output tsv

# Get access policies
az keyvault show \
    --name <vault-name> \
    --query "properties.accessPolicies"
```

### Secrets
```bash
# List secret names (not values)
az keyvault secret list \
    --vault-name <vault-name> \
    --query "[].{name:name, enabled:attributes.enabled, expires:attributes.expires}" \
    --output table

# Get secret value
az keyvault secret show \
    --vault-name <vault-name> \
    --name <secret-name> \
    --query value \
    --output tsv

# Export all secrets (USE WITH CAUTION)
for secret in $(az keyvault secret list --vault-name <vault-name> --query "[].name" -o tsv); do
    value=$(az keyvault secret show --vault-name <vault-name> --name $secret --query value -o tsv)
    echo "$secret=$value"
done
```

### Keys
```bash
# List keys
az keyvault key list \
    --vault-name <vault-name> \
    --query "[].{name:name, enabled:attributes.enabled, kty:key.kty}" \
    --output table
```

### Certificates
```bash
# List certificates
az keyvault certificate list \
    --vault-name <vault-name> \
    --query "[].{name:name, enabled:attributes.enabled, expires:attributes.expires}" \
    --output table

# Get certificate
az keyvault certificate show \
    --vault-name <vault-name> \
    --name <cert-name>
```

---

## Monitoring

### Application Insights

#### List Application Insights
```bash
# List all Application Insights components
az monitor app-insights component show \
    --resource-group <resource-group-name> \
    --output table

# Get component details
az monitor app-insights component show \
    --app <app-name> \
    --resource-group <resource-group-name> \
    --output json
```

#### Application Insights Configuration
```bash
# Get instrumentation key and connection string
az monitor app-insights component show \
    --app <app-name> \
    --resource-group <resource-group-name> \
    --query "{instrumentationKey:instrumentationKey, connectionString:connectionString, appId:appId}"

# Get application ID
az monitor app-insights component show \
    --app <app-name> \
    --resource-group <resource-group-name> \
    --query appId \
    --output tsv
```

---

## Networking

### Virtual Networks
```bash
# List virtual networks
az network vnet list \
    --resource-group <resource-group-name> \
    --output table

# Get VNet details
az network vnet show \
    --name <vnet-name> \
    --resource-group <resource-group-name>

# List subnets
az network vnet subnet list \
    --vnet-name <vnet-name> \
    --resource-group <resource-group-name> \
    --output table
```

### Network Security Groups
```bash
# List NSGs
az network nsg list \
    --resource-group <resource-group-name> \
    --output table

# Get NSG rules
az network nsg rule list \
    --nsg-name <nsg-name> \
    --resource-group <resource-group-name> \
    --output table
```

### Load Balancers
```bash
# List load balancers
az network lb list \
    --resource-group <resource-group-name> \
    --output table

# Get load balancer details
az network lb show \
    --name <lb-name> \
    --resource-group <resource-group-name>
```

### Application Gateways
```bash
# List application gateways
az network application-gateway list \
    --resource-group <resource-group-name> \
    --output table

# Get application gateway details
az network application-gateway show \
    --name <gateway-name> \
    --resource-group <resource-group-name>
```

---

## Resource Management

### Tagging
```bash
# Get resource tags
az resource show \
    --ids <resource-id> \
    --query tags

# List resources by tag
az resource list \
    --tag Environment=Production \
    --output table
```

### Resource Graph Queries
```bash
# Query all resources with Azure Resource Graph
az graph query -q "Resources | project name, type, location"

# Query specific resource types
az graph query -q "Resources | where type == 'microsoft.web/sites' | project name, location, kind"

# Query resources in a resource group
az graph query -q "Resources | where resourceGroup == '<resource-group-name>' | project name, type, location"

# Get all web apps with their settings
az graph query -q "Resources | where type == 'microsoft.web/sites' | project name, id, location, properties"
```

---

## Advanced Queries

### JMESPath Query Examples

#### Filter by Property
```bash
# Get running VMs only
az vm list --query "[?powerState=='VM running']"

# Get resources by location
az resource list \
    --resource-group <rg> \
    --query "[?location=='eastus']"
```

#### Select Specific Fields
```bash
# Get name and location only
az webapp list \
    --query "[].{Name:name, Location:location}" \
    --output table

# Get nested properties
az webapp show \
    --name <name> \
    --resource-group <rg> \
    --query "siteConfig.appSettings[?name=='WEBSITE_NODE_DEFAULT_VERSION'].value"
```

#### Use Functions
```bash
# Sort results
az vm list \
    --query "sort_by([].{Name:name, Size:hardwareProfile.vmSize}, &Name)" \
    --output table

# Filter with contains
az resource list \
    --query "[?contains(name, 'prod')]" \
    --output table

# Length of array
az webapp list \
    --query "length([])"
```

### Batch Operations
```bash
# Get all web app names and process
for webapp in $(az webapp list --resource-group <rg> --query "[].name" -o tsv); do
    echo "Processing: $webapp"
    az webapp config appsettings list --name $webapp --resource-group <rg>
done

# Parallel execution
for webapp in $(az webapp list --resource-group <rg> --query "[].name" -o tsv); do
    az webapp stop --name $webapp --resource-group <rg> --no-wait &
done
wait
```

### Export Entire Resource Group
```bash
# Export as ARM template
az group export \
    --name <resource-group-name> \
    --output json > full-export.json

# Get all resource IDs
az resource list \
    --resource-group <resource-group-name> \
    --query "[].id" \
    --output tsv > resource-ids.txt

# Get detailed info for each resource
while read -r id; do
    az resource show --ids "$id" --output json >> resources-detail.json
done < resource-ids.txt
```

---

## Complete Extraction Script Example

```bash
#!/bin/bash
# Complete infrastructure extraction

RESOURCE_GROUP="my-resource-group"
OUTPUT_DIR="./extracted-$(date +%Y%m%d)"

mkdir -p "$OUTPUT_DIR"

# All resources
az resource list --resource-group "$RESOURCE_GROUP" --output json > "$OUTPUT_DIR/all-resources.json"

# Web apps
for webapp in $(az webapp list --resource-group "$RESOURCE_GROUP" --query "[].name" -o tsv); do
    mkdir -p "$OUTPUT_DIR/webapps/$webapp"
    az webapp show --name "$webapp" --resource-group "$RESOURCE_GROUP" > "$OUTPUT_DIR/webapps/$webapp/config.json"
    az webapp config appsettings list --name "$webapp" --resource-group "$RESOURCE_GROUP" > "$OUTPUT_DIR/webapps/$webapp/settings.json"
done

# SQL Databases
for server in $(az sql server list --resource-group "$RESOURCE_GROUP" --query "[].name" -o tsv); do
    mkdir -p "$OUTPUT_DIR/sql/$server"
    az sql server show --name "$server" --resource-group "$RESOURCE_GROUP" > "$OUTPUT_DIR/sql/$server/config.json"
    az sql db list --server "$server" --resource-group "$RESOURCE_GROUP" > "$OUTPUT_DIR/sql/$server/databases.json"
done

# Storage accounts
for storage in $(az storage account list --resource-group "$RESOURCE_GROUP" --query "[].name" -o tsv); do
    mkdir -p "$OUTPUT_DIR/storage/$storage"
    az storage account show --name "$storage" --resource-group "$RESOURCE_GROUP" > "$OUTPUT_DIR/storage/$storage/config.json"
    az storage account keys list --account-name "$storage" --resource-group "$RESOURCE_GROUP" > "$OUTPUT_DIR/storage/$storage/keys.json"
done

echo "Extraction complete: $OUTPUT_DIR"
```

---

## Security Best Practices

### DO NOT:
- ❌ Hardcode credentials in scripts
- ❌ Commit access keys or connection strings to version control
- ❌ Share exported keys.json or connection-string.json files
- ❌ Run scripts as root/admin unless necessary

### DO:
- ✅ Use Azure Key Vault for secrets
- ✅ Use managed identities when possible
- ✅ Store credentials in environment variables
- ✅ Add sensitive files to .gitignore
- ✅ Use service principals with minimum required permissions
- ✅ Enable audit logging for all operations

### Example .gitignore
```text
# Sensitive files
**/*keys.json
**/*connection-string*.json
**/*.env
!**/*.env.example
**/secrets*.json
**/credentials*.json
```

---

## Troubleshooting

### Common Issues

**Issue: "Authentication failed"**
```bash
# Clear cache and re-login
az account clear
az login
```

**Issue: "Resource not found"**
```bash
# Verify you're in the correct subscription
az account show
az account set --subscription <subscription-id>

# Verify resource group exists
az group exists --name <resource-group-name>
```

**Issue: "Insufficient permissions"**
```bash
# Check your role assignments
az role assignment list --assignee <your-user-or-sp>

# Required roles: Reader (minimum), Contributor, or Owner
```

**Issue: "Quota exceeded"**
```bash
# Check current quota usage
az vm list-usage --location eastus --output table
```

---

## Additional Resources

- [Azure CLI Documentation](https://docs.microsoft.com/cli/azure/)
- [JMESPath Tutorial](http://jmespath.org/tutorial.html)
- [Azure Resource Graph](https://docs.microsoft.com/azure/governance/resource-graph/)
- [Azure ARM Templates](https://docs.microsoft.com/azure/azure-resource-manager/templates/)
- [SqlPackage CLI](https://docs.microsoft.com/sql/tools/sqlpackage/)
- [pg_dump Documentation](https://www.postgresql.org/docs/current/app-pgdump.html)
- [mysqldump Documentation](https://dev.mysql.com/doc/refman/8.0/en/mysqldump.html)

---

**Last Updated**: 2025-10-25
**Azure CLI Version**: 2.x
