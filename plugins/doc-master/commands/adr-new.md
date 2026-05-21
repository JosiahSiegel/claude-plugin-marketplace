---
description: Run the "is this an ADR?" diagnostic on a proposed decision, then either draft the ADR using the project's existing template, or recommend the correct alternative documentation form.
---

# /adr-new

Use this command when you (or another agent) think a decision should be recorded as an ADR.

## What this command does

Hands the request to the `doc-expert` agent with the diagnostic-first stance. The agent will:

1. **Run the four-question check** — Purpose, Audience, Owner, Update trigger. If any are unanswerable, the agent will ask you for the missing piece before proceeding.
2. **Apply the "is this architecturally significant?" test** — measurable effect on architecture or quality? hard to reverse? one decision (not a bundle)? made (not a proposal)?
3. **If yes** — detect the project's existing decision log (`docs/adr/`, `docs/decisions/`, `docs/architecture/decisions/`, `**/adr/*.md`, or legacy `architecture/decisions/` with a custom-root warning), confirm the template flavor in use (Nygard / MADR light / MADR full / Y-statement / project-custom), compute the next ADR number, propose an imperative-verb-phrase filename that starts with the numeric id, and draft the ADR with every required field populated honestly. Fields that need human input are marked `TBD — needs <specific info>` rather than invented.
4. **If no** — name the correct alternative home (Diátaxis tutorial / how-to / reference / explanation; RFC; design doc; runbook; README; CONTRIBUTING; code comment; PR description), explain why an ADR would be wrong, and apply the four-question check to the alternative.

## Your input

Tell the agent:

- **What was decided** (or what is being proposed)
- **Why this came up now** (the forcing function — new requirement, scaling pressure, incident, vendor change, etc.)
- **Alternatives considered**, if any
- **Who the deciders are** (names — not "the team")

The agent will ask follow-up questions if any of the four diagnostic fields cannot be answered.

## What the command will NOT do

- Invent decider names, dates, or re-evaluation triggers.
- Silently edit an existing Accepted ADR. Changed decisions get a new ADR that supersedes the old one.
- Write an ADR for a coding convention, a settled-elsewhere policy, or an in-flight proposal — those get redirected to the right home.
- Bulk-renumber existing ADRs.

Use `/doc-audit` when the goal is reviewing or cleaning up an existing doc set rather than adding a new entry.
