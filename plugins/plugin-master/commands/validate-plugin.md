---
description: Validate plugin structure, manifests, and configuration against 2025 standards
argument-hint: "[plugin-path]"
---

# Validate Plugin

Systematically validate plugin files against Claude Code requirements and best practices.

## Process

### Step 1: Locate Plugin

Use current directory or specified path:

```bash
PLUGIN_PATH="${1:-.}"
```

### Step 2: Validate plugin.json

**Check location:**
- Must be at `.claude-plugin/plugin.json`

**Check required fields:**
- `name` - Present and kebab-case

**Check field formats:**
- `author` - Must be object `{ "name": "..." }`, NOT string
- `version` - Must be string `"1.0.0"`, NOT number
- `keywords` - Must be array `["word1"]`, NOT string

**Check for deprecated fields:**
- `agents`, `skills`, `slashCommands` should NOT be in plugin.json

### Step 3: Check Directory Structure

```
plugin-name/
├── .claude-plugin/
│   └── plugin.json          # Required
├── commands/                 # Optional, auto-discovered
├── agents/                   # Optional, auto-discovered
├── skills/                   # Optional, auto-discovered
│   └── skill-name/
│       └── SKILL.md
└── hooks/
    └── hooks.json           # Optional
```

### Step 4: Validate Components

**For each command in commands/:**
- Check frontmatter exists (starts with `---`)
- Check `description` field present

**For each agent in agents/:**
- Check frontmatter exists
- Check required fields: `name`, `description`, `model`, `color`
- Check `<example>` blocks in description

**For each skill in skills/*/:**
- Check SKILL.md exists
- Check frontmatter exists
- Check `description` field present

**For hooks/hooks.json:**
- Check valid JSON syntax
- Check event names are valid

### Step 5: Check marketplace.json (if present)

If `.claude-plugin/marketplace.json` exists at repo root:
- Check plugin is registered
- Check source path is correct
- Check descriptions match

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

Warnings:
- Consider adding keywords for discovery

Errors:
(none)

================================
PASSED
================================
```

## Severity Levels

**Critical (Must Fix):**
- plugin.json missing or invalid
- Missing required fields
- Wrong field types (author as string, etc.)

**Warnings (Should Fix):**
- Missing recommended fields
- Inconsistent naming
- Missing frontmatter

**Suggestions (Nice to Have):**
- Add more keywords
- Add examples
- Improve documentation

## Usage

```bash
# Validate current directory
/validate-plugin

# Validate specific path
/validate-plugin plugins/my-plugin

# Validate before publishing
/validate-plugin . && echo "Ready to publish!"
```

## Quick Validation Script

Run validation script directly:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/validate-plugin.sh [path]
```

## Checklist

Before publishing:

- [ ] plugin.json has valid syntax
- [ ] `name` is kebab-case
- [ ] `author` is an object
- [ ] `version` is a string
- [ ] `keywords` is an array
- [ ] No `agents`/`skills`/`slashCommands` fields
- [ ] All components have frontmatter
- [ ] Agent has `<example>` blocks
- [ ] Registered in marketplace.json (if applicable)
