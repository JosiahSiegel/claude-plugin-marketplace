# The backfill honesty clause — canonical spec

The single source of truth for the mandatory honesty clause that every backfill ADR must contain. `adr-backfill` writes the clause during Phase 3; `adr-critique` audits records that should have one. Both skills point here rather than restating the clause. Update this file when the form changes; do not duplicate.

## Why this clause exists

A backfill ADR is, by construction, written after the fact. Without an explicit mark, a future reader cannot distinguish a reconstructed rationale from a contemporaneous record — and silently treating reconstruction as recording poisons the decision log. The clause is the load-bearing honesty marker. Removing or softening it is a refusal trigger for `adr-backfill` and a flag for `adr-critique`.

## Required form (verbatim)

The clause appears near the top of the ADR body, after the title and before Context. The literal form:

```text
**Backfill notice.** Recorded YYYY-MM-DD from <evidence locators>; original decider <named human(s) or "unrecoverable">. Alternatives could not be reconstructed at backfill time<, except <list> if partially recoverable>.
```

## Required fields

Three are mandatory, one is conditional.

| Field | Required? | Notes |
|---|---|---|
| `Recorded YYYY-MM-DD` | Yes | The backfill date (today, when the record is written), not the original decision date. ISO 8601 only. |
| `<evidence locators>` | Yes | At least two independent locators from the Phase 1 evidence set (see `_shared/adr-is-backfillable.md` section 3). |
| `<original decider>` | Yes | Named human(s) from commit author / PR reviewer / explicit attribution, OR the literal token `unrecoverable`. Never `the team`. Never fabricated. |
| `<except list>` | Conditional | Only when alternatives are partially reconstructible from PR comments, RFCs, or commit history. Otherwise the sentence terminates after `at backfill time.` (note the terminal period — see "Terminal punctuation" below). |

## Terminal punctuation (non-negotiable)

The clause ends with a literal period (`.`). The two valid terminations are:

- No reconstructible alternatives — ends with `... at backfill time.`
- Partially reconstructible alternatives — ends with `... at backfill time, except <list>.`

A clause that elides the terminal period (ends with `at backfill time` with no period, or trails into the next sentence without one) is non-compliant. `adr-critique` flags missing terminal punctuation. The period is part of the verbatim form, not a stylistic suggestion.

## Refusal: when the user wants the clause removed or softened

The clause is the single non-negotiable element of a backfill ADR. If the user asks to remove it, soften it, paraphrase it into past-tense narrative, hide it in a footnote, or elide any required field, refuse. The reason: a backfill without the clause looks indistinguishable from a contemporaneous record, and a future reader has no way to tell the rationale was reconstructed rather than recorded in the moment.

`adr-critique` enforces this independently. A record whose `tags:` contains `backfill` or whose frontmatter has `backfilled-on` but whose body lacks a compliant clause is a flag in the audit checklist. Older records that encode backfill text in `status` should be migrated to ADR Explorer-compatible `status: accepted` or `status: deprecated` without softening this clause. The audit routes back to `adr-backfill` for a redraft rather than patching the file in place.

## Where this clause is referenced

- `skills/adr-backfill/SKILL.md` Phase 3 — drafts the clause during backfill.
- `skills/adr-critique/references/audit-checklist.md` "Backfill ADRs" section — audits for the clause's presence, completeness, terminal punctuation, and softening.

These are the only two call sites by design. Adding a third would re-introduce the duplication this file exists to eliminate.
