# Terraform Master Plugin

Complete Terraform expertise system for Claude Code. Provides comprehensive infrastructure-as-code guidance, version-aware code generation, multi-environment architecture, CI/CD integration, and industry best practices across Windows, Linux, and macOS.

## Features

### Comprehensive Provider Coverage
- **Azure**: AzureRM, AzAPI for all Azure resources
- **AWS**: Complete AWS service coverage
- **Google Cloud**: Full GCP resource support
- **Community Providers**: Kubernetes, Helm, Datadog, PagerDuty, GitHub, GitLab, and more

### Enterprise Capabilities
- Multi-environment architecture patterns
- Multi-region deployment strategies
- Large-scale state management
- Module development and organization
- Landing zone implementations
- Service catalog patterns

### Resource Import & State Management ⭐ NEW
- **Import Existing Resources**: Bring manual deployments under Terraform control
  - Traditional imports and import blocks (Terraform 1.5+)
  - Bulk import with Terraformer, aztfexport, custom scripts
  - Migration from ARM templates, CloudFormation, manual provisioning
- **State Operations**: Complete state management
  - Move, rename, and refactor resources
  - Split/merge states
  - Backup and recovery
  - State inspection and troubleshooting

### Version-Aware Operations
- Automatic version detection
- Breaking change awareness
- Upgrade path guidance
- Provider version management
- Migration assistance

### Platform Support
- **Windows**: PowerShell-native, **Git Bash/MINGW compatibility**, path handling, credential management
- **Linux**: Package managers, permissions, environment configuration
- **macOS**: Homebrew integration, BSD utilities
- **CI/CD**: Azure DevOps, GitHub Actions, GitLab CI, Jenkins
- **Cross-Platform Scripts**: Shell detection and path conversion handling

### Security & Compliance (2025)
- **Trivy integration** (tfsec functionality merged into Trivy in 2025)
- Checkov policy-as-code scanning (750+ policies)
- Terrascan compliance scanning
- NIST SP 800-53 Rev 5 Sentinel policies (350+ policies)
- Best practice enforcement
- Secrets management patterns
- Ephemeral values for secure secrets (Terraform 1.10+)
- Network security guidance
- Encryption standards
- HYOK (Hold Your Own Key) support
- Compliance validation

## Installation

### From Claude Code Marketplace

```bash
# In Claude Code
/plugin install terraform-master@claude-plugin-marketplace
```

### Manual Installation

1. Clone this repository or download the `terraform-master` directory
2. Add marketplace to Claude Code settings:

```bash
# In Claude Code
/plugin marketplace add local file:///path/to/claude-code-marketplace
/plugin install terraform-master@local
```

## 2025 Feature Highlights

### Terraform 1.10+ Features
- **Ephemeral Values**: Secure secrets handling without persistence in state or plan files
- **Write-Only Arguments**: Accept ephemeral values in managed resources (Terraform 1.11+)
- **Testing Framework**: Native terraform test command with JUnit XML output (1.6+, enhanced 1.11+)
- **Terraform Query**: Execute list operations against existing infrastructure (Terraform 1.14+)
- **Actions Blocks**: Imperative operations outside CRUD model (Terraform 1.14+)

### OpenTofu Alternative (2025)
- **Open-Source Fork**: MPL 2.0 licensed, Linux Foundation governance
- **Latest Stable**: OpenTofu 1.10.6 (Beta: 1.11.0-beta1)
- **Built-in State Encryption**: Client-side encryption without cloud costs
- **Enhanced Import Blocks**: Loop-able imports with for_each (1.7+)
- **Early Variable Evaluation**: Use variables in terraform blocks and module sources (1.8+)
- **OpenTofu 1.10**: OCI Registry support, native S3 locking (no DynamoDB), OpenTelemetry tracing
- **OpenTofu 1.11** (Beta): Ephemeral resources, enabled meta-argument for conditional deployment
- **100% Compatible**: Drop-in replacement for Terraform 1.5.x
- **Fast Migration**: < 1 hour for most projects, no code changes required

### HCP Terraform 2025
- **Terraform Stacks (GA)**: Multi-deployment orchestration, Linked Stacks for dependencies
- **Module Lifecycle Management (GA)**: Revoke compromised modules, version control
- **HYOK (Hold Your Own Key)**: Full control over encryption keys for state and plan files
- **Private VCS Access**: Direct private connections to VCS without public internet exposure
- **AI Integration**: Experimental MCP servers for AI-driven infrastructure automation
- **Project Infragraph** (Private Beta Dec 2025): Centralized data substrate for autonomous agents

### Testing & Quality (2025)
- **terraform test**: Native testing framework with assertions and mocks (1.6+)
- **JUnit XML Output**: CI/CD test reporting integration (1.11+)
- **Terratest**: Go-based integration testing with real resources
- **TDD/BDD**: Test-driven development patterns and best practices

### Security & Compliance 2025
- **Trivy Scanner**: tfsec functionality merged into Trivy - unified IaC and container scanning
- **NIST SP 800-53 Rev 5 Policies**: 350+ pre-written Sentinel policies for government compliance
- **Enhanced Checkov**: 750+ policies covering CIS, GDPR, PCI-DSS, HIPAA standards

### Policy-as-Code & Governance (2025)
- **Sentinel Policies**: NIST SP 800-53 Rev 5 compliance with 350+ pre-written policies
- **Open Policy Agent (OPA)**: Rego policy language with conftest integration
- **Checkov**: 750+ policies for CIS, GDPR, PCI-DSS, HIPAA compliance
- **Private Registry**: Module lifecycle management, revoke compromised modules, no-code provisioning
- **No-Code Provisioning**: Self-service infrastructure for non-technical users with curated modules

### Provider Updates
- **AzureRM 4.x**: Latest stable with 1,101+ resources, 360+ data sources
- **AWS 6.0 (GA)**: Multi-region support, bucket_region attribute, service deprecations (CloudWatch Evidently EOL Oct 2025, MediaStore EOL Nov 2025)
- **GCP 6.x**: Incremental improvements and new services

## Components

### Slash Commands (19 Total)

#### `/terraform-master:tf-init`
Initialize Terraform projects with best practices and platform-specific guidance.

#### `/terraform-master:tf-plan`
Generate and review Terraform execution plans with comprehensive analysis.

#### `/terraform-master:tf-apply`
Apply Terraform changes safely with pre-apply checks and rollback strategies.

#### `/terraform-master:tf-validate`
Comprehensive validation including syntax, format, security, and compliance.

#### `/terraform-master:tf-format`
Format and lint Terraform code across all platforms.

#### `/terraform-master:tf-modules`
Manage local and remote Terraform modules with versioning best practices.

#### `/terraform-master:tf-providers`
Configure and manage providers across all cloud platforms.

#### `/terraform-master:tf-upgrade`
Safely upgrade Terraform and provider versions with migration guidance.

#### `/terraform-master:tf-debug`
Systematically debug Terraform issues across all platforms.

#### `/terraform-master:tf-security`
Security scanning, remediation, and best practices implementation.

#### `/terraform-master:tf-cicd`
Complete CI/CD pipeline generation and troubleshooting.

#### `/terraform-master:tf-architecture`
Architecture design and review for enterprise-scale Terraform.

#### `/terraform-master:tf-import`
Import existing cloud resources into Terraform management with traditional imports, import blocks (Terraform 1.5+), bulk import strategies, and migration from manual deployments.

#### `/terraform-master:tf-state`
Comprehensive state management including move, remove, inspect, backup, recovery, and state migration operations.

#### `/terraform-master:tf-cli`
Complete Terraform CLI reference with all commands, flags, options, and advanced usage patterns including -chdir, environment variables, and platform-specific examples.

#### `/terraform-master:tf-test`
Comprehensive testing with Terraform 1.6+ test framework, Terratest integration, unit/integration testing, TDD/BDD patterns, and CI/CD test reporting.

#### `/terraform-master:tf-stacks`
Terraform Stacks for multi-deployment orchestration with Linked Stacks, deployment management, and HCP Terraform integration.

#### `/terraform-master:tf-policy` ⭐ NEW
Policy-as-code governance with Sentinel, Open Policy Agent (OPA), and Checkov. Implement NIST SP 800-53 Rev 5 compliance (350+ policies), cost control, security enforcement, and CI/CD policy integration.

#### `/terraform-master:tf-registry` ⭐ NEW
Private module registry setup, module lifecycle management, no-code provisioning enablement, and enterprise module governance with terraform-docs and testing integration.

### Terraform Expert Agent

The `terraform-expert` agent is automatically activated for Terraform-related tasks and provides:

- **Comprehensive Provider Knowledge**: Deep expertise in Azure, AWS, GCP, and community providers
- **Version Awareness**: Always considers Terraform and provider versions, warns about breaking changes
- **Platform Intelligence**: Provides Windows, Linux, and macOS-specific guidance
- **Security Focus**: Enforces security best practices and scanning
- **Documentation Research**: Fetches latest provider documentation when needed
- **Architecture Guidance**: Enterprise-scale architecture patterns and best practices

**Proactive Activation**: The agent automatically activates when you mention Terraform, HCL, infrastructure-as-code, or cloud resources.

### Terraform Tasks Skill

Autonomous skill for executing complex Terraform operations including infrastructure code generation, version management, debugging, security scanning, architecture review, CI/CD pipeline creation, module development, and resource migration.

## Usage Examples

### Example 1: Initialize a New Azure Project

```
User: Help me initialize a new Terraform project for Azure

Agent: I'll help you initialize a Terraform project for Azure with best practices.
First, let me ask a few questions:
- What Terraform version are you using?
- Which AzureRM provider version?
- Do you need remote state backend?

[Creates complete project structure with all necessary files]
```

### Example 2: Generate Secure Infrastructure

```
User: Create an Azure Storage Account with all security best practices

Agent: [Detects your Terraform/provider versions]
[Generates complete configuration with encryption, private endpoints, network rules]
[Runs security scan and confirms all checks pass]
```

### Example 3: Debug Issues

```
User: My terraform plan is failing with authentication error on Windows

Agent: [Identifies Windows platform and Azure CLI authentication issue]
[Provides PowerShell commands to diagnose and fix]
[Explains root cause and prevention]
```

### Example 4: CI/CD Pipeline

```
User: /terraform-master:tf-cicd

Agent: [Generates complete CI/CD pipeline for your platform]
[Includes security scanning, approval gates, drift detection]
[Provides OIDC setup instructions]
```

### Example 5: Architecture Review

```
User: /terraform-master:tf-architecture

Agent: [Analyzes your current structure]
[Identifies anti-patterns and proposes improvements]
[Provides migration plan and ADR documentation]
```

### Example 6: Import Existing Resources ⭐ NEW

```
User: /terraform-master:tf-import

Agent: I'll help you import existing infrastructure into Terraform.

First, let me understand your situation:
- Which cloud provider? (Azure/AWS/GCP)
- How many resources need to be imported?
- Do you have Terraform 1.5+ (for import blocks)?

User: Azure, about 20 resources in a resource group, Terraform 1.7

Agent: Perfect! For Terraform 1.5+, I recommend using import blocks.

Step 1: Let me help you inventory the resources:
[Provides Azure CLI commands to list all resources]

Step 2: Create import blocks:
[Generates import.tf with all 20 resources]

Step 3: Generate configuration:
terraform plan -generate-config-out=generated.tf

[Provides complete workflow with verification steps]
```

### Example 7: State Management ⭐ NEW

```
User: I need to rename a resource and move it to a module

Agent: I'll help you refactor your Terraform structure safely.

Current structure:
resource "azurerm_virtual_network" "vnet"

Target structure:
module "networking" {
  # contains azurerm_virtual_network.vnet
}

Steps:
1. Backup state first:
   terraform state pull > backup-$(date +%Y%m%d).json

2. Move resource to module:
   terraform state mv azurerm_virtual_network.vnet module.networking.azurerm_virtual_network.vnet

3. Verify (should show no changes):
   terraform plan

[Provides complete commands with safety checks]
```

## Best Practices

### Version Management
- Always pin Terraform and provider versions in production
- Use pessimistic version constraints (~>)
- Review changelogs before upgrading
- Test upgrades in non-production first

### State Management
- Use remote backend (Azure Storage, S3, GCS, Terraform Cloud)
- Enable state locking
- Enable versioning on backend storage
- Restrict access with RBAC/IAM

### Security
- Never commit secrets to code
- Use secret management services
- Run security scanning in CI/CD
- Enforce HTTPS/TLS everywhere
- Implement least privilege IAM/RBAC

### Code Quality
- Run terraform fmt before committing
- Use pre-commit hooks
- Implement CI/CD validation
- Document all modules

### CI/CD
- Separate plan and apply stages
- Require approval for production
- Save plans as artifacts
- Implement drift detection

## Version Compatibility (2025)

- **Terraform**: 1.0+ (1.6+ for testing, 1.10+ for ephemeral values, 1.11+ for JUnit XML, 1.14+ for actions/query)
- **OpenTofu**: 1.6+ (1.10+ for OCI registry and S3 locking, 1.11+ beta for ephemeral resources and enabled meta-argument)
- **Providers**:
  - **AzureRM**: 4.x recommended (3.x supported), 1,101+ resources, 360+ data sources
  - **AWS**: 6.0 GA (multi-region support, service EOLs), 5.x still supported
  - **GCP**: 5.x/6.x recommended
- **HCP Terraform**: Stacks (GA 2025), Linked Stacks, Module Lifecycle Management, HYOK, Private VCS Access
- **Platforms**: Windows, Linux, macOS
- **CI/CD**: Azure DevOps, GitHub Actions, GitLab CI, Jenkins
- **Testing**: terraform test (1.6+), Terratest (Go), JUnit XML (1.11+)
- **Security Tools**: Trivy (recommended - replaces tfsec), Checkov, Terrascan, Sentinel
- **Policy Frameworks**: Sentinel (HCP Terraform), Open Policy Agent (OPA), Checkov
- **Module Registry**: HCP Terraform, Terraform Enterprise, Citizen (open source)

## Documentation Resources (2025)

- [Terraform Documentation](https://www.terraform.io/docs)
- [OpenTofu Documentation](https://opentofu.org/docs)
- [Terraform Registry](https://registry.terraform.io/)
- [OpenTofu Registry](https://registry.opentofu.org/)
- [HCP Terraform Documentation](https://developer.hashicorp.com/terraform/cloud-docs)
- [Terraform Stacks](https://developer.hashicorp.com/terraform/cloud-docs/stacks)
- [Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Trivy](https://trivy.dev/) - Unified security scanner (replaces tfsec)
- [Checkov](https://www.checkov.io/) - Policy-as-code
- [Terratest](https://terratest.gruntwork.io/) - Integration testing

## License

Part of the Claude Code Marketplace.

## Changelog

### Version 1.7.0 (2025)

**Git Bash Windows Compatibility:**
- **Git Bash/MINGW Path Conversion Expertise**: Complete guidance for Windows developers using Git Bash
  - Terraform-specific path issues (-chdir, -var-file, backend paths, module sources)
  - MSYS_NO_PATHCONV usage and workarounds
  - Shell detection patterns for cross-platform scripts
  - cygpath integration for path conversion
  - Best practices for Git Bash + Terraform workflows
- **Cross-Platform Script Patterns**: Shell detection and adaptive path handling
  - Detect Git Bash vs PowerShell vs Unix shells
  - Platform-specific path variable configuration
  - OSTYPE and MSYSTEM detection examples
  - Universal Terraform script templates

**Agent Enhancements:**
- Added comprehensive Git Bash/MINGW path conversion section (Section 6.5)
- Documented Terraform-specific path conversion issues
- Added shell detection for Terraform workflows
- Cross-platform script patterns with $OSTYPE and $MSYSTEM
- Best practices for Git Bash + Terraform compatibility
- Troubleshooting Git Bash path conversion failures
- Updated proactive behavior with 2 new activation scenarios

**Command Updates:**
- `/tf-debug`: Added Git Bash path troubleshooting section
  - -chdir path conversion issues
  - Backend state file path problems
  - Module source path issues
  - Variable file path failures
  - 5 solution patterns for each scenario
- `/tf-cli`: Added dedicated Git Bash on Windows section
  - Path conversion examples (bad vs good)
  - Cross-platform script pattern with shell detection
  - 5 Git Bash best practices
  - cygpath usage examples

**Documentation Updates:**
- README: Added Git Bash/MINGW compatibility to Platform Support
- README: Added cross-platform scripts feature
- Agent: Comprehensive Git Bash section with Terraform-specific examples
- Commands: Platform-specific Git Bash troubleshooting

### Version 1.6.0 (2025)

**Major New Features:**
- **Policy-as-Code Framework**: Complete policy governance with Sentinel, OPA, and Checkov
  - NIST SP 800-53 Rev 5 policies (350+ controls)
  - Compliance validation (CIS, GDPR, PCI-DSS, HIPAA)
  - Pre-commit and CI/CD integration
  - New command: `/tf-policy`
- **Private Module Registry**: Enterprise module distribution and governance
  - Module lifecycle management (revoke compromised modules)
  - No-code provisioning for self-service infrastructure
  - Module curation and approval workflows
  - terraform-docs integration
  - New command: `/tf-registry`
- **OpenTofu 1.10/1.11 Features**: Latest OpenTofu capabilities
  - OCI Registry support for module distribution
  - Native S3 locking (no DynamoDB required)
  - Ephemeral resources (1.11 beta)
  - Enabled meta-argument for conditional resources
  - OpenTelemetry tracing for observability
- **Terraform 1.14 Features**: Enhanced with actions and query
  - Actions blocks for imperative operations
  - Query command for infrastructure discovery
  - Lifecycle action triggers
- **AWS Provider 6.0 GA**: Updated breaking changes documentation
  - Multi-region support details
  - Service deprecations (CloudWatch Evidently, MediaStore)
  - Redshift public accessibility changes

**Agent Enhancements:**
- Added OpenTofu 1.10/1.11 features section with examples
- Added Terraform 1.14 actions and query command expertise
- Added policy-as-code mastery section
- Added private registry and no-code provisioning guidance
- Updated proactive behavior with 5 new activation scenarios
- Enhanced version-specific knowledge through OpenTofu 1.11 and Terraform 1.14

**Documentation Updates:**
- README: Added policy-as-code and registry highlights
- README: Updated OpenTofu to 1.10/1.11 versions
- README: Added no-code provisioning patterns
- Command count: 17 → 19 total commands

### Version 1.5.0 (2025)

**Major New Features:**
- **OpenTofu Support**: Complete OpenTofu expertise and migration guidance
  - State encryption configuration and best practices
  - Loop-able import blocks (for_each in imports)
  - Early variable evaluation in terraform blocks
  - Migration paths and decision matrix
  - New skill: `opentofu-guide`
- **Testing Framework**: Comprehensive testing guidance
  - Terraform 1.6+ native test framework
  - Terratest integration testing
  - Unit, integration, and E2E testing patterns
  - TDD/BDD best practices
  - CI/CD test reporting (JUnit XML 1.11+)
  - New command: `/tf-test`

**Provider Updates:**
- **AWS 6.0 GA**: Multi-region support, bucket_region attribute, service deprecations
- **AzureRM 4.x**: Updated to latest stable (1,101+ resources, 360+ data sources)
- **Terraform 1.11+**: JUnit XML test output, write-only arguments

**Agent Enhancements:**
- Added OpenTofu expertise section (licensing, features, migration)
- Added comprehensive testing knowledge section
- Updated version-specific knowledge (Terraform 1.11+, OpenTofu 1.8+)
- AWS Provider 6.0 breaking changes documented
- Enhanced proactive behavior for testing and OpenTofu scenarios

**Documentation Updates:**
- README: Added OpenTofu section and testing highlights
- README: Updated provider versions and compatibility
- README: Added OpenTofu documentation resources
- Command count: 15 → 17 total commands

### Version 1.4.0 (2025)

**2025 Feature Updates:**
- **Terraform Stacks (GA)**: Production-ready with Linked Stacks
- **Module Lifecycle Management (GA)**: Revoke compromised modules
- **Linked Stacks**: Cross-stack dependencies with automatic triggers
- **HCP Terraform Enhancements**: Private VCS Access, HYOK documentation

### Version 1.3.0 (2025)

**2025 Feature Updates:**
- **Terraform 1.10+ Support**: Added ephemeral values and write-only arguments
- **Terraform 1.14+ Support**: Added terraform query command and Actions blocks
- **HCP Terraform 2025**: Terraform Stacks GA status, Linked Stacks, HYOK, Private VCS Access
- **Security Tool Updates**: Trivy replaces tfsec (merged), updated CI/CD examples
- **Provider Version Updates**: AzureRM 4.x, AWS 6.0 beta, GCP 6.x recommendations
- **NIST SP 800-53 Rev 5**: Added 350+ Sentinel policy documentation
- **Enhanced Security**: Checkov 750+ policies, Trivy unified scanning

**Agent Enhancements:**
- Updated version-specific knowledge through Terraform 1.14+
- Added HCP Terraform 2025 features section
- Added Terraform Stacks expertise
- Updated security scanning tools (Trivy focus)
- Enhanced proactive behavior for 2025 features

**Command Updates:**
- `/tf-stacks`: Updated with GA status and 2025 features
- `/tf-security`: Trivy integration, NIST policies, Private VCS Access
- All commands: Updated examples and best practices for 2025

### Version 1.2.0

**New Features:**
- `/tf-cli` command for comprehensive CLI reference
  - Complete guide to all Terraform CLI flags and options
  - **-chdir** usage and best practices
  - Environment variables (TF_LOG, TF_PLUGIN_CACHE_DIR, etc.)
  - Exit codes and CI/CD patterns
  - Platform-specific usage (Windows PowerShell, Linux/macOS Bash)
  - Advanced flag combinations
  - Performance optimization flags
- Enhanced terraform-expert agent with CLI mastery section
  - All command flags documented
  - Platform-specific examples
  - CI/CD optimization patterns
  - Best practices for flag usage

### Version 1.1.0

**New Features:**
- `/tf-import` command for importing existing resources
  - Traditional import commands
  - Import blocks (Terraform 1.5+)
  - Bulk import strategies (Terraformer, aztfexport, custom scripts)
  - Migration from manual deployments
- `/tf-state` command for comprehensive state management
  - State inspection (list, show, pull)
  - Moving resources (rename, refactor, module migrations)
  - Removing resources from state
  - State backup and recovery
  - State migration scenarios
- Enhanced terraform-expert agent with import and state expertise

### Version 1.0.0

- 12 specialized slash commands
- terraform-expert agent with comprehensive provider knowledge
- terraform-tasks skill for autonomous operations
- Multi-provider support (Azure, AWS, GCP, community)
- Platform-specific guidance (Windows, Linux, macOS)
- CI/CD integration
- Security scanning integration
- Enterprise architecture patterns

---

**Made with Claude Code**
