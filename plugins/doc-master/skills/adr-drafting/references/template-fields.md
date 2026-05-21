# ADR template — full field semantics

The `adr-drafting` skill uses this canonical field set. It is MADR-compatible but enforces stricter limits to keep the ADR a decision record rather than a design doc.

## Frontmatter

| Field | Required? | Notes |
|---|---|---|
| `title` | yes | Imperative verb phrase: `"Use Postgres for primary store"`. No period. |
| `status` | yes | ADR Explorer-compatible value: `proposed`, `accepted`, `superseded`, or `deprecated`. Do not overload with `rfc`, `rejected`, or backfill text. |
| `date` | yes | ISO 8601 (`YYYY-MM-DD`). Stamp at acceptance, not first draft. |
| `deciders` | yes | YAML array of named human(s). "The team" is not a value. |
| `supersedes` | optional | YAML list of ADR ids this decision replaces (e.g., `["0004"]`). This list creates the graph edge; do not rely on `superseded-by` / `superseded by` text on the old ADR alone, and do not rely on prose `Related ADRs:` body lines — explorers read frontmatter only. |
| `amends` | optional | YAML list of ADR ids this decision adjusts without replacing. Graph-bearing; frontmatter only. |
| `relates-to` | optional | YAML list of objects: `{id: "0004", reason: "one-line reason"}`. Graph-bearing; frontmatter only. |
| `tags` | optional | Free-form, lowercase, hyphenated. |
| `review-by` | recommended | ISO date or named trigger (e.g., `100k DAU`). A fossil trigger ("revisit annually") is worse than no trigger. |
| `expires` | optional | ISO date for decisions that should stop applying unless renewed. Use only when expiry is real. |
| `confidence` | recommended | `high`, `medium`, or `low`. Used by the skill to suggest RFC routing. If a numeric score is desired, add separate `confidence-score`. |
| `rfc-deadline` | conditional | Required when the ADR is serving as an RFC with `status: proposed`. Date the RFC window closes. |

### How ADR Explorer-style parsers read these fields

ADR Explorer-style tools extract relationships from YAML frontmatter only:

- The frontmatter block is parsed with `gray-matter`. The Markdown body is **not** scanned for relationship links.
- Exactly three keys produce ADR-to-ADR graph edges: `relates-to`, `supersedes`, `amends`. Any other custom key (e.g., `related`, `links`, `see-also`) is ignored unless the team also wires it into their own tooling.
- ID values are normalized with the regex `/(\d+)/` — the first digit run is captured and zero-padded to four characters. So `8`, `"08"`, `"0008"`, and `"ADR-0008"` all collapse to the node `0008`.
- Recommendation: write IDs as **zero-padded four-digit strings** (`"0008"`) in every list. Bare integers parse correctly, but quoted four-digit strings sort, diff, and render predictably across tools.

Minimal canonical frontmatter that renders cleanly in a graph view:

```yaml
---
title: "Use Postgres for primary store"
status: accepted
date: 2026-05-20
deciders:
  - Jane Doe
supersedes:
  - "0004"
amends: []
relates-to:
  - id: "0011"
    reason: "shares the tenancy model decided in 0011"
---
```

Lines such as `Related ADRs: [ADR-0011](0011-tenancy.md)` in the body are for human readers — they do not appear in the graph.

## Sections

### Title (`# NNNN. <Title>`)

- Number is zero-padded, four digits.
- Numbering is **monotonic**. Never reuse a number, even for a rejected ADR.
- Numbers reflect creation order, not acceptance order.

### Context (≤ 3 sentences)

The **forces** that make this decision necessary now. Not the history of the project. Not the team's biography. Not a tutorial about the domain.

| Good | Bad |
|---|---|
| "Cross-entity reporting and audit search arrive in Q3. Both require multi-table joins over the user dataset. Current DynamoDB-based aggregation runs at p95 600ms; ASR-12 requires < 200ms." | "Our company has been growing rapidly over the last several quarters. We have many features in our pipeline. One of these is reporting…" |

### Decision (≤ 3 sentences)

Active voice. Present tense. Names the choice directly.

| Good | Bad |
|---|---|
| "We use Postgres on RDS for the primary store." | "It has been decided that Postgres will be adopted as our database of choice going forward." |

### Consequences (bullets only)

Prose paragraphs are a smell. Use `Good, because…` and `Bad, because…` markers. Include follow-up work this decision triggers.

```text
- Good, because join workloads land on the engine designed for them.
- Good, because the team's existing SQL experience applies.
- Bad, because we lose DynamoDB's auto-scaling read pattern; manual capacity planning required.
- Follow-up: ADR 0017 will record deployment topology (single vs multi-region).
```

### Compliance (1-3 sentences)

How is conformance to this decision verified? A **fitness function** is allowed here — a one-liner of code or a dashboard reference — but no broader implementation.

| Good | Bad |
|---|---|
| "CI enforces no `@aws-sdk/client-dynamodb` import outside `/legacy`. Latency dashboard `dashboards/db-latency.json` must show p95 < 200ms." | (A 40-line migration script) |

### Alternatives Considered (bullets)

Realistic options only. **At the same level of abstraction** — don't compare "a technology" to "a protocol." Each gets a one-paragraph "why not." Skip pseudo-alternatives like "do nothing."

### Notes (optional)

- Human-readable cross-links only. Prefer distinct labels so a reader can tell intent apart, for example:
  - `Related ADRs: [ADR-0001](0001-dual-runtime.md)`
  - `Related docs: [Architecture](../explanation/architecture.md)`
- **Do not treat body links as a relationship signal.** ADR Explorer-style parsers ignore the body entirely; only frontmatter `supersedes`, `amends`, and `relates-to` create graph edges. Anything you want a tool to see must be in the frontmatter.
- Do not rely on the decision-log `README.md` as a connection between ADRs either — index-hub links are also ignored when edges are drawn.
- `PARKED` open questions cited here, with the reason for parking.
- Anything that didn't fit but matters for the record. Resist using this section as overflow.

## Status transitions

```text
  proposed  ----accept----> accepted ----change----> superseded
                                  |
                                  +--no longer applies--> deprecated
```

- Use `status: proposed` for ADRs serving as RFCs; add `rfc-deadline` instead of inventing `status: rfc`.
- If a proposal is rejected, either delete it before acceptance or keep it as `status: deprecated` with a clear rejection note; do not use `status: rejected` when ADR Explorer compatibility matters.
- An accepted ADR's body is **append-only**. Header-only reverse links are allowed for human readers, but ADR Explorer graph rendering depends on the new ADR's `supersedes` list.
- Supersession is recorded by the new ADR setting `supersedes: ["NNNN"]` in its frontmatter. The old ADR may also receive a human-readable `superseded by` header note, but that note is not the graph edge and is not parsed by ADR Explorer-style tools.

## Numbering and filenames

- Format: `NNNN-kebab-imperative-title.md`. Examples: `0017-use-postgres-for-primary-store.md`, `0021-deprecate-event-sourcing.md`.
- Filenames must start with the numeric ADR id for ADR Explorer indexing.
- Lowercase, hyphenated. No spaces, no underscores.
- Never `decision-7.md` or `database-stuff.md`.
- Preferred ADR Explorer discovery paths: `docs/adr/`, `docs/decisions/`, `docs/architecture/decisions/`, and `**/adr/*.md`. A bare `architecture/decisions/` directory may require custom ADR Explorer root configuration.
