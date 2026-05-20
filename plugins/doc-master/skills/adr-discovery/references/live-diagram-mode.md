# Live-diagram mode (opt-in, during discovery)

A workflow for architects who think visually. The discovery skill can render a LikeC4 diagram **incrementally** as facts are confirmed, so the architect sees the system shape emerging. This is opt-in — never start it without asking.

## Pre-flight checks

Before offering, verify:

1. **LikeC4 CLI installed** — `npx likec4 --version` returns a version (any v1.47+).
2. **Port 5173 free** — `likec4 start` defaults to this port; offer an alternative if busy.
3. **No existing `likec4/` directory at the repo root** — if there is one, ask whether to extend it or scaffold a fresh `likec4-discovery/` sandbox so discovery doesn't pollute the canonical model.

## Scaffold

Create three files under `likec4-discovery/` (or the chosen path):

- `model.c4` — the spec block + an empty model
- `views.c4` — one `context` view and one `container` view of the system in focus
- `likec4.config.js` — minimal config pointing at the two `.c4` files

Use the canonical-C4 specification block from the `c4-model` skill. Do **not** invent custom element kinds or styles during discovery.

## Incremental write

As each component, relationship, or actor is confirmed in discovery:

1. Append a line to `model.c4`.
2. Save.
3. The LikeC4 server hot-reloads; the architect sees the diagram update.

## Open-question tagging

When a confirmed-but-incomplete element appears (e.g., "this component exists, but the architect hasn't named its tech yet"):

- Tag the element `#open-question`
- Prefix its description with `OPEN Q<N>:` matching the entry number in `open-questions.md`
- The canonical style renders `#open-question` as red + dashed, so unknowns are visually obvious

## What live mode does NOT do during discovery

- Does not run `likec4 validate` — that belongs in the `c4-model` skill.
- Does not add scoped views, styled views, deployment views, or component views.
- Does not apply custom styling.
- Does not commit to a final model — the architect copies confirmed elements into the canonical `likec4/` directory only after discovery completes, via `c4-model`.

The diagram during discovery is a **thinking aid**, not a deliverable.

## Tearing down

When discovery completes:

- Offer to delete `likec4-discovery/` (the sandbox)
- Offer to graduate the confirmed elements into `likec4/` via `c4-model`
- Stop the `likec4 start` server gracefully

Never auto-promote the sandbox model to the canonical one — let `c4-model` do that with its own lint pass.
