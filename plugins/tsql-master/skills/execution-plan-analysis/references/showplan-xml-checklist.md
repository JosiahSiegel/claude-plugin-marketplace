# ShowPlan XML Checklist

Use this checklist when inspecting SQL Server `.sqlplan` files or raw ShowPlan XML. Paths are XPath-style guidance; exact namespaces and nesting vary by SQL Server version, plan type, and tooling.

## XML Navigation Basics

Most ShowPlan XML uses the namespace `http://schemas.microsoft.com/sqlserver/2004/07/showplan`. XML tools may require binding it to a prefix such as `sp`.

Common lookup patterns:

```xpath
//sp:StmtSimple
//sp:RelOp
//sp:RelOp[@PhysicalOp='Index Seek']
//sp:RelOp[@PhysicalOp='Index Scan' or @PhysicalOp='Table Scan']
//sp:Warnings
//*[contains(@ScalarString, 'CONVERT_IMPLICIT')]
//sp:MissingIndexes
//sp:RunTimeCountersPerThread
```

If using text search first, search for `PhysicalOp=`, `LogicalOp=`, `CONVERT_IMPLICIT`, `PlanAffectingConvert`, `SpillToTempDb`, `MissingIndex`, `UnmatchedIndexes`, `CardinalityEstimationModelVersion`, `ActualRows`, `EstimateRows`, `ActualPartitionsAccessed`, and `Partitioned`.

## Statement-Level Attributes

Look under `StmtSimple`, `StmtCursor`, or `StmtCond`:

| Attribute / element | Use |
|---|---|
| `StatementText` | Identify the statement represented by the plan. |
| `StatementSubTreeCost` | Estimated total cost; useful for comparing statements in the same batch. |
| `StatementOptmLevel` | `TRIVIAL` plans may ignore many alternatives. |
| `CardinalityEstimationModelVersion` | CE version, often tied to compatibility level. |
| `ParameterList` | Compile-time and runtime parameter values when captured. |
| `QueryPlan/@CachedPlanSize` | Plan cache footprint signal. |
| `QueryPlan/@DegreeOfParallelism` | Parallel plan DOP. |
| `MemoryGrantInfo` | Requested, granted, used, ideal memory; spills often pair with bad grants. |
| `OptimizerStatsUsage` | Statistics consulted at compile time and last update metadata. |

## Operator Ranking

Each `RelOp` may include:

| Attribute | Interpretation |
|---|---|
| `@NodeId` | Stable operator identifier inside the plan. |
| `@PhysicalOp` / `@LogicalOp` | Actual operator implementation and relational intent. |
| `@EstimatedTotalSubtreeCost` | Cost of operator plus descendants; rank to find major work centers. |
| `@EstimateRows` | Estimated output rows per execution. |
| `@EstimateIO`, `@EstimateCPU` | Cost components. |
| `@AvgRowSize` | Wide rows can make memory, sort, hash, and lookup costs worse. |
| `@Parallel` | Whether operator participates in parallel sections. |

Cost percentages are optimizer estimates, not measured time. Validate with actual rows, rows read, executions, elapsed time, and waits when available.

## Runtime Counters

Actual plans expose `RunTimeCountersPerThread` under `RunTimeInformation`:

| Attribute | Use |
|---|---|
| `ActualRows` | Rows emitted by that thread. Sum across threads when needed. |
| `ActualRowsRead` | Rows read before residual filtering; critical for hidden scan-like seeks. |
| `ActualExecutions` | Repetition count; lookups and inner nested loops can multiply cost. |
| `ActualEndOfScans` | Repeated scans may indicate nested loops issues. |
| `ActualElapsedms`, `ActualCPUms` | Present in some actual plans; useful but not universal. |

Estimate ratio heuristic:

```text
ratio = max(actual_rows, 1) / max(estimated_rows * actual_executions, tiny_value)
```

Investigate ratios above 10x or below 0.1x, especially near joins, sorts, hashes, and memory grants.

## Access Path Inspection

For seeks and scans, inspect `IndexScan`, `TableScan`, and nested predicate elements.

```xpath
//sp:RelOp[sp:IndexScan or sp:TableScan]
//sp:SeekPredicates
//sp:Predicate
//sp:Object
//sp:DefinedValues
```

Key fields:

- `Object/@Database`, `@Schema`, `@Table`, `@Index`: confirms object and access path.
- `SeekPredicates`: conditions used to navigate the index b-tree.
- `Predicate`: residual filter applied after reading candidate rows.
- `Ordered`: whether the access path preserves order for merge joins or ORDER BY.
- `Lookup`: key/RID lookup indicator in some plan renderings.

Red flags:

- Seek with high `ActualRowsRead` but low `ActualRows`.
- Residual predicate on a highly selective column that is not a key column.
- Scan caused by `ScalarOperator` on an indexed column.
- Repeated lookup with high `ActualExecutions`.

## Implicit Conversion and Cardinality Warnings

Look for:

```xpath
//sp:Warnings/sp:PlanAffectingConvert
//*[contains(@ScalarString, 'CONVERT_IMPLICIT')]
//sp:Warnings[@NoJoinPredicate='1']
//sp:Warnings/sp:SpillToTempDb
```

Important attributes:

| Warning | Meaning |
|---|---|
| `PlanAffectingConvert/@ConvertIssue='Seek Plan'` | Conversion may prevent seek shape. |
| `PlanAffectingConvert/@ConvertIssue='Cardinality Estimate'` | Conversion may distort row estimates. |
| `SpillToTempDb` | Sort/hash/window aggregate exceeded memory grant. |
| `NoJoinPredicate` | Cross join or missing predicate; often severe. |

When a conversion appears in a join or predicate, identify which side is converted. Converting a literal or parameter may be harmless; converting a column can defeat index use.

## Partition Elimination

Useful searches:

```xpath
//*[contains(@ScalarString, '$PARTITION')]
//sp:RelOp[.//sp:Object[@Partitioned='true']]
//sp:RunTimePartitionSummary
//*[contains(@ActualPartitionsAccessed, '')]
```

Attributes and elements vary by version, but inspect:

- `Object/@Partitioned`.
- `Partitioned` access properties in graphical plan details.
- `Actual Partition Count` / `Actual Partitions Accessed` in SSMS properties.
- Predicate shape around the partitioning column.

Elimination is suspect when the filter uses functions on the partition key, mismatched data types, non-equivalent date columns, OR conditions, local variables with poor estimates, or remote sources.

## Missing and Unmatched Indexes

Look for:

```xpath
//sp:MissingIndexes
//sp:MissingIndexGroup
//sp:ColumnGroup[@Usage='EQUALITY']
//sp:ColumnGroup[@Usage='INEQUALITY']
//sp:ColumnGroup[@Usage='INCLUDE']
//sp:Warnings[@UnmatchedIndexes='1']
```

Interpretation rules:

- Equality columns usually precede inequality columns in candidate keys.
- INCLUDE suggestions may be overly broad; verify selected columns and lookup cost.
- Missing-index impact is compile-time and statement-local.
- Merge overlapping suggestions with existing indexes before recommending DDL.
- `UnmatchedIndexes` can indicate filtered indexes not considered because query predicates do not imply the filter or parameters obscure it.

## Operator-Specific Cost Interpretation

| Operator | What to inspect | Common causes |
|---|---|---|
| Nested Loops | Outer rows, inner executions, lookup count | Good for small outer input; bad when estimates understate repetitions. |
| Hash Match | build/probe sizes, spills, memory grant | Missing useful order/index, large joins, poor estimates. |
| Merge Join | sorted inputs, many-to-many flag, residual predicate | Good with ordered inputs; sort cost may dominate. |
| Sort | rows, memory grant, spills, order requirement | Missing order-compatible index, wide rows, underestimated rows. |
| Key/RID Lookup | executions and output columns | Missing covering columns; may be acceptable for few rows. |
| Spool | eager/lazy type, rewinds/rebinds | Halloween protection, repeated work, optimizer workaround. |
| Compute Scalar | scalar string | Harmless projection or expensive/conversion expression. |
| Parallelism | repartition/gather streams | Skew, exchange cost, MAXDOP/cost threshold issues. |
| Remote Query | remote SQL text, row counts | Linked-server pushdown failure or row-by-row local joins. |

## Evidence Snippet Format

When reporting, quote compact facts rather than dumping XML:

```text
Node 17 Index Seek on Sales.IX_Sales_CustomerDate:
- EstimatedRows=42, ActualRows=18, ActualRowsRead=2,410,000, ActualExecutions=1
- SeekPredicates: CustomerID = @CustomerID
- Residual Predicate: CONVERT_IMPLICIT(date, OrderDateTime) = @OrderDate
- Finding: seek navigates only CustomerID, then scans that customer's history due to date conversion.
```
