---
description: Validate a plugin's structure, manifest, frontmatter, and triggering reliability against the current Claude Code conventions. Produces a P0/P1/P2 finding list — does not modify files.
argument-hint: "[plugin-path]"
---

# /validate-plugin

Use this command to audit a plugin (or the current directory) before publishing — catches the structural and triggering-reliability bugs that make plugins install fine but never actually fire.

## What this command does

Hands the audit to the `plugin-expert` agent, which activates the `triggering-reliability` and `plugin-master` skills. The agent will:

1. **Locate the plugin** — uses the path argument, or the current directory if none is given.
2. **Validate `plugin.json`** — file present at `.claude-plugin/plugin.json`, valid JSON, required `name` field, correct field types (`author` object, `version` string, `keywords` array), no deprecated `agents`/`skills`/`slashCommands` fields.
3. **Validate every agent** — YAML frontmatter present, `name:` field set (not legacy `agent: true`), `model: inherit`, `color:`, at least one `<example>` block (4-6 preferred), description contains `PROACTIVELY activate for:` and `Provides:` enumeration, no Windows / docs / cross-cutting boilerplate inside the YAML `description`.
4. **Validate every skill** — `SKILL.md` starts with `---` (zero-frontmatter is a P0 bug, the skill never appears in discovery), `name:` matches the directory, `description:` includes the `PROACTIVELY` + `Provides` enumeration, description under the 1024 hard ceiling, no boilerplate in YAML, no trigger-phrase overlap with sibling skills.
5. **Validate `hooks/hooks.json`** if present — valid JSON, valid event names (PreToolUse, PostToolUse, etc.), each hook has `matcher` and `hooks` array, commands point at existing scripts.
6. **Cross-check `marketplace.json`** when applicable — plugin registered, source path correct, description and keywords match between marketplace.json and plugin.json.
7. **Produce a severity-tiered finding list** — P0 (must fix before ship — invalid manifest, missing required fields, zero-frontmatter skills, deprecated `agent: true`, YAML boilerplate), P1 (should fix — missing examples, missing enumeration, description over 1024), P2 (polish — missing `model: inherit`, description over the 400-1000 target, sibling trigger overlap).

## Your input

Optional. Defaults to the current directory. Pass a path to audit a specific plugin (e.g., `/validate-plugin plugins/my-plugin`).

## What this command will NOT do

- Modify any file. This is read-only — it produces findings; you decide what to fix.
- Bump versions. After fixing findings, use `python scripts/version_ops.py -b patch -p <plugin>` (see repo root `CLAUDE.md`).
- Run the official `claude plugin validate` CLI — that is a separate tool. This command focuses on the conventions and triggering-reliability rules that the CLI validator does not enforce.

The full anti-pattern catalog, severity table, canonical checklist, and the one-line greps that back each check live in the `triggering-reliability` skill — the agent will load it on demand. The agent will also load `plugin-master` for manifest/structure rules and `skill-development` / `agent-development` for the component-specific frontmatter rules.
