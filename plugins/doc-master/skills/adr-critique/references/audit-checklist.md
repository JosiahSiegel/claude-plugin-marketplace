# Audit checklist — per-section probes

The detailed probe set for `adr-critique` Phases 3 (missing-why), 4 (consistency), and 5 (LikeC4 drift). Walk these in order on every ADR under audit.

## Per-section probes

### Frontmatter / header

| Probe | Flag if… |
|---|---|
| `status` set? | Missing or `Proposed` for > 30 days. |
| `date` ISO 8601? | Missing or in `MM/DD/YYYY` format. |
| `deciders` named humans? | `"the team"`, `"engineering"`, `"leadership"`, or empty. |
| `supersedes` bidirectional? | This ADR claims `supersedes: X` but X has no `superseded by`. |
| `relates-to` reasoned? | List of bare IDs with no one-line reason each. |
| `review-by` concrete? | `"annually"`, `"as needed"`, `"when appropriate"` — fossils. |

### Context

| Probe | Flag if… |
|---|---|
| Length | More than 3 sentences. |
| Tutorial content | Explains what a tech *is* rather than what forces apply. |
| History padding | Opens with project / team biography. |
| Marketing | Banned words from `adr-is-not.md` rule 3. |

### Decision

| Probe | Flag if… |
|---|---|
| Length | More than 3 sentences. |
| Voice | Passive voice. ("It was decided…") |
| Tense | Future tense for the current decision. ("We will use…") |
| Hedging | `might`, `could`, `may`, `potentially`, `consider`. |
| Missing-why | Justified by `best practice`, `industry standard`, `most teams`, `the model`. |
| Bundled | Two or more independent decisions in one ADR. |

### Consequences

| Probe | Flag if… |
|---|---|
| Format | Prose paragraphs instead of bullets. |
| Asymmetry | Only "Good, because…" — no "Bad, because…". A decision with no costs is a fantasy. |
| Vagueness | "Improves scalability." "Increases flexibility." Without a number or scenario, these are noise. |
| Missing follow-ups | Decision implies migration / new ADRs / new dashboards, none cited. |

### Compliance (if present)

| Probe | Flag if… |
|---|---|
| Implementation bleed | A full migration script, deployment manifest, or > 10 lines of code. |
| No fitness function | Decision is verifiable but no check is named (lint rule, arch test, dashboard, CI rule). |

### Alternatives Considered

| Probe | Flag if… |
|---|---|
| Mixed abstraction levels | Compares "a technology" to "a protocol" or "a vendor" to "a pattern." |
| Pseudo-alternatives | "Do nothing." "Build it ourselves" with no realistic plan. |
| One-line dismissals | Alternative listed but no concrete "why not." |

### Notes

| Probe | Flag if… |
|---|---|
| Overflow | This section contains material that should be in Context / Decision / Consequences but was punted here. |

## Phase 3 — missing-why interrogation

For each line in the Decision (or any section claiming rationale), apply this two-question test:

1. **What business concern is this decision serving?** (compliance, cost, latency, time-to-market, vendor risk, team capacity)
2. **Which architectural characteristic does it optimize?** (availability, performance, maintainability, scalability, security, observability)

A valid line answers both. An invalid line answers neither.

| Rationale type | Valid? |
|---|---|
| "Compliance requires EU data residency; per-region replicas satisfy this." | Yes — business concern + characteristic. |
| "Our SRE team has 5 years of Postgres experience and zero with the alternatives." | Yes — team capacity is a business concern, operability is a characteristic. |
| "This is the industry standard." | No — neither concern nor characteristic. |
| "It's a best practice for microservices." | No — abstraction without local force. |
| "Most teams in 2026 do this." | No — popularity is not rationale. |
| "Future-proofs the architecture." | No — see rule 7. |

## Phase 4 — consistency probes

### Probe 1: bidirectional supersession

For every `supersedes: X` in the ADR, read X and confirm `superseded by:` is set to the current ADR's ID. Flag asymmetry in either direction.

### Probe 2: orphan amendments

For every `amends: X`, confirm X exists and is `accepted`. An amendment to a non-existent or `rejected` ADR is a flag.

### Probe 3: tension detection

Two ADRs are in **tension** when both are `accepted`, neither supersedes the other, but their decisions conflict. Walk the graph: for every pair of `relates-to`-linked ADRs, ask "do these claims sit cleanly side by side, or do they contradict?" Flag contradictions.

### Probe 4: duplicate authority

If two ADRs both claim authority over the same component or characteristic ("ADR 0007 picks the auth provider"; "ADR 0019 also picks the auth provider"), one must defer. Flag for the architect to resolve via supersession or scope narrowing.

### Probe 5: ghost references

The ADR references another ADR by number (e.g., "as in 0023") that does not exist or has a different topic. Flag.

## Phase 5 — LikeC4 drift probes

### Probe 1: component name mismatch

Compare every component name mentioned in the ADR text against names in the LikeC4 model. Case-insensitive substring match isn't enough — exact match preferred. Flag mismatches.

### Probe 2: missing component

ADR mentions a component the LikeC4 model does not contain. Could be:
- The model is stale (update the model)
- The ADR uses a wrong name (update the ADR)
- The component lives outside the diagram's scope (update neither, note explicitly)

### Probe 3: missing relationship

ADR claims A depends on B but the LikeC4 model shows no such edge. Same three possibilities.

### Probe 4: contradicting kind

ADR talks about "the user-service container" but the LikeC4 model defines `user-service` as an `externalSystem`. Flag — the kinds disagree.

## Reporting format

End-of-audit summary:

```
Audited: <path/to/NNNN-title.md>
Neighbors read: <list of ADR IDs>
Flags raised: <N>
Flags applied: <M>
Flags rejected by architect: <K>
Open items needing follow-up:
  - <one line per item>
```

Do not stamp the ADR with `[audited]` markers, dates, or signatures. The audit's value is in the diffs, not the metadata.
