---
name: adf-validation-rules
description: |
  ADF activity nesting rules, limits, and validation gotchas.
  PROACTIVELY activate for: (1) ADF activity nesting rules (ForEach inside If, Switch, Until), (2) ForEach limitations (no nested ForEach, item limits), (3) pipeline validation errors and ARM-template build failures, (4) linked service authentication issues, (5) Set Variable restrictions in ForEach, (6) Data Flow constraints (transformation limits, source/sink rules), (7) parameter and variable scope, (8) max activities per pipeline, (9) pipeline concurrency limits.
  Provides: nesting rule matrix, activity limit reference, validation error catalog, and refactoring patterns for unsupported nesting.
---

# Azure Data Factory Validation Rules and Limitations

## 🚨 CRITICAL: Activity Nesting Limitations

Azure Data Factory has **STRICT** nesting rules for control flow activities. Violating these rules will cause pipeline failures or prevent pipeline creation.

### Supported Control Flow Activities for Nesting

Four control flow activities support nested activities:
- **ForEach**: Iterates over collections and executes activities in a loop
- **If Condition**: Branches based on true/false evaluation
- **Until**: Implements do-until loops with timeout options
- **Switch**: Evaluates activities matching case conditions

### ✅ PERMITTED Nesting Combinations

| Parent Activity | Can Contain | Notes |
|----------------|-------------|-------|
| **ForEach** | If Condition | ✅ Allowed |
| **ForEach** | Switch | ✅ Allowed |
| **Until** | If Condition | ✅ Allowed |
| **Until** | Switch | ✅ Allowed |

### ❌ PROHIBITED Nesting Combinations

| Parent Activity | CANNOT Contain | Reason |
|----------------|----------------|---------|
| **If Condition** | ForEach | ❌ Not supported - use Execute Pipeline workaround |
| **If Condition** | Switch | ❌ Not supported - use Execute Pipeline workaround |
| **If Condition** | Until | ❌ Not supported - use Execute Pipeline workaround |
| **If Condition** | Another If | ❌ Cannot nest If within If |
| **Switch** | ForEach | ❌ Not supported - use Execute Pipeline workaround |
| **Switch** | If Condition | ❌ Not supported - use Execute Pipeline workaround |
| **Switch** | Until | ❌ Not supported - use Execute Pipeline workaround |
| **Switch** | Another Switch | ❌ Cannot nest Switch within Switch |
| **ForEach** | Another ForEach | ❌ Single level only - use Execute Pipeline workaround |
| **Until** | Another Until | ❌ Single level only - use Execute Pipeline workaround |
| **ForEach** | Until | ❌ Single level only - use Execute Pipeline workaround |
| **Until** | ForEach | ❌ Single level only - use Execute Pipeline workaround |

### 🚫 Special Activity Restrictions

**Validation Activity**:
- ❌ **CANNOT** be placed inside ANY nested activity
- ❌ **CANNOT** be used within ForEach, If, Switch, or Until activities
- ✅ Must be at pipeline root level only

### 🔧 Workaround: Execute Pipeline Pattern

**The ONLY supported workaround for prohibited nesting combinations:**

Instead of direct nesting, use the **Execute Pipeline Activity** to call a child pipeline:

```json
{
  "name": "ParentPipeline_WithIfCondition",
  "activities": [
    {
      "name": "IfCondition_Parent",
      "type": "IfCondition",
      "typeProperties": {
        "expression": "@equals(pipeline().parameters.ProcessData, 'true')",
        "ifTrueActivities": [
          {
            "name": "ExecuteChildPipeline_WithForEach",
            "type": "ExecutePipeline",
            "typeProperties": {
              "pipeline": {
                "referenceName": "ChildPipeline_ForEachLoop",
                "type": "PipelineReference"
              },
              "parameters": {
                "ItemList": "@pipeline().parameters.Items"
              }
            }
          }
        ]
      }
    }
  ]
}
```

**Child Pipeline Structure:**
```json
{
  "name": "ChildPipeline_ForEachLoop",
  "parameters": {
    "ItemList": {"type": "array"}
  },
  "activities": [
    {
      "name": "ForEach_InChildPipeline",
      "type": "ForEach",
      "typeProperties": {
        "items": "@pipeline().parameters.ItemList",
        "activities": [
          // Your ForEach logic here
        ]
      }
    }
  ]
}
```

**Why This Works:**
- Each pipeline can have ONE level of nesting
- Execute Pipeline creates a new pipeline context
- Child pipeline gets its own nesting level allowance
- Enables unlimited depth through pipeline chaining

## 🔢 Activity and Resource Limits

### Pipeline Limits
| Resource | Limit | Notes |
|----------|-------|-------|
| **Activities per pipeline** | 80 | Includes inner activities for containers |
| **Parameters per pipeline** | 50 | - |
| **ForEach concurrent iterations** | 50 (maximum) | Set via `batchCount` property |
| **ForEach items** | 100,000 | - |
| **Lookup activity rows** | 5,000 | Maximum rows returned |
| **Lookup activity size** | 4 MB | Maximum size of returned data |
| **Web activity timeout** | 1 hour | Default timeout for Web activities |
| **Copy activity timeout** | 7 days | Maximum execution time |

### ForEach Activity Configuration
```json
{
  "name": "ForEachActivity",
  "type": "ForEach",
  "typeProperties": {
    "items": "@pipeline().parameters.ItemList",
    "isSequential": false,  // false = parallel execution
    "batchCount": 50,       // Max 50 concurrent iterations
    "activities": [
      // Nested activities
    ]
  }
}
```

**Critical Considerations:**
- `isSequential: true` → Executes one item at a time (slow but predictable)
- `isSequential: false` → Executes up to `batchCount` items in parallel
- Maximum `batchCount` is **50** regardless of setting
- **Cannot use Set Variable activity** inside parallel ForEach (variable scope is pipeline-level)

### Set Variable Activity Limitations
❌ **CANNOT** use `Set Variable` inside ForEach with `isSequential: false`
- Reason: Variables are pipeline-scoped, not ForEach-scoped
- Multiple parallel iterations would cause race conditions
- ✅ **Alternative**: Use `Append Variable` with array type, or use sequential execution

## 📊 Linked Services Validation (Azure Blob, Azure SQL)

Detailed validation rules and templates for ADF Linked Services (Azure Blob Storage and Azure SQL Database) — auth types (key, SAS, managed identity, AAD), network configuration, and connection-string patterns — live in `references/linked-services.md`. Load that reference when authoring or validating a Linked Service JSON.

## 🔍 Data Flow Limitations

### General Limits
- **Column name length**: 128 characters maximum
- **Row size**: 1 MB maximum (some sinks like SQL have lower limits)
- **String column size**: Varies by sink (SQL: 8000 for varchar, 4000 for nvarchar)

### Transformation-Specific Limits
| Transformation | Limitation |
|----------------|------------|
| **Lookup** | Cache size limited by cluster memory |
| **Join** | Large joins may cause memory errors |
| **Pivot** | Maximum 10,000 unique values |
| **Window** | Requires partitioning for large datasets |

### Performance Considerations
- **Partitioning**: Always partition large datasets before transformations
- **Broadcast**: Use broadcast hint for small dimension tables
- **Sink optimization**: Enable table option "Recreate" instead of "Truncate" for better performance

## 🛡️ Validation Checklist for Pipeline Creation

### Before Creating Pipeline
- [ ] Verify activity nesting follows permitted combinations
- [ ] Check ForEach activities don't contain other ForEach/Until
- [ ] Verify If/Switch activities don't contain ForEach/Until/If/Switch
- [ ] Ensure Validation activities are at pipeline root level only
- [ ] Confirm total activities < 80 per pipeline
- [ ] Verify no Set Variable activities in parallel ForEach

### Linked Service Validation
- [ ] **Blob Storage**: If using managed identity/service principal, `accountKind` is set
- [ ] **SQL Database**: Authentication method matches security requirements
- [ ] **All services**: Secrets stored in Key Vault, not hardcoded
- [ ] **All services**: Firewall rules configured for integration runtime IPs
- [ ] **Network**: Private endpoints configured if using VNet integration

### Activity Configuration Validation
- [ ] **ForEach**: `batchCount` ≤ 50 if parallel execution
- [ ] **Lookup**: Query returns < 5000 rows and < 4 MB data
- [ ] **Copy**: DIU configured appropriately (2-256 for Azure IR)
- [ ] **Copy**: Staging enabled for large data movements
- [ ] **All activities**: Timeout values appropriate for expected execution time
- [ ] **All activities**: Retry logic configured for transient failures

### Data Flow Validation
- [ ] Column names ≤ 128 characters
- [ ] Source query doesn't return > 1 MB per row
- [ ] Partitioning configured for large datasets
- [ ] Sink has appropriate schema and data type mappings
- [ ] Staging linked service configured for optimal performance

## 🔍 Automated Validation Script

**CRITICAL: Always run automated validation before committing or deploying ADF pipelines!**

The adf-master plugin includes a comprehensive PowerShell validation script that checks for ALL the rules and limitations documented above.

### Using the Validation Script

**Location:** `${CLAUDE_PLUGIN_ROOT}/scripts/validate-adf-pipelines.ps1`

**Basic usage:**
```powershell
# From the root of your ADF repository
pwsh -File validate-adf-pipelines.ps1
```

**With custom paths:**
```powershell
pwsh -File validate-adf-pipelines.ps1 `
    -PipelinePath "path/to/pipeline" `
    -DatasetPath "path/to/dataset"
```

**With strict mode (additional warnings):**
```powershell
pwsh -File validate-adf-pipelines.ps1 -Strict
```

### What the Script Validates

The automated validation script checks for issues that Microsoft's official `@microsoft/azure-data-factory-utilities` package does **NOT** validate:

1. **Activity Nesting Violations:**
   - ForEach → ForEach, Until, Validation
   - Until → Until, ForEach, Validation
   - IfCondition → ForEach, If, IfCondition, Switch, Until, Validation
   - Switch → ForEach, If, IfCondition, Switch, Until, Validation

2. **Resource Limits:**
   - Pipeline activity count (max 120, warn at 100)
   - Pipeline parameter count (max 50)
   - Pipeline variable count (max 50)
   - ForEach batchCount limit (max 50, warn at 30 in strict mode)

3. **Variable Scope Violations:**
   - SetVariable in parallel ForEach (causes race conditions)
   - Proper AppendVariable vs SetVariable usage

4. **Dataset Configuration Issues:**
   - Missing fileName or wildcardFileName for file-based datasets
   - AzureBlobFSLocation missing required fileSystem property
   - Missing required properties for DelimitedText, Json, Parquet types

5. **Copy Activity Validations:**
   - Source/sink type compatibility with dataset types
   - Lookup activity firstRowOnly=false warnings (5000 row/4MB limits)
   - Blob file dependencies (additionalColumns logging pattern)

### Integration with CI/CD

**GitHub Actions example:**
```yaml
- name: Validate ADF Pipelines
  run: |
    pwsh -File validate-adf-pipelines.ps1 -PipelinePath pipeline -DatasetPath dataset
  shell: pwsh
```

**Azure DevOps example:**
```yaml
- task: PowerShell@2
  displayName: 'Validate ADF Pipelines'
  inputs:
    filePath: 'validate-adf-pipelines.ps1'
    arguments: '-PipelinePath pipeline -DatasetPath dataset'
    pwsh: true
```

### Command Reference

Use the `/adf-validate` command to run the validation script with proper guidance:

```bash
/adf-validate
```

This command will:
1. Detect your ADF repository structure
2. Run the validation script with appropriate paths
3. Parse and explain any errors or warnings found
4. Provide specific solutions for each violation
5. Recommend next actions based on results
6. Suggest CI/CD integration patterns

### Exit Codes

- **0**: Validation passed (no errors)
- **1**: Validation failed (errors found - DO NOT DEPLOY)

### Best Practices

1. **Run validation before every commit** to catch issues early
2. **Add validation to CI/CD pipeline** to prevent invalid deployments
3. **Use strict mode during development** for additional warnings
4. **Re-validate after bulk changes** or generated pipelines
5. **Document validation exceptions** if you must bypass a warning
6. **Share validation results with team** to prevent repeated mistakes

## 🚨 CRITICAL: Enforcement Protocol

**When creating or modifying ADF pipelines:**

1. **ALWAYS validate activity nesting** against the permitted/prohibited table
2. **REJECT** any attempt to create prohibited nesting combinations
3. **SUGGEST** Execute Pipeline workaround for complex nesting needs
4. **VALIDATE** linked service authentication matches the connector type
5. **CHECK** all limits (activities, parameters, ForEach iterations, etc.)
6. **VERIFY** required properties are set (e.g., `accountKind` for managed identity)
7. **WARN** about common pitfalls specific to the connector being used

**Example Validation Response:**
```yaml
❌ INVALID PIPELINE STRUCTURE DETECTED:

Issue: ForEach activity contains another ForEach activity
Location: Pipeline "PL_DataProcessing" → ForEach "OuterLoop" → ForEach "InnerLoop"

This violates Azure Data Factory nesting rules:
- ForEach activities support only a SINGLE level of nesting
- You CANNOT nest ForEach within ForEach

✅ RECOMMENDED SOLUTION:
Use the Execute Pipeline pattern:
1. Create a child pipeline with the inner ForEach logic
2. Replace the inner ForEach with an Execute Pipeline activity
3. Pass required parameters to the child pipeline

Would you like me to generate the refactored pipeline structure?
```

## 📚 Reference Documentation

**Official Microsoft Learn Resources:**
- Activity nesting: https://learn.microsoft.com/en-us/azure/data-factory/concepts-nested-activities
- Blob Storage connector: https://learn.microsoft.com/en-us/azure/data-factory/connector-azure-blob-storage
- SQL Database connector: https://learn.microsoft.com/en-us/azure/data-factory/connector-azure-sql-database
- Pipeline limits: https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/azure-subscription-service-limits#data-factory-limits

**Last Updated:** 2025-01-24 (Based on official Microsoft documentation)

This validation rules skill MUST be consulted before creating or modifying ANY Azure Data Factory pipeline to ensure compliance with platform limitations and best practices.

## Progressive Disclosure References

For detailed validation matrices and resource limits, see:

- **Nesting Rules**: `references/nesting-rules.md` - Complete matrix of permitted and prohibited activity nesting combinations with workaround patterns
- **Resource Limits**: `references/resource-limits.md` - Complete reference for all ADF limits (pipeline, activity, trigger, data flow, integration runtime, expression, API)
