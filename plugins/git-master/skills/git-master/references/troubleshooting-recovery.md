# Git Troubleshooting and Recovery

Reference for common problems, recovery scenarios, and emergency procedures.

## Common Problems

### Detached HEAD

```bash
# You're in detached HEAD state
git branch temp  # Create branch at current commit
git switch main
git merge temp
git branch -d temp
```

### Merge Conflicts

```bash
# During merge/rebase
git status  # See conflicted files
# Edit files to resolve conflicts
git add <resolved-files>
git merge --continue  # or git rebase --continue

# Abort and start over
git merge --abort
git rebase --abort
```

### Accidentally Deleted Branch

```bash
# Find branch in reflog
git reflog
# Create branch at commit
git branch <branch-name> <commit-hash>
```

### Committed to Wrong Branch

```bash
# Move commit to correct branch
git switch correct-branch
git cherry-pick <commit>
git switch wrong-branch
git reset --hard HEAD~1  # Remove from wrong branch
```

### Pushed Sensitive Data

```bash
# URGENT: Remove from history immediately
git filter-repo --path <sensitive-file> --invert-paths
git push --force --all
# Then: Rotate compromised credentials immediately!
```

### Large Commit by Mistake

```bash
# Before pushing
git reset --soft HEAD~1
git reset HEAD <large-file>
git commit -m "message"

# After pushing - use filter-repo or BFG
```

## Recovery Scenarios

### Recover After Hard Reset

```bash
git reflog
git reset --hard <commit-before-reset>
```

### Recover Deleted File

```bash
git log --all --full-history -- <file>
git checkout <commit>^ -- <file>
```

### Recover Deleted Commits

```bash
git reflog  # Find commit hash
git cherry-pick <commit>
# or
git merge <commit>
# or
git reset --hard <commit>
```

### Recover from Corrupted Repository

```bash
# Verify corruption
git fsck --full

# Attempt repair
git gc --aggressive

# Last resort: clone from remote
```

## Emergency Recovery Reference

Quick recovery commands at-a-glance:

```bash
# Undo last commit (keep changes)
git reset --soft HEAD~1

# Undo changes to file
git checkout -- <file>

# Recover deleted branch
git reflog
git branch <name> <commit>

# Undo force push (if recent)
git reflog
git reset --hard <commit-before-push>
git push --force-with-lease

# Recover from hard reset
git reflog
git reset --hard <commit-before-reset>

# Find lost commits
git fsck --lost-found
git reflog --all

# Recover deleted file
git log --all --full-history -- <file>
git checkout <commit>^ -- <file>
```
