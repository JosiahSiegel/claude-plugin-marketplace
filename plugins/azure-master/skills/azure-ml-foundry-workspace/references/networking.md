# Networking Reference

Complete reference for Azure ML networking, VNet integration, private endpoints, DNS zones, NSG rules, and service tags.

---

## Network Isolation Modes

Azure ML supports three managed network isolation modes:

| Mode | Inbound | Outbound | Use Case |
|------|---------|----------|----------|
| Disabled | Public | Public | Dev/test, non-sensitive data |
| AllowInternetOutbound | Private (PE) | Internet + Private endpoints | Most production workloads |
| AllowOnlyApprovedOutbound | Private (PE) | Only approved FQDNs + PEs | High-security, regulated environments |

## Managed Virtual Network (Recommended)

Azure ML creates and manages a VNet for you. All computes (instances, clusters, serverless, managed endpoints) run inside this managed VNet.

```bash
# Create workspace with managed VNet - AllowInternetOutbound
az ml workspace create \
  --name secure-workspace \
  --resource-group ml-rg \
  --location eastus \
  --managed-network AllowInternetOutbound

# Create workspace with managed VNet - AllowOnlyApprovedOutbound
az ml workspace create \
  --name lockdown-workspace \
  --resource-group ml-rg \
  --location eastus \
  --managed-network AllowOnlyApprovedOutbound

# Provision managed network (creates private endpoints to dependencies)
az ml workspace provision-network \
  --name secure-workspace \
  --resource-group ml-rg \
  --include-spark

# Add outbound rule - private endpoint to external storage
az ml workspace outbound-rule set \
  --name secure-workspace \
  --resource-group ml-rg \
  --rule-name external-storage-pe \
  --type private_endpoint \
  --service-resource-id /subscriptions/<sub>/resourceGroups/data-rg/providers/Microsoft.Storage/storageAccounts/externalstorage \
  --sub-resource-target blob \
  --spark-enabled false

# Add outbound rule - FQDN (for AllowOnlyApprovedOutbound)
az ml workspace outbound-rule set \
  --name lockdown-workspace \
  --resource-group ml-rg \
  --rule-name pypi-access \
  --type fqdn \
  --destination "pypi.org"

# Add outbound rule - service tag
az ml workspace outbound-rule set \
  --name secure-workspace \
  --resource-group ml-rg \
  --rule-name azure-monitor \
  --type service_tag \
  --service-tag AzureMonitor \
  --protocol TCP \
  --port-ranges "443"

# List outbound rules
az ml workspace outbound-rule list \
  --name secure-workspace \
  --resource-group ml-rg \
  --output table

# Remove outbound rule
az ml workspace outbound-rule remove \
  --name secure-workspace \
  --resource-group ml-rg \
  --rule-name external-storage-pe
```

## Private Endpoints for Workspace

A private endpoint on your own VNet provides inbound connectivity to the workspace.

```bash
# Create VNet and subnet for private endpoint
az network vnet create \
  --name ml-vnet \
  --resource-group ml-rg \
  --address-prefix 10.0.0.0/16 \
  --subnet-name pe-subnet \
  --subnet-prefix 10.0.1.0/24

# Disable private endpoint network policies on subnet
az network vnet subnet update \
  --name pe-subnet \
  --resource-group ml-rg \
  --vnet-name ml-vnet \
  --disable-private-endpoint-network-policies true

# Create private endpoint for workspace
az network private-endpoint create \
  --name ml-workspace-pe \
  --resource-group ml-rg \
  --vnet-name ml-vnet \
  --subnet pe-subnet \
  --private-connection-resource-id $(az ml workspace show -n my-ml-workspace -g ml-rg --query id -o tsv) \
  --group-id amlworkspace \
  --connection-name ml-workspace-connection

# Create private DNS zone
az network private-dns zone create \
  --resource-group ml-rg \
  --name privatelink.api.azureml.ms

az network private-dns zone create \
  --resource-group ml-rg \
  --name privatelink.notebooks.azure.net

# Link DNS zone to VNet
az network private-dns link vnet create \
  --resource-group ml-rg \
  --zone-name privatelink.api.azureml.ms \
  --name ml-dns-link \
  --virtual-network ml-vnet \
  --registration-enabled false

az network private-dns link vnet create \
  --resource-group ml-rg \
  --zone-name privatelink.notebooks.azure.net \
  --name ml-notebooks-dns-link \
  --virtual-network ml-vnet \
  --registration-enabled false

# Create DNS zone group for automatic DNS record management
az network private-endpoint dns-zone-group create \
  --resource-group ml-rg \
  --endpoint-name ml-workspace-pe \
  --name default \
  --private-dns-zone privatelink.api.azureml.ms \
  --zone-name api

az network private-endpoint dns-zone-group add \
  --resource-group ml-rg \
  --endpoint-name ml-workspace-pe \
  --name default \
  --private-dns-zone privatelink.notebooks.azure.net \
  --zone-name notebooks
```

## Required Private DNS Zones for Azure ML

| Service | Private DNS Zone |
|---------|-----------------|
| ML Workspace API | privatelink.api.azureml.ms |
| ML Notebooks | privatelink.notebooks.azure.net |
| Storage Blob | privatelink.blob.core.windows.net |
| Storage File | privatelink.file.core.windows.net |
| Storage Table | privatelink.table.core.windows.net |
| Storage Queue | privatelink.queue.core.windows.net |
| Key Vault | privatelink.vaultcore.azure.net |
| Container Registry | privatelink.azurecr.io |
| Application Insights | privatelink.monitor.azure.com |

## NSG Rules for Azure ML Compute

When using BYO VNet (not managed network), the following NSG rules are required:

```bash
# Create NSG
az network nsg create \
  --name ml-compute-nsg \
  --resource-group ml-rg

# INBOUND rules
# Allow Azure Machine Learning service (for compute management)
az network nsg rule create \
  --nsg-name ml-compute-nsg \
  --resource-group ml-rg \
  --name AllowAzureMLInbound \
  --priority 100 \
  --direction Inbound \
  --source-address-prefixes AzureMachineLearning \
  --destination-port-ranges 44224 \
  --protocol TCP \
  --access Allow

# Allow Azure Batch management
az network nsg rule create \
  --nsg-name ml-compute-nsg \
  --resource-group ml-rg \
  --name AllowBatchNodeManagement \
  --priority 110 \
  --direction Inbound \
  --source-address-prefixes BatchNodeManagement \
  --destination-port-ranges 29876-29877 \
  --protocol TCP \
  --access Allow

# OUTBOUND rules
# Allow Azure Storage (for data access)
az network nsg rule create \
  --nsg-name ml-compute-nsg \
  --resource-group ml-rg \
  --name AllowStorageOutbound \
  --priority 100 \
  --direction Outbound \
  --destination-address-prefixes Storage \
  --destination-port-ranges 443 \
  --protocol TCP \
  --access Allow

# Allow Azure ML service
az network nsg rule create \
  --nsg-name ml-compute-nsg \
  --resource-group ml-rg \
  --name AllowAzureMLOutbound \
  --priority 110 \
  --direction Outbound \
  --destination-address-prefixes AzureMachineLearning \
  --destination-port-ranges 443 \
  --protocol TCP \
  --access Allow

# Allow Azure Active Directory
az network nsg rule create \
  --nsg-name ml-compute-nsg \
  --resource-group ml-rg \
  --name AllowAADOutbound \
  --priority 120 \
  --direction Outbound \
  --destination-address-prefixes AzureActiveDirectory \
  --destination-port-ranges 443 \
  --protocol TCP \
  --access Allow

# Allow Azure Resource Manager
az network nsg rule create \
  --nsg-name ml-compute-nsg \
  --resource-group ml-rg \
  --name AllowARMOutbound \
  --priority 130 \
  --direction Outbound \
  --destination-address-prefixes AzureResourceManager \
  --destination-port-ranges 443 \
  --protocol TCP \
  --access Allow

# Allow Azure Container Registry
az network nsg rule create \
  --nsg-name ml-compute-nsg \
  --resource-group ml-rg \
  --name AllowACROutbound \
  --priority 140 \
  --direction Outbound \
  --destination-address-prefixes AzureContainerRegistry \
  --destination-port-ranges 443 \
  --protocol TCP \
  --access Allow

# Allow Azure Key Vault
az network nsg rule create \
  --nsg-name ml-compute-nsg \
  --resource-group ml-rg \
  --name AllowKeyVaultOutbound \
  --priority 150 \
  --direction Outbound \
  --destination-address-prefixes AzureKeyVault \
  --destination-port-ranges 443 \
  --protocol TCP \
  --access Allow

# Allow Azure Monitor (for logging)
az network nsg rule create \
  --nsg-name ml-compute-nsg \
  --resource-group ml-rg \
  --name AllowAzureMonitorOutbound \
  --priority 160 \
  --direction Outbound \
  --destination-address-prefixes AzureMonitor \
  --destination-port-ranges 443 \
  --protocol TCP \
  --access Allow
```

## Service Tags Reference for Azure ML

| Service Tag | Purpose |
|------------|---------|
| AzureMachineLearning | ML workspace management (inbound 44224, outbound 443, 8787, 18881) |
| BatchNodeManagement | Compute cluster management (inbound 29876-29877) |
| Storage | Access to Azure Storage (outbound 443) |
| AzureActiveDirectory | Authentication (outbound 443) |
| AzureResourceManager | ARM API calls (outbound 443) |
| AzureContainerRegistry | Pull Docker images (outbound 443) |
| AzureKeyVault | Secrets access (outbound 443) |
| AzureMonitor | Telemetry and logging (outbound 443) |
| AzureFrontDoor.Frontend | ML Studio UI access (outbound 443) |
| MicrosoftContainerRegistry | Base images (outbound 443) |
