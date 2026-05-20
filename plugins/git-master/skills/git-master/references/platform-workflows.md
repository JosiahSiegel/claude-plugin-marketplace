# Platform-Specific Git Workflows

Reference patterns for GitHub, Azure DevOps, Bitbucket, and GitLab.

## GitHub

### Pull Requests with GitHub CLI

```bash
# Install GitHub CLI from https://cli.github.com/

# Create PR
gh pr create
gh pr create --title "Title" --body "Description"
gh pr create --base main --head feature-branch

# List PRs
gh pr list

# View PR
gh pr view
gh pr view <number>

# Check out PR locally
gh pr checkout <number>

# Review PR
gh pr review
gh pr review --approve
gh pr review --request-changes
gh pr review --comment

# Merge PR
gh pr merge
gh pr merge --squash
gh pr merge --rebase
gh pr merge --merge

# Close PR
gh pr close <number>
```

### GitHub Actions

```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run tests
        run: npm test
```

## Azure DevOps

### Pull Requests

```bash
# Install Azure DevOps CLI from
# https://docs.microsoft.com/en-us/cli/azure/install-azure-cli

# Create PR
az repos pr create --title "Title" --description "Description"
az repos pr create --source-branch feature --target-branch main

# List PRs
az repos pr list

# View PR
az repos pr show --id <id>

# Complete PR
az repos pr update --id <id> --status completed

# Branch policies
az repos policy list
az repos policy create --config policy.json
```

### Azure Pipelines

```yaml
# azure-pipelines.yml
trigger:
  - main
pool:
  vmImage: 'ubuntu-latest'
steps:
  - script: npm test
    displayName: 'Run tests'
```

## Bitbucket

### Pull Requests

```bash
# Create PR (via web or Bitbucket CLI)
bb pr create

# Review PR
bb pr list
bb pr view <id>

# Merge PR
bb pr merge <id>
```

### Bitbucket Pipelines

```yaml
# bitbucket-pipelines.yml
pipelines:
  default:
    - step:
        script:
          - npm test
```

## GitLab

### Merge Requests

```bash
# Install GitLab CLI (glab) from
# https://gitlab.com/gitlab-org/cli

# Create MR
glab mr create
glab mr create --title "Title" --description "Description"

# List MRs
glab mr list

# View MR
glab mr view <id>

# Merge MR
glab mr merge <id>

# Close MR
glab mr close <id>
```

### GitLab CI

```yaml
# .gitlab-ci.yml
stages:
  - test
test:
  stage: test
  script:
    - npm test
```
