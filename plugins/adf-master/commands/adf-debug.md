---
name: adf-debug
description: Debug ADF pipeline failures, analyze error messages, and suggest fixes
argument-hint: "<error-message-or-pipeline-name>"
allowed-tools:
  - Read
  - Glob
  - Grep
  - WebSearch
  - WebFetch
---

# ADF Pipeline Debugger

Analyze Azure Data Factory pipeline errors and provide targeted solutions.

## Task

Debug the provided ADF error or pipeline issue and provide specific remediation steps.

## Arguments

- `$ARGUMENTS`: Either:
  - An error message or error code from ADF
  - A pipeline name to analyze for potential issues
  - A description of the failure behavior

## Common Error Patterns and Solutions

### Activity Errors

**ErrorCode: UserErrorActivityRunFailed**
- Check activity-specific error in `error.message`
- Common causes: connection timeout, invalid query, permission denied
- Solution: Validate linked service connectivity, check firewall rules

**ErrorCode: UserErrorFailedToReadSourceData**
- Source data unavailable or inaccessible
- Check: file exists, permissions granted, network accessible
- For Blob: verify container/path, SAS token not expired

**ErrorCode: UserErrorFailedToWriteSinkData**
- Cannot write to destination
- Check: sink permissions, disk space, schema compatibility
- For SQL: verify table exists, columns match, constraints satisfied

### Copy Activity Errors

**ErrorCode: SqlServerCannotConnect**
```
Solutions:
1. Verify server name and database name
2. Check firewall allows Azure services or specific IPs
3. Verify credentials (SQL auth) or role assignments (MI/SP)
4. For serverless: implement retry for auto-pause wake-up
```

**ErrorCode: CosmosDbPartitionKeyRangeTooLarge**
```
Solutions:
1. Increase Data Integration Units (DIUs)
2. Add WHERE clause to limit data per copy
3. Partition the copy by date or other key
```

### Data Flow Errors

**ErrorCode: DF-EXECUTOR-InvalidDataType**
```
Solutions:
1. Check source column types vs expected types
2. Add explicit cast/convert in transformation
3. Verify date format matches expected pattern
```

**ErrorCode: DF-EXECUTOR-OutOfMemory**
```
Solutions:
1. Increase cluster size (Core Count)
2. Add partitioning before memory-intensive operations
3. Use broadcast join for small dimension tables
4. Optimize transformations to reduce intermediate data
```

### Linked Service Errors

**ErrorCode: InvalidParameter**
```
For Blob Storage with Managed Identity:
- CRITICAL: Add "accountKind": "StorageV2" to typeProperties
- Verify MI has Storage Blob Data Reader/Contributor role

For SQL with Managed Identity:
- Create contained user: CREATE USER [<adf-name>] FROM EXTERNAL PROVIDER
- Grant roles: ALTER ROLE db_datareader ADD MEMBER [<adf-name>]
```

### Trigger Errors

**ErrorCode: TriggerFailedToStart**
```
Solutions:
1. Verify pipeline exists and is published
2. Check trigger parameters match pipeline parameters
3. For event triggers: verify Event Grid subscription active
4. For tumbling window: check dependencies are running
```

## Debugging Process

1. **Identify Error Location**
   - Which activity failed?
   - What was the error code and message?
   - What were the input values?

2. **Check Common Causes**
   - Connectivity (firewall, network, endpoints)
   - Authentication (expired credentials, missing permissions)
   - Data (schema mismatch, null values, size limits)
   - Configuration (missing properties, invalid expressions)

3. **Review Activity Configuration**
   - Read pipeline JSON for the failing activity
   - Validate all required properties are set
   - Check expression syntax

4. **Test Connectivity**
   - Use Test Connection in linked service
   - Verify private endpoints if using VNet
   - Check DNS resolution

5. **Analyze Monitoring Data**
   - Check Activity Runs in Monitor hub
   - Review detailed error message
   - Check input/output for activities

## Kusto Queries for Analysis

```kusto
// Find all failures in last 24 hours
ADFActivityRun
| where Status == "Failed"
| where TimeGenerated > ago(24h)
| project TimeGenerated, PipelineName, ActivityName, ErrorCode, ErrorMessage
| order by TimeGenerated desc

// Find long-running activities
ADFActivityRun
| where TimeGenerated > ago(7d)
| extend DurationMinutes = datetime_diff('minute', End, Start)
| where DurationMinutes > 30
| summarize AvgDuration=avg(DurationMinutes), Count=count() by PipelineName, ActivityName
| order by AvgDuration desc
```

## Output Format

```
=== ADF Debug Analysis ===

Error: [ErrorCode] - [Short Description]
Pipeline: [PipelineName]
Activity: [ActivityName]

Root Cause:
[Detailed explanation of what caused the error]

Solution Steps:
1. [First step to fix]
2. [Second step to fix]
3. [Verification step]

Prevention:
[How to prevent this in future]

Related Documentation:
- [Link to relevant Microsoft docs]
```
