# ADR template — full field semantics

The `adr-drafting` skill uses this canonical field set. It is MADR-compatible but enforces stricter limits to keep the ADR a decision record rather than a design doc.

## Frontmatter

| Field | Required? | Notes |
|---|---|---|
| `title` | yes | Imperative verb phrase: `"Use Postgres for primary store"`. No period. |
| `status` | yes | One of: `proposed`, `rfc`, `accepted`, `superseded`, `deprecated`. |
| `date` | yes | ISO 8601 (`YYYY-MM-DD`). Stamp at acceptance, not first draft. |
| `deciders` | yes | Named human(s). "The team" is not a value. |
| `supersedes` | optional | ADR id of the decision this one replaces (e.g., `0004`). |
| `amends` | optional | ADR id this one adjusts without replacing. |
| `relates-to` | optional | List of `<id> — one-line reason`. |
| `tags` | optional | Free-form, lowercase, hyphenated. |
| `review-by` | recommended | ISO date or named trigger (e.g., `100k DAU`). A fossil trigger ("revisit annually") is worse than no trigger. |
| `confidence` | recommended | 1-5. Used by the skill to suggest RFC routing. |
| `rfc-deadline` | conditional | Required when `status: rfc`. Date the RFC window closes. |

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

- Cross-links to related ADRs.
- `PARKED` open questions cited here, with the reason for parking.
- Anything that didn't fit but matters for the record. Resist using this section as overflow.

## Status transitions

```text
  proposed  ----accept----> accepted ----change----> superseded by NNNN
     |                          |
     +--reject--> rejected      +--no longer applies--> deprecated

  rfc  ----deadline passes + accepted----> accepted
   |
   +----deadline passes + rejected----> rejected
```

- `proposed` and `rfc` are similar; pick one per project. RFC adds a hard deadline.
- An accepted ADR's body is **append-only**. Only the header may receive a `superseded by:` link.
- Supersession is bidirectional: the new ADR sets `supersedes`, the old ADR's header gets `superseded by`.

## Numbering and filenames

- Format: `NNNN-kebab-imperative-title.md`. Examples: `0017-use-postgres-for-primary-store.md`, `0021-reject-event-sourcing.md`.
- Lowercase, hyphenated. No spaces, no underscores.
- Never `decision-7.md` or `database-stuff.md`.
