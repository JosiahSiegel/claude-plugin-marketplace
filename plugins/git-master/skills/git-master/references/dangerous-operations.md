# Dangerous Git Operations (High Risk)

Reference for destructive Git operations that REQUIRE safety protocols and explicit user confirmation. Always create a backup branch first.

## Safety Pattern (Apply to ALL Destructive Operations)

```bash
echo "WARNING: This operation is DESTRUCTIVE and will:"
echo "   - Permanently delete uncommitted changes"
echo "   - Rewrite Git history"
echo "   - [specific risks for the operation]"
echo ""
echo "Safety recommendation: Creating backup branch first..."
git branch backup-before-reset-$(date +%Y%m%d-%H%M%S)
echo ""
echo "To recover if needed: git reset --hard backup-before-reset-XXXXXXXX"
echo ""
read -p "Are you SURE you want to proceed? (yes/NO): " confirm
if [[ "$confirm" != "yes" ]]; then
    echo "Operation cancelled."
    exit 1
fi
```

## Reset

**WARNING: reset can permanently delete changes.**

```bash
# Soft reset (keep changes staged)
git reset --soft <commit>
git reset --soft HEAD~1  # Undo last commit, keep changes staged

# Mixed reset (default - keep changes unstaged)
git reset <commit>
git reset HEAD~1  # Undo last commit, keep changes unstaged

# HARD reset (DELETE all changes - DANGEROUS!)
# ALWAYS create backup branch first!
git branch backup-$(date +%Y%m%d-%H%M%S)
git reset --hard <commit>
git reset --hard HEAD~1               # Undo last commit and DELETE all changes
git reset --hard origin/<branch>      # Reset to remote state

# Unstage files
git reset HEAD <file>
git reset -- <file>

# Reset specific file to commit
git checkout <commit> -- <file>
```

## Force Push

```bash
# DANGEROUS: Force push (overwrites remote history)
# ALWAYS ASK USER FOR CONFIRMATION FIRST
git push --force
git push -f

# SAFER: Force push with lease (fails if remote updated)
git push --force-with-lease
git push --force-with-lease=<ref>:<expected-value>
```

### Force Push Safety Protocol

Before ANY force push, execute this safety check:

```bash
echo "DANGER: Force push will overwrite remote history!"
echo ""
echo "Remote branch status:"
git fetch origin
git log --oneline origin/<branch> ^<branch> --decorate

if [ -z "$(git log --oneline origin/<branch> ^<branch>)" ]; then
    echo "OK: No commits will be lost (remote is behind local)"
else
    echo "WARNING: Remote has commits that will be LOST:"
    git log --oneline --decorate origin/<branch> ^<branch>
    echo ""
    echo "These commits from other developers will be destroyed!"
fi

echo ""
echo "Consider using --force-with-lease instead of --force"
echo ""
read -p "Type 'force push' to confirm: " confirm
if [[ "$confirm" != "force push" ]]; then
    echo "Cancelled."
    exit 1
fi
```

## Filter-Repo (History Rewriting)

**EXTREMELY DANGEROUS: Rewrites entire repository history.**

```bash
# Install git-filter-repo (not built-in)
# pip install git-filter-repo

# Remove file from all history
git filter-repo --path <file> --invert-paths

# Remove directory from all history
git filter-repo --path <directory> --invert-paths

# Change author info
git filter-repo --name-callback 'return name.replace(b"Old Name", b"New Name")'
git filter-repo --email-callback 'return email.replace(b"old@email.com", b"new@email.com")'

# Remove large files
git filter-repo --strip-blobs-bigger-than 10M

# After filter-repo, force push required
git push --force --all
git push --force --tags
```

### Filter-Repo Safety Protocol

```bash
echo "*** EXTREME DANGER ***"
echo "This operation will:"
echo "  - Rewrite ENTIRE repository history"
echo "  - Change ALL commit hashes"
echo "  - Break all existing clones"
echo "  - Require all team members to re-clone"
echo "  - Cannot be undone after force push"
echo ""
echo "MANDATORY: Create full backup:"
git clone --mirror <repo-url> backup-$(date +%Y%m%d-%H%M%S)
echo ""
echo "Notify ALL team members before proceeding!"
echo ""
read -p "Type 'I UNDERSTAND THE RISKS' to continue: " confirm
if [[ "$confirm" != "I UNDERSTAND THE RISKS" ]]; then
    echo "Cancelled."
    exit 1
fi
```

## Amend Pushed Commits

**DANGER: Changing pushed commits requires force push.**

```bash
# Amend last commit
git commit --amend

# Amend without changing message
git commit --amend --no-edit

# Change author of last commit
git commit --amend --author="Name <email>"

# Force push required if already pushed
git push --force-with-lease
```

## Rewrite Multiple Commits

**DANGER: Interactive rebase on pushed commits.**

```bash
# Interactive rebase
git rebase -i HEAD~5

# Change author of older commits
git rebase -i <commit>^
# Mark commit as "edit"
# When stopped:
git commit --amend --author="Name <email>" --no-edit
git rebase --continue

# Force push required
git push --force-with-lease
```
