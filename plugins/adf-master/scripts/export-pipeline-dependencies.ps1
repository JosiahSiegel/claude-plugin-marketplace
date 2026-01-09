# export-pipeline-dependencies.ps1
# Analyzes ADF pipelines and exports dependency graph for visualization
# Usage: pwsh export-pipeline-dependencies.ps1 -PipelinePath pipeline -OutputFormat mermaid

param(
    [Parameter(Mandatory=$false)]
    [string]$PipelinePath = "pipeline",

    [Parameter(Mandatory=$false)]
    [ValidateSet("mermaid", "json", "csv")]
    [string]$OutputFormat = "mermaid",

    [Parameter(Mandatory=$false)]
    [string]$OutputFile = "",

    [Parameter(Mandatory=$false)]
    [switch]$IncludeDatasets,

    [Parameter(Mandatory=$false)]
    [switch]$IncludeLinkedServices
)

$ErrorActionPreference = "Stop"

Write-Host "=== ADF Pipeline Dependency Analyzer ===" -ForegroundColor Cyan
Write-Host ""

# Find pipeline files
if (-not (Test-Path $PipelinePath)) {
    Write-Error "Pipeline path not found: $PipelinePath"
    exit 1
}

$pipelineFiles = Get-ChildItem -Path $PipelinePath -Filter "*.json" -Recurse
if ($pipelineFiles.Count -eq 0) {
    Write-Error "No pipeline JSON files found in: $PipelinePath"
    exit 1
}

Write-Host "Found $($pipelineFiles.Count) pipeline files" -ForegroundColor Yellow
Write-Host ""

# Data structures for dependencies
$pipelines = @{}
$executePipelineDeps = @()
$datasetDeps = @()
$linkedServiceDeps = @()

# Parse each pipeline
foreach ($file in $pipelineFiles) {
    Write-Host "Analyzing: $($file.Name)"

    $pipeline = Get-Content $file.FullName -Raw | ConvertFrom-Json
    $pipelineName = $pipeline.name

    $pipelines[$pipelineName] = @{
        File = $file.Name
        Activities = @()
        Dependencies = @()
        Datasets = @()
        LinkedServices = @()
    }

    # Analyze activities
    function Analyze-Activities {
        param($activities, $pipelineName)

        foreach ($activity in $activities) {
            $pipelines[$pipelineName].Activities += $activity.name

            # Check for Execute Pipeline
            if ($activity.type -eq "ExecutePipeline") {
                $targetPipeline = $activity.typeProperties.pipeline.referenceName
                $executePipelineDeps += @{
                    Source = $pipelineName
                    Target = $targetPipeline
                    ActivityName = $activity.name
                }
                $pipelines[$pipelineName].Dependencies += $targetPipeline
            }

            # Check for datasets
            if ($activity.inputs) {
                foreach ($input in $activity.inputs) {
                    $datasetName = $input.referenceName
                    $datasetDeps += @{
                        Pipeline = $pipelineName
                        Dataset = $datasetName
                        Direction = "input"
                        Activity = $activity.name
                    }
                    if ($datasetName -notin $pipelines[$pipelineName].Datasets) {
                        $pipelines[$pipelineName].Datasets += $datasetName
                    }
                }
            }
            if ($activity.outputs) {
                foreach ($output in $activity.outputs) {
                    $datasetName = $output.referenceName
                    $datasetDeps += @{
                        Pipeline = $pipelineName
                        Dataset = $datasetName
                        Direction = "output"
                        Activity = $activity.name
                    }
                    if ($datasetName -notin $pipelines[$pipelineName].Datasets) {
                        $pipelines[$pipelineName].Datasets += $datasetName
                    }
                }
            }

            # Check for linked services
            if ($activity.linkedServiceName) {
                $lsName = $activity.linkedServiceName.referenceName
                $linkedServiceDeps += @{
                    Pipeline = $pipelineName
                    LinkedService = $lsName
                    Activity = $activity.name
                }
                if ($lsName -notin $pipelines[$pipelineName].LinkedServices) {
                    $pipelines[$pipelineName].LinkedServices += $lsName
                }
            }

            # Recurse into container activities
            if ($activity.typeProperties.activities) {
                Analyze-Activities -activities $activity.typeProperties.activities -pipelineName $pipelineName
            }
            if ($activity.typeProperties.ifTrueActivities) {
                Analyze-Activities -activities $activity.typeProperties.ifTrueActivities -pipelineName $pipelineName
            }
            if ($activity.typeProperties.ifFalseActivities) {
                Analyze-Activities -activities $activity.typeProperties.ifFalseActivities -pipelineName $pipelineName
            }
            if ($activity.typeProperties.cases) {
                foreach ($case in $activity.typeProperties.cases) {
                    if ($case.activities) {
                        Analyze-Activities -activities $case.activities -pipelineName $pipelineName
                    }
                }
            }
            if ($activity.typeProperties.defaultActivities) {
                Analyze-Activities -activities $activity.typeProperties.defaultActivities -pipelineName $pipelineName
            }
        }
    }

    if ($pipeline.properties.activities) {
        Analyze-Activities -activities $pipeline.properties.activities -pipelineName $pipelineName
    }
}

Write-Host ""
Write-Host "=== Dependency Analysis ===" -ForegroundColor Cyan
Write-Host "Pipelines: $($pipelines.Count)"
Write-Host "Execute Pipeline calls: $($executePipelineDeps.Count)"
Write-Host "Dataset references: $($datasetDeps.Count)"
Write-Host "Linked Service references: $($linkedServiceDeps.Count)"
Write-Host ""

# Generate output
$output = ""

switch ($OutputFormat) {
    "mermaid" {
        $output = "```mermaid`n"
        $output += "graph TD`n"
        $output += "    %% Pipeline Dependencies`n"

        # Add pipelines as nodes
        foreach ($pipelineName in $pipelines.Keys) {
            $activityCount = $pipelines[$pipelineName].Activities.Count
            $output += "    $($pipelineName -replace '-','_')[`"$pipelineName<br/>($activityCount activities)`"]`n"
        }

        $output += "`n    %% Execute Pipeline relationships`n"

        # Add Execute Pipeline edges
        foreach ($dep in $executePipelineDeps) {
            $source = $dep.Source -replace '-','_'
            $target = $dep.Target -replace '-','_'
            $output += "    $source -->|$($dep.ActivityName)| $target`n"
        }

        if ($IncludeDatasets) {
            $output += "`n    %% Dataset nodes`n"
            $datasets = $datasetDeps | Select-Object -ExpandProperty Dataset -Unique
            foreach ($ds in $datasets) {
                $dsNode = $ds -replace '-','_'
                $output += "    $dsNode[($ds)]`n"
            }

            $output += "`n    %% Dataset relationships`n"
            foreach ($dep in $datasetDeps) {
                $pipeline = $dep.Pipeline -replace '-','_'
                $dataset = $dep.Dataset -replace '-','_'
                if ($dep.Direction -eq "input") {
                    $output += "    $dataset --> $pipeline`n"
                } else {
                    $output += "    $pipeline --> $dataset`n"
                }
            }
        }

        if ($IncludeLinkedServices) {
            $output += "`n    %% Linked Service nodes`n"
            $linkedServices = $linkedServiceDeps | Select-Object -ExpandProperty LinkedService -Unique
            foreach ($ls in $linkedServices) {
                $lsNode = $ls -replace '-','_'
                $output += "    $lsNode{$ls}`n"
            }

            $output += "`n    %% Linked Service relationships`n"
            foreach ($dep in $linkedServiceDeps) {
                $pipeline = $dep.Pipeline -replace '-','_'
                $ls = $dep.LinkedService -replace '-','_'
                $output += "    $pipeline -.-> $ls`n"
            }
        }

        $output += "```"
    }

    "json" {
        $outputObj = @{
            pipelines = $pipelines
            executePipelineDependencies = $executePipelineDeps
            datasetDependencies = $datasetDeps
            linkedServiceDependencies = $linkedServiceDeps
        }
        $output = $outputObj | ConvertTo-Json -Depth 10
    }

    "csv" {
        $output = "source,target,type,activity`n"
        foreach ($dep in $executePipelineDeps) {
            $output += "$($dep.Source),$($dep.Target),execute_pipeline,$($dep.ActivityName)`n"
        }
        if ($IncludeDatasets) {
            foreach ($dep in $datasetDeps) {
                $output += "$($dep.Pipeline),$($dep.Dataset),dataset_$($dep.Direction),$($dep.Activity)`n"
            }
        }
        if ($IncludeLinkedServices) {
            foreach ($dep in $linkedServiceDeps) {
                $output += "$($dep.Pipeline),$($dep.LinkedService),linked_service,$($dep.Activity)`n"
            }
        }
    }
}

# Output results
if ($OutputFile) {
    $output | Set-Content $OutputFile -Encoding UTF8
    Write-Host "Output written to: $OutputFile" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "=== Output ($OutputFormat) ===" -ForegroundColor Cyan
    Write-Host $output
}

# Identify potential issues
Write-Host ""
Write-Host "=== Potential Issues ===" -ForegroundColor Yellow

# Check for circular dependencies
$visited = @{}
$recursionStack = @{}

function Has-CircularDependency {
    param($pipeline)

    if ($recursionStack[$pipeline]) {
        return $true
    }
    if ($visited[$pipeline]) {
        return $false
    }

    $visited[$pipeline] = $true
    $recursionStack[$pipeline] = $true

    foreach ($dep in $pipelines[$pipeline].Dependencies) {
        if (Has-CircularDependency -pipeline $dep) {
            return $true
        }
    }

    $recursionStack[$pipeline] = $false
    return $false
}

$hasCircular = $false
foreach ($pipeline in $pipelines.Keys) {
    $visited = @{}
    $recursionStack = @{}
    if (Has-CircularDependency -pipeline $pipeline) {
        Write-Host "  WARNING: Circular dependency detected involving: $pipeline" -ForegroundColor Red
        $hasCircular = $true
    }
}

if (-not $hasCircular) {
    Write-Host "  No circular dependencies detected" -ForegroundColor Green
}

# Check for orphan pipelines (not called by anything)
$calledPipelines = $executePipelineDeps | Select-Object -ExpandProperty Target -Unique
$orphans = $pipelines.Keys | Where-Object { $_ -notin $calledPipelines }
if ($orphans.Count -gt 0 -and $orphans.Count -lt $pipelines.Count) {
    Write-Host "  Root pipelines (entry points): $($orphans -join ', ')" -ForegroundColor Cyan
}
