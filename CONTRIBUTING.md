# Contributing to Claude Code Marketplace

Thank you for your interest in contributing to this Claude Code plugin marketplace! We welcome contributions of new plugins, improvements to existing plugins, and documentation enhancements.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How to Contribute](#how-to-contribute)
- [Adding a New Plugin](#adding-a-new-plugin)
- [Updating Existing Plugins](#updating-existing-plugins)
- [Plugin Guidelines](#plugin-guidelines)
- [Submission Process](#submission-process)
- [Review Process](#review-process)

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment for all contributors.

## How to Contribute

There are several ways to contribute:

1. **Add a new plugin** to the marketplace
2. **Improve existing plugins** with bug fixes or enhancements
3. **Update documentation** to help users
4. **Report issues** with existing plugins
5. **Suggest improvements** to the marketplace structure

## Adding a New Plugin

### Prerequisites

Before creating a plugin:
- Familiarize yourself with [Claude Code plugin documentation](https://docs.claude.com/en/docs/claude-code/plugins)
- Review existing plugins in this marketplace for examples
- Ensure your plugin provides unique value

### Plugin Structure

Your plugin must follow this structure:

```
plugins/your-plugin-name/
├── .claude-plugin/
│   └── plugin.json          # Plugin manifest (required)
├── commands/                 # Slash commands (optional)
│   └── command-name.md
├── agents/                   # Specialized agents (optional)
│   └── agent-name.md
├── skills/                   # Skills/knowledge (optional)
│   └── skill-name/
│       └── SKILL.md
├── hooks/                    # Event hooks (optional)
├── mcp/                      # MCP servers (optional)
├── LICENSE                   # License file (required)
└── README.md                 # Plugin documentation (required)
```

### Required Files

#### 1. plugin.json

```json
{
  "name": "your-plugin-name",
  "version": "1.0.0",
  "description": "Clear, concise description of what your plugin does",
  "author": {
    "name": "Your Name",
    "email": "your-github-username@users.noreply.github.com"
  },
  "license": "MIT",
  "keywords": ["relevant", "keywords", "for", "search"],
  "commands": {
    "command-name": "./commands/command-name.md"
  },
  "agents": {
    "agent-name": "./agents/agent-name.md"
  },
  "skills": {
    "skill-name": "./skills/skill-name"
  }
}
```

#### 2. README.md

Your plugin README should include:
- Clear description of what the plugin does
- Installation instructions
- Usage examples
- Available commands/agents/skills
- Configuration options (if any)
- Troubleshooting guide
- License information

#### 3. LICENSE

Use MIT License for consistency with the marketplace, or another permissive open-source license.

### Step-by-Step Guide

1. **Fork this repository**
   ```bash
   # On GitHub, click "Fork" button
   ```

2. **Clone your fork**
   ```bash
   git clone https://github.com/YOUR-USERNAME/claude-plugin-marketplace.git
   cd claude-plugin-marketplace
   ```

3. **Create a new branch**
   ```bash
   git checkout -b add-your-plugin-name
   ```

4. **Create your plugin directory**
   ```bash
   mkdir -p plugins/your-plugin-name/.claude-plugin
   ```

5. **Add your plugin files**
   - Create `plugin.json` with all required fields
   - Add commands, agents, skills as needed
   - Write comprehensive `README.md`
   - Include `LICENSE` file

6. **Update marketplace.json**
   ```json
   {
     "name": "claude-plugin-marketplace",
     "description": "A curated collection of Claude Code plugins for plugin development, context optimization, and productivity tools",
     "owner": {
       "name": "Josiah Siegel",
       "email": "JosiahSiegel@users.noreply.github.com"
     },
     "plugins": [
       // ... existing plugins ...
       {
         "name": "your-plugin-name",
         "source": "./plugins/your-plugin-name",
         "description": "Brief description for marketplace listing",
         "version": "1.0.0",
         "author": {
           "name": "Your Name"
         },
         "keywords": ["relevant", "keywords"]
       }
     ]
   }
   ```

7. **Test your plugin locally**
   ```bash
   # Copy to Claude plugins directory
   cp -r plugins/your-plugin-name ~/.local/share/claude/plugins/

   # Test all commands and functionality
   ```

8. **Commit your changes**
   ```bash
   git add .
   git commit -m "Add your-plugin-name plugin"
   ```

9. **Push to your fork**
   ```bash
   git push origin add-your-plugin-name
   ```

10. **Create a Pull Request**
    - Go to the original repository on GitHub
    - Click "New Pull Request"
    - Select your branch
    - Fill out the PR template

## Updating Existing Plugins

To update an existing plugin:

1. Fork and clone the repository
2. Create a new branch: `git checkout -b update-plugin-name`
3. Make your changes
4. Update the version number in `plugin.json`
5. Update the version in `.claude-plugin/marketplace.json`
6. Document changes in the plugin's README
7. Submit a pull request

## Plugin Guidelines

### Quality Standards

- **Documentation**: Clear, comprehensive README with examples
- **Code Quality**: Well-structured, commented code
- **Testing**: Verify all commands/agents/skills work correctly
- **Error Handling**: Graceful handling of edge cases
- **Performance**: Efficient, minimal resource usage

### Naming Conventions

- **Plugin names**: lowercase-with-hyphens
- **Command names**: descriptive-action-names
- **Agent names**: specific-role-names
- **Skill names**: topic-or-capability-names

### Privacy & Security

- **Use GitHub no-reply email**: `username@users.noreply.github.com`
- **No secrets**: Never commit API keys, tokens, or credentials
- **No malicious code**: All code must serve legitimate, defensive purposes only
- **Clear permissions**: Document what access your plugin needs

### License Requirements

- Use MIT or another OSI-approved open-source license
- Include LICENSE file in your plugin directory
- Ensure compatibility with marketplace MIT license

## Submission Process

### Pull Request Checklist

Before submitting, ensure:

- [ ] Plugin follows the required structure
- [ ] `plugin.json` includes all required fields
- [ ] README.md is comprehensive and well-formatted
- [ ] LICENSE file is included
- [ ] `.claude-plugin/marketplace.json` is updated
- [ ] All commands/agents/skills are tested
- [ ] No sensitive information (API keys, personal emails)
- [ ] Plugin name is unique in the marketplace
- [ ] Version number follows semantic versioning (1.0.0)

### Pull Request Template

Use this template when creating your PR:

```markdown
## Plugin Submission: [Plugin Name]

### Description
Brief description of what the plugin does and why it's useful.

### Type of Change
- [ ] New plugin
- [ ] Bug fix
- [ ] Enhancement
- [ ] Documentation update

### Testing
Describe how you tested the plugin:
- [ ] All commands work correctly
- [ ] Agents function as expected
- [ ] Skills load properly
- [ ] Cross-platform compatibility verified

### Checklist
- [ ] Plugin structure follows guidelines
- [ ] Documentation is complete
- [ ] No sensitive information included
- [ ] marketplace.json updated
- [ ] License included
```

## Review Process

### What Happens After Submission

1. **Initial Review** (1-3 days)
   - Structure verification
   - Documentation check
   - Basic functionality test

2. **Detailed Review** (3-7 days)
   - Code quality assessment
   - Security review
   - Cross-platform testing
   - Documentation clarity

3. **Feedback**
   - Requested changes (if any)
   - Approval or revision needed

4. **Merge**
   - Plugin added to marketplace
   - Available for installation

### Review Criteria

Plugins are evaluated on:
- **Functionality**: Does it work as described?
- **Usefulness**: Does it provide value to users?
- **Quality**: Is the code well-written and documented?
- **Security**: Is it safe to use?
- **Compatibility**: Does it work across platforms?

## Getting Help

- **Questions**: Open an [issue](https://github.com/JosiahSiegel/claude-plugin-marketplace/issues) with the "question" label
- **Bugs**: Report with detailed reproduction steps
- **Suggestions**: Open an issue with the "enhancement" label
- **Documentation**: Refer to [Claude Code docs](https://docs.claude.com/en/docs/claude-code/plugins)

## Recognition

Contributors will be:
- Listed as plugin authors in plugin.json
- Credited in plugin README files
- Acknowledged in release notes

## License

By contributing to this marketplace, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to the Claude Code ecosystem!
