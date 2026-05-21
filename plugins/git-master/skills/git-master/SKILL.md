---
name: git-master
description: |
  Complete Git expertise system for ALL git operations.
  PROACTIVELY activate for: (1) ANY Git task (basic/advanced/dangerous), (2) Repository management, (3) Branch strategies and workflows, (4) Conflict resolution, (5) History rewriting/recovery, (6) Platform-specific operations (GitHub/Azure DevOps/Bitbucket), (7) Advanced commands (rebase/cherry-pick/filter-repo).
  Provides: complete Git command reference, safety guardrails for destructive operations, platform best practices, workflow strategies, reflog recovery techniques, and expert guidance for even the most risky operations.
  Always asks user preference for automatic commits vs manual control.
---

# Git Mastery - Complete Git Expertise

Comprehensive Git skill covering basic to advanced operations, with mandatory safety guardrails for destructive commands and platform-specific workflows.

## Critical Guidelines

### Windows File Path Requirements

When using Edit or Write tools on Windows, use backslashes (`\`) in file paths, NOT forward slashes (`/`):

- WRONG: `D:/repos/project/file.tsx`
- CORRECT: `D:\repos\project\file.tsx`

Applies to: Edit/Write `file_path` parameters and all file operations.

### Documentation Guidelines

NEVER create new documentation files unless explicitly requested by the user. Prefer updating existing README.md files. Keep documentation concise, direct, and professional.

## TL;DR Safety First

Before ANY destructive operation:

```bash
# ALWAYS check status first
git status
git log --oneline -10

# For risky operations, create a safety branch
git branch backup-$(date +%Y%m%d-%H%M%S)

# Remember: git reflog is your safety net (90 days default)
git reflog
```

**User Preference Check (ALWAYS ASK at start of any Git task):**

"Would you like me to:
1. Create commits automatically with appropriate messages
2. Stage changes only (you handle commits manually)
3. Just provide guidance (no automatic operations)"

Respect this choice throughout the session.

## When to Use This Skill

Activate for ANY Git command or operation including:

- Repository initialization, cloning, configuration
- Branch management and strategies
- Commit workflows and best practices
- Merge strategies and conflict resolution
- Rebase operations (interactive and non-interactive)
- History rewriting (filter-repo, reset, revert)
- Recovery operations (reflog, fsck)
- Dangerous operations (force push, hard reset)
- Platform-specific workflows (GitHub, Azure DevOps, Bitbucket, GitLab)
- Advanced features (submodules, worktrees, hooks)
- Performance optimization, large files (LFS)
- Cross-platform compatibility (Windows/Linux/macOS)

**Key indicators:** user mentions Git, GitHub, GitLab, Bitbucket, Azure DevOps, version control, commit/push/pull/merge/rebase, branch management, history modification, or recovery scenarios.

## Core Principles

### 1. Safety Guardrails for Destructive Operations

Before ANY destructive operation (`reset --hard`, force push, `filter-repo`, etc.):

1. Always warn the user explicitly
2. Explain the risks clearly
3. Ask for confirmation
4. Suggest creating a backup branch first
5. Provide recovery instructions

See `references/dangerous-operations.md` for full safety protocols and confirmation scripts.

### 2. Commit Creation Policy

ALWAYS ask the user preference at the start of any Git task (automatic / stage-only / guidance-only). Respect this choice throughout.

### 3. Platform Awareness

Git behavior differs across platforms and hosting providers:

- **Windows (Git Bash/PowerShell):** Line endings (`core.autocrlf`), path separators, case sensitivity, Windows Credential Manager
- **Linux/macOS:** Case-sensitive filesystems, SSH key management, permissions
- **Hosting platforms:** GitHub (PRs, Actions, `gh` CLI), Azure DevOps (PRs, Pipelines, policies), Bitbucket (PRs, Pipelines, Jira), GitLab (MRs, CI/CD)

See `references/platform-workflows.md` for hosting-specific commands and `references/cross-platform.md` for Windows/Linux/macOS handling.

## Reference Map

This SKILL.md is a lean orchestrator. Detailed command catalogs and procedures live in `references/`:

| Reference | Contents |
|-----------|----------|
| `references/basic-operations.md` | Init, clone, config, basic workflow, branches, remotes, fetch/pull/push (non-destructive) |
| `references/merging-rebasing.md` | Merge strategies, conflict resolution, rebase (interactive/onto/autosquash), cherry-pick |
| `references/advanced-commands.md` | Stash (incl. Git 2.51+ import/export), revert, reflog, bisect, clean, worktrees, submodules, tags |
| `references/dangerous-operations.md` | Reset (hard/soft/mixed), force push, filter-repo, amend pushed commits, safety protocols |
| `references/platform-workflows.md` | GitHub, Azure DevOps, Bitbucket, GitLab CLIs and CI/CD templates |
| `references/performance-large-files.md` | GC, repack, fsck, LFS, shallow clones, large-file discovery |
| `references/hooks-and-security.md` | Client/server hooks, credential management, SSH, GPG, secret prevention, conventional commits |
| `references/troubleshooting-recovery.md` | Common problems, recovery scenarios, emergency commands |
| `references/cross-platform.md` | Line endings, case sensitivity, Git Bash/MINGW path conversion, shell detection |

## Quick Command Index

| Task | Reference |
|------|-----------|
| `git init`, `git clone`, `git add`, `git commit`, `git log`, `git diff` | basic-operations |
| `git branch`, `git switch`, `git remote`, `git fetch`, `git pull`, `git push` | basic-operations |
| `git merge`, conflict markers, `git rebase -i`, `git cherry-pick` | merging-rebasing |
| `git stash`, `git revert`, `git reflog`, `git bisect`, `git clean`, `git worktree`, `git submodule`, `git tag` | advanced-commands |
| `git reset --hard`, `git push --force[-with-lease]`, `git filter-repo`, amend pushed | dangerous-operations |
| `gh pr`, `az repos pr`, `bb pr`, `glab mr`, CI/CD YAML | platform-workflows |
| `git gc`, `git repack`, `git lfs`, shallow clone | performance-large-files |
| `.git/hooks/*`, conventional commits, SSH/GPG/secrets | hooks-and-security |
| Detached HEAD, recover branch/file/commit, corrupted repo | troubleshooting-recovery |
| `core.autocrlf`, `core.ignorecase`, `MSYS_NO_PATHCONV`, `cygpath`, `$MSYSTEM` | cross-platform |

## Success Criteria

A Git workflow using this skill should:

1. ALWAYS ask user preference for automatic commits vs manual
2. ALWAYS warn before destructive operations
3. ALWAYS create backup branches before risky operations
4. ALWAYS explain recovery procedures
5. Use appropriate branch strategy for the project
6. Write meaningful commit messages
7. Keep commit history clean and linear
8. Never commit secrets or large binary files
9. Test code before committing
10. Know how to recover from any mistake

## Closing Note

Combined with the reference files and safety guardrails, this skill provides the knowledge to handle ANY Git operation safely and effectively. Always load the appropriate reference before executing a category of commands.
