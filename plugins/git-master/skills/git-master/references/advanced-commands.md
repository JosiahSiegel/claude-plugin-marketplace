# Advanced Git Commands

Stash, revert, reflog, bisect, clean, worktrees, and submodules.

## Stash

```bash
# Stash changes
git stash
git stash save "message"
git stash push -m "message"

# Stash including untracked files
git stash -u
git stash --include-untracked

# Stash including ignored files
git stash -a
git stash --all

# List stashes
git stash list

# Show stash contents
git stash show
git stash show -p  # With diff
git stash show stash@{2}

# Apply stash (keep in stash list)
git stash apply
git stash apply stash@{2}

# Pop stash (apply and remove)
git stash pop
git stash pop stash@{2}

# Drop stash
git stash drop
git stash drop stash@{2}

# Clear all stashes
git stash clear

# Create branch from stash
git stash branch <branch-name>
git stash branch <branch-name> stash@{1}
```

### Git 2.51+: Import/Export Stashes

Share stashes between machines:

```bash
# Export stash to a file
git stash store --file=stash.patch stash@{0}

# Import stash from a file
git stash import --file=stash.patch

# Share stashes like branches/tags
git stash export > my-stash.patch
git stash import < my-stash.patch
```

## Revert

```bash
# Revert commit (creates new commit that undoes changes)
# Safer than reset for shared branches
git revert <commit>

# Revert without creating commit
git revert -n <commit>
git revert --no-commit <commit>

# Revert merge commit
git revert -m 1 <merge-commit>  # Keep first parent
git revert -m 2 <merge-commit>  # Keep second parent

# Revert multiple commits
git revert <commit1> <commit2>
git revert <commit1>..<commit5>

# Continue after resolving conflicts
git revert --continue

# Abort revert
git revert --abort
```

## Reflog (Recovery)

**reflog is your safety net - it tracks all HEAD movements for 90 days (default).**

```bash
# View reflog
git reflog
git reflog show
git reflog show <branch>

# More detailed reflog
git log -g          # Reflog as log
git log -g --all

# Find lost commits
git reflog --all
git fsck --lost-found

# Recover deleted branch
git reflog  # Find commit where branch existed
git branch <branch-name> <commit-hash>

# Recover from hard reset
git reflog  # Find commit before reset
git reset --hard <commit-hash>

# Recover deleted commits
git cherry-pick <commit-hash>

# Reflog expiration (change retention)
git config gc.reflogExpire "90 days"
git config gc.reflogExpireUnreachable "30 days"
```

## Bisect (Find Bad Commits)

```bash
# Start bisect
git bisect start

# Mark current commit as bad
git bisect bad

# Mark known good commit
git bisect good <commit>

# Test each commit, then mark as good or bad
git bisect good   # Current commit is good
git bisect bad    # Current commit is bad

# Automate with test script
git bisect run <test-script>

# Bisect shows the first bad commit

# Finish bisect
git bisect reset

# Skip commit if unable to test
git bisect skip
```

## Clean

**WARNING: clean permanently deletes untracked files.**

```bash
# Show what would be deleted (dry run - ALWAYS do this first!)
git clean -n
git clean --dry-run

# Delete untracked files
git clean -f

# Delete untracked files and directories
git clean -fd

# Delete untracked and ignored files
git clean -fdx

# Interactive clean
git clean -i
```

## Worktrees

```bash
# List worktrees
git worktree list

# Add new worktree
git worktree add <path> <branch>
git worktree add ../project-feature feature-branch

# Add worktree for new branch
git worktree add -b <new-branch> <path>

# Remove worktree
git worktree remove <path>

# Prune stale worktrees
git worktree prune
```

## Submodules

```bash
# Add submodule
git submodule add <url> <path>

# Initialize submodules (after clone)
git submodule init
git submodule update

# Clone with submodules
git clone --recurse-submodules <url>

# Update submodules
git submodule update --remote
git submodule update --init --recursive

# Execute command in all submodules
git submodule foreach <command>
git submodule foreach git pull origin main

# Remove submodule
git submodule deinit <path>
git rm <path>
rm -rf .git/modules/<path>
```

## Tags and Releases

### Creating Tags

```bash
# Lightweight tag
git tag <tag-name>
git tag v1.0.0

# Annotated tag (recommended - includes metadata)
git tag -a <tag-name> -m "message"
git tag -a v1.0.0 -m "Release version 1.0.0"

# Tag specific commit
git tag -a <tag-name> <commit>

# Signed tag (GPG signature)
git tag -s <tag-name> -m "message"
```

### Managing Tags

```bash
# List tags
git tag
git tag -l "v1.*"  # Pattern matching

# Show tag info
git show <tag-name>

# Delete local tag
git tag -d <tag-name>

# Delete remote tag
git push origin --delete <tag-name>
git push origin :refs/tags/<tag-name>

# Push tags
git push origin <tag-name>
git push --tags          # All tags
git push --follow-tags   # Only annotated tags
```
