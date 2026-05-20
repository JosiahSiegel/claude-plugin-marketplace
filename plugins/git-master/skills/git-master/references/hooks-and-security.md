# Git Hooks and Security Best Practices

## Git Hooks

### Client-Side Hooks

Hooks location: `.git/hooks/`

```bash
# pre-commit: Run before commit
# Example: .git/hooks/pre-commit
#!/bin/bash
npm run lint || exit 1
```

```bash
# commit-msg: Validate commit message
#!/bin/bash
msg=$(cat "$1")
if ! echo "$msg" | grep -qE "^(feat|fix|docs|style|refactor|test|chore):"; then
    echo "Error: Commit message must start with type (feat|fix|docs|...):"
    exit 1
fi
```

Other client-side hooks:
- `prepare-commit-msg`: Edit commit message before editor opens
- `post-commit`: Run after commit
- `pre-push`: Run before push
- `post-checkout`: Run after checkout
- `post-merge`: Run after merge

```bash
# Make hook executable
chmod +x .git/hooks/pre-commit
```

### Server-Side Hooks

- `pre-receive`: Run before refs are updated
- `update`: Run for each branch being updated
- `post-receive`: Run after refs are updated

```bash
# Example: Reject force pushes
#!/bin/bash
while read oldrev newrev refname; do
    if [ "$oldrev" != "0000000000000000000000000000000000000000" ]; then
        if ! git merge-base --is-ancestor "$oldrev" "$newrev"; then
            echo "Error: Force push rejected"
            exit 1
        fi
    fi
done
```

## Security Best Practices

### Credential Management

```bash
# Store credentials (cache for 1 hour)
git config --global credential.helper cache
git config --global credential.helper 'cache --timeout=3600'

# Store credentials (permanent - use with caution)
git config --global credential.helper store

# Windows: Use Credential Manager
git config --global credential.helper wincred

# macOS: Use Keychain
git config --global credential.helper osxkeychain

# Linux: Use libsecret
git config --global credential.helper /usr/share/doc/git/contrib/credential/libsecret/git-credential-libsecret
```

### SSH Keys

```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "your_email@example.com"
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"  # If ed25519 not supported

# Start ssh-agent
eval "$(ssh-agent -s)"

# Add key to ssh-agent
ssh-add ~/.ssh/id_ed25519

# Test connection
ssh -T git@github.com
ssh -T git@ssh.dev.azure.com
```

### GPG Signing

```bash
# Generate GPG key
gpg --full-generate-key

# List keys
gpg --list-secret-keys --keyid-format LONG

# Configure Git to sign commits
git config --global user.signingkey <key-id>
git config --global commit.gpgsign true

# Sign commits
git commit -S -m "message"

# Verify signatures
git log --show-signature
```

### Preventing Secrets

```bash
# Git-secrets (AWS tool)
git secrets --install
git secrets --register-aws

# Gitleaks
gitleaks detect
```

```bash
# Pre-commit hook to scan for secrets
#!/bin/bash
if git diff --cached | grep -E "(password|secret|api_key)" ; then
    echo "Potential secret detected!"
    exit 1
fi
```

## Best Practices Summary

### Commit Messages (Conventional Commits)

```text
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting (no code change)
- `refactor`: Code restructuring
- `test`: Adding tests
- `chore`: Maintenance

**Example:**

```text
feat(auth): add OAuth2 authentication

Implement OAuth2 flow for Google and GitHub providers.
Includes token refresh and revocation.

Closes #123
```

### Branching Best Practices

1. Keep branches short-lived (< 2 days ideal)
2. Use descriptive names: `feature/user-auth`, `fix/header-crash`
3. One purpose per branch
4. Rebase before merge to keep history clean
5. Delete merged branches

### Workflow Best Practices

1. Commit often (small, logical chunks)
2. Pull before push (stay up to date)
3. Review before commit (`git diff --staged`)
4. Write meaningful messages
5. Test before commit
6. Never commit secrets (use `.gitignore`, environment variables)

### .gitignore Template

```gitignore
# Environment files
.env
.env.local
*.env

# Dependencies
node_modules/
vendor/
venv/

# Build outputs
dist/
build/
*.exe
*.dll
*.so

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS files
.DS_Store
Thumbs.db

# Logs
*.log
logs/

# Temporary files
tmp/
temp/
*.tmp
```
