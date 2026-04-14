---
description: Validate plugin structure, manifests, and configuration against 2025-2026 standards (catches the triggering bugs from the triggering-reliability skill)
argument-hint: "[plugin-path]"
---

# Validate Plugin

Systematically validate plugin files against Claude Code requirements and the triggering-reliability anti-pattern catalog.

## Process

### Step 1: Locate Plugin

Use current directory or specified path:

```
PLUGIN_PATH="${1:-.}"
```

### Step 2: Validate plugin.json

**Check location:**
- Must be at `.claude-plugin/plugin.json`

**Check required fields:**
- `name` - present and kebab-case

**Check field formats:**
- `author` - must be object `{ "name": "..." }`, NOT string
- `version` - must be string `"1.0.0"`, NOT number
- `keywords` - must be array `["word1"]`, NOT string

**Check for deprecated fields:**
- `agents`, `skills`, `slashCommands` should NOT be in plugin.json

### Step 3: Check directory structure

```
plugin-name/
├── .claude-plugin/
│   └── plugin.json
├── commands/
├── agents/
├── skills/
│   └── skill-name/
│       └── SKILL.md
└── hooks/
    └── hooks.json
```

### Step 4: Validate every agent (anti-pattern checks)

For every `agents/*.md`:

1. **Has YAML frontmatter** (file starts with `---`).
2. **Has `name:` field** (NOT `agent: true` - that pattern is deprecated/broken).
3. **Has `model: inherit`** (not missing, not hard-coded `sonnet`/`opus`/`haiku` without justification).
4. **Has `color:` field** (one of blue/cyan/green/yellow/magenta/red).
5. **Has `description:` field with at least one `<example>` block** - ideally 4-6.
6. **Description contains the `PROACTIVELY activate for: (1)... (N)...` enumeration** AND a `Provides: ...` capability list.
7. **No Windows/docs boilerplate inside YAML `description:`** - search for "MANDATORY: Always Use Backslashes", "NEVER create new documentation files", or similar cross-cutting boilerplate. Move to body if found.
8. **Description uses `description: |` (block scalar) when multi-line.**

### Step 5: Validate every skill (anti-pattern checks)

For every `skills/*/SKILL.md`:

1. **Has YAML frontmatter** (file starts with `---` - NOT `# Skill Title`). A SKILL.md without frontmatter is a P0 bug - it will never appear in skill discovery.
2. **Has `name:` field matching the directory name.**
3. **Has `description:` field** containing BOTH `PROACTIVELY activate for:` AND `Provides:`.
4. **Description enumerates concrete named triggers** as `(1) trigger, (2) trigger, ..., (N) trigger`, not abstract capability statements.
5. **Description is under ~800 characters** (longer dilutes matching).
6. **No Windows/docs boilerplate inside YAML `description:`** - same check as agents.
7. **No trigger-phrase overlap with sibling skills** in the same plugin.

### Step 6: Validate hooks/hooks.json (if present)

- Valid JSON syntax
- Valid event names (PreToolUse, PostToolUse, Stop, etc.)
- Each hook has `matcher` and `hooks` array
- Hook commands reference existing scripts

### Step 7: Cross-cutting greps (the triggering-reliability audit)

Run these from the repo root or plugin root:

```
# 1. Skills with no frontmatter (BROKEN - P0)
for f in skills/*/SKILL.md; do
  head -1 "$f" | grep -q "^---" || echo "NO FRONTMATTER: $f"
done

# 2. Agents still using deprecated agent: true (BROKEN - P0)
grep -rn "^agent: true" agents/*.md

# 3. Agents missing example blocks
for f in agents/*.md; do
  grep -q "<example>" "$f" || echo "NO EXAMPLES: $f"
done

# 4. Skills missing PROACTIVELY activate for: enumeration
for f in skills/*/SKILL.md; do
  head -20 "$f" | grep -q "PROACTIVELY activate for:" || echo "NO ENUMERATION: $f"
done

# 5. Skills missing Provides: capability list
for f in skills/*/SKILL.md; do
  head -20 "$f" | grep -q "Provides:" || echo "NO PROVIDES: $f"
done

# 6. Agents missing model: inherit
for f in agents/*.md; do
  head -20 "$f" | grep -q "^model: inherit" || echo "NO MODEL INHERIT: $f"
done

# 7. Windows/docs boilerplate inside YAML descriptions (poisons routing)
# Note: only flag if the boilerplate appears BEFORE the closing --- of the frontmatter
grep -rn "MANDATORY: Always Use Backslashes" agents/*.md skills/*/SKILL.md
grep -rn "NEVER create new documentation files" agents/*.md skills/*/SKILL.md
```

Each row of output is a triggering bug. Fix in priority order.

### Step 8: Check marketplace.json (if present)

If `.claude-plugin/marketplace.json` exists at repo root:
- Plugin is registered
- Source path is correct
- Description and keywords match between marketplace.json and plugin.json

## Validation Report

Generate report with:

```
================================
Plugin Validation Report
================================

Plugin: plugin-name
Path: /path/to/plugin

✓ plugin.json found
✓ Valid JSON syntax
✓ Name: plugin-name
✓ Author is object format
✓ Version: 1.0.0

Components:
✓ 1 agent(s) found
✓ 2 skill(s) found
✓ 1 command(s) found

Triggering reliability:
✓ All agents have name: (no agent: true legacy)
✓ All agents have model: inherit
✓ All agents have at least one <example>
✓ All skills have YAML frontmatter
✓ All skills have PROACTIVELY activate for: enumeration
✓ All skills have Provides: capability list
✓ No Windows boilerplate inside YAML descriptions

Errors:
(none)

================================
PASSED
================================
```

## Severity Levels

**Critical (P0 - must fix before ship):**
- plugin.json missing or invalid
- Missing required fields
- Wrong field types
- Skill with no YAML frontmatter
- Agent using deprecated `agent: true`
- Windows/docs boilerplate inside YAML description (poisons routing)

**Major (P1 - should fix before ship):**
- Agent missing `<example>` blocks
- Skill description missing `PROACTIVELY activate for:` / `Provides:` enumeration
- Skill description describes WHAT instead of WHEN

**Minor (P2 - polish):**
- Missing `model: inherit`, `color:`, or `tools:` (use defaults)
- Description length over ~800 chars
- Trigger-phrase overlap between sibling skills

## Checklist (canonical)

Before publishing:

- [ ] plugin.json has valid syntax
- [ ] `name` is kebab-case
- [ ] `author` is an object
- [ ] `version` is a string
- [ ] `keywords` is an array
- [ ] No `agents`/`skills`/`slashCommands` fields in plugin.json
- [ ] Every agent has YAML frontmatter (`---` first line)
- [ ] Every agent has `name:` (not `agent: true`)
- [ ] Every agent has `model: inherit`
- [ ] Every agent has at least one `<example>` block (4-6 preferred)
- [ ] Every agent has `color:`
- [ ] Every agent has `tools:` (minimal set) or omits for full access
- [ ] Every skill has YAML frontmatter (`---` first line, NOT `#`)
- [ ] Every skill description contains `PROACTIVELY activate for:` enumeration
- [ ] Every skill description contains `Provides:` capability list
- [ ] No Windows/docs boilerplate inside YAML descriptions
- [ ] Registered in marketplace.json (if applicable)
- [ ] Plugin version matches between marketplace.json and plugin.json

## Quick validation greps

Run from a plugin directory:

```
grep -L "^---" skills/*/SKILL.md          # any output = zero-frontmatter skills
grep -l "^agent: true" agents/*.md         # any output = deprecated agents
grep -L "<example>" agents/*.md            # any output = missing examples
grep -L "PROACTIVELY activate for:" skills/*/SKILL.md   # any output = missing enumeration
grep -l "MANDATORY: Always Use Backslashes" agents/*.md skills/*/SKILL.md   # any output = boilerplate to move
```
