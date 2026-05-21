---
description: Interactively fix Windows file path issues and convert paths from Git Bash MINGW format to Windows format
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

# Windows Path Fix Command

## Purpose

This command provides interactive assistance for fixing Windows file path issues in Claude Code, especially when working with Git Bash. It helps detect and convert paths from MINGW/POSIX format to Windows-native format required by Claude Code's file operation tools.

## When to Use This Command

**PROACTIVELY use this command when:**
1. A file operation (Edit/Write/Read) fails with "file not found" or "ENOENT" error on Windows
2. User is working on Windows with Git Bash
3. User provides a path that looks like MINGW format (e.g., `/s/repos/`, `/c/Users/`)
4. User reports file path issues on Windows
5. You need to verify a path format before using Edit/Write/Read tools
6. User asks how to format paths for Claude Code on Windows

## Instructions

### Step 1: Identify the Problem

**Check for these indicators:**
- User is on Windows (check environment or user mentions it)
- Path starts with `/` followed by single letter (e.g., `/s/`, `/c/`, `/d/`)
- Path uses forward slashes instead of backslashes
- Recent Edit/Write/Read tool failure with path-related error

### Step 2: Gather Path Information

**Ask the user (if path is not already provided):**

```bash
I can help fix the file path format for Windows. Could you provide the file path you're trying to access?

If you're in Git Bash, you can get the full path by running:
  pwd -W
or for a specific file:
  realpath filename.txt
```

### Step 3: Analyze the Path Format

**Determine the path type:**

**MINGW Path (Git Bash format):**
- Pattern: `/x/path/to/file` where `x` is a single letter
- Example: `/s/repos/project/file.tsx`
- Example: `/c/Users/name/Documents/file.txt`
- **Action:** Convert to Windows format

**Windows Path with Forward Slashes:**
- Pattern: `X:/path/to/file` where `X` is drive letter
- Example: `S:/repos/project/file.tsx`
- **Action:** Replace forward slashes with backslashes

**Windows Path (Correct):**
- Pattern: `X:\path\to\file` where `X` is drive letter
- Example: `S:\repos\project\file.tsx`
- **Action:** No conversion needed

**Relative Path:**
- Pattern: `./path/to/file` or `../path/to/file`
- Example: `./src/components/Button.tsx`
- **Action:** Request full path or current directory

**WSL Path:**
- Pattern: `/mnt/x/path/to/file` where `x` is drive letter
- Example: `/mnt/c/repos/project/file.tsx`
- **Action:** Convert to Windows format

### Step 4: Convert the Path

**Use the appropriate conversion algorithm:**

**For MINGW paths (`/x/...`):**
```text
Input:  /s/repos/myproject/file.tsx

Step 1: Extract drive letter from first segment → "s"
Step 2: Uppercase the drive letter → "S"
Step 3: Add colon → "S:"
Step 4: Replace remaining forward slashes with backslashes → \repos\myproject\file.tsx
Step 5: Combine → S:\repos\myproject\file.tsx

Output: S:\repos\myproject\file.tsx
```

**For Windows paths with forward slashes (`X:/...`):**
```text
Input:  S:/repos/project/file.tsx

Step 1: Drive letter already present → "S:"
Step 2: Replace all forward slashes with backslashes → \repos\project\file.tsx
Step 3: Combine → S:\repos\project\file.tsx

Output: S:\repos\project\file.tsx
```

**For relative paths:**
```text
Input:  ./src/components/Button.tsx
Current directory (ask user for `pwd -W` output): S:/repos/my-project

Step 1: Get current directory in Windows format → S:\repos\my-project
Step 2: Remove ./ prefix from relative path → src/components/Button.tsx
Step 3: Replace forward slashes with backslashes → src\components\Button.tsx
Step 4: Combine → S:\repos\my-project\src\components\Button.tsx

Output: S:\repos\my-project\src\components\Button.tsx
```

**For WSL paths (`/mnt/x/...`):**
```text
Input:  /mnt/c/Users/name/project/file.tsx

Step 1: Extract drive letter after /mnt/ → "c"
Step 2: Uppercase → "C"
Step 3: Add colon → "C:"
Step 4: Remove /mnt/c/ prefix → Users/name/project/file.tsx
Step 5: Replace forward slashes with backslashes → Users\name\project\file.tsx
Step 6: Combine → C:\Users\name\project\file.tsx

Output: C:\Users\name\project\file.tsx
```

### Step 5: Present the Conversion

**Show the conversion clearly:**

```text
✅ Path Conversion Complete

**Original Path (Git Bash/MINGW format):**
/s/repos/myproject/src/components/Button.tsx

**Converted Path (Windows format for Claude Code):**
S:\repos\myproject\src\components\Button.tsx

**What Changed:**
- Converted /s/ → S:
- Replaced forward slashes (/) with backslashes (\)
- Now compatible with Claude Code's Edit/Write/Read tools
```

### Step 6: Verify and Retry

**If the original operation failed, retry with the converted path:**

```text
I'll now retry the [Edit/Write/Read] operation with the correct Windows path format...
```

Then execute the intended file operation using the converted path.

### Step 7: Educate the User

**Explain why the conversion was necessary:**

```bash
📚 Why This Matters:

**Git Bash displays paths in POSIX/MINGW format** (e.g., /s/repos/file.tsx), but
**Claude Code's file tools require Windows native format** (e.g., S:\repos\file.tsx).

**Key Points:**
1. Always use backslashes (\) in file paths for Claude Code on Windows
2. Use drive letter format (C:, D:, S:) not MINGW format (/c/, /d/, /s/)
3. Run `pwd -W` in Git Bash to get Windows-formatted paths

**This conversion is automatic when you use the /path-fix command!**
```

### Step 8: Prevent Automatic Path Conversion (Advanced)

**For command-line operations that need POSIX paths:**

When running commands in Git Bash that interact with tools expecting Unix-style paths (like Docker, WSL tools, or certain CLIs), Git Bash may automatically convert paths, which can cause issues.

**Use MSYS_NO_PATHCONV=1 to disable automatic conversion:**

```bash
# Problem: Git Bash converts /app to C:/Program Files/Git/app
docker run -v /app:/app myimage

# Solution: Disable path conversion for this command
MSYS_NO_PATHCONV=1 docker run -v /app:/app myimage
```

**Common scenarios where MSYS_NO_PATHCONV=1 is needed:**

1. **Docker volume mounts:**
   ```bash
   # ✅ Correct
   MSYS_NO_PATHCONV=1 docker run -v /app:/app nginx

   # ❌ Wrong - Git Bash converts /app to C:/Program Files/Git/app
   docker run -v /app:/app nginx
   ```

2. **Docker exec commands:**
   ```bash
   MSYS_NO_PATHCONV=1 docker exec container ls /app
   ```

3. **Azure CLI with paths:**
   ```bash
   MSYS_NO_PATHCONV=1 az storage blob upload --file /path/to/file
   ```

4. **Terraform with module sources:**
   ```bash
   MSYS_NO_PATHCONV=1 terraform init
   ```

**When to recommend MSYS_NO_PATHCONV=1:**
- User reports Docker commands failing with weird paths
- Commands expecting Unix paths get Windows paths instead
- Azure CLI, AWS CLI, or other cloud tools show path errors
- Terraform or other IaC tools fail with path conversion issues

**Example explanation for users:**
```bash
💡 Pro Tip for Git Bash Users:

Git Bash automatically converts Unix-style paths to Windows paths, which can
break Docker and other tools. Use MSYS_NO_PATHCONV=1 to prevent this:

MSYS_NO_PATHCONV=1 docker run -v /app:/app myimage

Or set it globally for your Git Bash session:
export MSYS_NO_PATHCONV=1
```

## Common Scenarios

### Scenario 1: User Reports "File Not Found" Error

**User:** "I'm trying to edit a file but getting 'file not found' error"

**Response:**
```bash
I can help fix that! This is likely a path format issue on Windows.

Could you share the file path you're trying to access? If you're using Git Bash,
run this command to get the Windows-formatted path:

pwd -W

Then share the full path to the file you want to edit.
```

**After receiving path `/s/repos/project/file.tsx`:**
```yaml
I see the issue - this is Git Bash MINGW format. I'll convert it to Windows format:

Original:  /s/repos/project/file.tsx
Converted: S:\repos\project\file.tsx

Now retrying the edit operation with the correct Windows path...
```

### Scenario 2: Proactive Path Conversion

**User:** "Please edit /c/Users/john/Documents/notes.txt"

**Response (proactive conversion):**
```text
I notice you're using Git Bash path format. I'll convert this to Windows format
for Claude Code's Edit tool:

Git Bash format:  /c/Users/john/Documents/notes.txt
Windows format:   C:\Users\john\Documents\notes.txt

Editing the file now...
```

### Scenario 3: Relative Path Resolution

**User:** "Edit the file ./src/components/Button.tsx"

**Response:**
```bash
To work with this relative path on Windows, I need the full Windows path.

Could you run this command in Git Bash and share the output?

pwd -W

This will give me your current directory in Windows format, so I can construct
the full path.
```

**After receiving `S:/repos/my-project`:**
```text
Got it! Here's the conversion:

Current directory: S:\repos\my-project
Relative path: ./src/components/Button.tsx
Full Windows path: S:\repos\my-project\src\components\Button.tsx

Editing the file now...
```

### Scenario 4: Multiple Paths Need Conversion

**User:** "Edit these files: /s/repos/file1.ts, /s/repos/file2.ts, /s/repos/file3.ts"

**Response:**
```text
I'll convert all three paths from Git Bash to Windows format:

1. /s/repos/file1.ts → S:\repos\file1.ts
2. /s/repos/file2.ts → S:\repos\file2.ts
3. /s/repos/file3.ts → S:\repos\file3.ts

Editing all three files with the correct Windows paths...
```

## Validation Steps

**Before using a converted path, verify:**

- [ ] Path starts with uppercase drive letter and colon (e.g., `C:`, `S:`)
- [ ] Path uses backslashes (`\`) not forward slashes (`/`)
- [ ] Path is absolute (starts with drive letter), not relative
- [ ] No MINGW format indicators (`/c/`, `/s/`, `/mnt/`)
- [ ] No environment variables unexpanded (`$HOME`, `%USERPROFILE%`)
- [ ] No trailing spaces or hidden characters

## Error Handling

**If path conversion still results in errors:**

### Error: File still not found after conversion

**Possible causes:**
1. File doesn't actually exist at that path
2. Path has typos
3. File extension is missing or incorrect
4. Case sensitivity issue (rare on Windows but possible)

**Actions:**
```bash
The converted path appears correct, but the file might not exist. Let's verify:

Could you run this command in Git Bash to check if the file exists?

ls -la [path to file]

This will show if the file exists and its exact name (including extension).
```

### Error: Access denied or permission error

**Possible causes:**
1. File is locked by another process
2. User doesn't have read/write permissions
3. File is in a protected directory

**Actions:**
```text
The path format is correct, but there's a permission issue.

Could you check:
1. Is the file currently open in another program?
2. Do you have read/write permissions for this file?
3. Try running Git Bash as Administrator if needed
```

## Quick Reference

### Path Conversion Patterns

| Input Format | Output Format | Example |
|--------------|---------------|---------|
| `/s/repos/file.txt` | `S:\repos\file.txt` | MINGW → Windows |
| `S:/repos/file.txt` | `S:\repos\file.txt` | Windows with `/` → Windows with `\` |
| `/mnt/c/Users/file.txt` | `C:\Users\file.txt` | WSL → Windows |
| `./src/file.txt` | `[CWD]\src\file.txt` | Relative → Absolute |
| `/c/Program Files/app/file.txt` | `C:\Program Files\app\file.txt` | MINGW with spaces → Windows |

### Git Bash Commands for Path Discovery

```bash
# Get current directory in Windows format
pwd -W

# Get absolute path of a file in Windows format
realpath -W filename.txt

# List files with full details
ls -la

# Show file with full path
readlink -f filename.txt
```

## Success Criteria

The command is successful when:

1. ✅ Path is correctly identified as MINGW, WSL, or Windows format
2. ✅ Conversion algorithm produces valid Windows path
3. ✅ Converted path uses backslashes throughout
4. ✅ File operation succeeds with converted path
5. ✅ User understands why conversion was necessary
6. ✅ User knows how to provide Windows-formatted paths in future

## Related Commands

- **Windows Path Troubleshooting Skill**: Comprehensive path format knowledge
- **Windows Path Expert Agent**: For complex path issues and debugging
- **File operations**: Edit, Write, Read tools that require proper Windows paths

## Best Practices

1. **Proactive Detection**: Don't wait for errors - convert paths immediately when you see MINGW format
2. **Clear Communication**: Always show both original and converted paths
3. **User Education**: Explain why conversion is needed
4. **Validation**: Verify path format before using file tools
5. **Helpful Guidance**: Provide `pwd -W` command for users to get Windows paths themselves
