# Git Security: Credential Management and CodeQL Scanning

Detailed credential-management guidance (PATs, SSH keys, Git Credential Manager, rotation, storage) and CodeQL / security scanning setup for repositories. SKILL.md keeps zero-trust model, signed commits, secret scanning, enforcement, security configuration, audit trail, checklist, and incident response.

## Credential Management

### SSH Keys

```bash
# Generate secure SSH key
ssh-keygen -t ed25519 -C "your.email@example.com" -f ~/.ssh/id_ed25519_work

# Use ed25519 (modern, secure, fast)
# Avoid RSA < 4096 bits
# Avoid DSA (deprecated)

# Configure SSH agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519_work

# Test connection
ssh -T git@github.com

# Use different keys for different services
# ~/.ssh/config
Host github.com
  IdentityFile ~/.ssh/id_ed25519_github

Host gitlab.com
  IdentityFile ~/.ssh/id_ed25519_gitlab
```

### HTTPS Credentials

```bash
# Use credential manager (not plaintext!)

# Windows
git config --global credential.helper wincred

# macOS
git config --global credential.helper osxkeychain

# Linux (libsecret)
git config --global credential.helper /usr/share/git/credential/libsecret/git-credential-libsecret

# Cache for limited time (temporary projects)
git config --global credential.helper 'cache --timeout=3600'
```

### Personal Access Tokens (PAT)

**GitHub:**
- Settings → Developer settings → Personal access tokens → Fine-grained tokens
- Set expiration (max 1 year)
- Minimum scopes needed
- Use for HTTPS authentication

**Never commit tokens:**

```bash
# Use environment variable
export GITHUB_TOKEN="ghp_xxxxxxxxxxxx"
git clone https://$GITHUB_TOKEN@github.com/user/repo.git

# Or use Git credential helper
gh auth login  # GitHub CLI method
```

## CodeQL & Security Scanning

### GitHub CodeQL

**.github/workflows/codeql.yml:**

```yaml
name: "CodeQL Security Scan"

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
  schedule:
    - cron: '0 0 * * 1'  # Weekly scan

jobs:
  analyze:
    name: Analyze
    runs-on: ubuntu-latest
    permissions:
      security-events: write
      contents: read

    strategy:
      fail-fast: false
      matrix:
        language: [ 'javascript', 'python', 'java' ]

    steps:
    - name: Checkout repository
      uses: actions/checkout@v4

    - name: Initialize CodeQL
      uses: github/codeql-action/init@v3
      with:
        languages: ${{ matrix.language }}
        queries: security-and-quality

    - name: Autobuild
      uses: github/codeql-action/autobuild@v3

    - name: Perform CodeQL Analysis
      uses: github/codeql-action/analyze@v3
      with:
        category: "/language:${{ matrix.language }}"
```

**Detects:**
- SQL injection
- XSS vulnerabilities
- Path traversal
- Command injection
- Insecure deserialization
- Authentication bypass
- Hardcoded secrets

