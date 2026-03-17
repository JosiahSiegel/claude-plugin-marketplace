# Troubleshooting Reference

Complete reference for Azure ML log reading, debugging, error resolution, and workspace setup checklist.

---

## 10. LOG READING AND DEBUGGING - COMPLETE REFERENCE

### Job Logs

```bash
# Stream logs in real-time during execution
az ml job stream --name <job-name> \
  --resource-group ml-rg --workspace-name my-workspace

# View job status and details
az ml job show --name <job-name> \
  --resource-group ml-rg --workspace-name my-workspace \
  --query "{status:status, error:error, startTime:properties.startTime, endTime:properties.endTime}" -o json

# Download job logs
az ml job download --name <job-name> \
  --resource-group ml-rg --workspace-name my-workspace \
  --output-name logs \
  --download-path ./job-logs

# Query job logs via Log Analytics
az monitor log-analytics query \
  --workspace <workspace-id> \
  --analytics-query "
    AmlComputeJobEvent
    | where TimeGenerated > ago(24h)
    | where JobName == '<job-name>'
    | project TimeGenerated, EventType, Message
    | order by TimeGenerated desc
  " --output table
```

### Compute Instance Logs

```bash
# View compute instance state and errors
az ml compute show --name dev-instance \
  --resource-group ml-rg --workspace-name my-workspace \
  --query "{state:properties.state, errors:properties.errors, lastOperation:properties.lastOperation}" -o json

# SSH into compute instance for deep debugging
az ml compute connect-ssh --name dev-instance \
  --resource-group ml-rg --workspace-name my-workspace

# On the compute instance, check these log locations:
# /var/log/azureml/                     - Azure ML agent logs
# /var/log/azureml/azureml_setup.log    - Setup/provisioning logs
# /mnt/batch/tasks/startup/stdout.txt   - Startup script output
# /mnt/batch/tasks/startup/stderr.txt   - Startup script errors
# /var/log/syslog                       - System logs
# /var/log/kern.log                     - Kernel logs (GPU driver issues)
# ~/.azureml/logs/                      - SDK-level logs
# nvidia-smi                            - GPU utilization and errors
# dmesg | grep -i gpu                   - GPU kernel messages

# Query compute events in Log Analytics
az monitor log-analytics query \
  --workspace <workspace-id> \
  --analytics-query "
    AmlComputeClusterEvent
    | where TimeGenerated > ago(24h)
    | where ComputeName == 'dev-instance'
    | project TimeGenerated, EventType, Message, NodeId
    | order by TimeGenerated desc
  " --output table
```

### Endpoint Deployment Logs

```bash
# Inference server logs (default - shows score.py output)
az ml online-deployment get-logs \
  --name blue --endpoint-name my-endpoint \
  --resource-group ml-rg --workspace-name my-workspace \
  --lines 500

# Storage initializer logs (model download, environment setup)
az ml online-deployment get-logs \
  --name blue --endpoint-name my-endpoint \
  --resource-group ml-rg --workspace-name my-workspace \
  --container storage-initializer --lines 200

# Query Log Analytics for comprehensive endpoint logs
az monitor log-analytics query \
  --workspace <workspace-id> \
  --analytics-query "
    AmlOnlineEndpointConsoleLog
    | where TimeGenerated > ago(1h)
    | where EndpointName == 'my-endpoint'
    | project TimeGenerated, Message, ContainerName, InstanceId
    | order by TimeGenerated desc
    | take 200
  " --output table

# Monitor endpoint request metrics
az monitor log-analytics query \
  --workspace <workspace-id> \
  --analytics-query "
    AmlOnlineEndpointTrafficLog
    | where TimeGenerated > ago(24h)
    | where EndpointName == 'my-endpoint'
    | summarize
        TotalRequests = count(),
        SuccessRate = countif(ResponseCode >= 200 and ResponseCode < 300) * 100.0 / count(),
        AvgLatencyMs = avg(RequestDuration),
        P99LatencyMs = percentile(RequestDuration, 99)
      by bin(TimeGenerated, 1h), DeploymentName
    | order by TimeGenerated desc
  " --output table

# Check endpoint health metrics
az monitor metrics list \
  --resource $(az ml online-endpoint show -n my-endpoint -g ml-rg -w my-workspace --query id -o tsv) \
  --metric "RequestsPerMinute,RequestLatency,NewConnectionsPerSecond" \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ) \
  --interval PT1M \
  --output table
```

### Workspace Diagnostics

```bash
# Run workspace diagnostic check
az ml workspace diagnose \
  --name my-workspace \
  --resource-group ml-rg

# This checks:
# - Storage account connectivity
# - Key vault accessibility
# - ACR connectivity
# - Application Insights configuration
# - Network configuration
# - DNS resolution
# - NSG rules
# - Private endpoint status

# Check workspace Activity Log for errors
az monitor activity-log list \
  --resource-group ml-rg \
  --start-time $(date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%SZ) \
  --query "[?contains(operationName.value, 'MachineLearningServices')].{Time:eventTimestamp, Operation:operationName.value, Status:status.value, Message:properties.statusMessage}" \
  --output table
```

---

## 12. TROUBLESHOOTING - COMPREHENSIVE ERROR REFERENCE

### Compute Errors

| Error | Cause | Solution |
|-------|-------|----------|
| QuotaExceeded | Regional vCPU quota limit reached | Portal > Subscriptions > Usage + quotas > Request increase for specific VM family |
| AllocationFailed | No capacity in region for VM size | Try different region, different VM size, or use LowPriority tier |
| ComputeInstance won't start | NSG blocking, disk full, image issue | Check NSG rules allow AzureMachineLearning tag on port 44224; check disk space |
| Cluster stuck at 0 nodes | Idle timeout, quota, or VNet issue | Increase idle_time, check quota, verify NSG/subnet config |
| Permission denied on compute | Missing RBAC | Assign AzureML Compute Operator or Contributor role |
| Disk full on compute instance | /tmp or user data partition full | SSH in, run `df -h`, clear `/tmp`, notebook outputs, or unused files |
| SSH connection refused | Public IP disabled, no bastion | Use `az ml compute connect-ssh` for managed VNet instances |
| GPU not detected | Driver issue or wrong VM SKU | Run `nvidia-smi` on instance; ensure CUDA-compatible VM SKU |

### Endpoint Deployment Errors

| Error | Cause | Solution |
|-------|-------|----------|
| ScoringError: Model loading failed | score.py init() error | Check `get-logs`, verify AZUREML_MODEL_DIR, model path in deployment YAML |
| EndpointNotReady | Deployment still provisioning | Wait; check `az ml online-endpoint show --query provisioning_state` |
| HealthCheckFailure | Container not responding on /score | Check liveness/readiness probes, ensure server starts on correct port |
| ImageBuildFailed | Dockerfile or conda env error | Check ACR build logs, test Docker build locally, check conda.yml conflicts |
| InvalidDeploymentSpec: Not enough memory | Container OOM | Increase instance_type to larger VM |
| ResourceNotFound: model not found | Wrong model name or version | Verify with `az ml model list`, check model reference in deployment YAML |
| SSLError calling endpoint | Network/cert issue | Check firewall, use `--set public_network_access=Enabled` for testing |
| 429 Too Many Requests | Throttling | Implement exponential backoff, increase instance_count |
| 503 Service Unavailable | All instances overloaded/crashed | Check logs, increase instance_count, check memory usage |

### Networking Errors

| Error | Cause | Solution |
|-------|-------|----------|
| DNS resolution failure | Missing private DNS zone | Create required DNS zones and link to VNet |
| Connection timeout to workspace | No PE or NSG blocking | Verify PE exists, check NSG allows outbound to AzureMachineLearning |
| Storage access denied | RBAC or network rules | Check storage firewall allows workspace identity; assign Storage Blob Data roles |
| ACR pull failed | AcrPull role missing or ACR firewall | Assign AcrPull to compute identity; check ACR network rules |
| Key Vault access denied | RBAC or firewall | Assign Key Vault roles; check KV network rules allow Azure services |
| Managed network PE not created | Provider not registered | Register Microsoft.Network provider: `az provider register -n Microsoft.Network` |
| Studio UI inaccessible | PE not configured for workspace | Create PE with amlworkspace subresource; configure DNS |

### Job Errors

| Error | Cause | Solution |
|-------|-------|----------|
| UserError: blob does not exist | Wrong data path | Verify datastore paths with `az ml datastore list` |
| EnvironmentBuildError | Docker/conda build fail | Check conda.yml for package conflicts; test locally with `docker build` |
| JobCanceled: exceeded timeout | Job hit wall clock limit | Increase timeout in job YAML or optimize training code |
| ModuleNotFoundError in job | Missing package in environment | Add package to conda.yml or requirements.txt |
| OutOfMemoryError | Insufficient RAM or GPU memory | Use larger VM SKU, reduce batch size, enable gradient checkpointing |
| NCCL timeout (distributed) | Network issue between nodes | Ensure nodes in same subnet; check InfiniBand connectivity for ND-series |

---

## QUICK REFERENCE: SETTING UP A COMPLETE SECURE ML WORKSPACE

Step-by-step checklist for a production-ready, network-isolated Azure ML workspace:

1. Create VNet with subnets for private endpoints and compute
2. Create NSG with required service tag rules for compute subnet
3. Create storage account with firewall (Deny default), private endpoints for blob + file
4. Create key vault with RBAC enabled, purge protection, private endpoint
5. Create ACR (Premium SKU) with firewall, private endpoint
6. Create Application Insights with Log Analytics workspace
7. Create all required private DNS zones and link to VNet
8. Create ML workspace with managed-network=AllowInternetOutbound, private endpoint
9. Run `az ml workspace provision-network` to provision managed network
10. Create CPU cluster for image builds (set as image-build-compute)
11. Create GPU cluster for training
12. Assign RBAC roles: workspace identity -> storage, KV, ACR; compute identity -> storage, ACR
13. Run `az ml workspace diagnose` to verify configuration
14. Create environment, data assets, and test a simple training job
15. Create managed online endpoint and test inference

## References

- [Azure ML Documentation](https://learn.microsoft.com/azure/machine-learning/)
- [Azure AI Foundry Documentation](https://learn.microsoft.com/azure/ai-foundry/)
- [az ml CLI Reference](https://learn.microsoft.com/cli/azure/ml)
- [Az.MachineLearningServices PowerShell Module](https://learn.microsoft.com/powershell/module/az.machinelearningservices/)
- [Terraform AzureRM ML Workspace](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/machine_learning_workspace)
- [Terraform AzureRM ML Compute Cluster](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/machine_learning_compute_cluster)
- [Secure Azure ML Workspace with VNet](https://learn.microsoft.com/azure/machine-learning/how-to-secure-workspace-vnet)
- [Managed Network Isolation](https://learn.microsoft.com/azure/machine-learning/how-to-managed-network)
- [Troubleshoot Online Endpoints](https://learn.microsoft.com/azure/machine-learning/how-to-troubleshoot-online-endpoints)
- [Azure ML Network Isolation Planning](https://learn.microsoft.com/azure/machine-learning/how-to-network-isolation-planning)
- [Azure ML RBAC Roles](https://learn.microsoft.com/azure/machine-learning/how-to-assign-roles)
- [GPU VM Sizes](https://learn.microsoft.com/azure/virtual-machines/sizes/gpu-accelerated/nd-family)
