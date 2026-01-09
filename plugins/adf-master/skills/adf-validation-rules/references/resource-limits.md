# ADF Resource Limits - Complete Reference

## Pipeline Limits

| Resource | Limit | Notes |
|----------|-------|-------|
| Activities per pipeline | 80 (standard) / 120 (with Execute Pipeline) | Cannot exceed regardless of nesting |
| Parameters per pipeline | 50 | Includes inherited parameters |
| Variables per pipeline | 50 | Array variables count as 1 |
| Pipeline name length | 260 characters | |
| Nested Execute Pipeline depth | 10 levels | Beyond 5 impacts debugging |
| Pipeline JSON size | 4 MB | Compressed pipeline definition |

---

## Activity Limits

| Activity | Resource | Limit |
|----------|----------|-------|
| ForEach | batchCount | 1-50 |
| ForEach | items | 100,000 max |
| Lookup | rows returned | 5,000 |
| Lookup | response size | 4 MB |
| Copy | parallel copies | Auto (default) or 1-256 |
| Copy | DIU (Data Integration Units) | 2-256 |
| Web Activity | response size | 4 MB |
| Web Activity | timeout | 7 days max |
| Execute Pipeline | concurrent runs | 20 (default) |
| Until | timeout | 7 days max |
| Until | iterations | Not explicitly limited, but timeout applies |

---

## Data Factory Resource Limits

| Resource | Free Tier | Standard | Premium |
|----------|-----------|----------|---------|
| Pipelines | 50 | 5,000 | 10,000 |
| Datasets | 200 | 5,000 | 10,000 |
| Linked Services | 50 | 5,000 | 5,000 |
| Integration Runtimes | 5 | 5,000 | 5,000 |
| Triggers | 50 | 5,000 | 10,000 |
| Data Flows | N/A | 200 | 1,000 |
| Total objects | 500 | 15,000 | 30,000 |

---

## Trigger Limits

| Trigger Type | Resource | Limit |
|--------------|----------|-------|
| Schedule | executions per minute | 5 |
| Tumbling Window | maxConcurrency | 1-50 |
| Tumbling Window | max historical windows | 366 (daily) |
| Event Trigger | subject length | 1024 characters |
| All triggers | pipelines per trigger | 10 |

---

## Copy Activity Performance Limits

| Source Type | Max Throughput | DIU Recommendation |
|-------------|----------------|-------------------|
| Azure Blob | 10+ Gbps | Auto or 64-256 |
| ADLS Gen2 | 10+ Gbps | Auto or 64-256 |
| Azure SQL | 1.2 Gbps | 16-64 |
| Synapse | 2+ Gbps | Auto or 32-128 |
| SQL Server (SHIR) | 500 Mbps | N/A (SHIR limited) |
| SFTP (SHIR) | 50-100 Mbps | N/A |

---

## Data Flow Limits

| Resource | Limit |
|----------|-------|
| Transformations per flow | 100 |
| Sources per flow | 50 |
| Sinks per flow | 50 |
| Columns per transformation | 2,000 |
| Expression depth | 10 nested functions |
| Row size | 4 MB |
| Debug session timeout | 8 hours |
| Cluster startup time | 2-5 minutes (warm) / 5-7 minutes (cold) |

---

## Integration Runtime Limits

### Azure IR
| Resource | Limit |
|----------|-------|
| DIU per copy | 2-256 |
| Parallel copies | Up to 256 |
| Data Flow cores | 8-256 |
| Regions | All Azure regions |

### Self-Hosted IR
| Resource | Limit |
|----------|-------|
| Nodes per IR | 4 |
| Concurrent jobs per node | 4-50 |
| Concurrent pipeline runs | Limited by node capacity |
| Memory per node | 8 GB minimum recommended |
| Network throughput | Varies by node specs |

### Azure-SSIS IR
| Resource | Limit |
|----------|-------|
| Node count | 1-10 |
| Node size | Standard_D2_v3 to Standard_E64i_v3 |
| SSIS package count | No explicit limit |

---

## Expression Limits

| Expression | Limit |
|------------|-------|
| String length | 4,000 characters |
| Expression depth | 10 nested functions |
| concat parameters | 250 |
| Dynamic content size | 256 KB |

---

## API and ARM Limits

| Resource | Limit |
|----------|-------|
| API calls per hour | 10,000 |
| ARM deployment size | 4 MB |
| ARM template resources | 800 |
| Batch size (create/update) | 100 objects |

---

## Common Limit Errors

### Error: "The pipeline contains X activities, which exceeds the maximum of 80"
**Solution:** Refactor into child pipelines using Execute Pipeline

### Error: "The ForEach activity items exceed the maximum of 100000"
**Solution:** Chunk the input array or use multiple ForEach with Skip/Take

### Error: "Lookup activity returned X rows, which exceeds the maximum of 5000"
**Solution:** Add WHERE clause or use Copy Activity with staging

### Error: "The response size (X bytes) exceeds the maximum of 4194304"
**Solution:** For Web Activity, paginate responses; for Lookup, limit columns/rows

---

## Performance Recommendations

### High-Volume Scenarios
```
| Scenario | Recommendation |
|----------|----------------|
| 1M+ rows | Use Staging with PolyBase |
| Large files (>1GB) | Increase DIU to 64-128 |
| Many small files | Use wildcards, avoid per-file ForEach |
| Cross-region | Deploy IR in target region |
| Real-time | Consider Event Trigger, not polling |
```

### Optimization Checklist
1. Set appropriate DIU (Auto works well for most)
2. Enable staging for Synapse/SQL DW destinations
3. Use partitioned copy for large tables
4. Avoid Lookup for >5000 rows - use Copy to staging
5. Minimize Web Activity response size
6. Use parallel ForEach (isSequential: false)
7. Set realistic timeouts to fail fast

---

## Quota Increase Requests

For limits that can be increased, contact Azure Support:
- Pipeline count
- Dataset count
- Concurrent pipeline runs
- Integration Runtime capacity
- API throttling limits

Standard process:
1. Azure Portal → Support + Troubleshooting
2. Select "Service and subscription limits (quotas)"
3. Choose Data Factory quota type
4. Specify required increase with justification
