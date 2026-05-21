# doc-master

Documentation diagnostic, Markdown style, and Architecture Decision Record (ADR) expert.

**The plugin's value is avoiding unnecessary docs, routing the ones that earn their place to the right home, and keeping the Markdown of the docs that exist clean.** Use it when you need to decide whether a document should exist, whether a proposed decision deserves an ADR, how to backfill a missing decision record honestly, or how to lint Markdown form without rewriting content.

## What this plugin is for

Most documentation failures are not "we didn't write enough." They are:

- ADRs written for coding conventions or settled-elsewhere policies, which become noise in the decision log.
- "Explanation" docs that try to be ADRs, "ADRs" that try to be how-tos, "how-tos" that try to be tutorials.
- Decision records that get silently edited when the decision changes — destroying the audit trail.
- Docs nobody owns, nobody reads, and nobody updates.
- Premature ADRs for in-flight proposals that should have been RFCs.

The `doc-expert` agent runs a diagnostic *before* it produces anything. It separates three concerns and routes each to the right skill:

1. **Placement** — should this doc exist, and where? Can you state its **purpose, audience, owner, and update trigger** in one sentence each? If yes, is the thing being documented **architecturally significant** — measurable effect on architecture or quality, hard to reverse, one decision (not a bundle), made (not a proposal)? If yes, it's an ADR. If no, the agent routes you to the correct alternative (Diátaxis explanation / how-to / reference / tutorial; RFC; runbook; etc.).
2. **Form** — is the Markdown clean? Two-pass lint over any `.md` file: canonical syntax (Markdown Guide) first, then opinionated style overlay (Google's Markdown style guide). Per-finding, with line numbers and verbatim quotes — never bulk-rewrites.
3. **Content** (ADR-specific) — when the doc is an ADR, is the reasoning honest? Co-thinking draft, scripted push-back, line-by-line legacy critique against the "ADR is NOT" checklist.

## What the agent knows

**ADR practice — the canon:**

- Nygard's original template (2011), MADR short and long forms (Olaf Zimmermann's primer), Y-statements, and the 12+ templates in the community reference repo.
- Template selection per project context — and the rule to pick one and stick to it.
- The ADR Explorer-compatible status lifecycle: proposed → accepted → superseded / deprecated.
- Append-only immutability and supersession instead of editing.
- ADR-to-ADR graph edges encoded in **YAML frontmatter only** — the keys `supersedes`, `amends`, and `relates-to`. Gray-matter-style parsers read frontmatter and ignore the Markdown body, so a body line such as `Related ADRs: [ADR-0001](0001-foo.md)` is human navigation, not a graph signal; index-hub links from the decision log's `README.md` are likewise ignored. ID values normalize via `/(\d+)/` and zero-pad to four characters, so `8`, `"08"`, `"0008"`, and `"ADR-0008"` all resolve to the same node — zero-padded four-digit strings (`"0008"`) are recommended for stable display and sorting.
- **doc-master defaults to MADR (currently 4.0.0) + YAML frontmatter unless the project has an explicit different convention.** Every ADR begins with a `---` frontmatter block (mandatory; `adr-drafting` refuses to save without it) **and** mirrors each frontmatter relationship into a body `## More Information` → `### Relationships` section using doc-master link prefixes (`Supersedes`, `Superseded by`, `Amends`, `Amended by`, `Related to`). The two sources must agree. This dual-source convention is what makes the ADR render correctly in both gray-matter-style parsers (ADR Explorer and similar) and body-scanning parsers (ADR Manager and similar).
- Numbering discipline (monotonic, zero-padded, never reused), naming (filenames start with the numeric id, then an imperative verb phrase), and RACI ownership (Deciders / Consulted / Informed).
- The required fields: Title, Status, Date, Owners, Supersedes, Related requirements (ASRs), Related ADRs, Related docs, Context, Decision, Decision drivers, Alternatives, Consequences, Confirmation/Validation, Re-evaluation triggers.

A quick offline validator for this canon ships at [`scripts/validate_adrs.py`](scripts/validate_adrs.py) — a stdlib-only Python script that enforces the doc-master canon against both gray-matter-style and body-scanning ADR parser families (frontmatter required keys, status lifecycle, graph edges, and the frontmatter ↔ body Relationships mirror). See [`scripts/README.md`](scripts/README.md) for the full per-file check list and CLI usage.

**The alternatives catalog — when NOT to use an ADR:**

| User impulse                                          | Right home                                          |
|-------------------------------------------------------|-----------------------------------------------------|
| Coding convention / style                             | `CONTRIBUTING.md` or linter config                  |
| "How to do X"                                         | Diátaxis **how-to guide**                           |
| "Why does the system look like this?"                 | Diátaxis **explanation**                            |
| API / schema / config lookup                          | Diátaxis **reference**                              |
| Onboarding lesson                                     | Diátaxis **tutorial**                               |
| In-flight proposal                                    | **RFC** / design doc — ADR only when accepted       |
| Incident response steps                               | **Runbook**                                         |
| Open research question                                | **Open-questions register**                         |
| Reversible product/UX detail                          | **PR description** / changelog                      |
| Architecturally significant, hard-to-reverse choice   | **ADR**                                             |

**The Diátaxis four** (diataxis.fr): tutorials are *learning-oriented*, how-to guides are *task-oriented*, reference is *information-oriented* (austere, neutral), explanation is *understanding-oriented* (discursive, considers alternatives). ADRs are none of these — they record *decided choices and their rationale*, which is a fifth category.

**ADR failure modes the agent will detect and remediate:**

drift, ADRs for non-decisions, ADR–PRD duplication, ADRs nobody reads, missing context, missing re-evaluation triggers, hidden alternatives, bundled decisions, premature ADRs for proposals, template thrash, decision-by-AI without human buy-in, **unrecorded past decisions** (surfaced as `BACKFILL-ADR` candidates during a `/doc-audit` and recorded via `adr-backfill` with a mandatory honesty clause).

## When the agent activates

PROACTIVELY, when the user (or another agent):

- Asks to "write an ADR," "document a decision," or "record an architectural decision."
- Is about to create any new doc file under `docs/`, `architecture/`, `adr/`, `decisions/`, `rfcs/`, or `design/`.
- Wants to review, audit, or clean up an existing decision log or design-doc folder.
- Suspects a past architectural decision was made but never written up, and wants to surface or record it.
- Debates "should this be an ADR or something else?"
- Mentions "supersede," "deprecate," or "revisit" relative to a prior doc.
- Suspects doc drift, dead docs, or duplicated decision records.
- Bootstraps doc governance in a repo without one yet.
- Wants Markdown form review — "review this README," "lint this doc," "fix the formatting," "what's the heading style here," "is this Markdown valid," "style-check this doc."

The most important interception is **before** an ADR gets written for a non-decision — because once it's in the log, it's noise that takes social effort to remove. The second most important is form review on docs that *did* earn their place, so they age well.

## Commands

- **`/adr-new`** — Run the diagnostic on a proposed decision. If the decision is architecturally significant and made, draft the ADR using the project's existing template, with every required field populated honestly (or marked `TBD — needs <specific info>`). If not, route to the correct alternative form and explain why an ADR would be wrong.

- **`/adr-discover`** — Run the zero-hallucination pre-flight Q&A *before* drafting. Confirms the domain, the architectural characteristic under pressure, the components (≤5), the related ADRs, and the named decider — one fact at a time. Produces a discovery brief and open-questions register in the project's documentation area. Use when context is fuzzy.

- **`/adr-critique`** — Audit a pre-existing or legacy ADR line by line. Quotes the offending line verbatim, names the rule broken, proposes a shorter rewrite, requires per-line approval. For ADRs that didn't go through the co-thinking flow.

- **`/doc-audit`** — Inventory a doc directory, test every ADR against the canon, test every non-ADR against the four-question check (Purpose / Audience / Owner / Update trigger), detect drift, duplication, misclassification, and *unrecorded past decisions* (the ASR test against shipped-change evidence — commits, migrations, removed subsystems, retired vendors). Produces a KEEP / MERGE / REWRITE / DELETE / MOVE / **BACKFILL-ADR** action list. `BACKFILL-ADR` rows are candidates only; the user decides whether to route them to `adr-backfill` for retroactive recording. Nothing is deleted without your sign-off.

- **`/adr-scan`** — Scan code and history for architecturally significant decisions missing from the decision log. Produces `BACKFILL-ADR` candidates plus open questions only; never drafts without human confirmation. Use it for inherited repos, architecture archaeology, vendor removals, subsystem retirements, migrations, and suspicious ADR coverage gaps.

- **`/doc-lint`** — Two-pass Markdown lint on any one file. Pass 1 (syntax must-fix) flags non-portable Markdown — setext where ATX is expected, unfenced code blocks, missing blank lines around block elements, mid-word underscore emphasis, etc. Pass 2 (style should-fix) applies the opinionated Google Markdown style overlay — single H1, ATX headings, `[TOC]` on long docs, 80-character lines, informative link text, fenced blocks with language tags. One finding at a time, per-line approval, no bulk rewrites.

Most of the time you don't need a command — just describe the doc situation and the agent will load the right skill (`doc-diagnostic`, `adr-discovery`, `adr-drafting`, `adr-backfill`, `adr-critique`, `c4-model`, `markdown-style`, or `repo-health`). The commands give common workflows a one-token entry point. There is intentionally no top-level `/adr-backfill` or `/repo-health` command — backfill is reached either through a `/doc-audit` `BACKFILL-ADR` row or through direct user phrasing ("we decided years ago and never wrote it down"), and `repo-health` activates from prose ("set up community-health files", "review our CONTRIBUTING.md", "audit our repo bootstrap docs"). Both stay command-less to keep them from becoming the easy-default path they should not be.

## Skills

The deep ADR mechanics live in skills, loaded by the agent when relevant. The canonical trigger list for each skill is the `description:` frontmatter of the skill's `SKILL.md` — the table below gives a one-line prose summary, not a re-enumeration of triggers.

| Skill | What it does |
|---|---|
| **`doc-diagnostic`** | The canon: alternatives catalog, ADR templates / lifecycle / numbering / required fields, failure-modes table, folder-level audit procedure. Loaded when the question is "where does this doc belong?" or "how do I clean up this doc set?" |
| **`adr-discovery`** | Pre-flight context gathering for an ADR. Produces a `discovery-brief.md` and `open-questions.md` containing only architect-confirmed facts; refuses to advance until five MUSTs are confirmed. |
| **`adr-drafting`** | Seven-phase co-thinking draft of a new ADR with one question per turn, scripted push-back, and a self-critique pass against the "ADR is NOT" checklist before the architect sees a draft. Tense: *"we decided / we're deciding."* |
| **`adr-backfill`** | Retroactive write-up of a past architectural decision that was never recorded — typically surfaced by a `/doc-audit` `BACKFILL-ADR` row. Tense: *"we decided years ago / before my time / never wrote it down."* Looser gates than `adr-drafting` (decider may be `unrecoverable`, alternatives may be partial) but stricter honesty: evidence in two independent locations, a mandatory backfill notice in the body, refusal when reconstruction confidence is `low`. |
| **`adr-critique`** | Line-by-line audit of a legacy ADR. Verbatim quotes, per-line approval, no bulk edits. Also flags backfill ADRs missing or softening the honesty clause. |
| **`c4-model`** | Canonical-C4 LikeC4 diagram alongside an ADR — Context + Container views (+ optional Deployment). Refuses Component / dynamic / custom-kind views. |
| **`markdown-style`** | Markdown form review on any `.md` file. Two-pass — canonical syntax (Markdown Guide) must-fix first, opinionated style (Google Markdown style guide) should-fix second. Per-finding with line numbers, verbatim quotes, rule citations; never bulk-rewrites. |
| **`repo-health`** | Repository community-health and cornerstone files: README (Standard Readme), LICENSE (routed to choosealicense.com — doc-master does not pick), CONTRIBUTING, CODE_OF_CONDUCT (Contributor Covenant 3.0 default; 2.1 fallback), SECURITY, SUPPORT, `.github/` templates (issues, PRs, CODEOWNERS, FUNDING, CITATION), and REUSE 3.3 / SPDX per-file licensing metadata. Four-question diagnostic per file before recommending creation; refuses single-maintainer contact lines in SECURITY / CODE_OF_CONDUCT. |

A shared **`_shared/adr-is-not.md`** enforces the canonical "must not" checklist across the four ADR-flow skills (`adr-discovery`, `adr-drafting`, `adr-backfill`, `adr-critique`) and the `doc-expert` agent: an ADR is not a tutorial, an implementation guide, a marketing doc, a hedge, a generic best-practice citation, an LLM probability summary, a future-proofing essay, corporate passive voice, a design doc, or long. Hard limits: Context ≤ 3 sentences, Decision ≤ 3 sentences, Consequences as bullets.

A sibling **`_shared/adr-is-backfillable.md`** is the positive-polarity counterpart, used only by `adr-backfill`: the seven-item eligibility self-check that decides whether a past, unrecorded decision is reconstructible to a standard that would justify a backfilled record (observable evidence in the system, ASR-test pass, evidence in two independent locations, measurable architectural-characteristic signal, not already recorded, reconstruction confidence at least `medium`, decider nameable or explicitly `unrecoverable`).

The mandatory backfill **honesty clause** — its verbatim form, required fields, terminal punctuation, and refusal conditions — lives in `skills/adr-backfill/references/honesty-clause.md`. It is the single source of truth: `adr-backfill` writes from it during Phase 3 and `adr-critique` audits against it. Do not restate the clause elsewhere.

**Recent additions:** the `repo-health` skill covers community-health files (README / LICENSE / CONTRIBUTING / CODE_OF_CONDUCT / SECURITY / SUPPORT / `.github/` templates / REUSE 3.3 + SPDX). `doc-diagnostic` gained canonical references for **changelog** (Keep a Changelog 1.1 + SemVer 2.0), **runbook** (PagerDuty Incident Response template; distinct from Diátaxis how-to), **postmortem** (PagerDuty template + Google SRE Workbook framing), **open-questions register** (the legitimate alternative to a premature ADR), **AGENTS.md** (vendor-neutral AI-agent context — the right home for "we use agent X" rather than an ADR), and an **ADR template catalog** (Nygard / MADR / Y-statement / Tyree-Akerman / arc42, with the Y-statement template inline). Spec-version corrections: MADR is referenced as currently 4.0.0 (was 3.0); Contributor Covenant defaults to 3.0 with the four-rung Enforcement Ladder and Encouraged-vs-Restricted split (2.1 remains a valid fallback).

## Typical workflow

- **New decision** — start with `/adr-new` (or describe the situation). The agent runs the diagnostic. If it's not an ADR, you get routed to the right alternative (Diátaxis explanation, RFC, runbook, code comment, etc.). If it is an ADR but discovery is shallow, run `/adr-discover` first; otherwise drafting begins.
- **Drafting** — once the five MUSTs are confirmed, `adr-drafting` produces the ADR through the seven-phase co-thinking flow.
- **Diagram (optional)** — after saving, `c4-model` adds canonical Context + Container views alongside the ADR.
- **Audit existing docs** — `/adr-critique` for one legacy ADR (line-by-line); `/doc-audit` for a whole directory (KEEP / MERGE / REWRITE / DELETE / MOVE / BACKFILL-ADR).
- **Find missing ADRs** — `/adr-scan` for code/history archaeology when ADR coverage is suspect but you don't need full doc cleanup.
- **Backfill a past decision** — when `/doc-audit` or `/adr-scan` surfaces a `BACKFILL-ADR` candidate (or the user describes a long-ago shipped change with no record), `adr-backfill` retroactively records it. Mandatory honesty clause; evidence in two independent locations; refuses when reconstruction confidence is `low`.
- **Lint any Markdown file** — `/doc-lint` for two-pass syntax-then-style review of one `.md` file. Works on READMEs, how-tos, runbooks, ADRs (form only — content goes through `/adr-critique`).

```text
                          New decision                    Past decision, no record
                              |                                    |
                       /adr-new (diagnostic)            /doc-audit surfaces BACKFILL-ADR
                              |                                    |
                  --------- ADR? ---------                          v
                  |                     |                     adr-backfill
                  no                   yes                          |
                  |                     |              (refuses if confidence: low,
            doc-diagnostic       discovery shallow?           routes to open-questions.md)
            (RFC / runbook /            |                          |
             Diátaxis / etc.)     yes ---+--- no                   |
                                  |          |                     |
                            adr-discovery   adr-drafting           |
                                            (7 phases)             |
                                                |                  |
                                                +--> ADR file <----+
                                                          |
                                              c4-model (optional)
                                              adr-critique (audit)
                                              doc-lint (Markdown form)
```

## Installation

Standard marketplace install:

```text
/plugin marketplace add JosiahSiegel/claude-plugin-marketplace
/plugin install doc-master@claude-plugin-marketplace
```

## What this plugin does NOT do

- Write the code or implementation that the decision governs.
- Maintain product backlog / Jira / Linear tickets — those are work items, not decisions.
- Enforce **prose** style — sentence structure, tone, terminology consistency. Markdown form (headings, code fences, lists, link syntax, line length) is in scope via `markdown-style`; prose-level style is not.
- Enforce **coding** style — that's what linters and `CONTRIBUTING.md` are for. The agent will explicitly route you there for coding-convention questions.
- Decide for you. The Owners / Deciders field exists because humans decide; the agent drafts.

## Rationale

The remaining ADR failure mode is not "we don't know how to write ADRs" — it is "we write them for the wrong things." This plugin's diagnostic filter is the differentiator.

## Sources

- [adr.github.io](https://adr.github.io/) — umbrella site for ADR practice
- [adr.github.io/ad-practices](https://adr.github.io/ad-practices/) — practices catalog
- [community reference repo](https://github.com/architecture-decision-record/architecture-decision-record) — templates, examples, anti-patterns
- [Olaf Zimmermann's MADR primer](https://www.ozimmer.ch/practices/2022/11/22/MADRTemplatePrimer.html) — when MADR vs Nygard, decision drivers, Y-statements
- Michael Nygard, "Documenting Architecture Decisions" (2011) — the seed template
- [ThoughtWorks Technology Radar: Lightweight ADRs](https://www.thoughtworks.com/radar/techniques/lightweight-architecture-decision-records) — Adopt-ring, source-control storage
- [Diátaxis](https://diataxis.fr) — tutorial / how-to / reference / explanation framework for the alternatives catalog
- [Markdown Guide — Basic Syntax](https://www.markdownguide.org/basic-syntax/) — canonical Markdown syntax reference (CC BY-SA 4.0), distilled into the `markdown-style` skill's syntax-canon layer
- [Google developer documentation — Markdown style guide](https://google.github.io/styleguide/docguide/style.html) — opinionated Markdown style (Apache 2.0), distilled into the `markdown-style` skill's style-overlay layer

## Acknowledgments

ADR workflow capabilities were informed by the open-source `deep-adr` project. The Markdown style skill distills the canonical Markdown Guide basic syntax (CC BY-SA 4.0) and Google's developer-documentation Markdown style guide (Apache 2.0). See [NOTICES.md](NOTICES.md) for third-party license details.

## License

MIT.
