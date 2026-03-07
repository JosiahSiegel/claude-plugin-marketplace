---
description: Improve an existing plugin with requested changes. Usage - /improve <plugin-name> <description of improvements>
---

## Requirements
$ARGUMENTS

## Process

1. **Read first** — Read the target plugin's existing agents, skills, commands, and hooks before making any changes. Understand the current structure, patterns, and conventions.
2. **Research** — Use web search and context7 to gather up-to-date information relevant to the requested improvements.
3. **Make focused changes** — Implement only what was requested. Avoid unrelated refactoring, unnecessary abstractions, or cosmetic changes that don't add value. Every change should have a clear purpose.
4. **Validate** — Review the changes for consistency with the plugin's existing style and structure.
5. **Version bump** — Run `python3 scripts/version_ops.py -b <patch|minor|major> -p <plugin-name>` to bump the version. Use `patch` for fixes/tweaks, `minor` for new features, `major` for breaking changes.

## Guidance

- Use the `plugin-master:plugin-expert` agent for architectural questions or plugin structure concerns.
- Load relevant plugin skills (e.g., `plugin-master:plugin-master`, `plugin-master:validate-plugin`) when needed.
- Prioritize meaningful improvements over quantity of changes.