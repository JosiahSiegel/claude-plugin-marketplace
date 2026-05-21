---
name: ado-pipeline-best-practices
description: |
  Azure DevOps pipeline best practices, patterns, and industry standards.
  PROACTIVELY activate for: (1) authoring or reviewing Azure DevOps YAML pipelines, (2) multi-stage pipeline patterns (build, test, deploy), (3) reusable templates (steps, jobs, stages), (4) pipeline caching (Cache@2 task), (5) parallel jobs and matrix strategies, (6) deployment strategies (rolling, blue-green, canary), (7) approvals and environments, (8) variable groups, secret variables, Key Vault linkage, (9) service connections (Azure RM, GitHub, container registries), (10) pipeline versioning and pinning task major versions.
  Provides: YAML pattern catalog, template library structure, caching recipes, deployment strategy templates, and a pipeline-quality checklist.
---

# Azure Pipelines Best Practices

Comprehensive best practices for creating and maintaining Azure DevOps YAML pipelines.

## Core Review Procedure

1. Identify trigger scope, deployment environments, and required approvals before editing YAML.
2. Verify secrets flow through service connections, Key Vault, secret variables, or secure files; never inline credentials.
3. Pin task major versions and centralize repeated steps in templates.
4. Add path filters, caching, and parallel jobs only when they reduce real build cost without hiding validation.
5. Keep build, test, package, and deploy concerns separated by stages or jobs.
6. Validate with Azure DevOps pipeline YAML validation or a dry run before recommending rollout.

## Pipeline Structure

**Multi-Stage Pipelines:**
```yaml
# Recommended structure
stages:
  - stage: Build
  - stage: Test
  - stage: DeployDev
  - stage: DeployStaging  
  - stage: DeployProduction
```

**Benefits:**
- Clear separation of concerns
- Conditional stage execution
- Environment-specific configurations
- Approval gates between stages

## Triggers and Scheduling

**Best practices:**
- Use path filters to avoid unnecessary builds
- Enable batch builds for high-frequency repos
- Use PR triggers for validation
- Schedule nightly/weekly builds for comprehensive testing

```yaml
trigger:
  batch: true
  branches:
    include: [main, develop]
  paths:
    exclude: ['docs/*', '**.md']

pr:
  autoCancel: true
  branches:
    include: [main]

schedules:
  - cron: '0 0 * * *'
    displayName: 'Nightly build'
    branches:
      include: [main]
    always: false  # Only if code changed
```

## Variable Management

**Hierarchy:**
1. Pipeline-level variables (az devops YAML)
2. Variable groups (shared across pipelines)
3. Azure Key Vault (secrets)
4. Runtime parameters (user input)

**Security:**
- Never hardcode secrets
- Use Key Vault for sensitive data
- Mark secrets in variable groups
- Secrets are automatically masked in logs

## Caching

Implement caching for:
- Package dependencies (npm, pip, NuGet, Maven)
- Docker layers
- Build outputs

**Impact:**
- Faster builds (up to 90% reduction)
- Reduced network usage
- Lower costs

## Templates

**Use templates for:**
- Reusable build patterns
- Standardized deployment steps
- Consistent security scanning
- Company-wide best practices

**Benefits:**
- DRY (Don't Repeat Yourself)
- Centralized updates
- Consistent processes

## Security Practices

**Essential:**
- Code scanning (SAST, dependency)
- Container image scanning
- Secret scanning
- Compliance checks
- Branch protection policies
- Required approvals

## Performance

**Optimize:**
- Parallelize independent jobs
- Use caching extensively
- Shallow git clones (fetchDepth: 1)
- Appropriate agent pools
- Clean up artifacts

## Monitoring

**Track:**
- Build success rates
- Build durations
- Test pass rates
- Deployment frequency
- Mean time to recovery (MTTR)

## References and Pairings

- Use Microsoft Azure Pipelines YAML schema documentation for task syntax and newly released features.
- Pair with workload-identity/OIDC guidance when replacing service principal secrets.
- Pair with security scanning guidance when adding SAST, dependency, container, or IaC checks.

Always verify best practices against latest Azure DevOps documentation.
