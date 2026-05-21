---
description: Audit documentation and ADR coverage against the four-question test and ADR canon. Finds stale/cluttered docs plus architecture decisions visible only in code/history, surfacing BACKFILL-ADR candidates without drafting. Produces a KEEP / MERGE / REWRITE / DELETE / MOVE / BACKFILL-ADR action list — does not delete anything without sign-off.
---

# /doc-audit

Use this command to clean up a documentation directory that has accumulated drift, duplication, misclassified docs, or ADRs that violate the canon. When requested, it also scans outside docs for architecture decisions visible only in code or history and surfaces missing-record candidates as `BACKFILL-ADR` rows.

## What this command does

Hands the audit to the `doc-expert` agent, which will:

1. **Inventory** — glob the target directory (default `docs/`) and group files by inferred type: ADR, RFC, runbook, how-to, reference, explanation, tutorial, README, loose markdown.
2. **Test every ADR against the canon** — Status present? Owners / Deciders named? Alternatives surfaced? Consequences listed (good *and* bad)? Re-evaluation triggers present? Supersession links bidirectional? Numbering monotonic? Filename in imperative verb phrase?
3. **Test every non-ADR against the four questions** — Purpose, Audience, Owner, Update trigger. Files that fail two or more get flagged.
4. **Detect drift** — cross-reference ADR claims against the current codebase (e.g., ADR says "we use Postgres" but the codebase has switched to SQLite).
5. **Detect duplication** — two docs answering the same question; the loser becomes a redirect to the winner.
6. **Detect misclassification** — a "decision" doc that's actually a how-to; a "runbook" that's actually an explanation. Each move is justified by the Diátaxis quadrant the doc actually belongs in.
7. **Detect missing records** — when scope includes code/history, scan for architecturally significant decisions visible in commits, migrations, dependency manifests, infra files, removed dependencies, retired modules, vendor removals, or subsystem retirements. Emit `BACKFILL-ADR` candidates only when the ASR test passes and evidence has two independent locators where possible.
8. **Produce a numbered action list** — `KEEP / MERGE / REWRITE / DELETE / MOVE / BACKFILL-ADR` per file or candidate, with a one-sentence rationale.

## Your input

Optional — by default the agent audits `docs/`. You can scope to a subdirectory (e.g., "audit only `docs/adr/`") or expand to additional locations (e.g., "include `architecture/` and the root-level `*.md` files"). If you ask for missing ADRs or architecture archaeology, the default scan expands beyond docs to commit history, migrations, dependency manifests, infra files, removed dependencies, retired modules, vendor removals, and subsystem retirements.

Optionally tell the agent:

- **What "drift" looks like for this repo** — which ADRs you suspect are out of sync with the code.
- **The project's stance on immutability vs living-document ADRs** — if you've not stated it in the decision log's `README.md`, the agent will recommend you state it explicitly.
- **Which docs are off-limits** — generated files, third-party imports, license boilerplate.

## What the command will NOT do

- Delete or move files without your explicit sign-off on the action list.
- Edit an Accepted ADR's body. Header-only metadata or human-readable supersession notes require your sign-off; ADR Explorer graph edges belong in the new ADR's `supersedes` list.
- Bulk-renumber ADRs.
- Auto-generate Owners / re-evaluation triggers for ADRs missing them — those need human input.
- Draft backfilled ADRs from scan results. `BACKFILL-ADR` rows are candidates; recording them requires explicit human confirmation and the `adr-backfill` flow.

After you approve the action list, the agent executes the actions one file at a time, summarizing each change so you can stop the audit at any point.
