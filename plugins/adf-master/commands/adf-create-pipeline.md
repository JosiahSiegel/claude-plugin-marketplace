---
name: adf-create-pipeline
description: Generate ADF pipeline JSON with proper structure, activities, and best practices
argument-hint: "<pipeline-name> <description-of-requirements>"
allowed-tools:
  - Read
  - Write
  - Glob
  - WebSearch
---

# ADF Pipeline Generator

Generate Azure Data Factory pipeline JSON files following best practices and avoiding common pitfalls.

## Task

Create a complete, valid ADF pipeline JSON based on the provided requirements.

## Arguments

- `$ARGUMENTS`: Pipeline name followed by requirements description
  - Example: `PL_SalesETL Copy sales data from Azure SQL to Parquet in ADLS, partitioned by date`
  - Example: `PL_DailyLoad Load multiple tables using ForEach with config lookup`
  - Example: `PL_APIIngestion Fetch data from REST API with pagination and error handling`

## Pipeline Generation Rules

### Required Structure
```json
{
  "name": "<PipelineName>",
  "properties": {
    "activities": [],
    "parameters": {},
    "variables": {},
    "annotations": [],
    "folder": { "name": "<FolderName>" }
  }
}
```

### Naming Conventions
- Pipelines: `PL_<Domain>_<Action>` (e.g., `PL_Sales_DailyLoad`)
- Activities: `<Type>_<Purpose>` (e.g., `Copy_SalesToParquet`, `ForEach_Tables`)
- Variables: `var<Name>` (e.g., `varCounter`, `varResults`)
- Parameters: `<Name>` (e.g., `ProcessDate`, `TableList`)

### Activity Nesting Rules
NEVER create prohibited combinations:
- ForEach cannot contain: ForEach, Until, Validation
- IfCondition cannot contain: ForEach, If, Switch, Until, Validation
- Switch cannot contain: ForEach, If, Switch, Until, Validation
- Until cannot contain: Until, ForEach, Validation

If nested control flow is required, use Execute Pipeline pattern.

### Best Practices to Apply
1. **Always include retry policy** for Copy, Web, and external activities
2. **Use parameters** for environment-specific values (servers, databases, paths)
3. **Add dependsOn** with explicit dependency conditions
4. **Include timeout** values appropriate for the operation
5. **Use Key Vault references** for secrets (never hardcode)
6. **Add annotations** for documentation and tagging
7. **Set secureInput/secureOutput** when handling sensitive data

### Common Patterns

**Copy with Lookup Config:**
```json
{
  "activities": [
    {
      "name": "Lookup_GetTables",
      "type": "Lookup",
      "typeProperties": {
        "source": { "type": "AzureSqlSource", "sqlReaderQuery": "SELECT * FROM Config.Tables" },
        "dataset": { "referenceName": "DS_Config", "type": "DatasetReference" },
        "firstRowOnly": false
      }
    },
    {
      "name": "ForEach_Tables",
      "type": "ForEach",
      "dependsOn": [{ "activity": "Lookup_GetTables", "dependencyConditions": ["Succeeded"] }],
      "typeProperties": {
        "items": { "value": "@activity('Lookup_GetTables').output.value", "type": "Expression" },
        "isSequential": false,
        "batchCount": 20,
        "activities": [...]
      }
    }
  ]
}
```

**Error Handling with Fail:**
```json
{
  "name": "Fail_OnError",
  "type": "Fail",
  "dependsOn": [{ "activity": "Copy_Data", "dependencyConditions": ["Failed"] }],
  "typeProperties": {
    "message": "Copy activity failed: @{activity('Copy_Data').error.message}",
    "errorCode": "COPY_FAILED"
  }
}
```

## Output

1. Generate complete, valid pipeline JSON
2. Include inline comments explaining key decisions
3. List any required linked services and datasets
4. Provide parameterization recommendations
5. Note any limitations or considerations

## Validation

After generating, mentally validate against:
- Activity nesting rules
- Resource limits (80 activities, 50 parameters, 50 variables)
- No SetVariable in parallel ForEach
- Proper dependsOn chains
