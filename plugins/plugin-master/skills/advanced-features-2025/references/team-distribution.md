# Team Plugin Distribution

Repository-level configuration for automatic plugin installation.

## Overview

Teams can configure repositories to automatically install plugins when developers trust the folder. This ensures consistent tooling across all team members.

## Configuration File

Create `.claude/settings.json` at repository root:

```
repo-root/
├── .claude/
│   └── settings.json    # Plugin configuration
├── src/
└── README.md
```

## Settings Format

### Basic Configuration

```json
{
  "extraKnownMarketplaces": [
    "company/internal-plugins"
  ],
  "plugins": {
    "enabled": [
      "code-standards@company",
      "deployment-helper@company"
    ]
  }
}
```

### Multiple Marketplaces

```json
{
  "extraKnownMarketplaces": [
    "company/internal-plugins",
    "JosiahSiegel/claude-plugin-marketplace",
    "team/specialized-tools"
  ],
  "plugins": {
    "enabled": [
      "code-standards@company",
      "docker-master@JosiahSiegel",
      "custom-tool@team"
    ]
  }
}
```

## Plugin Specification

### Format

```
plugin-name@marketplace-owner
```

### Examples

```json
{
  "plugins": {
    "enabled": [
      "docker-master@JosiahSiegel",     // From JosiahSiegel marketplace
      "test-helper@company",             // From company marketplace
      "code-review-helper"               // From default marketplace
    ]
  }
}
```

## Setup Workflow

### For Repository Maintainers

1. **Create configuration directory:**
   ```bash
   mkdir -p .claude
   ```

2. **Create settings.json:**
   ```json
   {
     "extraKnownMarketplaces": [
       "your-org/plugins"
     ],
     "plugins": {
       "enabled": [
         "required-plugin@your-org"
       ]
     }
   }
   ```

3. **Commit to version control:**
   ```bash
   git add .claude/settings.json
   git commit -m "Add Claude Code plugin configuration"
   ```

4. **Document in README:**
   ```markdown
   ## Development Setup

   This repository uses Claude Code plugins for standardized workflows.

   ### First Time Setup
   1. Install Claude Code
   2. Clone this repository
   3. Open folder in Claude Code
   4. Trust this folder when prompted
   5. Plugins will install automatically
   ```

### For Team Members

1. Clone repository
2. Open in Claude Code
3. Trust folder when prompted
4. Plugins install automatically
5. Start working with shared tooling

## Advanced Patterns

### Environment-Specific Plugins

```json
{
  "extraKnownMarketplaces": [
    "company/plugins"
  ],
  "plugins": {
    "enabled": [
      "core-tools@company"
    ]
  }
}
```

Create different configs per environment using branches or separate files (though only one .claude/settings.json is read).

### Minimal vs Full Setup

**Minimal (essential only):**
```json
{
  "extraKnownMarketplaces": ["company/core"],
  "plugins": {
    "enabled": ["standards@company"]
  }
}
```

**Full (all team tools):**
```json
{
  "extraKnownMarketplaces": [
    "company/core",
    "company/optional",
    "JosiahSiegel/claude-plugin-marketplace"
  ],
  "plugins": {
    "enabled": [
      "standards@company",
      "testing@company",
      "docs-helper@company",
      "docker-master@JosiahSiegel"
    ]
  }
}
```

## Security Considerations

### Trust Model

- Users must explicitly trust folders
- Trust is granted per-folder, not globally
- Review settings.json before trusting unknown repos

### Marketplace Security

- Only trust verified marketplaces
- Use organization-owned marketplaces for internal tools
- Review plugin code before adding to marketplace

### Best Practices

1. **Document requirements:**
   ```markdown
   ## Required Plugins

   This repo requires the following plugins:
   - `code-standards` - Enforces coding standards
   - `test-helper` - Runs tests automatically

   Review plugin source at: https://github.com/company/plugins
   ```

2. **Explain why:**
   ```markdown
   These plugins ensure:
   - Consistent code formatting
   - Automatic test execution
   - Standard commit messages
   ```

3. **Provide opt-out:**
   ```markdown
   To skip plugin installation:
   - Remove `.claude/settings.json` locally
   - Or: Don't trust the folder
   ```

## Maintenance

### Updating Plugins

1. Update version in marketplace
2. Team members get updates on next session

### Adding New Plugins

1. Add to marketplace if new
2. Add to settings.json
3. Commit change
4. Team members get on pull

### Removing Plugins

1. Remove from settings.json
2. Commit change
3. Team members manually uninstall

## Troubleshooting

### Plugins not installing

- Verify settings.json syntax is valid JSON
- Check marketplace names are correct
- Ensure repo is trusted
- Verify marketplace is public

### Wrong marketplace

- Check spelling of marketplace owner
- Verify plugin exists in specified marketplace
- Try full format: `plugin@owner`

### Conflicts

- Ensure plugin names are unique
- Check for version conflicts
- Review error messages in Claude Code

### Testing Configuration

```bash
# Validate JSON syntax
cat .claude/settings.json | python -m json.tool

# Check file exists
ls -la .claude/

# Verify git status
git status .claude/
```

## Example Configurations

### Frontend Team

```json
{
  "extraKnownMarketplaces": [
    "company/frontend-tools"
  ],
  "plugins": {
    "enabled": [
      "react-patterns@company",
      "typescript-helper@company",
      "style-guide@company"
    ]
  }
}
```

### Backend Team

```json
{
  "extraKnownMarketplaces": [
    "company/backend-tools"
  ],
  "plugins": {
    "enabled": [
      "api-design@company",
      "database-helper@company",
      "security-scanner@company"
    ]
  }
}
```

### DevOps Team

```json
{
  "extraKnownMarketplaces": [
    "company/devops-tools",
    "JosiahSiegel/claude-plugin-marketplace"
  ],
  "plugins": {
    "enabled": [
      "terraform-master@JosiahSiegel",
      "docker-master@JosiahSiegel",
      "ci-helper@company"
    ]
  }
}
```
