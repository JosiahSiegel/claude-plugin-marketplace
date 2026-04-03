---
description: Create a comprehensive Claude Code plugin with all necessary components and marketplace structure
argument-hint: "[plugin-name or description]"
---

# Create Plugin

Create production-ready Claude Code plugins with complete structure, documentation, and marketplace packaging.

## Process

### Step 1: Detect Context

Before creating files:

1. **Check for marketplace repo:**
   ```bash
   if [[ -f .claude-plugin/marketplace.json ]]; then
       # Create in plugins/ subdirectory
       PLUGIN_DIR="plugins/PLUGIN_NAME"
   else
       # Create in current directory
       PLUGIN_DIR="PLUGIN_NAME"
   fi
   ```

2. **Get author from git config:**
   ```bash
   AUTHOR_NAME=$(git config user.name)
   AUTHOR_EMAIL=$(git config user.email)
   ```

### Step 2: Create Structure

Create required directories:

```bash
mkdir -p $PLUGIN_DIR/.claude-plugin
mkdir -p $PLUGIN_DIR/agents
mkdir -p $PLUGIN_DIR/skills/domain-knowledge
```

### Step 3: Create Files

**Required files:**

1. **`.claude-plugin/plugin.json`** - Plugin manifest
2. **`agents/domain-expert.md`** - Primary expert agent
3. **`README.md`** - Documentation

**Optional files:**

- `skills/domain-knowledge/SKILL.md` - Core knowledge skill
- `commands/*.md` - Slash commands (0-2 max)
- `hooks/hooks.json` - Event automation
- `.mcp.json` - MCP server configuration

### Step 4: Register in Marketplace

**CRITICAL**: If `.claude-plugin/marketplace.json` exists at repo root, add the plugin entry:

```json
{
  "name": "plugin-name",
  "source": "./plugins/plugin-name",
  "description": "Same as plugin.json description",
  "version": "1.0.0",
  "author": { "name": "Author Name" },
  "keywords": ["keyword1", "keyword2"]
}
```

## Plugin Design Rules

### Agent-First Design

- **Primary interface**: ONE expert agent named `{domain}-expert`
- **Minimal commands**: Only 0-2 for specific automation workflows
- **Naming**: `docker-master` → `docker-expert`

### plugin.json Rules

```json
{
  "name": "plugin-name",           // Required, kebab-case
  "version": "1.0.0",              // String, not number
  "description": "...",
  "author": {                      // Object, NOT string
    "name": "Name",
    "email": "email@example.com"
  },
  "license": "MIT",
  "keywords": ["word1", "word2"]   // Array, NOT string
}
```

**DO NOT include**: `agents`, `skills`, `slashCommands` - these are auto-discovered

### Agent Format

```markdown
---
name: domain-expert
description: |
  Use this agent when... Examples:
  <example>
  Context: ...
  user: "..."
  assistant: "..."
  <commentary>Why trigger</commentary>
  </example>
model: inherit
color: blue
---

System prompt content...
```

## Validation

After creating plugin, validate structure with:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/validate-plugin.sh plugins/plugin-name
```

Or use: `/validate-plugin`

### Post-Creation Quality Checks

After structural validation, verify content quality:

1. **Skill trigger phrases** — Each skill description has 5+ phrases including synonyms and informal terms
2. **SKILL.md size** — No SKILL.md over 3,000 words (extract to references/ if needed)
3. **No duplicate content** — No repeated tables or blocks within any SKILL.md
4. **Agent example coverage** — Every skill has at least one agent `<example>` block routing to it
5. **No trigger overlap** — No ambiguous keyword shared between skill descriptions without disambiguation
6. **Synonym audit** — Descriptions include how users actually phrase requests, not just formal feature names

## Examples

```
/create-plugin for Docker workflow automation
/create-plugin API testing helper
/create-plugin deployment automation with rollback
```

## Tips

- Infer requirements from context - don't ask unnecessary questions
- Use git config values for author fields
- Create progressive disclosure skills (SKILL.md + references/)
- Include comprehensive README with installation instructions
- Always register in marketplace.json if in marketplace repo
