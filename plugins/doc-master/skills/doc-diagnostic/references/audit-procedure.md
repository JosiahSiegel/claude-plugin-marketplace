# Folder-level audit procedure (used by /doc-audit)

The canonical procedure for auditing an existing doc set. The `/doc-audit` command hands the audit to the `doc-expert` agent, which loads `doc-diagnostic` and follows this procedure.

This reference is the long-form spec. The short pointer in `SKILL.md` and the user-facing description in `commands/doc-audit.md` both route here.

## Inputs

- **Target directory** — default `docs/`. The user may scope to a subdirectory (e.g., `docs/adr/`) or expand to additional paths (e.g., `architecture/` plus root-level `*.md`).
- **Optional context** — which ADRs the user already suspects of drift; the project's stance on immutability vs living-document ADRs; files to exclude (generated docs, third-party imports, license boilerplate).

## The procedure

1. **Inventory.** Glob the target directories. Count files, group by type:
   - ADR (under `adr/`, `decisions/`, or with ADR-shaped filenames)
   - RFC (under `rfcs/` or with explicit "Status: Open / Closed" headers)
   - Runbook (under `runbooks/` or with operational/incident framing)
   - Diátaxis: how-to, reference, explanation, tutorial
   - README / index files
   - Loose markdown that doesn't fit any of the above

2. **Test each ADR against the canon.** For every ADR check:
   - Status set (Proposed / Accepted / Superseded / Deprecated / Rejected)?
   - Owners / Deciders named (humans, not "the team")?
   - Alternatives considered, at the same level of abstraction?
   - Consequences listed — both Good and Bad?
   - Re-evaluation triggers present and concrete (not "annually")?
   - Supersession links bidirectional?
   - Numbering monotonic? Filename in imperative verb phrase?
   - Each failure points to a row in `references/failure-modes.md`.

3. **Test each non-ADR against the four questions.** Purpose / Audience / Owner / Update trigger (see `SKILL.md` "The four-question diagnostic"). Files that fail two or more should be flagged for deletion or rewrite.

4. **Detect drift.** Cross-reference ADR claims with the code. If the ADR says "we use Postgres" and the codebase has switched to SQLite, flag it. Drift is the most common failure mode in long-lived doc sets.

5. **Detect duplication.** Two docs that answer the same question should be merged; the duplicate becomes a redirect to the canonical.

6. **Detect misclassification.** A "decision" doc that's actually a how-to should be moved. A "runbook" that's actually an explanation should be moved. Cite the Diátaxis quadrant for each move (see `references/alternatives-catalog.md`).

7. **Report.** Produce a numbered list of recommended actions:
   - `KEEP` — passes the canon and the four-question test as-is.
   - `MERGE` — overlaps with another doc; specify the merge target.
   - `REWRITE` — content is salvageable but violates the canon or fails the four-question test.
   - `DELETE` — fails the four-question test with no salvage path. Requires human approval.
   - `MOVE` — wrong location for its content type. Specify the new path and the Diátaxis quadrant.

   Each entry gets a one-sentence rationale. Do not bulk-delete without human approval.

## Hard constraints

- Never delete or move a file without explicit human sign-off on the action list.
- Never edit an Accepted ADR's body. Header-only edits (e.g., adding `Superseded by: NNNN`) are allowed, body changes require a superseding ADR drafted via `adr-drafting`.
- Never bulk-renumber ADRs. Numbers reflect creation order; gaps and out-of-order acceptance are fine.
- Never auto-generate Owners or re-evaluation triggers for ADRs that lack them — those need human input. Flag them in the action list as `REWRITE — needs Owner / re-evaluation trigger input`.

## Execution after approval

After the user approves the action list, execute the actions one file at a time, summarizing each change so the user can stop the audit at any point. Batch execution is allowed only when the user explicitly approves a group of actions ("apply all MOVEs," "apply all DELETEs").
