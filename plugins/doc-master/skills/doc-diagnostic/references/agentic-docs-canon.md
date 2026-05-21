# AGENTS.md canon — AI-agent context file

The canonical reference for `AGENTS.md`. Load this when the user asks "where do I tell our AI agents about this repo?", "should I write an ADR for 'we use Claude Code'?", "we have CLAUDE.md and .cursorrules — what should we use instead?", or "what's the convention for agent instructions?"

`AGENTS.md` is a **vendor-neutral, agent-readable file** that describes a codebase to AI coding assistants: conventions, build commands, test commands, code style, deployment notes — anything an agent needs to operate effectively in the repo. It is the converged community answer to the proliferation of vendor-specific files (`CLAUDE.md`, `.cursorrules`, `.github/copilot-instructions.md`, `.continuerc`, and the rest).

Upstream: [agents.md](https://agents.md/). The convention is now stewarded by the **Agentic AI Foundation** as a vendor-neutral spec.

## The closest-AGENTS.md-wins rule

For monorepos and nested projects:

- The agent reads the **nearest** `AGENTS.md` walking upward from the working directory.
- Sub-project `AGENTS.md` files **override** parent files for their own scope, on a per-section basis where the agent supports it.
- Repo root `AGENTS.md` provides the defaults; subdirectory files refine them for their specific package / service / language.

This means a monorepo with `packages/frontend/AGENTS.md` and `packages/backend/AGENTS.md` can give the agent fundamentally different instructions per package (npm vs gradle, prettier vs spotless, etc.) without conflict.

## Migration from vendor-specific files

If the repo currently has vendor-specific agent-context files, migrate them:

| Old file                                  | Vendor              | Migration                                                     |
|-------------------------------------------|---------------------|---------------------------------------------------------------|
| `CLAUDE.md` / `.claude/CLAUDE.md`         | Claude Code         | Move content into `AGENTS.md`; symlink `CLAUDE.md` → `AGENTS.md`. |
| `.cursorrules` / `.cursor/rules`          | Cursor              | Move content into `AGENTS.md`; symlink old path → `AGENTS.md`.|
| `.github/copilot-instructions.md`         | GitHub Copilot      | Move content into `AGENTS.md`; symlink the old path.          |
| `.continuerc` / `.continue/`              | Continue            | Move applicable instructions into `AGENTS.md`.                |
| `.aiderrc` / `.aider/`                    | Aider               | Same pattern.                                                  |

**Symlinks during migration** are the safe path. They preserve compatibility with tools that look for the vendor-specific name while making `AGENTS.md` authoritative. On Windows, where symlinks need elevated permissions or developer mode, the alternative is a tiny pointer file (e.g., a `CLAUDE.md` containing only "See `AGENTS.md`.") with the same effect.

## What goes in AGENTS.md

A typical `AGENTS.md` covers:

- **Build, test, and lint commands** — the exact commands the agent should run, with no guessing.
- **Code style** — language version, linter / formatter config, naming conventions that the linter does not cover.
- **Repository layout** — where source, tests, docs, configs live.
- **Dependency rules** — what is allowed, what requires an ADR, vendor-pinning policy.
- **Branching / PR conventions** — branch naming, commit message style (Conventional Commits etc.), required reviewers.
- **Forbidden actions** — what the agent must not do (force-push, edit specific protected files, commit secrets, bypass CI).
- **Pointers to other docs** — ADR directory, runbook directory, security policy, contribution guide.

It does **not** typically duplicate ADRs, runbooks, or the README — it points to them.

## "Should I write an ADR for 'we use Claude Code'?" — no

Picking an AI coding assistant is **not** an architectural decision in the ASR sense:

- It is reversible — switch to a different agent tomorrow.
- It has no measurable effect on system architecture or quality.
- It does not constrain future architectural choices.

The choice of agent is a **tooling preference**, like the choice of editor or terminal. It belongs in `AGENTS.md` (the configuration / instruction file the agent reads) or in `CONTRIBUTING.md` (if there are project-wide expectations about how agents are used). It does not belong in the decision log.

What **may** be an ADR-worthy decision in the same neighborhood:

- "All AI-generated code requires human-named reviewer sign-off before merge" — governance, often architecturally significant.
- "We forbid AI agents from modifying files under `/security/`" — constraint with measurable effect on review surface and compliance.
- "We license-screen all AI-suggested dependencies through workflow X" — a process commitment with measurable impact.

These produce an ADR because the **policy** has architectural and compliance implications. The choice of *which agent* is configuration.

## Common failure modes

| Failure                                                  | Symptom                                                                                | Remedy                                                                                  |
|----------------------------------------------------------|----------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------|
| Three competing agent-config files                       | `CLAUDE.md` + `.cursorrules` + `AGENTS.md` with overlapping, drifting content.         | One source of truth (`AGENTS.md`); symlink the rest. Audit drift quarterly.             |
| `AGENTS.md` duplicates the README                        | Both files re-state the same build commands; they drift.                               | `AGENTS.md` links to the README for what the README covers; only adds agent-only notes.|
| ADR for "we use agent X"                                 | The decision log carries a tool-choice entry that has no architectural force.          | Move the content to `AGENTS.md`. Mark the ADR Rejected with a note.                     |
| Secrets in `AGENTS.md`                                   | API keys, internal URLs, credentials embedded as "examples."                           | Never. Reference the secret-management approach; never the secret.                      |
| `AGENTS.md` as a manifesto                               | Pages of philosophy about AI; no actionable instructions.                              | Strip to imperatives. The agent reads this file to operate, not to read essays.         |

## Routing — when this is not the answer

- A decision about **how the team uses agents** with architectural / compliance impact → **ADR**.
- A decision about **which agent to use** → `AGENTS.md` (tooling preference, not a decision).
- A general "what conventions does this repo follow" doc for humans → `CONTRIBUTING.md`. `AGENTS.md` may link to it.
- Per-language style → linter / formatter config. `AGENTS.md` points at the config; it does not restate it.
- Forbidden-actions policy with legal / security weight → may be both an `AGENTS.md` entry **and** a `SECURITY.md` section, depending on audience.
