# Identities, ACR, and Storage Reference

Complete reference for Azure ML managed identities, ACR integration, and storage account configuration.

---

## 5. MANAGED IDENTITIES - COMPLETE REFERENCE

### Identity Types and When to Use Them

| Identity Type | Use Case | Advantages |
|--------------|----------|------------|
| System-Assigned (workspace) | Default workspace operations | Auto-lifecycle, simple setup |
| User-Assigned (workspace) | CMK encryption, cross-resource | Shared across resources, persistent |
| System-Assigned (compute) | Compute accessing storage/ACR | Per-cluster identity |
| User-Assigned (compute) | Fine-grained access control | Reusable across clusters |

### Workspace Identity Configuration

```bash
# Create workspace with system-assigned identity
az ml workspace create \
  --name my-workspace \
  --resource-group ml-rg \
  --location eastus \
  --identity-type SystemAssigned

# Create workspace with user-assigned identity
az identity create \
  --name ml-workspace-identity \
  --resource-group ml-rg

az ml workspace create \
  --name my-workspace \
  --resource-group ml-rg \
  --location eastus \
  --identity-type UserAssigned \
  --user-assigned-identities /subscriptions/<sub>/resourceGroups/ml-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/ml-workspace-identity \
  --primary-user-assigned-identity /subscriptions/<sub>/resourceGroups/ml-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/ml-workspace-identity
```

### Required Role Assignments

**Workspace system-assigned identity (auto-granted for workspaces created after Nov 2024):**
```bash
WS_IDENTITY=$(az ml workspace show -n my-workspace -g ml-rg --query identity.principalId -o tsv)

# Azure AI Administrator on resource group (auto for new workspaces)
az role assignment create \
  --assignee $WS_IDENTITY \
  --role "Azure AI Administrator" \
  --scope /subscriptions/<sub>/resourceGroups/ml-rg

# If using older workspace (pre Nov 2024), Contributor was auto-assigned
# For fine-grained control, assign these individually:

# Storage Blob Data Contributor on storage account
az role assignment create \
  --assignee $WS_IDENTITY \
  --role "Storage Blob Data Contributor" \
  --scope /subscriptions/<sub>/resourceGroups/ml-rg/providers/Microsoft.Storage/storageAccounts/mlstorage

# Storage File Data Privileged Contributor on storage account
az role assignment create \
  --assignee $WS_IDENTITY \
  --role "Storage File Data Privileged Contributor" \
  --scope /subscriptions/<sub>/resourceGroups/ml-rg/providers/Microsoft.Storage/storageAccounts/mlstorage

# Key Vault Administrator on key vault
az role assignment create \
  --assignee $WS_IDENTITY \
  --role "Key Vault Administrator" \
  --scope /subscriptions/<sub>/resourceGroups/ml-rg/providers/Microsoft.KeyVault/vaults/mlkeyvault

# AcrPush on container registry (for building/pushing environment images)
az role assignment create \
  --assignee $WS_IDENTITY \
  --role "AcrPush" \
  --scope /subscriptions/<sub>/resourceGroups/ml-rg/providers/Microsoft.ContainerRegistry/registries/mlacr

# Contributor on Application Insights
az role assignment create \
  --assignee $WS_IDENTITY \
  --role "Contributor" \
  --scope /subscriptions/<sub>/resourceGroups/ml-rg/providers/Microsoft.Insights/components/mlinsights
```

**Compute cluster/instance identity for data access:**
```bash
COMPUTE_IDENTITY=$(az ml compute show -n gpu-cluster -g ml-rg -w my-workspace --query identity.principalId -o tsv)

# Storage Blob Data Reader (minimum for reading training data)
az role assignment create \
  --assignee $COMPUTE_IDENTITY \
  --role "Storage Blob Data Reader" \
  --scope /subscriptions/<sub>/resourceGroups/ml-rg/providers/Microsoft.Storage/storageAccounts/mlstorage

# Storage Blob Data Contributor (if compute needs write access)
az role assignment create \
  --assignee $COMPUTE_IDENTITY \
  --role "Storage Blob Data Contributor" \
  --scope /subscriptions/<sub>/resourceGroups/ml-rg/providers/Microsoft.Storage/storageAccounts/mlstorage

# AcrPull (for pulling Docker images from workspace ACR)
az role assignment create \
  --assignee $COMPUTE_IDENTITY \
  --role "AcrPull" \
  --scope /subscriptions/<sub>/resourceGroups/ml-rg/providers/Microsoft.ContainerRegistry/registries/mlacr
```

**Managed online endpoint identity for deployment:**
```bash
ENDPOINT_IDENTITY=$(az ml online-endpoint show -n my-endpoint -g ml-rg -w my-workspace --query identity.principalId -o tsv)

# AcrPull on ACR (to pull model serving images)
az role assignment create \
  --assignee $ENDPOINT_IDENTITY \
  --role "AcrPull" \
  --scope /subscriptions/<sub>/resourceGroups/ml-rg/providers/Microsoft.ContainerRegistry/registries/mlacr

# Storage Blob Data Reader (to access model artifacts)
az role assignment create \
  --assignee $ENDPOINT_IDENTITY \
  --role "Storage Blob Data Reader" \
  --scope /subscriptions/<sub>/resourceGroups/ml-rg/providers/Microsoft.Storage/storageAccounts/mlstorage

# AzureML Workspace Connection Secrets Reader (to access workspace connections/secrets)
az role assignment create \
  --assignee $ENDPOINT_IDENTITY \
  --role "Azure Machine Learning Workspace Connection Secrets Reader" \
  --scope /subscriptions/<sub>/resourceGroups/ml-rg/providers/Microsoft.MachineLearningServices/workspaces/my-workspace
```

### User RBAC Roles for Azure ML

| Role | Description | Scope |
|------|-------------|-------|
| AzureML Data Scientist | Run jobs, manage compute, deploy models | Workspace |
| AzureML Compute Operator | Create/manage compute resources | Workspace |
| Reader | View workspace resources (read-only) | Workspace/RG |
| Contributor | Full access except role assignments | Workspace/RG |
| Owner | Full access including role assignments | Workspace/RG |
| Azure AI Developer | AI Foundry project development | Project |
| Azure AI Inference Deployment Operator | Deploy models to endpoints | Workspace |

---

## 6. ACR INTEGRATION - COMPLETE REFERENCE

### How Azure ML Uses ACR

Azure ML uses ACR to store Docker images for:
- Custom environments (Docker + conda builds)
- Model serving containers
- Training job containers
- Pipeline step containers

The workspace creates or associates an ACR. Environment builds push images there.

```bash
# Check workspace ACR
az ml workspace show \
  --name my-workspace \
  --resource-group ml-rg \
  --query "container_registry" -o tsv

# Create environment (triggers image build to ACR)
az ml environment create \
  --file environment.yml \
  --resource-group ml-rg \
  --workspace-name my-workspace

# List environments
az ml environment list \
  --resource-group ml-rg \
  --workspace-name my-workspace \
  --output table

# Show environment details (includes Docker image URI in ACR)
az ml environment show \
  --name my-env \
  --version 1 \
  --resource-group ml-rg \
  --workspace-name my-workspace
```

### Image Build Compute (Required for Private ACR)

When ACR is behind a VNet, Azure ML cannot build images directly. You must configure a compute cluster for image builds.

```bash
# Set image build compute
az ml workspace update \
  --name my-workspace \
  --resource-group ml-rg \
  --image-build-compute cpu-build-cluster

# The cpu-build-cluster must:
# 1. Be in the same workspace
# 2. Be a CPU cluster (GPU not needed for Docker builds)
# 3. Have network access to ACR
# 4. Have AcrPull + AcrPush roles on the workspace ACR
```

### Using a Private External ACR

```bash
# Create user-assigned identity for ACR access
az identity create \
  --name acr-pull-identity \
  --resource-group ml-rg

ACR_IDENTITY_ID=$(az identity show -n acr-pull-identity -g ml-rg --query id -o tsv)
ACR_IDENTITY_PRINCIPAL=$(az identity show -n acr-pull-identity -g ml-rg --query principalId -o tsv)

# Grant AcrPull on the external private ACR
az role assignment create \
  --assignee $ACR_IDENTITY_PRINCIPAL \
  --role AcrPull \
  --scope /subscriptions/<sub>/resourceGroups/acr-rg/providers/Microsoft.ContainerRegistry/registries/externalacr

# Grant workspace identity Managed Identity Operator on the pull identity
WS_IDENTITY=$(az ml workspace show -n my-workspace -g ml-rg --query identity.principalId -o tsv)
az role assignment create \
  --assignee $WS_IDENTITY \
  --role "Managed Identity Operator" \
  --scope $ACR_IDENTITY_ID

# Use external ACR image in environment
cat <<EOF > env-external-acr.yml
\$schema: https://azuremlschemas.azureedge.net/latest/environment.schema.json
name: external-acr-env
version: 1
image: externalacr.azurecr.io/my-base-image:latest
inference_config:
  liveness_route:
    path: /health
    port: 8080
  readiness_route:
    path: /ready
    port: 8080
  scoring_route:
    path: /score
    port: 8080
EOF

az ml environment create --file env-external-acr.yml \
  --resource-group ml-rg --workspace-name my-workspace
```

### Troubleshooting ACR/Environment Build Issues

```bash
# Check environment build status
az ml environment show \
  --name my-env --version 1 \
  --resource-group ml-rg --workspace-name my-workspace \
  --query "build_context"

# View ACR build logs
az acr task logs \
  --registry mlacr \
  --resource-group ml-rg

# List images in workspace ACR
az acr repository list \
  --name mlacr \
  --output table

# Show image tags
az acr repository show-tags \
  --name mlacr \
  --repository azureml/azureml_<env-hash> \
  --output table

# Check ACR access from compute
# SSH into compute instance, then:
# az acr login --name mlacr
# docker pull mlacr.azurecr.io/azureml/azureml_<hash>:latest
```

---

## 7. STORAGE ACCOUNTS - COMPLETE REFERENCE

### Default Workspace Storage

Azure ML uses the workspace storage account for:
- Default datastore (blob container `azureml-blobstore-<guid>`)
- File share for notebooks (`code-<guid>`)
- MLflow tracking artifacts
- Job outputs and logs
- Pipeline intermediate data
- Model artifacts before registration

```bash
# Check workspace default storage
az ml workspace show \
  --name my-workspace \
  --resource-group ml-rg \
  --query "storage_account" -o tsv

# List datastores (shows connection to storage)
az ml datastore list \
  --resource-group ml-rg \
  --workspace-name my-workspace \
  --output table

# Show default datastore
az ml datastore show \
  --name workspaceblobstore \
  --resource-group ml-rg \
  --workspace-name my-workspace
```

### Register Additional Datastores

```bash
# Register Azure Blob datastore (identity-based access - recommended)
az ml datastore create \
  --file blob-datastore.yml \
  --resource-group ml-rg \
  --workspace-name my-workspace
```

**blob-datastore.yml:**
```yaml
$schema: https://azuremlschemas.azureedge.net/latest/azureBlob.schema.json
name: training-data-store
type: azure_blob
account_name: trainingdatastorage
container_name: ml-datasets
credentials:
  # Option 1: Identity-based (recommended - no keys stored)
  # Leave credentials empty, configure RBAC instead
  # Option 2: Account key
  # account_key: "<key>"
  # Option 3: SAS token
  # sas_token: "<sas>"
```

```bash
# Register ADLS Gen2 datastore
az ml datastore create \
  --name adls-datastore \
  --type azure_data_lake_gen2 \
  --resource-group ml-rg \
  --workspace-name my-workspace \
  --account-name mydatalakeaccount \
  --filesystem ml-filesystem

# Register Azure File share datastore
az ml datastore create \
  --name fileshare-datastore \
  --type azure_file \
  --resource-group ml-rg \
  --workspace-name my-workspace \
  --account-name mystorage \
  --file-share-name ml-files \
  --account-key "<key>"

# Test datastore connectivity
az ml datastore show \
  --name training-data-store \
  --resource-group ml-rg \
  --workspace-name my-workspace \
  --query "credentials"
```
