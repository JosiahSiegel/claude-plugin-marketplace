# ADF Activity Nesting Rules - Complete Reference

## Container Activity Nesting Matrix

This matrix shows which activities can be nested inside container activities.

| Inner Activity | ForEach | If Condition | Switch | Until |
|---------------|---------|--------------|--------|-------|
| Copy | Yes | Yes | Yes | Yes |
| Lookup | Yes | Yes | Yes | Yes |
| GetMetadata | Yes | Yes | Yes | Yes |
| WebActivity | Yes | Yes | Yes | Yes |
| SetVariable | Yes* | Yes | Yes | Yes |
| AppendVariable | Yes | Yes | Yes | Yes |
| Wait | Yes | Yes | Yes | Yes |
| Fail | Yes | Yes | Yes | Yes |
| ExecutePipeline | Yes | Yes | Yes | Yes |
| DatabricksJob | Yes | Yes | Yes | Yes |
| **ForEach** | **NO** | **NO** | **NO** | **NO** |
| **IfCondition** | **NO** | **NO** | **NO** | **NO** |
| **Switch** | **NO** | **NO** | **NO** | **NO** |
| **Until** | **NO** | **NO** | **NO** | **NO** |
| **Validation** | **NO** | **NO** | **NO** | **NO** |

*SetVariable cannot run in parallel ForEach - use sequential mode or AppendVariable

---

## Prohibited Nesting Combinations

### NEVER Allowed Inside ForEach
```
ForEach → ForEach      ❌ PROHIBITED
ForEach → IfCondition  ❌ PROHIBITED
ForEach → Switch       ❌ PROHIBITED
ForEach → Until        ❌ PROHIBITED
ForEach → Validation   ❌ PROHIBITED
```

### NEVER Allowed Inside IfCondition
```
IfCondition → ForEach      ❌ PROHIBITED
IfCondition → IfCondition  ❌ PROHIBITED
IfCondition → Switch       ❌ PROHIBITED
IfCondition → Until        ❌ PROHIBITED
IfCondition → Validation   ❌ PROHIBITED
```

### NEVER Allowed Inside Switch
```
Switch → ForEach      ❌ PROHIBITED
Switch → IfCondition  ❌ PROHIBITED
Switch → Switch       ❌ PROHIBITED
Switch → Until        ❌ PROHIBITED
Switch → Validation   ❌ PROHIBITED
```

### NEVER Allowed Inside Until
```
Until → ForEach      ❌ PROHIBITED
Until → IfCondition  ❌ PROHIBITED
Until → Switch       ❌ PROHIBITED
Until → Until        ❌ PROHIBITED
Until → Validation   ❌ PROHIBITED
```

---

## Workaround Patterns

### Pattern 1: Execute Pipeline for Nested ForEach
Instead of nesting ForEach activities, use Execute Pipeline:

**WRONG (Will Fail):**
```json
{
  "name": "OuterForEach",
  "type": "ForEach",
  "typeProperties": {
    "items": "@pipeline().parameters.Categories",
    "activities": [
      {
        "name": "InnerForEach",
        "type": "ForEach",
        "typeProperties": {
          "items": "@item().products"
        }
      }
    ]
  }
}
```

**CORRECT:**
```json
{
  "name": "OuterForEach",
  "type": "ForEach",
  "typeProperties": {
    "items": { "value": "@pipeline().parameters.Categories", "type": "Expression" },
    "isSequential": false,
    "batchCount": 20,
    "activities": [
      {
        "name": "ExecuteInnerLoop",
        "type": "ExecutePipeline",
        "typeProperties": {
          "pipeline": {
            "referenceName": "PL_Inner_ForEach",
            "type": "PipelineReference"
          },
          "waitOnCompletion": true,
          "parameters": {
            "Products": { "value": "@item().products", "type": "Expression" }
          }
        }
      }
    ]
  }
}
```

### Pattern 2: Execute Pipeline for Conditional ForEach
When you need ForEach inside an If Condition:

**WRONG:**
```json
{
  "name": "CheckData",
  "type": "IfCondition",
  "typeProperties": {
    "expression": { "value": "@greater(length(activity('Lookup').output.value), 0)", "type": "Expression" },
    "ifTrueActivities": [
      {
        "name": "ProcessItems",
        "type": "ForEach"
      }
    ]
  }
}
```

**CORRECT:**
```json
{
  "name": "CheckData",
  "type": "IfCondition",
  "typeProperties": {
    "expression": { "value": "@greater(length(activity('Lookup').output.value), 0)", "type": "Expression" },
    "ifTrueActivities": [
      {
        "name": "ExecuteProcessing",
        "type": "ExecutePipeline",
        "typeProperties": {
          "pipeline": { "referenceName": "PL_Process_Items", "type": "PipelineReference" },
          "waitOnCompletion": true,
          "parameters": {
            "ItemList": { "value": "@activity('Lookup').output.value", "type": "Expression" }
          }
        }
      }
    ]
  }
}
```

### Pattern 3: Sequential ForEach with Conditional Logic
Move the condition inside the ForEach:

```json
{
  "name": "ProcessEach",
  "type": "ForEach",
  "typeProperties": {
    "items": { "value": "@pipeline().parameters.Items", "type": "Expression" },
    "isSequential": true,
    "activities": [
      {
        "name": "ExecuteConditionalPipeline",
        "type": "ExecutePipeline",
        "typeProperties": {
          "pipeline": { "referenceName": "PL_Conditional_Process", "type": "PipelineReference" },
          "parameters": {
            "Item": { "value": "@item()", "type": "Expression" }
          }
        }
      }
    ]
  }
}
```

---

## SetVariable in ForEach

### Issue
SetVariable cannot be used in parallel ForEach because of race conditions.

### Solutions

**Option 1: Sequential ForEach**
```json
{
  "name": "ForEachItem",
  "type": "ForEach",
  "typeProperties": {
    "items": "@pipeline().parameters.Items",
    "isSequential": true,
    "activities": [
      {
        "name": "UpdateCounter",
        "type": "SetVariable",
        "typeProperties": {
          "variableName": "Counter",
          "value": "@add(variables('Counter'), 1)"
        }
      }
    ]
  }
}
```

**Option 2: AppendVariable (Parallel Safe)**
```json
{
  "name": "ForEachItem",
  "type": "ForEach",
  "typeProperties": {
    "items": "@pipeline().parameters.Items",
    "isSequential": false,
    "batchCount": 20,
    "activities": [
      {
        "name": "AddResult",
        "type": "AppendVariable",
        "typeProperties": {
          "variableName": "Results",
          "value": "@item().id"
        }
      }
    ]
  }
}
```

---

## Validation Rules Summary

### Error: "Activity X is not allowed inside Y"

| Error Pattern | Solution |
|--------------|----------|
| ForEach inside ForEach | Use Execute Pipeline |
| ForEach inside If/Switch/Until | Use Execute Pipeline |
| If inside ForEach | Use Execute Pipeline |
| Switch inside any container | Use Execute Pipeline |
| Until inside any container | Use Execute Pipeline |
| SetVariable in parallel ForEach | Use sequential mode or AppendVariable |

### Maximum Nesting Depth

While not explicitly limited, deep nesting via Execute Pipeline has practical limits:
- Each nested pipeline counts toward concurrent run limits
- Debugging becomes difficult beyond 2-3 levels
- Consider flattening logic or using Data Flows for complex transformations

---

## Quick Reference Card

```
ALLOWED:
├── ForEach
│   ├── Copy           ✓
│   ├── Lookup         ✓
│   ├── GetMetadata    ✓
│   ├── WebActivity    ✓
│   ├── SetVariable    ✓ (sequential only)
│   ├── AppendVariable ✓
│   ├── Wait           ✓
│   ├── Fail           ✓
│   ├── ExecutePipeline ✓
│   └── DatabricksJob  ✓

PROHIBITED:
├── ForEach
│   ├── ForEach        ❌
│   ├── IfCondition    ❌
│   ├── Switch         ❌
│   ├── Until          ❌
│   └── Validation     ❌
```

**WORKAROUND:** Always use ExecutePipeline to wrap container activities when nesting is required.
