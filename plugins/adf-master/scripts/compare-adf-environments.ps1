# compare-adf-environments.ps1
# Compares ADF resources between two environments (e.g., dev vs prod)
# Usage: pwsh compare-adf-environments.ps1 -SourceFactory adf-dev -TargetFactory adf-prod

param(
    [Parameter(Mandatory=$true)]
    [string]$SourceFactory,

    [Parameter(Mandatory=$true)]
    [string]$TargetFactory,

    [Parameter(Mandatory=$false)]
    [string]$ResourceGroup = "",

    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId = "",

    [Parameter(Mandatory=$false)]
    [ValidateSet("all", "pipelines", "datasets", "linkedServices", "triggers", "dataflows")]
    [string]$ResourceType = "all",

    [Parameter(Mandatory=$false)]
    [switch]$ShowDetails,

    [Parameter(Mandatory=$false)]
    [string]$OutputFile = ""
)

$ErrorActionPreference = "Stop"

Write-Host "=== ADF Environment Comparison ===" -ForegroundColor Cyan
Write-Host "Source: $SourceFactory"
Write-Host "Target: $TargetFactory"
Write-Host ""

# Check Azure connection
try {
    $context = Get-AzContext
    if ($null -eq $context) {
        Write-Error "Not logged in to Azure. Run Connect-AzAccount first."
        exit 1
    }
    Write-Host "Azure Context: $($context.Account.Id)" -ForegroundColor Gray

    if ($SubscriptionId) {
        Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
    }
} catch {
    Write-Error "Azure PowerShell module not available. Install with: Install-Module -Name Az -Scope CurrentUser"
    exit 1
}

# Function to get ADF resources
function Get-AdfResources {
    param(
        [string]$FactoryName,
        [string]$ResourceGroupName,
        [string]$Type
    )

    $resources = @{}

    switch ($Type) {
        "pipelines" {
            $items = Get-AzDataFactoryV2Pipeline -ResourceGroupName $ResourceGroupName -DataFactoryName $FactoryName
            foreach ($item in $items) {
                $resources[$item.Name] = @{
                    Name = $item.Name
                    Type = "Pipeline"
                    Properties = $item.Properties | ConvertTo-Json -Depth 10 -Compress
                }
            }
        }
        "datasets" {
            $items = Get-AzDataFactoryV2Dataset -ResourceGroupName $ResourceGroupName -DataFactoryName $FactoryName
            foreach ($item in $items) {
                $resources[$item.Name] = @{
                    Name = $item.Name
                    Type = "Dataset"
                    Properties = $item.Properties | ConvertTo-Json -Depth 10 -Compress
                }
            }
        }
        "linkedServices" {
            $items = Get-AzDataFactoryV2LinkedService -ResourceGroupName $ResourceGroupName -DataFactoryName $FactoryName
            foreach ($item in $items) {
                $resources[$item.Name] = @{
                    Name = $item.Name
                    Type = "LinkedService"
                    Properties = $item.Properties | ConvertTo-Json -Depth 10 -Compress
                }
            }
        }
        "triggers" {
            $items = Get-AzDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $FactoryName
            foreach ($item in $items) {
                $resources[$item.Name] = @{
                    Name = $item.Name
                    Type = "Trigger"
                    Properties = $item.Properties | ConvertTo-Json -Depth 10 -Compress
                }
            }
        }
        "dataflows" {
            $items = Get-AzDataFactoryV2DataFlow -ResourceGroupName $ResourceGroupName -DataFactoryName $FactoryName
            foreach ($item in $items) {
                $resources[$item.Name] = @{
                    Name = $item.Name
                    Type = "DataFlow"
                    Properties = $item.Properties | ConvertTo-Json -Depth 10 -Compress
                }
            }
        }
    }

    return $resources
}

# Determine resource groups if not provided
if (-not $ResourceGroup) {
    Write-Host "Detecting resource groups..." -ForegroundColor Yellow
    $factories = Get-AzDataFactoryV2
    $sourceRg = ($factories | Where-Object { $_.DataFactoryName -eq $SourceFactory }).ResourceGroupName
    $targetRg = ($factories | Where-Object { $_.DataFactoryName -eq $TargetFactory }).ResourceGroupName

    if (-not $sourceRg) {
        Write-Error "Source factory not found: $SourceFactory"
        exit 1
    }
    if (-not $targetRg) {
        Write-Error "Target factory not found: $TargetFactory"
        exit 1
    }
} else {
    $sourceRg = $ResourceGroup
    $targetRg = $ResourceGroup
}

Write-Host "Source RG: $sourceRg" -ForegroundColor Gray
Write-Host "Target RG: $targetRg" -ForegroundColor Gray
Write-Host ""

# Determine which resource types to compare
$resourceTypes = @()
if ($ResourceType -eq "all") {
    $resourceTypes = @("pipelines", "datasets", "linkedServices", "triggers", "dataflows")
} else {
    $resourceTypes = @($ResourceType)
}

# Comparison results
$results = @{
    OnlyInSource = @()
    OnlyInTarget = @()
    Different = @()
    Identical = @()
}

# Compare each resource type
foreach ($type in $resourceTypes) {
    Write-Host "Comparing $type..." -ForegroundColor Cyan

    try {
        $sourceResources = Get-AdfResources -FactoryName $SourceFactory -ResourceGroupName $sourceRg -Type $type
        $targetResources = Get-AdfResources -FactoryName $TargetFactory -ResourceGroupName $targetRg -Type $type

        Write-Host "  Source: $($sourceResources.Count) | Target: $($targetResources.Count)"

        # Find resources only in source
        foreach ($name in $sourceResources.Keys) {
            if (-not $targetResources.ContainsKey($name)) {
                $results.OnlyInSource += @{
                    Name = $name
                    Type = $type
                    Factory = $SourceFactory
                }
            }
        }

        # Find resources only in target
        foreach ($name in $targetResources.Keys) {
            if (-not $sourceResources.ContainsKey($name)) {
                $results.OnlyInTarget += @{
                    Name = $name
                    Type = $type
                    Factory = $TargetFactory
                }
            }
        }

        # Compare matching resources
        foreach ($name in $sourceResources.Keys) {
            if ($targetResources.ContainsKey($name)) {
                $sourceProps = $sourceResources[$name].Properties
                $targetProps = $targetResources[$name].Properties

                # Normalize for comparison (remove environment-specific values)
                $sourceNorm = $sourceProps -replace $SourceFactory, "<FACTORY>" -replace $sourceRg, "<RG>"
                $targetNorm = $targetProps -replace $TargetFactory, "<FACTORY>" -replace $targetRg, "<RG>"

                if ($sourceNorm -ne $targetNorm) {
                    $results.Different += @{
                        Name = $name
                        Type = $type
                        SourceProperties = $sourceProps
                        TargetProperties = $targetProps
                    }
                } else {
                    $results.Identical += @{
                        Name = $name
                        Type = $type
                    }
                }
            }
        }
    } catch {
        Write-Host "  Error comparing $type`: $_" -ForegroundColor Red
    }
}

# Display results
Write-Host ""
Write-Host "=== Comparison Results ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "Resources only in $SourceFactory (not in $TargetFactory):" -ForegroundColor Yellow
if ($results.OnlyInSource.Count -eq 0) {
    Write-Host "  None" -ForegroundColor Green
} else {
    foreach ($item in $results.OnlyInSource) {
        Write-Host "  - [$($item.Type)] $($item.Name)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Resources only in $TargetFactory (not in $SourceFactory):" -ForegroundColor Yellow
if ($results.OnlyInTarget.Count -eq 0) {
    Write-Host "  None" -ForegroundColor Green
} else {
    foreach ($item in $results.OnlyInTarget) {
        Write-Host "  - [$($item.Type)] $($item.Name)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Resources with differences:" -ForegroundColor Yellow
if ($results.Different.Count -eq 0) {
    Write-Host "  None" -ForegroundColor Green
} else {
    foreach ($item in $results.Different) {
        Write-Host "  - [$($item.Type)] $($item.Name)" -ForegroundColor Yellow
        if ($ShowDetails) {
            Write-Host "    Source: $($item.SourceProperties.Substring(0, [Math]::Min(100, $item.SourceProperties.Length)))..." -ForegroundColor Gray
            Write-Host "    Target: $($item.TargetProperties.Substring(0, [Math]::Min(100, $item.TargetProperties.Length)))..." -ForegroundColor Gray
        }
    }
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "Only in source: $($results.OnlyInSource.Count)" -ForegroundColor $(if ($results.OnlyInSource.Count -gt 0) { "Red" } else { "Green" })
Write-Host "Only in target: $($results.OnlyInTarget.Count)" -ForegroundColor $(if ($results.OnlyInTarget.Count -gt 0) { "Red" } else { "Green" })
Write-Host "Different: $($results.Different.Count)" -ForegroundColor $(if ($results.Different.Count -gt 0) { "Yellow" } else { "Green" })
Write-Host "Identical: $($results.Identical.Count)" -ForegroundColor Green

# Output to file if specified
if ($OutputFile) {
    $results | ConvertTo-Json -Depth 10 | Set-Content $OutputFile -Encoding UTF8
    Write-Host ""
    Write-Host "Detailed results written to: $OutputFile" -ForegroundColor Green
}

# Exit code
if ($results.OnlyInSource.Count -gt 0 -or $results.OnlyInTarget.Count -gt 0 -or $results.Different.Count -gt 0) {
    Write-Host ""
    Write-Host "Environments are NOT in sync" -ForegroundColor Red
    exit 1
} else {
    Write-Host ""
    Write-Host "Environments are in sync" -ForegroundColor Green
    exit 0
}
