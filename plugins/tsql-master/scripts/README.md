# T-SQL Master Utility Scripts

SQL Server diagnostic and analysis scripts for performance optimization.

## Scripts

### check-sargability.sql

Identifies queries with potential SARGability issues by analyzing Query Store data.

**Detects:**
- Date functions in WHERE clauses (YEAR, MONTH, DATEPART)
- String functions on columns (LEFT, RIGHT, UPPER, LOWER)
- ISNULL/COALESCE patterns that prevent index seeks
- Implicit conversions in execution plans

**Requirements:**
- Query Store must be enabled
- SQL Server 2016+ or Azure SQL Database

**Usage:**
```sql
-- Run in target database
:r check-sargability.sql
```

### index-analysis.sql

Comprehensive index health check covering multiple optimization areas.

**Analyzes:**
1. Missing indexes with impact scores
2. Unused indexes (removal candidates)
3. Duplicate/overlapping indexes
4. Index fragmentation levels
5. Index usage statistics
6. Heap tables (no clustered index)
7. Outdated statistics

**Requirements:**
- SQL Server 2016+ or Azure SQL Database
- db_datareader role minimum

**Usage:**
```sql
-- Run in target database
:r index-analysis.sql
```

## Best Practices

### Before Running

1. **Test in non-production first** - These scripts read from system DMVs
2. **Schedule during low activity** - Some queries may cause brief CPU spikes
3. **Review recommendations carefully** - Automated suggestions need context

### Interpreting Results

**Missing Indexes:**
- Impact score > 10,000 = High priority
- Consider query frequency and importance
- Don't create all suggested indexes blindly

**Unused Indexes:**
- Check if SQL Server was recently restarted
- Consider seasonal or periodic workloads
- Keep unique constraints even if low usage

**Fragmentation:**
- < 10%: No action needed
- 10-30%: REORGANIZE (online)
- > 30%: REBUILD (may need offline window)

### After Analysis

1. Create indexes one at a time
2. Monitor for 24-48 hours before next change
3. Update statistics after index changes
4. Re-run analysis after major workload changes
