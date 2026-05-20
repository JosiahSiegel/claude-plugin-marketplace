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
/plugin install plugin-master@claude-plugin-marketplace
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
| `plugin-master` | Core plugin development guide — layout, manifest, marketplace registration |
| `advanced-features-2025` | Hooks, MCP, progressive disclosure, team distribution |
| `agent-development` | Agent frontmatter, `<example>` blocks, system prompts, tool restriction |
| `skill-development` | SKILL.md authoring, progressive disclosure, references/ vs examples/ |
| `hook-development` | Prompt-based and command hooks, events, matchers, security |
| `triggering-reliability` | Anti-pattern catalog, severity tiers (P0/P1/P2), canonical checklist, description-length caps |

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

```text
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

## What's New

- **Thin-router commands** - `/create-plugin` and `/validate-plugin` are now lean routers (~40 lines each) that delegate to the `plugin-expert` agent and named skills. No duplicated content between commands and skills.
- **Corrected description limits** - Size limits updated to match Claude Code's actual API spec (1024-char hard ceiling per description) and listing cap (1536 chars, raised from 250 in v2.1.105). Target is now 400-1000 chars, not the obsolete ~500-char "soft target."
- **Severity table & canonical checklist** - `triggering-reliability` skill now owns the P0/P1/P2 severity tiers and the canonical pre-publish checklist; commands point users at the skill rather than duplicating it.
- **Lean orchestrator pattern** - Agent body stays an orchestrator; all domain knowledge lives in skills.
- **Progressive disclosure enforcement** - Skills over 2,000 words split into SKILL.md + references/.

## Technical Details

- **Author:** Josiah Siegel
- **License:** MIT
- **Repository:** https://github.com/JosiahSiegel/claude-plugin-marketplace

## Support

- [GitHub Issues](https://github.com/JosiahSiegel/claude-plugin-marketplace/issues)
- [Official Claude Code Docs](https://docs.claude.com/en/docs/claude-code/plugins)
