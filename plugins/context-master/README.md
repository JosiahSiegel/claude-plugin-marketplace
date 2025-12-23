# Context Master Plugin

Optimal planning and context management for multi-file projects, website creation, and complex coding tasks. Full cross-platform support including Windows with Git Bash.

## Overview

Context Master helps Claude Code work more efficiently on multi-file projects by:
- **Planning optimal file creation order** before implementation
- **Preventing redundant work** through dependency-aware architecture
- **Saving context tokens** (62% reduction on average)
- **Providing extended thinking delegation** patterns
- **Verifying project structures** automatically
- **Supporting Windows/Git Bash workflows** with path conversion guidance

## Quick Start

### When to Use

Context Master activates automatically for:
- Creating 3+ related files (HTML, CSS, JS, docs, etc.)
- Building complete websites or web applications
- Multi-file code projects (APIs, full-stack apps, libraries)
- Tasks requiring 5+ sequential steps
- Architecture or design planning before implementation

### Basic Workflow

For ANY multi-file project, follow these 5 steps:

```
1. STOP - Don't create files yet
2. PLAN - Use /plan-project command
3. ANNOUNCE - Tell user your file creation order
4. CREATE - Make files in optimal order (dependencies first)
5. VERIFY - Use /verify-structure to check all references work
```

## Installation

### Option 1: GitHub Marketplace (Recommended for All Platforms)

1. **Add this marketplace:**
   ```bash
   /plugin marketplace add JosiahSiegel/claude-code-marketplace
   ```

2. **Install the plugin:**
   ```bash
   /plugin install context-master@claude-plugin-marketplace
   ```

### Option 2: Local Installation (Mac/Linux)

```bash
# Extract to plugins directory
unzip context-master.zip -d ~/.local/share/claude/plugins/
```

### Windows Users

**Important:** Use GitHub marketplace installation method (Option 1) for best compatibility. Local installation may encounter path conversion issues with Git Bash.

If you encounter path-related issues:
- See **WINDOWS_GIT_BASH_GUIDE.md** for troubleshooting
- Consider upgrading Claude Code to v1.0.72+
- Ensure Git Bash is properly configured

## Features

### Commands

#### `/plan-project`
Plan optimal file creation order for multi-file projects before implementation.

**Token Savings:** ~5,000 tokens (62% reduction) per multi-file project

#### `/verify-structure`
Verify multi-file project structure and cross-file references after creation.

**Checks:**
- File paths are correct (cross-platform compatible)
- CSS/JS references load properly
- Navigation between pages works
- Cross-file dependencies resolve
- Consistency across files

#### `/context-analysis`
Analyze context usage and suggest optimization strategies for ongoing session.

#### `/optimize-context`
Real-time context optimization for ongoing sessions with metrics and recommendations.

### Skills

#### `context-master`
Comprehensive knowledge about:
- Multi-file project planning workflows
- Optimal file creation order principles
- Context-efficient patterns and strategies
- Extended thinking delegation architecture
- CLI-specific tooling (for Claude Code users)
- Windows/Git Bash path compatibility

## Token Savings

### Real-World Impact

**Small Project (3-4 files) - Portfolio Website**
- Without planning: ~6,000 tokens
- With planning: ~2,500 tokens
- **Savings: ~3,500 tokens (58%)**

**Medium Project (7-8 files) - Multi-page App**
- Without planning: ~12,000 tokens
- With planning: ~4,500 tokens
- **Savings: ~7,500 tokens (63%)**

**Large Project (20+ files) - Full Application**
- Without planning: ~35,000 tokens
- With planning: ~12,000 tokens
- **Savings: ~23,000 tokens (66%)**

## Platform Support

### Cross-Platform Compatibility

Context Master works identically on:
- **macOS** - Full support, no path issues
- **Linux** - Full support, no path issues
- **Windows with Git Bash** - Full support with path conversion guidance
- **Windows with PowerShell/CMD** - Full support

### Windows/Git Bash Specific Notes

Context Master fully supports Windows development with Git Bash. Understanding automatic path conversion helps optimize workflows:

**Automatic Path Conversion:**
- Git Bash converts Unix-style paths to Windows paths automatically
- This usually works transparently with Context Master
- See WINDOWS_GIT_BASH_GUIDE.md for advanced scenarios

**Known Issues (mostly resolved in Claude Code v1.0.72+):**
- Path conversion failure in snapshot operations
- Drive letter duplication errors
- Spaces in paths

**Workarounds:**
- Use GitHub marketplace installation
- Upgrade Claude Code to v1.0.72+
- See WINDOWS_GIT_BASH_GUIDE.md for detailed troubleshooting

## Best Practices

### Always Plan Before Creating Files
- Use `/plan-project` for any 3+ file task
- Identify shared dependencies first
- Create foundation files before dependents
- Announce your plan to the user

### Verify After Creation
- Use `/verify-structure` to catch errors early
- Check all file paths and references
- Ensure navigation and imports work

### Optimize Context Throughout Session
- Use `/context-analysis` periodically
- Create artifacts for code and documents
- Break complex tasks into phases

## Troubleshooting

### Plugin Not Loading
- Check plugin.json syntax
- Windows users: Use GitHub marketplace instead
- Run with --debug flag for details

### Commands Not Showing
- Verify commands directory contains .md files
- Reload plugins: claude --reload-plugins

### Windows/Git Bash Issues
- Check WINDOWS_GIT_BASH_GUIDE.md for detailed solutions
- Verify Git Bash installation
- Check environment variables

## Documentation

- **SKILL.md** - Comprehensive skill documentation
- **WINDOWS_GIT_BASH_GUIDE.md** - Windows/Git Bash compatibility guide
- **commands/** - Individual command documentation

## License

MIT

---

**Get Started:** Install the plugin and try `/plan-project` on your next multi-file task!

**Windows Users:** See WINDOWS_GIT_BASH_GUIDE.md for Git Bash compatibility notes.
