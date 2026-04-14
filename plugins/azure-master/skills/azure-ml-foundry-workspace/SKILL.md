---
name: azure-ml-foundry-workspace
description: Azure Machine Learning Workspace and Azure AI Foundry deep dive. PROACTIVELY activate for: (1) creating and configuring Azure ML workspaces, (2) Azure AI Foundry hubs and projects, (3) ML workspace networking (managed VNet, private endpoints, DNS), (4) ML compute clusters and compute instances, (5) managed online endpoints, batch endpoints, Kubernetes endpoints, (6) managed identities for ML resources, (7) ACR integration for custom environments, (8) storage account configuration, (9) az ml CLI v2 commands, (10) PowerShell Az.MachineLearningServices, (11) reading ML compute and deployment logs, (12) GPU SKU selection (ND/NC series, H100/H200/A100). Provides: workspace setup playbook, network-isolation patterns, endpoint deployment templates, az ml CLI cheat sheet, and log diagnosis workflow.
---

# Azure Machine Learning Workspace / Azure AI Foundry - Complete Deep-Dive Reference

Authoritative reference for every aspect of Azure Machine Learning Workspace (Azure AI Foundry) including architecture, networking, private endpoints, compute clusters, endpoint deployment, managed identities, ACR integration, storage accounts, all CLI and PowerShell commands, log reading, debugging, and Terraform integration.

---

## 1. ARCHITECTURE AND CORE CONCEPTS

### Workspace Resource Hierarchy

```
Azure Subscription
  └── Resource Group
        ├── Azure ML Workspace (Microsoft.MachineLearningServices/workspaces)
        │     ├── Dependent Resources (auto-created or BYO)
        │     │     ├── Azure Storage Account (default datastore)
        │     │     ├── Azure Key Vault (secrets, connection strings)
        │     │     ├── Azure Application Insights (telemetry)
        │     │     └── Azure Container Registry (Docker images for environments)
        │     ├── Compute Targets
        │     │     ├── Compute Instances (dev/test VMs)
        │     │     ├── Compute Clusters (AmlCompute - training)
        │     │     ├── Serverless Compute (on-demand)
        │     │     ├── Kubernetes Compute (AKS / Arc-enabled)
        │     │     └── Attached Compute (Databricks, HDInsight, VMs)
        │     ├── Data Assets (versioned references to data)
        │     ├── Datastores (connections to storage)
        │     ├── Environments (Docker + conda specs)
        │     ├── Models (registered trained models)
        │     ├── Endpoints
        │     │     ├── Managed Online Endpoints (real-time)
        │     │     ├── Kubernetes Online Endpoints (BYO infra)
        │     │     ├── Batch Endpoints (large-scale scoring)
        │     │     └── Serverless Endpoints (MaaS - pay-per-token)
        │     ├── Jobs (training runs, pipelines, sweeps)
        │     ├── Components (reusable pipeline steps)
        │     ├── Schedules (recurring job triggers)
        │     └── Registries (cross-workspace sharing)
        └── AI Foundry Hub (kind=hub) + Projects (kind=project)
```

### AI Foundry Hub/Project vs Classic Workspace

| Feature | Classic Workspace (kind=Default) | AI Foundry Hub + Project |
|---------|----------------------------------|--------------------------|
| Portal | ml.azure.com | ai.azure.com |
| Scope | Single workspace | Hub shares infra across projects |
| Networking | Per-workspace | Hub-level (shared across projects) |
| Identity | Per-workspace | Hub-level identity, project inherits |
| Model catalog | Yes | Yes, plus additional Foundry models |
| Prompt flow | Yes | Yes |
| AI agents | Limited | Full AI Agent Service |
| Use case | Classical ML, custom training | GenAI, LLM apps, AI agents |

### Workspace Creation - All Methods

**CLI:**
```bash
# Install/upgrade ML extension
az extension add --name ml --upgrade

# Create resource group
az group create --name ml-rg --location eastus

# Create workspace with all dependencies auto-created
az ml workspace create \
  --name my-ml-workspace \
  --resource-group ml-rg \
  --location eastus

# Create workspace with explicit dependencies
az ml workspace create \
  --name my-ml-workspace \
  --resource-group ml-rg \
  --location eastus \
  --storage-account /subscriptions/<sub>/resourceGroups/ml-rg/providers/Microsoft.Storage/storageAccounts/mlstorage \
  --key-vault /subscriptions/<sub>/resourceGroups/ml-rg/providers/Microsoft.KeyVault/vaults/mlkeyvault \
  --app-insights /subscriptions/<sub>/resourceGroups/ml-rg/providers/Microsoft.Insights/components/mlinsights \
  --container-registry /subscriptions/<sub>/resourceGroups/ml-rg/providers/Microsoft.ContainerRegistry/registries/mlacr \
  --public-network-access Disabled \
  --managed-network AllowInternetOutbound \
  --image-build-compute cpu-build-cluster \
  --enable-data-isolation true \
  --tags Environment=Production Team=DataScience

# Create AI Foundry Hub
az ml workspace create \
  --name my-ai-hub \
  --resource-group ml-rg \
  --location eastus \
  --kind hub \
  --storage-account aihubstorage \
  --key-vault aihubkeyvault

# Create AI Foundry Project within Hub
az ml workspace create \
  --name my-ai-project \
  --resource-group ml-rg \
  --location eastus \
  --kind project \
  --hub-id /subscriptions/<sub>/resourceGroups/ml-rg/providers/Microsoft.MachineLearningServices/workspaces/my-ai-hub

# Show workspace details
az ml workspace show \
  --name my-ml-workspace \
  --resource-group ml-rg

# List all workspaces
az ml workspace list \
  --resource-group ml-rg \
  --output table

# Update workspace
az ml workspace update \
  --name my-ml-workspace \
  --resource-group ml-rg \
  --description "Updated workspace" \
  --public-network-access Disabled

# Delete workspace
az ml workspace delete \
  --name my-ml-workspace \
  --resource-group ml-rg \
  --permanently-delete --all-resources

# Diagnose workspace configuration
az ml workspace diagnose \
  --name my-ml-workspace \
  --resource-group ml-rg
```

**PowerShell (Az.MachineLearningServices):**
```powershell
# Install the module
Install-Module -Name Az.MachineLearningServices -Scope CurrentUser -Repository PSGallery -Force

# Create workspace
New-AzMLWorkspace `
  -Name "my-ml-workspace" `
  -ResourceGroupName "ml-rg" `
  -Location "eastus" `
  -StorageAccountId "/subscriptions/<sub>/resourceGroups/ml-rg/providers/Microsoft.Storage/storageAccounts/mlstorage" `
  -KeyVaultId "/subscriptions/<sub>/resourceGroups/ml-rg/providers/Microsoft.KeyVault/vaults/mlkeyvault" `
  -ApplicationInsightId "/subscriptions/<sub>/resourceGroups/ml-rg/providers/Microsoft.Insights/components/mlinsights" `
  -IdentityType "SystemAssigned" `
  -PublicNetworkAccess "Disabled"

# Get workspace
Get-AzMLWorkspace -Name "my-ml-workspace" -ResourceGroupName "ml-rg"

# List workspaces
Get-AzMLWorkspace -ResourceGroupName "ml-rg"

# Update workspace
Update-AzMLWorkspace `
  -Name "my-ml-workspace" `
  -ResourceGroupName "ml-rg" `
  -Description "Updated workspace" `
  -Tag @{Environment="Production"}

# Remove workspace
Remove-AzMLWorkspace -Name "my-ml-workspace" -ResourceGroupName "ml-rg"

# Diagnose workspace
Invoke-AzMLWorkspaceDiagnose -Name "my-ml-workspace" -ResourceGroupName "ml-rg"
```

---

## 2. NETWORKING

Azure ML supports three managed network isolation modes (Disabled, AllowInternetOutbound, AllowOnlyApprovedOutbound) with the managed VNet approach recommended for production. Private endpoints provide inbound connectivity, and outbound rules control egress from compute resources.

### Key DNS Zones

| Service | Private DNS Zone |
|---------|-----------------|
| ML Workspace API | privatelink.api.azureml.ms |
| ML Notebooks | privatelink.notebooks.azure.net |
| Storage Blob | privatelink.blob.core.windows.net |
| Storage File | privatelink.file.core.windows.net |
| Key Vault | privatelink.vaultcore.azure.net |
| Container Registry | privatelink.azurecr.io |
| Application Insights | privatelink.monitor.azure.com |

### Key Service Tags

| Service Tag | Purpose |
|------------|---------|
| AzureMachineLearning | ML workspace management (inbound 44224, outbound 443) |
| BatchNodeManagement | Compute cluster management (inbound 29876-29877) |
| Storage | Access to Azure Storage (outbound 443) |
| AzureActiveDirectory | Authentication (outbound 443) |

For full VNet configuration, private endpoint setup, NSG rules, and outbound rule management, see **[references/networking.md](references/networking.md)**.

---

## 3. COMPUTE

Azure ML offers multiple compute targets: Compute Instances for dev/test, AmlCompute Clusters for scalable training, Serverless Compute for on-demand jobs without cluster management, and Kubernetes Compute for BYO infrastructure scenarios.

### GPU VM SKU Quick Reference

| VM Series | GPU | GPU Memory | Use Case |
|-----------|-----|-----------|----------|
| Standard_NC24ads_A100_v4 | 1x A100 | 80 GB | Training, fine-tuning |
| Standard_ND96amsr_A100_v4 | 8x A100 80GB | 640 GB | Large model training |
| Standard_ND_H100_v5 | 8x H100 | 640 GB | GenAI, LLM training |
| Standard_ND_H200_v5 | 8x H200 | 1120 GB | Latest: 2x perf vs H100 |
| Standard_NCads_H100_v5 | 1x H100 NVL | 94 GB | Inference, fine-tuning |
| Standard_NC4as_T4_v3 | 1x T4 | 16 GB | Budget inference |

For the complete GPU SKU table, compute instance/cluster CLI reference, serverless compute, Kubernetes attach, and debugging commands, see **[references/compute.md](references/compute.md)**.

---

## 4. ENDPOINT DEPLOYMENT

Azure ML supports four endpoint types: Managed Online Endpoints (recommended for real-time inference with blue-green deployments), Batch Endpoints (large-scale scoring on compute clusters), Kubernetes Online Endpoints (BYO AKS/Arc infrastructure), and Serverless Endpoints (pay-per-token Model-as-a-Service).

### Endpoint Types Quick Reference

| Type | Use Case | Auth Modes | Scaling |
|------|----------|------------|---------|
| Managed Online | Real-time inference | key, aml_token | Per-deployment instance count |
| Batch | Large-scale scoring | managed identity | Compute cluster auto-scale |
| Kubernetes Online | BYO infra real-time | key, aml_token | K8s pod scaling |
| Serverless (MaaS) | Pay-per-token LLM | key | Automatic |

For full endpoint creation, deployment, traffic splitting, log retrieval, and batch invocation commands, see **[references/endpoints.md](references/endpoints.md)**.

---

## 5-7. IDENTITIES, ACR, AND STORAGE

Managed identities (system-assigned or user-assigned) control access between workspace, compute, endpoints, and dependent resources. ACR stores Docker images for environments and model serving, requiring Premium SKU for private endpoints and an image-build-compute cluster when behind a VNet. Storage accounts serve as the default datastore for blobs, file shares, job outputs, and MLflow artifacts.

### Identity Types

| Identity Type | Use Case |
|--------------|----------|
| System-Assigned (workspace) | Default workspace operations, auto-lifecycle |
| User-Assigned (workspace) | CMK encryption, cross-resource sharing |
| System-Assigned (compute) | Per-cluster storage/ACR access |
| User-Assigned (compute) | Fine-grained, reusable access control |

### Key RBAC Roles

| Role | Description |
|------|-------------|
| AzureML Data Scientist | Run jobs, manage compute, deploy models |
| AzureML Compute Operator | Create/manage compute resources |
| Azure AI Developer | AI Foundry project development |
| Azure AI Inference Deployment Operator | Deploy models to endpoints |

For full identity configuration, role assignment commands, ACR integration, private ACR setup, datastore registration, and storage account details, see **[references/identities-acr-storage.md](references/identities-acr-storage.md)**.

---

## 8-9. CLI AND POWERSHELL

The `az ml` CLI extension provides comprehensive workspace management through 20+ command groups covering workspaces, compute, jobs, models, endpoints, environments, data, datastores, components, schedules, registries, and connections. The `Az.MachineLearningServices` PowerShell module offers equivalent functionality for Windows-native automation.

### Key az ml Command Groups

| Command Group | Purpose |
|--------------|---------|
| `az ml workspace` | Manage workspaces (create, diagnose, provision-network, outbound-rule) |
| `az ml compute` | Manage compute (create, start, stop, connect-ssh, attach) |
| `az ml job` | Manage jobs (create, stream, cancel, download) |
| `az ml online-endpoint` | Manage online endpoints (create, invoke, get-credentials) |
| `az ml online-deployment` | Manage deployments (create, get-logs, traffic) |
| `az ml batch-endpoint` | Manage batch endpoints (create, invoke, list-jobs) |
| `az ml serverless-endpoint` | Manage serverless endpoints (create, get-credentials) |

For the complete command reference, job management deep-dive, schedule management, and full PowerShell cmdlet reference, see **[references/cli-powershell.md](references/cli-powershell.md)**.

---

## 10. TERRAFORM INTEGRATION

Azure ML workspaces can be fully provisioned with Terraform using the `azurerm` provider. A production setup includes the workspace, VNet/subnets, NSG, storage account, key vault, ACR, Application Insights, private endpoints, DNS zones, compute clusters, and RBAC role assignments.

### Key Terraform Resources

| Resource | Purpose |
|----------|---------|
| `azurerm_machine_learning_workspace` | ML workspace (Default, Hub, Project) |
| `azurerm_machine_learning_compute_cluster` | AmlCompute training clusters |
| `azurerm_machine_learning_compute_instance` | Dev/test compute instances |
| `azurerm_machine_learning_workspace_network_outbound_rule_*` | Managed network outbound rules |

For the full production-ready Terraform configuration (providers, networking, storage, key vault, ACR, workspace, compute, role assignments, and outputs), see **[references/terraform.md](references/terraform.md)**.

---

## 11. TROUBLESHOOTING AND DEBUGGING

Azure ML provides multiple debugging surfaces: real-time job log streaming, deployment container logs (inference-server and storage-initializer), compute instance SSH access for system-level diagnostics, Log Analytics queries for historical analysis, and the `az ml workspace diagnose` command for configuration validation.

### Common Error Categories

| Category | Common Errors |
|----------|--------------|
| Compute | QuotaExceeded, AllocationFailed, disk full, GPU not detected |
| Endpoints | ScoringError, HealthCheckFailure, ImageBuildFailed, 429/503 errors |
| Networking | DNS resolution failure, connection timeout, storage/ACR access denied |
| Jobs | EnvironmentBuildError, OutOfMemoryError, NCCL timeout, blob not found |

For full error reference tables, log locations, Log Analytics queries, endpoint metrics monitoring, workspace diagnostics, and the secure workspace setup checklist, see **[references/troubleshooting.md](references/troubleshooting.md)**.

---

## Additional Resources

Detailed reference files for each topic area:

- **[references/networking.md](references/networking.md)** -- VNet, private endpoints, DNS zones, NSG rules, service tags
- **[references/compute.md](references/compute.md)** -- GPU SKUs, compute instances, clusters, serverless, Kubernetes
- **[references/endpoints.md](references/endpoints.md)** -- Managed online, batch, Kubernetes, and serverless endpoints
- **[references/identities-acr-storage.md](references/identities-acr-storage.md)** -- Managed identities, ACR integration, storage accounts
- **[references/cli-powershell.md](references/cli-powershell.md)** -- Complete az ml CLI and PowerShell command reference
- **[references/terraform.md](references/terraform.md)** -- Full production-ready Terraform configuration
- **[references/troubleshooting.md](references/troubleshooting.md)** -- Log reading, debugging, error tables, setup checklist

### External Documentation

- [Azure ML Documentation](https://learn.microsoft.com/azure/machine-learning/)
- [Azure AI Foundry Documentation](https://learn.microsoft.com/azure/ai-foundry/)
- [az ml CLI Reference](https://learn.microsoft.com/cli/azure/ml)
- [Az.MachineLearningServices PowerShell Module](https://learn.microsoft.com/powershell/module/az.machinelearningservices/)
- [Terraform AzureRM ML Workspace](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/machine_learning_workspace)
- [Secure Azure ML Workspace with VNet](https://learn.microsoft.com/azure/machine-learning/how-to-secure-workspace-vnet)
- [Managed Network Isolation](https://learn.microsoft.com/azure/machine-learning/how-to-managed-network)
- [Troubleshoot Online Endpoints](https://learn.microsoft.com/azure/machine-learning/how-to-troubleshoot-online-endpoints)
- [Azure ML RBAC Roles](https://learn.microsoft.com/azure/machine-learning/how-to-assign-roles)
- [GPU VM Sizes](https://learn.microsoft.com/azure/virtual-machines/sizes/gpu-accelerated/nd-family)
