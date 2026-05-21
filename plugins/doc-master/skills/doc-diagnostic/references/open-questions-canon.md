# Open-questions register canon

The canonical reference for an **open-questions register** as a standalone documentation form. Load this when the user says "we're not ready to decide yet," "park this for later," "what should I do with the things we don't know?", or "where do unresolved architectural questions go?"

An open-questions register is a **scoped, owned, dated list of unknowns** that block or qualify future decisions. It is the **legitimate alternative to a premature ADR** — when a team feels pressure to "write something down" before the decision is actually made, the register is where that pressure should land.

## Why this is not an ADR

An ADR captures a **made decision and its rationale**. An open question by definition has neither — it has a *question* and (at best) candidate answers awaiting evidence. Putting open questions in the ADR log:

- Pollutes the decision graph with non-decisions.
- Creates ADRs that sit in `status: proposed` for months.
- Mixes "what did we decide" with "what are we still figuring out," which confuses every reader.

The register keeps unknowns visible without converting them into decisions they are not.

## File location

- Single file, in the architecture area but **outside** the ADR directory the parsers walk:
  - Default: `docs/architecture/open-questions.md`.
  - Alternative: `docs/decisions/open-questions.md` if the project uses `docs/decisions/` for ADRs — keep the file at the *parent* of the ADR directory, not inside it.
- One register per system / product area. Do not maintain one register per team — too many registers means none of them are read.

The register is intentionally **one level up** from the ADR globs so ADR Explorer / ADR Manager / `validate_adrs.py` do not try to parse it as an ADR.

## Distinction from `adr-discovery`'s `open-questions-register.md`

doc-master has two related artifacts:

| Artifact                                                                       | Scope                                                                | Owner                  | Lifecycle                                              |
|--------------------------------------------------------------------------------|----------------------------------------------------------------------|------------------------|--------------------------------------------------------|
| **This canon** (`open-questions-canon.md`) — the standalone register form.     | Anything the team is consciously deferring or actively researching.  | The project / team.    | Lives indefinitely; sweeps quarterly.                  |
| **`adr-discovery/references/open-questions-register.md`** — the discovery subset. | Unknowns surfaced specifically during a single ADR's pre-flight Q&A.| The drafting architect.| Tied to the ADR; questions resolve before drafting.    |

The discovery file is a focused subset; this canon is the long-lived home. Discovery questions that survive past their ADR (because the team chose to ship the ADR with the question PARKED) graduate into the standalone register here.

## Required columns per row

Each row of the register answers six questions. Missing any one of these and the row is too vague to act on.

| Column                  | What it answers                                                                                                |
|-------------------------|----------------------------------------------------------------------------------------------------------------|
| **Question**            | The unknown, phrased as a question. ("Should we shard the user table?" — not "Sharding.")                      |
| **Decision needed by**  | A concrete date or measurable trigger. ("When DAU exceeds 50k," "by 2026-09-01," "before the Q4 migration.")   |
| **Blocker for**         | What downstream work this question is gating. Without a blocker, the question is academic.                     |
| **Current best guess**  | The team's working hypothesis, with a confidence note (`low`, `medium`, `high`). Not a commitment.             |
| **Measurement plan**    | What evidence would resolve the question. The specific dashboard, the specific experiment, the specific call.  |
| **Owner**               | A named human (not "the team"). The person accountable for moving this row forward.                            |

Optional columns:

- **Raised** — ISO 8601 date the question was added.
- **Related ADRs** — IDs of ADRs this question relates to (e.g., it qualifies an existing ADR, or will produce a new one).
- **Status** — `OPEN`, `ANSWERED`, `PARKED` (matches the discovery file's vocabulary).

## Graduation rule

When the **Measurement plan** produces evidence, the row graduates — it does not stay open forever.

- If the resolved question is **architecturally significant** (an ASR — passes the ASR test in `SKILL.md`): **promote to an ADR**. The register row gets marked `ANSWERED` with the date and a link to the new ADR.
- If the question turned out to **not** be architecturally significant (a coding convention, a settled-elsewhere policy, a reversible UX detail): **close** the row and route the answer to the correct alternative form via `alternatives-catalog.md`.
- If the team decides to **ship with the question unresolved**: mark the row `PARKED`, cite it in the relevant ADR's Consequences section, and add a re-evaluation trigger.

The graduation rule is what keeps the register from becoming a dead list.

## Canonical example

```md
# Open Questions -- Architecture

This file tracks unknowns that block or qualify upcoming architectural decisions.
Each row is owned by a named human and has a measurement plan.

| ID  | Question                                                | Decision needed by         | Blocker for                  | Current best guess (confidence)              | Measurement plan                                                                | Owner   | Status  |
|-----|---------------------------------------------------------|----------------------------|------------------------------|----------------------------------------------|---------------------------------------------------------------------------------|---------|---------|
| Q12 | Should we shard the user table?                         | When DAU > 50k             | ADR-0016 (Postgres adoption) | Yes, by tenant ID (medium)                   | Run a load test at 75k synthetic users on the staging Postgres; record p95.    | Priya   | OPEN    |
| Q14 | Multi-region read replicas -- needed for EU launch?    | 2026-08-15                 | ADR-0019 (regional routing)  | Yes (high) -- latency requirement is firm.   | Confirm latency budget with product; benchmark cross-region replication.       | Marcus  | OPEN    |
| Q07 | Will the queue handle 10x peak?                         | Resolved 2026-04-12        | (none)                       | Yes -- confirmed by load test on 2026-04-10. | Load test result: p99 < 200ms at 12x peak. Logged in test-run-2026-04-10.json. | Priya   | ANSWERED|
```

When `Q07` was answered, the team did not write an ADR — the answer ("yes, the queue handles 10x") is a measurement, not a decision. Had the team *chosen* to oversize the queue based on that measurement, that choice would be the ADR.

## Common failure modes

| Failure                                                | Symptom                                                                                | Remedy                                                                                |
|--------------------------------------------------------|----------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------|
| Orphan questions                                       | A question with no owner, no measurement plan, no decision-by date.                    | Refuse to add it. Push back to the requester until those are filled.                  |
| Eternal `OPEN` rows                                    | Rows with `Decision needed by` dates in the past, still marked `OPEN`.                 | Sweep quarterly. Re-date or escalate or PARK.                                         |
| The register becomes a TODO list                       | Implementation tasks creep in ("upgrade Redis to 7.2").                                | Implementation tasks belong in the issue tracker. The register is for *open questions*.|
| Resolved questions never graduate                      | `ANSWERED` accumulates; no resulting ADRs.                                             | The graduation rule is the point. If nothing graduates, the register is bookkeeping.  |
| One register per team                                  | Five registers, none of them comprehensive, none of them read.                         | One register per system / product area, owned at the architecture level.              |

## Routing — when this is not the answer

- "We've decided X" → **ADR**, not the register.
- "We've decided not to decide yet, and we've identified the trigger that will force the decision" → register row with a clear `Decision needed by`.
- "We don't know how to do X right now and don't intend to decide soon" → **`SUPPORT.md` / FAQ / Discussions** if it's user-facing; **issue tracker** if it's implementation.
- "We've decided to ship with this question unresolved" → ADR with the question PARKED in Consequences, plus a register row tracking the PARKED state and re-evaluation trigger.
