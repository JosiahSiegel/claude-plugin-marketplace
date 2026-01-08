/*
 * T-SQL SARGability Checker
 * Run against your database to find queries with potential SARGability issues
 *
 * Usage: Execute in target database
 * Note: Requires Query Store to be enabled
 */

-- Find queries with potential SARGability issues (function calls in predicates)
SELECT TOP 50
    qt.query_sql_text,
    q.query_id,
    rs.count_executions,
    rs.avg_duration / 1000 AS avg_duration_ms,
    rs.avg_logical_io_reads,
    CASE
        WHEN qt.query_sql_text LIKE '%YEAR(%' THEN 'YEAR() function'
        WHEN qt.query_sql_text LIKE '%MONTH(%' THEN 'MONTH() function'
        WHEN qt.query_sql_text LIKE '%DAY(%' THEN 'DAY() function'
        WHEN qt.query_sql_text LIKE '%DATEPART(%' THEN 'DATEPART() function'
        WHEN qt.query_sql_text LIKE '%CONVERT(%' AND qt.query_sql_text LIKE '%WHERE%' THEN 'CONVERT() in WHERE'
        WHEN qt.query_sql_text LIKE '%CAST(%' AND qt.query_sql_text LIKE '%WHERE%' THEN 'CAST() in WHERE'
        WHEN qt.query_sql_text LIKE '%LEFT(%' AND qt.query_sql_text LIKE '%WHERE%' THEN 'LEFT() in WHERE'
        WHEN qt.query_sql_text LIKE '%RIGHT(%' AND qt.query_sql_text LIKE '%WHERE%' THEN 'RIGHT() in WHERE'
        WHEN qt.query_sql_text LIKE '%SUBSTRING(%' AND qt.query_sql_text LIKE '%WHERE%' THEN 'SUBSTRING() in WHERE'
        WHEN qt.query_sql_text LIKE '%UPPER(%' AND qt.query_sql_text LIKE '%WHERE%' THEN 'UPPER() in WHERE'
        WHEN qt.query_sql_text LIKE '%LOWER(%' AND qt.query_sql_text LIKE '%WHERE%' THEN 'LOWER() in WHERE'
        WHEN qt.query_sql_text LIKE '%ISNULL(%' AND qt.query_sql_text LIKE '%WHERE%' THEN 'ISNULL() in WHERE'
        WHEN qt.query_sql_text LIKE '%COALESCE(%' AND qt.query_sql_text LIKE '%WHERE%' THEN 'COALESCE() in WHERE'
        ELSE 'Review needed'
    END AS potential_issue
FROM sys.query_store_query q
JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
JOIN sys.query_store_plan p ON q.query_id = p.query_id
JOIN sys.query_store_runtime_stats rs ON p.plan_id = rs.plan_id
WHERE (
    -- Date function patterns
    qt.query_sql_text LIKE '%YEAR(%'
    OR qt.query_sql_text LIKE '%MONTH(%'
    OR qt.query_sql_text LIKE '%DAY(%'
    OR qt.query_sql_text LIKE '%DATEPART(%'
    -- String function patterns
    OR (qt.query_sql_text LIKE '%LEFT(%' AND qt.query_sql_text LIKE '%WHERE%')
    OR (qt.query_sql_text LIKE '%RIGHT(%' AND qt.query_sql_text LIKE '%WHERE%')
    OR (qt.query_sql_text LIKE '%SUBSTRING(%' AND qt.query_sql_text LIKE '%WHERE%')
    OR (qt.query_sql_text LIKE '%UPPER(%' AND qt.query_sql_text LIKE '%WHERE%')
    OR (qt.query_sql_text LIKE '%LOWER(%' AND qt.query_sql_text LIKE '%WHERE%')
    -- Conversion patterns
    OR (qt.query_sql_text LIKE '%CONVERT(%' AND qt.query_sql_text LIKE '%WHERE%')
    OR (qt.query_sql_text LIKE '%CAST(%' AND qt.query_sql_text LIKE '%WHERE%')
    -- NULL handling patterns
    OR (qt.query_sql_text LIKE '%ISNULL(%' AND qt.query_sql_text LIKE '%WHERE%')
    OR (qt.query_sql_text LIKE '%COALESCE(%' AND qt.query_sql_text LIKE '%WHERE%')
)
AND q.is_internal_query = 0
ORDER BY rs.avg_logical_io_reads * rs.count_executions DESC;

GO

-- Find queries with implicit conversions (from plan XML)
SELECT TOP 20
    qt.query_sql_text,
    q.query_id,
    p.plan_id,
    rs.count_executions,
    rs.avg_duration / 1000 AS avg_duration_ms
FROM sys.query_store_query q
JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
JOIN sys.query_store_plan p ON q.query_id = p.query_id
JOIN sys.query_store_runtime_stats rs ON p.plan_id = rs.plan_id
WHERE TRY_CONVERT(XML, p.query_plan) IS NOT NULL
  AND CONVERT(XML, p.query_plan).exist('//PlanAffectingConvert') = 1
ORDER BY rs.count_executions DESC;

GO

-- Summary of SARGability issues by type
PRINT '=== SARGability Issue Summary ===';
PRINT '';

SELECT
    'Date Functions in WHERE' AS issue_type,
    COUNT(*) AS query_count
FROM sys.query_store_query_text
WHERE query_sql_text LIKE '%WHERE%YEAR(%'
   OR query_sql_text LIKE '%WHERE%MONTH(%'
   OR query_sql_text LIKE '%WHERE%DATEPART(%'

UNION ALL

SELECT
    'String Functions in WHERE',
    COUNT(*)
FROM sys.query_store_query_text
WHERE query_sql_text LIKE '%WHERE%LEFT(%'
   OR query_sql_text LIKE '%WHERE%RIGHT(%'
   OR query_sql_text LIKE '%WHERE%UPPER(%'
   OR query_sql_text LIKE '%WHERE%LOWER(%'

UNION ALL

SELECT
    'ISNULL/COALESCE in WHERE',
    COUNT(*)
FROM sys.query_store_query_text
WHERE query_sql_text LIKE '%WHERE%ISNULL(%'
   OR query_sql_text LIKE '%WHERE%COALESCE(%';
