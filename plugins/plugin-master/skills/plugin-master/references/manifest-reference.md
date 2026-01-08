# Plugin Manifest Reference

Complete documentation for all plugin.json fields.

## Required Fields

### name (required)

```json
{
  "name": "my-plugin-name"
}
```

**Rules:**
- Kebab-case format (lowercase with hyphens)
- Must be unique across installed plugins
- No spaces or special characters
- 3-50 characters

**Valid examples:**
- `code-review-assistant`
- `test-runner`
- `api-docs-generator`

**Invalid examples:**
- `My Plugin` (spaces, uppercase)
- `my_plugin` (underscores)
- `ab` (too short)

## Recommended Fields

### version

Semantic versioning string:

```json
{
  "version": "1.0.0"
}
```

**Format:** MAJOR.MINOR.PATCH
- MAJOR: Breaking changes
- MINOR: New features (backward compatible)
- PATCH: Bug fixes

**CRITICAL:** Must be a STRING, not a number:
- ✅ `"1.0.0"`
- ❌ `1.0` (number)

### description

Brief explanation of plugin purpose:

```json
{
  "description": "Complete [domain] expertise. PROACTIVELY activate for: (1) Use case 1, (2) Use case 2. Provides: capability list."
}
```

**Best practices:**
- Start with "Complete" or action verb
- Include numbered use cases
- Mention key capabilities
- Keep under 300 characters for display

### author

**MUST be an object:**

```json
{
  "author": {
    "name": "Author Name",
    "email": "author@example.com",
    "url": "https://author-website.com"
  }
}
```

**NEVER a string:**
```json
// ❌ WRONG - will cause validation errors
{
  "author": "Author Name"
}
```

**Minimal:**
```json
{
  "author": {
    "name": "Author Name"
  }
}
```

### homepage

Documentation or landing page URL:

```json
{
  "homepage": "https://docs.example.com/my-plugin"
}
```

### repository

Source code repository URL:

```json
{
  "repository": "https://github.com/user/repo"
}
```

**Note:** Must be a STRING URL, not an object.

### license

SPDX license identifier:

```json
{
  "license": "MIT"
}
```

**Common values:**
- `MIT` - Permissive
- `Apache-2.0` - Permissive with patent clause
- `GPL-3.0` - Copyleft
- `BSD-3-Clause` - Permissive
- `UNLICENSED` - Proprietary

### keywords

Array of discovery keywords:

```json
{
  "keywords": ["testing", "automation", "ci-cd", "quality"]
}
```

**MUST be an array:**
- ✅ `["word1", "word2"]`
- ❌ `"word1, word2"` (string)

**Best practices:**
- Include 5-15 relevant keywords
- Use lowercase
- Include technology names (e.g., `docker`, `kubernetes`)
- Include use cases (e.g., `testing`, `deployment`)

## Optional Configuration Fields

### commands

Custom commands directory (supplements default):

```json
{
  "commands": "./custom-commands"
}
```

Or array for multiple directories:

```json
{
  "commands": ["./commands", "./extra-commands"]
}
```

**Note:** Default `commands/` still loads automatically.

### agents

Custom agents directory:

```json
{
  "agents": "./custom-agents"
}
```

### hooks

Custom hooks configuration file:

```json
{
  "hooks": "./config/hooks.json"
}
```

### mcpServers

MCP server configuration file:

```json
{
  "mcpServers": "./.mcp.json"
}
```

Or inline configuration:

```json
{
  "mcpServers": {
    "server-name": {
      "command": "node",
      "args": ["${CLAUDE_PLUGIN_ROOT}/servers/server.js"],
      "env": {
        "API_KEY": "${API_KEY}"
      }
    }
  }
}
```

## Complete Example

```json
{
  "name": "deployment-helper",
  "version": "2.1.0",
  "description": "Complete deployment automation system. PROACTIVELY activate for: (1) Production deployments, (2) Rollback operations, (3) Environment configuration. Provides: safe deployments, automated rollbacks, multi-environment support.",
  "author": {
    "name": "DevOps Team",
    "email": "devops@company.com",
    "url": "https://company.com/devops"
  },
  "homepage": "https://docs.company.com/deployment-helper",
  "repository": "https://github.com/company/deployment-helper",
  "license": "MIT",
  "keywords": [
    "deployment",
    "devops",
    "automation",
    "rollback",
    "production",
    "staging",
    "kubernetes",
    "docker"
  ]
}
```

## Validation Checklist

Before publishing, verify:

- [ ] `name` is kebab-case, unique
- [ ] `version` is a string like "1.0.0"
- [ ] `author` is an object with at least `name`
- [ ] `keywords` is an array of strings
- [ ] `repository` is a URL string (if present)
- [ ] No `agents`, `skills`, `slashCommands` fields (auto-discovered)
- [ ] JSON syntax is valid (use validator)

## Common Errors

**"author must be an object"**
```json
// Change from:
"author": "Name"
// To:
"author": { "name": "Name" }
```

**"version must be a string"**
```json
// Change from:
"version": 1.0
// To:
"version": "1.0.0"
```

**"keywords must be an array"**
```json
// Change from:
"keywords": "word1, word2"
// To:
"keywords": ["word1", "word2"]
```
