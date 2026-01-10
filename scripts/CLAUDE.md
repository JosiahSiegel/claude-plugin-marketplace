# Version Tracking for AI Agents

This document describes how AI agents should use the `version_ops.py` script to manage plugin versions in the Claude Plugin Marketplace.

## Overview

The marketplace uses two locations for plugin versions:
1. **`.claude-plugin/marketplace.json`** - Central registry with all plugin metadata
2. **`plugins/<plugin-name>/.claude-plugin/plugin.json`** - Individual plugin configuration

Both locations MUST have matching versions. The `version_ops.py` script ensures consistency.

## File Locations

```
claude-code-marketplace/
├── .claude-plugin/
│   └── marketplace.json          # Central version registry
├── plugins/
│   ├── bash-master/
│   │   └── .claude-plugin/
│   │       └── plugin.json       # Plugin-specific version
│   ├── ffmpeg-master/
│   │   └── .claude-plugin/
│   │       └── plugin.json
│   └── ...                       # 25 plugins total
└── scripts/
    ├── version_ops.py            # Main Python script
    ├── version-tracker.sh        # Bash wrapper
    └── CLAUDE.md                 # This documentation
```

## Usage

```bash
# Run from repo root
python3 scripts/version_ops.py [OPTIONS] [PLUGIN_NAME]

# Or use the bash wrapper
./scripts/version-tracker.sh [OPTIONS] [PLUGIN_NAME]
```

## Complete CLI Reference

```
usage: version_ops.py [-h] [-v] [-s] [-b {patch,minor,major}]
                      [-i {patch,minor,major}] [-p PLUGIN] [-a] [-d] [-q]
                      [--json] [plugin_name]

Options:
  -h, --help                 Show help message
  -v, --validate             Validate all versions match (default action)
  -s, --sync                 Sync versions using highest (never downgrades)
  -b, --bump {patch,minor,major}
                             Bump version type
  -i, --increment {patch,minor,major}
                             Same as --bump
  -p, --plugin PLUGIN        Plugin name to bump
  -a, --all                  Apply bump to ALL plugins
  -d, --dry-run              Preview changes without applying
  -q, --quiet                Only show errors and mismatches
  --json                     Output as JSON (for programmatic use)

Positional:
  plugin_name                Plugin name (alternative to -p)
```

## Commands

### Validate Versions (Default)

Check that all versions match between marketplace.json and plugin.json files:

```bash
python3 scripts/version_ops.py
python3 scripts/version_ops.py --validate
python3 scripts/version_ops.py -q              # Quiet - only show mismatches
python3 scripts/version_ops.py --json          # Machine-readable output
```

**Exit codes:**
- `0` - All versions match
- `1` - Version mismatches found
- `2` - Plugin directories missing

### Sync Versions

Synchronize versions using the highest version (never downgrades):

```bash
python3 scripts/version_ops.py --sync
python3 scripts/version_ops.py --sync --dry-run  # Preview changes
python3 scripts/version_ops.py -s -d             # Short form
```

**Behavior:** Compares versions between marketplace.json and plugin.json. Updates BOTH files to the higher version. This ensures versions never go down.

### Bump Single Plugin

Increment a single plugin's version (updates both locations automatically):

```bash
# Using -p flag
python3 scripts/version_ops.py -b patch -p bash-master
python3 scripts/version_ops.py -b minor -p ffmpeg-master
python3 scripts/version_ops.py -b major -p modal-master

# Using positional argument
python3 scripts/version_ops.py -b patch bash-master
python3 scripts/version_ops.py --bump minor ffmpeg-master

# Preview with dry-run
python3 scripts/version_ops.py -b patch -p bash-master --dry-run
```

### Bump ALL Plugins

Increment version for all 25 plugins at once:

```bash
# Preview first (recommended)
python3 scripts/version_ops.py -b patch --all --dry-run
python3 scripts/version_ops.py -b minor --all --dry-run
python3 scripts/version_ops.py -b major --all --dry-run

# Apply changes
python3 scripts/version_ops.py -b patch --all    # Bug fixes
python3 scripts/version_ops.py -b minor --all    # New features
python3 scripts/version_ops.py -b major --all    # Breaking changes
```

**Version bump types:**
- `patch` - Bug fixes, docs, minor tweaks (1.0.0 -> 1.0.1)
- `minor` - New features, skills, agents (1.0.0 -> 1.1.0)
- `major` - Breaking changes, rewrites (1.0.0 -> 2.0.0)

## Current Plugins (25 total)

| Plugin | Description |
|--------|-------------|
| context-master | Context management |
| plugin-master | Plugin development |
| bash-master | Bash/shell scripting |
| git-master | Git operations |
| docker-master | Docker/containers |
| ado-master | Azure DevOps |
| test-master | Testing frameworks |
| powershell-master | PowerShell scripting |
| terraform-master | Terraform IaC |
| ssdt-master | SQL Server Data Tools |
| adf-master | Azure Data Factory |
| salesforce-master | Salesforce development |
| azure-master | Azure cloud |
| azure-to-docker-master | Azure to Docker migration |
| windows-path-master | Windows path handling |
| dotnet-microservices-master | .NET microservices |
| ffmpeg-master | FFmpeg video/audio |
| tailwindcss-master | TailwindCSS |
| react-master | React development |
| nextjs-master | Next.js framework |
| python-master | Python development |
| fal-ai-master | Fal.ai integration |
| modal-master | Modal.com serverless |
| viral-video-master | Viral video creation |
| tsql-master | T-SQL development |

## AI Agent Workflow

### Standard Workflow

```bash
# 1. Check current status
python3 scripts/version_ops.py --validate

# 2. Make your plugin changes
# ... edit files ...

# 3. Bump the version
python3 scripts/version_ops.py -b patch -p <plugin-name>

# 4. Verify the update
python3 scripts/version_ops.py --validate
```

### After Modifying a Plugin
```bash
python3 scripts/version_ops.py -b patch -p <plugin-name>
```

### After Adding New Features
```bash
python3 scripts/version_ops.py -b minor -p <plugin-name>
```

### After Making Breaking Changes
```bash
python3 scripts/version_ops.py -b major -p <plugin-name>
```

### If Versions Get Out of Sync
```bash
# Preview what would be synced
python3 scripts/version_ops.py --sync --dry-run

# Apply sync (uses highest version)
python3 scripts/version_ops.py --sync
```

### Bulk Operations (All Plugins)
```bash
# Bump all plugins for a release
python3 scripts/version_ops.py -b patch --all --dry-run  # Preview
python3 scripts/version_ops.py -b patch --all            # Apply
```

## Guidelines for AI Agents

1. **Always validate before committing** - Run `--validate` to ensure versions are in sync
2. **Bump versions after changes** - Every plugin modification should include a version bump
3. **Use appropriate bump type:**
   - `patch` for bug fixes, documentation updates, minor tweaks
   - `minor` for new skills, agents, or features
   - `major` for breaking changes, major rewrites, API changes
4. **Never manually edit versions** - Always use this script to maintain consistency
5. **Preview with --dry-run** - Use dry-run before sync or bump operations to verify
6. **Use --all for bulk operations** - When updating multiple plugins, use `--all` flag
7. **Check JSON output** - Use `--json` flag for programmatic parsing of validation results

## Examples

```bash
# Complete workflow after updating bash-master plugin
python3 scripts/version_ops.py --validate              # Check status
python3 scripts/version_ops.py -b patch -p bash-master # Bump version
python3 scripts/version_ops.py --validate              # Verify update

# Sync all versions after manual edits
python3 scripts/version_ops.py --sync --dry-run        # Preview
python3 scripts/version_ops.py --sync                  # Apply

# Prepare for release - bump all plugins
python3 scripts/version_ops.py -b patch --all --dry-run
python3 scripts/version_ops.py -b patch --all

# Check only mismatches (quiet mode)
python3 scripts/version_ops.py -q

# Get JSON output for scripting
python3 scripts/version_ops.py --json | jq '.summary'

# Using positional argument (shorter syntax)
python3 scripts/version_ops.py -b minor ffmpeg-master
```

## Troubleshooting

### "Plugin not found in marketplace"
The plugin name doesn't exist in marketplace.json. Check spelling and use exact plugin name.

### Version mismatch after manual edit
Run `python3 scripts/version_ops.py --sync` to automatically fix using the highest version.

### Missing plugin.json
The script will warn but continue. Only marketplace.json will be updated for that plugin.

### Colors not showing
Colors are automatically disabled when output is piped. Use `--json` for machine-readable output.
