---
name: adf-validate
description: Validate ADF pipeline JSON files for nesting violations, resource limits, and configuration issues
argument-hint: "[path-to-pipeline-folder]"
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
---

# ADF Pipeline Validation

Validate Azure Data Factory pipeline JSON files against the complete set of ADF rules and limitations.

## Task

Run comprehensive validation on the specified ADF pipeline folder (or detect automatically) checking for:

1. **Activity Nesting Violations:**
   - ForEach → ForEach, Until, Validation (PROHIBITED)
   - Until → Until, ForEach, Validation (PROHIBITED)
   - IfCondition → ForEach, If, Switch, Until, Validation (PROHIBITED)
   - Switch → ForEach, If, Switch, Until, Validation (PROHIBITED)

2. **Resource Limits:**
   - Activities per pipeline (max 80/120)
   - Parameters per pipeline (max 50)
   - Variables per pipeline (max 50)
   - ForEach batchCount (max 50)

3. **Variable Scope Violations:**
   - SetVariable in parallel ForEach (causes race conditions)

4. **Linked Service Issues:**
   - Missing accountKind for Managed Identity Blob Storage
   - Missing required properties for authentication types

5. **Dataset Issues:**
   - Missing fileName/wildcardFileName for file datasets
   - Missing required location properties

## Arguments

- `$ARGUMENTS`: Optional path to pipeline folder. If not provided, will auto-detect common ADF folder structures (pipeline/, pipelines/, adf/)

## Execution

1. Detect or use specified pipeline folder path
2. Find all pipeline JSON files
3. Parse each pipeline and check for violations
4. Report all errors and warnings with specific line references
5. Suggest fixes for each violation
6. Return exit code (0 = pass, 1 = fail)

## Output Format

```
=== ADF Pipeline Validation ===

Scanning: [path]
Found: X pipeline files

[PIPELINE: PL_Example]
  ✓ Activity count: 15/80
  ✓ Parameter count: 5/50
  ✗ ERROR: ForEach 'OuterLoop' contains prohibited ForEach 'InnerLoop'
    → Fix: Use Execute Pipeline pattern to call child pipeline with inner ForEach
  ⚠ WARNING: ForEach 'ProcessItems' has batchCount=40 (recommend ≤30)

[PIPELINE: PL_DataLoad]
  ✓ All validations passed

=== Summary ===
Pipelines scanned: 2
Errors: 1
Warnings: 1
Status: FAILED
```

## Integration

For CI/CD integration, recommend running the PowerShell validation script at:
`${CLAUDE_PLUGIN_ROOT}/scripts/validate-adf-pipelines.ps1`

```yaml
# GitHub Actions
- name: Validate ADF
  run: pwsh -File validate-adf-pipelines.ps1 -PipelinePath pipeline

# Azure DevOps
- task: PowerShell@2
  inputs:
    filePath: 'validate-adf-pipelines.ps1'
    arguments: '-PipelinePath pipeline'
    pwsh: true
```
