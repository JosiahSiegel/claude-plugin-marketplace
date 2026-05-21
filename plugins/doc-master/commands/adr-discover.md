---
description: Run the zero-hallucination pre-flight Q&A before writing an ADR. Confirms domain, components, relationships, related ADRs, and decision-makers one fact at a time. Produces a discovery brief and an open-questions register. Use BEFORE drafting if context is fuzzy.
---

# /adr-discover

Use this command when you (or another agent) want to write an ADR but the context isn't pinned down yet — the components, the relationships, the related decisions, the decider, or the architectural characteristic under pressure.

## What this command does

Hands the request to the `doc-expert` agent, which activates the `adr-discovery` skill. The skill:

1. **Scans, doesn't summarize** — globs ADR directories, manifests, READMEs, and LikeC4 files. Reports raw findings only. Optionally offers a live LikeC4 diagram during discovery.
2. **Confirms the domain** — one question, one answer, one line in the brief.
3. **Confirms components one at a time** — defines `component` as a C4 Container, then walks each candidate. Hard limit of 5 components per decision.
4. **Confirms relationships with human-written descriptions** — "A talks to B" is not a description.
5. **Confirms related ADRs** — each existing ADR classified as `supersedes` / `amends` / `relates-to` / `tension` / `unrelated` by you, not by inference.
6. **Probes multi-repo and ecosystem** — owners, access, platform-level ADRs, compliance constraints.
7. **Runs the checklist gate** — domain, characteristic under pressure, ≤5 components, related ADRs, named decision-maker.
8. **Optionally hands off to `c4-model`** — for a canonical Context + Container diagram.
9. **Hands off to `adr-drafting`** — only when the gate passes.

## Outputs

- `docs/architecture/discovery-brief.md` — append-mostly, every fact tagged `[CONFIRMED YYYY-MM-DD]`.
- `docs/architecture/open-questions.md` — unknowns and parked items, deliberately outside the directories ADR-parser tools walk.

## Your input

Describe in one sentence what decision is on the table. The agent will take it from there — one question per turn.

## What this command will NOT do

- Assert any fact the architect hasn't confirmed.
- Promote `FROM CODE, UNCONFIRMED` findings into the brief without an explicit yes.
- Advance to drafting while any MUST is `UNKNOWN` or `PARKED` (PARKED MUSTs are surfaced in the eventual ADR's Consequences, but discovery still refuses to hand off).

Use `/adr-new` once the discovery brief is complete — it runs the diagnostic and routes to `adr-drafting` (for genuine decisions) or to the alternative-doc-form path (for non-decisions).
