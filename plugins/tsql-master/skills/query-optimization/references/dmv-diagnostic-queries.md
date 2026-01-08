# DMV Diagnostic Queries

Essential Dynamic Management View queries for SQL Server performance troubleshooting.

## Wait Statistics

### Current Wait Statistics
```sql
-- Top waits since server restart
SELECT TOP 20
    wait_type,
    wait_time_ms / 1000.0 AS wait_time_sec,
    signal_wait_time_ms / 1000.0 AS signal_wait_sec,
    waiting_tasks_count,
    wait_time_ms * 100.0 / SUM(wait_time_ms) OVER() AS pct
FROM sys.dm_os_wait_stats
WHERE wait_type NOT IN (
    'CLR_SEMAPHORE', 'LAZYWRITER_SLEEP', 'RESOURCE_QUEUE',
    'SLEEP_TASK', 'SLEEP_SYSTEMTASK', 'SQLTRACE_BUFFER_FLUSH',
    'WAITFOR', 'BROKER_RECEIVE_WAITFOR', 'CLR_AUTO_EVENT',
    'CLR_MANUAL_EVENT', 'DISPATCHER_QUEUE_SEMAPHORE',
    'XE_TIMER_EVENT', 'XE_DISPATCHER_WAIT', 'FT_IFTS_SCHEDULER_IDLE_WAIT',
    'CHECKPOINT_QUEUE', 'REQUEST_FOR_DEADLOCK_SEARCH'
)
AND wait_time_ms > 0
ORDER BY wait_time_ms DESC
```

### Session Wait Statistics (SQL 2016+)
```sql
-- Waits for current session
SELECT * FROM sys.dm_exec_session_wait_stats
WHERE session_id = @@SPID
ORDER BY wait_time_ms DESC
```

### Currently Waiting Tasks
```sql
SELECT
    wt.session_id,
    wt.wait_type,
    wt.wait_duration_ms,
    wt.blocking_session_id,
    st.text AS query_text
FROM sys.dm_os_waiting_tasks wt
LEFT JOIN sys.dm_exec_requests r ON wt.session_id = r.session_id
OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) AS st
WHERE wt.session_id > 50
ORDER BY wt.wait_duration_ms DESC
```

## Query Performance

### Top Resource-Consuming Queries
```sql
-- Top queries by CPU
SELECT TOP 20
    qs.total_worker_time / 1000 AS total_cpu_ms,
    qs.execution_count,
    qs.total_worker_time / qs.execution_count / 1000 AS avg_cpu_ms,
    SUBSTRING(st.text, (qs.statement_start_offset/2) + 1,
        ((CASE qs.statement_end_offset
            WHEN -1 THEN DATALENGTH(st.text)
            ELSE qs.statement_end_offset
        END - qs.statement_start_offset)/2) + 1) AS query_text
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
ORDER BY qs.total_worker_time DESC
```

### Top Queries by Logical Reads (I/O)
```sql
SELECT TOP 20
    qs.total_logical_reads,
    qs.execution_count,
    qs.total_logical_reads / qs.execution_count AS avg_logical_reads,
    SUBSTRING(st.text, (qs.statement_start_offset/2) + 1,
        ((CASE qs.statement_end_offset
            WHEN -1 THEN DATALENGTH(st.text)
            ELSE qs.statement_end_offset
        END - qs.statement_start_offset)/2) + 1) AS query_text
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
ORDER BY qs.total_logical_reads DESC
```

### Currently Running Queries
```sql
SELECT
    r.session_id,
    r.status,
    r.command,
    r.cpu_time,
    r.total_elapsed_time,
    r.reads,
    r.writes,
    r.wait_type,
    r.blocking_session_id,
    st.text AS query_text,
    qp.query_plan
FROM sys.dm_exec_requests r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS st
CROSS APPLY sys.dm_exec_query_plan(r.plan_handle) AS qp
WHERE r.session_id > 50
  AND r.session_id <> @@SPID
ORDER BY r.cpu_time DESC
```

## Index Analysis

### Missing Indexes
```sql
SELECT
    CONVERT(DECIMAL(18,2), migs.avg_user_impact * (migs.user_seeks + migs.user_scans)) AS improvement_measure,
    'CREATE INDEX [IX_' + OBJECT_NAME(mid.object_id) + '_'
        + REPLACE(REPLACE(REPLACE(ISNULL(mid.equality_columns,''), ', ', '_'), '[', ''), ']', '')
        + '] ON ' + mid.statement
        + ' (' + ISNULL(mid.equality_columns,'')
        + CASE WHEN mid.equality_columns IS NOT NULL AND mid.inequality_columns IS NOT NULL THEN ',' ELSE '' END
        + ISNULL(mid.inequality_columns, '')
        + ')' + ISNULL(' INCLUDE (' + mid.included_columns + ')', '') AS create_index_statement,
    migs.user_seeks,
    migs.user_scans,
    migs.avg_user_impact
FROM sys.dm_db_missing_index_groups mig
JOIN sys.dm_db_missing_index_group_stats migs ON mig.index_group_handle = migs.group_handle
JOIN sys.dm_db_missing_index_details mid ON mig.index_handle = mid.index_handle
WHERE mid.database_id = DB_ID()
ORDER BY improvement_measure DESC
```

### Index Usage Statistics
```sql
SELECT
    OBJECT_NAME(i.object_id) AS TableName,
    i.name AS IndexName,
    i.type_desc,
    ius.user_seeks,
    ius.user_scans,
    ius.user_lookups,
    ius.user_updates,
    ius.last_user_seek,
    ius.last_user_scan
FROM sys.indexes i
LEFT JOIN sys.dm_db_index_usage_stats ius
    ON i.object_id = ius.object_id
    AND i.index_id = ius.index_id
    AND ius.database_id = DB_ID()
WHERE OBJECTPROPERTY(i.object_id, 'IsUserTable') = 1
ORDER BY OBJECT_NAME(i.object_id), i.index_id
```

### Unused Indexes
```sql
SELECT
    OBJECT_NAME(i.object_id) AS TableName,
    i.name AS IndexName,
    i.type_desc,
    ius.user_updates AS writes,
    ius.user_seeks + ius.user_scans + ius.user_lookups AS reads
FROM sys.indexes i
LEFT JOIN sys.dm_db_index_usage_stats ius
    ON i.object_id = ius.object_id
    AND i.index_id = ius.index_id
WHERE OBJECTPROPERTY(i.object_id, 'IsUserTable') = 1
  AND i.index_id > 0
  AND (ius.user_seeks + ius.user_scans + ius.user_lookups) = 0
  AND ius.user_updates > 0
ORDER BY ius.user_updates DESC
```

### Index Fragmentation
```sql
SELECT
    OBJECT_NAME(ips.object_id) AS TableName,
    i.name AS IndexName,
    ips.index_type_desc,
    ips.avg_fragmentation_in_percent,
    ips.page_count
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.avg_fragmentation_in_percent > 10
  AND ips.page_count > 1000
ORDER BY ips.avg_fragmentation_in_percent DESC
```

## Memory and Buffer Pool

### Buffer Pool Usage by Object
```sql
SELECT TOP 20
    OBJECT_NAME(p.object_id) AS TableName,
    COUNT(*) * 8 / 1024 AS buffer_mb,
    COUNT(*) AS pages
FROM sys.dm_os_buffer_descriptors bd
JOIN sys.allocation_units au ON bd.allocation_unit_id = au.allocation_unit_id
JOIN sys.partitions p ON au.container_id = p.hobt_id
WHERE bd.database_id = DB_ID()
GROUP BY p.object_id
ORDER BY COUNT(*) DESC
```

### Memory Grants
```sql
SELECT
    session_id,
    request_id,
    scheduler_id,
    dop,
    requested_memory_kb,
    granted_memory_kb,
    used_memory_kb,
    query_cost,
    timeout_sec,
    wait_time_ms
FROM sys.dm_exec_query_memory_grants
ORDER BY requested_memory_kb DESC
```

## Blocking and Locking

### Current Blocking
```sql
SELECT
    blocked.session_id AS blocked_session,
    blocked.blocking_session_id AS blocking_session,
    blocked.wait_type,
    blocked.wait_time / 1000.0 AS wait_sec,
    blocked_text.text AS blocked_query,
    blocking_text.text AS blocking_query
FROM sys.dm_exec_requests blocked
JOIN sys.dm_exec_requests blocking ON blocked.blocking_session_id = blocking.session_id
CROSS APPLY sys.dm_exec_sql_text(blocked.sql_handle) AS blocked_text
CROSS APPLY sys.dm_exec_sql_text(blocking.sql_handle) AS blocking_text
WHERE blocked.blocking_session_id > 0
```

### Lock Waits
```sql
SELECT
    tl.request_session_id AS session_id,
    OBJECT_NAME(p.object_id) AS table_name,
    tl.resource_type,
    tl.request_mode,
    tl.request_status
FROM sys.dm_tran_locks tl
JOIN sys.partitions p ON tl.resource_associated_entity_id = p.hobt_id
WHERE tl.resource_database_id = DB_ID()
  AND tl.request_status = 'WAIT'
```

## Query Store (SQL 2016+)

### Top Queries from Query Store
```sql
SELECT TOP 20
    qt.query_sql_text,
    q.query_id,
    rs.count_executions,
    rs.avg_duration / 1000 AS avg_duration_ms,
    rs.avg_cpu_time / 1000 AS avg_cpu_ms,
    rs.avg_logical_io_reads
FROM sys.query_store_query q
JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
JOIN sys.query_store_plan p ON q.query_id = p.query_id
JOIN sys.query_store_runtime_stats rs ON p.plan_id = rs.plan_id
JOIN sys.query_store_runtime_stats_interval rsi ON rs.runtime_stats_interval_id = rsi.runtime_stats_interval_id
WHERE rsi.start_time >= DATEADD(hour, -24, GETUTCDATE())
ORDER BY rs.avg_duration DESC
```

### Regressed Queries
```sql
SELECT
    qt.query_sql_text,
    q.query_id,
    p.plan_id,
    rs.avg_duration / 1000 AS recent_avg_ms,
    hist.avg_duration / 1000 AS baseline_avg_ms,
    (rs.avg_duration - hist.avg_duration) / hist.avg_duration * 100 AS regression_pct
FROM sys.query_store_query q
JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
JOIN sys.query_store_plan p ON q.query_id = p.query_id
JOIN sys.query_store_runtime_stats rs ON p.plan_id = rs.plan_id
JOIN sys.query_store_runtime_stats_interval rsi ON rs.runtime_stats_interval_id = rsi.runtime_stats_interval_id
JOIN (
    SELECT plan_id, AVG(avg_duration) AS avg_duration
    FROM sys.query_store_runtime_stats rs
    JOIN sys.query_store_runtime_stats_interval rsi ON rs.runtime_stats_interval_id = rsi.runtime_stats_interval_id
    WHERE rsi.start_time >= DATEADD(day, -30, GETUTCDATE())
      AND rsi.start_time < DATEADD(day, -1, GETUTCDATE())
    GROUP BY plan_id
) hist ON p.plan_id = hist.plan_id
WHERE rsi.start_time >= DATEADD(hour, -24, GETUTCDATE())
  AND rs.avg_duration > hist.avg_duration * 1.5
ORDER BY regression_pct DESC
```

## Azure SQL Database Specific

### Resource Usage
```sql
SELECT
    end_time,
    avg_cpu_percent,
    avg_data_io_percent,
    avg_log_write_percent,
    avg_memory_usage_percent,
    max_worker_percent,
    max_session_percent
FROM sys.dm_db_resource_stats
ORDER BY end_time DESC
```

### Query Performance Insight
```sql
SELECT TOP 20
    qt.query_sql_text,
    rs.avg_cpu_time / 1000 AS avg_cpu_ms,
    rs.avg_logical_io_reads,
    rs.avg_duration / 1000 AS avg_duration_ms,
    rs.count_executions
FROM sys.query_store_query q
JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
JOIN sys.query_store_plan p ON q.query_id = p.query_id
JOIN sys.query_store_runtime_stats rs ON p.plan_id = rs.plan_id
JOIN sys.query_store_runtime_stats_interval rsi ON rs.runtime_stats_interval_id = rsi.runtime_stats_interval_id
WHERE rsi.start_time >= DATEADD(hour, -1, GETUTCDATE())
ORDER BY rs.avg_cpu_time * rs.count_executions DESC
```
