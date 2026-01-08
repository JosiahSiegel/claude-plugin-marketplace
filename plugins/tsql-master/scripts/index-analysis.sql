/*
 * T-SQL Index Analysis Script
 * Comprehensive index health check for SQL Server databases
 *
 * Usage: Execute in target database
 * Works with: SQL Server 2016+, Azure SQL Database
 */

SET NOCOUNT ON;

PRINT '================================================';
PRINT 'Index Analysis Report - ' + DB_NAME();
PRINT 'Generated: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '================================================';
PRINT '';

-- ============================================
-- 1. MISSING INDEXES (High Impact)
-- ============================================
PRINT '=== MISSING INDEXES ===';
PRINT '';

SELECT TOP 20
    CONVERT(DECIMAL(18,2), migs.avg_user_impact * (migs.user_seeks + migs.user_scans)) AS impact_score,
    migs.avg_user_impact AS avg_impact_pct,
    migs.user_seeks,
    migs.user_scans,
    mid.statement AS table_name,
    mid.equality_columns,
    mid.inequality_columns,
    mid.included_columns,
    'CREATE NONCLUSTERED INDEX [IX_' +
        REPLACE(REPLACE(OBJECT_NAME(mid.object_id), '[', ''), ']', '') + '_' +
        REPLACE(REPLACE(REPLACE(ISNULL(mid.equality_columns,''), ', ', '_'), '[', ''), ']', '') +
        '] ON ' + mid.statement +
        ' (' + ISNULL(mid.equality_columns,'') +
        CASE WHEN mid.equality_columns IS NOT NULL AND mid.inequality_columns IS NOT NULL THEN ',' ELSE '' END +
        ISNULL(mid.inequality_columns, '') + ')' +
        ISNULL(' INCLUDE (' + mid.included_columns + ')', '') AS create_statement
FROM sys.dm_db_missing_index_groups mig
JOIN sys.dm_db_missing_index_group_stats migs ON mig.index_group_handle = migs.group_handle
JOIN sys.dm_db_missing_index_details mid ON mig.index_handle = mid.index_handle
WHERE mid.database_id = DB_ID()
ORDER BY impact_score DESC;

PRINT '';

-- ============================================
-- 2. UNUSED INDEXES (Candidates for Removal)
-- ============================================
PRINT '=== UNUSED INDEXES (potential removal candidates) ===';
PRINT '';

SELECT
    OBJECT_SCHEMA_NAME(i.object_id) + '.' + OBJECT_NAME(i.object_id) AS table_name,
    i.name AS index_name,
    i.type_desc,
    ISNULL(ius.user_seeks, 0) AS user_seeks,
    ISNULL(ius.user_scans, 0) AS user_scans,
    ISNULL(ius.user_lookups, 0) AS user_lookups,
    ISNULL(ius.user_updates, 0) AS user_updates,
    CASE
        WHEN ius.last_user_seek IS NULL AND ius.last_user_scan IS NULL
        THEN 'Never used'
        ELSE CONVERT(VARCHAR, ISNULL(ius.last_user_seek, ius.last_user_scan), 120)
    END AS last_access,
    ps.row_count,
    CONVERT(DECIMAL(18,2), ps.reserved_page_count * 8.0 / 1024) AS size_mb
FROM sys.indexes i
LEFT JOIN sys.dm_db_index_usage_stats ius
    ON i.object_id = ius.object_id
    AND i.index_id = ius.index_id
    AND ius.database_id = DB_ID()
JOIN sys.dm_db_partition_stats ps
    ON i.object_id = ps.object_id
    AND i.index_id = ps.index_id
WHERE OBJECTPROPERTY(i.object_id, 'IsUserTable') = 1
  AND i.index_id > 1  -- Exclude clustered indexes and heaps
  AND i.is_primary_key = 0
  AND i.is_unique_constraint = 0
  AND (ISNULL(ius.user_seeks, 0) + ISNULL(ius.user_scans, 0) + ISNULL(ius.user_lookups, 0)) = 0
  AND ISNULL(ius.user_updates, 0) > 0
ORDER BY ius.user_updates DESC;

PRINT '';

-- ============================================
-- 3. DUPLICATE/OVERLAPPING INDEXES
-- ============================================
PRINT '=== POTENTIALLY DUPLICATE INDEXES ===';
PRINT '';

WITH IndexColumns AS (
    SELECT
        i.object_id,
        i.index_id,
        i.name AS index_name,
        i.type_desc,
        (
            SELECT STRING_AGG(c.name, ',') WITHIN GROUP (ORDER BY ic.key_ordinal)
            FROM sys.index_columns ic
            JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
            WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.is_included_column = 0
        ) AS key_columns
    FROM sys.indexes i
    WHERE OBJECTPROPERTY(i.object_id, 'IsUserTable') = 1
      AND i.index_id > 0
)
SELECT
    OBJECT_SCHEMA_NAME(ic1.object_id) + '.' + OBJECT_NAME(ic1.object_id) AS table_name,
    ic1.index_name AS index_1,
    ic1.key_columns AS index_1_keys,
    ic2.index_name AS index_2,
    ic2.key_columns AS index_2_keys,
    'Review for consolidation' AS recommendation
FROM IndexColumns ic1
JOIN IndexColumns ic2
    ON ic1.object_id = ic2.object_id
    AND ic1.index_id < ic2.index_id
    AND (ic1.key_columns = ic2.key_columns
         OR ic1.key_columns LIKE ic2.key_columns + ',%'
         OR ic2.key_columns LIKE ic1.key_columns + ',%')
ORDER BY OBJECT_NAME(ic1.object_id), ic1.index_name;

PRINT '';

-- ============================================
-- 4. INDEX FRAGMENTATION
-- ============================================
PRINT '=== FRAGMENTED INDEXES (>10%, >1000 pages) ===';
PRINT '';

SELECT
    OBJECT_SCHEMA_NAME(ips.object_id) + '.' + OBJECT_NAME(ips.object_id) AS table_name,
    i.name AS index_name,
    ips.index_type_desc,
    CONVERT(DECIMAL(5,2), ips.avg_fragmentation_in_percent) AS frag_pct,
    ips.page_count,
    CONVERT(DECIMAL(18,2), ips.page_count * 8.0 / 1024) AS size_mb,
    CASE
        WHEN ips.avg_fragmentation_in_percent < 30 THEN 'REORGANIZE'
        ELSE 'REBUILD'
    END AS recommended_action
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.avg_fragmentation_in_percent > 10
  AND ips.page_count > 1000
  AND ips.index_id > 0
ORDER BY ips.avg_fragmentation_in_percent DESC;

PRINT '';

-- ============================================
-- 5. INDEX USAGE SUMMARY
-- ============================================
PRINT '=== INDEX USAGE SUMMARY (Top 20 by reads) ===';
PRINT '';

SELECT TOP 20
    OBJECT_SCHEMA_NAME(i.object_id) + '.' + OBJECT_NAME(i.object_id) AS table_name,
    i.name AS index_name,
    i.type_desc,
    ius.user_seeks,
    ius.user_scans,
    ius.user_lookups,
    ius.user_seeks + ius.user_scans + ius.user_lookups AS total_reads,
    ius.user_updates AS writes,
    CASE
        WHEN ius.user_updates > 0
        THEN CONVERT(DECIMAL(10,2), (ius.user_seeks + ius.user_scans + ius.user_lookups) * 1.0 / ius.user_updates)
        ELSE NULL
    END AS read_write_ratio
FROM sys.indexes i
JOIN sys.dm_db_index_usage_stats ius
    ON i.object_id = ius.object_id
    AND i.index_id = ius.index_id
    AND ius.database_id = DB_ID()
WHERE OBJECTPROPERTY(i.object_id, 'IsUserTable') = 1
ORDER BY (ius.user_seeks + ius.user_scans + ius.user_lookups) DESC;

PRINT '';

-- ============================================
-- 6. TABLES WITHOUT CLUSTERED INDEX (Heaps)
-- ============================================
PRINT '=== HEAP TABLES (no clustered index) ===';
PRINT '';

SELECT
    OBJECT_SCHEMA_NAME(t.object_id) + '.' + t.name AS table_name,
    ps.row_count,
    CONVERT(DECIMAL(18,2), ps.reserved_page_count * 8.0 / 1024) AS size_mb,
    'Consider adding clustered index' AS recommendation
FROM sys.tables t
JOIN sys.dm_db_partition_stats ps ON t.object_id = ps.object_id AND ps.index_id = 0
WHERE NOT EXISTS (
    SELECT 1 FROM sys.indexes i
    WHERE i.object_id = t.object_id AND i.type = 1
)
ORDER BY ps.row_count DESC;

PRINT '';

-- ============================================
-- 7. STATISTICS HEALTH
-- ============================================
PRINT '=== OUTDATED STATISTICS (>7 days old) ===';
PRINT '';

SELECT TOP 20
    OBJECT_SCHEMA_NAME(s.object_id) + '.' + OBJECT_NAME(s.object_id) AS table_name,
    s.name AS stats_name,
    STATS_DATE(s.object_id, s.stats_id) AS last_updated,
    DATEDIFF(day, STATS_DATE(s.object_id, s.stats_id), GETDATE()) AS days_old,
    sp.rows AS row_count,
    sp.modification_counter AS rows_modified,
    CASE
        WHEN sp.rows > 0
        THEN CONVERT(DECIMAL(10,2), sp.modification_counter * 100.0 / sp.rows)
        ELSE 0
    END AS pct_modified
FROM sys.stats s
CROSS APPLY sys.dm_db_stats_properties(s.object_id, s.stats_id) sp
WHERE OBJECTPROPERTY(s.object_id, 'IsUserTable') = 1
  AND STATS_DATE(s.object_id, s.stats_id) < DATEADD(day, -7, GETDATE())
ORDER BY sp.modification_counter DESC;

PRINT '';
PRINT '=== Analysis Complete ===';
