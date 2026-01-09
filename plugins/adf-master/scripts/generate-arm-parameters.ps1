# generate-arm-parameters.ps1
# Generates environment-specific ARM parameter files for ADF deployments
# Usage: pwsh generate-arm-parameters.ps1 -TemplateFile ARMTemplateForFactory.json -OutputPath parameters -Environments dev,test,prod

param(
    [Parameter(Mandatory=$true)]
    [string]$TemplateFile,

    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "parameters",

    [Parameter(Mandatory=$false)]
    [string[]]$Environments = @("dev", "test", "prod"),

    [Parameter(Mandatory=$false)]
    [string]$FactoryNamePrefix = "",

    [Parameter(Mandatory=$false)]
    [switch]$IncludeKeyVaultReferences
)

$ErrorActionPreference = "Stop"

Write-Host "=== ADF ARM Parameter File Generator ===" -ForegroundColor Cyan
Write-Host ""

# Validate template file exists
if (-not (Test-Path $TemplateFile)) {
    Write-Error "Template file not found: $TemplateFile"
    exit 1
}

# Create output directory
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    Write-Host "Created output directory: $OutputPath" -ForegroundColor Green
}

# Read template
Write-Host "Reading template: $TemplateFile"
$template = Get-Content $TemplateFile -Raw | ConvertFrom-Json

# Extract parameters
$parameters = $template.parameters
if ($null -eq $parameters) {
    Write-Error "No parameters found in template"
    exit 1
}

Write-Host "Found $($parameters.PSObject.Properties.Count) parameters" -ForegroundColor Yellow
Write-Host ""

# Parameter categorization helpers
$sensitivePatterns = @("password", "secret", "key", "credential", "token", "connectionstring")
$environmentPatterns = @("server", "database", "endpoint", "url", "path", "storage", "keyvault")

function Get-ParameterCategory {
    param([string]$Name)

    $lowerName = $Name.ToLower()

    foreach ($pattern in $sensitivePatterns) {
        if ($lowerName -match $pattern) {
            return "sensitive"
        }
    }

    foreach ($pattern in $environmentPatterns) {
        if ($lowerName -match $pattern) {
            return "environment"
        }
    }

    return "general"
}

function Get-KeyVaultReference {
    param(
        [string]$ParameterName,
        [string]$Environment,
        [string]$KeyVaultName
    )

    return @{
        reference = @{
            keyVault = @{
                id = "/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.KeyVault/vaults/$KeyVaultName"
            }
            secretName = "$ParameterName-$Environment"
        }
    }
}

# Generate parameter file for each environment
foreach ($env in $Environments) {
    Write-Host "Generating parameters for: $env" -ForegroundColor Cyan

    $envParams = @{
        '$schema' = "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#"
        contentVersion = "1.0.0.0"
        parameters = @{}
    }

    $keyVaultName = "kv-adf-$env"

    foreach ($prop in $parameters.PSObject.Properties) {
        $paramName = $prop.Name
        $paramDef = $prop.Value
        $category = Get-ParameterCategory -Name $paramName

        # Determine value based on category and environment
        $paramValue = $null

        switch ($category) {
            "sensitive" {
                if ($IncludeKeyVaultReferences) {
                    $paramValue = Get-KeyVaultReference -ParameterName $paramName -Environment $env -KeyVaultName $keyVaultName
                } else {
                    # Placeholder for sensitive values
                    $paramValue = @{ value = "<$paramName-$env>" }
                }
            }
            "environment" {
                # Environment-specific placeholder
                $paramValue = @{ value = "<$paramName-$env>" }
            }
            default {
                # Use default value if available, otherwise placeholder
                if ($null -ne $paramDef.defaultValue) {
                    $paramValue = @{ value = $paramDef.defaultValue }
                } else {
                    $paramValue = @{ value = "<$paramName>" }
                }
            }
        }

        # Special handling for factoryName
        if ($paramName -eq "factoryName") {
            if ($FactoryNamePrefix) {
                $paramValue = @{ value = "$FactoryNamePrefix-$env" }
            } else {
                $paramValue = @{ value = "adf-<project>-$env" }
            }
        }

        $envParams.parameters[$paramName] = $paramValue
    }

    # Write parameter file
    $outputFile = Join-Path $OutputPath "ARMTemplateParametersForFactory.$env.json"
    $envParams | ConvertTo-Json -Depth 10 | Set-Content $outputFile -Encoding UTF8

    Write-Host "  Created: $outputFile" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "Generated $($Environments.Count) parameter files in: $OutputPath"
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Replace placeholder values (<...>) with actual environment-specific values"
Write-Host "2. Store sensitive values in Azure Key Vault"

if ($IncludeKeyVaultReferences) {
    Write-Host "3. Update Key Vault references with actual subscription/resource group IDs"
    Write-Host "4. Create corresponding secrets in each environment's Key Vault"
}

Write-Host ""
Write-Host "Parameter Categories Found:" -ForegroundColor Yellow

$sensitiveCount = 0
$environmentCount = 0
$generalCount = 0

foreach ($prop in $parameters.PSObject.Properties) {
    $category = Get-ParameterCategory -Name $prop.Name
    switch ($category) {
        "sensitive" { $sensitiveCount++ }
        "environment" { $environmentCount++ }
        default { $generalCount++ }
    }
}

Write-Host "  Sensitive (Key Vault recommended): $sensitiveCount"
Write-Host "  Environment-specific: $environmentCount"
Write-Host "  General: $generalCount"
