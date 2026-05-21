---
name: adr-backfill
description: |
  This skill should be used to retroactively record an architectural decision that was made in the past but never written up as an ADR — typically surfaced by a doc audit or by a user realising a long-ago shipped change should have been documented.
  PROACTIVELY activate on "backfill ADR", "retroactive ADR", "post-hoc ADR", "reconstruct an ADR from history", "write up a past decision", "we never documented this decision", "decision was made but no ADR exists", "we decided years ago", "back when", "before my time", or "the audit surfaced a backfill candidate."
  Tense rule: `adr-drafting` claims "we decided / we're deciding"; `adr-backfill` claims "we decided years ago / back when / before my time / never wrote it down." Refuses when reconstruction confidence is `low` -- routes to `open-questions.md`. Requires evidence in two independent locations and a verbatim honesty clause in the record.
  Provides: backfill ADR template, confidence rubric, evidence corroboration, honesty-clause boilerplate.
---

# adr-backfill

Retroactively records a past architectural decision that was made but never documented. Surfaces typically come from `/doc-audit` `BACKFILL-ADR` rows or from a user who realises a past change should have been an ADR. Operates with relaxed gates relative to `adr-drafting` (the decider may be unrecoverable, alternatives may not be reconstructible) but enforces stricter honesty: a backfill ADR must visibly mark itself as a backfill so future readers do not mistake it for a contemporaneous record.

## When to use this skill

- `/doc-audit` surfaced a `BACKFILL-ADR` candidate row and the user wants to record it.
- The user describes a decision in past tense — *"we decided years ago,"* *"back when,"* *"before my time,"* *"we never wrote it down"* — about a change whose effects are visible in the codebase today.
- A code-archaeology session uncovered a migration, vendor removal, or subsystem retirement with no corresponding decision record.

## When NOT to use this skill

- The decision is current or in-flight — use `adr-drafting` instead.
- The decision is already recorded in any form — use `adr-critique` to tighten the existing record.
- `reconstruction-confidence` is `low` (only the *what* is recoverable, not the *why*) — refuse to draft and route to `open-questions.md`.
- The change is not architecturally significant — see `_shared/adr-is-backfillable.md` § 2. Route via the alternatives catalog in `doc-diagnostic`.

## Inputs

- **Required:** at least two independent evidence locators (see `_shared/adr-is-backfillable.md` § 3). Examples: commit SHA + migration file, migration file + removed manifest entry, removed module + retired feature-flag commit.
- **Required:** a measurable signal for the architectural characteristic affected (see `_shared/adr-is-backfillable.md` § 4).
- **Optional:** a `BACKFILL-ADR` row from `/doc-audit` containing the proposed `decision`, `evidence-locator`, `ASR-test-result`, `reconstruction-confidence`, and `suggested-status` fields. If present, use it as the starting brief.

## Refusal behaviors

The skill **refuses to draft** when:

- The eligibility self-check in `_shared/adr-is-backfillable.md` fails any of items 1-3 or 5 (no evidence, no ASR significance, single-locator evidence, or already recorded).
- `reconstruction-confidence` is `low` — the *why* would have to be fabricated. Route to `open-questions.md`.
- No measurable signal can be named for the architectural characteristic affected.
- The user wants the backfill ADR to look like a contemporaneous record (no honesty clause). The clause is non-negotiable.

## Core operating rule

**Never emit more than one question or one step per message.** Inherits the one-question-per-turn discipline from `adr-drafting`. Backfill is at least as easy to over-stuff as forward drafting; tighter discipline, not looser.

## The four phases

### Phase 1 — Eligibility and evidence

Run the seven-item eligibility self-check from `_shared/adr-is-backfillable.md` against the candidate. Walk it one item at a time. If any item fails, stop:

- Items 1-3 or 5 failing → refuse to draft, explain which evidence is missing.
- Item 4 failing (no measurable signal) → drop to `open-questions.md`.
- Item 6 failing (confidence `low`) → drop to `open-questions.md` with the evidence that would upgrade it.
- Item 7 failing (decider not nameable and not yet marked `unrecoverable`) → ask once whether to use the `unrecoverable` marker or to keep digging.

Confirm the two-locator evidence in dialogue — quote the locators back to the user so they can correct a mistaken artifact. Do not proceed to Phase 2 until the user agrees the evidence is right.

### Phase 2 — Historical context reconstruction (best effort)

For each section of the ADR, gather what can be reconstructed and **mark gaps explicitly** rather than papering over them.

| Section | Reconstruction approach |
|---|---|
| Context (the forces) | Read commit messages, PR descriptions, ticket links, removed README content, retired runbooks. Cite each source. If the forces cannot be reconstructed, write *"Forces at the time of the decision could not be reconstructed from available evidence."* — do not invent. |
| Decision | The *what* — almost always reconstructible from the shipped change. Stated in present-tense active voice, same as a forward ADR. |
| Alternatives | Often the hardest to recover. If the original alternatives are visible in PR review comments, commit history, or contemporary RFCs, cite them. If not, the honesty clause covers the gap. |
| Consequences (Good / Bad) | Reconstruct from observable effects in the codebase today. *"Removed 14k LOC"* is observable; *"Improved developer morale"* is not. |
| Decider | Named human(s) from commit author / PR reviewer / explicit attribution, OR the literal token `unrecoverable`. Never fabricate. |

### Phase 3 — Draft with honesty clause (MANDATORY)

Every backfill ADR must contain a verbatim honesty clause near the top of the body (after the title, before Context). The verbatim form, required fields, terminal punctuation, and refusal conditions live in `references/honesty-clause.md` — read it before drafting.

The clause exists so a future reader cannot mistake the backfill for a contemporaneous record. Removing or softening it is a critique-flag (see `adr-critique` audit checklist).

### Phase 4 — Save

Same save discipline as `adr-drafting`:

1. Glob ADR Explorer-friendly directories first (`docs/adr/`, `docs/decisions/`, `docs/architecture/decisions/`, `**/adr/*.md`); also check legacy `architecture/decisions/` but warn it may need custom ADR Explorer root configuration. Use the first existing directory; if none, create `docs/adr/`.
2. Auto-number: read existing ADRs, take `max+1`, zero-pad to 4 digits. **The backfill ADR takes the next available number, not a number from the past.** Numbering reflects creation order, not decision order. The original decision date appears inside the file (see frontmatter); the number is just-now.
3. Filename: `NNNN-kebab-imperative-title.md`.
4. Write the file with the honesty clause and the backfill-specific frontmatter (see template below).
5. Update the decision-log `README.md` index, marking the row with `(backfilled YYYY-MM-DD)`.

## Backfill-specific frontmatter

```yaml
---
title: "<imperative verb phrase>"
status: accepted                   # or deprecated if reversed; keep status ADR Explorer-compatible
date: <original decision date if known, else first-evidence date in ISO 8601>
backfilled-on: YYYY-MM-DD          # today
deciders:
  - <named human, or unrecoverable>
evidence:                          # at least two locators
  - <commit SHA / file path / manifest line>
  - <commit SHA / file path / manifest line>
reconstruction-confidence: high | medium
asr-characteristic: <latency | cost | availability | security | maintainability | operability | portability | ...>
asr-signal: "<measurable signal -- e.g., removed 14k LOC and one vendor dependency>"
tags: [backfill]
---
```

If the decision has since been reversed by a later shipped change, set `status: deprecated` and cite the reversing commit / migration in `evidence:` plus the honesty clause or notes. The backfill still gets recorded — the historical decision matters even after reversal — but the status remains ADR Explorer-compatible.

## Status conventions

| Status | Use when… |
|---|---|
| `accepted` | The decision is still in force today. Default. |
| `deprecated` | A later shipped change undid the original decision. Cite the reversing evidence. |

Backfill ADRs never use `proposed` or `rfc` — a backfill is, by definition, a recording of a decision that was already shipped. Keep backfill identity in `tags: [backfill]`, `backfilled-on`, evidence fields, and the mandatory honesty clause; do not encode it in `status`.

## Refusal: when the user wants the honesty clause removed

The honesty clause is the single non-negotiable element of a backfill ADR. If the user asks to remove it, soften it, or hide it in a footnote, refuse. Explain that a backfill without the clause looks like a contemporaneous record and silently poisons the decision log — a future reader has no way to tell the rationale was reconstructed rather than recorded in the moment. The clause stays in the body.

`adr-critique` enforces this independently: a record with `tags: [backfill]` or `backfilled-on` whose body lacks the honesty clause is a flag in the audit checklist.

## Hand-off

`adr-backfill` does **not** chain automatically to other skills. After the backfill record is saved, the user may choose to:

- Run `adr-critique` against the new record to tighten language (especially if `reconstruction-confidence` was `medium`).
- Run `c4-model` to add a Context / Container view that reflects the post-decision system shape (optional).
- Update `open-questions.md` to close out any locked questions the backfill resolved.

None of these are forced. Soft hand-off via skill triggers only.

## References

- `references/honesty-clause.md` — the canonical spec for the Phase 3 honesty clause (form, required fields, terminal punctuation, refusal conditions). Single source of truth; `adr-critique` reads the same file.
- `../_shared/adr-is-backfillable.md` — the seven-item eligibility self-check (used in Phase 1)
- `../_shared/adr-is-not.md` — applies to backfill ADRs the same as forward ADRs (no tutorial, no implementation guide, no marketing, no hedging, no long-form padding)
- `../doc-diagnostic/references/audit-procedure.md` — defines the `BACKFILL-ADR` row schema that feeds this skill
- `adr-drafting` skill — the forward-drafting counterpart for in-the-moment decisions
- `adr-critique` skill — for tightening the saved backfill record afterwards
- `doc-diagnostic` skill — for the ASR definition and the alternatives catalog
