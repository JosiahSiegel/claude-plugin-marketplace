# Assumption Tracker

Use this protocol during SQL Server optimization sessions to separate proven facts from guesses. Every recommendation that depends on unknown schema, data distribution, constraints, or operational permissions must name the assumption and its status.

## Status Values

| Status | Meaning | Required action |
|---|---|---|
| `verified` | Confirmed by DDL, execution plan, DMV output, constraints, data sample, or user statement. | Use as evidence; cite source briefly. |
| `unverified` | Plausible but not proven. | Phrase recommendations conditionally and ask for proof. |
| `disproved` | Evidence contradicts the assumption. | Remove dependent recommendation or explain why it changed. |
| `needs diagnostic` | Cannot be verified from current artifacts and requires a specific query, plan, or measurement. | Provide the diagnostic and expected interpretation. |

## Tracking Protocol

1. Start an assumption table for any non-trivial optimization task.
2. Convert assumptions to verified or disproved as evidence arrives.
3. Do not let disproved assumptions remain in the recommendation path.
4. Tie each proposed rewrite, hint, or index to the assumptions it requires.
5. Prefer diagnostics over speculation when a change could be expensive or risky.

## Common Optimization Assumptions

| Assumption | Typical proof |
|---|---|
| A join does not filter rows | Count comparison before/after join; trusted FK; uniqueness proof. |
| A join does not multiply rows | Unique index or grouped duplicate check on join key. |
| A predicate is selective | Histogram, filtered count, actual plan row counts. |
| A seek is possible | Matching data types, SARGable predicate, useful leading index key. |
| Partition elimination occurs | Actual partitions accessed or partition range evidence. |
| Temp table types match source types | Temp-table DDL compared with source metadata. |
| Missing-index request is useful | Existing-index comparison plus workload and write-cost review. |
| Linked-server predicate is pushed down | Remote query text and rows returned from remote source. |

## Example Session Tracking

```text
Assumptions:
1. Customer.CustomerID is unique.
   Status: verified.
   Evidence: PK_Customer clustered primary key on CustomerID.

2. Joining Customer only adds no selected columns and does not filter Orders.
   Status: needs diagnostic.
   Diagnostic: compare COUNT_BIG(*) from Orders to Orders JOIN Customer, and check trusted FK.

3. #OrderKeys.CustomerID matches Orders.CustomerID type.
   Status: disproved.
   Evidence: #OrderKeys.CustomerID is nvarchar(50); Orders.CustomerID is int. Rewrite must fix temp table type before evaluating index changes.

4. Date predicate eliminates partitions.
   Status: unverified.
   Evidence needed: actual plan partition access or partition function boundaries.
```

When reporting final guidance, include only recommendations whose supporting assumptions are verified or clearly label remaining risk.
