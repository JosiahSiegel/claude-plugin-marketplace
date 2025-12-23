# ADO Master Plugin

Master Azure DevOps pipelines with expert knowledge of YAML pipelines, CI/CD best practices, security, CLI operations, and industry standards.

## Overview

The ADO Master plugin equips Claude Code with comprehensive Azure DevOps expertise, enabling you to create, optimize, secure, and debug Azure Pipelines following current Microsoft 2025 best practices. Updated for Sprint 254-262 with Agent v4, Microsoft Security DevOps, template management, and GitHub Copilot integration.

## What's New in v1.5.0

**NEW Skills:**
- **`ado-windows-git-bash-compatibility`** - Comprehensive Windows/Git Bash path handling for Azure Pipelines
  - MINGW/MSYS path conversion mastery
  - Shell detection patterns for cross-platform scripts
  - Windows agent troubleshooting and diagnostics
  - Azure DevOps CLI path handling on Windows

**Windows Compatibility Enhancements:**
- Complete Git Bash path conversion guidance (`MSYS_NO_PATHCONV`)
- Cross-platform script patterns for Windows/Linux/macOS agents
- Platform detection using `$(Agent.OS)` and `uname`
- Windows-specific pipeline examples in all commands
- Troubleshooting guides for common Windows agent failures

**Previous Features (v1.4.0):**
- Workload identity federation (OIDC) setup and migration guidance (2025 security standard)
- Pipeline performance analytics and cost tracking with Azure DevOps CLI
- Microsoft Security DevOps (MSDO) extension integration (replaces deprecated CredScan)
- Pipeline template management and reusability patterns
- Agent v4 with .NET 8 and ARM64 support
- Sprint 261-262 features: OAuth migration to Entra ID, GitHub Copilot integration
- Continuous Access Evaluation (CAE) security features
- Updated OS images: Ubuntu-24.04, Windows-2025, macOS-15

## Features

### Commands

- **`/ado-pipeline-create`** - Create new YAML pipelines following current best practices and industry standards
- **`/ado-pipeline-optimize`** - Optimize pipelines for performance, cost, and efficiency
- **`/ado-pipeline-security`** - Secure pipelines with Microsoft Security DevOps, Defender for DevOps, and compliance standards
- **`/ado-pipeline-debug`** - Debug pipeline failures and troubleshoot common issues
- **`/ado-workload-identity`** - Configure workload identity federation (OIDC) for passwordless Azure authentication (NEW in v1.4.0)
- **`/ado-pipeline-analytics`** - Analyze pipeline performance, track metrics, and identify optimization opportunities (NEW in v1.4.0)
- **`/ado-quality-gates`** - Implement quality gates and code quality enforcement with SonarQube integration (NEW in v1.4.0)
- **`/ado-templates`** - Create and manage reusable YAML templates for consistency and efficiency
- **`/ado-tasks`** - Help with common Azure DevOps pipeline tasks and their usage
- **`/ado-cli`** - Manage Azure DevOps using Azure DevOps CLI
- **`/ado-repo`** - Manage repositories, branches, and Git operations

### Agent

- **ADO Expert Agent** - Comprehensive Azure DevOps expert with knowledge of:
  - Azure Pipelines YAML schema and best practices
  - CI/CD patterns and deployment strategies
  - Task-specific expertise (all Azure Pipelines tasks)
  - Security and compliance implementation
  - Performance optimization techniques
  - Systematic troubleshooting
  - Azure DevOps CLI automation

### Skills

- **ado-pipeline-best-practices** - Best practices for Azure Pipelines structure, triggers, variables, and more
- **sprint-254-features** - Azure DevOps Sprint 254-262 latest features including Agent v4, ARM64 support, GitHub Copilot integration
- **defender-for-devops** - Microsoft Defender for DevOps integration with comprehensive security scanning
- **ado-windows-git-bash-compatibility** - Windows/Git Bash path handling and cross-platform compatibility (NEW in v1.5.0)

## Installation

### Via Marketplace

```bash
/plugin marketplace add JosiahSiegel/claude-code-marketplace
/plugin install ado-master@claude-plugin-marketplace
```

## Usage

### Creating New Pipelines

```bash
/ado-pipeline-create
```

Claude will:
1. Check latest Azure Pipelines YAML schema
2. Gather your requirements (language, platform, deployment)
3. Create complete pipeline with best practices
4. Apply security and performance optimizations
5. Provide setup instructions

### Optimizing Existing Pipelines

```bash
/ado-pipeline-optimize
```

Claude will:
1. Analyze current pipeline performance
2. Identify bottlenecks and inefficiencies
3. Implement caching and parallelization
4. Reduce costs and execution time
5. Provide before/after metrics

### Securing Pipelines

```bash
/ado-pipeline-security
```

Claude will:
1. Audit pipeline security
2. Implement secrets management (Azure Key Vault)
3. Add code scanning (SAST, dependency scanning)
4. Configure approval gates and policies
5. Apply compliance standards

### Configuring Workload Identity (OIDC)

```bash
/ado-workload-identity
```

Claude will:
1. Set up workload identity federation for Azure
2. Migrate from service principals to OIDC
3. Configure passwordless authentication
4. Apply 2025 security best practices
5. Eliminate secret management overhead

### Analyzing Pipeline Performance

```bash
/ado-pipeline-analytics
```

Claude will:
1. Track pipeline performance metrics
2. Calculate success rates and duration trends
3. Identify bottlenecks and optimization opportunities
4. Generate cost efficiency reports
5. Set up monitoring and alerting

### Debugging Failures

```bash
/ado-pipeline-debug
```

Claude will:
1. Analyze logs and failure patterns
2. Identify root cause
3. Provide step-by-step fix
4. Add prevention measures
5. Show verification commands

### Working with Tasks

```bash
/ado-tasks
```

Claude will help you use specific Azure Pipelines tasks with:
- Latest task versions
- Complete working examples
- Best practices for each task
- Error handling recommendations

### CLI Operations

```bash
/ado-cli
```

Claude will provide Azure DevOps CLI commands for:
- Pipeline management
- Repository operations
- Variable and variable group management
- Automation scripts

### Expert Consultation

```bash
/agent ado-expert
```

The ADO Expert agent can help with:
- Complex multi-stage pipelines
- Template design and reusability
- Deployment strategy selection
- Azure service integration
- Troubleshooting complex issues
- CLI automation scripts

## Key Principles

This plugin ensures Claude always:

1. **Checks Latest Documentation** - Fetches current Azure Pipelines docs before recommendations
2. **Follows Microsoft Best Practices** - Implements official recommended patterns
3. **Security-First** - Prioritizes security in all pipeline designs
4. **Comprehensive Examples** - Provides complete, working YAML
5. **Current Task Versions** - Uses latest stable task versions
6. **Explains Rationale** - Teaches why, not just what
7. **Cross-Platform Compatibility** - Ensures pipelines work on Windows, Linux, and macOS agents

## Best Practices Applied

### Pipeline Structure
- Multi-stage YAML for complex workflows
- Templates for reusability
- Runtime parameters for flexibility
- Proper stage dependencies
- Conditional execution

### Security
- Azure Key Vault integration
- No hardcoded secrets
- Code scanning (SAST, dependency, container)
- Branch policies and protection
- Approval gates for production
- Service connections with least privilege

### Performance
- Dependency caching (npm, NuGet, Maven, pip)
- Job parallelization
- Shallow git clone
- Appropriate agent selection
- Artifact cleanup

### Quality
- Automated testing integration
- Code coverage requirements
- Quality gates (SonarQube)
- Test result publishing
- Build validation for PRs

## Technology Support

### Languages & Frameworks
- .NET / .NET Core
- Node.js / JavaScript / TypeScript
- Python
- Java (Maven, Gradle)
- Go
- Ruby
- PHP

### Platforms
- Azure services (Web Apps, Functions, Container Registry, Kubernetes)
- Docker and containers
- Kubernetes and Helm
- On-premises deployments
- Multi-cloud scenarios

### Tools & Integrations
- Docker and container registries
- Kubernetes and AKS
- Azure services
- SonarQube / SonarCloud
- Security scanning tools
- Test frameworks

## Common Workflows

### Full CI/CD Pipeline

```bash
# 1. Create optimized pipeline
/ado-pipeline-create

# 2. Add security scanning
/ado-pipeline-security

# 3. Optimize for performance
/ado-pipeline-optimize

# Result: Production-ready, secure, optimized pipeline
```

### Debug and Fix

```bash
# Pipeline failing?
/ado-pipeline-debug

# Claude will:
# - Analyze logs
# - Identify issue
# - Provide fix
# - Prevent recurrence
```

### CLI Automation

```bash
/ado-cli

# Get commands for:
# - Bulk operations
# - Automation scripts
# - Monitoring and reporting
```

## Example Scenarios

### Scenario: New Node.js Application

User: "I need a CI/CD pipeline for my Node.js app deployed to Azure Web App"

```bash
/ado-pipeline-create
```

Result:
- Complete YAML pipeline
- npm caching
- Test execution
- Build optimization
- Azure Web App deployment
- Environment-specific stages

### Scenario: Slow Docker Builds

User: "My Docker builds take 30 minutes. Can we optimize?"

```bash
/ado-pipeline-optimize
```

Result:
- Docker layer caching implemented
- Build time reduced to 5 minutes
- Cost savings calculated
- Multi-stage build optimization

### Scenario: Security Audit Required

User: "We need to pass security audit. Help secure our pipelines."

```bash
/ado-pipeline-security
```

Result:
- Key Vault integration
- Code scanning added
- Container vulnerability scanning
- Approval gates configured
- Compliance documentation

## Requirements

- Azure DevOps organization
- Access to create/edit pipelines
- Appropriate permissions for target environments
- Azure subscription (for Azure deployments)

## Recommended Tools

This plugin references:
- **Azure DevOps CLI** - Command-line management
- **Azure CLI** - Azure resource management
- **SonarQube/SonarCloud** - Code quality
- **Trivy/Aqua** - Container scanning
- **OWASP Dependency Check** - Dependency scanning

## Learning Resources

The plugin provides guidance on:
- Microsoft Learn Azure Pipelines docs
- YAML schema reference
- Task documentation
- Best practices guides
- Security recommendations

## Contributing

This plugin stays current with Azure DevOps monthly updates. Feedback and improvements welcome!

## License

MIT

## Support

For issues or questions:
- Use commands for specific guidance
- Consult `/agent ado-expert` for complex scenarios
- Check Microsoft Learn documentation
- Review Azure DevOps release notes

---

**Master Azure DevOps pipelines with confidence.** This plugin ensures you follow current Microsoft best practices, maintain security, optimize performance, and build production-ready CI/CD pipelines.
