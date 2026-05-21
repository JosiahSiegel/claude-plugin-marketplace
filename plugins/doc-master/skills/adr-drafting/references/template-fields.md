# ADR template — full field semantics

The `adr-drafting` skill uses this canonical field set. It is MADR (currently 4.0.0)-compatible but enforces stricter limits to keep the ADR a decision record rather than a design doc. Upstream template: [adr.github.io/madr/](https://adr.github.io/madr/); source repo: [github.com/adr/madr](https://github.com/adr/madr).

## The two-source rule (frontmatter and body must agree)

ADR-graph tooling does not converge on a single source. Two families dominate:

| Parser family | What it reads | Examples |
|---|---|---|
| Frontmatter-scanning (gray-matter style) | YAML between `---` fences. Body is ignored. | ADR Explorer and similar |
| Body-scanning (Markdown-AST style) | Rendered Markdown body, looking for ADR-to-ADR links under known section headings (originally `## Links` in MADR 2.x; now community-conventionally under `## More Information`, frequently a `### Relationships` sub-section, in MADR 3.0 and 4.0). Frontmatter is ignored. | ADR Manager and similar |

**A doc-master ADR is rendered correctly by both.** That means:

1. The file begins with a `---` YAML frontmatter block (mandatory — see refusal rule in `../SKILL.md`).
2. The frontmatter populates `supersedes`, `amends`, and `relates-to` whenever any relationship exists.
3. The body contains a `## More Information` section with a `### Relationships` sub-section that **mirrors the frontmatter relationships** using the link-prefix vocabulary below.
4. The two sources do not disagree. If they do, the ADR is broken.

## Canonical example — frontmatter and body side by side

```md
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
tags: [storage, primary-store]
review-by: 2026-11-20
confidence: high
---

# 0017. Use Postgres for primary store

## Context
...

## Decision
...

## Consequences
- Good, because ...
- Bad, because ...

## Compliance
...

## Alternatives Considered
- DynamoDB extension -- one paragraph, single strongest con.

## More Information

### Relationships

- Supersedes [ADR-0004](0004-use-dynamodb-for-primary-store.md) -- replaced because Q3 reporting workload requires multi-table joins under 200ms (ASR-12).
- Related to [ADR-0011](0011-tenancy.md) -- shares the tenancy model decided in 0011.
```

In this example:

- `supersedes: ["0004"]` in frontmatter and `Supersedes [ADR-0004](...)` in body **must both be present**. Either one alone leaves the relationship invisible to half the tooling.
- `relates-to: [{id: "0011", reason: ...}]` in frontmatter and `Related to [ADR-0011](...)` in body are likewise paired.
- If the architect adds a body line `Amended by [ADR-0023](...)` later, they must also add `"0023"` to the **superseding ADR's** `amends:` list — not to this file's frontmatter (which is now immutable if `accepted`). See "Status transitions" below for the immutability rule.

## Link-prefix vocabulary (doc-master convention)

The body `### Relationships` section uses these link prefixes. Each prefix corresponds to a frontmatter key or its inverse, so a mechanical mirror is always possible. The exact strings:

| Body link prefix | Frontmatter key (new ADR) | Frontmatter key (old ADR) | Direction |
|---|---|---|---|
| `Supersedes [ADR-NNNN](...)` | `supersedes: ["NNNN"]` | (none — old ADR is immutable) | Forward |
| `Superseded by [ADR-NNNN](...)` | (none — already in old ADR's frontmatter via the new ADR's `supersedes` list) | reverse note for human readers | Backward |
| `Amends [ADR-NNNN](...)` | `amends: ["NNNN"]` | (none) | Forward |
| `Amended by [ADR-NNNN](...)` | (none) | reverse note for human readers | Backward |
| `Related to [ADR-NNNN](...)` | `relates-to: [{id: "NNNN", reason: "..."}]` | (none — symmetric, but only one side needs it) | Symmetric |

Notes:

- These prefixes are **the doc-master convention**, distilled from MADR 3.0/4.0 community practice and the older MADR 2.x `## Links` lexer (which tokenized `## Links` as the relationship heading). They are not a formal MADR specification — the upstream MADR 4.0 template only suggests "Links to other decisions and resources might appear here" under `## More Information`. doc-master codifies the prefix names so frontmatter and body can always be mirrored mechanically. Upstream MADR template: [github.com/adr/madr/tree/4.0.0/template](https://github.com/adr/madr/tree/4.0.0/template).
- Use a Markdown link with a path relative to the ADR (e.g., `[ADR-0004](0004-old-decision.md)`), not a bare ID.
- The `— reason` trailing dash-clause is optional but recommended; for `relates-to` it should match the frontmatter `reason` field.
- Reverse-direction prefixes (`Superseded by`, `Amended by`) are **human-only** courtesy notes added to the old ADR's header. They do not produce graph edges; the edge always lives in the new ADR's frontmatter `supersedes` / `amends` list.

## Status vocabulary

The lowercase status lifecycle is `proposed`, `accepted`, `superseded`, `deprecated`. Do **not** overload `status` with `rfc`, `rejected`, `backfilled`, or explanatory strings — those break gray-matter-based filters. For RFC routing, use `status: proposed` with a separate `rfc-deadline:` field.


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

### More Information

The MADR 4.0 catch-all section. doc-master pins **one required sub-section** and allows optional siblings.

#### Relationships (required when frontmatter relationships exist)

Mirror every populated frontmatter relationship into this body section using the link-prefix vocabulary above. This is the section body-scanning parsers (ADR Manager and similar) read. Example:

```md
### Relationships

- Supersedes [ADR-0004](0004-use-dynamodb-for-primary-store.md) -- replaced because <reason>.
- Related to [ADR-0011](0011-tenancy.md) -- shares the tenancy model.
```

If frontmatter `supersedes`, `amends`, and `relates-to` are all empty, this sub-section may be omitted. If any is populated, the sub-section is mandatory; the `adr-critique` skill flags ADRs that have one source but not the other.

#### Notes (optional)

- `PARKED` open questions cited here, with the reason for parking.
- Provenance links to other docs that are not ADRs (explanations, runbooks, architecture diagrams):
  - `Related docs: [Architecture](../explanation/architecture.md)`
- Anything that didn't fit but matters for the record. Resist using this section as overflow.

**Do not put ADR-to-ADR links here.** They belong under `### Relationships` above, using the link-prefix vocabulary. A `Related ADRs:` line in this section is a smell — it's the legacy form `adr-critique` flags for promotion.

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
