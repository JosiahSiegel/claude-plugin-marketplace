# Windows Path Troubleshooting: Errors, Platform Notes, Advanced Scenarios

Detailed lookup tables for common Claude Code Windows path errors, platform-specific behavior (PowerShell, CMD, Git Bash, WSL, Node/Python), user-teaching scripts, and advanced path scenarios (UNC paths, long paths, spaces, special characters). SKILL.md keeps critical path rules, common issues, conversion algorithm, fixing workflow, checklist, quick-reference examples, and best practices.

## 🐛 Common Error Messages and Solutions

### Error: "ENOENT: no such file or directory"

**Most likely cause:** Forward slashes instead of backslashes

**Solution:**
1. Check if path uses forward slashes
2. Convert to backslashes
3. Verify drive letter format
4. Retry operation

### Error: "Invalid file path"

**Most likely cause:** MINGW path format

**Solution:**
1. Detect `/x/` pattern at start
2. Convert to `X:` format
3. Replace all forward slashes with backslashes
4. Retry operation

### Error: "Access denied" or "Permission denied"

**Most likely cause:** Path is correct but permissions issue

**Solution:**
1. Verify file exists and is accessible
2. Check if file is locked by another process
3. Verify user has read/write permissions
4. Consider running Git Bash as administrator

### Error: "File not found" but path looks correct

**Possible causes:**
1. Path has hidden characters (copy-paste issue)
2. File extension is hidden in Windows
3. Path has trailing spaces
4. Case sensitivity (some tools are case-sensitive)

**Solution:**
1. Ask user to run `ls -la` in Git Bash to verify exact filename
2. Check for file extensions
3. Trim whitespace from path
4. Match exact case of filename

## 📚 Platform-Specific Knowledge

### Windows File System Characteristics

**Path characteristics:**
- Drive letters: A-Z (typically C: for system, D-Z for additional drives)
- Path separator: Backslash (`\`)
- Case insensitive: `File.txt` same as `file.txt`
- Special characters: Avoid `< > : " | ? *` in filenames
- Maximum path length: 260 characters (legacy limit, can be increased)

### Git Bash on Windows

**Git Bash is a POSIX-compatible environment:**
- Uses MINGW (Minimalist GNU for Windows)
- Translates POSIX paths to Windows paths internally
- Commands like `ls`, `pwd`, `cd` use POSIX format
- Native Windows programs need Windows format paths

**Key insight:** Git Bash displays and accepts POSIX paths, but Windows APIs (used by Claude Code) require Windows paths.

### WSL (Windows Subsystem for Linux)

**WSL path mounting:**
- Windows drives mounted at `/mnt/c/`, `/mnt/d/`, etc.
- WSL path: `/mnt/c/Users/name/project`
- Windows path: `C:\Users\name\project`

**Conversion:**
1. Replace `/mnt/x/` with `X:`
2. Replace forward slashes with backslashes

## 🎓 Teaching Users

When explaining path issues to users, use this template:

```bash
I encountered a path format issue. Here's what happened:

**The Problem:**
Claude Code's file tools (Edit, Write, Read) on Windows require paths in Windows
native format with backslashes (\), but Git Bash displays paths in POSIX format
with forward slashes (/).

**The Path Formats:**
- Git Bash shows: /s/repos/project/file.tsx
- Windows needs: S:\repos\project\file.tsx

**The Solution:**
I've converted your path to Windows format. For future reference, when working
with Claude Code on Windows with Git Bash:
1. Use backslashes (\) in file paths
2. Use drive letter format (C:, D:, S:) not MINGW format (/c/, /d/, /s/)
3. Run `pwd -W` in Git Bash to get Windows-formatted paths

**The Fix:**
✅ Now using: S:\repos\project\file.tsx
```

## 🔍 Advanced Scenarios

### Scenario 1: Mixed Path Contexts

**User is working with both WSL and Git Bash:**
- Ask which environment they're in
- Use appropriate conversion
- Document the choice

### Scenario 2: Symbolic Links

**Windows symbolic links:**
```text
mklink /D C:\link C:\target
```

**Handling:**
- Follow the link to actual path
- Use actual path in tool calls
- Inform user if link resolution needed

### Scenario 3: Docker Volumes

**Docker volume mounts on Windows:**
```bash
docker run -v C:\repos:/app
```

**Path translation:**
- Outside container: `C:\repos\file.txt`
- Inside container: `/app/file.txt`
- Use context-appropriate format

