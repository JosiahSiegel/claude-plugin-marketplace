# Terraform Reference

Complete Terraform configuration for production-ready Azure ML workspace deployment.

---

## Full Production-Ready Terraform Configuration

```hcl
# ========================================
# providers.tf
# ========================================
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# ========================================
# data.tf
# ========================================
data "azurerm_client_config" "current" {}

# ========================================
# variables.tf
# ========================================
variable "resource_group_name" {
  type    = string
  default = "ml-production-rg"
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "workspace_name" {
  type    = string
  default = "ml-prod-workspace"
}

variable "environment" {
  type    = string
  default = "production"
}

variable "managed_network_isolation_mode" {
  type        = string
  default     = "AllowInternetOutbound"
  description = "Disabled, AllowInternetOutbound, or AllowOnlyApprovedOutbound"
}

# ========================================
# resource-group.tf
# ========================================
resource "azurerm_resource_group" "ml" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Purpose     = "Machine Learning"
  }
}

# ========================================
# networking.tf
# ========================================
resource "azurerm_virtual_network" "ml" {
  name                = "${var.workspace_name}-vnet"
  location            = azurerm_resource_group.ml.location
  resource_group_name = azurerm_resource_group.ml.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "private_endpoints" {
  name                 = "private-endpoints"
  resource_group_name  = azurerm_resource_group.ml.name
  virtual_network_name = azurerm_virtual_network.ml.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "compute" {
  name                 = "compute"
  resource_group_name  = azurerm_resource_group.ml.name
  virtual_network_name = azurerm_virtual_network.ml.name
  address_prefixes     = ["10.0.2.0/24"]
}

# NSG for compute subnet
resource "azurerm_network_security_group" "compute" {
  name                = "${var.workspace_name}-compute-nsg"
  location            = azurerm_resource_group.ml.location
  resource_group_name = azurerm_resource_group.ml.name

  security_rule {
    name                       = "AllowAzureMLInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "44224"
    source_address_prefix      = "AzureMachineLearning"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowBatchInbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["29876", "29877"]
    source_address_prefix      = "BatchNodeManagement"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowAzureServicesOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefixes = [
      "AzureMachineLearning",
      "Storage",
      "AzureActiveDirectory",
      "AzureResourceManager",
      "AzureContainerRegistry",
      "AzureKeyVault",
      "AzureMonitor",
      "AzureFrontDoor.Frontend",
      "MicrosoftContainerRegistry",
    ]
  }
}

resource "azurerm_subnet_network_security_group_association" "compute" {
  subnet_id                 = azurerm_subnet.compute.id
  network_security_group_id = azurerm_network_security_group.compute.id
}

# Private DNS Zones
locals {
  private_dns_zones = [
    "privatelink.api.azureml.ms",
    "privatelink.notebooks.azure.net",
    "privatelink.blob.core.windows.net",
    "privatelink.file.core.windows.net",
    "privatelink.vaultcore.azure.net",
    "privatelink.azurecr.io",
    "privatelink.monitor.azure.com",
  ]
}

resource "azurerm_private_dns_zone" "zones" {
  for_each            = toset(local.private_dns_zones)
  name                = each.value
  resource_group_name = azurerm_resource_group.ml.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "links" {
  for_each              = toset(local.private_dns_zones)
  name                  = "${replace(each.value, ".", "-")}-link"
  resource_group_name   = azurerm_resource_group.ml.name
  private_dns_zone_name = azurerm_private_dns_zone.zones[each.value].name
  virtual_network_id    = azurerm_virtual_network.ml.id
  registration_enabled  = false
}

# ========================================
# storage.tf
# ========================================
resource "azurerm_storage_account" "ml" {
  name                            = "mlstorage${random_string.suffix.result}"
  location                        = azurerm_resource_group.ml.location
  resource_group_name             = azurerm_resource_group.ml.name
  account_tier                    = "Standard"
  account_replication_type        = "ZRS"
  account_kind                    = "StorageV2"
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true  # Required for Azure ML

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Private endpoint for blob
resource "azurerm_private_endpoint" "storage_blob" {
  name                = "${azurerm_storage_account.ml.name}-blob-pe"
  location            = azurerm_resource_group.ml.location
  resource_group_name = azurerm_resource_group.ml.name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "storage-blob-connection"
    private_connection_resource_id = azurerm_storage_account.ml.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.zones["privatelink.blob.core.windows.net"].id]
  }
}

# Private endpoint for file
resource "azurerm_private_endpoint" "storage_file" {
  name                = "${azurerm_storage_account.ml.name}-file-pe"
  location            = azurerm_resource_group.ml.location
  resource_group_name = azurerm_resource_group.ml.name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "storage-file-connection"
    private_connection_resource_id = azurerm_storage_account.ml.id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.zones["privatelink.file.core.windows.net"].id]
  }
}

# ========================================
# keyvault.tf
# ========================================
resource "azurerm_key_vault" "ml" {
  name                       = "mlkv${random_string.suffix.result}"
  location                   = azurerm_resource_group.ml.location
  resource_group_name        = azurerm_resource_group.ml.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  purge_protection_enabled   = true
  soft_delete_retention_days = 90
  enable_rbac_authorization  = true

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }
}

resource "azurerm_private_endpoint" "keyvault" {
  name                = "${azurerm_key_vault.ml.name}-pe"
  location            = azurerm_resource_group.ml.location
  resource_group_name = azurerm_resource_group.ml.name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "keyvault-connection"
    private_connection_resource_id = azurerm_key_vault.ml.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.zones["privatelink.vaultcore.azure.net"].id]
  }
}

# ========================================
# acr.tf
# ========================================
resource "azurerm_container_registry" "ml" {
  name                = "mlacr${random_string.suffix.result}"
  location            = azurerm_resource_group.ml.location
  resource_group_name = azurerm_resource_group.ml.name
  sku                 = "Premium"  # Required for private endpoint
  admin_enabled       = true       # Required for Azure ML

  network_rule_set {
    default_action = "Deny"
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_private_endpoint" "acr" {
  name                = "${azurerm_container_registry.ml.name}-pe"
  location            = azurerm_resource_group.ml.location
  resource_group_name = azurerm_resource_group.ml.name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "acr-connection"
    private_connection_resource_id = azurerm_container_registry.ml.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.zones["privatelink.azurecr.io"].id]
  }
}

# ========================================
# application-insights.tf
# ========================================
resource "azurerm_log_analytics_workspace" "ml" {
  name                = "${var.workspace_name}-logs"
  location            = azurerm_resource_group.ml.location
  resource_group_name = azurerm_resource_group.ml.name
  sku                 = "PerGB2018"
  retention_in_days   = 90
}

resource "azurerm_application_insights" "ml" {
  name                = "${var.workspace_name}-appinsights"
  location            = azurerm_resource_group.ml.location
  resource_group_name = azurerm_resource_group.ml.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.ml.id
}

# ========================================
# ml-workspace.tf
# ========================================
resource "azurerm_machine_learning_workspace" "ml" {
  name                          = var.workspace_name
  location                      = azurerm_resource_group.ml.location
  resource_group_name           = azurerm_resource_group.ml.name
  application_insights_id       = azurerm_application_insights.ml.id
  key_vault_id                  = azurerm_key_vault.ml.id
  storage_account_id            = azurerm_storage_account.ml.id
  container_registry_id         = azurerm_container_registry.ml.id
  public_network_access_enabled = false
  image_build_compute_name      = "cpu-build-cluster"
  high_business_impact          = true

  managed_network {
    isolation_mode = var.managed_network_isolation_mode
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  depends_on = [
    azurerm_private_endpoint.storage_blob,
    azurerm_private_endpoint.storage_file,
    azurerm_private_endpoint.keyvault,
    azurerm_private_endpoint.acr,
  ]
}

# Private endpoint for workspace
resource "azurerm_private_endpoint" "workspace" {
  name                = "${var.workspace_name}-pe"
  location            = azurerm_resource_group.ml.location
  resource_group_name = azurerm_resource_group.ml.name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "workspace-connection"
    private_connection_resource_id = azurerm_machine_learning_workspace.ml.id
    subresource_names              = ["amlworkspace"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name = "default"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.zones["privatelink.api.azureml.ms"].id,
      azurerm_private_dns_zone.zones["privatelink.notebooks.azure.net"].id,
    ]
  }
}

# ========================================
# ml-compute.tf
# ========================================
# CPU cluster for image builds and general training
resource "azurerm_machine_learning_compute_cluster" "cpu_build" {
  name                          = "cpu-build-cluster"
  location                      = azurerm_resource_group.ml.location
  machine_learning_workspace_id = azurerm_machine_learning_workspace.ml.id
  vm_priority                   = "Dedicated"
  vm_size                       = "Standard_DS3_v2"

  scale_settings {
    min_node_count                       = 0
    max_node_count                       = 4
    scale_down_nodes_after_idle_duration = "PT120S"
  }

  identity {
    type = "SystemAssigned"
  }
}

# GPU cluster for training
resource "azurerm_machine_learning_compute_cluster" "gpu_training" {
  name                          = "gpu-training-cluster"
  location                      = azurerm_resource_group.ml.location
  machine_learning_workspace_id = azurerm_machine_learning_workspace.ml.id
  vm_priority                   = "Dedicated"
  vm_size                       = "Standard_NC24ads_A100_v4"

  scale_settings {
    min_node_count                       = 0
    max_node_count                       = 4
    scale_down_nodes_after_idle_duration = "PT300S"
  }

  identity {
    type = "SystemAssigned"
  }
}

# Low-priority GPU cluster for cost savings
resource "azurerm_machine_learning_compute_cluster" "gpu_spot" {
  name                          = "gpu-spot-cluster"
  location                      = azurerm_resource_group.ml.location
  machine_learning_workspace_id = azurerm_machine_learning_workspace.ml.id
  vm_priority                   = "LowPriority"
  vm_size                       = "Standard_NC24ads_A100_v4"

  scale_settings {
    min_node_count                       = 0
    max_node_count                       = 8
    scale_down_nodes_after_idle_duration = "PT120S"
  }

  identity {
    type = "SystemAssigned"
  }
}

# Compute instance for development
resource "azurerm_machine_learning_compute_instance" "dev" {
  name                          = "dev-instance"
  machine_learning_workspace_id = azurerm_machine_learning_workspace.ml.id
  virtual_machine_size          = "Standard_DS3_v2"
  authorization_type            = "personal"
  description                   = "Development compute instance"

  assign_to_user {
    object_id = data.azurerm_client_config.current.object_id
    tenant_id = data.azurerm_client_config.current.tenant_id
  }
}

# ========================================
# role-assignments.tf
# ========================================
# Workspace identity -> Storage Blob Data Contributor
resource "azurerm_role_assignment" "ws_storage_blob" {
  scope                = azurerm_storage_account.ml.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_machine_learning_workspace.ml.identity[0].principal_id
}

# Workspace identity -> Storage File Data Privileged Contributor
resource "azurerm_role_assignment" "ws_storage_file" {
  scope                = azurerm_storage_account.ml.id
  role_definition_name = "Storage File Data Privileged Contributor"
  principal_id         = azurerm_machine_learning_workspace.ml.identity[0].principal_id
}

# Workspace identity -> Key Vault Administrator
resource "azurerm_role_assignment" "ws_keyvault" {
  scope                = azurerm_key_vault.ml.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = azurerm_machine_learning_workspace.ml.identity[0].principal_id
}

# Workspace identity -> AcrPush on ACR
resource "azurerm_role_assignment" "ws_acr_push" {
  scope                = azurerm_container_registry.ml.id
  role_definition_name = "AcrPush"
  principal_id         = azurerm_machine_learning_workspace.ml.identity[0].principal_id
}

# GPU cluster identity -> AcrPull
resource "azurerm_role_assignment" "gpu_acr_pull" {
  scope                = azurerm_container_registry.ml.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_machine_learning_compute_cluster.gpu_training.identity[0].principal_id
}

# GPU cluster identity -> Storage Blob Data Reader
resource "azurerm_role_assignment" "gpu_storage_reader" {
  scope                = azurerm_storage_account.ml.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_machine_learning_compute_cluster.gpu_training.identity[0].principal_id
}

# ========================================
# outbound-rules.tf (for managed network)
# ========================================
resource "azurerm_machine_learning_workspace_network_outbound_rule_private_endpoint" "external_storage" {
  count                = var.managed_network_isolation_mode != "Disabled" ? 1 : 0
  name                 = "external-data-storage"
  workspace_id         = azurerm_machine_learning_workspace.ml.id
  service_resource_id  = azurerm_storage_account.ml.id  # or external storage
  sub_resource_target  = "blob"
}

# ========================================
# outputs.tf
# ========================================
output "workspace_id" {
  value = azurerm_machine_learning_workspace.ml.id
}

output "workspace_name" {
  value = azurerm_machine_learning_workspace.ml.name
}

output "workspace_discovery_url" {
  value = azurerm_machine_learning_workspace.ml.discovery_url
}

output "storage_account_name" {
  value = azurerm_storage_account.ml.name
}

output "acr_login_server" {
  value = azurerm_container_registry.ml.login_server
}

output "key_vault_uri" {
  value = azurerm_key_vault.ml.vault_uri
}
```

## All Terraform Resources for Azure ML

| Resource | Purpose |
|----------|---------|
| `azurerm_machine_learning_workspace` | ML workspace (kind: Default, FeatureStore, Hub, Project) |
| `azurerm_machine_learning_compute_cluster` | AmlCompute training clusters |
| `azurerm_machine_learning_compute_instance` | Dev/test compute instances |
| `azurerm_machine_learning_inference_cluster` | AKS-based inference cluster |
| `azurerm_machine_learning_synapse_spark` | Synapse Spark compute |
| `azurerm_machine_learning_datastore_blobstorage` | Blob datastore |
| `azurerm_machine_learning_datastore_datalake_gen2` | ADLS Gen2 datastore |
| `azurerm_machine_learning_datastore_fileshare` | File share datastore |
| `azurerm_machine_learning_workspace_network_outbound_rule_private_endpoint` | Managed network PE outbound rules |
| `azurerm_machine_learning_workspace_network_outbound_rule_fqdn` | Managed network FQDN outbound rules |
| `azurerm_machine_learning_workspace_network_outbound_rule_service_tag` | Managed network service tag rules |
| `azurerm_private_endpoint` | Private endpoints for all dependent resources |
| `azurerm_role_assignment` | RBAC role assignments for identities |
