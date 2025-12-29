---
description: Create a comprehensive Claude Code plugin with all necessary components and marketplace structure
---

## 🚨 CRITICAL GUIDELINES

### Windows File Path Requirements

**MANDATORY: Always Use Backslashes on Windows for File Paths**

When using Edit or Write tools on Windows, you MUST use backslashes (`\`) in file paths, NOT forward slashes (`/`).

**Examples:**
- ❌ WRONG: `D:/repos/project/file.tsx`
- ✅ CORRECT: `D:\repos\project\file.tsx`

This applies to:
- Edit tool file_path parameter
- Write tool file_path parameter
- All file operations on Windows systems


### Documentation Guidelines

**NEVER create new documentation files unless explicitly requested by the user.**

- **Priority**: Update existing README.md files rather than creating new documentation
- **Repository cleanliness**: Keep repository root clean - only README.md unless user requests otherwise
- **Style**: Documentation should be concise, direct, and professional - avoid AI-generated tone
- **User preference**: Only create additional .md files when user specifically asks for documentation


---

# Create Plugin

Autonomously create production-ready Claude Code plugins with complete structure, documentation, and marketplace packaging.

## Purpose

Guides Claude through the complete plugin creation workflow: fetching latest docs, generating all files (plugin.json, commands, agents, skills, README), creating marketplace structure, and providing installation instructions.

## Instructions

1. **Fetch latest documentation** from docs.claude.com (plugins-reference, plugin-marketplaces)
2. **Detect repository context** - Check git config for author info and marketplace.json existence
3. **Infer requirements** from user request - Only ask questions if genuinely ambiguous
4. **Create comprehensive structure**:
   - Plugin manifest with all appropriate metadata fields
   - Commands, agents, and Agent Skills as needed (2025: Skills are auto-discovered from skills/ directory)
   - Hooks for automated workflows (PreToolUse, PostToolUse, SessionStart, etc.)
   - MCP servers for external integrations (inline in plugin.json or .mcp.json)
   - Complete README with examples and installation instructions
   - Marketplace structure if not in existing marketplace repo
5. **Apply 2025 best practices**:
   - Use Agent Skills for dynamic knowledge loading
   - Configure hooks for automated validation and testing
   - Support repository-level plugin configuration via .claude/settings.json
   - Use ${CLAUDE_PLUGIN_ROOT} environment variable for portable paths
6. **Validate plugin.json schema** - **CRITICAL RULES**:
   - ✅ `repository` must be a **string URL**, NOT an object
   - ✅ `agents` field is **NOT needed** - auto-discovered from `agents/` directory
   - ✅ `skills` field is **NOT needed** - auto-discovered from `skills/` directory
   - ✅ `commands` field is **optional** - auto-discovered from `commands/` directory by default
   - ✅ Only include: name, version, description, author (object), homepage, repository (string), license, keywords (array)
   - ❌ NEVER include `agents: {...}` or `skills: {...}` in plugin.json - these cause validation errors
7. **🚨 MANDATORY: Register in marketplace.json** (NON-NEGOTIABLE):
   - **FIRST**: Check if `.claude-plugin/marketplace.json` exists at repo root
   - **IF EXISTS**: Read it and add new plugin entry to `plugins` array
   - **FORMAT**: `{"name": "plugin-name", "source": "./plugins/plugin-name", "description": "...", "version": "1.0.0", "author": {"name": "..."}, "keywords": [...]}`
   - **SYNCHRONIZE**: Descriptions must match between plugin.json, marketplace.json, and README.md
   - **⚠️ PLUGIN CREATION IS NOT COMPLETE UNTIL REGISTERED IN MARKETPLACE.JSON ⚠️**
8. **Update README.md** - Add plugin to appropriate category
9. **Provide clear instructions** for GitHub-first installation and repository-level configuration

## Best Practices

### Plugin Design Philosophy (2025)

**Agent-First, Minimal Commands:**
- **Primary interface:** Expert agent that users interact with conversationally
- **Minimal commands:** Only 0-2 slash commands per plugin for specific, high-value workflows
- **Why:** Users want to invoke domain expertise, not navigate command menus
- **Commands only for:** Automated workflows, batch operations, or specialized utilities
- **Agent handles:** Questions, guidance, code generation, troubleshooting, best practices

**Agent Naming Standard:**
- **CRITICAL:** Every plugin must have exactly ONE primary agent named `{domain}-expert`
- **Pattern:** `docker-master` → agent named `docker-expert`
- **Pattern:** `terraform-master` → agent named `terraform-expert`
- **Why:** Predictable names allow Claude to reliably invoke the correct agent
- **Never:** Use multiple specialized agents or non-standard names

**Examples:**
- ✅ `dotnet-microservices-master`: 0 commands, 1 agent (`dotnet-microservices-expert`)
- ✅ `docker-master`: 0 commands, 1 agent (`docker-expert`)
- ❌ OLD: 10+ commands + multiple agents - overwhelming and unpredictable!

**Default to action, not questions** - infer intent from context
- Include agent and Agent Skills by default
- Commands only when genuinely needed for automation
- Use detected git config values for author fields (never use placeholders)
- Create in plugins/ subdirectory if marketplace.json exists at repo root
- **ALWAYS update `.claude-plugin/marketplace.json` when adding plugins to a marketplace repository**
- Synchronize descriptions and keywords between plugin.json, marketplace.json, and README.md
- Add hooks for common automation needs (testing, linting, validation)
- Use ${CLAUDE_PLUGIN_ROOT} for all internal paths (scripts, configs, MCP servers)
- Include .claude/settings.json template for team distribution
- Leverage Agent Skills for dynamic, context-efficient knowledge delivery
- Configure MCP servers inline in plugin.json for simpler distribution
- Emphasize GitHub marketplace installation for cross-platform reliability (especially Windows/Git Bash)
- Document shell detection for plugin testing ($MSYSTEM for Git Bash/MinGW)
- Include path conversion guidance for Git Bash users developing plugins
- Support repository-level automatic installation for team standardization

## Example Usage

```
/create-plugin for Git workflow automation
/create-plugin with deployment commands and rollback features
/create-plugin that helps with code reviews and security scanning
```

The plugin-master skill activates automatically to provide complete templates and current best practices.
