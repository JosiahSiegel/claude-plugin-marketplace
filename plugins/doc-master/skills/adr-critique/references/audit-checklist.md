# Audit checklist — per-section probes

The detailed probe set for `adr-critique` Phases 3 (missing-why), 4 (consistency), and 5 (LikeC4 drift). Walk these in order on every ADR under audit.

## Per-section probes

### Frontmatter / header

| Probe | Flag if… |
|---|---|
| Frontmatter present at all? | The file does not begin with a `---` YAML frontmatter block. Without it the ADR is invisible to gray-matter-style parsers (ADR Explorer and similar). This is an error, not a style warning. |
| `status` set? | Missing, non-lowercase, `proposed` for > 30 days, or not one of ADR Explorer's valid values: `proposed`, `accepted`, `deprecated`, `superseded`. Flag overloaded values such as `rfc`, `rejected`, or `accepted (backfilled YYYY-MM-DD)`. |
| `date` ISO 8601? | Missing or in `MM/DD/YYYY` format. |
| `deciders` named humans? | Not a YAML array, `"the team"`, `"engineering"`, `"leadership"`, or empty. (Exception: backfill ADRs may include the literal `unrecoverable` — see "Backfill ADRs" probe below.) |
| `supersedes` graph edge? | Not a YAML list, or the new ADR relies only on `superseded-by` / `superseded by` text instead of listing the old ADR id in `supersedes`. |
| `amends` shaped? | Present but not a YAML list of ADR ids. |
| `relates-to` reasoned? | Not a YAML list of `{id, reason}` objects, or reason is missing. |
| `confidence` shaped? | Present but not `high`, `medium`, or `low`; numeric confidence belongs in separate `confidence-score`. |
| `expires` valid? | Present but not ISO 8601, or used for a decision that has no real expiry semantics. |
| `review-by` concrete? | `"annually"`, `"as needed"`, `"when appropriate"` — fossils. |

### Frontmatter / body mirror

doc-master requires both sources to agree so the ADR renders edges in both parser families. Walk these probes for every ADR:

| Probe | Flag if… |
|---|---|
| Mirror present? | Frontmatter populates `supersedes`, `amends`, or `relates-to`, but the body has no `## More Information` section with a `### Relationships` sub-section. Body-scanning parsers (ADR Manager and similar) cannot see the relationship. Error. |
| Mirror reciprocal? | Body has a `### Relationships` section listing ADR-to-ADR links via doc-master link prefixes (`Supersedes`, `Superseded by`, `Amends`, `Amended by`, `Related to`), but the corresponding frontmatter relationship keys are empty or absent. Gray-matter parsers cannot see the relationship. Error. |
| Mirror sets agree? | The set of relationships in frontmatter does not match the set in the body Relationships section. Quote the diff and ask which is correct. Error. |
| Link-prefix vocabulary used? | The body Relationships section uses ad-hoc phrasing ("See ADR-0004", "Like in 0011", "Replaces ADR-0004") instead of the canonical link prefixes. Warning. |
| Reverse-link in frontmatter? | The old ADR has `superseded-by:` / `amended-by:` in its frontmatter (these are not valid graph keys; only `supersedes`, `amends`, `relates-to` produce edges). The reverse direction belongs in the **new** ADR's frontmatter `supersedes` / `amends` list, with a courtesy `Superseded by [ADR-NNNN](...)` line in the old ADR's body for human readers. Warning. |

### Backfill ADRs

A backfill ADR is detectable by `tags: [backfill]` plus `backfilled-on: YYYY-MM-DD`. Older records may use `status: accepted (backfilled YYYY-MM-DD)` or `status: deprecated (decision reversed since)`; flag those for header migration to ADR Explorer-compatible status values without changing the body. These records have a small set of probes of their own — they are subject to all other probes in this file as well.

| Probe | Flag if… |
|---|---|
| Honesty clause present? | Body lacks a compliant backfill notice (canonical form: `../../adr-backfill/references/honesty-clause.md`). |
| Honesty-clause completeness | Clause present but missing a required field (record date, evidence locators, decider) or terminal period. |
| Evidence locators ≥ 2? | Fewer than two independent locators in the frontmatter `evidence:` list. One commit message alone is not enough. |
| ASR signal measurable? | `asr-signal` is vague ("felt cleaner," "improved DX") rather than a measurable signal ("removed 14k LOC and one vendor dependency"). |
| Status / tags consistent? | `tags` does not include `backfill`, `backfilled-on` is missing, or `status` is overloaded with backfill/reversal text instead of plain `accepted` or `deprecated`. |
| Honesty clause softened? | The clause has been rewritten to hide the backfill nature (e.g., moved to a footnote, paraphrased into past-tense narrative, fields omitted). The clause is non-negotiable; flag and route to redraft via `adr-backfill`. |

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

### Probe 1: supersession graph compatibility

For every superseding decision, confirm the new ADR has `supersedes: ["X"]` (or an equivalent YAML list) in its **frontmatter**. ADR Explorer-style parsers read frontmatter only — a reverse `superseded by:` note on X, a body line such as `Related ADRs: [ADR-0004](0004-foo.md)`, or a link from the decision-log `README.md` index does **not** create the edge. Flag missing or scalar `supersedes` values, and flag any relationship that lives only in prose with a recommendation to promote it into frontmatter using zero-padded four-digit string IDs (`"0004"`).

### Probe 2: orphan amendments

For every id in `amends: [X]`, confirm X exists and is `accepted`. An amendment to a non-existent, `deprecated`, or `superseded` ADR is a flag.

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

```text
Audited: <path/to/NNNN-title.md>
Neighbors read: <list of ADR IDs>
Flags raised: <N>
Flags applied: <M>
Flags rejected by architect: <K>
Open items needing follow-up:
  - <one line per item>
```

Do not stamp the ADR with `[audited]` markers, dates, or signatures. The audit's value is in the diffs, not the metadata.
