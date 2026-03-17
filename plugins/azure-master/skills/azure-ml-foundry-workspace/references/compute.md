# Compute Reference

Complete reference for Azure ML compute targets including GPU SKUs, compute instances, compute clusters, serverless compute, Kubernetes compute, and debugging.

---

## GPU VM SKU Reference for Azure ML

| VM Series | GPU | GPU Memory | vCPUs | RAM | Use Case |
|-----------|-----|-----------|-------|-----|----------|
| Standard_NC6s_v3 | 1x V100 | 16 GB | 6 | 112 GB | Small-scale training (RETIRING Sep 2025) |
| Standard_NC12s_v3 | 2x V100 | 32 GB | 12 | 224 GB | Medium training (RETIRING Sep 2025) |
| Standard_NC24s_v3 | 4x V100 | 64 GB | 24 | 448 GB | Large training (RETIRING Sep 2025) |
| Standard_NC24ads_A100_v4 | 1x A100 | 80 GB | 24 | 220 GB | Training, fine-tuning |
| Standard_NC48ads_A100_v4 | 2x A100 | 160 GB | 48 | 440 GB | Distributed training |
| Standard_NC96ads_A100_v4 | 4x A100 | 320 GB | 96 | 880 GB | Large-scale training |
| Standard_ND96asr_v4 | 8x A100 40GB | 320 GB | 96 | 900 GB | HPC, distributed training |
| Standard_ND96amsr_A100_v4 | 8x A100 80GB | 640 GB | 96 | 1900 GB | Large model training |
| Standard_ND_H100_v5 | 8x H100 | 640 GB | 96 | 1900 GB | GenAI, LLM training |
| Standard_ND_H200_v5 | 8x H200 | 1120 GB | 96 | 1900 GB | Latest: 2x perf vs H100 |
| Standard_NCads_H100_v5 | 1x H100 NVL | 94 GB | 12-48 | 110-440 GB | Inference, fine-tuning |
| Standard_NC4as_T4_v3 | 1x T4 | 16 GB | 4 | 28 GB | Budget inference |
| Standard_NC8as_T4_v3 | 1x T4 | 16 GB | 8 | 56 GB | Budget inference |
| Standard_NC16as_T4_v3 | 1x T4 | 16 GB | 16 | 110 GB | Budget inference |
| Standard_NC64as_T4_v3 | 4x T4 | 64 GB | 64 | 440 GB | Multi-GPU inference |
| Standard_NV36ads_A10_v5 | 1x A10 | 24 GB | 36 | 440 GB | Visualization, inference |

## Compute Instance - Complete CLI Reference

```bash
# Create compute instance - standard
az ml compute create \
  --name dev-instance \
  --type ComputeInstance \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace \
  --size Standard_DS3_v2 \
  --enable-node-public-ip false \
  --idle-time-before-shutdown-minutes 30 \
  --ssh-public-access disabled

# Create GPU compute instance
az ml compute create \
  --name gpu-dev \
  --type ComputeInstance \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace \
  --size Standard_NC24ads_A100_v4 \
  --idle-time-before-shutdown-minutes 60 \
  --enable-node-public-ip false

# Create compute instance with setup script
az ml compute create \
  --name dev-custom \
  --type ComputeInstance \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace \
  --size Standard_DS3_v2 \
  --setup-scripts-creation-script "https://raw.githubusercontent.com/myorg/scripts/setup.sh"

# Start compute instance
az ml compute start \
  --name dev-instance \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace

# Stop compute instance
az ml compute stop \
  --name dev-instance \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace

# Restart compute instance
az ml compute restart \
  --name dev-instance \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace

# Show compute details
az ml compute show \
  --name dev-instance \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace

# List all compute
az ml compute list \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace \
  --output table

# List compute by type
az ml compute list \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace \
  --type ComputeInstance \
  --output table

# Connect via SSH (managed VNet with no public IP)
az ml compute connect-ssh \
  --name dev-instance \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace

# Delete compute instance
az ml compute delete \
  --name dev-instance \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace \
  --yes

# Update compute instance (e.g., idle shutdown)
az ml compute update \
  --name dev-instance \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace \
  --idle-time-before-shutdown-minutes 120
```

**PowerShell equivalents:**
```powershell
# Create compute instance
New-AzMLWorkspaceCompute `
  -Name "dev-instance" `
  -ResourceGroupName "ml-rg" `
  -WorkspaceName "my-ml-workspace" `
  -Location "eastus" `
  -ComputeType "ComputeInstance" `
  -Property @{
    vmSize = "Standard_DS3_v2"
    sshSettings = @{sshPublicAccess = "Disabled"}
    idleTimeBeforeShutdown = "PT30M"
  }

# Get compute
Get-AzMLWorkspaceCompute -Name "dev-instance" -ResourceGroupName "ml-rg" -WorkspaceName "my-ml-workspace"

# Start compute
Start-AzMLWorkspaceCompute -Name "dev-instance" -ResourceGroupName "ml-rg" -WorkspaceName "my-ml-workspace"

# Stop compute
Stop-AzMLWorkspaceCompute -Name "dev-instance" -ResourceGroupName "ml-rg" -WorkspaceName "my-ml-workspace"

# Remove compute
Remove-AzMLWorkspaceCompute -Name "dev-instance" -ResourceGroupName "ml-rg" -WorkspaceName "my-ml-workspace"
```

## Compute Cluster - Complete CLI Reference

```bash
# Create CPU cluster
az ml compute create \
  --name cpu-cluster \
  --type AmlCompute \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace \
  --size Standard_DS3_v2 \
  --min-instances 0 \
  --max-instances 10 \
  --idle-time-before-scale-down 120 \
  --tier Dedicated \
  --enable-node-public-ip false \
  --identity-type SystemAssigned

# Create GPU cluster for training
az ml compute create \
  --name gpu-cluster \
  --type AmlCompute \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace \
  --size Standard_NC24ads_A100_v4 \
  --min-instances 0 \
  --max-instances 4 \
  --idle-time-before-scale-down 300 \
  --tier Dedicated \
  --enable-node-public-ip false

# Create low-priority (spot) cluster for cost savings
az ml compute create \
  --name spot-gpu-cluster \
  --type AmlCompute \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace \
  --size Standard_NC24ads_A100_v4 \
  --min-instances 0 \
  --max-instances 8 \
  --tier LowPriority

# Create cluster with user-assigned identity
az ml compute create \
  --name identity-cluster \
  --type AmlCompute \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace \
  --size Standard_DS3_v2 \
  --min-instances 0 \
  --max-instances 4 \
  --identity-type UserAssigned \
  --user-assigned-identities /subscriptions/<sub>/resourceGroups/ml-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/ml-identity

# Create cluster in specific subnet (BYO VNet)
az ml compute create \
  --name subnet-cluster \
  --type AmlCompute \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace \
  --size Standard_DS3_v2 \
  --min-instances 0 \
  --max-instances 10 \
  --vnet-name ml-vnet \
  --subnet compute-subnet \
  --vnet-resource-group network-rg

# Update cluster (scale limits)
az ml compute update \
  --name gpu-cluster \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace \
  --min-instances 1 \
  --max-instances 8 \
  --idle-time-before-scale-down 600
```

**YAML definition (compute-cluster.yml):**
```yaml
$schema: https://azuremlschemas.azureedge.net/latest/amlCompute.schema.json
name: gpu-cluster
type: amlcompute
size: Standard_NC24ads_A100_v4
min_instances: 0
max_instances: 4
idle_time_before_scale_down: 300
tier: dedicated
enable_node_public_ip: false
identity:
  type: system_assigned
tags:
  purpose: training
  team: data-science
```

```bash
# Create from YAML
az ml compute create --file compute-cluster.yml \
  --resource-group ml-rg --workspace-name my-ml-workspace
```

## Serverless Compute

On-demand compute without cluster management. Azure provisions and deprovisions automatically.

```yaml
# job.yml with serverless compute
$schema: https://azuremlschemas.azureedge.net/latest/commandJob.schema.json
command: python train.py --epochs 50 --lr 0.001
environment: azureml:AzureML-sklearn-1.5-ubuntu22.04-py311-cpu:1
resources:
  instance_type: Standard_NC24ads_A100_v4
  instance_count: 1
queue_settings:
  job_tier: Standard
```

## Kubernetes Compute (AKS / Arc-enabled)

```bash
# Attach existing AKS cluster
az ml compute attach \
  --name aks-compute \
  --type Kubernetes \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace \
  --resource-id /subscriptions/<sub>/resourceGroups/aks-rg/providers/Microsoft.ContainerService/managedClusters/my-aks \
  --namespace azureml

# Install Azure ML extension on AKS
az k8s-extension create \
  --name azureml \
  --extension-type Microsoft.AzureML.Kubernetes \
  --scope cluster \
  --cluster-name my-aks \
  --resource-group aks-rg \
  --cluster-type managedClusters \
  --configuration-settings \
    enableTraining=True \
    enableInference=True \
    inferenceRouterServiceType=LoadBalancer \
    allowInsecureConnections=False \
    InferenceRouterHA=True

# Verify extension
az k8s-extension show \
  --name azureml \
  --cluster-name my-aks \
  --resource-group aks-rg \
  --cluster-type managedClusters

# Detach compute
az ml compute detach \
  --name aks-compute \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace
```

## Compute Instance Logs and Debugging

```bash
# Get compute instance details (includes state, errors)
az ml compute show \
  --name dev-instance \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace \
  --query "{state:properties.state, errors:properties.errors, applications:properties.applications}" \
  --output json

# Check compute instance provisioning state
az ml compute show \
  --name dev-instance \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace \
  --query "properties.provisioningState" -o tsv

# SSH into compute instance for direct log access
az ml compute connect-ssh \
  --name dev-instance \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace

# Once SSHed in, check system logs:
# journalctl -u azureml -n 100
# cat /var/log/azureml/*.log
# cat /mnt/batch/tasks/startup/stdout.txt
# cat /mnt/batch/tasks/startup/stderr.txt
# df -h   (check disk space)
# nvidia-smi  (GPU status)
# top / htop  (process status)

# Check compute cluster node status
az ml compute show \
  --name gpu-cluster \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace \
  --query "{currentNodeCount:properties.currentNodeCount, targetNodeCount:properties.targetNodeCount, allocationState:properties.allocationState, errors:properties.errors}" \
  --output json

# Use Activity Log for compute events
az monitor activity-log list \
  --resource-group ml-rg \
  --resource-type Microsoft.MachineLearningServices/workspaces/computes \
  --start-time $(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%SZ) \
  --output table
```
