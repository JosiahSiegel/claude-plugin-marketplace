# adf-master

Complete Azure Data Factory expertise system for ALL platforms, deployment methods, Microsoft Fabric integration, and ML/analytics orchestration (2025-2026).

## Overview

The **adf-master** plugin provides comprehensive Azure Data Factory expertise, covering everything from pipeline design to CI/CD automation. It includes both modern npm-based deployment approaches and traditional methods, ensuring you can work with any ADF setup.

## 🆕 What's New in 3.0.0 (2025 Update)

### 🚨 Critical Databricks Updates
- **Databricks Job activity** is now the ONLY recommended method (migrate from Notebook activities)
- **Serverless by default** - No cluster configuration needed in linked service
- **Advanced workflow features** - Run As, Task Values, If/Else tasks, AI/BI tasks, Repair Runs
- **Correct activity type** - `DatabricksJob` (fixed from incorrect `DatabricksSparkJob`)

### Connectors
- **ServiceNow V2** - V1 is End of Support, migration required
- **Microsoft Fabric Warehouse** - Native integration with Fabric data platform
- **Enhanced connectors** - PostgreSQL, Snowflake with improved performance

### 🔐 Security & Authentication
- **User-assigned managed identity** support for cross-factory scenarios
- **Credentials consolidation** - Centralized Microsoft Entra ID credential management
- **MFA enforced** - Since October 2025
- **Principle of least privilege** - Updated RBAC patterns

### 📦 Modern CI/CD Patterns
- **Latest npm utilities** - `@microsoft/azure-data-factory-utilities` with preview mode
- **Selective trigger management** - Only stop/start modified triggers with `--preview` flag
- **Updated workflows** - GitHub Actions and Azure DevOps 2025 templates

## Key Features

### 🛡️ **Comprehensive Validation & Edge-Case Handling**
- **STRICT activity nesting validation** - Prevents prohibited combinations (ForEach in If, nested ForEach, etc.)
- **Linked service validation** - Ensures required properties are set (e.g., accountKind for managed identity)
- **Resource limit enforcement** - Validates activity counts, ForEach batching, Lookup limits
- **Automatic violation detection** - Immediately identifies and rejects invalid configurations
- **Execute Pipeline workarounds** - Provides valid alternatives for complex nesting scenarios
- **Popular connector mastery** - Deep knowledge of Azure Blob Storage, SQL Database requirements and pitfalls

- **Microsoft Fabric Integration**: ADF mounting, cross-workspace orchestration, OneLake connectivity, Variable Libraries

### 🚀 CI/CD Automation
- **Modern Automated CI/CD** using `@microsoft/azure-data-factory-utilities` v1.0.3+
- **Traditional Manual CI/CD** with Git integration and publish button
- **GitHub Actions workflows** with complete templates
- **Azure DevOps pipelines** (YAML and classic)
- **ARM template deployment** with PowerShell and Azure CLI
- **PrePostDeploymentScript.Ver2** for intelligent trigger management

### 🔧 Pipeline Development with Validation
- **Validated pipeline design** following Microsoft best practices AND ADF limitations
- Data transformation patterns (SCD, incremental load, metadata-driven)
- Performance optimization strategies
- Error handling and retry logic
- Monitoring and logging patterns
- **ENFORCED Execute Pipeline pattern** for prohibited nesting scenarios

### 🐛 Troubleshooting & Debugging
- Systematic debugging approaches
- Common error patterns and solutions
- CI/CD deployment troubleshooting
- Performance analysis with Log Analytics queries
- Integration runtime issues

### 📊 Performance Optimization
- Copy activity optimization (DIUs, staging, partitioning)
- Data Flow performance tuning
- Cost reduction strategies
- Incremental load patterns
- Resource sizing guidance

## Installation

### Via Marketplace (Recommended)

```bash
# Add the marketplace
/plugin marketplace add JosiahSiegel/claude-plugin-marketplace

# Install the plugin
/plugin install adf-master@claude-plugin-marketplace
```

### Verify Installation

```bash
# See available commands
/help

# See available agents
/agents
```

## Commands

### `/adf-master:adf-validate`
Validate existing ADF pipeline JSON against activity nesting rules, resource limits, and best practices.

### `/adf-master:adf-create-pipeline`
Create ADF pipelines with strict validation enforcement — rejects prohibited nesting patterns and suggests Execute Pipeline workarounds.

### `/adf-master:adf-debug`
Debug ADF pipeline failures with systematic analysis, error pattern matching, and Log Analytics queries.

### `/adf-master:adf-expression`
Help with ADF expression language — functions, system variables, activity outputs, and dynamic content.

### `/adf-master:adf-linked-service`
Create and configure ADF linked service JSON with proper authentication and required properties.

## Agent

### `adf-expert`
Lean orchestrator agent that loads skills on demand. Covers all ADF operations with validation enforcement, ML orchestration, Fabric integration, and Databricks patterns.

## Skills

### `adf-master` Skill
Comprehensive knowledge base with:
- Official documentation sources and URLs
- CI/CD deployment methods (modern and traditional)
- npm package configuration
- PrePostDeploymentScript Ver2 details
- GitHub Actions and Azure DevOps resources
- ARM template deployment commands
- Troubleshooting resources and error patterns
- Best practices and repository structure

**How it helps:**
The skill provides detailed reference information that agents and commands can access on-demand, ensuring all guidance is based on the latest official documentation and proven patterns.

### `adf-validation-rules` Skill **[NEW]**
**Comprehensive validation rules and limitations enforcement:**

**Activity Nesting Rules:**
- ✅ Permitted combinations (ForEach→If, Until→Switch, etc.)
- ❌ Prohibited combinations (ForEach→ForEach, If→ForEach, Switch→If, etc.)
- 🔧 Execute Pipeline workarounds for all prohibited scenarios
- 🚫 Special restrictions (Validation activity, Set Variable in parallel ForEach)

**Linked Service Requirements:**
- **Azure Blob Storage**: Authentication methods, accountKind requirements, common pitfalls
- **Azure SQL Database**: Connection string parameters, authentication setup, serverless tier issues
- **All popular connectors**: Configuration requirements, edge cases, validation rules

**Resource Limits:**
- Activity limits (80 per pipeline - 2025 update)
- ForEach limits (50 concurrent iterations max)
- Lookup limits (5000 rows, 4 MB size)
- Data Flow limits (column names, row size, transformation limits)

**Validation Checklist:**
- Complete pre-creation validation checklist
- Linked service property verification
- Common error patterns and prevention

**How it helps:**
This skill is automatically consulted by agents and commands to ENFORCE Azure Data Factory limitations, preventing invalid configurations from being created. Ensures all pipelines comply with platform restrictions.

## Use Cases

### Creating a New Pipeline
```bash
/adf-master:adf-create-pipeline
```

### Validating Existing Pipelines
```bash
/adf-master:adf-validate
```

### Debugging a Failed Pipeline
```bash
/adf-master:adf-debug
```

### Working with Expressions
```bash
/adf-master:adf-expression
```

### Configuring Linked Services
```bash
/adf-master:adf-linked-service
```

## Best Practices

This plugin enforces Microsoft best practices **AND Azure Data Factory platform limitations**:

### 🚨 CRITICAL Validation Rules (ALWAYS ENFORCED)
1. **Activity Nesting Validation** - REJECT prohibited combinations (ForEach in If, nested ForEach, etc.)
2. **Linked Service Validation** - VERIFY required properties (accountKind for managed identity, etc.)
3. **Resource Limits** - ENFORCE activity count < 80, ForEach batchCount ≤ 50, Lookup < 5000 rows
4. **Variable Scope** - PREVENT Set Variable in parallel ForEach

### Standard Best Practices
5. **Parameterization** - Everything configurable should be parameterized
6. **Error Handling** - Comprehensive retry and logging
7. **Incremental Loads** - Avoid full refreshes
8. **Security** - Managed Identity and Key Vault for secrets
9. **Monitoring** - Log Analytics and alerts
10. **Testing** - Debug mode before production
11. **Git Configuration** - Only on development environment
12. **Modular Design** - Reusable child pipelines with **Execute Pipeline pattern**
13. **Modern CI/CD** - npm-based automated deployments
14. **Documentation** - Clear purpose and dependencies

**NEW:** All validation rules are automatically enforced - the plugin will REJECT invalid configurations before they're created!

## Documentation Sources

All guidance is based on:

- **Microsoft Learn:** https://learn.microsoft.com/en-us/azure/data-factory/
- **Context7 Library:** `/websites/learn_microsoft_en-us_azure_data-factory` (10,839 code snippets)
- **npm Package:** https://www.npmjs.com/package/@microsoft/azure-data-factory-utilities
- **PrePostDeploymentScript:** https://github.com/Azure/Azure-DataFactory/tree/main/SamplesV2/ContinuousIntegrationAndDelivery
- **Community Guides:** Medium, TechCommunity, blogs (2025 content)

## Requirements

### For CI/CD Setup:
- **Node.js:** Version 20.x or compatible
- **npm package:** `@microsoft/azure-data-factory-utilities` v1.0.3+
- **Azure CLI** or **PowerShell:** For ARM template deployment
- **GitHub** or **Azure DevOps:** For CI/CD pipelines
- **Azure permissions:** Contributor on Data Factory and Resource Group

### For General Use:
- Azure Data Factory resource (any tier)
- Access to Azure Portal or ADF Studio
- Appropriate RBAC permissions for your tasks

## Support

### Getting Help

If you encounter issues or have questions:

1. **Use the debug command:** `/adf-master:adf-debug`
2. **Check official documentation:** Microsoft Learn links in skill
3. **Community support:**
   - Microsoft Q&A: https://learn.microsoft.com/en-us/answers/tags/130/azure-data-factory
   - Stack Overflow: Tag `azure-data-factory`
4. **Azure Status:** https://status.azure.com (service outages)

### Filing Issues

For plugin-specific issues:
- Repository: https://github.com/JosiahSiegel/claude-plugin-marketplace
- Create an issue with:
  - Command or feature used
  - Expected vs actual behavior
  - Error messages (if any)
  - Your environment (Node.js version, platform, etc.)

## Windows & Git Bash Compatibility

Azure Data Factory development frequently occurs on Windows with Git Bash (MINGW64). This plugin includes comprehensive guidance for handling path conversion issues common in this environment.

### Quick Fix for Git Bash Path Errors

If npm build commands fail with path errors on Git Bash:

```bash
# Add to your .bashrc or run before ADF commands
export MSYS_NO_PATHCONV=1

# Then run your npm commands
npm run build validate ./adf-resources /subscriptions/.../myFactory
```

### Cross-Platform Features

- **Shell Detection**: Automatic detection of Git Bash, PowerShell, WSL, macOS, Linux
- **Path Conversion Handling**: MSYS_NO_PATHCONV guidance for Git Bash users
- **Cross-Platform Scripts**: PowerShell Core (pwsh) examples work on all platforms
- **CI/CD Compatibility**: GitHub Actions and Azure DevOps patterns tested on multiple shells

### Resources

- **New Skill**: `windows-git-bash-compatibility` - Comprehensive Windows/Git Bash guidance
- **Commands Updated**: All CI/CD commands include shell detection patterns
- **Troubleshooting**: Git Bash-specific issues and solutions documented

## Version History

### 3.3.0 (January 2025) **[WINDOWS/GIT BASH COMPATIBILITY UPDATE]**
- **🆕 NEW SKILL: windows-git-bash-compatibility**
  - Comprehensive Git Bash path conversion guidance for Windows developers
  - Shell detection patterns (Bash, PowerShell, Node.js)
  - MSYS_NO_PATHCONV usage and troubleshooting
  - Cross-platform CI/CD script examples
- **📝 ENHANCED CI/CD COMMANDS**
  - adf-cicd-setup: Added Git Bash path handling and shell detection
  - adf-arm-template: Cross-platform PowerShell script guidance
  - adf-troubleshoot: Windows Git Bash specific troubleshooting section
- **🔧 CI/CD IMPROVEMENTS**
  - Shell detection helpers for multi-platform teams
  - Node.js shell detection for npm scripts
  - Bash wrapper scripts for Git Bash compatibility
  - PowerShell Core (pwsh) cross-platform patterns
- **📚 COMPREHENSIVE DOCUMENTATION**
  - Windows developer workflow guidance
  - Git Bash (MINGW64) path conversion issues and solutions
  - WSL, PowerShell, and native shell compatibility
  - Local development script examples with shell detection

### 3.2.0 (January 2025) **[2025 FABRIC INTEGRATION UPDATE]**
- **🆕 NEW COMMAND: /adf-master:adf-fabric-integration**
  - ADF mounting in Fabric workspaces (GA)
  - Cross-workspace pipeline orchestration (Invoke Pipeline activity)
  - OneLake connectivity with Lakehouse and Warehouse connectors
  - Variable Libraries for environment-specific CI/CD
  - Migration strategies from ADF to Fabric
- **🚨 CRITICAL: Apache Airflow Deprecation**
  - Airflow Workflow Orchestration Manager deprecated (existing customers only)
  - Migration guidance to Fabric Data Factory or standalone Airflow
  - Action required: Plan migration within 12-18 months
- **📦 CI/CD UPDATES (2025)**
  - Node.js 20.x requirement for npm utilities
  - Updated GitHub Actions and Azure DevOps templates
  - Enhanced Variable Libraries support for multi-environment deployments
- **🆕 2025 CONNECTOR UPDATES**
  - ServiceNow V2 connector (V1 End of Support)
  - Enhanced PostgreSQL and Snowflake connectors
  - Native OneLake integration patterns
- **📚 COMPREHENSIVE DOCUMENTATION**
  - New fabric-integration command with mounting patterns
  - Cross-platform Invoke Pipeline examples
  - Variable Libraries implementation guide
  - Airflow deprecation and migration paths

### 3.1.0 (January 2025) **[2025 Updates]**
- **🆕 NEW COMMAND: /adf-master:adf-validate**
  - Standalone validation for existing pipelines
  - Comprehensive validation reports with actionable fixes
  - Pre-deployment compliance checking
- **🆕 MICROSOFT FABRIC INTEGRATION (2025)**
  - Fabric Lakehouse connector (tables and files)
  - Fabric Warehouse connector (T-SQL warehousing)
  - OneLake shortcuts for zero-copy data access
  - Cross-platform Invoke Pipeline activity (ADF ↔ Synapse ↔ Fabric)
- **✅ CORRECTED: Activity Limit Update**
  - Updated from 120 to 80 activities per pipeline (2025 platform limit)
  - All documentation and validation rules updated
- **🧹 OPTIMIZATION: 21% Content Reduction**
  - Removed duplicate pattern examples from agent
  - Consolidated validation guidance
  - Improved maintainability and clarity
- **📚 ENHANCED DOCUMENTATION**
  - New fabric-onelake-2025 skill with comprehensive Fabric integration
  - Invoke Pipeline cross-platform orchestration patterns
  - Updated connector references (ServiceNow V2, enhanced PostgreSQL)

### 3.0.0 (January 2025) **[MAJOR 2025 UPDATE]**
- **🚨 CRITICAL: Databricks Job Activity Updates**
  - Corrected activity type from `DatabricksSparkJob` to `DatabricksJob`
  - Added serverless execution guidance (no cluster config needed)
  - Documented advanced 2025 features: Run As, Task Values, If/Else, AI/BI Tasks, Repair Runs, DABs support
  - Migration urgency from legacy Notebook/Python/JAR activities
- **🆕 NEW CONNECTORS (2025)**
  - ServiceNow V2 connector (V1 End of Support - migration required)
  - Microsoft Fabric Warehouse connector (Q3 2024+)
  - Enhanced PostgreSQL and Snowflake connectors
- **🔐 MANAGED IDENTITY 2025 BEST PRACTICES**
  - User-assigned managed identity support and guidance
  - Credentials consolidation feature documentation
  - MFA enforcement compatibility (October 2025 requirement)
  - Principle of least privilege patterns
- **📦 CI/CD ENHANCEMENTS**
  - npm package `@microsoft/azure-data-factory-utilities` latest version patterns
  - Preview mode (`--preview`) for selective trigger management
  - Updated GitHub Actions and Azure DevOps examples
- **🧹 DEDUPLICATION AND OPTIMIZATION**
  - Removed redundant content across agents and skills
  - Consolidated Databricks guidance into single skill
  - Streamlined validation rules documentation
  - Updated all 2024 references to 2025

### 2.0.0 (January 2025)
- **NEW: Comprehensive validation and edge-case handling**
- **NEW: adf-validation-rules skill** with all ADF limitations
- **ENHANCED: Activity nesting validation** - Enforces ForEach, If, Switch, Until rules
- **ENHANCED: Linked service validation** - Azure Blob Storage, SQL Database requirements
- **ENHANCED: Resource limit enforcement** - Activity counts, ForEach batching, Lookup limits
- **ENHANCED: Execute Pipeline workarounds** - Automatic suggestions for prohibited nesting
- **ENHANCED: Common pitfall prevention** - accountKind, SAS expiry, connection pooling, etc.
- Updated all agents and commands with strict validation enforcement
- Comprehensive validation checklist for pipeline creation
- Detailed error messages with clear explanations and solutions

### 1.0.0 (January 2025)
- Initial release
- 6 comprehensive slash commands
- 2 specialized agents
- Complete skill with documentation sources
- Support for both modern and traditional CI/CD
- GitHub Actions and Azure DevOps templates
- ARM template deployment guidance
- Troubleshooting and optimization tools

## Contributing

Contributions welcome! Areas for enhancement:
- Additional pipeline patterns
- More CI/CD platform support (GitLab, Bitbucket)
- Advanced debugging techniques
- Performance benchmarks
- Cost optimization strategies

## License

MIT License - See LICENSE file for details.

## Author

**Josiah Siegel**
- Email: JosiahSiegel@users.noreply.github.com
- Marketplace: JosiahSiegel/claude-plugin-marketplace

## Acknowledgments

- Microsoft Azure Data Factory team for excellent documentation
- Community contributors to CI/CD patterns
- @microsoft/azure-data-factory-utilities package maintainers
- Azure Data Factory GitHub samples repository

---

**Ready to master Azure Data Factory? Install the plugin and start with:**

```bash
# Create a pipeline with validation
/adf-master:adf-create-pipeline

# Validate existing pipeline JSON
/adf-master:adf-validate

# Or just ask the adf-expert agent directly!
```
