# Cross-Platform Git Considerations

Reference for line endings, case sensitivity, path handling, and Git Bash specifics on Windows.

## Line Endings

```bash
# Windows (CRLF in working directory, LF in repository)
git config --global core.autocrlf true

# macOS/Linux (LF everywhere)
git config --global core.autocrlf input

# No conversion (not recommended)
git config --global core.autocrlf false
```

Use `.gitattributes` for consistency:

```gitattributes
* text=auto
*.sh text eol=lf
*.bat text eol=crlf
```

## Case Sensitivity

```bash
# macOS/Windows: Case-insensitive filesystems
# Linux: Case-sensitive filesystem

# Enable case sensitivity in Git
git config --global core.ignorecase false

# Rename file (case-only change)
git mv --force myfile.txt MyFile.txt
```

## Path Handling

Git always uses forward slashes internally. This works on all platforms:

```bash
git add src/components/Header.jsx
```

Windows-specific tools may need backslashes in some contexts.

## Git Bash / MINGW Path Conversion (Windows)

**CRITICAL: Git Bash is the primary Git environment on Windows.**

Git Bash (MINGW/MSYS2) automatically converts Unix-style paths to Windows paths for native executables, which can cause issues with Git operations.

### Path Conversion Behavior

```text
# Automatic conversions that occur:
/foo          -> C:/Program Files/Git/usr/foo
/foo:/bar     -> C:\msys64\foo;C:\msys64\bar
--dir=/foo    -> --dir=C:/msys64/foo
```

What triggers conversion:
- Leading forward slash (`/`) in arguments
- Colon-separated path lists
- Arguments after `-` or `,` with path components

What's exempt from conversion:
- Arguments containing `=` (variable assignments)
- Drive specifiers (`C:`)
- Arguments with `;` (already Windows format)
- Arguments starting with `//` (Windows switches)

### Controlling Path Conversion

```bash
# Method 1: MSYS_NO_PATHCONV (Git for Windows only)
# Disable ALL path conversion for a command
MSYS_NO_PATHCONV=1 git command --option=/path

# Permanently disable (use with caution - can break scripts)
export MSYS_NO_PATHCONV=1

# Method 2: MSYS2_ARG_CONV_EXCL (MSYS2)
# Exclude specific argument patterns
export MSYS2_ARG_CONV_EXCL="*"              # Exclude everything
export MSYS2_ARG_CONV_EXCL="--dir=;/test"  # Specific prefixes

# Method 3: Manual conversion with cygpath
cygpath -u "C:\path"     # -> Unix format: /c/path
cygpath -w "/c/path"     # -> Windows format: C:\path
cygpath -m "/c/path"     # -> Mixed format: C:/path

# Method 4: Workarounds
# Use double slashes: //e //s instead of /e /s
# Use dash notation: -e -s instead of /e /s
# Quote paths with spaces: "/c/Program Files/file.txt"
```

### Shell Detection in Git Workflows

```bash
# Method 1: $MSYSTEM (Most Reliable for Git Bash)
case "$MSYSTEM" in
  MINGW64)  echo "Git Bash 64-bit" ;;
  MINGW32)  echo "Git Bash 32-bit" ;;
  MSYS)     echo "MSYS environment" ;;
esac

# Method 2: uname -s (Portable)
case "$(uname -s)" in
  MINGW64_NT*)  echo "Git Bash 64-bit" ;;
  MINGW32_NT*)  echo "Git Bash 32-bit" ;;
  MSYS_NT*)     echo "MSYS" ;;
  CYGWIN*)      echo "Cygwin" ;;
  Darwin*)      echo "macOS" ;;
  Linux*)       echo "Linux" ;;
esac

# Method 3: $OSTYPE (Bash-only, fast)
case "$OSTYPE" in
  msys*)       echo "Git Bash/MSYS" ;;
  cygwin*)     echo "Cygwin" ;;
  darwin*)     echo "macOS" ;;
  linux-gnu*)  echo "Linux" ;;
esac
```

### Git Bash Path Issues & Solutions

```bash
# Issue: Git commands with paths fail in Git Bash
# Example: git log --follow /path/to/file fails

# Solution 1: Use relative paths
git log --follow ./path/to/file

# Solution 2: Disable path conversion
MSYS_NO_PATHCONV=1 git log --follow /path/to/file

# Solution 3: Use Windows-style paths
git log --follow C:/path/to/file

# Issue: Spaces in paths (Program Files)
# Solution: Always quote paths
git add "/c/Program Files/project/file.txt"

# Issue: Drive letter duplication (D:\dev -> D:\d\dev)
# Solution: Use cygpath for conversion
file=$(cygpath -u "D:\dev\file.txt")
git add "$file"
```

### Git Bash Best Practices

1. **Always use forward slashes in Git commands** - Git handles them on all platforms
2. **Quote paths with spaces** - Essential in Git Bash
3. **Use relative paths when possible** - Avoids conversion issues
4. **Detect shell environment** - Use `$MSYSTEM` for Git Bash detection
5. **Test scripts on Git Bash** - Primary Windows Git environment
6. **Use `MSYS_NO_PATHCONV` selectively** - Only when needed, not globally
