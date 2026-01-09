# AzureRM Provider 4.x Reference (2025)

## Overview
- 1,101+ resources
- 360+ data sources
- Provider-defined functions
- Improved resource provider registration

## Key Features

### Provider-Defined Functions
```hcl
# Use provider functions directly
locals {
  # Normalize Azure location names
  location = provider::azurerm::normalize_location("East US 2")

  # Parse resource IDs
  parsed = provider::azurerm::parse_resource_id(azurerm_resource_group.main.id)
}
```

### AKS Enhancements
```hcl
resource "azurerm_kubernetes_cluster" "main" {
  name                = "my-aks"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "my-aks"

  default_node_pool {
    name       = "default"
    node_count = 3
    vm_size    = "Standard_D4s_v3"

    # AzureRM 4.x: AzureLinux OS support
    os_sku = "AzureLinux"

    # AzureRM 4.x: Node provisioning profile
    upgrade_settings {
      max_surge = "33%"
    }
  }

  # AzureRM 4.x: AI toolchain operator
  ai_toolchain_operator_enabled = true

  # AzureRM 4.x: Workload identity
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  identity {
    type = "SystemAssigned"
  }
}
```

### Azure OpenAI
```hcl
resource "azurerm_cognitive_account" "openai" {
  name                = "my-openai"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  kind                = "OpenAI"
  sku_name            = "S0"

  # AzureRM 4.x: Enhanced network configuration
  network_acls {
    default_action = "Deny"
    ip_rules       = ["1.2.3.4/32"]
  }
}

resource "azurerm_cognitive_deployment" "gpt4" {
  name                 = "gpt-4"
  cognitive_account_id = azurerm_cognitive_account.openai.id

  model {
    format  = "OpenAI"
    name    = "gpt-4"
    version = "turbo-2024-04-09"
  }

  sku {
    name     = "Standard"
    capacity = 120
  }
}
```

## Migration from 3.x to 4.x

### Breaking Changes
```hcl
# 3.x - Some properties renamed
resource "azurerm_storage_account" "old" {
  allow_blob_public_access = false  # Deprecated
}

# 4.x - Updated property names
resource "azurerm_storage_account" "new" {
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true
}
```

### Resource Provider Registration
```hcl
provider "azurerm" {
  features {}

  # AzureRM 4.x: Improved provider registration
  resource_provider_registrations = "core"  # Or "none", "all", "extended"
}
```

## New Resources (4.x)

### AI & ML
- `azurerm_machine_learning_workspace`
- `azurerm_cognitive_account` (OpenAI)
- `azurerm_cognitive_deployment`

### Kubernetes
- `azurerm_kubernetes_cluster_node_pool`
- `azurerm_kubernetes_fleet_manager`

### Networking
- `azurerm_virtual_network_gateway_nat_rule`
- `azurerm_express_route_port_authorization`

## Best Practices

### Version Pinning
```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}
```

### Features Block
```hcl
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }

    resource_group {
      prevent_deletion_if_contains_resources = false
    }

    virtual_machine {
      delete_os_disk_on_deletion     = true
      graceful_shutdown              = false
      skip_shutdown_and_force_delete = false
    }
  }
}
```
