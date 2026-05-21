---
description: Scaffold a new Claude Code plugin with the canonical structure (plugin.json, agent, skills, optional commands/hooks/MCP) and register it in marketplace.json when applicable.
argument-hint: "[plugin-name or description]"
---

# /create-plugin

Use this command when you want to create a new Claude Code plugin from scratch, scaffold one from a short description, or add the canonical structure to an existing folder.

## What this command does

Hands the request to the `plugin-expert` agent, which activates the `plugin-master`, `agent-development`, and `skill-development` skills. The agent will:

1. **Detect the repository context** — if `.claude-plugin/marketplace.json` exists at the repo root, scaffold under `plugins/<name>/`; otherwise scaffold in the current directory. Author name and email come from `git config`.
2. **Create the canonical directory layout** — `.claude-plugin/plugin.json`, one agent (`agents/<domain>-expert.md`), and one or more skills (`skills/<skill-name>/SKILL.md`) with progressive disclosure scaffolding (`references/`, `examples/` only if needed).
3. **Author production-quality frontmatter** — agent description with 4-6 `<example>` blocks; skill descriptions with `PROACTIVELY activate for: (1)... (N)... Provides: ...` enumeration. All descriptions sit in the 400-1000 char target with a 1024 hard ceiling (Claude Code API spec).
4. **Register in `marketplace.json` when applicable** — with matching name, description, version, author, and keywords. A plugin is not complete until registered.
5. **Run a post-creation quality audit** — trigger-phrase completeness, SKILL.md word counts, agent example coverage, no trigger overlap, no Windows / docs boilerplate inside YAML descriptions.

## Your input

Tell the agent:

- **What the plugin does** (one sentence is enough — "Docker workflow automation", "API testing helper", etc.).
- **Whether it lives in a marketplace repo** (the agent will detect this if you do not say).
- **Optional**: any specific skills, commands, or hooks you already know you want.

The agent will ask follow-ups only if the domain is ambiguous or if you ask for components the canonical agent-first layout discourages (e.g., five slash commands instead of one expert agent).

## What this command will NOT do

- Invent author identity. Author name and email come from `git config`; if those are unset the agent will ask.
- Overwrite an existing plugin. If a folder of the same name exists, the agent inspects it and proposes additive changes rather than clobbering.
- Skip marketplace registration when in a marketplace repo. That step is mandatory.
- Bump versions. New plugins start at `1.0.0`; existing-plugin edits go through `scripts/version_ops.py` (see repo root `CLAUDE.md`).

Use `/validate-plugin` after creation to confirm the scaffolded plugin passes all triggering-reliability checks before publishing.
