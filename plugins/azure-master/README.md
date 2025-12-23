# Azure Master Plugin

Complete Azure cloud expertise system with 2025 features for Claude Code.

## Overview

Azure Master provides comprehensive knowledge and automation for all major Azure services, featuring the latest 2025 updates including AKS Automatic, Container Apps GPU support, Azure OpenAI GPT-5/reasoning models, Deployment Stacks, and Bicep v0.37+ features.

## Key Features

### 🚀 2025 Azure Services

- **AKS Automatic (GA October 2025)**
  - Zero operational overhead with Karpenter autoscaling
  - HPA, VPA, and KEDA enabled by default
  - Ubuntu 24.04 on Kubernetes 1.34+
  - New billing model: $0.16/hour cluster + compute

- **Container Apps GPU Support (GA)**
  - Serverless GPU with scale-to-zero
  - Per-second billing for cost optimization
  - Dapr integration for microservices
  - Foundry Models integration

- **Azure OpenAI Service 2025 Models**
  - GPT-5 series: gpt-5, gpt-5-pro, gpt-5-codex
  - GPT-4.1 with 1M token context
  - Reasoning models: o4-mini, o3, o1
  - Image generation: GPT-image-1
  - Video generation: Sora

- **Deployment Stacks (GA)**
  - Unified resource lifecycle management
  - Deny settings for resource protection
  - Replaces Azure Blueprints (deprecated July 2026)
  - Subscription and resource group scopes

- **Bicep 2025 (v0.37.4)**
  - externalInput() function (GA)
  - C# authoring for custom extensions
  - Enhanced parameter validation
  - Improved module lifecycle

- **Azure AI Foundry**
  - Model router for optimal selection
  - Agentic retrieval (40% better accuracy)
  - Foundry Observability (Preview)
  - SRE Agent for autonomous monitoring

### 📋 Comprehensive Service Coverage

**Compute**: VMs, AKS, Container Apps, App Service, Azure Functions, Batch

**Networking**: VNet, NSG, Application Gateway, Front Door, Load Balancer, Private Link

**Storage**: Blob Storage, Azure Files, Data Lake, Managed Disks

**Databases**: SQL Database, Cosmos DB, PostgreSQL, MySQL, Redis Cache

**AI/ML**: Azure OpenAI, Cognitive Services, Machine Learning, AI Foundry

**Security**: Key Vault, Microsoft Defender, Entra ID, RBAC, Managed Identity

**Monitoring**: Azure Monitor, Application Insights, Log Analytics

**DevOps**: Deployment Stacks, Bicep, ARM Templates, Azure CLI

## Installation

### Via Claude Code Marketplace

```bash
# Install from marketplace
claude-code plugin install azure-master
```

### Manual Installation

```bash
# Clone repository
git clone https://github.com/JosiahSiegel/claude-plugin-marketplace
cd claude-plugin-marketplace/plugins/azure-master

# Link plugin
claude-code plugin link .
```

## Usage

### Automatic Activation

The plugin automatically activates when you:
- Mention Azure services in your request
- Work with Azure CLI commands
- Deploy infrastructure with Bicep or ARM templates
- Configure AKS, Container Apps, or other Azure resources

### Slash Commands

#### `/azure-master:az-cli`

Execute Azure CLI commands with expert guidance and 2025 best practices.

**Examples:**

```bash
# Create AKS Automatic cluster
/azure-master:az-cli Create an AKS Automatic cluster with Karpenter, Cilium networking, and workload identity

# Deploy Container App with GPU
/azure-master:az-cli Deploy a Container App with NVIDIA A100 GPU for AI inference with scale-to-zero

# Setup Azure OpenAI with GPT-5
/azure-master:az-cli Create Azure OpenAI resource and deploy GPT-5 model with 100 capacity
```

#### `/azure-master:azure-deploy`

Deploy Azure resources using Bicep, ARM templates, or Deployment Stacks.

**Examples:**

```bash
# Create production infrastructure with Deployment Stack
/azure-master:azure-deploy Create a deployment stack for AKS Automatic, Container Apps, and Azure OpenAI

# Deploy multi-region application
/azure-master:azure-deploy Deploy web app with Front Door, App Service in multiple regions, and Cosmos DB

# Infrastructure with monitoring
/azure-master:azure-deploy Create complete observability stack with Log Analytics, Application Insights, and alerts
```

### Skills

#### `aks-automatic-2025`

Complete knowledge base for AKS Automatic including:
- Karpenter configuration and NodePools
- HPA, VPA, and KEDA autoscaling
- Workload identity setup
- GPU NodePools for AI workloads
- Cost optimization strategies

#### `container-apps-gpu-2025`

Azure Container Apps GPU support including:
- Serverless and dedicated GPU configurations
- Dapr integration patterns
- AI model deployment (vLLM, Stable Diffusion)
- Scaling rules and cost optimization
- Batch processing jobs

#### `deployment-stacks-2025`

Deployment Stacks best practices:
- Stack creation at different scopes
- Deny settings and resource protection
- ActionOnUnmanage policies
- Migration from Azure Blueprints

#### `azure-openai-2025`

Latest Azure OpenAI models and features:
- GPT-5 series deployment
- Reasoning models (o3, o4-mini)
- Image and video generation
- Model router configuration
- Foundry Observability

## Agent: Azure Expert

The core `azure-expert` agent provides:

✓ Latest Azure documentation research (WebSearch + Context7)
✓ Production-ready configurations
✓ Well-Architected Framework guidance
✓ Security hardening and RBAC
✓ Cost optimization strategies
✓ Complete service examples with all parameters
✓ Troubleshooting and debugging assistance

## Quick Start Examples

### 1. Create AKS Automatic Cluster

```bash
az aks create \
  --resource-group MyRG \
  --name MyAKSAutomatic \
  --sku automatic \
  --kubernetes-version 1.34 \
  --enable-karpenter \
  --network-plugin azure \
  --network-plugin-mode overlay \
  --network-dataplane cilium \
  --zones 1 2 3 \
  --enable-workload-identity \
  --enable-oidc-issuer
```

### 2. Deploy Container App with GPU

```bash
az containerapp create \
  --name ai-inference \
  --resource-group MyRG \
  --environment myenv \
  --image myregistry.azurecr.io/model:latest \
  --cpu 4 \
  --memory 16Gi \
  --gpu-type nvidia-a100 \
  --gpu-count 1 \
  --min-replicas 0 \
  --max-replicas 10 \
  --target-port 8080 \
  --ingress external
```

### 3. Create Deployment Stack

```bash
az stack sub create \
  --name MyStack \
  --location eastus \
  --template-file main.bicep \
  --deny-settings-mode DenyWriteAndDelete \
  --action-on-unmanage deleteAll \
  --description "Production infrastructure"
```

### 4. Deploy Azure OpenAI GPT-5

```bash
az cognitiveservices account create \
  --name myopenai \
  --resource-group MyRG \
  --kind OpenAI \
  --sku S0 \
  --location eastus

az cognitiveservices account deployment create \
  --resource-group MyRG \
  --name myopenai \
  --deployment-name gpt-5 \
  --model-name gpt-5 \
  --model-version latest \
  --model-format OpenAI \
  --sku-name Standard \
  --sku-capacity 100
```

## Architecture Patterns

### Microservices with Container Apps and Dapr

```bicep
resource containerAppEnv 'Microsoft.App/managedEnvironments@2025-02-01' = {
  name: 'myenv'
  location: location
  properties: {
    daprAIInstrumentationKey: appInsights.properties.InstrumentationKey
    zoneRedundant: true
  }
}

resource frontendApp 'Microsoft.App/containerApps@2025-02-01' = {
  name: 'frontend'
  properties: {
    environmentId: containerAppEnv.id
    configuration: {
      dapr: {
        enabled: true
        appId: 'frontend'
        appPort: 3000
      }
      ingress: {
        external: true
        targetPort: 3000
      }
    }
  }
}

resource backendApp 'Microsoft.App/containerApps@2025-02-01' = {
  name: 'backend'
  properties: {
    environmentId: containerAppEnv.id
    configuration: {
      dapr: {
        enabled: true
        appId: 'backend'
        appPort: 8080
      }
      ingress: {
        external: false
        targetPort: 8080
      }
    }
  }
}
```

### AI/ML Platform with GPU Workloads

- **AKS Automatic**: Training jobs with GPU NodePools
- **Container Apps GPU**: Inference endpoints with scale-to-zero
- **Azure OpenAI**: Pre-trained models via API
- **AI Foundry**: Model management and observability
- **Storage**: Azure Blob for datasets and model artifacts
- **Monitoring**: Application Insights + Foundry Observability

### Hub-Spoke Network Topology

```bash
# Hub VNet with Azure Firewall
az network vnet create \
  --resource-group Hub-RG \
  --name Hub-VNet \
  --address-prefix 10.0.0.0/16 \
  --subnet-name AzureFirewallSubnet \
  --subnet-prefix 10.0.1.0/24

# Spoke VNets for workloads
az network vnet create \
  --resource-group Spoke-RG \
  --name Spoke-VNet \
  --address-prefix 10.1.0.0/16

# VNet peering
az network vnet peering create \
  --name Hub-to-Spoke \
  --resource-group Hub-RG \
  --vnet-name Hub-VNet \
  --remote-vnet Spoke-VNet \
  --allow-vnet-access \
  --allow-forwarded-traffic \
  --allow-gateway-transit
```

## Best Practices

### Reliability
✓ Deploy across availability zones (3 zones for 99.99% SLA)
✓ Use AKS Automatic with Karpenter for dynamic scaling
✓ Implement health probes and readiness checks
✓ Enable automatic OS patching

### Security
✓ Use managed identities (workload identity for AKS)
✓ Implement network policies and private endpoints
✓ Enable Microsoft Defender for Cloud
✓ Store secrets in Key Vault with RBAC
✓ Apply deny settings in Deployment Stacks

### Cost Optimization
✓ Use Container Apps scale-to-zero
✓ Purchase Azure reservations (1-3 years)
✓ Enable Azure Hybrid Benefit
✓ Implement autoscaling policies
✓ Use AKS Automatic for efficient resource allocation

### Performance
✓ Use premium storage tiers for production
✓ Enable accelerated networking
✓ Implement CDN for static content
✓ Use Container Apps GPU for AI workloads
✓ Configure appropriate scaling rules

### Operational Excellence
✓ Use Deployment Stacks for lifecycle management
✓ Implement Infrastructure as Code (Bicep)
✓ Enable comprehensive monitoring
✓ Configure alerts and action groups
✓ Implement CI/CD pipelines

## Azure CLI 2025 Updates

**Version 2.79.0 (November 2025 Breaking Changes)**

- ACR Helm 2 support removed (March 2025)
- Role assignment delete behavior changed
- Deprecated parameters removed (location, endpoint-type, max-percent-unhealthy-deployed-applications)

**Keep Azure CLI Updated:**

```bash
az version
az upgrade
```

## Git Bash / Windows Compatibility

**Critical for Windows developers using Git Bash:**

Azure CLI development is common on Windows with Git Bash, but automatic path conversion can break commands. This plugin includes comprehensive Git Bash compatibility guidance.

### Quick Fix for Git Bash

```bash
# Add to your .bashrc or script start
export MSYS_NO_PATHCONV=1

# Or detect Git Bash automatically
if [[ -n "$MSYSTEM" ]]; then
    export MSYS_NO_PATHCONV=1
fi
```

### Common Issues

**Problem:** Resource IDs get converted incorrectly
```bash
# Fails: /subscriptions/... becomes C:/Program Files/Git/subscriptions/...
az vm start --ids /subscriptions/xxx/resourceGroups/xxx/...
```

**Solution:**
```bash
export MSYS_NO_PATHCONV=1
az vm start --ids /subscriptions/xxx/resourceGroups/xxx/...
```

**Problem:** ARM/Bicep template deployments fail
```bash
# May fail with path conversion issues
az deployment group create --template-file main.bicep --parameters @params.json
```

**Solution:**
```bash
export MSYS_NO_PATHCONV=1
az deployment group create --template-file main.bicep --parameters @params.json
```

### Shell Detection

The plugin agents include automatic shell detection patterns:

```bash
# Detect Git Bash using MSYSTEM variable (most reliable)
if [[ -n "$MSYSTEM" ]]; then
    export MSYS_NO_PATHCONV=1
    echo "Git Bash detected"
fi

# Detect using OSTYPE
case "$OSTYPE" in
    msys*)    export MSYS_NO_PATHCONV=1 ;;
    cygwin*)  export MSYS_NO_PATHCONV=1 ;;
esac
```

### Path Conversion Tools

```bash
# Convert Unix to Windows path
cygpath -w "/c/Projects/template.bicep"
# Output: C:\Projects\template.bicep

# Convert Windows to Unix path
cygpath -u "C:\Projects\template.bicep"
# Output: /c/Projects/template.bicep

# Use in deployments
templatePath=$(cygpath -w "./main.bicep")
az deployment group create --template-file "$templatePath"
```

All Azure Master agents (`az-cli-expert`, `arm-bicep-expert`) include Windows/Git Bash compatibility guidance and examples.

## Troubleshooting

### Check Azure CLI Version

```bash
az version
# Should be 2.79.0 or later
```

### Verify Bicep Version

```bash
az bicep version
# Should be 0.37.4 or later

az bicep upgrade
```

### Check Resource Provider Registration

```bash
az provider list \
  --query "[?registrationState=='Registered']" \
  --output table
```

### View Activity Logs

```bash
az monitor activity-log list \
  --resource-group MyRG \
  --start-time 2025-01-27T00:00:00Z \
  --output table
```

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Add/update documentation and examples
4. Test thoroughly with Azure CLI
5. Submit a pull request

## Resources

- [Azure Documentation](https://learn.microsoft.com/en-us/azure/)
- [AKS Automatic](https://learn.microsoft.com/en-us/azure/aks/automatic)
- [Container Apps](https://learn.microsoft.com/en-us/azure/container-apps/)
- [Deployment Stacks](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deployment-stacks)
- [Azure OpenAI](https://learn.microsoft.com/en-us/azure/ai-foundry/openai/)
- [Bicep Documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [Azure CLI Reference](https://learn.microsoft.com/en-us/cli/azure/)

## License

MIT License - see [LICENSE](../../LICENSE) for details.

## Author

Josiah Siegel (JosiahSiegel@users.noreply.github.com)

## Version

1.1.0 (January 2025)

### What's New in 1.1.0

- **Git Bash / Windows Compatibility**: Comprehensive path conversion guidance for Windows developers
- **Shell Detection**: Automatic Git Bash/MINGW detection with MSYS_NO_PATHCONV configuration
- **ARM/Bicep Windows Support**: Path handling examples for template deployments on Windows
- **Cross-Platform Scripts**: Production-ready scripts that work across Git Bash, PowerShell, and Unix shells
- **Path Conversion Tools**: cygpath usage examples for Windows/Unix path conversion

---

**Azure Master** - Production-ready Azure infrastructure with 2025 best practices.
