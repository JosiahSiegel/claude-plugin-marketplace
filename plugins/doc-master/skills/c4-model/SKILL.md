---
name: c4-model
description: |
  This skill should be used to create or update a C4 architecture diagram alongside an ADR, especially in LikeC4.
  PROACTIVELY activate on "add a C4 diagram", "create a context diagram", "container view", "LikeC4 model", "draw the architecture", "diagram this decision", "architecture diagram for the ADR", "visualize the components", "C4 view", or "Simon Brown C4."
  Provides: canonical-C4 Context and Container views from confirmed elements, relationship descriptions, and strict refusal of non-canonical diagram types.
---

# c4-model

Produces a canonical-C4 LikeC4 model — Context and Container views by default, Deployment optional. Refuses every LikeC4 feature that would push the diagram beyond Simon Brown's canonical C4. The canonical-C4 features used here are stable across LikeC4 versions; re-validate with `npx likec4 validate` to confirm against your installed version.

## What this skill makes

- A `model.c4` file containing the specification + the model
- A `<system>.c4` file scoped to the single system in focus
- A `views.c4` file with one Context view and one Container view (optionally one Deployment view)
- A `likec4.config.js` file

## What this skill refuses

| Refused thing | Why | Architect alternative |
|---|---|---|
| Component views | "Component views belong at a deeper level than ADRs work at." | Use a code-level diagram tool (e.g., Mermaid in source) — outside C4. |
| Dynamic views | Sequence/runtime flows are not canonical C4. | Use a sequence diagram tool separately. |
| Custom element kinds | Canonical C4 has Person / Software System / Container — period. | Use `container` and put the type in the `technology` attribute. |
| Custom relationship kinds | Canonical relationships: `uses`, `reads`, `writes`, `publishes`, `consumes`. | Pick the closest canonical kind. |
| Custom styles | Diagram should look recognizably C4. | If styling matters more than canonicality, use LikeC4 directly outside this skill. |
| Nested systems | C4 has Context and Container; nesting systems-in-systems muddies the levels. | Split into separate models. |
| Multiple systems in focus | One system per `.c4` file is canonical. | Make separate models for each, link via `externalSystem`. |

The refusals are the point. An architect who wants full LikeC4 freedom should not use this skill.

## Vocabulary

- **Actor** — a Person in C4 terms (a human role). Render outside the system boundary.
- **External system** — a system the team does not own. Render outside the system boundary.
- **System** — the one bounded product in focus. Exactly one per file.
- **Container** — a runnable/deployable unit inside the system in focus. Not a code class.
- **Relationship** — directed edge with a one-line description; the description is required.

## Hard rules

1. **Every relationship has a one-line description.** No description → no edge.
2. **Element names match what the architect confirmed in discovery.** Don't translate, abbreviate, or pluralize.
3. **No invented styling unless the architect explicitly requests it.**
4. **Exactly one `system` definition per `.c4` file.**

## Locked specification block

Use this `specification` block verbatim. Do not edit, extend, or rename.

```c4
specification {
  element actor {
    style {
      shape person
    }
  }
  element externalSystem {
    style {
      color secondary
    }
  }
  element system
  element container

  relationship uses
  relationship reads
  relationship writes
  relationship publishes
  relationship consumes

  tag open-question {
    style {
      color red
      border dashed
    }
  }
}
```

## Open-question convention

For elements or relationships that exist but have unresolved details:

- Add the tag `#open-question`
- Prefix the description with `OPEN Q<N>:` matching the entry number in `docs/architecture/open-questions.md`
- The style renders red + dashed — visually obvious

Example:

```c4
container payments-service "Payments Service" "OPEN Q7: tech stack unconfirmed" {
  #open-question
}
```

## The eight phases

### Phase 1 — Intake

If `docs/architecture/discovery-brief.md` exists with `CONFIRMED` elements, use it directly — do not re-ask. Otherwise walk the architect through each element one at a time (one question per turn, same discipline as `adr-discovery`).

### Phase 2 — Locate or scaffold

Glob `**/*.c4` and `**/likec4.config.*`. Two cases:

- **Files exist:** read them. Identify the system in focus. Add to the existing model if the architect confirms scope.
- **No files:** scaffold `model.c4`, `<system>.c4`, `views.c4`, `likec4.config.js` at the architect's chosen path (default `likec4/` at the repo root).

### Phase 3 — Generate DSL

Three blocks in `model.c4`:

1. **Specification** — verbatim from the locked block above.
2. **Model** — actors and external systems at top level; containers nested inside the `system` block. See `references/likec4-dsl-cheatsheet.md`.
3. **Views** — in `views.c4`: one `context` view (the system + its actors + external systems), one `container` view (containers inside the system), optionally one `deployment` view.

### Phase 4 — Canonical-C4 lint

Before validation, run the 11-item checklist:

| # | Check |
|---|---|
| 1 | Exactly one `system` definition. |
| 2 | All containers nested inside that one system. |
| 3 | All actors at top level (not inside the system). |
| 4 | All external systems at top level. |
| 5 | Every relationship has a non-empty description. |
| 6 | No relationship kinds outside the canonical five. |
| 7 | No element kinds beyond `actor`, `externalSystem`, `system`, `container`. |
| 8 | No nested systems. |
| 9 | No views beyond `context`, `container`, `deployment`. |
| 10 | Specification block matches the locked block verbatim. |
| 11 | No `#open-question` tagged element lacks a `OPEN Q<N>:` description prefix. |

Print `PASS` or `FAIL` with a numbered list of violations. Do not proceed on `FAIL`.

### Phase 5 — Show diff, not apply

Render the proposed file changes as a diff, hunk by hunk. Per-hunk approval. Do not write files until the architect approves.

### Phase 6 — Validate syntax

Run `npx likec4 validate`. If validation fails, surface the error to the architect — do not auto-fix.

### Phase 7 — Render guidance

Tell the architect how to view the diagram. Do not start a server uninvited.

```bash
To view: npx likec4 start    # interactive browser at http://localhost:5173
To serve: npx likec4 serve   # static export
```

### Phase 8 — Drift check

Glob ADR directories (`docs/adr/`, `docs/decisions/`, `docs/architecture/decisions/`, `**/adr/*.md`; also check legacy `architecture/decisions/`). For each ADR, compare component names mentioned in the text against names in the LikeC4 model. Report name mismatches as `drift` candidates — let the architect choose which side is canonical. Do not auto-rename either side.

## DSL notes

For complex DSL questions (scoped views, `extend`, deployment specs), consult `references/likec4-dsl-cheatsheet.md`. For features that fall outside canonical C4, refer the architect to the upstream LikeC4 documentation rather than implementing them in this skill.

## References

- `references/likec4-dsl-cheatsheet.md` — minimal cheat-sheet of canonical-C4 LikeC4 DSL
- `references/canonical-c4-refusals.md` — verbatim refusal scripts for the disallowed features
- The `adr-discovery` skill — upstream source of confirmed elements and relationships
- The `adr-critique` skill — downstream consumer for drift detection against ADRs
