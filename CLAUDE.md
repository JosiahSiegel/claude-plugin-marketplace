# Claude Code Marketplace - AI Agent Instructions

## Critical: Version Management

**NEVER manually edit plugin versions.** Always use the version management script:

```bash
# Bump a single plugin after making changes
python3 scripts/version_ops.py -b patch -p <plugin-name>

# Bump ALL plugins
python3 scripts/version_ops.py -b patch --all

# Validate versions are in sync
python3 scripts/version_ops.py --validate

# Sync versions if they get out of sync
python3 scripts/version_ops.py --sync
```

The script maintains consistency between:
- `.claude-plugin/marketplace.json` (central registry)
- `plugins/<name>/.claude-plugin/plugin.json` (individual configs)

**Version bump types:**
- `patch` - Bug fixes, docs, minor tweaks
- `minor` - New features, skills, agents
- `major` - Breaking changes

See `scripts/CLAUDE.md` for complete documentation.

## Agent Model Configuration

All agents should use `model: inherit` to adopt the parent session's model:

```yaml
---
name: my-agent
model: inherit  # Inherits from parent session (opus/sonnet/haiku)
---
```

## File Structure

```
claude-code-marketplace/
├── .claude-plugin/
│   └── marketplace.json      # Central plugin registry
├── plugins/
│   └── <plugin-name>/
│       ├── .claude-plugin/
│       │   └── plugin.json   # Plugin config (version must match marketplace)
│       ├── agents/           # Agent definitions (.md)
│       ├── skills/           # Skills (.md)
│       ├── commands/         # Slash commands (.md)
│       └── hooks/            # Lifecycle hooks (.md)
└── scripts/
    ├── version_ops.py        # Version management script
    └── CLAUDE.md             # Detailed version docs
```
