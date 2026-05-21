# Alternatives catalog — when NOT to write an ADR

When the four-question diagnostic and the ASR check say "not an ADR," route the user to the right home. Each row below maps a common user impulse to its correct documentation form and the reason an ADR would be wrong.

This catalog is the routing reference for `doc-diagnostic`. Load it whenever the user is debating "ADR vs RFC vs design doc vs runbook vs how-to" or asks "where should I document X?"

## The catalog

| User says...                                                | Right home                                                            | Why not an ADR                                              |
|-------------------------------------------------------------|-----------------------------------------------------------------------|-------------------------------------------------------------|
| "Document our coding style."                                | `CONTRIBUTING.md` or a linter config                                  | Coding conventions are enforceable; ADRs are not enforcement |
| "Explain how the auth flow works."                          | **Diátaxis explanation** (`docs/explanation/auth.md`)                 | This is *understanding*, not a decision                     |
| "Show how to deploy to staging."                            | **Diátaxis how-to** (`docs/how-to/deploy-staging.md`)                 | This is a *task*; ADRs don't direct action                  |
| "List all the env vars / API endpoints / config keys."      | **Diátaxis reference**                                                | Reference is descriptive, austere, product-led; an ADR is argumentative |
| "Onboard a new engineer."                                   | **Diátaxis tutorial** (`docs/tutorials/getting-started.md`)           | Tutorials are learning-oriented; ADRs aren't lessons        |
| "We're considering Postgres vs SQLite."                     | **RFC / design doc** while open; ADR *if* accepted                    | An ADR is a decided record; a proposal isn't decided yet    |
| "What do we do when the queue backlog spikes?"              | **Runbook** (`docs/runbooks/queue-backlog.md`)                        | Runbooks are operational; ADRs are architectural rationale  |
| "Why did we pick Tailwind?"                                 | **ADR**                                                               | Architectural / hard to reverse — this IS an ADR            |
| "We're using camelCase for JSON keys."                      | `CONTRIBUTING.md` or a style guide                                    | Convention, not architecturally significant                 |
| "What's the team's branching policy?"                       | `CONTRIBUTING.md` / wiki                                              | Process, not architecture                                   |
| "Open question: should we shard the user table?"            | An **open-questions register** until measured                         | ADRs record made decisions, not pending research            |
| "I changed the button color on the dashboard."              | **PR description** / changelog                                        | Reversible product/UX detail                                |
| "We will not adopt event sourcing — and here's why."        | **ADR** (a "rejected alternative" decision is still a decision)       | Architectural, irreversible-ish, expensive to revisit       |
| "Document this regex so future-me understands it."          | **Code comment**                                                      | Tiny, local, has exactly one reader: whoever touches that line next |
| "We need to write down our deployment pipeline."            | **Diátaxis reference** + a **how-to** for common operations           | Description of the system + tasks, not a decision           |
| "What's our SLA / latency budget for the API?"              | **Diátaxis reference** (a quality attribute spec) — and an **ADR** if the *choice of budget* was a deliberate tradeoff | Numbers belong in reference; the *why we picked them* belongs in an ADR |
| "Capture the meeting notes from architecture review."       | A meeting-notes doc, then *distill* any actual decisions into ADRs    | Meeting notes are not decision records; they're transcripts |

## The Diátaxis four

The most-confused alternatives. Name them precisely:

- **Tutorial** — learning-oriented; a guided lesson; serves a learner. *"Build your first API endpoint."*
- **How-to guide** — task-oriented; sequence of steps; serves a competent user with a goal. *"How to deploy to production."*
- **Reference** — information-oriented; austere, neutral, product-led description. *"Configuration options."*
- **Explanation** — understanding-oriented; discursive, considers alternatives, gives the *why*. *"About the request-routing model."*

ADRs are **not** Diátaxis explanations. An explanation answers "*can you tell me about X?*" and reflects on the bigger picture. An ADR answers "*what did we decide, and why this rather than the alternatives, and what does that commit us to?*" An explanation may *link* to ADRs to surface the rationale; it should not duplicate them.

## How to use this catalog

1. Run the four-question diagnostic in `SKILL.md` first.
2. If the request fails the diagnostic, find the closest row above by matching the user's words.
3. Name the alternative explicitly, give the path, then re-run the four-question check on the alternative.
4. If no row fits, fall back to the Diátaxis four: ask whether the user needs *learning*, *task completion*, *reference lookup*, or *understanding*.
