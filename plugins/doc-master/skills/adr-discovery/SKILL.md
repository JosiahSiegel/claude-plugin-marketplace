---
name: adr-discovery
description: |
  This skill should be used before drafting an ADR when context, components, relationships, deciders, or prior decisions are unclear.
  PROACTIVELY activate on "I want to write an ADR for X", "gather context for a decision", "discovery for an ADR", "ADR intake", "ADR pre-flight", "prep work before an ADR", "what's the current architecture?", or "set up a decision log."
  Provides: zero-hallucination Q&A, human-confirmed discovery brief, open-questions register, and five required confirmations before drafting.
---

# adr-discovery

Pre-flight context gathering for an ADR. The output is a `docs/architecture/discovery-brief.md` containing only human-confirmed facts, plus a `docs/architecture/open-questions.md` register of unknowns. The architect then hands off to `adr-drafting` to actually draft the decision.

## Core rule: zero hallucination

No fact enters the discovery brief until the architect says yes. Code findings, doc findings, and inferences are all presented as **questions**, never as assertions.

| Wrong | Right |
|---|---|
| "Your system uses Postgres and Redis." | "I see `pg` and `ioredis` in `package.json`. Is Postgres your primary store? (yes / no / unsure)" |
| "Component A talks to component B." | "I see a fetch from A to B in `src/a/client.ts`. Does A depend on B? (yes / no)" |

Every confirmed fact is dated and tagged in the brief: `[CONFIRMED YYYY-MM-DD]`. Unconfirmed code findings get `[FROM CODE, UNCONFIRMED YYYY-MM-DD]` and live in `open-questions.md`, not the brief.

## Fact states

| State | Where it lives | Allowed to drive a decision? |
|---|---|---|
| `CONFIRMED` | `discovery-brief.md` | Yes |
| `FROM CODE, UNCONFIRMED` | `open-questions.md` | No |
| `UNKNOWN` | `open-questions.md` | No |
| `PARKED` | `open-questions.md` (with reason) | No — must be noted in ADR Consequences |

## Vocabulary (define on first use)

- **Component** — a runnable / deployable unit (C4 *Container*). Not a code class.
- **System** — the one bounded product in focus for this ADR. Exactly one.
- **External system** — a system the team does not own but interacts with.
- **Actor** — a human role (Person in C4 terms).
- **Architectural characteristic** — the non-functional quality under pressure (latency, cost, maintainability, availability, security posture, etc.).
- **Tension** — two ADRs that conflict without one superseding the other. A tension is a fact, not a failure; it must be acknowledged.
- **RFC** — a proposal-stage doc. ADRs are for decisions already made.

## Style

- One topic at a time. Never ask two questions in one turn.
- Restate the architect's answer in your own words before recording it.
- Direct. Skip "Great question!", "Excellent!", and other affirmations.
- Name specific files, tech, and components — never vague nouns ("the service," "the database").
- If a turn would contain more than one `?` or run more than a short paragraph, shorten it.

## The nine phases

### 1. Scan, don't summarize

Glob the repo for signals — never assert what you find.

- ADR directories: `docs/adr/`, `docs/decisions/`, `docs/architecture/decisions/`, `**/adr/*.md`; also check legacy `architecture/decisions/` and warn it may need custom ADR Explorer root configuration
- Manifests: `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `pom.xml`, `*.csproj`
- READMEs at the repo root and one level down
- LikeC4 files: `**/*.c4`, `likec4.config.*`
- Existing `discovery-brief.md` / `open-questions.md`

Report **raw findings only**: "I found these files: X, Y, Z. I have not interpreted them yet." Then ask: "Should I walk through them with you one at a time, or do you want to start from a clean slate?"

Optionally offer **live diagram mode** — see `references/live-diagram-mode.md` — but only after the architect opts in.

### 2. Confirm domain

Ask exactly one question: *"What does this system do, and for whom?"*

Wait for an answer. Restate. Confirm. Then write a single `Domain:` line to the brief.

### 3. Confirm components one at a time

Define **Component** (a C4 Container — a deployable unit). Then walk candidates one by one. For each:

1. State the candidate name as you found it (in the manifest, the README, the LikeC4 file, or the architect's words).
2. Ask: "Is this a component in scope for this decision? (yes / no / out of scope)"
3. If yes: ask for a one-line description in the architect's words.
4. If no: drop it.
5. Hard limit: **5 components**. If the architect names a 6th, ask whether the decision is bundled.

### 4. Confirm relationships with human-written descriptions

For each confirmed component pair, ask: "Does A depend on B? If yes, in one line, what does A use B for?"

A relationship without a human-written description does not enter the brief. "A talks to B" is not a description.

### 5. Confirm existing ADRs

Glob the ADR directory. For each ADR, ask one of:

- *Supersedes?* — does this new decision replace this prior one?
- *Amends?* — does it adjust without replacing?
- *Relates-to?* — does it share context but stand alone?
- *Tension?* — does it conflict, with neither superseding?
- *Unrelated?* — drop it.

Only the architect's answer enters the brief. Inference does not.

### 6. Multi-repo + ecosystem probe

Many decisions cross repo boundaries. Ask per related repo:

- Role (consumer / producer / shared library / platform)
- Owner (named team or person)
- Access (read / write / no access)
- Existing ADRs in that repo
- Existing C4 / architecture diagrams

Beyond repos, ask whether the org has:

- A wiki / Backstage / TechRadar / platform-level ADR set
- Compliance constraints (data residency, SOC2, HIPAA, GDPR, FedRAMP) that bind the decision
- A platform team whose decisions the architect inherits

### 7. Checklist gate

Before hand-off, all five MUSTs must be `CONFIRMED`:

| MUST | Confirmed when… |
|---|---|
| Domain | Architect has stated what the system does and for whom |
| Architectural characteristic under pressure | Architect named the quality being optimized (latency / cost / availability / etc.) and the specific number or condition forcing the decision |
| ≤5 components in scope | Architect confirmed each by name, with a one-line description |
| Related ADRs classified | Each existing ADR classified or explicitly dropped |
| Named decision-maker | Specific human(s) — not "the team," not "leadership" |

If any MUST is `UNKNOWN` or `PARKED`, the skill refuses to advance and routes to `open-questions.md`.

### 8. C4 handoff (optional)

If the architect wants a diagram before drafting, hand off to `c4-model` (canonical C4: Context + Container views only). Skip if they don't.

### 9. Handoff to drafting

When all five MUSTs are confirmed, write a one-line summary at the bottom of `discovery-brief.md`:

```text
Discovery complete: 2026-05-20. Hand off to adr-drafting.
```

The drafting skill reads the brief and does not re-ask anything in it.

## Living files (kept deliberately outside ADR-parsed directories)

`docs/architecture/discovery-brief.md` and `docs/architecture/open-questions.md` are intentionally **not** under `docs/adr/`, so ADR-parser tools and indexes don't mistake them for ADRs.

### `discovery-brief.md` shape

```md
# Discovery Brief

## Domain
[CONFIRMED 2026-05-20] One sentence -- what does the system do, for whom.

## System in focus
[CONFIRMED 2026-05-20] Single named system.

## Architectural characteristic under pressure
[CONFIRMED 2026-05-20] e.g., "p95 read latency < 200ms on cross-entity reports."

## Components in scope (≤5)
[CONFIRMED 2026-05-20] - Name -- one-line description (architect's words)
...

## Relationships
[CONFIRMED 2026-05-20] - A → B: A uses B to <verb phrase>
...

## External actors
[CONFIRMED 2026-05-20] - Role -- one-line description
...

## Existing ADRs in play
[CONFIRMED 2026-05-20] - 0007 -- supersedes / amends / relates-to / tension

## Repos in play
[CONFIRMED 2026-05-20] - repo: role / owner / access / ADRs / C4

## Ecosystem constraints
[CONFIRMED 2026-05-20] - Compliance, platform, wiki/Backstage hits

## Decision-makers
[CONFIRMED 2026-05-20] - Named human(s)

---
Discovery complete: 2026-05-20. Hand off to adr-drafting.
```

### `open-questions.md` shape — see `references/open-questions-register.md` for the full schema.

## The "ADR IS NOT" rules apply here too

Even during discovery, do not tutorialize, hedge, or invent. See `../_shared/adr-is-not.md` for the shared checklist.

## References

- `references/live-diagram-mode.md` — opt-in LikeC4 live-diagram workflow during discovery
- `references/open-questions-register.md` — schema and discipline for `open-questions.md`
- `../_shared/adr-is-not.md` — shared "ADR is not" checklist
