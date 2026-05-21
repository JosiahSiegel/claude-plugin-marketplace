---
name: execution-plan-analysis
description: |
  This skill should be used when the user asks to analyze SQL Server execution plans, .sqlplan files, ShowPlan XML, actual vs estimated plans, plan warnings, or operator costs. PROACTIVELY activate for: .sqlplan triage, ShowPlan XML inspection, high-cost operator ranking, scan vs seek review, residual predicate analysis, CONVERT_IMPLICIT warnings, bad row estimates, cardinality-estimation warnings, partition elimination verification, missing-index suggestions, unused-index warnings, spills, key lookups, sorts, hash joins, and plan-regression evidence gathering.
  Provides: plan triage workflow, operator-cost ranking heuristics, warning interpretation rubric, and rewrite/index recommendation gating.
---

# Execution Plan Analysis

Use this skill to triage SQL Server actual or estimated execution plans, especially `.sqlplan` ShowPlan XML. Treat the plan as evidence, not a verdict: validate schema, data types, indexes, row counts, partitioning, parameter values, and local-vs-linked-server execution before recommending rewrites or indexes.

## Required Inputs

Ask for the smallest set needed to verify the plan:

- SQL Server version, database compatibility level, and Azure SQL vs boxed SQL Server.
- Actual plan when available; estimated plan if execution is unsafe.
- Query text, parameter values, SET options if relevant, and runtime symptoms.
- Table DDL, column data types, indexes, statistics age, partition scheme/function, and row counts.
- Whether referenced objects are local, remote linked servers, views, table-valued functions, or temp tables.
- Allowed changes: query rewrite, statistics update, index add/drop/change, computed column, staging table, or no code change.

Use `../_shared/optimization-intake.md` and `../_shared/assumption-tracker.md` for intake and assumption status tracking.

## Workflow

### 1. Establish Plan Context

Record whether the plan is actual or estimated. Actual plans expose runtime row counts, warnings, spills, memory grant use, and actual partition access. Estimated plans can still reveal access paths, conversions, missing index requests, and join choices, but cannot prove runtime misestimates or spills.

Capture:

- Statement subtree cost and top-level statement text.
- Compile-time parameter values and runtime parameter values when present.
- Cardinality estimator version and compatibility level if visible.
- Degree of parallelism, memory grant, and warnings.

### 2. Rank High-Cost Operators, Then Validate

Sort operators by estimated subtree or operator cost to find likely work centers, but do not tune solely by percentage. A 90% operator in a tiny query may not matter; a low-percentage operator inside a repeated nested loops branch can dominate runtime.

For each candidate operator, record:

| Evidence | What to capture |
|---|---|
| Operator | Physical and logical operation |
| Object | Table, index, or remote source |
| Cost | Estimated operator/subtree cost and relative percentage |
| Rows | estimated rows, actual rows, executions, rows read |
| Predicates | seek predicates, residual predicates, probes, join predicates |
| Warnings | spills, conversions, missing indexes, no join predicate, cardinality issues |

### 3. Check Scans, Seeks, and Residual Predicates

A seek is not automatically good and a scan is not automatically bad. Verify how much data was read vs returned.

- **Index/Table Scan**: determine whether it is expected for large-result queries, forced by non-SARGable predicates, caused by missing indexes, or caused by type/collation mismatch.
- **Index Seek with residual predicate**: inspect `SeekPredicates` vs `Predicate`. A seek that reads millions and filters later may need a better key order, computed column, filtered index, or rewrite.
- **Key Lookup/RID Lookup**: multiply actual rows by executions; many lookups can justify covering indexes, but avoid blindly adding wide INCLUDE columns.

### 4. Find Implicit Conversions and Collation Issues

Search ShowPlan for `CONVERT_IMPLICIT`, `PlanAffectingConvert`, and scalar operators around indexed columns. Prioritize conversions on the column side of predicates and joins because they can block seeks or distort estimates.

Classify each conversion:

- Safe projection-only conversion.
- Predicate conversion that may still seek but harms estimates.
- Column-side conversion that prevents efficient seek.
- Join-key conversion that causes scans, hash joins, or remote row-by-row work.

Recommended fixes must preserve semantics: align parameter types, temp-table types, literals, computed columns, or source column definitions when schema change is allowed.

### 5. Compare Estimated vs Actual Rows

Large estimate errors can explain bad join order, memory grants, spills, and wrong join algorithms.

Flag when any operator has:

- Actual rows vs estimated rows off by 10x or more.
- Actual executions far above expectation.
- Estimated one row but actual many rows from table variables, multi-statement TVFs, local variables, or stale stats.
- Severe skew suggesting parameter sniffing or Parameter Sensitive Plan behavior.

Tie recommendations to root cause: update statistics, create filtered statistics/indexes, use temp tables for phased cardinality, address parameter sensitivity, or rewrite predicates.

### 6. Verify Partition Elimination

For partitioned objects, prove whether the plan eliminates partitions.

Check:

- Partitioning column and data type.
- Predicate column and expression shape.
- Actual or estimated accessed partitions.
- Whether conversions, functions, OR predicates, joins, views, or local variables obscure the partition key.

Warn against unsafe partition predicates such as wrapping the partition column in functions, comparing mismatched types, or filtering on a related date column that is not the partitioning column unless a trusted constraint proves equivalence.

### 7. Interpret Index Warnings Carefully

Missing-index warnings are suggestions for one compiled statement, not a design. Convert them into candidate indexes only after comparing with existing indexes, workload patterns, write cost, and constraints.

Also inspect unused or duplicate indexes if the plan shows update overhead or if index maintenance is part of the ask. Do not recommend dropping indexes from a single plan; require workload evidence.

### 8. Report Findings as Evidence

Use this format:

1. **Plan summary**: plan type, statement, runtime symptom, top operators.
2. **Verified facts**: schema/index/type/row-count facts confirmed.
3. **Findings**: each with operator, XML evidence, impact, confidence.
4. **Assumptions**: tracked as verified, unverified, disproved, or needs diagnostic.
5. **Recommendations**: safest first; separate rewrites, index/stat changes, and diagnostics.
6. **Proof plan**: before/after metrics to collect.

## Reference

For ShowPlan XML attributes, XPath-style lookups, and operator-cost interpretation, see `references/showplan-xml-checklist.md`.
