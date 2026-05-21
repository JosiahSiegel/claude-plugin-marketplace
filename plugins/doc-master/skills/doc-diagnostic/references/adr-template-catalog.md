# ADR template catalog — the canonical index

The master index of ADR template forms doc-master knows and can route between. Load this when the user asks "which ADR template should I use?", "what's a Y-statement?", "Nygard vs MADR vs Y-statement vs arc42 vs Tyree-Akerman", or "is there a one-paragraph ADR form?"

The authoritative catalog of community-curated ADR templates lives at **[adr.github.io](https://adr.github.io/)** — when in doubt about a template not listed here, route there first.

## The forms doc-master knows

| Template                  | Shape                                                                 | Best fit                                                                                       |
|---------------------------|-----------------------------------------------------------------------|-----------------------------------------------------------------------------------------------|
| **Nygard (short)**        | Title / Status / Context / Decision / Consequences.                   | Simple decisions, obvious alternatives, lightweight team. The original 2011 form.            |
| **MADR (4.0.0) short**    | Context and Problem Statement / Decision / Consequences.              | A modern minimalist baseline; structured but small. Upstream: [adr.github.io/madr/](https://adr.github.io/madr/). |
| **MADR (4.0.0) long**     | Adds Decision Drivers, Considered Options, Decision Outcome (with positive/negative consequences), Compliance, More Information. | Decisions with 3+ realistic alternatives and traceability requirements. |
| **Y-statement (Zimmermann)** | Single-paragraph form (see below).                                  | Compact log entries, executive summaries atop a longer ADR, RFC pitch lines, decision dashboards. |
| **Tyree-Akerman**         | Heavier form with Group, Assumptions, Positions, Argument, Implications, Related Decisions, Related Requirements, Notes. | Enterprise contexts that already use this form; consistency outweighs minimalism.            |
| **arc42 §9**              | The "Architecture Decisions" section of the [arc42 template](https://arc42.org/). | Projects already using arc42 for the overall architecture documentation.                     |

doc-master's default is **MADR (currently 4.0.0)** with YAML frontmatter and a body Relationships mirror; see `../SKILL.md` "Storage and discoverability" and `../../adr-drafting/references/template-fields.md` for the full canonical fields.

## Y-statement template (inline)

A Y-statement compresses an ADR into a single paragraph. The form is fixed:

> In the context of `<use case / functional requirement>`, facing `<concern / non-functional requirement>`, we decided for `<chosen option>` and neglected `<other options>`, to achieve `<quality goal / criteria>`, accepting `<downside / consequence>`, because `<additional rationale>`.

Each slot is mandatory. A Y-statement missing any slot is a marketing sentence, not a decision record.

Example:

> In the context of the customer-facing API, facing sub-200ms p95 latency requirements, we decided for Postgres with read replicas and neglected DynamoDB, to achieve sub-150ms reporting-query latency with multi-table joins, accepting the operational overhead of self-managing replication, because the reporting workload requires SQL joins and the team has stronger Postgres operational experience than DynamoDB experience.

Y-statements are excellent as:

- The opening summary atop a longer ADR (give readers the gist before they commit to the full doc).
- Index-row summaries in the decision log's `README.md`.
- Executive-summary versions of an existing ADR for stakeholders.
- RFC pitch lines that compress the proposal into a single sentence.

They are **insufficient when**:

- The decision genuinely needs side-by-side comparison of multiple alternatives on multiple criteria.
- The Consequences need bullet lists with Good-because / Bad-because framing.
- Traceability requires structured fields (decision drivers, confirmation, re-evaluation triggers).

Source: Olaf Zimmermann's original Y-statement post on Medium, [medium.com/olzzio/y-statements-10eb07b5a177](https://medium.com/olzzio/y-statements-10eb07b5a177). Route via [adr.github.io](https://adr.github.io/) for the up-to-date catalog entry.

## Selection rules

1. **If the project already uses a template — use it.** Consistency outweighs minimalism. Switching templates mid-log is *template thrash* (a named failure mode); do not propose it lightly.
2. **If the project is starting fresh — default to MADR 4.0.** It has the best balance of structure, parser support, and community tooling.
3. **If the team is small and the decision is simple — Nygard or MADR short.** Do not pad three-field decisions with empty MADR-long sections.
4. **If you need a one-paragraph summary — Y-statement** atop a longer ADR. The longer ADR remains the canonical record.
5. **If the project already uses arc42 or Tyree-Akerman — keep it.** Translating into MADR for cosmetic reasons is template thrash.

## When NOT to use any of these — beyond architecture

If the user is recording **non-architectural decisions** (product decisions, business decisions, policy decisions) and finds the "architectural" framing constraining: the broader pattern is just **decision records**, and the directory is conventionally renamed to `decisions/`. See `../SKILL.md` "Storage and discoverability" — the Joel Parker Henderson reference repo at [github.com/joelparkerhenderson/architecture-decision-record](https://github.com/joelparkerhenderson/architecture-decision-record) catalogs the broader pattern.

The shape is the same; only the ASR test loosens. The four-question diagnostic still applies.
