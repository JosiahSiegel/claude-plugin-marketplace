# Basic Git Operations

Reference for everyday Git commands: init, clone, configuration, workflow, and branches.

## Repository Initialization and Cloning

```bash
# Initialize new repository
git init
git init --initial-branch=main  # Specify default branch name

# Clone repository
git clone <url>
git clone <url> <directory>
git clone --depth 1 <url>  # Shallow clone (faster, less history)
git clone --branch <branch> <url>  # Clone specific branch
git clone --recurse-submodules <url>  # Include submodules
```

## Configuration

```bash
# User identity (required for commits)
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Default branch name
git config --global init.defaultBranch main

# Line ending handling (Windows)
git config --global core.autocrlf true  # Windows
git config --global core.autocrlf input  # macOS/Linux

# Editor
git config --global core.editor "code --wait"  # VS Code
git config --global core.editor "vim"

# Diff tool
git config --global diff.tool vscode
git config --global difftool.vscode.cmd 'code --wait --diff $LOCAL $REMOTE'

# Merge tool
git config --global merge.tool vscode
git config --global mergetool.vscode.cmd 'code --wait $MERGED'

# Aliases
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.unstage 'reset HEAD --'
git config --global alias.last 'log -1 HEAD'
git config --global alias.visual '!gitk'

# View configuration
git config --list
git config --global --list
git config --local --list
git config user.name  # Get specific value
```

## Basic Workflow

```bash
# Check status
git status
git status -s   # Short format
git status -sb  # Short with branch info

# Add files
git add <file>
git add .   # Add all changes in current directory
git add -A  # Add all changes in repository
git add -p  # Interactive staging (patch mode)

# Remove files
git rm <file>
git rm --cached <file>  # Remove from index, keep in working directory
git rm -r <directory>

# Move/rename files
git mv <old> <new>

# Commit
git commit -m "message"
git commit -am "message"           # Add and commit tracked files
git commit --amend                 # Amend last commit
git commit --amend --no-edit       # Amend without changing message
git commit --allow-empty -m "msg"  # Empty commit (useful for triggers)

# View history
git log
git log --oneline
git log --graph --oneline --all --decorate
git log --stat        # Show file statistics
git log --patch       # Show diffs
git log -p -2         # Show last 2 commits with diffs
git log --since="2 weeks ago"
git log --until="2025-01-01"
git log --author="Name"
git log --grep="pattern"
git log -- <file>          # History of specific file
git log --follow <file>    # Follow renames

# Show changes
git diff                   # Unstaged changes
git diff --staged          # Staged changes
git diff HEAD              # All changes since last commit
git diff <branch>          # Compare with another branch
git diff <commit1> <commit2>
git diff <commit>          # Changes since specific commit
git diff <branch1>...<branch2>  # Changes between branches

# Show commit details
git show <commit>
git show <commit>:<file>   # Show file at specific commit
```

## Branch Management

### Creating and Switching Branches

```bash
# List branches
git branch     # Local branches
git branch -r  # Remote branches
git branch -a  # All branches
git branch -v  # With last commit info
git branch -vv # With tracking info

# Create branch
git branch <branch-name>
git branch <branch-name> <start-point>  # From specific commit/tag

# Switch branch
git switch <branch-name>
git checkout <branch-name>  # Old syntax, still works

# Create and switch
git switch -c <branch-name>
git checkout -b <branch-name>
git switch -c <branch-name> <start-point>

# Delete branch
git branch -d <branch-name>  # Safe delete (only if merged)
git branch -D <branch-name>  # Force delete (even if not merged)

# Rename branch
git branch -m <old-name> <new-name>
git branch -m <new-name>  # Rename current branch

# Set upstream tracking
git branch --set-upstream-to=origin/<branch>
git branch -u origin/<branch>
```

### Branch Strategies

**Git Flow:**
- `main/master`: Production-ready code
- `develop`: Integration branch for features
- `feature/*`: New features
- `release/*`: Release preparation
- `hotfix/*`: Production fixes

**GitHub Flow:**
- `main`: Always deployable
- `feature/*`: Short-lived feature branches
- Create PR, review, merge

**Trunk-Based Development:**
- `main`: Single branch
- Short-lived feature branches (< 1 day)
- Feature flags for incomplete features

**GitLab Flow:**
- Environment branches: `production`, `staging`, `main`
- Feature branches merge to `main`
- Deploy from environment branches

## Remote Operations

### Remote Management

```bash
# List remotes
git remote
git remote -v  # With URLs

# Add remote
git remote add <name> <url>
git remote add origin https://github.com/user/repo.git

# Change remote URL
git remote set-url <name> <new-url>

# Remove remote
git remote remove <name>
git remote rm <name>

# Rename remote
git remote rename <old> <new>

# Show remote info
git remote show <name>
git remote show origin

# Prune stale remote branches
git remote prune origin
git fetch --prune
```

### Fetch and Pull

```bash
# Fetch from remote (doesn't merge)
git fetch
git fetch origin
git fetch --all     # All remotes
git fetch --prune   # Remove stale remote-tracking branches

# Pull (fetch + merge)
git pull
git pull origin <branch>
git pull --rebase  # Fetch + rebase instead of merge
git pull --no-ff   # Always create merge commit
git pull --ff-only # Only if fast-forward possible

# Set default pull behavior
git config --global pull.rebase true  # Always rebase
git config --global pull.ff only      # Only fast-forward
```

### Push

```bash
# Push to remote
git push
git push origin <branch>
git push origin <local-branch>:<remote-branch>

# Push new branch and set upstream
git push -u origin <branch>
git push --set-upstream origin <branch>

# Push all branches
git push --all

# Push tags
git push --tags
git push origin <tag-name>

# Delete remote branch
git push origin --delete <branch>
git push origin :<branch>  # Old syntax

# Delete remote tag
git push origin --delete <tag>
git push origin :refs/tags/<tag>
```

For force-push (dangerous) see `dangerous-operations.md`.
