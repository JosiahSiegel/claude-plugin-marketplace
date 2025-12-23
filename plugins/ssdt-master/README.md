# SSDT Master Plugin

Complete SQL Server Data Tools (SSDT) expertise with **SQL Server 2025 RC** and **SqlPackage 170.2.70** support. Enterprise database development with cutting-edge 2025 features, modern CI/CD patterns, and comprehensive tooling.

## Latest 2025 Updates

### Version 1.6.0 (October 2025) - Windows/Git Bash Path Handling
- **NEW: Git Bash/MINGW Path Support** - Comprehensive guidance for SqlPackage on Git Bash/MSYS2
- **Shell Detection** - Automatic detection and workarounds for Windows shell environments
- **MSYS_NO_PATHCONV** - Documented path conversion fixes for all SqlPackage actions
- **Double-Slash Method** - Shell-agnostic parameter syntax (//Action instead of /Action)
- **Cross-Platform Scripts** - Examples with shell detection and path handling
- **Enhanced Troubleshooting** - New section for Git Bash path issues in README
- **New Skill: windows-git-bash-paths** - Complete reference for path conversion
- **Updated Commands** - All SSDT commands now include Git Bash examples

### SQL Server 2025 RC1 Features (GA Predicted Nov 12, 2025)
- **Optional Parameter Plan Optimization (OPPO)** - Solves parameter sniffing issues for optimal plan selection
- **Microsoft Entra Managed Identities** - Improved credential management and security compliance
- **GraphQL Support** - Data API Builder (DAB) for exposing SQL Server data via GraphQL endpoints
- **Optimized Locking** - TID Locking & Lock After Qualification (LAQ) for enhanced concurrency
- **Fabric Mirroring** - Zero-ETL near real-time analytics with change feed technology
- **Native JSON** - New JSON data type with enhanced functions
- **RegEx Support** - REGEXP_LIKE, REGEXP_REPLACE, REGEXP_SUBSTR functions
- **REST API Integration** - sp_invoke_external_rest_endpoint for external data enrichment
- **Vector Database** - Native enterprise vector store with up to 3,996 dimensions
- **DiskANN Indexing** - Efficient large-scale vector search
- **AI Model Integration** - Built-in support for Azure OpenAI, Ollama, LangChain, Semantic Kernel, ONNX
- **Hybrid Search** - Combine vector similarity with traditional SQL queries
- **New Data Types** - VECTOR, JSON

### SqlPackage 170.2.70 (October 2025)
- **Data Virtualization** - Azure SQL Database external data source support
- **Parquet Files** - Azure Blob Storage integration with automatic BCP fallback
- **New Permissions** - ALTER ANY INFORMATION PROTECTION, ALTER ANY EXTERNAL MIRROR
- **Deployment Options** - IgnorePreDeployScript, IgnorePostDeployScript
- **Fabric Support** - Microsoft Fabric Data Warehouse deployment

### Microsoft.Build.Sql 2.0.0 GA (October 2025)
- **Production Ready** - General availability achieved, recommended for all new projects
- **.NET 8 Required** - Cross-platform support (Windows/Linux/macOS)
- **Visual Studio 2022 17.12+** - Full SDK-style project support
- **Automatic Globbing** - Enhanced file management for database objects
- **Next-Gen SQL Projects** - Future-proof format with improved CI/CD integration

### CI/CD Best Practices 2025
- **State-Based Deployment** - Source represents current state (NOT migration scripts)
- **tSQLt Unit Testing** - T-SQL unit tests with automatic rollback and pipeline abort on failure
- **Windows Authentication** - Preferred over SQL auth for CI/CD security (no passwords)
- **Deployment Reports Required** - Always generate before production push
- **Environment Promotion** - Dev → QA → Staging → Prod with gates

## Features

### Comprehensive SSDT Coverage

- **SDK-Style Projects** - Microsoft.Build.Sql 2.0.0 GA (production-ready)
- **Legacy Projects** - Traditional .sqlproj format support
- **All Build Methods** - dotnet CLI, MSBuild, Visual Studio, VS Code, Azure Data Studio
- **SqlPackage 170.2.70** - ALL 7 actions with complete 100+ deployment options
  - Extract, Publish, Export, Import, Script, DeployReport, DriftReport
  - Data virtualization and parquet file support
  - All connection methods (SQL Auth, Windows Auth, Azure AD, Managed Identity)
- **Schema Comparison** - Compare databases, DACPACs, generate update scripts, drift detection
- **Database Refactoring** - Safe rename, schema changes, data transformations
- **Visual Studio 2022** - SDK-style support (17.12+), table designer, T-SQL editor
- **CI/CD 2025 Patterns** - tSQLt unit testing, state-based deployment, Windows auth
- **Cross-Platform** - Windows, Linux, macOS (.NET 8+)

### Safety First

- Always prompts before destructive operations
- Generates deployment previews before publishing
- Warns about potential data loss
- Recommends backups for production changes
- Follows Microsoft best practices

### Latest Standards

- Always researches latest Microsoft documentation
- Supports newest Microsoft.Build.Sql SDK versions
- Follows current best practices
- Cross-platform compatibility guidance
- CI/CD integration patterns

## Installation

### Prerequisites

**Required for SQL Server 2025 & SDK-style projects:**
- **.NET 8.0 SDK or later** - `dotnet --version`
- **SqlPackage 170.2.70** - `dotnet tool install -g Microsoft.SqlPackage`

**Optional:**
- **Visual Studio 2022 (17.12+)** - For SDK-style project GUI support
- **Azure Data Studio** - SQL Database Projects extension
- **VS Code** - SQL Database Projects extension

### Quick Install (Recommended)

```bash
# Install from Claude Code Marketplace
claude-code plugins install ssdt-master
```

### Manual Install from GitHub

#### macOS/Linux

```bash
# Clone to plugins directory
git clone https://github.com/anthropics/claude-plugin-marketplace.git ~/tmp/marketplace
mkdir -p ~/.claude-code/plugins
cp -r ~/tmp/marketplace/ssdt-master ~/.claude-code/plugins/
rm -rf ~/tmp/marketplace
```

#### Windows (PowerShell)

```powershell
# Clone to plugins directory
git clone https://github.com/anthropics/claude-plugin-marketplace.git $env:TEMP\marketplace
New-Item -ItemType Directory -Force -Path "$env:APPDATA\Claude\plugins"
Copy-Item -Recurse "$env:TEMP\marketplace\ssdt-master" "$env:APPDATA\Claude\plugins\"
Remove-Item -Recurse -Force "$env:TEMP\marketplace"
```

### Verify Installation

```bash
# List installed plugins
claude-code plugins list

# You should see: ssdt-master
```

## Prerequisites

### Required Tools

Install based on your scenario:

#### For SDK-Style Projects (Cross-Platform)

```bash
# .NET 8.0 SDK or later
dotnet --version

# SqlPackage as .NET global tool
dotnet tool install -g Microsoft.SqlPackage
```

#### For Legacy Projects (Windows Only)

- Visual Studio 2022 with SQL Server Data Tools workload
- MSBuild (included with Visual Studio)
- SqlPackage.exe (included with SSDT)

#### Optional Tools

- **Visual Studio 2022** (17.12+) - Full SSDT features including SDK-style support
- **Azure Data Studio** - SQL Database Projects extension
- **VS Code** - SQL Database Projects extension

## Available Commands

### `/ssdt-master:build`

Build SQL Server database projects (SDK-style or legacy) following current best practices.

```bash
/ssdt-master:build
```

**Features:**
- Auto-detects project type (SDK-style vs legacy)
- Verifies prerequisites (.NET SDK, MSBuild)
- Checks dependencies and references
- Validates output DACPAC
- Reports warnings and suggestions

**Example:**
```
User: /ssdt-master:build
Claude: Found SDK-style project: MyDatabase.sqlproj
        Building with dotnet CLI...
        Build succeeded: bin/Debug/MyDatabase.dacpac (245 KB)
```

### `/ssdt-master:publish`

Publish DACPAC files to SQL Server databases with safety checks.

```bash
/ssdt-master:publish
```

**Features:**
- Locates DACPAC files automatically
- Generates deployment preview (DeployReport)
- Warns about data loss operations
- **Always asks for confirmation** before deployment
- Supports publish profiles
- Cross-platform compatible

**Example:**
```
User: /ssdt-master:publish
Claude: Found DACPAC: bin/Debug/MyDatabase.dacpac
        Target: localhost/MyDatabase

        Generating deployment preview...

        Changes:
        - Tables: 2 created, 1 altered
        - Stored Procedures: 3 created, 2 altered
        - WARNING: 1 column will be dropped (dbo.Customer.LegacyId)

        Proceed with deployment? (yes/no)
```

### `/ssdt-master:extract`

Extract DACPAC or BACPAC files from SQL Server databases.

```bash
/ssdt-master:extract
```

**Features:**
- Extracts DACPAC (schema only) or BACPAC (schema + data)
- Handles extraction errors gracefully
- Validates extracted files
- Cross-platform SqlPackage usage

**Example:**
```
User: /ssdt-master:extract
Claude: Extract DACPAC (schema only) or BACPAC (schema + data)?

User: DACPAC
Claude: Extracting from localhost/AdventureWorks...
        Created: AdventureWorks_Prod_1.0.0_20250123.dacpac (2.4 MB)
```

### `/ssdt-master:schema-compare`

Compare database schemas and generate update scripts.

```bash
/ssdt-master:schema-compare
```

**Features:**
- Compare DACPAC to DACPAC, DACPAC to database, or database to database
- Generate XML deployment reports
- Generate T-SQL update scripts
- Schema drift detection
- Configurable comparison options

**Example:**
```
User: /ssdt-master:schema-compare
Claude: Comparing source.dacpac to localhost/TargetDB...

        Differences found:
        - Tables: 3 new, 1 modified
        - Views: 2 modified
        - Stored Procedures: 5 new, 2 modified

        Generate update script? (yes/no)
```

### `/ssdt-master:migrate-sdk`

Migrate legacy SQL Server projects to SDK-style format.

```bash
/ssdt-master:migrate-sdk
```

**Features:**
- Backs up original project automatically
- Checks for SQLCLR compatibility
- Updates project file format
- Fixes property name changes
- Validates migration with build test
- Compares DACPAC output

**Example:**
```
User: /ssdt-master:migrate-sdk
Claude: Found legacy project: MyDatabase.sqlproj
        Checking for SQLCLR objects... None found

        Backing up to MyDatabase.sqlproj.original...
        Migrating to SDK-style (Microsoft.Build.Sql)...
        Testing build with dotnet CLI...

        Migration successful!
        Build output matches legacy version.
```

### `/ssdt-master:create-project`

Create new SQL Server database projects with proper structure.

```bash
/ssdt-master:create-project
```

**Features:**
- Creates SDK-style (recommended) or legacy projects
- Sets up proper directory structure
- Generates sample schema objects
- Creates pre/post deployment script templates
- Includes .gitignore and README
- Ready to build immediately

**Example:**
```
User: /ssdt-master:create-project
Claude: Project type: SDK-style (recommended) or legacy?

User: SDK-style
Claude: Creating SDK-style project "MyNewDatabase"...

        Created:
        ├── MyNewDatabase.sqlproj
        ├── dbo/Tables/
        ├── dbo/StoredProcedures/
        ├── Scripts/Script.PreDeployment.sql
        ├── Scripts/Script.PostDeployment.sql
        ├── .gitignore
        └── README.md

        Build with: dotnet build MyNewDatabase.sqlproj
```

### `/ssdt-master:analyze`

Analyze DACPAC files, projects, and databases for insights.

```bash
/ssdt-master:analyze
```

**Features:**
- DACPAC contents analysis
- Project file analysis
- Live database analysis
- Dependency detection
- Static code analysis
- Schema drift detection
- Performance analysis
- Security audit

**Example:**
```
User: /ssdt-master:analyze
Claude: Analyzing MyDatabase.dacpac...

        Database: MyDatabase v1.2.0
        Target: SQL Server 2022
        Size: 245 KB

        Schema Objects:
        - Tables: 15
        - Views: 8
        - Stored Procedures: 32
        - Functions: 6

        Findings:
        - 3 tables missing primary keys
        - 5 broken dependencies detected
        - 12 unused indexes (45 MB)

        Recommendations provided.
```

### `/ssdt-master:refactor`

Assist with database refactoring operations.

```bash
/ssdt-master:refactor
```

**Features:**
- Safe rename operations (tables, columns, procedures)
- Column type changes with data migration
- Table splitting and merging
- Add NOT NULL constraints safely
- Move objects between schemas
- Pre/post deployment script generation
- Rollback planning

**Example:**
```
User: /ssdt-master:refactor
Claude: What refactoring do you need?
        1. Rename object
        2. Change column type
        3. Split/merge tables
        4. Add constraints
        5. Move to different schema

User: 1
Claude: Rename table, column, procedure, or function?

User: column
Claude: Current name: OldColumnName
        New name: NewColumnName

        Generating pre-deployment script to preserve data...
        Updating all 15 references...
        Creating rollback plan...

        Ready to apply refactoring.
```

### `/ssdt-master:deployment-report`

Generate detailed deployment reports showing exactly what changes would be made before deploying.

```bash
/ssdt-master:deployment-report
```

**Features:**
- Generates XML deployment reports
- Identifies all schema changes (creates, alters, drops)
- Highlights data loss risks
- Compares DACPAC to database or DACPAC to DACPAC
- Schema drift detection
- Pre-deployment safety check

**Example:**
```
User: /ssdt-master:deployment-report
Claude: Generating deployment report for MyDB.dacpac → ProductionDB...

        Deployment Report Generated
        ===========================

        Total Operations: 47
        ├─ Creates: 15
        ├─ Alters: 22
        └─ Drops: 10

        ⚠️  DATA LOSS WARNINGS (3):
        1. CRITICAL: Dropping column [dbo].[Customer].[LegacyId]
        2. WARNING: Altering [dbo].[Order].[Total] may truncate data
        3. INFO: Dropping unused index [dbo].[IX_OldIndex]

        Report saved: deploy-report.xml

        Proceed with /ssdt-master:publish? (yes/no)
```

### `/ssdt-master:sqlpackage`

Complete SqlPackage reference with all actions and deployment options.

```bash
/ssdt-master:sqlpackage
```

**Features:**
- Master reference for ALL SqlPackage actions
- Complete list of deployment properties
- All 7 actions: Extract, Publish, Export, Import, Script, DeployReport, DriftReport
- Connection methods (SQL Auth, Windows Auth, Azure AD)
- Platform-specific guidance
- Advanced deployment scenarios
- Troubleshooting and error handling

**Example:**
```
User: /ssdt-master:sqlpackage
Claude: SqlPackage Expert - What do you need help with?

        Available Actions:
        1. Extract - Create DACPAC from database
        2. Publish - Deploy DACPAC to database
        3. Export - Create BACPAC with data
        4. Import - Restore BACPAC to database
        5. Script - Generate deployment script
        6. DeployReport - Generate deployment report
        7. DriftReport - Detect schema drift
        8. Show all deployment options
        9. Connection methods

User: 8
Claude: [Displays comprehensive list of all 100+ deployment options with descriptions]

        Critical Deployment Options:
        ============================

        Data Loss Prevention:
        • /p:BlockOnPossibleDataLoss=True
        • /p:BackupDatabaseBeforeChanges=True
        • /p:DropObjectsNotInSource=False

        [... complete reference ...]
```

## Agent: ssdt-expert

The `ssdt-expert` agent provides autonomous SSDT expertise for complex tasks.

### Capabilities

- **Autonomous Research** - Fetches latest Microsoft documentation when needed
- **Safety-First Approach** - Always prompts before destructive operations
- **Cross-Platform Awareness** - Detects OS and suggests appropriate tools
- **Best Practice Enforcement** - Follows Microsoft standards automatically
- **Comprehensive Knowledge** - All SSDT features, all platforms, all scenarios

### When It Activates

The agent automatically activates for:
1. ANY SSDT task (build/publish/extract/compare)
2. Database project creation or migration
3. Schema refactoring and changes
4. Deployment troubleshooting
5. Cross-platform guidance
6. CI/CD integration

### Example Usage

```
User: I need to deploy my database changes to production
Claude: [ssdt-expert agent activates]
        I'll help deploy safely. First, let me generate a deployment preview...

        [Analyzes project, generates DeployReport]

        Found 15 schema changes. WARNING: 2 operations may cause data loss:
        - Dropping column dbo.Customer.LegacyId
        - Changing type of dbo.Order.Total from DECIMAL(10,2) to DECIMAL(18,2)

        Recommendations:
        1. Backup production database first
        2. Review data in columns being modified
        3. Consider deploying during maintenance window

        Shall I proceed with generating a deployment script for review?
```

## Usage Examples

### Building a Database Project

```
User: Build my database project
Claude: [Scans directory for .sqlproj files]
        Found: MyDatabase.sqlproj (SDK-style)

        Prerequisites:
        ✓ .NET 8.0 SDK installed
        ✓ Microsoft.Build.Sql SDK referenced

        Building...
        dotnet build MyDatabase.sqlproj

        Build succeeded!
        Output: bin/Debug/MyDatabase.dacpac (2.4 MB)

        Ready to publish with /ssdt-master:publish
```

### Publishing to a Database

```
User: Publish to my local database
Claude: Generating deployment preview...

        Target: localhost/MyDatabase
        Source: bin/Debug/MyDatabase.dacpac

        Deployment Plan:
        ─────────────────
        CREATE dbo.Customer (table)
        CREATE dbo.Order (table)
        ALTER dbo.Product (add column UnitPrice)
        CREATE dbo.usp_GetCustomer (procedure)

        No data loss detected.

        Proceed? (yes/no)

User: yes
Claude: Publishing...
        sqlpackage /Action:Publish ...

        Deployment successful! ✓
        Duration: 2.3 seconds
```

### Schema Comparison

```
User: Compare my DACPAC to production
Claude: Extracting production schema...
        Comparing schemas...

        DRIFT DETECTED:

        Production has 3 objects NOT in source control:
        - dbo.TempTable (manual creation)
        - dbo.usp_DebugProc (ad-hoc procedure)
        - IX_Customer_Email (manual index)

        Source control has 2 objects NOT in production:
        - dbo.NewFeatureTable (not deployed yet)
        - dbo.usp_NewFeature (not deployed yet)

        Recommendation: Investigate manual changes in production.
        Generate script to add to source control? (yes/no)
```

### Creating a New Project

```
User: Create a new database project for CustomerDB
Claude: Creating SDK-style project "CustomerDB"...

        ├── CustomerDB.sqlproj
        ├── dbo/
        │   ├── Tables/
        │   ├── Views/
        │   ├── StoredProcedures/
        │   └── Functions/
        ├── Scripts/
        │   ├── Script.PreDeployment.sql
        │   └── Script.PostDeployment.sql
        ├── .gitignore
        └── README.md

        Added sample table: dbo/Tables/Customer.sql

        Build: dotnet build CustomerDB.sqlproj
        Publish: /ssdt-master:publish

        Project ready for development!
```

### Migrating to SDK-Style

```
User: Migrate my old project to SDK-style
Claude: Analyzing LegacyDatabase.sqlproj...
        Format: Legacy (MSBuild/SSDT)
        Target: SQL Server 2019

        Checking compatibility...
        ✓ No SQLCLR objects found
        ✓ No blocking issues detected

        Backing up original...
        Saved: LegacyDatabase.sqlproj.original

        Migrating...
        - Updated project element with SDK reference
        - Removed legacy import statements
        - Updated property names (AnsiPadding → AnsiPaddingOn)
        - Referenced Microsoft.Build.Sql 0.2.3

        Testing build...
        ✓ Build successful with dotnet CLI
        ✓ DACPAC output matches legacy version

        Migration complete! Project now cross-platform compatible.
```

## Best Practices

The plugin enforces Microsoft best practices:

### Project Organization
- ✓ Separate folders for Tables, Views, Procedures, Functions
- ✓ Pre/post deployment scripts for data operations
- ✓ SQLCMD variables for environment-specific values
- ✓ Publish profiles per environment

### Source Control
- ✓ Commit all .sql files
- ✓ Commit .sqlproj files
- ✓ .gitignore bin/ and obj/ directories
- ✓ Never commit credentials

### Deployment Safety
- ✓ Always preview changes (DeployReport/Script)
- ✓ Backup before production deployments
- ✓ Block on data loss for production
- ✓ Test in non-production first

### Cross-Platform
- ✓ Prefer SDK-style for new projects
- ✓ Use dotnet CLI for builds
- ✓ SqlPackage as .NET global tool
- ✓ Avoid Windows-only features

## Platform Support

| Platform | SDK-Style | Legacy | SqlPackage | Visual Studio |
|----------|-----------|---------|------------|---------------|
| Windows | ✓ | ✓ | ✓ | ✓ |
| Linux | ✓ | ✗ | ✓ | ✗ |
| macOS | ✓ | ✗ | ✓ | ✗ |
| Docker | ✓ | ✗ | ✓ | ✗ |

## Troubleshooting

### "SDK not found" Error

```bash
# Install Microsoft.Build.Sql SDK globally
dotnet workload install microsoft-sql-sdk

# Or add to project
dotnet add package Microsoft.Build.Sql
```

### "SqlPackage not found" Error

```bash
# Install as .NET global tool
dotnet tool install -g Microsoft.SqlPackage

# Verify installation
sqlpackage /version
```

### Git Bash / MINGW Path Issues on Windows

**Problem**: SqlPackage fails with "Invalid parameter" or "Unknown action" when using Git Bash on Windows.

**Cause**: Git Bash automatically converts paths starting with `/` (e.g., `/Action:Publish`) to Windows paths, breaking SqlPackage parameters.

**Solutions**:

**Option 1: Use PowerShell (Recommended)**
```powershell
# PowerShell - no path conversion issues
sqlpackage /Action:Publish /SourceFile:"MyDB.dacpac" /TargetServerName:"localhost" /TargetDatabaseName:"MyDB"
```

**Option 2: Disable Path Conversion in Git Bash**
```bash
# Set MSYS_NO_PATHCONV=1 before SqlPackage commands
MSYS_NO_PATHCONV=1 sqlpackage /Action:Publish \
  /SourceFile:"MyDB.dacpac" \
  /TargetServerName:"localhost" \
  /TargetDatabaseName:"MyDB"
```

**Option 3: Use Double Slashes**
```bash
# Use // instead of / (works in all shells)
sqlpackage //Action:Publish //SourceFile:MyDB.dacpac //TargetServerName:localhost //TargetDatabaseName:MyDB
```

**Shell Detection Script**:
```bash
#!/bin/bash
# Detect Git Bash and disable path conversion
if [ -n "$MSYSTEM" ]; then
  export MSYS_NO_PATHCONV=1
fi

# Now SqlPackage works correctly
sqlpackage /Action:Publish /SourceFile:"MyDB.dacpac" /TargetServerName:"localhost" /TargetDatabaseName:"MyDB"
```

**For comprehensive Git Bash guidance**, see plugin commands with examples:
- `/ssdt-master:build` - Build with shell detection
- `/ssdt-master:publish` - Publish with Git Bash workarounds
- `/ssdt-master:sqlpackage` - Complete SqlPackage reference with path handling

### Build Errors

```
User: Build is failing with "Cannot resolve reference"
Claude: Checking database references...

        Found reference: master.dacpac
        Path: C:\Program Files\...
        Status: NOT FOUND

        Options:
        1. Update reference path in .sqlproj
        2. Remove reference if not needed
        3. Download master.dacpac from SQL Server installation

        Which would you like to do?
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Database CI

on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup .NET
        uses: actions/setup-dotnet@v3
        with:
          dotnet-version: '8.0.x'

      - name: Build Database
        run: dotnet build MyDatabase.sqlproj

      - name: Publish DACPAC
        uses: actions/upload-artifact@v3
        with:
          name: dacpac
          path: bin/Debug/*.dacpac
```

### Azure DevOps Pipeline

```yaml
trigger:
  - main

pool:
  vmImage: 'ubuntu-latest'

steps:
  - task: UseDotNet@2
    inputs:
      version: '8.0.x'

  - task: DotNetCoreCLI@2
    displayName: 'Build Database Project'
    inputs:
      command: 'build'
      projects: '**/*.sqlproj'

  - task: PublishBuildArtifacts@1
    inputs:
      PathtoPublish: 'bin/Debug'
      ArtifactName: 'dacpac'
```

## Resources

### Official Microsoft Documentation
- [SQL Server Data Tools (SSDT)](https://learn.microsoft.com/sql/ssdt/)
- [SqlPackage](https://learn.microsoft.com/sql/tools/sqlpackage/)
- [SDK-Style Database Projects](https://learn.microsoft.com/sql/ssdt/sql-server-data-tools-sdk-style)
- [Microsoft.Build.Sql SDK](https://www.nuget.org/packages/Microsoft.Build.Sql)
- [DacFx GitHub](https://github.com/microsoft/DacFx)

### Community Resources
- [SSDT Blog Posts](https://devblogs.microsoft.com/ssdt/)
- [SQL Database Projects Extension](https://learn.microsoft.com/azure-data-studio/extensions/sql-database-project-extension)

## Contributing

Found an issue or have a suggestion?

1. Open an issue: [GitHub Issues](https://github.com/anthropics/claude-plugin-marketplace/issues)
2. Submit a pull request with improvements
3. Share your SSDT workflows and tips

## License

MIT License - See [LICENSE](../../LICENSE) file for details

## Support

- GitHub Issues: [claude-plugin-marketplace/issues](https://github.com/anthropics/claude-plugin-marketplace/issues)
- Claude Code Docs: [docs.claude.com](https://docs.claude.com)

---

**Made with ❤️ by the Claude Code Community**

Ensuring safe, efficient, and modern SQL Server database development across all platforms.
