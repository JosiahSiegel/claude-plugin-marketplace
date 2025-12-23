# Plugin Master

> **Comprehensive plugin development skill for Claude Code**

Give Claude the ability to autonomously create, test, and publish Claude Code plugins with complete structures, following best practices and official documentation.

## 🎯 What This Plugin Does

This plugin teaches Claude how to create plugins with 2025 features:

- **Autonomous plugin generation** - Creates complete structures with sensible defaults
- **Latest documentation fetching** - Always uses current Claude Code specifications
- **Progressive disclosure** - Agent Skills with three-tier loading (frontmatter → body → linked files)
- **Comprehensive hooks** - Nine event types for workflow automation
- **Context efficiency** - Unbounded capacity through filesystem retrieval
- **All component types** - Commands, agents, Agent Skills, hooks, MCP servers
- **Testing automation** - Built-in validation and cross-platform testing
- **Team distribution** - Repository-level configuration (.claude/settings.json)
- **Portability** - ${CLAUDE_PLUGIN_ROOT} for cross-platform paths
- **GitHub-ready outputs** - Marketplace structures ready for publishing

## 📦 Installation

### From Marketplace (Recommended)

```bash
# Add the marketplace
/plugin marketplace add JosiahSiegel/claude-plugin-marketplace

# Install this plugin
/plugin install plugin-master@claude-plugin-marketplace
```

### Local Installation (Mac/Linux)

```bash
# Clone or download this repository
git clone https://github.com/JosiahSiegel/claude-plugin-marketplace.git

# Extract just the plugin
cd claude-plugin-marketplace/plugins
cp -r plugin-master ~/.local/share/claude/plugins/

# Restart Claude Code
```

**Note for Windows users:** Use the marketplace installation method for best results.

## 🚀 Usage

Once installed, Claude automatically recognizes plugin creation requests:

### Basic Examples

**Create a Git workflow plugin:**
```
"Create a plugin for Git workflows"
```
→ Claude generates complete Git plugin with PR, commit, and branch commands

**Create a deployment plugin:**
```
"Make a deployment automation plugin"
```
→ Claude builds deployment plugin with staging, production, and rollback commands

**Create a code review plugin:**
```
"Build a code review plugin with security focus"
```
→ Claude creates plugin with review commands and security-focused agents

### Advanced Examples

**API integration plugin:**
```
"Create a plugin that integrates with our Stripe API"
```
→ Claude generates plugin with API commands, skills, and MCP server configuration

**Package an existing skill:**
```
"Package this skill as a plugin for my team"
```
→ Claude converts any skill document into a distributable plugin

## 🎁 What You Get

Every plugin Claude creates includes:

### Plugin Files
- ✅ `plugin.json` - Properly configured manifest
- ✅ Commands - Working slash commands in markdown
- ✅ Agents - Specialized subagents when appropriate
- ✅ Skills - Knowledge documents when useful
- ✅ `README.md` - Complete documentation

### Distribution
- ✅ **Complete plugin directory** - Ready for local development
- ✅ **Marketplace structure** - Ready for GitHub publishing
- ✅ **Optional skill export** - ZIP skills for claude.ai web app

### Documentation
- ✅ Installation instructions (GitHub + local)
- ✅ Usage examples
- ✅ Platform compatibility notes
- ✅ Publishing guidelines

## 📋 Available Commands

### `/plugin-master:create-plugin`
Create a comprehensive Claude Code plugin with 2025 features (Agent Skills, hooks, MCP, repository config).

### `/plugin-master:generate-plugin`
Generate a complete, production-ready plugin with all 2025 capabilities.

### `/plugin-master:test-plugin`
Test plugin structure, validation, and cross-platform functionality before publishing.

### `/plugin-master:validate-plugin`
Validate plugin structure, manifests, and configuration files against 2025 standards.

### `/plugin-master:publish-plugin`
Prepare and publish Claude Code plugins to GitHub marketplaces with complete documentation.

### `/plugin-master:setup-repo-plugins`
Configure repository-level automatic plugin installation for team standardization.

### `/plugin-master:plugin-guide`
Get comprehensive guidance on creating Claude Code plugins with 2025 features.

## 🤖 Available Agents

### plugin-architect
Expert in Claude Code plugin architecture, design patterns, and best practices. Specializes in creating production-ready plugins.

**Invoke via Task tool:**
```
Task: plugin-architect agent for design review
```

**Capabilities:**
- Plugin architecture design
- Component selection and organization
- Best practices implementation
- Performance optimization
- Cross-platform compatibility
- Marketplace publishing strategy

## 🧠 Included Skills

### plugin-master
Comprehensive beginner's guide providing step-by-step guidance for creating Claude Code plugins.

**Covers:**
- What Claude Code plugins are
- Your first plugin in 10 minutes
- Creating plugin structures with 2025 features
- Publishing to marketplaces
- Testing workflows
- Best practices
- Troubleshooting

### advanced-features-2025
Complete guide to cutting-edge 2025 plugin capabilities.

**Covers:**
- Agent Skills patterns and best practices
- Hooks system (PreToolUse, PostToolUse, SessionStart, etc.)
- MCP server integration
- Repository-level configuration
- Environment variables (${CLAUDE_PLUGIN_ROOT})
- Context efficiency strategies
- Migration from legacy plugins

Both skills are automatically available when the plugin is installed.

## 🔧 Plugin Creation Workflow

When you ask Claude to create a plugin, it follows this process:

1. **Fetch Documentation** - Gets latest plugin specs from official docs
2. **Infer Requirements** - Determines components needed from your request
3. **Create Structure** - Builds complete directory hierarchy
4. **Generate Files** - Creates plugin.json, commands, agents, skills, README
5. **Create Marketplace Structure** - Prepares GitHub-ready directory layout
6. **Provide Instructions** - Gives installation and publishing guidance

## 🎯 Use Cases

### For Individual Developers
- **Rapid prototyping** - Test plugin ideas quickly
- **Learning** - See working examples of plugin structures
- **Templates** - Generate baseline plugins to customize

### For Teams
- **Standardization** - Ensure consistent plugin structures
- **Knowledge sharing** - Package team expertise as plugins
- **Workflow automation** - Create custom commands for common tasks

### For Organizations
- **Internal tools** - Package proprietary workflows
- **Best practices** - Enforce standards through plugins
- **Onboarding** - Create plugins for new team members

## 🌐 Platform Notes

- ✅ **Windows:** Marketplace installation recommended (local paths may have issues)
- ✅ **Git Bash/MinGW:** Use marketplace installation method; includes shell detection and path conversion guidance
- ✅ **macOS:** All installation methods work
- ✅ **Linux:** All installation methods work

**For Plugin Developers on Git Bash:**
- Shell detection with $MSYSTEM environment variable
- Path conversion awareness for testing
- GitHub marketplace method recommended for reliability

## 📚 Documentation

This plugin includes comprehensive documentation:

- **Beginner's guide** - Learn plugin development from scratch
- **Step-by-step tutorials** - Create your first plugin in 10 minutes
- **Component guides** - Commands, agents, skills, hooks, MCP servers
- **Publishing guide** - Get your plugin on GitHub
- **Best practices** - Security, naming, structure conventions
- **Troubleshooting** - Common issues and solutions

## 🔍 Technical Details

**Plugin Name:** plugin-master
**Version:** 2.2.0
**Author:** Josiah Siegel
**License:** MIT
**Repository:** https://github.com/JosiahSiegel/claude-plugin-marketplace

**Components:**
- 7 slash commands (create, generate, test, validate, publish, setup, guide)
- 1 specialized agent (plugin-architect)
- 2 comprehensive skills (plugin-master + advanced-features-2025)

**New in 2.2.0:**
- Git Bash/MinGW compatibility guidance for plugin development
- Shell environment detection ($MSYSTEM) for testing workflows
- Path conversion troubleshooting for Windows development environments
- Enhanced cross-platform testing instructions
- Plugin installation path guidance for Git Bash users

**Features from 2.1.0:**
- Plugin testing command with automated validation
- Progressive disclosure patterns for Agent Skills
- Unbounded capacity context strategies
- Nine hook event types documented
- Enhanced portability guidelines with ${CLAUDE_PLUGIN_ROOT}
- Evaluation-driven skill development practices
- Structural scalability patterns

## 🤝 Contributing

Contributions welcome! Areas for improvement:

- Additional plugin templates
- More examples
- Platform-specific optimizations
- Documentation enhancements
- New commands or agents

## 🆘 Support

For help:
- Check the included comprehensive guide
- Review [official Claude Code docs](https://docs.claude.com/en/docs/claude-code/plugins)
- Join Claude Developers Discord
- File [issues on GitHub](https://github.com/JosiahSiegel/claude-plugin-marketplace/issues)

## 📄 License

MIT License - free to use, modify, and distribute.

## 🎓 Credits

Created by Josiah Siegel. Built on the Claude Skills system and Claude Code plugin framework by Anthropic.

---

**Start creating plugins today!** Install this plugin and ask Claude to build something amazing.
