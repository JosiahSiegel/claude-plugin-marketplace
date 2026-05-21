---
name: doc-diagnostic
description: |
  This skill should be used when deciding whether a doc should exist, where it belongs, whether something is really an ADR, or whether an architectural decision is missing from the record.
  PROACTIVELY activate on "should this be an ADR?", "where should I document X?", "is this architecturally significant?", "ADR vs RFC vs design doc vs runbook", "Diátaxis", "audit docs folder", "clean up the decision log", "doc drift", "doc governance", "ADR template selection", "Nygard vs MADR vs Y-statement", "missing ADR", "missing decision record", "undocumented architecture", "implicit decision", "historical documentation clutter", "inherited repo", "large legacy repo", "architecture archaeology", "code archaeology", "scan for decision records", "find decisions not captured in ADRs."
  Provides: doc placement diagnostic, alternatives catalog, ADR canon, folder audit procedure, and BACKFILL-ADR candidate detection.
---

# doc-diagnostic

The diagnostic and canon skill. Owns three things:

1. **The alternatives catalog** -- what to write when a user impulse should not be an ADR. Full catalog: `references/alternatives-catalog.md`.
2. **The ADR canon** -- templates, status lifecycle, numbering, required fields, immutability rules. (In this file.)
3. **The audit procedure** -- folder-level KEEP / MERGE / REWRITE / DELETE / MOVE / BACKFILL-ADR classification used by `/doc-audit`. Full procedure: `references/audit-procedure.md`.

Use this skill when routing a doc request, picking a template, naming a status, or auditing an existing doc set. The drafting / discovery / critique skills consume the canon defined here; they do not redefine it.

## The four-question diagnostic (run before recommending any doc)

The canonical four-question check. The `doc-expert` agent and every other skill in this plugin reference this section rather than restate it. Before agreeing to produce *any* document, run all four. If any answer is "no" or "unclear," the doc should not be written yet.

1. **Purpose** -- one sentence stating what question this doc answers for a reader who already knows the system exists.
2. **Audience** -- a specific reader in a specific situation. ("Future maintainers" is not an audience; "an on-call engineer at 03:00 with a P1" is.)
3. **Owner** -- a named human accountable for keeping it true. No owner → drift within months.
4. **Update trigger** -- a concrete event that causes the doc to be revisited or superseded. No trigger → fossil-in-waiting.

If all four are answerable, proceed to the "is this an ADR?" diagnostic in the `doc-expert` agent body.

## Architecturally Significant Requirement (ASR) -- canonical definition

An ADR captures **a single architectural decision and its rationale**. An architectural decision addresses a requirement that is **architecturally significant** -- an ASR with "a measurable effect on the architecture and quality of a software and/or hardware system." If the change is not architecturally significant, an ADR is the wrong tool -- route via the alternatives catalog.

### Beyond architecture -- "decision records" more broadly

The same form generalizes to product, business, policy, security-program, and process decisions -- anywhere a justified, hard-to-reverse choice deserves a rationale that outlives its authors. Convention: rename `docs/adr/` to `docs/decisions/` and relax the ASR test to "is this decision worth recording at all?" Templates, lifecycle, numbering, immutability, and Relationships-mirror rules hold unchanged. Umbrella: [github.com/joelparkerhenderson/architecture-decision-record](https://github.com/joelparkerhenderson/architecture-decision-record); see also `references/adr-template-catalog.md`.

## The alternatives catalog (when NOT to write an ADR)

When the diagnostic says "not an ADR," route via `references/alternatives-catalog.md` -- it maps every common impulse to the correct doc form, explains why an ADR would be wrong, and names the **Diátaxis four** (tutorial / how-to / reference / explanation). ADRs are *not* Diátaxis explanations. Load it whenever the user debates "ADR vs RFC vs design doc vs runbook vs how-to" or asks "where should I document X?"

## ADR canon

### Template selection

Pick the smallest template that captures the decision honestly:

| Template          | Use when...                                                                                | Don't use when...                                |
|-------------------|--------------------------------------------------------------------------------------------|--------------------------------------------------|
| **Nygard / MADR light** | Decision is simple, alternatives obvious, three to five fields suffice (Context, Decision, Consequences). | You need to compare 3+ alternatives on multiple criteria. |
| **MADR (full)**   | Multiple options need side-by-side analysis; decision drivers matter; Confirmation/Validation field needed; traceability matters. | The decision is trivial -- full MADR pads it. |
| **Y-statement**   | One sentence: *"In the context of X, facing Y, we decided Z, to achieve W, accepting that V."* Good for compact log entries or executive summaries. | The decision needs structured fields. |
| **arc42 / Tyree-Akerman / Business case** | The project already uses one. | Starting fresh -- heavier than most teams need. |

Pick once per project; do not mix templates within a single log unless explicitly migrating.

### Canonical status lifecycle

```text
  proposed  ----accepted---->  accepted  ----changed---->  superseded
                                      |
                                      +--no-longer-applies-->  deprecated
```

Explorer-compatible status values are lowercase `proposed`, `accepted`, `deprecated`, `superseded`. Do not overload `status` with `rfc`, `rejected`, `backfilled`, or explanatory strings.

- **proposed** -- under discussion, including ADRs serving as RFCs (add `rfc-deadline`, do not invent `status: rfc`).
- **accepted** -- in force.
- **superseded** -- replaced by a later ADR; the new ADR's `supersedes` list creates the edge.
- **deprecated** -- no longer applies but no new decision replaces it, or a proposal rejected but kept for its "why not." Explain in body, not `status`.

### Immutability and supersession

The cardinal rule: **"Don't alter existing information in an ADR."** Amend or supersede.

- Once Accepted, the body is append-only: typo fixes, a `superseded by` note, dated entries under an "Amendments" heading.
- A changed decision is a **new ADR** naming the old one in `supersedes`. The old ADR may get a `superseded by: NNNN` reader note but otherwise stays untouched. The new ADR's `supersedes` list is the edge; `superseded-by` body prose is not.
- Teams preferring "living document" with dated inline amendments must state it up front in the log's `README.md`.

### Numbering, naming, ownership

- **Numbering**: monotonically increasing, zero-padded (`0001`, `0002`, ...). Never reuse. The number IS the identity.
- **Filename**: zero-padded id + present-tense imperative phrase, lowercase, hyphenated, `.md` (`0007-use-postgres-for-primary-store.md`).
- **Ownership**: `deciders` as a YAML array (accountable); optionally `consulted` / `informed` (MADR RACI). "The team" is not an owner.
- **Date**: ISO 8601. Stamp at acceptance, not first draft.
- **Review cadence**: a concrete trigger on the ADR ("Revisit when we exceed 10k QPS"), not "revisit annually."

### Required fields

Every ADR contains:

1. **Title** -- `NNNN. Decision (imperative verb phrase)`.
2. **YAML frontmatter -- mandatory.** A `---` block with at minimum `title`, `status`, `date`, `deciders`. Add `supersedes` / `amends` / `relates-to` when relationships exist. Optional: `tags`, `review-by`, `expires`, `confidence: high|medium|low`, `confidence-score`, `rfc-deadline` (when `status: proposed` acts as an RFC). Gray-matter parsers read only the frontmatter; missing it orphans the node.
3. **Body Relationships mirror -- mandatory whenever frontmatter relationships exist.** MADR 4.0.0 `## More Information` → `### Relationships`, link-prefix vocabulary (`Supersedes`, `Superseded by`, `Amends`, `Amended by`, `Related to`). Body-scanning parsers read only this section; the two surfaces must agree.
4. **Context** -- the architecturally significant forces; a stranger three years later understands why this had to be decided now.
5. **Decision** -- the choice, present tense, standing alone.
6. **Decision drivers** *(MADR)* or implicit in Context *(Nygard)*.
7. **Alternatives considered** -- realistic ones at the same level of abstraction, each with a one-paragraph "why not." Skip pseudo-alternatives.
8. **Consequences** -- **Good, because...** and **Bad, because...** plus follow-up work.
9. **Confirmation / Validation** *(MADR full)* -- how compliance is enforced.
10. **Re-evaluation triggers** -- concrete conditions that should cause a new ADR to supersede this one.

### Storage and discoverability

- Keep ADRs **in the source repository, in source control**, alongside the code they govern.
- Explorer-friendly locations: `docs/adr/`, `docs/decisions/`, `docs/architecture/decisions/`, `**/adr/*.md`. Pick one; document it in the log's `README.md`.
- Provide an **index** in that `README.md` listing every ADR with status and a one-line summary. The index is navigation, not the graph; index-hub links are not edge signals.
- **Default to MADR 4.0.0 + frontmatter + body Relationships mirror.** Frontmatter `supersedes` / `amends` / `relates-to` feed gray-matter parsers; body `### Relationships` feeds body-scanning parsers; either alone half-renders. If the project already uses Nygard, Y-statement, arc42, or Tyree-Akerman, follow it. MADR: [adr.github.io/madr/](https://adr.github.io/madr/), source [github.com/adr/madr](https://github.com/adr/madr).
- Body lines like `Related ADRs:` outside `### Relationships`, or `Related docs:` in `### Notes`, are courtesy navigation -- not edges.
- **ID format in frontmatter lists:** zero-padded four-digit strings (`"0008"`). Explorer parsers extract digits with `/(\d+)/` and zero-pad, so `8`, `"08"`, `"0008"`, `"ADR-0008"` resolve identically -- but zero-padded strings render and sort predictably.
- Cross-link from code when feasible (`// See docs/adr/0007-use-postgres-for-primary-store.md`).
- State the governance rule for relationship-link maintenance: if Accepted ADRs are immutable, either allow metadata-only relationship-list edits + body Relationships additions, or require a named exception.
- Offline canon check: `plugins/doc-master/scripts/validate_adrs.py`. See `plugins/doc-master/scripts/README.md` for the full per-file check list and CLI flags. Use during `/doc-audit` or as a CI gate, not as a substitute for the four-question check.

#### Canonical mirror example

```md
---
title: "Use Postgres for primary store"
status: accepted
date: 2026-05-20
deciders: [Jane Doe]
supersedes: ["0004"]
relates-to:
  - id: "0011"
    reason: "shares the tenancy model decided in 0011"
---

# 0017. Use Postgres for primary store

## More Information

### Relationships

- Supersedes [ADR-0004](0004-use-dynamodb-for-primary-store.md) -- replaced because Q3 reporting needs sub-200ms joins.
- Related to [ADR-0011](0011-tenancy.md) -- shares the tenancy model decided in 0011.
```

Both surfaces must agree. Stray `Related ADRs:` lines in `### Notes`, index-hub entries, or `superseded-by` body notes are courtesy navigation, not edges.

### Repo-level cornerstones around the decision log

A decision log sits inside a broader set of community-health files: README, LICENSE, CONTRIBUTING, CODE_OF_CONDUCT ([opensource.guide four-file canon](https://opensource.guide/starting-a-project/)), plus the extended GitHub profile (SECURITY, SUPPORT, CODEOWNERS, FUNDING, CITATION, `.github/` templates). doc-master does not auto-create any of these; the four-question diagnostic still applies. Full canon in the `repo-health` skill -- load it when the user sets up community-health files, audits repo bootstrap docs, or picks a license / code-of-conduct / contribution guide.

## ADR failure modes

The eleven canonical failure modes (drift, ADR-PRD duplication, bundled decisions, premature ADR, template thrash, decision-by-AI-without-buy-in, and the rest) with symptoms and remedies: `references/failure-modes.md`. Load during audits and `adr-critique`.

## Folder-level audit procedure (used by `/doc-audit`)

Follow the eight-step procedure in `references/audit-procedure.md`: Inventory → ADR-canon test → four-question test → drift → duplication → misclassification → backfill-candidate detection (ASR test against shipped-change evidence) → numbered KEEP / MERGE / REWRITE / DELETE / MOVE / **BACKFILL-ADR** action list.

`BACKFILL-ADR` is a candidate, not a draft -- the audit surfaces it; the architect decides whether to load `adr-backfill`. Evidence must appear in two independent locations; `reconstruction-confidence: low` routes to `open-questions.md`. The procedure file pins the hard constraints (no body edits on Accepted ADRs, no bulk renumbering, no auto-generated Owners, no deletion without sign-off) and the post-approval flow.

## Anti-padding rule

Every doc recommended must answer all four diagnostic questions (Purpose, Audience, Owner, Update trigger). If one is unanswerable, the doc should not exist yet. This applies to ADRs, RFCs, how-tos, references, explanations, tutorials, runbooks, READMEs, and CONTRIBUTING alike. Documentation is a cost as well as a benefit -- the right number is the smallest number that keeps the system understandable, operable, and decisive.

## References

- `references/alternatives-catalog.md` -- Diátaxis / RFC / runbook routing
- `references/failure-modes.md` -- eleven ADR failure modes with remedies
- `references/audit-procedure.md` -- folder-level audit procedure with hard constraints
- `references/changelog-canon.md` -- Keep a Changelog 1.1 + SemVer 2.0.0
- `references/runbook-canon.md` -- runbook structure for paged incidents (not how-to)
- `references/postmortem-canon.md` -- blameless postmortem (PagerDuty + Google SRE)
- `references/open-questions-canon.md` -- standalone open-questions register
- `references/agentic-docs-canon.md` -- `AGENTS.md` convention for AI-agent context
- `references/adr-template-catalog.md` -- template index (Nygard / MADR short / MADR long / Y-statement / Tyree-Akerman / arc42 §9)
- `../_shared/adr-is-not.md` -- canonical "ADR is NOT" checklist
- `adr-discovery`, `adr-drafting`, `adr-critique` skills
- `c4-model` skill -- canonical-C4 LikeC4 diagrams
- `repo-health` skill -- community-health files (README / LICENSE / CONTRIBUTING / CODE_OF_CONDUCT / SECURITY / SUPPORT / templates / REUSE-SPDX)
