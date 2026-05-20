# doc-master

Documentation diagnostic and Architecture Decision Record (ADR) expert.

**The plugin's value is avoiding unnecessary docs, not generating them.**

## What this plugin is for

Most documentation failures are not "we didn't write enough." They are:

- ADRs written for coding conventions or settled-elsewhere policies, which become noise in the decision log.
- "Explanation" docs that try to be ADRs, "ADRs" that try to be how-tos, "how-tos" that try to be tutorials.
- Decision records that get silently edited when the decision changes — destroying the audit trail.
- Docs nobody owns, nobody reads, and nobody updates.
- Premature ADRs for in-flight proposals that should have been RFCs.

The `doc-expert` agent runs a diagnostic *before* it produces anything. The diagnostic asks two questions:

1. Can you state this doc's **purpose, audience, owner, and update trigger** in one sentence each? If not, the doc shouldn't exist yet.
2. Is the thing being documented **architecturally significant** — measurable effect on architecture or quality, hard to reverse, one decision (not a bundle), made (not a proposal)? If yes, it's an ADR. If no, the agent routes you to the correct alternative.

## What the agent knows

**ADR practice — the canon:**

- Nygard's original template (2011), MADR short and long forms (Olaf Zimmermann's primer), Y-statements, and the 12+ templates in the community reference repo.
- Template selection per project context — and the rule to pick one and stick to it.
- The canonical status lifecycle: Proposed → Accepted → Superseded / Deprecated / Rejected.
- Append-only immutability and supersession instead of editing.
- Numbering discipline (monotonic, zero-padded, never reused), naming (imperative verb phrase), and RACI ownership (Deciders / Consulted / Informed).
- The required fields: Title, Status, Date, Owners, Supersedes, Superseded by, Related requirements (ASRs), Context, Decision, Decision drivers, Alternatives, Consequences, Confirmation/Validation, Re-evaluation triggers.

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

drift, ADRs for non-decisions, ADR–PRD duplication, ADRs nobody reads, missing context, missing re-evaluation triggers, hidden alternatives, bundled decisions, premature ADRs for proposals, template thrash, decision-by-AI without human buy-in.

## When the agent activates

PROACTIVELY, when the user (or another agent):

- Asks to "write an ADR," "document a decision," or "record an architectural decision."
- Is about to create any new doc file under `docs/`, `architecture/`, `adr/`, `decisions/`, `rfcs/`, or `design/`.
- Wants to review, audit, or clean up an existing decision log or design-doc folder.
- Debates "should this be an ADR or something else?"
- Mentions "supersede," "deprecate," or "revisit" relative to a prior doc.
- Suspects doc drift, dead docs, or duplicated decision records.
- Bootstraps doc governance in a repo without one yet.

The most important interception is **before** an ADR gets written for a non-decision — because once it's in the log, it's noise that takes social effort to remove.

## Commands

- **`/adr-new`** — Run the diagnostic on a proposed decision. If the decision is architecturally significant and made, draft the ADR using the project's existing template, with every required field populated honestly (or marked `TBD — needs <specific info>`). If not, route to the correct alternative form and explain why an ADR would be wrong.

- **`/doc-audit`** — Inventory a doc directory, test every ADR against the canon, test every non-ADR against the four-question check (Purpose / Audience / Owner / Update trigger), detect drift and duplication and misclassification, and produce a KEEP / MERGE / REWRITE / DELETE / MOVE action list. Nothing is deleted without your sign-off.

Most of the time you don't need a command — just describe the doc situation and the agent will run the right procedure. The commands exist to give common workflows a one-token entry point.

## Installation

Standard marketplace install:

```
/plugin marketplace add JosiahSiegel/claude-plugin-marketplace
/plugin install doc-master
```

## What this plugin does NOT do

- Write the code or implementation that the decision governs.
- Maintain product backlog / Jira / Linear tickets — those are work items, not decisions.
- Enforce style — that's what linters and `CONTRIBUTING.md` are for. The agent will explicitly route you there for style/convention questions.
- Pick an ADR template if the project already has one — it will adopt the project's choice.
- Decide for you. The Owners / Deciders field exists because humans decide; the agent drafts.

## Rationale

ADR practice is now ~15 years old (Nygard 2011) and well-canonicalized — adr.github.io, the community reference repo, MADR, Y-statements, the ThoughtWorks Radar's Adopt-ring endorsement. The remaining failure mode is not "we don't know how to write ADRs"; it is *"we write them for the wrong things, or skip them for the right things, or treat them as living documents and lose the audit trail."* This plugin encodes the diagnostic stance — purpose / audience / owner / update trigger, then "architecturally significant?" — that filters those failures before they reach the decision log.

The plugin contains one agent and two commands, deliberately. Adding skills would push the alternatives catalog and the canon into separate files behind a lookup, which would defeat the diagnostic — the agent needs the whole catalog in scope to route a request in one turn.

## Sources

- [adr.github.io](https://adr.github.io/) — umbrella site for ADR practice
- [adr.github.io/ad-practices](https://adr.github.io/ad-practices/) — practices catalog
- [community reference repo](https://github.com/architecture-decision-record/architecture-decision-record) — templates, examples, anti-patterns
- [Olaf Zimmermann's MADR primer](https://www.ozimmer.ch/practices/2022/11/22/MADRTemplatePrimer.html) — when MADR vs Nygard, decision drivers, Y-statements
- Michael Nygard, "Documenting Architecture Decisions" (2011) — the seed template
- [ThoughtWorks Technology Radar: Lightweight ADRs](https://www.thoughtworks.com/radar/techniques/lightweight-architecture-decision-records) — Adopt-ring, source-control storage
- [Diátaxis](https://diataxis.fr) — tutorial / how-to / reference / explanation framework for the alternatives catalog

## License

MIT.
