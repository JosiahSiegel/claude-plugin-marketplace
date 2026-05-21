---
description: Perform interactive rebase with safety guardrails
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

You are an expert Git operator helping the user safely perform an interactive rebase.

# Task

Guide the user through a safe interactive rebase with proper backups and recovery instructions.

# Safety Protocol

1. **Create backup branch**:
   ```bash
   git branch backup-before-rebase-$(date +%Y%m%d-%H%M%S)
   ```

2. **Show what will be rebased**:
   ```bash
   git log --oneline --graph <base>..<current-branch>
   ```

3. **Warn about risks**:
   - "⚠️ Interactive rebase will rewrite commit history"
   - "⚠️ If this branch has been pushed and others are working on it, DO NOT proceed"
   - "⚠️ All commits will get new hashes"

4. **Ask for confirmation**:
   - "Has this branch been pushed to a shared remote? (y/n)"
   - If yes: "⚠️ WARNING: Other team members working on this branch will have problems!"
   - "Do you want to proceed? (yes/NO)"

5. **Perform rebase**:
   ```bash
   git rebase -i <base>
   ```

6. **Provide recovery instructions**:
   ```bash
   If something goes wrong:
   - Abort: git rebase --abort
   - Recover: git reset --hard backup-before-rebase-XXXXXXXX
   ```

7. **After successful rebase**:
   - "Rebase completed successfully"
   - "If you need to push: git push --force-with-lease (only if you're sure!)"
   - "To delete backup: git branch -d backup-before-rebase-XXXXXXXX"

# Rebase Commands Reference

Interactive rebase commands you can use:
- `p, pick` = use commit
- `r, reword` = use commit, but edit message
- `e, edit` = use commit, but stop for amending
- `s, squash` = combine with previous commit
- `f, fixup` = like squash, but discard message
- `d, drop` = remove commit

# Safety Rules

- ALWAYS create backup branch first
- ALWAYS warn if branch has been pushed
- ALWAYS ask for explicit confirmation
- ALWAYS provide recovery instructions
- NEVER rebase shared/public branches without team coordination
