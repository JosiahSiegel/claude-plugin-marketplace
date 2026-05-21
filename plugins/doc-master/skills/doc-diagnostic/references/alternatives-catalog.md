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
| "What do we do when the queue backlog spikes?"              | **Runbook** (`docs/runbooks/queue-backlog.md`) — see `runbook-canon.md`. A runbook is for a paged on-call engineer; it is **not** the same as a Diátaxis how-to (planned work, healthy system). | Runbooks are operational; ADRs are architectural rationale  |
| "Why did we pick Tailwind?"                                 | **ADR**                                                               | Architectural / hard to reverse — this IS an ADR            |
| "We're using camelCase for JSON keys."                      | `CONTRIBUTING.md` or a style guide                                    | Convention, not architecturally significant                 |
| "What's the team's branching policy?"                       | `CONTRIBUTING.md` / wiki                                              | Process, not architecture                                   |
| "Open question: should we shard the user table?"            | An **open-questions register** until measured — see `open-questions-canon.md` (the standalone form) | ADRs record made decisions, not pending research            |
| "I changed the button color on the dashboard."              | **PR description** / changelog — see `changelog-canon.md` (Keep a Changelog 1.1 + SemVer 2.0) | Reversible product/UX detail                                |
| "We will not adopt event sourcing — and here's why."        | **ADR** (a "rejected alternative" decision is still a decision)       | Architectural, irreversible-ish, expensive to revisit       |
| "Document this regex so future-me understands it."          | **Code comment**                                                      | Tiny, local, has exactly one reader: whoever touches that line next |
| "We need to write down our deployment pipeline."            | **Diátaxis reference** + a **how-to** for common operations           | Description of the system + tasks, not a decision           |
| "What's our SLA / latency budget for the API?"              | **Diátaxis reference** (a quality attribute spec) — and an **ADR** if the *choice of budget* was a deliberate tradeoff | Numbers belong in reference; the *why we picked them* belongs in an ADR |
| "Capture the meeting notes from architecture review."       | A meeting-notes doc, then *distill* any actual decisions into ADRs    | Meeting notes are not decision records; they're transcripts |
| "Write up the outage we just had."                          | **Postmortem** — see `postmortem-canon.md` (PagerDuty template, Google SRE cultural framing) | Postmortems record what happened; ADRs record what was decided. A postmortem may *produce* an ADR. |
| "Document AI / agent context for this repo."                | **`AGENTS.md`** at repo root — see `agentic-docs-canon.md`. Replaces vendor-specific files (`CLAUDE.md`, `.cursorrules`, `.github/copilot-instructions.md`). | Tool configuration, not an architectural decision. The choice of *which* agent is not ASR-significant. |
| "Track copyright / per-file licensing metadata."            | **REUSE 3.3 / SPDX** headers + `LICENSES/` directory + optional `REUSE.toml`. Specs: [reuse.software/spec-3.3/](https://reuse.software/spec-3.3/) and [spdx.org/licenses/](https://spdx.org/licenses/). | Metadata convention, not a decision. The *choice* to adopt REUSE can be an ADR; the per-file headers are not. |
| "Standardize our commit-message format."                    | **Conventional Commits 1.0** ([conventionalcommits.org](https://www.conventionalcommits.org/en/v1.0.0/)) referenced from `CONTRIBUTING.md` and enforced via commit-lint. | Convention enforcement, not architecture. The *adoption* may be an ADR if it gates release tooling.|
| "How do users report a security vulnerability?"             | **`SECURITY.md`** at repo root (private disclosure channel, scope, response SLA) — see `../../repo-health/references/security-canon.md`. Refuses single-maintainer contact lines. | Disclosure-channel policy is community-health bootstrap, not an architectural decision. The *choice* to add a coordinated-disclosure program may be an ADR. |
| "Where do users go for help?"                               | **`SUPPORT.md`** at repo root (issue tracker scope, discussion forum, paid support, response expectations) — see `../../repo-health/references/support-canon.md`. | Support routing is community-health, not architecture. Apply the four-question check before creating it (new projects often shouldn't have one yet). |
| "How do I cite this software?"                              | **`CITATION.cff`** at repo root (Citation File Format 1.2.0; GitHub renders "Cite this repository") — see `../../repo-health/references/templates-canon.md`. | Citation metadata is descriptive, not a decision. Adopting CFF as the project's citation channel may be an ADR if downstream tooling depends on it. |
| "Who owns this code?"                                       | **`CODEOWNERS`** in `.github/`, `docs/`, or repo root (GitHub auto-assigns PR reviewers from path globs) — see `../../repo-health/references/templates-canon.md`. | Reviewer routing is process configuration, not architecture. The *policy* requiring two CODEOWNERS for `/security/` may be an ADR. |
| "Issue / PR templates."                                     | **`.github/ISSUE_TEMPLATE/*.yml`** (GitHub Forms) and **`.github/PULL_REQUEST_TEMPLATE.md`** — see `../../repo-health/references/templates-canon.md`. | Form configuration, not a decision. The *requirement* that every PR include a changelog entry may be an ADR (or simpler: encoded in the template itself plus CI). |
| "What should our README contain?"                           | **`README.md`** at repo root following the Standard Readme structure (title → badges → short description → install → usage → API → contributing → license) — see `../../repo-health/references/readme-canon.md`. | README structure is convention, not architecture. The decision to adopt Standard Readme can be implicit (just follow it) or, if the team needs accountability, recorded as an ADR. |

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
