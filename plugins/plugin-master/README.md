# Plugin Master

Complete Claude Code plugin development system with 2025 best practices.

## Features

- **Agent-first design** - Single expert agent pattern for domain expertise
- **Progressive disclosure** - Skills with three-tier loading for unbounded capacity
- **Validation utilities** - Scripts to validate plugins, agents, and skills
- **Best practices** - Up-to-date 2025 patterns and conventions
- **Marketplace publishing** - Complete workflow for distribution

## Installation

### From Marketplace (Recommended)

```bash
/plugin marketplace add JosiahSiegel/claude-plugin-marketplace
/plugin install plugin-master@JosiahSiegel
```

### Local Installation

```bash
git clone https://github.com/JosiahSiegel/claude-plugin-marketplace.git
cp -r claude-plugin-marketplace/plugins/plugin-master ~/.claude/plugins/local/
```

## Usage

Just ask about plugin development:

- "Create a plugin for Docker automation"
- "Help me add an agent to my plugin"
- "Validate my plugin structure"
- "How do I publish to a marketplace?"

## Components

### Agent

| Name | Purpose |
|------|---------|
| `plugin-expert` | Primary expert for all plugin development questions |

### Skills

| Skill | Purpose |
|-------|---------|
| `plugin-master` | Core plugin development guide |
| `advanced-features-2025` | Hooks, MCP, progressive disclosure |

### Commands

| Command | Purpose |
|---------|---------|
| `/create-plugin` | Create a new plugin |
| `/validate-plugin` | Validate plugin structure |

### Scripts

| Script | Purpose |
|--------|---------|
| `validate-plugin.sh` | Validate complete plugin |
| `validate-agent.sh` | Validate agent file |
| `validate-skill.sh` | Validate skill directory |

## Plugin Structure

```
plugin-name/
├── .claude-plugin/
│   └── plugin.json          # Required manifest
├── agents/
│   └── domain-expert.md     # Primary agent
├── skills/
│   └── skill-name/
│       ├── SKILL.md         # Core content
│       ├── references/      # Detailed docs
│       └── examples/        # Working code
├── commands/                 # Optional (0-2 max)
├── hooks/
│   └── hooks.json           # Optional
└── README.md
```

## Key Concepts

### Agent-First Design

- ONE expert agent named `{domain}-expert`
- Minimal commands (0-2) for automation only
- Users interact conversationally

### Progressive Disclosure

Three-tier skill loading:
1. **Frontmatter** - Loaded at startup
2. **SKILL.md body** - Loaded on activation
3. **references/** - Loaded when detail needed

### plugin.json Rules

```json
{
  "name": "plugin-name",
  "version": "1.0.0",
  "description": "...",
  "author": { "name": "Name" },  // Object, NOT string
  "keywords": ["word1", "word2"] // Array, NOT string
}
```

**Do NOT include**: `agents`, `skills`, `slashCommands` - auto-discovered

## Validation

Before publishing:

```bash
# Validate entire plugin
./scripts/validate-plugin.sh .

# Validate agent
./scripts/validate-agent.sh agents/plugin-expert.md

# Validate skill
./scripts/validate-skill.sh skills/plugin-master/
```

## What's New in 3.0.0

- **Restructured agent** - Renamed to `plugin-expert` with proper format
- **Progressive disclosure** - Skills split into SKILL.md + references/
- **Validation scripts** - New utilities for validating plugins, agents, skills
- **Improved commands** - Better structured with clear process steps
- **Modern patterns** - Follows official plugin-dev patterns

## Technical Details

- **Version:** 3.0.0
- **Author:** Josiah Siegel
- **License:** MIT
- **Repository:** https://github.com/JosiahSiegel/claude-plugin-marketplace

## Support

- [GitHub Issues](https://github.com/JosiahSiegel/claude-plugin-marketplace/issues)
- [Official Claude Code Docs](https://docs.claude.com/en/docs/claude-code/plugins)
