# Plugin Master Scripts

Utility scripts for validating and testing Claude Code plugins.

## Available Scripts

### validate-plugin.sh

Validates complete plugin structure:

```bash
./scripts/validate-plugin.sh [plugin-path]
```

**Checks:**
- plugin.json exists and has valid syntax
- Required fields (name)
- Field formats (author as object, version as string, keywords as array)
- No deprecated fields (agents, skills in manifest)
- Components have YAML frontmatter

### validate-agent.sh

Validates agent file structure:

```bash
./scripts/validate-agent.sh agents/my-agent.md
```

**Checks:**
- YAML frontmatter present
- Required fields (name, description, model, color)
- Name format (3-50 chars, lowercase, hyphens)
- Model value (inherit, sonnet, opus, haiku)
- Color value (blue, cyan, green, yellow, magenta, red)
- Example blocks in description
- System prompt structure

### validate-skill.sh

Validates skill directory structure:

```bash
./scripts/validate-skill.sh skills/my-skill/
```

**Checks:**
- SKILL.md exists
- YAML frontmatter present
- Description field with use cases
- Content length (warns if > 500 lines)
- Quick Reference section
- Progressive disclosure structure (references/, examples/)
- Script executability

## Usage

### From Plugin Root

```bash
# Validate entire plugin
./scripts/validate-plugin.sh .

# Validate specific agent
./scripts/validate-agent.sh agents/plugin-expert.md

# Validate specific skill
./scripts/validate-skill.sh skills/plugin-master/
```

### From Scripts Directory

```bash
cd scripts/
./validate-plugin.sh ..
./validate-agent.sh ../agents/plugin-expert.md
./validate-skill.sh ../skills/plugin-master/
```

## Exit Codes

- `0`: Validation passed
- `1`: Validation failed (errors found)

## Output

Scripts use colored output:
- 🟢 Green (✓): Success
- 🟡 Yellow (WARNING): Potential issues
- 🔴 Red (ERROR): Must fix

## Making Scripts Executable

On Unix/Mac/Linux:

```bash
chmod +x scripts/*.sh
```

On Windows (Git Bash):

```bash
chmod +x scripts/*.sh
```

## Integration

These scripts can be used in:

1. **Pre-commit hooks**: Validate before committing
2. **CI/CD pipelines**: Validate in PRs
3. **Manual testing**: Run before publishing
