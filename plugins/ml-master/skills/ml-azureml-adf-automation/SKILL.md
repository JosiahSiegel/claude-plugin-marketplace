---
name: ml-azureml-adf-automation
description: |
  This skill should be used when the user asks to automate Azure ML and Azure Data Factory production workflows. PROACTIVELY activate for: (1) Azure ML code asset registration, azure-ai-ml SDK, AML code versions, `result.version`, requested-vs-actual versions, (2) ADF to Azure ML orchestration, ADF WebActivity, managed identity blob reads, `connectVia`, managed VNet IR, (3) code asset version pointer blobs, latest.json contracts, training/scoring code version propagation, (4) private storage firewalls, Microsoft-hosted CI agents, temporary network rules, storage data-plane smoke tests, (5) marshmallow<4 pinning, AML SDK import failures, runtime validation for Azure ML infrastructure. Provides: operationally safe Azure ML + ADF automation patterns.
---

# Azure ML and ADF Automation

## Overview

Use this skill for Azure Machine Learning automation that registers code assets in CI and orchestrates training, scoring, registration, or deployment through Azure Data Factory. The main invariant is that runtime systems must consume the exact Azure ML asset versions that were actually registered, not the versions a pipeline attempted to request. Validate every recommendation against runtime behavior because Azure ML, ADF, storage networking, and SDK dependency behavior can diverge from static API documentation.

## Core Invariants

- CI owns Azure ML code asset registration and publishes the actual SDK-returned version.
- ADF receives code versions through an explicit contract, usually a storage pointer blob, instead of discovering AML code versions at runtime.
- The SDK result is the source of truth: requested version, build ID, branch name, or commit-derived strings are not authoritative.
- Private storage requires both correct RBAC and proven data-plane reachability from the executing runtime.
- ADF WebActivity networking must be tested through the intended integration runtime, not just validated as JSON.
- Dependency constraints for Azure ML automation are pinned in CI environments.
- Runtime evidence beats plausible ARM paths, documentation snippets, or successful template compilation.

## Azure ML Code Asset Registration

Prefer the Python SDK for registering Azure ML code assets when automation must reliably capture the registered version. Use the Azure CLI only after confirming the target environment's `az ml` extension supports the needed code commands and returns enough information for downstream automation.

```python
from azure.ai.ml import MLClient
from azure.ai.ml.entities._assets._artifacts.code import Code
from azure.identity import AzureCliCredential

ml_client = MLClient(
    AzureCliCredential(),
    subscription_id,
    resource_group,
    workspace_name,
)

result = ml_client._code.create_or_update(
    Code(name=code_name, version=requested_version, path=staged_code_path)
)
actual_version = result.version
print(actual_version)
```

Do not assume `requested_version == result.version`. Azure ML code assets can deduplicate uploads by content hash and return an existing version when the staged directory matches a prior asset. That is useful storage behavior but dangerous if CI publishes a requested build identifier instead of the SDK-returned version.

### CI Output Variable Pattern

Publish the returned version as a pipeline output variable and wire downstream steps to that output.

```python
print(
    "##vso[task.setvariable "
    f"variable=trainingCodeVersion;isOutput=true]{result.version}"
)
```

Prefer:

```powershell
$registeredVersion = '$(RegisterTrainingCode.trainingCodeVersion)'
```

Avoid:

```powershell
$registeredVersion = '$(Build.BuildId)'
```

If unique asset versions are operationally required even when code content repeats, stage the code directory and write a small marker file such as `.aml-code-asset-version` before registration. Treat this only as a dedup workaround. The real contract remains the SDK-returned `result.version`.

## ADF to Azure ML Version Resolution

Avoid making ADF discover AML code versions through Azure ML ARM code-container endpoints unless that exact path has passed runtime validation. Some AML management endpoints can appear valid in REST documentation but fail from ADF WebActivity at execution time with unsupported-operation behavior. Treat that as service behavior until proven otherwise, not primarily an RBAC problem.

Use a CI-written pointer blob as the runtime contract between registration and orchestration:

```text
https://<storage-account>.blob.core.windows.net/ml-globals/code-assets/training-code/latest.json
```

Example payload:

```json
{
  "assetName": "training-code",
  "version": "<actual-sdk-returned-version>",
  "workspaceName": "<workspace-name>",
  "resourceGroup": "<resource-group>",
  "subscriptionId": "<subscription-id>",
  "buildId": "<build-or-run-id>",
  "sourceBranch": "<branch>",
  "sourceVersion": "<source-version>",
  "registeredAtUtc": "<timestamp>"
}
```

ADF reads `version` from this blob and passes it as a parameter to training, scoring, model registration, or deployment pipelines. The payload may include provenance fields, but downstream jobs should depend only on fields that are deliberately part of the contract.

## ADF WebActivity for Pointer Blob Reads

Read the pointer blob with managed identity authentication against Azure Storage:

```json
{
  "name": "ReadLatestTrainingCodeVersion",
  "type": "WebActivity",
  "typeProperties": {
    "method": "GET",
    "url": {
      "type": "Expression",
      "value": "@concat('https://', pipeline().globalParameters.StorageAccountName, '.blob.core.windows.net/ml-globals/code-assets/training-code/latest.json')"
    },
    "headers": {
      "x-ms-version": "2023-11-03",
      "Accept": "application/json"
    },
    "authentication": {
      "type": "MSI",
      "resource": "https://storage.azure.com/"
    },
    "connectVia": {
      "referenceName": "<managed-vnet-ir-name>",
      "type": "IntegrationRuntimeReference"
    }
  }
}
```

Critical placement rule: for ADF WebActivity, `connectVia` belongs inside `typeProperties`. If it is placed at the activity root, it can be ignored, causing traffic to leave over the public internet and fail against storage accounts with `defaultAction: Deny`.

Required access commonly includes:

- ADF managed identity: `Storage Blob Data Reader` on the pointer container or account scope.
- CI service connection identity: `Storage Blob Data Contributor` to write pointer blobs.
- CI service connection identity: `Storage Account Contributor` when the pipeline manages storage firewall rules.

## Private Storage and Hosted CI Agents

For storage accounts with private endpoints and `defaultAction: Deny`, Microsoft-hosted CI agents usually egress from public per-run IP addresses. Correct RBAC is not enough if the agent cannot reach the storage data plane. Before blaming the Azure ML SDK, ADF, or IAM, prove storage reachability from the agent.

Safe CI pattern:

1. Resolve the agent public IP.
2. Add a temporary storage network rule for that IP.
3. Wait for propagation.
4. Smoke-test storage data-plane access.
5. Register code assets and write pointer blobs.
6. Remove the temporary rule in an `always()` cleanup step.

```powershell
$agentIp = (Invoke-RestMethod -Uri 'https://api.ipify.org' -TimeoutSec 20).Trim()

az storage account network-rule add `
  --resource-group $rg `
  --account-name $storageAccount `
  --action Allow `
  --ip-address $agentIp `
  --only-show-errors

Start-Sleep -Seconds 30

az storage container list `
  --account-name $storageAccount `
  --auth-mode login `
  --only-show-errors `
  -o none
```

Cleanup should run even when registration fails. In Azure DevOps YAML, put network-rule removal in a step with `condition: always()`.

## Python Dependency Pinning

Some `azure-ai-ml` versions import private `marshmallow` symbols that are unavailable in marshmallow 4.x. Hosted agents can install an incompatible transitive version and fail before any Azure ML API call runs. Pin the SDK and transitive dependency together when using affected versions.

```powershell
python -m pip install --upgrade `
  "azure-ai-ml==1.24.0" `
  "azure-identity==1.19.0" `
  "marshmallow>=3.18,<4.0"
```

If using a newer SDK, verify the dependency behavior in CI rather than removing the pin based on local success.

## ADF Development Workflow

Confirm which ADF execution mode reads unpublished Git-branch state and which mode runs the published factory definition. Debug runs may exercise branch state, while scheduled and production runs typically execute the last published factory. Manual trigger behavior depends on how the factory is configured and invoked. Pick the mode that actually exercises the change being validated.

## Runtime Validation Standard

Accept runtime evidence, not structural plausibility. Validate:

- Azure ML registration returned `result.version` and CI propagated that exact value.
- Pointer blobs contain the version that Azure ML actually registered.
- ADF reads the blob through the intended integration runtime and managed identity.
- Storage is tested with the real firewall posture and CI agent egress path.
- Downstream ADF parameters flow into the AML job definition used at runtime.
- The AML training or scoring job starts with the expected code asset version.
- SDK imports succeed in the same hosted-agent image used by CI.

Insufficient validation includes: docs showing an endpoint exists, JSON parsing, a plausible ARM URL, a successful deployment template, a requested version printed in logs without checking `result.version`, or review comments without runtime evidence.

## Operational Checklist

- [ ] Does CI own registration of Azure ML code assets?
- [ ] Does CI capture and publish SDK-returned `result.version`?
- [ ] Does ADF receive the exact code version through an explicit parameter or pointer blob?
- [ ] Does the pointer payload separate contract fields from optional provenance metadata?
- [ ] Are ADF WebActivities using `connectVia` inside `typeProperties` when private networking is required?
- [ ] Is MSI blob access using the auth resource `https://storage.azure.com/`?
- [ ] Does the ADF managed identity have `Storage Blob Data Reader`?
- [ ] Does the CI service connection identity have `Storage Blob Data Contributor`?
- [ ] If CI changes storage firewall rules, does it add, wait, smoke-test, and remove in cleanup?
- [ ] Are known Azure ML SDK dependency constraints pinned?
- [ ] Was validation performed against the runtime infrastructure path, not only compiled or reviewed?

## Short Rules

- Use the Azure ML Python SDK for code registration unless CLI behavior is verified in the target environment.
- Never assume requested version equals registered version.
- Treat SDK `result.version` as the source of truth.
- Avoid AML ARM `/codes/...` discovery from ADF without runtime testing.
- Use blob pointers for ADF-readable ML asset version contracts.
- Put ADF WebActivity `connectVia` inside `typeProperties`.
- Assume hosted CI agents need temporary storage firewall access for private storage.
- Pin transitive dependencies when AML SDK imports have known constraints.
- Require runtime validation for ML infrastructure changes.

## Sources

- Azure Machine Learning documentation: https://learn.microsoft.com/azure/machine-learning/
- Azure Data Factory Web activity documentation: https://learn.microsoft.com/azure/data-factory/control-flow-web-activity
- Azure Storage firewall and virtual network documentation: https://learn.microsoft.com/azure/storage/common/storage-network-security
- Azure Machine Learning Python SDK documentation: https://learn.microsoft.com/python/api/overview/azure/ai-ml-readme
