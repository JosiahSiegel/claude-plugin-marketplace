# Git Master Plugin

Complete Git expertise system for ALL Git operations - from basic to advanced, including dangerous operations with comprehensive safety guardrails.

## 🎯 What This Plugin Does

When installed, Claude becomes a complete Git expert with:

- **Comprehensive Git Knowledge** - Every command, option, and workflow
- **Safety Guardrails** - Warnings and confirmations for destructive operations
- **Platform Expertise** - Windows, Linux, macOS, GitHub, Azure DevOps, Bitbucket
- **Workflow Strategies** - Git Flow, GitHub Flow, trunk-based development
- **Advanced Operations** - Rebase, cherry-pick, filter-repo, history rewriting
- **Recovery Expertise** - Reflog, fsck, recovering from any mistake
- **User Control** - Always asks about automatic commits vs manual control

## 📦 Installation

### Via GitHub Marketplace (Recommended)

```bash
/plugin marketplace add JosiahSiegel/claude-code-marketplace
/plugin install git-master@claude-plugin-marketplace
```

### Local Installation (Mac/Linux)

⚠️ **Windows users:** Use the GitHub marketplace method instead.

```bash
# Extract to plugins directory
unzip git-master.zip -d ~/.local/share/claude/plugins/
```

## 🚀 Features

### 1. Complete Git Command Reference

Covers every Git command from basic to advanced:

- **Basic Operations**: init, clone, add, commit, push, pull, status, log, diff
- **Branching**: branch, switch, checkout, merge strategies
- **Advanced**: rebase (interactive & non-interactive), cherry-pick, reflog
- **Dangerous**: reset --hard, force push, filter-repo, history rewriting
- **Recovery**: reflog recovery, fsck, lost commit recovery
- **Maintenance**: gc, prune, repack, optimization
- **Collaboration**: Pull requests, merge requests, code review workflows

### 2. Safety Guardrails

**Every dangerous operation includes:**

- ⚠️ Explicit warnings about risks
- 🔒 Confirmation prompts before execution
- 💾 Automatic backup branch creation
- 🔄 Recovery instructions if something goes wrong
- 📋 Pre-flight checklists for critical operations

**Example safety protocol for `git reset --hard`:**

```
⚠️  WARNING: This operation is DESTRUCTIVE and will:
   - Permanently delete uncommitted changes
   - Cannot be undone (except via reflog)

Safety recommendation: Creating backup branch first...
✓ Created: backup-before-reset-20251023-143022

To recover if needed: git reset --hard backup-before-reset-20251023-143022

Are you SURE you want to proceed? (yes/NO): _
```

### 3. User Preference Management

**First question on any Git task:**

```
Would you like me to:
1. Create commits automatically with appropriate messages
2. Stage changes only (you handle commits manually)
3. Just provide guidance (no automatic operations)

Your choice: _
```

Claude respects your choice throughout the session.

### 4. Platform-Specific Expertise

**Windows (Git Bash/PowerShell):**
- Line ending configuration (CRLF vs LF)
- Windows Credential Manager integration
- Git Bash/MINGW path conversion handling
- Path separator handling
- Case sensitivity considerations
- Shell detection ($MSYSTEM, uname -s)

**Git Bash Path Conversion (Critical for Windows):**
Git Bash automatically converts Unix-style paths, which can affect Git operations:
- Provides MSYS_NO_PATHCONV environment variable control
- Includes cygpath conversion utilities
- Offers workarounds for common path issues
- Documents path quoting requirements
- Explains shell detection patterns

**Linux/macOS:**
- SSH key management
- Permission handling
- Shell-specific configurations
- Package manager integration

**Cloud Platforms:**
- **GitHub**: PR workflows, GitHub Actions, GitHub CLI (`gh`)
- **Azure DevOps**: Azure Repos, Azure Pipelines, branch policies
- **Bitbucket**: Bitbucket Pipelines, Jira integration
- **GitLab**: GitLab CI/CD, merge request workflows

### 5. Comprehensive Slash Commands

#### `/git-master:git-cleanup`
Clean up repository safely:
- Remove merged branches
- Prune remote-tracking branches
- Run garbage collection
- Optimize repository size

#### `/git-master:git-safe-rebase`
Interactive rebase with safety:
- Automatic backup branch creation
- Shared branch detection
- Step-by-step guidance
- Recovery instructions

#### `/git-master:git-recover`
Recover from Git mistakes:
- Find lost commits via reflog
- Recover deleted branches
- Restore deleted files
- Undo accidental force push
- Repair corrupted repository

#### `/git-master:git-history-rewrite`
**⚠️ EXTREMELY DANGEROUS** - History rewriting with maximum safety:
- Comprehensive pre-flight checks
- Full repository backup
- Team coordination verification
- Remove sensitive files
- Remove large files
- Change author information
- Complete rollback procedures

### 6. Workflow Strategies

**Git Flow:**
```
main/master (production)
  ├── develop (integration)
  │   ├── feature/user-auth
  │   ├── feature/api-integration
  │   └── feature/ui-redesign
  ├── release/v1.2.0
  └── hotfix/security-patch
```

**GitHub Flow:**
```
main (always deployable)
  ├── feature/add-search
  ├── fix/header-bug
  └── docs/update-readme
```

**Trunk-Based Development:**
```
main (single source of truth)
  ├── short-lived-feature-1 (< 1 day)
  └── short-lived-feature-2 (< 1 day)
```

## 💡 Usage Examples

### Example 1: Safe Force Push

```
User: "I need to force push my changes"

Claude: "⚠️ Force push is a dangerous operation. Let me help you do this safely.

First, let me check the current state:
[runs: git status, git log, git fetch]

I can see that the remote has commits that will be overwritten:
- abc1234 Fix typo (by teammate@example.com)
- def5678 Update docs (by teammate@example.com)

These commits from your teammates will be LOST if you force push.

Options:
1. Pull and merge their changes first (recommended)
2. Pull and rebase on their changes
3. Proceed with force push anyway (⚠️ DANGER)

What would you like to do?"
```

### Example 2: Recover Deleted Branch

```
User: "I accidentally deleted my feature branch!"

Claude: "Don't worry, we can recover it using reflog. Let me find it:
[runs: git reflog --all | grep feature-branch]

Found it! Your branch 'feature/new-api' was at commit a1b2c3d.

To recover:
git branch feature/new-api a1b2c3d

Would you like me to run this command? (yes/no)"
```

### Example 3: Interactive Rebase

```
User: "Help me squash my last 5 commits"

Claude: "I'll help you perform an interactive rebase to squash commits.

Safety first - creating backup branch:
✓ Created: backup-before-rebase-20251023-143500

Current commits to be rebased:
a1b2c3d Fix typo
b2c3d4e Add tests
c3d4e5f Implement feature
d4e5f6g Update docs
e5f6g7h Initial commit

Starting interactive rebase:
[runs: git rebase -i HEAD~5]

In the editor, I'll help you mark commits:
- Keep e5f6g7h (pick)
- Squash d4e5f6g (squash into e5f6g7h)
- Squash c3d4e5f (squash into e5f6g7h)
- Squash b2c3d4e (squash into e5f6g7h)
- Squash a1b2c3d (squash into e5f6g7h)

This will combine all 5 commits into one.

If anything goes wrong:
- Abort: git rebase --abort
- Recover: git reset --hard backup-before-rebase-20251023-143500

Proceed? (yes/no)"
```

### Example 4: Remove Sensitive File

```
User: "I accidentally committed my .env file with secrets!"

Claude: "⚠️⚠️⚠️ CRITICAL SECURITY ISSUE ⚠️⚠️⚠️

If this has been pushed to a remote, your secrets are compromised.

IMMEDIATE ACTIONS REQUIRED:
1. Rotate ALL credentials in that .env file NOW
2. Remove file from Git history
3. Add .env to .gitignore

Has this been pushed to a remote repository? (yes/no)"

User: "yes"

Claude: "⚠️ URGENT:
1. ROTATE CREDENTIALS IMMEDIATELY (do this first!)
2. Then we'll remove from history

Are credentials rotated? (yes/no)"

User: "yes"

Claude: "Good. Now removing from history with git-filter-repo:

⚠️ This will rewrite ALL repository history!

Safety steps:
1. Creating full backup: ✓
2. Removing .env from all commits
3. Will require force push
4. ALL team members must re-clone

Proceeding:
[runs: git filter-repo --path .env --invert-paths]

✓ File removed from all history
✓ Adding .env to .gitignore

Next steps:
1. Review changes: git log --oneline -20
2. Force push: git push --force --all
3. Notify team to re-clone repository

Note: Old commits still exist on remote until garbage collection.
Anyone who cloned before force push still has the secrets.
Keep those credentials rotated!"
```

## 🛡️ Safety Features

### 1. Pre-Execution Warnings

Every risky command gets a warning:

```
⚠️  WARNING: git reset --hard is DESTRUCTIVE
⚠️  DANGER: git push --force will overwrite remote history
⚠️⚠️⚠️  EXTREME DANGER: git filter-repo rewrites ALL history
```

### 2. Automatic Backups

Before destructive operations:

```bash
# Backup branch created automatically
git branch backup-before-reset-20251023-143022

# Recovery instructions provided
"To undo: git reset --hard backup-before-reset-20251023-143022"
```

### 3. Confirmation Prompts

Dangerous operations require explicit confirmation:

```
Are you SURE you want to proceed? (yes/NO): _
Type 'force push' to confirm: _
Type 'I UNDERSTAND THE RISKS' to continue: _
```

### 4. Dry-Run First

Show what will happen before doing it:

```bash
# Before cleaning
git clean -n  # Show what would be deleted

# Before filter-repo
git filter-repo --analyze  # Analyze repository first
```

## 📚 Knowledge Areas

### Basic Git
- Repository initialization and cloning
- Staging and committing
- Viewing history and changes
- Branch creation and switching
- Basic merging

### Intermediate Git
- Merge strategies
- Conflict resolution
- Remote operations
- Stashing
- Tagging
- .gitignore

### Advanced Git
- Interactive rebase
- Cherry-picking
- Reflog
- Bisect
- Worktrees
- Submodules
- Hooks

### Expert Git
- Filter-repo
- History rewriting
- Repository recovery
- Performance optimization
- Custom merge strategies
- Low-level plumbing commands

### Platform Integration
- GitHub Pull Requests and Actions
- Azure DevOps Repos and Pipelines
- Bitbucket Pipelines
- GitLab CI/CD
- Platform-specific CLI tools

## 🎓 What Claude Learns

### Git Workflows

- **Git Flow**: Feature, develop, release, hotfix branches
- **GitHub Flow**: Main branch with PRs
- **GitLab Flow**: Environment branches
- **Trunk-Based**: Short-lived feature branches

### Best Practices

- Commit message conventions
- Branch naming strategies
- Code review workflows
- CI/CD integration
- Security practices

### Recovery Techniques

- Reflog navigation
- Lost commit recovery
- Branch restoration
- File recovery
- Corruption repair

### Platform Specifics

- Line ending handling (CRLF vs LF)
- Case sensitivity differences
- Credential management
- SSH vs HTTPS
- Platform-specific features

## 🔍 Quality Assurance

Every Git operation Claude performs:

- ✅ Checks current state first
- ✅ Warns about risks
- ✅ Creates backups when needed
- ✅ Asks for confirmation
- ✅ Provides recovery instructions
- ✅ Verifies success after execution
- ✅ Respects user's preference for automation

## 🌐 Platform Support

- **Windows** - Git Bash (MINGW/MSYS2), PowerShell, Windows Credential Manager
  - Git Bash path conversion handling (MSYS_NO_PATHCONV, cygpath)
  - Shell detection ($MSYSTEM for MINGW64/MINGW32/MSYS)
  - Cross-platform path compatibility
- **Linux** - All distributions, SSH, GPG signing
- **macOS** - Keychain integration, BSD vs GNU differences
- **GitHub** - CLI, Actions, PRs
- **Azure DevOps** - Azure CLI, Pipelines, Repos
- **Bitbucket** - Bitbucket CLI, Pipelines
- **GitLab** - GitLab CLI, CI/CD, MRs

## 📖 Example Workflows

### Workflow 1: Feature Branch

```bash
# Create feature branch
git switch -c feature/user-authentication

# Make changes
git add src/auth/
git commit -m "feat(auth): add OAuth2 authentication"

# Keep updated with main
git fetch origin
git rebase origin/main

# Push and create PR
git push -u origin feature/user-authentication
gh pr create --title "Add OAuth2 authentication"
```

### Workflow 2: Hotfix

```bash
# Create hotfix from production
git switch -c hotfix/security-patch main

# Make fix
git add src/security/
git commit -m "fix(security): patch XSS vulnerability"

# Merge to main
git switch main
git merge --no-ff hotfix/security-patch
git tag -a v1.2.1 -m "Security patch"
git push --follow-tags

# Merge to develop
git switch develop
git merge --no-ff hotfix/security-patch
git push
```

### Workflow 3: Squash Commits Before Merge

```bash
# Interactive rebase to squash
git rebase -i origin/main

# In editor: squash all commits into one
# Then force push
git push --force-with-lease
```

## 🤝 Contributing

This plugin is part of the claude-code-marketplace. Contributions welcome!

## 📄 License

MIT License - Feel free to use, modify, and distribute.

## 🔗 Resources

- [Git Documentation](https://git-scm.com/doc)
- [Pro Git Book](https://git-scm.com/book/en/v2)
- [GitHub Guides](https://guides.github.com/)
- [Atlassian Git Tutorials](https://www.atlassian.com/git/tutorials)

## 🎯 Next Steps

1. Install the plugin
2. Try: `/git-master:git-cleanup` to clean your repository
3. Ask Claude any Git question - from basic to advanced
4. Watch Claude apply safety best practices automatically

---

**Made with ❤️ for the Claude Code community**

Master Git with confidence and safety!
