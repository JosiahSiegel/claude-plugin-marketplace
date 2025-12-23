# PowerShell Master Plugin

Complete PowerShell expertise across all platforms (Windows, Linux, macOS) for scripting, automation, CI/CD, and cloud management.

## 🎯 What This Plugin Does

This plugin makes Claude a PowerShell expert with comprehensive 2025 knowledge:

- **PowerShell 7.5.4 / 7.6 Preview** - Latest features, .NET 9 performance, ConvertTo/From-CliXml
- **2025 Breaking Changes** - MSOnline/AzureAD retirement, PowerShell 2.0 removal, WMIC replacement
- **Modern Security** - JEA (Just Enough Administration), WDAC, Constrained Language Mode
- **PSResourceGet** - Modern package manager (2x faster than PowerShellGet)
- **Latest Modules** - Az 14.5.0, Microsoft.Graph 2.32.0, PnP, AWS Tools, Pester
- **Migration Guidance** - From deprecated modules to current 2025 standards
- **Cross-Platform** - Windows, Linux, macOS with .NET 9 performance
- **CI/CD Integration** - GitHub Actions, Azure DevOps, Bitbucket Pipelines

## 📦 Installation

### Via GitHub Marketplace (Recommended)

```bash
/plugin marketplace add JosiahSiegel/claude-plugin-marketplace
/plugin install powershell-master@claude-plugin-marketplace
```

### Local Installation (Mac/Linux)

⚠️ **Windows users:** Use the GitHub marketplace method instead.

```bash
# Extract to plugins directory
unzip powershell-master.zip -d ~/.local/share/claude/plugins/
```

## 🚀 Features

### Comprehensive PowerShell Knowledge

This plugin includes expert knowledge of:

1. **PowerShell Syntax & Cmdlets**
   - Full cmdlet reference
   - Operators and control flow
   - Functions and pipelines
   - Error handling patterns

2. **Cross-Platform Best Practices**
   - Path handling across OS
   - Platform detection
   - Text encoding (UTF-8)
   - Case sensitivity awareness
   - **NEW: Shell detection (PowerShell vs Git Bash/MSYS2)**
   - **NEW: Cross-shell compatibility guidance**

3. **Module Ecosystem**
   - **Azure (Az):** Complete Azure resource management
   - **Microsoft.Graph:** Microsoft 365, Teams, SharePoint
   - **PnP.PowerShell:** SharePoint Online automation
   - **AWS.Tools:** AWS resource management
   - **Pester:** Testing framework
   - **PSScriptAnalyzer:** Code quality analysis

4. **CI/CD Integration**
   - GitHub Actions workflows
   - Azure DevOps Pipelines
   - Bitbucket Pipelines
   - Cross-platform testing
   - Artifact publishing

5. **Security & Performance**
   - Credential management
   - Input validation
   - Performance optimization
   - Parallel execution (PS 7+)
   - Code signing

## 📋 Available Commands

### `/pwsh-script`
Create or review PowerShell scripts with best practices, error handling, and cross-platform compatibility.

**Example:**
```
/pwsh-script to backup files with retention policy
```

### `/pwsh-module`
Find, install, and manage PowerShell modules from PSGallery or other sources.

**Example:**
```
/pwsh-module to work with Azure VMs
```

### `/pwsh-cicd`
Set up PowerShell in CI/CD pipelines (GitHub Actions, Azure DevOps, Bitbucket).

**Example:**
```
/pwsh-cicd for cross-platform testing
```

### `/pwsh-azure`
Automate Azure resources using the Az PowerShell module.

**Example:**
```
/pwsh-azure to deploy virtual machines
```

### `/pwsh-performance` (NEW in v1.4.0)
Optimize PowerShell scripts for performance with parallel processing, efficient filtering, and .NET 9 enhancements.

**Example:**
```
/pwsh-performance to speed up file processing script
```

## 🤖 PowerShell Expert Agent

The plugin includes a specialized **powershell-expert** agent with comprehensive PowerShell knowledge.

**Automatically activates for:**
- Any PowerShell script creation or review
- Module discovery and management
- CI/CD pipeline setup
- Cloud automation (Azure/AWS/M365)
- Script debugging and optimization

**Invoke explicitly via Task tool:**
```
Use powershell-expert agent to create Azure automation script
```

## 💡 Usage Examples

### Example 1: Create Cross-Platform Script

**Request:** "Create a script to find large files"

**Result:** Production-ready script with:
- Cross-platform path handling
- Parameter validation
- Error handling
- Comment-based help
- Performance optimization

### Example 2: Azure Automation

**Request:** "Show me how to manage Azure VMs with PowerShell"

**Result:** Complete guide including:
- Az module installation
- Authentication methods
- VM operations (start/stop/create)
- Service principal setup for automation
- CI/CD integration examples

### Example 3: CI/CD Setup

**Request:** "Set up PowerShell testing in GitHub Actions"

**Result:** Full workflow with:
- Multi-platform matrix
- Pester test execution
- PSScriptAnalyzer code quality checks
- Test result publishing
- Module caching for speed

### Example 4: Module Discovery

**Request:** "I need to work with Microsoft Teams"

**Result:**
- Relevant modules identified (Microsoft.Graph)
- Installation instructions
- Common operations examples
- Authentication guidance
- Best practices for automation

## 🌐 Platform Support

- ✅ **Windows:** PowerShell 7+ and Windows PowerShell 5.1
- ✅ **Linux:** PowerShell 7+ (Ubuntu, RHEL, Debian, Alpine)
- ✅ **macOS:** PowerShell 7+ (Intel and Apple Silicon)

All examples and scripts are tested for cross-platform compatibility.

## 🔧 Common Use Cases

### Script Development
- Creating new PowerShell scripts
- Converting Windows PowerShell to PowerShell 7+
- Adding error handling and logging
- Performance optimization
- Code review and refactoring

### Module Management
- Finding modules on PSGallery
- Installing and updating modules
- Resolving version conflicts
- Creating custom modules
- Offline module installation

### Cloud Automation
- Azure resource deployment and management
- AWS infrastructure automation
- Microsoft 365 administration
- Multi-cloud orchestration
- Cost management and reporting

### CI/CD
- GitHub Actions workflows
- Azure DevOps Pipelines
- Bitbucket Pipelines
- Cross-platform testing
- Automated deployments

### DevOps
- Infrastructure as Code
- Configuration management
- Log analysis and monitoring
- Backup and recovery automation
- Security compliance checks

## 📚 Knowledge Base

The plugin includes comprehensive 2025 documentation on:

- **PowerShell 7.5.4 / 7.6 features** - ConvertTo/From-CliXml, Test-Path time filtering, .NET 9 performance
- **2025 Breaking Changes** - MSOnline/AzureAD retirement (March-May 2025), PowerShell 2.0 removal, WMIC replacement
- **Migration Paths** - Detailed guides for deprecated modules to current standards
- **Modern Security** - SecretManagement, JEA, WDAC, Constrained Language Mode, Script Block Logging
- **PSResourceGet 1.1.1** - Modern package management (2x faster), Azure Artifacts integration, SecretManagement
- **Performance Optimization** - ForEach-Object -Parallel, efficient filtering, .NET 9 enhancements
- **Latest Modules** - Az 14.5.0 (zone redundancy, symbolic links), Microsoft.Graph 2.32.0
- **CI/CD Patterns** - GitHub Actions, Azure DevOps, Bitbucket with latest practices
- **Cross-Platform** - Windows 11 24H2, Server 2025, Linux, macOS compatibility
- **Testing & Quality** - Pester, PSScriptAnalyzer with 2025 rules
- **NEW: Shell Detection** - PowerShell vs Git Bash/MSYS2 differentiation on Windows
- **NEW: Cross-Shell Compatibility** - Path handling, environment variables, command differences

## 🎓 Learning Resources

Claude will guide you through:
- PowerShell fundamentals
- Advanced scripting techniques
- Module development
- CI/CD best practices
- Cloud automation patterns
- Security considerations
- Performance tuning

And always refers to:
- Latest PowerShell documentation
- Module-specific documentation
- Platform-specific guides
- Community best practices

## ⚡ Quick Start

After installation, just ask Claude:

```
"Create a PowerShell script to..."
"How do I install the Az module?"
"Set up PowerShell in GitHub Actions"
"Automate Azure resource deployment"
"Find modules for Microsoft Teams"
```

The plugin will automatically activate and provide expert guidance with working examples.

## 🔍 Technical Details

**Plugin Name:** powershell-master
**Version:** 1.5.0
**Author:** Josiah Siegel
**License:** MIT
**Last Updated:** October 2025

**Components:**
- 5 comprehensive skills (powershell-master, powershell-7.5-features, powershell-2025-changes, powershell-security, powershell-shell-detection)
- 5 specialized commands
- 1 expert agent

**Supported PowerShell Versions:**
- PowerShell 7.5.4 (Stable, Recommended)
- PowerShell 7.6.0-preview.5 (Latest Preview)
- PowerShell 7.0+ (Supported)
- Windows PowerShell 5.1 (Legacy, limited support)

**Knowledge Currency:**
- PowerShell 7.5.4 stable / 7.6.0-preview.5 (October 2025)
- Az Module 14.5.0 (October 2025)
- Microsoft.Graph 2.32.0 (October 2025)
- PSResourceGet 1.1.0+ (October 2025)
- .NET 9.0.306 / 9.0.101
- 2025 breaking changes and migrations
- Modern security practices (JEA, WDAC)

## 🤝 Contributing

Contributions welcome! Areas for improvement:
- Additional command examples
- More module coverage
- Platform-specific optimizations
- CI/CD platform additions
- Best practice updates

## 🆘 Support

For help:
- Check the comprehensive skill documentation
- Review [official PowerShell docs](https://learn.microsoft.com/powershell)
- Visit [PowerShell Gallery](https://www.powershellgallery.com)
- Explore [PSGallery modules](https://www.powershellgallery.com/packages)

## 📄 License

MIT License - free to use, modify, and distribute.

## 🎓 Credits

Created by Josiah Siegel. Built on PowerShell best practices and community knowledge.

---

**Start automating with PowerShell today!** Install this plugin and unleash the power of cross-platform PowerShell scripting, automation, and cloud management.
