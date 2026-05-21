# LikeC4 DSL cheat-sheet (canonical-C4 subset)

A minimal cheat-sheet of the LikeC4 DSL constructs `c4-model` uses. Anything not listed here is either disallowed (see `canonical-c4-refusals.md`) or out of scope for this skill — consult upstream LikeC4 documentation for those features.

Targets LikeC4 v1.47+.

## File layout

```text
likec4/
  model.c4         # specification + model
  <system>.c4      # system-scoped extension (optional split)
  views.c4         # context + container views
  likec4.config.js # minimal config
```

A single-file model is also valid; put everything in `model.c4`.

## Specification (the locked block)

The specification is fixed by `c4-model`. See the locked block in `SKILL.md`. Do not add element kinds, relationship kinds, or styles beyond what is in that block.

## Model — actors and external systems

```c4
model {
  customer = actor "Customer" "End user placing orders"

  payment-gateway = externalSystem "Payment Gateway" "Third-party charge processor"
}
```

- Identifier (`customer`) is lowercase, hyphenated.
- Display name is title-cased in quotes.
- The third quoted string is the one-line description (required).

## Model — the system and its containers

Exactly one system block per file:

```c4
model {
  customer = actor "Customer" "End user placing orders"

  shop = system "Shop" {
    web = container "Web App" "User-facing frontend" {
      technology "Next.js"
    }
    api = container "API" "Backend HTTP API" {
      technology "Node.js / Fastify"
    }
    db = container "Primary Store" "Order and user data" {
      technology "Postgres"
    }
  }
}
```

- `technology` attribute holds the tech stack — do not invent a new element kind for it.
- Containers are nested **inside** the system block.

## Relationships — five kinds only

```c4
customer -> shop.web "Browses catalog and places orders"

shop.web -> shop.api "Calls REST endpoints"
shop.api reads shop.db "Reads order and user data"
shop.api writes shop.db "Writes new orders"

shop.api publishes events "Emits OrderPlaced events"
analytics consumes events "Consumes OrderPlaced for reporting"
```

Allowed verbs in the canonical subset:

| Verb | Use for |
|---|---|
| `->` / `uses` | Generic dependency or call |
| `reads` | Read-only dependency on a data store |
| `writes` | Write dependency on a data store |
| `publishes` | Producer side of a queue/topic |
| `consumes` | Consumer side of a queue/topic |

**Every relationship requires the trailing quoted description.** No description → no edge.

## Tags

```c4
api = container "API" "Backend HTTP API" {
  technology "Node.js / Fastify"
  #open-question
}
```

Only the canonical-C4 tag `open-question` is in scope for this skill. Other tags are out of scope.

## Views

Three view kinds permitted by this skill:

```c4
views {
  view context-of-shop of shop {
    include shop, customer, payment-gateway
    title "Context -- Shop"
  }

  view containers-of-shop of shop {
    include shop, shop.*
    title "Containers -- Shop"
  }

  // Optional, only on architect request:
  view deployment-of-shop of shop {
    include shop, shop.*
    title "Deployment -- Shop"
  }
}
```

- View identifiers follow the same lowercase-hyphenated convention.
- `include` lists exactly the elements the view should render.
- No `style` blocks inside the view — canonical styling only.

## Config

`likec4.config.js`:

```js
export default {
  name: "shop-architecture",
  sources: ["model.c4", "views.c4"],
};
```

Keep it minimal. Adding plugin configuration, custom themes, or output transforms is out of scope.

## CLI commands the skill uses

| Command | Purpose |
|---|---|
| `npx likec4 validate` | Phase 6 syntax check. |
| `npx likec4 start` | Phase 7 — interactive browser viewer (architect-initiated). |
| `npx likec4 serve` | Phase 7 — static export (architect-initiated). |

Never run `start` or `serve` without architect consent; they bind a port.
