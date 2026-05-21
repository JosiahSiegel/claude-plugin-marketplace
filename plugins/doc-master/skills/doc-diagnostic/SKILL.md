---
name: doc-diagnostic
description: |
  This skill should be used when deciding whether a doc should exist, where it belongs, whether something is really an ADR, or whether an architectural decision is missing from the record.
  PROACTIVELY activate on "should this be an ADR?", "where should I document X?", "is this architecturally significant?", "ADR vs RFC vs design doc vs runbook", "Diátaxis", "audit docs folder", "clean up the decision log", "doc drift", "doc governance", "ADR template selection", "Nygard vs MADR vs Y-statement", "missing ADR", "missing decision record", "undocumented architecture", "implicit decision", "historical documentation clutter", "inherited repo", "large legacy repo", "architecture archaeology", "code archaeology", "scan for decision records", "find decisions not captured in ADRs."
  Provides: doc placement diagnostic, alternatives catalog, ADR canon, folder audit procedure, and BACKFILL-ADR candidate detection.
---

# doc-diagnostic

The diagnostic and canon skill. Owns three things:

1. **The alternatives catalog** — when a user impulse should not be an ADR, what is the right home. Full catalog: `references/alternatives-catalog.md`.
2. **The ADR canon** — templates, status lifecycle, numbering, required fields, immutability rules. (In this file.)
3. **The audit procedure** — folder-level KEEP / MERGE / REWRITE / DELETE / MOVE classification used by `/doc-audit`. Full procedure: `references/audit-procedure.md`.

Use this skill when routing a doc request, picking a template, naming a status, or auditing an existing doc set. The drafting / discovery / critique skills consume the canon defined here; they do not redefine it.

## The four-question diagnostic (run before recommending any doc)

This is the canonical four-question check. The `doc-expert` agent and every other skill in this plugin reference this section rather than restating it. Before agreeing to produce *any* document, run these four checks. If any answer is "no" or "unclear," the doc should not be written yet.

1. **Purpose** — Can you state in one sentence what question this doc answers for a reader who already knows the system exists?
2. **Audience** — Who specifically will read this, in what situation? ("Future maintainers" is not an audience; "an on-call engineer at 03:00 with a P1" is.)
3. **Owner** — Who is accountable for keeping this doc true? If nobody, the doc will drift within months.
4. **Update trigger** — What concrete event causes this doc to be revisited or superseded? If you can't name one, the doc becomes a fossil.

If all four are answerable, proceed to the "is this an ADR?" diagnostic in the `doc-expert` agent body.

## Architecturally Significant Requirement (ASR) — canonical definition

An ADR captures **a single architectural decision and its rationale**. An architectural decision is "a justified design choice that addresses a functional or non-functional requirement that is **architecturally significant**." An Architecturally Significant Requirement (ASR) is one with "a measurable effect on the architecture and quality of a software and/or hardware system."

If the change is not architecturally significant, an ADR is the wrong tool — route via the alternatives catalog.

## The alternatives catalog (when NOT to write an ADR)

When the diagnostic says "not an ADR," route the user to the right home. The full mapping — every common user impulse, its correct documentation form, and the reason an ADR would be wrong — lives in `references/alternatives-catalog.md`. Load it whenever the user is debating "ADR vs RFC vs design doc vs runbook vs how-to" or asks "where should I document X?"

The catalog also names the **Diátaxis four** precisely (tutorial / how-to / reference / explanation) so you can route reliably between them. ADRs are *not* Diátaxis explanations — see the catalog file for the distinction.

## ADR canon

### Template selection

Pick the smallest template that captures the decision honestly:

| Template          | Use when...                                                                                | Don't use when...                                |
|-------------------|--------------------------------------------------------------------------------------------|--------------------------------------------------|
| **Nygard / MADR light** | Decision is simple, alternatives are obvious, three to five fields suffice (Context, Decision, Consequences). | You need to compare 3+ alternatives on multiple criteria. |
| **MADR (full)**   | Multiple plausible options need side-by-side analysis; decision drivers matter; you need a Confirmation/Validation field; the team values traceability. | The decision is trivial — full MADR will pad it. |
| **Y-statement**   | The decision fits one sentence: *"In the context of X, facing Y, we decided Z, to achieve W, accepting that V."* Excellent for a compact log entry or executive summary atop a longer ADR. | The decision genuinely needs structured fields. |
| **arc42 / Tyree-Akerman / Business case** | The project already uses one of these and consistency outweighs minimalism. | You're starting fresh — they're heavier than most teams need. |

Pick once per project, then "stick to what you have decided for." Don't mix templates within a single decision log unless you're explicitly migrating.

### Canonical status lifecycle

```text
  proposed  ----accepted---->  accepted  ----changed---->  superseded
                                      |
                                      +--no-longer-applies-->  deprecated
```

ADR Explorer-compatible status values are lowercase `proposed`, `accepted`, `deprecated`, and `superseded`. Do not overload `status` with `rfc`, `rejected`, `backfilled`, or explanatory strings.

- **proposed** — under discussion, including ADRs serving as RFCs. Add `rfc-deadline` for the RFC window instead of inventing `status: rfc`.
- **accepted** — the decision is in force.
- **superseded** — replaced by a later ADR. The new ADR's `supersedes` list creates the graph edge; the old ADR may also receive a human-readable reverse link.
- **deprecated** — the decision no longer applies but no new decision replaces it, or a proposal was rejected but kept for its "why not" reasoning. Explain the reason in the body or notes, not in `status`.

### Immutability and supersession

The cardinal rule: **"Don't alter existing information in an ADR."** Amend or supersede instead.

- Once Accepted, treat the body as append-only. Allowed edits: typo fixes, adding a `superseded by` note, adding dated notes at the bottom under an explicit "Amendments" heading.
- A changed decision is a **new ADR** that names the old one in its `supersedes` list. The old ADR may get a `superseded by: NNNN` note for human readers — and otherwise stays untouched. Do not rely on `superseded-by` / `superseded by` for ADR Explorer graph rendering; the new ADR's `supersedes` list is the edge.
- Some teams prefer a "living document" stance with dated inline amendments. State the project's stance up front in the decision log's `README.md` and stick to it.

### Numbering, naming, ownership

- **Numbering**: monotonically increasing, zero-padded (`0001`, `0002`, ...). Never reuse a number, even for a rejected ADR. The number IS the identity.
- **Filename**: starts with the zero-padded numeric id, then a present-tense imperative verb phrase, lowercase, hyphenated, `.md` (e.g., `0007-use-postgres-for-primary-store.md`). Not `decision-7.md`. Not `database-stuff.md`.
- **Ownership**: name `deciders` as a YAML array (accountable) and, if relevant, `consulted` (two-way input) and `informed` (one-way notice) — the RACI distinction in MADR. "The team" is not an owner.
- **Date**: ISO 8601 (`YYYY-MM-DD`). Stamp at acceptance, not first draft.
- **Review cadence**: state the re-evaluation trigger on the ADR itself. "Revisit when we exceed 10k QPS" is concrete; "revisit annually" is a fossil-in-waiting.

### Required fields

Every ADR should contain:

1. **Title** — `NNNN. Decision (imperative verb phrase)`.
2. **YAML frontmatter — mandatory.** The file **must** begin with a `---` block containing at minimum `title`, `status`, `date`, and `deciders`. When relationships exist, also `supersedes`, `amends`, and / or `relates-to`. Optional: `tags`, `review-by`, `expires`, `confidence: high | medium | low`, separate `confidence-score`, and `rfc-deadline` when `status: proposed` is acting as an RFC. **An ADR without YAML frontmatter is invisible to any gray-matter-based explorer** (ADR Explorer and similar) — they parse the front block and ignore the body. This is the single biggest cause of ADRs that "have relationships" but show as orphan nodes in tooling. doc-master defaults to writing frontmatter on every ADR; the `adr-drafting` skill refuses to save without it.
3. **Body Relationships mirror — mandatory whenever frontmatter relationships exist.** doc-master defaults to MADR 3.0 with a `## More Information` section containing a `### Relationships` sub-section that mirrors the frontmatter `supersedes` / `amends` / `relates-to` using doc-master's link-prefix vocabulary (`Supersedes`, `Superseded by`, `Amends`, `Amended by`, `Related to`). This second source is what body-scanning parsers (ADR Manager and similar) read; they do not look at frontmatter. **An ADR with frontmatter relationships but no body mirror is invisible to body-scanning tools, and vice versa.** The two sources must agree.
4. **Context** — architecturally significant forces: requirements, constraints, business pressure, team skills, prior decisions. Enough that a stranger three years later understands *why this decision had to be made now*.
5. **Decision** — the choice, stated directly, present tense. ("We use Postgres for the primary store.") The ADR must stand alone even if it links to longer design material.
6. **Decision drivers** *(MADR)* or implicit in Context *(Nygard)* — the qualities being optimized: latency, cost, operational simplicity, team familiarity, vendor lock-in, etc.
7. **Alternatives considered** — at least the realistic ones, **at the same level of abstraction** (don't compare "a technology" to "a protocol"). Each alternative gets a one-paragraph "why not." Skip pseudo-alternatives ("we could do nothing").
8. **Consequences** — both **Good, because...** and **Bad, because...** outcomes, plus follow-up work the decision triggers.
9. **Confirmation / Validation** *(MADR full)* — how compliance with the decision is enforced and evaluated (lint rule? architecture test? ArchUnit? ADR audit? code review checklist?).
10. **Re-evaluation triggers** — concrete conditions that should cause a new ADR to supersede this one.

### Storage and discoverability

- Keep ADRs **in the source repository, in source control**, alongside the code they govern.
- ADR Explorer-friendly locations: `docs/adr/`, `docs/decisions/`, `docs/architecture/decisions/`, or `**/adr/*.md`. A bare `architecture/decisions/` directory can work as a legacy project convention, but warn that it may need custom ADR Explorer root configuration. Pick one per project; document the choice in the decision log's `README.md`.
- Provide an **index** in the decision log `README.md` listing every ADR with its status and a one-line summary. Treat the index as navigation, not the relationship graph.
- **Default to frontmatter-first.** Every ADR begins with a `---` YAML block. Without it, the file is invisible to gray-matter-style parsers (ADR Explorer and similar), which means relationships never render in the graph regardless of what the body says. This is the single most common failure mode for "ADRs that don't show up in tooling." doc-master refuses to save an ADR without frontmatter.
- **Default to MADR 3.0 + body Relationships mirror.** Direct ADR-to-ADR relationships live in the **frontmatter** keys `supersedes`, `amends`, and `relates-to` **and** are mirrored in the body under `## More Information` → `### Relationships` using doc-master's link-prefix vocabulary (`Supersedes`, `Superseded by`, `Amends`, `Amended by`, `Related to`). Gray-matter-style parsers read the frontmatter and ignore the body; body-scanning parsers (ADR Manager and similar) read the body and ignore the frontmatter. Mirroring both is what makes the ADR render in every common tool. If the project already uses a different template (Nygard plain, Y-statement, arc42, Tyree-Akerman), follow it; otherwise, MADR 3.0 is the default.
- A bare body line such as `Related ADRs: [ADR-0001](0001-dual-runtime.md)` outside the `### Relationships` section is human navigation only — neither parser family treats it as authoritative. Keep `Related docs:` (provenance to explanations, runbooks, architecture diagrams) in `### Notes`. Do not rely on an index page linking to both ADRs as a relationship signal; index-hub links are ignored when edges are drawn.
- ID format inside the frontmatter lists: ADR Explorer-style parsers extract digits from each entry with `/(\d+)/` and zero-pad to four characters, so `8`, `"08"`, `"0008"`, and `"ADR-0008"` all resolve to the same node. **Use zero-padded four-digit strings (`"0008"`)** in `supersedes`, `amends`, and `relates-to[].id` for stable display, consistent sorting, and grep-ability; bare integers parse correctly but render less predictably.
- Cross-link ADRs from the code they govern when feasible (`// See docs/adr/0007-use-postgres-for-primary-store.md`).
- State the governance rule for relationship-link maintenance. If Accepted ADRs are otherwise immutable, either explicitly allow metadata-only relationship/link fixes (frontmatter list edits and body Relationships line additions) or require a named governance exception; body changes outside the Relationships mirror still require amendment or supersession.
- A quick offline check against the canon (filenames, required keys, lowercase status lifecycle, ISO date, deciders, ADR Explorer-compatible graph edges, frontmatter / body Relationships mirror, duplicate / dangling / circular references) is available via `plugins/doc-master/scripts/validate_adrs.py`. Use it during `/doc-audit` triage or as a CI gate, not as a substitute for the four-question check on each ADR.

Minimal canonical frontmatter **plus** body Relationships mirror for an ADR that renders edges in both parser families:

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
---

# 0017. Use Postgres for primary store

## Context
...

## Decision
...

## More Information

### Relationships

- Supersedes [ADR-0004](0004-use-dynamodb-for-primary-store.md) — replaced because Q3 reporting needs sub-200ms joins.
- Related to [ADR-0011](0011-tenancy.md) — shares the tenancy model decided in 0011.
```

Three keys (`supersedes`, `amends`, `relates-to`) produce ADR-to-ADR edges for gray-matter-style parsers. The `### Relationships` body section produces the same edges for body-scanning parsers. Either alone leaves the ADR half-rendered. Prose links elsewhere in the file (a stray `Related ADRs:` line in `### Notes`, an index-hub entry in `README.md`, a `superseded-by` note in the old ADR's body) are not authoritative — they are courtesy navigation for human readers.

## ADR failure modes

The eleven canonical ADR failure modes — drift, ADR-PRD duplication, bundled decisions, premature ADR, template thrash, decision-by-AI-without-buy-in, and the rest — with their symptoms and concrete remedies live in `references/failure-modes.md`. Load that file during audits (`/doc-audit`) and during `adr-critique` to put a name to what's wrong with a given ADR.

## Folder-level audit procedure (used by `/doc-audit`)

When the user asks you to review or clean up an existing doc set, follow the eight-step procedure documented in `references/audit-procedure.md`: Inventory → ADR-canon test → four-question test → drift detection → duplication detection → misclassification detection → backfill-candidate detection (ASR test against shipped-change evidence) → numbered KEEP / MERGE / REWRITE / DELETE / MOVE / **BACKFILL-ADR** action list.

`BACKFILL-ADR` is a candidate, not a draft. The audit only surfaces it; the architect chooses whether to load `adr-backfill` to record it. Evidence must appear in two independent locations before a row is emitted, and `reconstruction-confidence: low` routes to `open-questions.md` rather than the action list.

The procedure file also specifies the hard constraints (no body edits on Accepted ADRs, no bulk renumbering, no auto-generated Owners, no deletion without human sign-off) and the post-approval execution flow. Load it whenever `/doc-audit` runs, or when the user asks to audit, clean up, or review a doc folder.

## Anti-padding rule

Every doc you recommend creating must answer all four diagnostic questions affirmatively (Purpose, Audience, Owner, Update trigger). If even one is unanswerable, the doc should not exist yet. This rule applies to ADRs, RFCs, how-tos, references, explanations, tutorials, runbooks, READMEs, and CONTRIBUTING files alike.

Documentation is a cost as well as a benefit. Every doc consumes future attention from readers, requires updates, and competes with other docs for trust. The right number of docs is the smallest number that keeps the system understandable, operable, and decisive — not the largest.

## References

- `references/alternatives-catalog.md` — full Diátaxis / RFC / runbook / convention routing catalog (load when routing "should this be an ADR or something else?")
- `references/failure-modes.md` — eleven canonical ADR failure modes with remedies (load during audits and line-by-line critique)
- `references/audit-procedure.md` — folder-level audit procedure with hard constraints (load when `/doc-audit` runs)
- `../_shared/adr-is-not.md` — canonical "ADR is NOT" checklist enforced during drafting / critique
- `adr-discovery` skill — pre-flight Q&A before drafting
- `adr-drafting` skill — seven-phase co-thinking flow
- `adr-critique` skill — line-by-line audit of legacy ADRs
- `c4-model` skill — canonical-C4 LikeC4 diagrams
