---
description: Scan code and history for architecturally significant decisions that lack ADRs. Produces BACKFILL-ADR candidates and open questions only; never drafts without human confirmation.
---

# /adr-scan

Use this command when a repository's architecture may be under-documented and you want to find past decisions that are visible in code or history but missing from the decision log.

## What this command does

Hands the scan to the `doc-expert` agent, which activates `doc-diagnostic` and uses the backfill-candidate portion of the audit procedure. The agent will:

1. **Find existing records** — locate ADR/decision-log roots and index what is already recorded.
2. **Scan shipped-change evidence** — inspect commit history, migrations, dependency manifests, infra files, removed dependencies, retired modules, vendor removals, and subsystem retirements.
3. **Apply the ASR test** — keep only decisions with a measurable effect on architecture or quality.
4. **Require evidence** — cite two independent evidence locators where possible; a single commit message is not enough for a confident candidate.
5. **Produce candidates plus questions** — output `BACKFILL-ADR` rows for medium/high-confidence cases and open questions for low-confidence or one-locator findings.

## Outputs

- `BACKFILL-ADR` candidates only — not drafts.
- Open questions naming what evidence or human context would upgrade a weak finding.

## Your input

Tell the agent the scan scope: whole repo, a time range, a subsystem, a vendor migration, a module retirement, or a suspect decision-log gap.

## What this command will NOT do

- Draft or save an ADR without explicit human confirmation.
- Emit a candidate that fails the ASR test.
- Treat one evidence locator as enough for a confident backfill.
- Invent deciders, alternatives, dates, or rationale.
- Edit existing docs or ADRs.

Use `/doc-audit` when you also want doc cleanup classification (`KEEP / MERGE / REWRITE / DELETE / MOVE`). Use `/adr-scan` when the goal is specifically finding missing ADRs from code/history evidence.
