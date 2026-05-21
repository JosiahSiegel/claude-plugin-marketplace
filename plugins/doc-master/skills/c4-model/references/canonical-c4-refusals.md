# Canonical-C4 refusal scripts

When an architect asks for a LikeC4 feature outside the canonical-C4 subset, the skill refuses with one of these scripts. Use them verbatim — vague refusals leak into the model.

## Component view

**Architect says:** "Add a component view inside the API container."

**Refuse with:**

> Component views belong at a deeper level than ADRs work at. The C4 Component level is for inside-the-codebase structure — classes, modules, packages. ADRs record *which containers exist and why*, not their internal shape. If you need a class/module diagram, use a code-level tool (Mermaid in source, structurizr, or a code-graph generator) outside this skill.

## Dynamic / sequence view

**Architect says:** "Show me the runtime sequence for placing an order."

**Refuse with:**

> Dynamic views are not part of the canonical-C4 subset this skill produces. Sequence and runtime flows belong in a sequence diagram (PlantUML, Mermaid sequence) alongside the relevant ADR — not in the C4 model. The C4 model captures structure; sequences capture behavior. Keeping them in separate artifacts keeps both readable.

## Custom element kind

**Architect says:** "Add a new element kind for `lambda` (or `queue`, `database-table`, etc.)."

**Refuse with:**

> Canonical C4 has four element kinds: Person, Software System, Container, Component. Adding `<kind>` makes the diagram unrecognizable as C4. Use `container` and put `<kind>` in the `technology` attribute:
>
> ```c4
> orders-queue = container "Orders Queue" "Decouples checkout from fulfillment" {
>   technology "<kind>"
> }
> ```

## Custom relationship kind

**Architect says:** "Add a `mirrors` (or `replicates`, `proxies`, `caches`) relationship kind."

**Refuse with:**

> The canonical relationship vocabulary is small on purpose: `uses`, `reads`, `writes`, `publishes`, `consumes`. Pick the closest canonical kind and put the specifics in the one-line description:
>
> ```c4
> primary -> replica "Mirrors writes asynchronously for read scaling"
> ```
>
> A larger vocabulary makes every diagram a custom DSL that future readers must learn.

## Custom style

**Architect says:** "Make the database containers blue and the queues yellow."

**Refuse with:**

> Custom styling makes the diagram look like a corporate slide instead of a C4 diagram. Canonical C4 relies on shape (Person) and the `externalSystem` color distinction; adding more colors trains readers to look at the styling instead of the structure. If brand-styled diagrams matter more than canonicality, use LikeC4 directly outside this skill.

## Nested systems

**Architect says:** "Put system B inside system A."

**Refuse with:**

> C4 has Context (systems + actors) and Container (one system's internals). Nesting systems-in-systems collapses the levels and makes the diagram impossible to read at a glance. If A and B genuinely share scope, model them as one system with multiple containers. If they're independent, model them as two separate `.c4` files and link via `externalSystem` references.

## Multiple systems in focus

**Architect says:** "Put both the shop system and the analytics system in this one model."

**Refuse with:**

> One system in focus per `.c4` file is the canonical-C4 rule. The shop's containers and the analytics platform's containers are different "Container views" — two diagrams, not one. The connection between them is captured by an `externalSystem` reference in each file.

## Standalone container or actor outside any system

**Architect says:** "Add a container at the top level, not inside a system."

**Refuse with:**

> Containers are *inside* a system by definition. A free-floating container has no boundary — it's not a C4 element. If it's a third-party service, model it as `externalSystem` at the top level. If it's owned by the team, it belongs inside the system in focus.

## Inline style on a single element

**Architect says:** "Just make this one container red."

**Refuse with:**

> Per-element styling is the gateway to custom-styling everything. The only sanctioned per-element style is the `#open-question` tag for unresolved elements — that's enough signal. If the element needs more emphasis, the description should carry the message; styling is a decoration, not a decision.

## How to deliver a refusal

- Open with the refusal — do not pad with "I understand," "great idea," or "good thinking."
- Cite the rule briefly.
- Offer the canonical alternative concretely (with a DSL snippet when possible).
- Do not negotiate the rule. Negotiation here is how the diagram becomes non-canonical over weeks.

If the architect insists on a refused feature after the alternative is offered, the appropriate response is: "That's outside this skill's scope. Use LikeC4 directly for that."
