# Windows Path Master

**Windows path resolution and Git Bash compatibility expert for Claude Code.**

Never struggle with file path errors on Windows again! This plugin automatically detects and converts Git Bash MINGW paths to Windows-native format, ensuring Claude Code's file operation tools work flawlessly.

## The Problem

When using Claude Code on Windows with Git Bash, file operations often fail with errors like:

```
Error: ENOENT: no such file or directory
```

**Why?** Git Bash displays paths in POSIX/MINGW format (`/s/repos/file.txt`), but Claude Code's Edit/Write/Read tools require Windows native format (`S:\repos\file.txt`).

## The Solution

This plugin provides:

✅ **Automatic path detection and conversion** from MINGW to Windows format
✅ **Proactive error prevention** before file operations fail
✅ **Expert troubleshooting guidance** for Windows path issues
✅ **Cross-platform compatibility** knowledge (WSL, Git Bash, Windows)
✅ **Interactive path fixing** with the `/path-fix` command
✅ **Comprehensive educational resources** to understand path formats

## Installation

### Via Marketplace (Recommended)

```bash
/plugin marketplace add JosiahSiegel/claude-plugin-marketplace
/plugin install windows-path-master@claude-plugin-marketplace
```

### Local Installation (Windows/Mac/Linux)

```bash
# Clone or download this repository
git clone https://github.com/JosiahSiegel/claude-plugin-marketplace

# Copy plugin to Claude Code plugins directory
# Windows (Git Bash):
cp -r plugins/windows-path-master ~/.local/share/claude/plugins/

# Windows (PowerShell):
Copy-Item -Recurse plugins\windows-path-master $env:USERPROFILE\.local\share\claude\plugins\

# Mac/Linux:
cp -r plugins/windows-path-master ~/.local/share/claude/plugins/
```

## Features

### 1. Automatic Path Detection & Conversion

The plugin automatically detects these path formats and converts them:

| Input Format | Converted To | Example |
|--------------|--------------|---------|
| **MINGW (Git Bash)** | Windows native | `/s/repos/file.txt` → `S:\repos\file.txt` |
| **Windows with `/`** | Windows with `\` | `S:/repos/file.txt` → `S:\repos\file.txt` |
| **WSL paths** | Windows native | `/mnt/c/Users/file.txt` → `C:\Users\file.txt` |
| **Relative paths** | Absolute Windows | `./src/file.txt` → `S:\repos\project\src\file.txt` |

### 2. Proactive Error Prevention

**Before:**
```
User: "Edit /s/repos/project/file.tsx"
Claude: [Tries to edit, fails with ENOENT error]
Claude: "Sorry, file not found"
```

**After (with windows-path-master):**
```
User: "Edit /s/repos/project/file.tsx"
Claude: "I'll convert this Git Bash path to Windows format (S:\repos\project\file.tsx) and edit the file..."
✅ File edited successfully!
```

### 3. Windows Path Expert Agent

Specialized AI agent that:
- Automatically activates for Windows path issues
- Converts paths before they cause problems
- Explains what was changed and why
- Provides troubleshooting guidance

### 4. Interactive Path Fix Command

Use `/path-fix` to interactively diagnose and fix path issues:

```bash
/path-fix
```

The command will:
1. Analyze the path format
2. Show the conversion process
3. Explain what changed
4. Provide education on Windows paths
5. Retry failed operations with correct paths

### 5. Comprehensive Knowledge Base

The plugin includes extensive documentation on:
- Windows vs MINGW path formats
- Conversion algorithms
- Git Bash compatibility
- Common error messages and solutions
- Best practices for Windows file operations
- Cross-platform path handling

## Usage Examples

### Example 1: Edit a File (Git Bash Path)

```bash
# In Git Bash, you see:
pwd
# Output: /s/repos/claude-plugin-marketplace

# You ask Claude:
"Edit the file /s/repos/myproject/README.md"

# Plugin automatically converts:
# From: /s/repos/myproject/README.md
# To:   S:\repos\myproject\README.md

# Result: ✅ File edited successfully!
```

### Example 2: Fix a Failed File Operation

```bash
# File operation fails with "file not found"

# Run the path fix command:
/path-fix

# Plugin will:
# 1. Analyze the path that failed
# 2. Detect it's MINGW format
# 3. Convert to Windows format
# 4. Retry the operation
# 5. Explain what was wrong
```

### Example 3: Work with Relative Paths

```bash
# You're in Git Bash:
pwd -W
# Output: S:/repos/my-project

# You ask Claude:
"Edit ./src/components/Button.tsx"

# Plugin converts:
# From: ./src/components/Button.tsx (relative)
# To:   S:\repos\my-project\src\components\Button.tsx (absolute Windows)

# Result: ✅ File edited successfully!
```

## Components

### Commands

#### `/path-fix`
Interactive path troubleshooting and conversion command.

**Use when:**
- File operations fail with path errors
- You need to verify path format
- You want to understand path conversion

**Features:**
- Detects path format automatically
- Shows conversion steps
- Explains what changed
- Provides educational tips

### Agents

#### Windows Path Expert
Specialized agent that automatically activates for Windows path issues.

**Activates when:**
- File path errors occur on Windows
- MINGW paths are detected (e.g., `/s/`, `/c/`)
- Edit/Write/Read tool failures happen
- User mentions Windows or Git Bash

**Capabilities:**
- Automatic path detection and conversion
- Proactive error prevention
- Clear communication of changes
- Troubleshooting guidance

### Skills

#### Windows Path Troubleshooting
Comprehensive knowledge base for Windows path issues.

**Covers:**
- MINGW to Windows path conversion
- WSL path handling
- Relative path resolution
- UNC network paths
- Common error messages and solutions
- Best practices for Windows file operations
- Cross-platform compatibility

## How It Works

### The Decision Tree

When you provide a file path, the plugin follows this logic:

```
1. Detect path format:
   - MINGW format? (/s/, /c/, etc.) → Convert to Windows
   - Windows with /? (S:/, C:/) → Replace / with \
   - WSL format? (/mnt/c/) → Convert to Windows
   - Relative path? (./, ../) → Request full path
   - Already Windows? (S:\) → Use as-is

2. Convert path:
   - Extract drive letter
   - Replace separators
   - Construct Windows path

3. Verify format:
   - Starts with drive letter (C:, S:)
   - Uses backslashes (\)
   - Is absolute path

4. Use in file operation:
   - Edit/Write/Read tools work correctly!
```

### Conversion Algorithm

**MINGW to Windows:**
```
Input:  /s/repos/claude-plugin-marketplace/file.tsx

Steps:
1. Extract drive letter: "s" → "S"
2. Add colon: "S:"
3. Get remaining path: repos/myproject/file.tsx
4. Replace / with \: repos\myproject\file.tsx
5. Combine: S:\repos\myproject\file.tsx

Output: S:\repos\myproject\file.tsx
```

## Common Scenarios

### Scenario 1: "File Not Found" Error

**Problem:**
```
User: "Edit /s/repos/file.txt"
Error: ENOENT: no such file or directory
```

**Solution:**
```
Plugin detects MINGW format
Converts: /s/repos/file.txt → S:\repos\file.txt
Retries with Windows path
✅ Success!
```

### Scenario 2: Copying Path from Git Bash

**Problem:**
```
# In Git Bash:
pwd
/s/repos/my-project

# User copies and pastes this path
# Claude tries to use it directly
# ❌ Fails because it's MINGW format
```

**Solution:**
```
Plugin automatically detects MINGW format
Converts to Windows: S:\repos\my-project
Claude can now work with the path
✅ Success!
```

### Scenario 3: Mixed Environment (WSL + Git Bash)

**Problem:**
```
User sometimes uses WSL (/mnt/c/Users/...)
User sometimes uses Git Bash (/c/Users/...)
Different path formats cause confusion
```

**Solution:**
```
Plugin handles both formats:
- WSL: /mnt/c/Users/file.txt → C:\Users\file.txt
- Git Bash: /c/Users/file.txt → C:\Users\file.txt
Both convert to same Windows format
✅ Consistent behavior!
```

## Best Practices

### For Users

1. **Use `pwd -W` in Git Bash** to get Windows-formatted paths
   ```bash
   pwd -W  # Shows: S:/repos/project (Windows format with /)
   ```

2. **Provide absolute paths** when possible (avoid relative paths)
   ```
   ✅ Good: S:\repos\project\file.txt
   ❌ Avoid: ./file.txt
   ```

3. **Use the `/path-fix` command** when you encounter path errors

4. **Learn the conversion pattern** so you understand what's happening

### For Claude Code

The plugin ensures Claude Code:
- ✅ Always uses backslashes (`\`) on Windows
- ✅ Converts MINGW paths automatically
- ✅ Validates path format before file operations
- ✅ Provides clear explanations of conversions
- ✅ Educates users about path formats

## Troubleshooting

### Issue: Plugin not activating

**Check:**
1. Is the plugin installed? Run `/plugin list`
2. Is this a Windows system with Git Bash?
3. Does the path match MINGW format (`/c/`, `/s/`, etc.)?

### Issue: Conversion still results in errors

**Possible causes:**
1. File doesn't actually exist at that path
2. Typo in filename
3. File extension missing
4. Permission issues

**Solution:**
Use `/path-fix` to diagnose, or verify the file exists:
```bash
# In Git Bash:
ls -la /s/repos/file.txt
```

### Issue: Path looks correct but still fails

**Check:**
- Are there trailing spaces?
- Is the file extension hidden in Windows?
- Is the file locked by another program?
- Do you have read/write permissions?

## Platform Notes

### Windows
✅ **Primary use case** - This plugin is designed for Windows users
✅ **Git Bash** - Automatically handles MINGW path conversion
✅ **WSL** - Supports WSL path format (`/mnt/c/`)
✅ **PowerShell/CMD** - Works with native Windows paths

### macOS/Linux
ℹ️ Plugin will not activate on Unix systems (paths already use `/`)
ℹ️ No conversion needed on these platforms

## Technical Details

### Path Format Reference

**MINGW (Git Bash on Windows):**
- Format: `/[drive-letter]/path/to/file`
- Example: `/s/repos/project/file.txt`
- Used by: Git Bash, MSYS2, Cygwin

**WSL (Windows Subsystem for Linux):**
- Format: `/mnt/[drive-letter]/path/to/file`
- Example: `/mnt/c/Users/name/file.txt`
- Used by: WSL 1, WSL 2

**Windows Native:**
- Format: `[Drive]:\path\to\file`
- Example: `S:\repos\project\file.txt`
- Used by: Windows Explorer, CMD, PowerShell

**Windows with Forward Slashes:**
- Format: `[Drive]:/path/to/file`
- Example: `S:/repos/project/file.txt`
- Used by: Git Bash output of `pwd -W`

### Environment Detection

The plugin activates based on:
1. User mentions "Windows" or "Git Bash"
2. Path starts with `/[letter]/` (MINGW pattern)
3. Path starts with `/mnt/[letter]/` (WSL pattern)
4. File operation error on Windows
5. Platform is Windows (detected via environment)

## Contributing

Contributions are welcome! This plugin is part of the [Claude Code Marketplace](https://github.com/JosiahSiegel/claude-plugin-marketplace).

To contribute:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

MIT License - See LICENSE file for details

## Support

- **Issues:** [GitHub Issues](https://github.com/JosiahSiegel/claude-plugin-marketplace/issues)
- **Discussions:** [GitHub Discussions](https://github.com/JosiahSiegel/claude-plugin-marketplace/discussions)
- **Marketplace:** [Claude Code Marketplace](https://claudecodemarketplace.com/)

## Related Plugins

- **bash-master** - Expert bash/shell scripting across all platforms
- **git-master** - Complete Git expertise system
- **context-master** - Universal context management and planning

## Acknowledgments

Created to solve the #1 file operation issue for Windows users: **path format incompatibility between Git Bash and Claude Code**.

Special thanks to the Claude Code community for feedback and testing!

---

**Stop fighting with file paths. Start coding.** 🚀
