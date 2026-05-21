# Optimization Intake Protocol

Use this checklist before recommending T-SQL rewrites, indexes, hints, statistics changes, or partition changes. The goal is to prevent confident recommendations based on incomplete schema or workload assumptions.

## Mandatory Intake Checklist

Collect or explicitly mark unknown:

| Area | Required details |
|---|---|
| Platform | SQL Server version, edition, compatibility level, Azure SQL tier if applicable. |
| Query | Full query or procedure text, parameters, representative parameter values, frequency, timeout or duration target. |
| Plan | Actual execution plan preferred; estimated plan acceptable when execution is unsafe. |
| Tables | DDL for referenced tables, views, TVFs, temp tables, and table variables. |
| Data types | Join, filter, grouping, ordering, and temp-table column types including length, precision, scale, collation, and nullability. |
| Indexes | Existing clustered, nonclustered, filtered, columnstore, unique constraints, included columns, compression, and disabled indexes. |
| Statistics | Relevant stats names, last updated date, sampled vs fullscan, filtered stats, incremental stats for partitions. |
| Row counts | Table row counts, filtered row counts for key predicates, skewed values, partition row counts. |
| Partitioning | Partition function/scheme, partitioning column, boundary values, aligned indexes, and elimination evidence. |
| Locality | Local table vs linked server vs external table; whether predicates and joins are pushed down remotely. |
| Constraints | Primary keys, foreign keys, unique constraints, check constraints, trusted/untrusted status. |
| Allowed changes | Query-only rewrite, add index, change existing huge-table index, drop index, update stats, add computed column, use temp/staging table, change schema, or no code change. |
| Operational limits | Maintenance windows, online/resumable index operations, blocking tolerance, tempdb limits, write overhead tolerance. |

## Minimum Safe Recommendation Rule

If DDL, data types, indexes, and row counts are missing, do not present rewrites or indexes as final answers. Provide:

1. A likely hypothesis.
2. The missing facts needed to verify it.
3. A diagnostic query or plan evidence request.
4. A conditional recommendation clearly labeled with assumptions.

## Schema-First Validation

Before rewrite advice:

- Compare all predicate and join data types exactly, including temp tables and parameters.
- Verify indexes support the proposed access path and do not conflict with existing similar indexes.
- Confirm partition predicates target the partitioning column in a SARGable form.
- Validate row counts and selectivity; do not assume small dimension tables or unique joins.
- Identify linked-server objects because local rewrites can change pushdown and row movement.

## Output Block

Use this compact intake summary in optimization responses:

```text
Intake status:
- Verified: SQL Server version, query text, actual plan, Orders DDL, IX_Orders_CustomerDate.
- Unverified: parameter skew, filtered row count for Status='Open', online index allowance.
- Needs diagnostic: temp table type comparison, partition access proof.
- Change constraints: query rewrite allowed; new indexes require approval; no changes to clustered index.
```
