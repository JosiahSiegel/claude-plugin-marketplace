# adf-master

Complete Azure Data Factory expertise system for ALL platforms, deployment methods, and Microsoft Fabric integration (2025).

## Overview

The **adf-master** plugin provides comprehensive Azure Data Factory expertise, covering everything from pipeline design to CI/CD automation. It includes both modern npm-based deployment approaches and traditional methods, ensuring you can work with any ADF setup.

## 🆕 What's New in 3.0.0 (2025 Update)

### 🚨 Critical Databricks Updates
- **Databricks Job activity** is now the ONLY recommended method (migrate from Notebook activities)
- **Serverless by default** - No cluster configuration needed in linked service
- **Advanced workflow features** - Run As, Task Values, If/Else tasks, AI/BI tasks, Repair Runs
- **Correct activity type** - `DatabricksJob` (fixed from incorrect `DatabricksSparkJob`)

### 🆕 New 2025 Connectors
- **ServiceNow V2** - V1 is End of Support, migration required
- **Microsoft Fabric Warehouse** - Native integration with Fabric data platform
- **Enhanced connectors** - PostgreSQL, Snowflake with improved performance

### 🔐 2025 Security & Authentication
- **User-assigned managed identity** support for cross-factory scenarios
- **Credentials consolidation** - Centralized Microsoft Entra ID credential management
- **MFA enforcement ready** - October 2025 compliance built-in
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

- **Microsoft Fabric Integration (2025)**: ADF mounting, cross-workspace orchestration, OneLake connectivity, Variable Libraries

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
/plugin marketplace add JosiahSiegel/claude-code-marketplace

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

### `/adf-master:adf-cicd-setup`
Interactive setup for Azure Data Factory CI/CD with GitHub Actions or Azure DevOps.

**What it does:**
- Assesses your current environment and requirements
- Generates complete CI/CD pipelines (build and deploy)
- Configures GitHub Actions workflows or Azure DevOps YAML pipelines
- Sets up PrePostDeploymentScript.Ver2 integration
- Guides you through secrets and variables configuration
- Provides testing and validation steps

**When to use:**
- Setting up CI/CD for the first time
- Migrating from traditional to modern CI/CD
- Adding new environments (test, production)
- Troubleshooting existing CI/CD pipelines

**Example usage:**
```
User: "Set up CI/CD for my Azure Data Factory using GitHub Actions"

Claude: I'll guide you through setting up modern automated CI/CD for Azure Data Factory using GitHub Actions...
[Provides complete workflow templates, secret configuration guide, and testing steps]
```

### `/adf-master:adf-validate`
Validate existing Azure Data Factory pipelines against activity nesting rules, resource limits, and best practices.

**What it does:**
- **VALIDATES existing pipeline JSON** without modifying it
- **CHECKS activity nesting** against permitted/prohibited combinations
- **VERIFIES resource limits** (activities, parameters, ForEach batching)
- **AUDITS linked services** for required properties
- **GENERATES comprehensive validation report** with issues and fixes
- **PROVIDES actionable recommendations** for each violation

**When to use:**
- Validating existing pipeline JSON before deployment
- Auditing pipelines for compliance with ADF limitations
- Troubleshooting why a pipeline design might fail
- Code review of ADF pipelines
- Pre-deployment validation checks

**Example usage:**
```
User: "Validate this pipeline JSON for any issues"

Claude: Let me validate your pipeline against ADF limitations...
[Provides detailed validation report with critical issues, warnings, and recommendations]
```

### `/adf-master:adf-pipeline-create`
Create Azure Data Factory pipelines following Microsoft best practices **with STRICT validation enforcement**.

**What it does:**
- **VALIDATES activity nesting** against ADF limitations BEFORE creation
- **REJECTS prohibited patterns** (ForEach in If, nested ForEach, etc.)
- **SUGGESTS Execute Pipeline workarounds** for complex nesting needs
- Designs pipeline architecture based on requirements
- Implements proper parameterization
- Adds error handling and retry logic
- Optimizes for performance
- Includes monitoring and logging
- **Provides ONLY valid, production-ready pipeline JSON**

**New Validation Features:**
- ✅ Activity nesting validation (ForEach, If, Switch, Until)
- ✅ Resource limit checks (activity count < 80, ForEach batchCount ≤ 50)
- ✅ Linked service property validation (accountKind, authentication requirements)
- ✅ Automatic detection of Set Variable in parallel ForEach
- ✅ Comprehensive validation checklist before finalization

**When to use:**
- Creating new pipelines from scratch
- Implementing common patterns (incremental load, SCD, metadata-driven)
- Need validation that pipeline structure is valid
- Want production-ready code with best practices
- Complex nesting requirements (automatically uses Execute Pipeline pattern)

**Example usage:**
```
User: "Create a pipeline with ForEach loop inside an If condition"

Claude: ❌ INVALID: If activities CANNOT contain ForEach activities.

✅ SOLUTION: Execute Pipeline pattern
[Provides parent pipeline with If calling Execute Pipeline, and child pipeline with ForEach]
This complies with ADF limitations while maintaining your logic.
```

### `/adf-master:adf-pipeline-debug`
Debug Azure Data Factory pipeline failures with systematic analysis.

**What it does:**
- Analyzes error messages and patterns
- Uses ADF monitoring tools for investigation
- Provides step-by-step debugging approach
- Offers solutions for common failure scenarios
- Generates Log Analytics queries for analysis
- Implements custom logging patterns

**When to use:**
- Pipeline is failing and you need to diagnose why
- Works in debug mode but fails when triggered
- Intermittent failures
- Performance degradation issues
- Need to set up better monitoring

**Example usage:**
```
User: "My copy activity is failing with 'OperationTimedOut' error"

Claude: Let's troubleshoot this timeout issue systematically...
[Analyzes timeout causes, suggests increasing timeout, optimizing source query, and checking network connectivity]
```

### `/adf-master:adf-arm-template`
Generate, validate, and deploy Azure Data Factory ARM templates using npm utilities.

**What it does:**
- Validates ADF resources before deployment
- Generates ARM templates using npm or UI
- Creates environment-specific parameter files
- Deploys using PowerShell or Azure CLI
- Integrates PrePostDeploymentScript
- Provides what-if analysis

**When to use:**
- Generating ARM templates for deployment
- Validating resources before publishing
- Creating parameter files for multiple environments
- Deploying to test or production
- Troubleshooting template deployment issues

**Example usage:**
```
User: "Generate and deploy ARM templates to my test environment"

Claude: I'll help you generate and deploy ARM templates...
[Provides npm commands for generation, parameter file creation, and PowerShell deployment script]
```

### `/adf-master:adf-troubleshoot`
Troubleshoot common Azure Data Factory CI/CD and runtime issues.

**What it does:**
- Diagnoses CI/CD build and deployment failures
- Troubleshoots npm validation errors
- Resolves ARM deployment issues
- Debugs PrePostDeploymentScript errors
- Fixes authentication and permission problems
- Analyzes performance issues

**When to use:**
- CI/CD pipeline is failing
- ARM template deployment errors
- GitHub Actions or Azure DevOps issues
- PrePostDeploymentScript errors
- Authentication failures
- Need Log Analytics queries for investigation

**Example usage:**
```
User: "My Azure DevOps pipeline is failing with 'Template parameters are not valid'"

Claude: This error typically occurs when a trigger was deleted in dev but the parameter still exists...
[Provides detailed troubleshooting steps and solutions]
```

### `/adf-master:adf-optimize`
Optimize Azure Data Factory pipelines for performance, cost, and efficiency.

**What it does:**
- Analyzes current performance metrics
- Optimizes copy activities (DIUs, staging, partitioning)
- Tunes data flow performance
- Reduces costs with incremental loads
- Right-sizes compute resources
- Provides baseline comparisons and ROI calculations

**When to use:**
- Pipelines are slow or timing out
- High Azure costs
- Need to improve performance
- Want to implement incremental loads
- Optimizing for specific data volumes

**Example usage:**
```
User: "My data flow is taking hours to complete and costing too much"

Claude: Let's optimize your data flow performance and cost...
[Analyzes compute sizing, partitioning strategy, and provides cost reduction recommendations]
```

## Agents

### `adf-expert` **[ENHANCED with Validation]**
Complete Azure Data Factory expertise across all operations **with STRICT validation enforcement**.

**Expertise:**
- **VALIDATION-FIRST** pipeline design and architecture
- **Activity nesting rules enforcement** (ForEach, If, Switch, Until)
- **Linked service configuration validation** (Blob Storage, SQL Database, etc.)
- Data transformation patterns
- Integration patterns (source-to-sink, real-time vs batch)
- Performance optimization
- Security and compliance
- All ADF components (linked services, datasets, activities, triggers, IRs)

**New Validation Capabilities:**
- ⚠️ **Immediately rejects** prohibited activity nesting combinations
- ⚠️ **Verifies** linked service properties match authentication requirements
- ⚠️ **Enforces** resource limits (activities, ForEach batching, Lookup size)
- ✅ **Suggests** Execute Pipeline workarounds for complex nesting
- ✅ **Validates** against common pitfalls (missing accountKind, expired SAS tokens, etc.)

**When activated:**
- Automatically when you work on ADF pipelines
- When you need design guidance with validation
- For complex transformation logic
- When implementing best practices
- **When creating ANY pipeline with control flow activities**

**Example:**
```
User: "Create nested ForEach loops to process files"

adf-expert: ❌ INVALID NESTING DETECTED
ForEach activities support only ONE level of nesting. Cannot nest ForEach within ForEach.

✅ SOLUTION: Execute Pipeline Pattern
[Provides validated solution with parent ForEach calling Execute Pipeline to child pipeline with inner ForEach]
```

### `adf-cicd-expert`
Complete Azure Data Factory CI/CD expertise.

**Expertise:**
- Modern automated CI/CD (@microsoft/azure-data-factory-utilities)
- Traditional manual CI/CD methods
- GitHub Actions workflows
- Azure DevOps pipelines
- ARM template deployment
- PrePostDeploymentScript
- Multi-environment strategies

**When activated:**
- Automatically when working on CI/CD setup
- For deployment automation
- When troubleshooting build/deploy failures
- For multi-environment configuration

**Example:**
```
User: "Set up automated deployment from GitHub to multiple environments"

adf-cicd-expert: I'll create a complete GitHub Actions workflow for multi-environment deployment...
[Provides build workflow, deployment workflow, environment configuration, and secret setup]
```

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

### Setting Up CI/CD for the First Time
```bash
# Use the interactive setup command
/adf-master:adf-cicd-setup
```
**Result:** Complete CI/CD pipelines generated for your platform (GitHub or Azure DevOps), with all configuration steps documented.

### Creating a New Pipeline
```bash
# Use the pipeline creation command
/adf-master:adf-pipeline-create
```
**Result:** Production-ready pipeline with parameterization, error handling, logging, and best practices.

### Debugging a Failed Pipeline
```bash
# Use the debugging command
/adf-master:adf-pipeline-debug
```
**Result:** Systematic diagnosis of the failure with specific solutions and monitoring recommendations.

### Optimizing Performance
```bash
# Use the optimization command
/adf-master:adf-optimize
```
**Result:** Performance improvements with measurable metrics and cost reduction strategies.

### Deploying to New Environment
```bash
# Use the ARM template command
/adf-master:adf-arm-template
```
**Result:** Generated templates, parameter files, and deployment scripts for your target environment.

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

1. **Use the troubleshooting command:** `/adf-master:adf-troubleshoot`
2. **Check official documentation:** Microsoft Learn links in skill
3. **Community support:**
   - Microsoft Q&A: https://learn.microsoft.com/en-us/answers/tags/130/azure-data-factory
   - Stack Overflow: Tag `azure-data-factory`
4. **Azure Status:** https://status.azure.com (service outages)

### Filing Issues

For plugin-specific issues:
- Repository: https://github.com/JosiahSiegel/claude-code-marketplace
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
  - ADF mounting in Fabric workspaces (GA June 2025 feature)
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
- Marketplace: JosiahSiegel/claude-code-marketplace

## Acknowledgments

- Microsoft Azure Data Factory team for excellent documentation
- Community contributors to CI/CD patterns
- @microsoft/azure-data-factory-utilities package maintainers
- Azure Data Factory GitHub samples repository

---

**Ready to master Azure Data Factory? Install the plugin and start with:**

```bash
# Interactive CI/CD setup
/adf-master:adf-cicd-setup

# Or create your first optimized pipeline
/adf-master:adf-pipeline-create

# Or get help with any ADF task
# The agents activate automatically!
```

**Happy data engineering! 🚀**
