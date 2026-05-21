# Azure Deployment Stacks: CI/CD, Monitoring, Auditing

Detailed GitHub Actions and Azure DevOps CI/CD examples for deployment stacks, plus monitoring, audit queries, deployment history checks, and operational observability. SKILL.md keeps overview, creation, Bicep template, management, deny settings, actionOnUnmanage, RBAC, migration, best practices, and troubleshooting.

## CI/CD Integration

### GitHub Actions

```yaml
name: Deploy Deployment Stack

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Azure Login
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: What-if Analysis
        run: |
          az stack sub what-if \
            --name MyProductionStack \
            --location eastus \
            --template-file main.bicep \
            --parameters @parameters.json

      - name: Deploy Stack
        run: |
          az stack sub create \
            --name MyProductionStack \
            --location eastus \
            --template-file main.bicep \
            --parameters @parameters.json \
            --deny-settings-mode DenyWriteAndDelete \
            --deny-settings-excluded-principals ${{ secrets.DEVOPS_PRINCIPAL_ID }} \
            --action-on-unmanage deleteAll \
            --yes
```

### Azure DevOps Pipeline

```yaml
trigger:
  branches:
    include:
      - main

pool:
  vmImage: 'ubuntu-latest'

variables:
  azureSubscription: 'MyAzureConnection'
  stackName: 'MyProductionStack'
  location: 'eastus'

steps:
  - task: AzureCLI@2
    displayName: 'What-if Analysis'
    inputs:
      azureSubscription: $(azureSubscription)
      scriptType: 'bash'
      scriptLocation: 'inlineScript'
      inlineScript: |
        az stack sub what-if \
          --name $(stackName) \
          --location $(location) \
          --template-file main.bicep \
          --parameters @parameters.json

  - task: AzureCLI@2
    displayName: 'Deploy Stack'
    inputs:
      azureSubscription: $(azureSubscription)
      scriptType: 'bash'
      scriptLocation: 'inlineScript'
      inlineScript: |
        az stack sub create \
          --name $(stackName) \
          --location $(location) \
          --template-file main.bicep \
          --parameters @parameters.json \
          --deny-settings-mode DenyWriteAndDelete \
          --action-on-unmanage deleteAll \
          --yes
```

## Monitoring and Auditing

### View Stack Events

```bash
# Get deployment operations
az stack sub show \
  --name MyProductionStack \
  --query "deploymentId" \
  --output tsv | \
  xargs -I {} az deployment sub show --name {}

# List managed resources
az stack sub show \
  --name MyProductionStack \
  --query "resources[].id" \
  --output table
```

### Activity Logs

```bash
# Query stack operations
az monitor activity-log list \
  --resource-group MyRG \
  --namespace Microsoft.Resources \
  --start-time 2025-01-01T00:00:00Z \
  --query "[?contains(authorization.action, 'Microsoft.Resources/deploymentStacks')]" \
  --output table
```

