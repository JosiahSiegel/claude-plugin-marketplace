# Publishing Guide

Complete guide to publishing plugins to GitHub marketplaces.

## Marketplace Concepts

### What is a Marketplace?

A GitHub repository containing multiple plugins organized in a standard structure. Users add marketplaces and install plugins from them.

### Marketplace Structure

```text
marketplace-repo/
├── .claude-plugin/
│   └── marketplace.json     # Required: Plugin registry
├── plugins/
│   ├── plugin-one/
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json
│   │   └── ...
│   └── plugin-two/
│       └── ...
└── README.md
```

### marketplace.json Format

```json
{
  "name": "My Marketplace",
  "owner": {
    "name": "Organization Name",
    "email": "contact@org.com",
    "github": "github-username"
  },
  "plugins": [
    {
      "name": "plugin-name",
      "source": "./plugins/plugin-name",
      "description": "Plugin description matching plugin.json",
      "version": "1.0.0",
      "author": {
        "name": "Author Name"
      },
      "keywords": ["keyword1", "keyword2"]
    }
  ]
}
```

## Publishing to Existing Marketplace

### Step 1: Fork or Clone

```bash
git clone https://github.com/owner/marketplace-repo.git
cd marketplace-repo
```

### Step 2: Create Plugin Directory

```bash
mkdir -p plugins/my-plugin/.claude-plugin
mkdir -p plugins/my-plugin/agents
```

### Step 3: Create Plugin Files

Create all necessary plugin files in `plugins/my-plugin/`:
- `.claude-plugin/plugin.json`
- `agents/my-expert.md`
- `README.md`
- etc.

### Step 4: Register in marketplace.json

Add entry to the `plugins` array in `.claude-plugin/marketplace.json`:

```json
{
  "name": "my-plugin",
  "source": "./plugins/my-plugin",
  "description": "Same description as plugin.json",
  "version": "1.0.0",
  "author": {
    "name": "Your Name"
  },
  "keywords": ["relevant", "keywords"]
}
```

**CRITICAL:** Descriptions and keywords must match between:
- `plugins/my-plugin/.claude-plugin/plugin.json`
- `.claude-plugin/marketplace.json` entry
- `plugins/my-plugin/README.md`

### Step 5: Submit PR

```bash
git checkout -b add-my-plugin
git add .
git commit -m "Add my-plugin: Brief description"
git push origin add-my-plugin
# Create PR through GitHub
```

## Creating Your Own Marketplace

### Step 1: Create Repository

```bash
mkdir my-marketplace
cd my-marketplace
git init
```

### Step 2: Create Marketplace Structure

```bash
mkdir -p .claude-plugin
mkdir -p plugins
```

### Step 3: Create marketplace.json

```json
{
  "name": "My Marketplace",
  "owner": {
    "name": "Your Name",
    "email": "your@email.com",
    "github": "your-github-username"
  },
  "plugins": []
}
```

### Step 4: Add Plugins

Create plugins in `plugins/` and register each in `marketplace.json`.

### Step 5: Push to GitHub

```bash
git add .
git commit -m "Initial marketplace setup"
git remote add origin https://github.com/username/my-marketplace.git
git push -u origin main
```

**Important:** Repository must be PUBLIC for users to access.

## Installation Commands

### Adding a Marketplace

```text
/plugin marketplace add username/marketplace-repo
```

### Installing a Plugin

```text
/plugin install plugin-name@username
```

### Listing Available Plugins

```text
/plugin list --marketplace username/repo
```

## Publishing Checklist

Before publishing, verify:

### Plugin Quality
- [ ] plugin.json has all required fields
- [ ] plugin.json author is an object
- [ ] All components have YAML frontmatter
- [ ] Agent has proper `<example>` blocks
- [ ] README is comprehensive

### Marketplace Registration
- [ ] Plugin added to marketplace.json
- [ ] Source path is correct (`./plugins/plugin-name`)
- [ ] Description matches plugin.json
- [ ] Keywords synchronized
- [ ] Version matches

### Testing
- [ ] Test installation from marketplace
- [ ] Verify commands appear in `/help`
- [ ] Test agent triggering
- [ ] Check on multiple platforms if possible

### Documentation
- [ ] Plugin README has installation instructions
- [ ] Usage examples provided
- [ ] Platform-specific notes included

### Licensed / Vendored / Derived Content (MANDATORY when applicable)

If the plugin ships ANY third-party content — vendored docs, derived prompts, ported skill text, embedded example code under another license, anything that originated outside this plugin's own authorship — treat the attribution manifest as a first-class shipping artifact, NOT as doc polish.

- [ ] `NOTICES.md` exists at the plugin root (same level as `README.md`)
- [ ] Each upstream source has **exactly one** `## <source-name>` heading (no duplicate H2 sections for the same upstream — `grep -c "^## " NOTICES.md | sort | uniq -c` should show no repeats)
- [ ] Required license text (MIT preamble, Apache NOTICE, CC-BY attribution string, etc.) is preserved verbatim under each section — paraphrasing or truncation is not acceptable
- [ ] Each section names: upstream project, upstream URL, upstream license SPDX identifier, the specific file(s) in this plugin that derive from it, and the nature of the derivation (verbatim, adapted, fragment quoted)
- [ ] `README.md` contains a cross-reference: a one-liner under "License" or "Attribution" pointing to `NOTICES.md`
- [ ] `plugin.json` `license` field is consistent with what `NOTICES.md` permits (e.g., if you incorporate AGPL content, `"license": "MIT"` is wrong)
- [ ] Cross-reference test passes: `grep -l "NOTICES" README.md plugin.json` returns at least `README.md` when third-party content is present

Why this is a separate gate from regular docs: license-text preservation and accurate attribution are legal-adjacent obligations, not stylistic choices. A duplicate H2 heading for the same upstream is not a typo — it is an attribution defect that obscures the actual provenance chain.

If the plugin ships zero third-party content, `NOTICES.md` is not required and these items are N/A.

## Common Issues

### "Plugin not found"

- Check source path in marketplace.json starts with `./`
- Verify directory structure matches path
- Ensure repository is public

### "Invalid plugin manifest"

- Check plugin.json syntax
- Verify author is an object
- Ensure version is a string

### "Commands not showing"

- Check frontmatter in command files
- Verify files are in `commands/` directory
- Restart Claude Code after changes

## Version Management

### Semantic Versioning

- MAJOR (1.0.0 → 2.0.0): Breaking changes
- MINOR (1.0.0 → 1.1.0): New features
- PATCH (1.0.0 → 1.0.1): Bug fixes

### Updating Versions

1. Update `version` in plugin.json
2. Update `version` in marketplace.json
3. Update changelog in README
4. Commit and push

### Release Process

1. Create release branch
2. Update versions
3. Test thoroughly
4. Merge to main
5. Tag release: `git tag v1.0.0`
6. Push tags: `git push --tags`

## Best Practices

### Naming
- Use descriptive, unique names
- Avoid generic names like `helper` or `utils`
- Include domain in name: `docker-deploy`, `api-testing`

### Documentation
- Include real-world examples
- Document all configuration options
- Provide troubleshooting section

### Maintenance
- Respond to issues promptly
- Keep dependencies updated
- Document breaking changes clearly

### Security
- Never hardcode secrets
- Use environment variables for sensitive data
- Document required permissions
