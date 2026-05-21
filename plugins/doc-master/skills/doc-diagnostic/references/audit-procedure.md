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
   - Status set to an ADR Explorer-compatible value (`proposed`, `accepted`, `superseded`, `deprecated`) with no overloaded `rfc`, `rejected`, or backfill text?
   - Owners / Deciders named as a YAML array (humans, not "the team")?
   - Relationship fields shaped for graphing: `supersedes` and `amends` as YAML lists, `relates-to` as `{id, reason}` objects?
   - Confidence is `high`, `medium`, or `low` (with optional separate `confidence-score` if numeric scoring is used)?
   - Alternatives considered, at the same level of abstraction?
   - Consequences listed — both Good and Bad?
   - Re-evaluation triggers present and concrete (not "annually")? Optional `expires` used only when expiry is real?
   - Supersession graph edge present on the new ADR's `supersedes` list? Do not rely on `superseded-by` / `superseded by` alone.
   - Numbering monotonic? Filename starts with the numeric id and uses an imperative verb phrase?
   - ADRs live under ADR Explorer-friendly roots (`docs/adr/`, `docs/decisions/`, `docs/architecture/decisions/`, `**/adr/*.md`), or `architecture/decisions/` is documented as needing custom root configuration?
   - Each failure points to a row in `references/failure-modes.md`.

3. **Test each non-ADR against the four questions.** Purpose / Audience / Owner / Update trigger (see `SKILL.md` "The four-question diagnostic"). Files that fail two or more should be flagged for deletion or rewrite.

4. **Detect drift.** Cross-reference ADR claims with the code. If the ADR says "we use Postgres" and the codebase has switched to SQLite, flag it. Drift is the most common failure mode in long-lived doc sets.

5. **Detect duplication.** Two docs that answer the same question should be merged; the duplicate becomes a redirect to the canonical.

6. **Detect misclassification.** A "decision" doc that's actually a how-to should be moved. A "runbook" that's actually an explanation should be moved. Cite the Diátaxis quadrant for each move (see `references/alternatives-catalog.md`).

7. **Detect backfill candidates** — run the ASR test against shipped-change evidence.
   - **Surface to walk.** Commit history, migration files, dependency manifests, infra files, removed dependencies, removed subsystems, retired modules, retired vendors, policy unifications, and subsystem retirements. For each, ask: *did the team make an architecturally significant decision that was never recorded?*
   - **ASR test.** Apply the same measurable-effect-on-architecture-or-quality test used during pre-flight discovery. No measurable signal, no row.
   - **Two-locator rule (false-positive guard).** Evidence must appear in at least two independent locations before a backfill row is emitted. A single commit message alone is not enough. A commit plus a deleted module, or a migration plus a removed dependency in the manifest, is enough.
   - **No measurable signal?** Do not emit a row. Log it in `open-questions.md` instead, naming what evidence would have to surface to upgrade it.

8. **Report.** Produce a numbered list of recommended actions:
   - `KEEP` — passes the canon and the four-question test as-is.
   - `MERGE` — overlaps with another doc; specify the merge target.
   - `REWRITE` — content is salvageable but violates the canon or fails the four-question test.
   - `DELETE` — fails the four-question test with no salvage path. Requires human approval.
   - `MOVE` — wrong location for its content type. Specify the new path and the Diátaxis quadrant.
   - `BACKFILL-ADR` — shipped-change evidence reveals a past architectural decision that was never recorded. Surface as a candidate, not a draft. Use the row schema below.

   Each entry gets a one-sentence rationale. Do not bulk-delete without human approval.

### BACKFILL-ADR row schema

Each `BACKFILL-ADR` row has exactly five fields:

| Field | Notes |
|---|---|
| `decision` | One-line imperative phrase, as if it were the title of the ADR that should have been written (e.g., *"Retire the legacy queueing vendor in favor of an in-house event bus"*). |
| `evidence-locator` | At least two independent pointers: commit SHA, migration file path, removed module path, vendor record, manifest line removed, infra-as-code resource deleted. One pointer is not enough. |
| `ASR-test-result` | Which architectural characteristic was affected (latency / cost / availability / security / maintainability / operability / portability / …) **with a measurable signal**. "Felt cleaner" is not a signal; "removed 14k LOC and one vendor dependency" is. |
| `reconstruction-confidence` | `high` / `medium` / `low`. High = the decision, its forces, and at least one realistic alternative can be reconstructed from evidence. Medium = the decision is clear but forces or alternatives are partial. Low = only the *what* is recoverable, not the *why*. |
| `suggested-status` | ADR Explorer-compatible value only: `accepted` if the decision is still in force, `deprecated` if the change was later undone or superseded. Put backfill/reversal details in `tags`, `backfilled-on`, and the honesty clause — not in `status`. |

### Backfill confidence rule

If `reconstruction-confidence` is `low`, **do not emit a BACKFILL-ADR row**. The decision is not reconstructible to a standard that would justify a record in the decision log. Emit an `open-questions.md` row instead, naming what evidence would have to surface to upgrade the confidence to `medium` or `high`. Surfacing the gap is more honest than fabricating a rationale at backfill time.

## Hard constraints

- Never delete or move a file without explicit human sign-off on the action list.
- Never edit an Accepted ADR's body. Header-only metadata or human-readable supersession notes require sign-off; ADR Explorer graph edges belong in the new ADR's `supersedes` list. Body changes require a superseding ADR drafted via `adr-drafting`.
- Never bulk-renumber ADRs. Numbers reflect creation order; gaps and out-of-order acceptance are fine.
- Never auto-generate Owners or re-evaluation triggers for ADRs that lack them — those need human input. Flag them in the action list as `REWRITE — needs Owner / re-evaluation trigger input`.

## Execution after approval

After the user approves the action list, execute the actions one file at a time, summarizing each change so the user can stop the audit at any point. Batch execution is allowed only when the user explicitly approves a group of actions ("apply all MOVEs," "apply all DELETEs").
