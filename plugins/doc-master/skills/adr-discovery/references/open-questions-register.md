# `open-questions.md` — schema and discipline

The open-questions register lives at `docs/architecture/open-questions.md`, deliberately outside any directory an ADR parser walks. It is the single home for unknowns that surface during discovery, drafting, or critique.

## Why a separate file

- Unknowns are not decisions; they should not pollute the ADR log.
- Unknowns have lifecycles (open → answered / parked) and owners — they deserve a register, not a scattered set of TODO comments.
- ADR-parser tooling typically globs `docs/adr/**` or `docs/architecture/decisions/**`; placing the register one level up keeps tooling honest.

## Entry shape

Each entry is a short numbered block:

```md
## Q12 -- Should we run Postgres single-region or multi-region?

- **Status:** OPEN
- **Why it matters:** ASR-7 requires read latency < 50ms p95 for EU users; single-region from us-east-1 is ~110ms.
- **Where to look:** existing RDS dashboard (cloudwatch/rds-latency), product roadmap on EU expansion, finance for cross-region transfer cost.
- **Who to ask:** Priya (Platform), Marcus (Finance), product owner for EU launch.
- **Raised:** 2026-05-20 during discovery for ADR-0016 (Postgres adoption).
- **Related ADR:** 0016 (proposed).
```

## Allowed statuses

| Status | Meaning |
|---|---|
| `OPEN` | Unanswered; blocks any ADR that depends on it. |
| `ANSWERED` | Resolved; the answer must be inlined here with a date, then promoted into the discovery brief or ADR Consequences. |
| `PARKED` | Deliberately deferred — the team has agreed to ship the decision with this unknown unaddressed. Must be cited in the resulting ADR's Consequences section. |

## Rules

1. **No orphan questions.** Every entry has `Why it matters`, `Where to look`, `Who to ask`. Without these, the entry is too vague to act on.
2. **No silent edits.** When a question moves to `ANSWERED`, append the answer with a date — do not overwrite the original.
3. **No drift into ADR territory.** If an entry starts to resemble a decision ("We will probably use X"), it has matured into an ADR proposal; move it.
4. **No bulk delete.** Cleanup of `ANSWERED` entries happens in scheduled sweeps with the team's awareness, not silently.

## Lifecycle

```text
OPEN ----answered---> ANSWERED ----promote--> discovery-brief.md or ADR
  |
  +--parked-------> PARKED ----cited-in--> ADR Consequences
```

## When the skills add or update entries

- `adr-discovery` — adds entries when a MUST cannot be confirmed; refuses to advance until the MUST is `ANSWERED` or `PARKED`.
- `adr-drafting` — refuses to reach the Draft phase while any MUST is `OPEN`. PARKED MUSTs are echoed into the ADR's Consequences.
- `adr-critique` — flags ADRs that reference no open-questions while obviously relying on assumptions, and ADRs that reference an `OPEN` question without acknowledging it as a known unknown.

## Out-of-band sources

When discovery scans an external wiki, Backstage entry, TechRadar, or platform ADR set, surface what was found as an open question — never as a confirmed fact, unless the architect explicitly confirms.
