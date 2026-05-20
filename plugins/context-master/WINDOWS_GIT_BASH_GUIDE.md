# Windows / Git Bash Compatibility Guide for Context Master

This guide addresses path conversion and shell compatibility when using context-master plugin on Windows with Git Bash.

## Git Bash Path Conversion Overview

When using Git Bash (MSYS2/MinGW), Windows paths may be automatically converted. Understanding this is critical for context workflows.

### Automatic Conversion Behavior

Git Bash automatically converts paths in specific contexts:

**Unix → Windows:**
- `/foo` → `C:/Program Files/Git/usr/foo`

**Path Lists (colon-separated):**
- `/foo:/bar` → `C:\msys64\foo;C:\msys64\bar`

**Arguments:**
- `--dir=/foo` → `--dir=C:/msys64/foo`

### What Triggers Conversion
- Leading forward slash (/) in arguments
- Colon-separated path lists
- Arguments after `-` or `,` with path components

### What's Exempt (NOT Converted)
- Arguments containing `=` (variable assignments like `VAR=/path`)
- Drive specifiers like `C:`
- Arguments with `;` (already Windows format)
- Arguments starting with `//` (Windows switches)

## Claude Code Specific Issues

### Issue: Path Conversion Failure in Snapshot Operations

**Error Pattern:**
```text
/usr/bin/bash: line 1: C:UsersDavid...No such file or directory
```

**Root Cause:** `os.tmpdir()` returns Windows paths in Git Bash, triggering conversion.

**Solution (Claude Code v1.0.51+):**
Set environment variable:
```bash
export CLAUDE_CODE_GIT_BASH_PATH=C:\Program\ Files\git\bin\bash.exe
```

**Note:** Versions 1.0.72+ reportedly work without modifications.

### Other Known Issues
- Drive letter duplication: `D:\dev` → `D:\d\dev`
- Spaces in paths (Program Files) cause failures
- VS Code extension can't auto-detect Git Bash

## Shell Detection for Context Workflows

### Method 1: $OSTYPE (Bash Only)
```bash
case "$OSTYPE" in
  linux-gnu*)  # Linux
  darwin*)     # macOS
  cygwin*)     # Cygwin
  msys*)       # MSYS/Git Bash/MinGW
  win*)        # Windows
esac
```

### Method 2: uname -s (Most Portable)
```bash
case "$(uname -s)" in
  Darwin*)     # macOS
  Linux*)      # Linux or WSL
  CYGWIN*)     # Cygwin
  MINGW64*)    # Git Bash 64-bit
  MINGW32*)    # Git Bash 32-bit
  MSYS_NT*)    # MSYS
esac
```

### Method 3: $MSYSTEM (MSYS2/Git Bash Specific)
```bash
case "$MSYSTEM" in
  MINGW64)  # Native Windows 64-bit
  MINGW32)  # Native Windows 32-bit
  MSYS)     # POSIX-compliant environment
esac
```

### Node.js Shell Detection
```javascript
function detectShell() {
  const { platform, env } = process;

  // Git Bash/MinGW (MOST RELIABLE)
  if (env.MSYSTEM) return { type: 'mingw', subsystem: env.MSYSTEM };

  // WSL
  if (env.WSL_DISTRO_NAME) return { type: 'wsl', distro: env.WSL_DISTRO_NAME };

  // PowerShell
  if (env.PSModulePath?.split(';').length >= 3) return { type: 'powershell' };

  // Cygwin
  if (env.TERM === 'cygwin') return { type: 'cygwin' };

  // Unix shells
  if (env.SHELL?.includes('bash')) return { type: 'bash' };
  if (env.SHELL?.includes('zsh')) return { type: 'zsh' };

  return { type: 'unknown', platform };
}
```

## Path Conversion Control

### MSYS_NO_PATHCONV (Git for Windows)
Disable ALL path conversion:
```bash
export MSYS_NO_PATHCONV=1
```
Value doesn't matter - just needs to be defined.

### MSYS2_ARG_CONV_EXCL (MSYS2)
Exclude specific patterns:
```bash
export MSYS2_ARG_CONV_EXCL="*"              # Exclude everything
export MSYS2_ARG_CONV_EXCL="--dir=;/test"  # Specific prefixes
```

### MSYS2_ENV_CONV_EXCL
Prevent environment variable conversion:
```bash
export MSYS2_ENV_CONV_EXCL="*"  # Same syntax as MSYS2_ARG_CONV_EXCL
```

## Common Workarounds for Path Issues

1. **Use double slashes** instead of single slashes:
   - Use `//e //s` instead of `/e /s`

2. **Use dash notation**:
   - Use `-e -s` instead of `/e /s`

3. **Set MSYS_NO_PATHCONV before command**:
   ```bash
   MSYS_NO_PATHCONV=1 command_that_uses_paths
   ```

4. **Quote paths with spaces**:
   ```bash
   "./path with spaces/script.sh"
   ```

## Context Master Compatibility Notes

### Multi-File Project Planning on Windows

When using `/plan-project` on Windows with Git Bash:

1. **File path references** in planning documents should use forward slashes (Unix format)
2. **Actual file creation** uses platform-appropriate separators
3. **Verification checks** work cross-platform

Example:
```text
Planning (Unix format):
- styles.css
- js/app.js
- pages/index.html

Creation (Windows):
- D:\project\styles.css
- D:\project\js\app.js
- D:\project\pages\index.html

Verification: Works identically on both platforms
```

### Path Verification in /verify-structure

The `/verify-structure` command:
- Auto-detects platform (Windows vs Unix)
- Normalizes paths internally for comparison
- Reports issues using native path format

**Example verification output on Windows:**
```text
✓ File paths verified:
  D:\project\styles.css ✓
  D:\project\index.html → references D:\project\styles.css ✓
  D:\project\about.html → references D:\project\styles.css ✓
```

## Optimal Context Workflow for Windows/Git Bash Users

### Step 1: Detect Your Environment
Understand your setup:
```bash
echo "MSYSTEM: $MSYSTEM"
echo "OS: $(uname -s)"
echo "SHELL: $SHELL"
```

### Step 2: Set Path Conversion Expectations
- If using Git Bash: Expect automatic path conversion in some contexts
- If using PowerShell/CMD: Standard Windows path behavior
- If using WSL: Treat as Linux environment

### Step 3: Use Context Master Commands
All commands work identically regardless of shell:

```bash
/plan-project           # Works on all platforms
/verify-structure       # Auto-detects platform
/context-analysis       # Platform-independent
/optimize-context       # Platform-independent
```

### Step 4: Reference Paths Appropriately
- In planning documents: Use `/` (forward slashes)
- In actual file operations: Use `\` (backslashes on Windows)
- In verification: System handles both formats

## Quick Reference

| Scenario | Action |
|----------|--------|
| Path conversion causing issues | Set `MSYS_NO_PATHCONV=1` |
| Drive letter duplication errors | Upgrade Claude Code to v1.0.72+ |
| Spaces in path failing | Quote the path: `"C:\Program Files\..."` |
| Need to verify multi-file project | Use `/verify-structure` command |
| Planning multi-file project | Use `/plan-project` (cross-platform) |
| Git Bash detection needed | Check `$MSYSTEM` environment variable |

## Related Resources

- **Git Bash Documentation:** https://git-scm.com/book/en/v2
- **MSYS2 Documentation:** https://www.msys2.org/
- **Claude Code Issues:** Reference issue #2602 (path conversion failure)

---

For additional context management guidance, see:
- README.md - Main plugin documentation
- SKILL.md - Comprehensive context strategies
- commands/ - Individual command documentation
