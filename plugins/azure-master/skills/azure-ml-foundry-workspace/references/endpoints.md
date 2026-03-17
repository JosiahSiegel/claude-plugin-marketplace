# Endpoints Reference

Complete reference for Azure ML endpoint deployment including managed online endpoints, batch endpoints, Kubernetes endpoints, serverless endpoints, and deployment logs.

---

## Managed Online Endpoints (Recommended for Real-Time Inference)

```bash
# Create endpoint
az ml online-endpoint create \
  --name my-endpoint \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace \
  --auth-mode key

# Create endpoint with managed identity auth
az ml online-endpoint create \
  --name secure-endpoint \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace \
  --auth-mode aml_token

# Create deployment (blue)
az ml online-deployment create \
  --name blue \
  --endpoint-name my-endpoint \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace \
  --model azureml:my-model@latest \
  --code-configuration code=./scoring scoring_script=score.py \
  --environment azureml:my-env@latest \
  --instance-type Standard_DS3_v2 \
  --instance-count 2 \
  --all-traffic

# Create deployment (green) for blue-green
az ml online-deployment create \
  --name green \
  --endpoint-name my-endpoint \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace \
  --model azureml:my-model@2 \
  --code-configuration code=./scoring scoring_script=score.py \
  --environment azureml:my-env@latest \
  --instance-type Standard_DS3_v2 \
  --instance-count 2

# Split traffic between deployments
az ml online-endpoint update \
  --name my-endpoint \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace \
  --traffic "blue=90 green=10"

# Shift all traffic to green
az ml online-endpoint update \
  --name my-endpoint \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace \
  --traffic "blue=0 green=100"

# Test endpoint
az ml online-endpoint invoke \
  --name my-endpoint \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace \
  --request-file sample-request.json

# Test specific deployment (mirror traffic)
az ml online-endpoint invoke \
  --name my-endpoint \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace \
  --deployment-name green \
  --request-file sample-request.json

# Get endpoint scoring URI and keys
az ml online-endpoint show \
  --name my-endpoint \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace \
  --query "scoring_uri" -o tsv

az ml online-endpoint get-credentials \
  --name my-endpoint \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace

# List endpoints
az ml online-endpoint list \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace \
  --output table

# Delete deployment then endpoint
az ml online-deployment delete \
  --name blue \
  --endpoint-name my-endpoint \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace \
  --yes

az ml online-endpoint delete \
  --name my-endpoint \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace \
  --yes
```

## Endpoint Deployment Logs - All Container Types

```bash
# Get inference server logs (default)
az ml online-deployment get-logs \
  --name blue \
  --endpoint-name my-endpoint \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace \
  --lines 500

# Get storage initializer logs (model download phase)
az ml online-deployment get-logs \
  --name blue \
  --endpoint-name my-endpoint \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace \
  --container storage-initializer \
  --lines 200

# Get inference server container logs specifically
az ml online-deployment get-logs \
  --name blue \
  --endpoint-name my-endpoint \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace \
  --container inference-server \
  --lines 200

# Check endpoint provisioning state
az ml online-endpoint show \
  --name my-endpoint \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace \
  --query "{state:provisioning_state, traffic:traffic}" -o json

# Check deployment provisioning state
az ml online-deployment show \
  --name blue \
  --endpoint-name my-endpoint \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace \
  --query "{state:provisioning_state, instanceType:instance_type, instanceCount:instance_count}" -o json

# Use Log Analytics for comprehensive endpoint logs
az monitor log-analytics query \
  --workspace <log-analytics-workspace-id> \
  --analytics-query "
    AmlOnlineEndpointConsoleLog
    | where TimeGenerated > ago(1h)
    | where EndpointName == 'my-endpoint'
    | where DeploymentName == 'blue'
    | project TimeGenerated, Message, ContainerName
    | order by TimeGenerated desc
    | take 100
  " \
  --output table

# Query endpoint traffic metrics
az monitor log-analytics query \
  --workspace <log-analytics-workspace-id> \
  --analytics-query "
    AmlOnlineEndpointTrafficLog
    | where TimeGenerated > ago(24h)
    | where EndpointName == 'my-endpoint'
    | summarize RequestCount=count(), AvgLatencyMs=avg(RequestDuration) by bin(TimeGenerated, 1h), DeploymentName
    | order by TimeGenerated desc
  " \
  --output table
```

## Batch Endpoints

```bash
# Create batch endpoint
az ml batch-endpoint create \
  --name my-batch-endpoint \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace

# Create batch deployment
az ml batch-deployment create \
  --name batch-v1 \
  --endpoint-name my-batch-endpoint \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace \
  --model azureml:my-model@latest \
  --compute azureml:cpu-cluster \
  --instance-count 4 \
  --mini-batch-size 100 \
  --max-concurrency-per-instance 2 \
  --output-action append_row \
  --output-file-name predictions.csv \
  --set-default

# Invoke batch scoring
az ml batch-endpoint invoke \
  --name my-batch-endpoint \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace \
  --input azureml:my-scoring-data@latest

# Invoke with inline data
az ml batch-endpoint invoke \
  --name my-batch-endpoint \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace \
  --input-type uri_folder \
  --input "https://mystorage.blob.core.windows.net/data/scoring/"

# Check batch job status
az ml batch-endpoint list-jobs \
  --name my-batch-endpoint \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace \
  --output table
```

## Kubernetes Online Endpoints

```bash
# Create Kubernetes online endpoint
az ml online-endpoint create \
  --name k8s-endpoint \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace \
  --auth-mode key

# Create Kubernetes deployment
az ml online-deployment create \
  --name k8s-deploy \
  --endpoint-name k8s-endpoint \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace \
  --model azureml:my-model@latest \
  --code-configuration code=./scoring scoring_script=score.py \
  --environment azureml:my-env@latest \
  --compute azureml:aks-compute \
  --instance-type "defaultInstanceType" \
  --instance-count 2 \
  --all-traffic
```

## Serverless Endpoints (Model as a Service)

```bash
# Deploy model from catalog as serverless
az ml serverless-endpoint create \
  --name phi3-serverless \
  --model-id azureml://registries/azureml/models/Phi-3-medium-128k-instruct \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace

# Get credentials
az ml serverless-endpoint get-credentials \
  --name phi3-serverless \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace

# List serverless endpoints
az ml serverless-endpoint list \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace \
  --output table

# Delete serverless endpoint
az ml serverless-endpoint delete \
  --name phi3-serverless \
  --resource-group ml-rg \
  --workspace-name my-ml-workspace
```
