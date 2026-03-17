# CLI and PowerShell Reference

Complete reference for all `az ml` CLI commands and `Az.MachineLearningServices` PowerShell commands.

---

## 8. COMPLETE az ml CLI COMMAND REFERENCE

### All az ml Subcommands

| Command Group | Purpose | Key Subcommands |
|--------------|---------|-----------------|
| `az ml workspace` | Manage workspaces | create, show, list, update, delete, diagnose, provision-network, outbound-rule |
| `az ml compute` | Manage compute targets | create, show, list, update, delete, start, stop, restart, connect-ssh, attach, detach |
| `az ml job` | Manage training jobs | create, show, list, stream, cancel, download, archive, restore, update |
| `az ml model` | Manage registered models | create, show, list, archive, restore, download, package |
| `az ml online-endpoint` | Manage online endpoints | create, show, list, update, delete, invoke, get-credentials, regenerate-keys |
| `az ml online-deployment` | Manage online deployments | create, show, list, update, delete, get-logs |
| `az ml batch-endpoint` | Manage batch endpoints | create, show, list, update, delete, invoke, list-jobs |
| `az ml batch-deployment` | Manage batch deployments | create, show, list, update, delete |
| `az ml serverless-endpoint` | Manage serverless endpoints | create, show, list, delete, get-credentials, regenerate-keys |
| `az ml environment` | Manage environments | create, show, list, archive, restore |
| `az ml data` | Manage data assets | create, show, list, archive, restore |
| `az ml datastore` | Manage datastores | create, show, list, delete |
| `az ml component` | Manage pipeline components | create, show, list, archive, restore |
| `az ml schedule` | Manage recurring schedules | create, show, list, update, delete, enable, disable |
| `az ml registry` | Manage ML registries | create, show, list, update, delete |
| `az ml connection` | Manage workspace connections | create, show, list, update, delete |
| `az ml feature-store` | Manage feature stores | create, show, list |
| `az ml feature-store-entity` | Manage feature store entities | create, show, list |
| `az ml feature-set` | Manage feature sets | create, show, list |
| `az ml marketplace-subscription` | Manage marketplace subscriptions | create, show, list, delete |

### Job Management - Deep Dive

```bash
# Create and submit a job
az ml job create --file job.yml \
  --resource-group ml-rg --workspace-name my-workspace

# Stream job logs in real-time
az ml job stream --name <job-name> \
  --resource-group ml-rg --workspace-name my-workspace

# Show job details
az ml job show --name <job-name> \
  --resource-group ml-rg --workspace-name my-workspace \
  --query "{status:status, duration:properties.duration, compute:compute}" -o json

# List jobs
az ml job list \
  --resource-group ml-rg --workspace-name my-workspace \
  --output table \
  --max-results 20

# List jobs by experiment
az ml job list \
  --resource-group ml-rg --workspace-name my-workspace \
  --query "[?experiment_name=='my-experiment']" \
  --output table

# Cancel a running job
az ml job cancel --name <job-name> \
  --resource-group ml-rg --workspace-name my-workspace

# Download job outputs
az ml job download --name <job-name> \
  --resource-group ml-rg --workspace-name my-workspace \
  --output-name model \
  --download-path ./downloaded-outputs

# Download all outputs
az ml job download --name <job-name> \
  --resource-group ml-rg --workspace-name my-workspace \
  --all

# Archive/restore jobs
az ml job archive --name <job-name> \
  --resource-group ml-rg --workspace-name my-workspace
az ml job restore --name <job-name> \
  --resource-group ml-rg --workspace-name my-workspace

# Run job locally for debugging
az ml job create --file job.yml \
  --set compute=local \
  --resource-group ml-rg --workspace-name my-workspace

# Create and test local endpoint deployment
az ml online-deployment create --local \
  --file deployment.yml \
  --resource-group ml-rg --workspace-name my-workspace
```

### Schedule Management

```bash
# Create a schedule
az ml schedule create --file schedule.yml \
  --resource-group ml-rg --workspace-name my-workspace

# List schedules
az ml schedule list \
  --resource-group ml-rg --workspace-name my-workspace \
  --output table

# Enable/disable schedule
az ml schedule enable --name my-schedule \
  --resource-group ml-rg --workspace-name my-workspace
az ml schedule disable --name my-schedule \
  --resource-group ml-rg --workspace-name my-workspace

# Delete schedule
az ml schedule delete --name my-schedule \
  --resource-group ml-rg --workspace-name my-workspace --yes
```

**schedule.yml:**
```yaml
$schema: https://azuremlschemas.azureedge.net/latest/schedule.schema.json
name: daily-retrain
display_name: Daily Retraining
trigger:
  type: recurrence
  frequency: day
  interval: 1
  schedule:
    hours: [2]
    minutes: [0]
  time_zone: "Eastern Standard Time"
create_job: ./pipeline.yml
```

---

## 9. POWERSHELL Az.MachineLearningServices - COMPLETE REFERENCE

```powershell
# ===================== WORKSPACE COMMANDS =====================
# Create workspace
New-AzMLWorkspace -Name "ws" -ResourceGroupName "rg" -Location "eastus" `
  -IdentityType "SystemAssigned"

# Get workspace
Get-AzMLWorkspace -Name "ws" -ResourceGroupName "rg"

# List workspaces
Get-AzMLWorkspace -ResourceGroupName "rg"

# Update workspace
Update-AzMLWorkspace -Name "ws" -ResourceGroupName "rg" `
  -Description "Updated" -Tag @{env="prod"}

# Diagnose workspace
Invoke-AzMLWorkspaceDiagnose -Name "ws" -ResourceGroupName "rg"

# Remove workspace
Remove-AzMLWorkspace -Name "ws" -ResourceGroupName "rg"

# ===================== COMPUTE COMMANDS =====================
# Create compute
New-AzMLWorkspaceCompute -Name "cluster" -ResourceGroupName "rg" `
  -WorkspaceName "ws" -Location "eastus" -ComputeType "AmlCompute" `
  -Property @{vmSize="Standard_DS3_v2"; scaleSettings=@{minNodeCount=0;maxNodeCount=4}}

# Get compute
Get-AzMLWorkspaceCompute -Name "cluster" -ResourceGroupName "rg" -WorkspaceName "ws"

# List compute
Get-AzMLWorkspaceCompute -ResourceGroupName "rg" -WorkspaceName "ws"

# Start/stop compute
Start-AzMLWorkspaceCompute -Name "instance" -ResourceGroupName "rg" -WorkspaceName "ws"
Stop-AzMLWorkspaceCompute -Name "instance" -ResourceGroupName "rg" -WorkspaceName "ws"

# Remove compute
Remove-AzMLWorkspaceCompute -Name "cluster" -ResourceGroupName "rg" -WorkspaceName "ws"

# ===================== ONLINE ENDPOINT COMMANDS =====================
# Create online endpoint
New-AzMLWorkspaceOnlineEndpoint -Name "ep" -ResourceGroupName "rg" `
  -WorkspaceName "ws" -Location "eastus" `
  -AuthMode "Key" -IdentityType "SystemAssigned"

# Get online endpoint
Get-AzMLWorkspaceOnlineEndpoint -Name "ep" -ResourceGroupName "rg" -WorkspaceName "ws"

# List online endpoints
Get-AzMLWorkspaceOnlineEndpoint -ResourceGroupName "rg" -WorkspaceName "ws"

# Get endpoint keys
Get-AzMLWorkspaceOnlineEndpointKey -Name "ep" -ResourceGroupName "rg" -WorkspaceName "ws"

# Regenerate keys
New-AzMLWorkspaceOnlineEndpointKey -Name "ep" -ResourceGroupName "rg" `
  -WorkspaceName "ws" -KeyType "Primary"

# Remove endpoint
Remove-AzMLWorkspaceOnlineEndpoint -Name "ep" -ResourceGroupName "rg" -WorkspaceName "ws"

# ===================== ONLINE DEPLOYMENT COMMANDS =====================
# Create deployment
New-AzMLWorkspaceOnlineDeployment -Name "blue" -ResourceGroupName "rg" `
  -WorkspaceName "ws" -EndpointName "ep" -Location "eastus" `
  -SkuName "Default" -SkuCapacity 1

# Get deployment
Get-AzMLWorkspaceOnlineDeployment -Name "blue" -ResourceGroupName "rg" `
  -WorkspaceName "ws" -EndpointName "ep"

# Get deployment logs
Get-AzMLWorkspaceOnlineDeploymentLog -Name "blue" -ResourceGroupName "rg" `
  -WorkspaceName "ws" -EndpointName "ep" -Tail 200

# Remove deployment
Remove-AzMLWorkspaceOnlineDeployment -Name "blue" -ResourceGroupName "rg" `
  -WorkspaceName "ws" -EndpointName "ep"

# ===================== BATCH ENDPOINT COMMANDS =====================
New-AzMLWorkspaceBatchEndpoint -Name "batch" -ResourceGroupName "rg" `
  -WorkspaceName "ws" -Location "eastus"
Get-AzMLWorkspaceBatchEndpoint -Name "batch" -ResourceGroupName "rg" -WorkspaceName "ws"
Remove-AzMLWorkspaceBatchEndpoint -Name "batch" -ResourceGroupName "rg" -WorkspaceName "ws"

# ===================== JOB COMMANDS =====================
# Get job
Get-AzMLWorkspaceJob -Name "job-id" -ResourceGroupName "rg" -WorkspaceName "ws"

# List jobs
Get-AzMLWorkspaceJob -ResourceGroupName "rg" -WorkspaceName "ws"

# Cancel job
Stop-AzMLWorkspaceJob -Name "job-id" -ResourceGroupName "rg" -WorkspaceName "ws"

# ===================== DATA AND DATASTORE COMMANDS =====================
Get-AzMLWorkspaceDatastore -Name "store" -ResourceGroupName "rg" -WorkspaceName "ws"
Get-AzMLWorkspaceDatastore -ResourceGroupName "rg" -WorkspaceName "ws"

# ===================== ENVIRONMENT COMMANDS =====================
Get-AzMLWorkspaceEnvironmentContainer -Name "env" -ResourceGroupName "rg" -WorkspaceName "ws"
Get-AzMLWorkspaceEnvironmentVersion -Name "env" -ResourceGroupName "rg" -WorkspaceName "ws" -Version 1

# ===================== MODEL COMMANDS =====================
Get-AzMLWorkspaceModelContainer -Name "model" -ResourceGroupName "rg" -WorkspaceName "ws"
Get-AzMLWorkspaceModelVersion -Name "model" -ResourceGroupName "rg" -WorkspaceName "ws" -Version 1

# ===================== CONNECTION COMMANDS =====================
Get-AzMLWorkspaceConnection -Name "conn" -ResourceGroupName "rg" -WorkspaceName "ws"
New-AzMLWorkspaceConnection -Name "conn" -ResourceGroupName "rg" -WorkspaceName "ws" `
  -AuthType "ApiKey" -Category "AzureOpenAI" -Target "https://myopenai.openai.azure.com"
```
