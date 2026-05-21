---
name: query-optimization
description: |
  This skill should be used when the user asks to optimize slow T-SQL queries, fix SQL Server performance regressions, improve SARGability, rewrite joins, prove whether joins can be removed, compare temp-table data types, select rewrite templates, diagnose parameter sniffing, evaluate query hints, inspect statistics/cardinality estimates, reduce spills or memory grants, use Query Store, or interpret plan evidence. PROACTIVELY activate for slow queries, scans vs seeks, implicit conversions, bad joins, tempdb spills, query rewrites, partition predicate safety, and before recommending indexes or hints.
  Provides: evidence-first workflow, rewrite templates, parameter-sniffing playbook, and gating rules before recommending indexes or hints.
---

# Query Optimization

Comprehensive guide to T-SQL query optimization for SQL Server and Azure SQL Database. Optimize from verified evidence: schema, data types, indexes, row counts, partitioning, execution plans, and allowed change types.

## Mandatory Workflow

### 1. Schema-First Validation

Before recommending rewrites, indexes, or hints, verify or mark unknown:

- SQL Server version, edition, compatibility level, and Azure SQL tier if applicable.
- Full query/procedure text, parameter values, frequency, and runtime target.
- DDL for tables, views, temp tables, table variables, and TVFs.
- Data types for join, filter, grouping, ordering, and temp-table columns, including length, precision, scale, collation, and nullability.
- Existing indexes, constraints, statistics age, partition function/scheme, and row counts.
- Whether objects are local or linked-server/remote sources.
- Allowed change types: query rewrite, new index, huge-table index change, stats update, staging table, computed column, or no code change.

Use `../_shared/optimization-intake.md` and `../_shared/assumption-tracker.md`. If key facts are missing, provide conditional guidance plus diagnostics instead of final prescriptions.

### 2. Identify the Root Bottleneck

Use actual execution plans and `STATISTICS IO, TIME` when possible. Rank findings by measured impact, not just estimated plan percentage:

- High logical reads or row reads.
- Bad estimate vs actual row gaps.
- Scans caused by non-SARGable predicates or missing access paths.
- Key lookups multiplied by many executions.
- Sort/hash/window spills from poor estimates or missing order.
- Remote queries that fail to push predicates or joins to the linked server.

For detailed `.sqlplan` inspection, load `tsql-master:execution-plan-analysis`.

### 3. Fix SARGability and Type Mismatches

SARGable predicates can use ordered index access. Avoid functions or conversions on indexed columns.

| Non-SARGable | Safer pattern |
|---|---|
| `WHERE YEAR(OrderDate) = 2026` | `WHERE OrderDate >= '20260101' AND OrderDate < '20270101'` |
| `WHERE LEFT(Name, 3) = 'ABC'` | `WHERE Name LIKE 'ABC%'` |
| `WHERE Amount * 1.1 > 1000` | `WHERE Amount > 1000 / 1.1` |
| `WHERE CONVERT(date, Dt) = @d` | `WHERE Dt >= @d AND Dt < DATEADD(day, 1, @d)` |
| `WHERE VarcharCol = 123` | `WHERE VarcharCol = '123'` |

Check actual data types. A syntactically SARGable predicate can still scan if a parameter, temp column, or join key has the wrong type or collation.

### 4. Prove Join Changes

Never remove or replace joins only because selected columns come from one table. Prove:

- **Does the join filter rows?** Compare base count vs joined count and check trusted foreign keys.
- **Does the join multiply rows?** Check uniqueness on the joined key and duplicates in the referenced table.
- **Can it be replaced with `EXISTS`?** Use a semi-join when only existence is needed and row multiplication must be avoided.
- **Are outer joins preserved?** Predicates in `WHERE` can accidentally convert `LEFT JOIN` to inner join.

Move join-removal experiments into a proof harness and validate equivalence with `EXCEPT` in both directions. See `references/rewrite-proof-harnesses.md`.

### 5. Check Temp Tables and Staging Types

Temp tables are often the right optimization tool, but bad types can create hidden conversions.

Before using or recommending a temp table:

- Compare staged column types against source metadata.
- Match string length and collation for join/filter columns.
- Match numeric precision/scale and date/time precision.
- Add appropriate clustered or nonclustered indexes after load when row counts justify them.
- Update temp-table statistics when phased optimization depends on accurate cardinality.

Flag mismatches as first-order findings because they can invalidate plan analysis and index recommendations. Use the checker in `references/rewrite-proof-harnesses.md`.

### 6. Select the Rewrite Template

Choose the least invasive rewrite that addresses the verified bottleneck:

| Situation | Template |
|---|---|
| Highly selective predicate before huge joins | Stage selective keys first, index the stage, then join. |
| Huge detail table aggregated later | Aggregate early if grouping preserves semantics. |
| Join only tests existence | Replace row-producing join with `EXISTS`. |
| OR across different columns | Split into `UNION ALL` branches with duplicate guards. |
| Catch-all optional predicates | Dynamic SQL or targeted recompilation; avoid `Col = @p OR @p IS NULL` for hot paths. |
| Unsafe partition predicate | Rewrite to direct typed range on partition column. |
| Bad estimates from table variables/TVFs | Use temp tables, inline TVFs, or recompile depending on version and workload. |

Do not stage huge unfiltered tables or aggregate early unless the row reduction and semantic equivalence are proven.

## Parameter Sensitivity

Parameter sniffing occurs when a plan compiled for one value is reused for a very different value. Confirm skew and compile/runtime values before applying fixes.

| Option | Best for | Caution |
|---|---|---|
| `OPTION (RECOMPILE)` | Infrequent or highly variable statements | Adds compile CPU; plan not reused. |
| `OPTIMIZE FOR (@p = value)` | Stable representative value | Can age badly as data changes. |
| `OPTIMIZE FOR UNKNOWN` | Average distribution is acceptable | Can be mediocre for all cases. |
| Dynamic SQL | Optional predicates and varied shapes | Requires safe parameterization. |
| Query Store hints | SQL Server 2022+ or Azure SQL, no code change | Monitor regressions. |
| PSP optimization | SQL Server 2022+ with compatibility 160 | Only applies to eligible patterns. |

## Execution Plan Checks

Watch these operators and warnings:

| Plan evidence | Likely action |
|---|---|
| Scan with residual predicate | Fix SARGability, key order, or filtered index. |
| Seek with high rows read | Add more selective key columns or rewrite residual predicate. |
| Key lookup repeated many times | Cover query or reduce outer rows first. |
| Sort spill or hash spill | Fix estimates, reduce rows/width, add order-compatible index. |
| `CONVERT_IMPLICIT` on column | Align parameter/temp/source data types. |
| Estimate off by 10x+ | Check stats, skew, table variables, predicates, constraints. |
| Missing-index warning | Treat as candidate only; merge with existing indexes and workload. |

## Statistics and Cardinality

Use statistics work when evidence points to stale or insufficient estimates:

```sql
DBCC SHOW_STATISTICS('dbo.TableName', 'IndexOrStatsName');
UPDATE STATISTICS dbo.TableName IndexOrStatsName WITH FULLSCAN;
```

For large partitioned tables, evaluate incremental statistics and filtered stats. Do not run broad fullscan updates in production without maintenance-window and blocking considerations.

## Output Format

Respond with:

1. **Intake status**: verified, unverified, disproved, needs diagnostic.
2. **Bottleneck evidence**: plan nodes, reads, rows, estimates, warnings.
3. **Recommendation path**: rewrite, index/stat change, or diagnostic, separated by allowed change type.
4. **Proof harness**: result equivalence and before/after performance metrics.
5. **Risks**: parameter sensitivity, write overhead, blocking, partition safety, remote pushdown.

## References

- `../_shared/optimization-intake.md` - mandatory intake checklist.
- `../_shared/assumption-tracker.md` - assumption status protocol.
- `references/rewrite-proof-harnesses.md` - join proof, temp type checker, and rewrite templates.
- `references/dmv-diagnostic-queries.md` - DMV queries for performance analysis.
