# An ADR IS backfillable — shared checklist

The positive companion to `adr-is-not.md`. That file enforces what an ADR must not become. **This file enforces when a past, unrecorded decision is eligible to be retroactively written up as an ADR.** Referenced only by the `adr-backfill` skill — keep `adr-is-not.md` polarised toward negative enforcement; positive backfill criteria live here.

A backfill claims authority over a decision no one documented in real time. The criteria below exist because a fabricated rationale is worse than no ADR.

---

## 1. The decision was actually made

A decision was made if **the system today is observably different** from what it would be without the decision. Evidence: a migration that landed, a vendor that was removed, a subsystem that was deleted, a policy that was unified across services, a module that was deprecated.

If the only evidence is a Slack thread where someone said "we should probably do X someday," there was no decision — there was a thought. Do not backfill.

## 2. The decision was architecturally significant (the ASR test)

Apply the same ASR test used during forward drafting: did the change have a **measurable effect on architecture or quality** (latency, cost, availability, security, maintainability, operability, portability)?

| Eligible | Not eligible |
|---|---|
| Migrated the primary store from one engine to another. | Renamed a function across the codebase. |
| Retired a vendor dependency and replaced it with an in-house service. | Bumped a library minor version. |
| Unified the auth model across three services. | Reformatted a config file. |
| Removed a deprecated module that 40 callers had depended on. | Fixed a typo in a doc. |

If the change is not architecturally significant, an ADR is the wrong tool — and a *backfilled* ADR is the wrong tool twice over.

## 3. Evidence appears in at least two independent locations

The false-positive guard. One artifact can be a coincidence; two converging artifacts are a decision.

Eligible pairs include any two of:

- A commit SHA whose message names the change.
- A migration file (DB schema, infra-as-code, config) that implements the change.
- A removed module / subsystem / package path.
- A vendor entry removed from manifests (`package.json`, `requirements.txt`, `go.mod`, lockfile, IaC vendor block).
- A retired feature flag whose removal commit implements the change.
- A deprecation note removed because the deprecation finished.
- A CI / fitness-function rule added to keep the change from regressing.

A single commit message, by itself, is **not** enough. A single mention in a chat log, by itself, is **not** enough.

## 4. The architectural characteristic affected can be named with a measurable signal

The ASR test demands a measurable effect. "Felt cleaner" is not measurable. "Improved developer experience" is not measurable. A measurable signal looks like:

- *"Removed 14k LOC and one vendor dependency"* — maintainability.
- *"Cut p95 cold start from 1.2s to 380ms"* — latency.
- *"Eliminated a $2.4k / month vendor line item"* — cost.
- *"Reduced on-call paging from three services to one"* — operability.

If no measurable signal can be named, the decision is either too small to backfill or too poorly evidenced to backfill honestly. Drop to `open-questions.md`.

## 5. The decision is not already recorded

Glob the decision log before drafting. If an existing ADR — even an old, badly written one — already covers the decision, the right move is `adr-critique` against the existing record, not a parallel backfill. Two records of the same decision is a duplicate-authority failure mode.

## 6. Reconstruction confidence is at least `medium`

A backfill ADR is the *what*, the *why*, and at least one realistic *what-else-we-could-have-done*. If only the *what* is recoverable from evidence, the rationale would have to be fabricated. Fabricated rationale is worse than no record.

| Confidence | Eligible? |
|---|---|
| `high` — decision, forces, and at least one realistic alternative all reconstructible from evidence. | Yes. |
| `medium` — decision is clear, forces are partial, alternatives are partial. Draft with the honesty clause; mark gaps as `unrecoverable` rather than inventing. | Yes. |
| `low` — only the *what* is recoverable; the *why* would have to be fabricated. | **No.** Route to `open-questions.md` with the evidence that would have to surface to upgrade confidence. |

## 7. The decider can be identified — or explicitly marked unrecoverable

Forward-drafted ADRs require a named human decider. Backfill ADRs require either a named human (from commit author / PR reviewer / explicit attribution) or an **explicit `unrecoverable` marker**. Never fabricate a decider. "The team" is not a value here either — but `unrecoverable` is honest and acceptable.

---

## Quick eligibility self-check before drafting a backfill ADR

Run these in order. Stop at the first failure.

1. Is there observable evidence in the system today that the decision was made? → no, stop.
2. Does the change pass the ASR test (measurable effect on architecture or quality)? → no, stop.
3. Is the evidence in at least two independent locations? → no, stop.
4. Can the architectural characteristic be named with a measurable signal? → no, drop to `open-questions.md`.
5. Is there *not* already an ADR covering this decision? → no, route to `adr-critique` instead.
6. Is `reconstruction-confidence` at least `medium`? → no, drop to `open-questions.md`.
7. Can the decider be named, or explicitly marked `unrecoverable`? → no — refuse to draft until the user resolves it.

If all seven pass, the backfill is eligible. Proceed to the `adr-backfill` skill's phase flow.
