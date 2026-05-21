---
name: sql-server-2025
description: |
  SQL Server 2025 and SqlPackage 170.2.70 (October 2025) — vector databases, AI integration, and modern features.
  PROACTIVELY activate for: (1) SQL Server 2025 features, (2) vector type and vector indexes for AI, (3) Vector functions (VECTOR_DISTANCE, etc.), (4) AI integration (Azure OpenAI, embeddings, RAG), (5) JSON type and JSON_ARRAYAGG, (6) parameter sensitivity plan optimization, (7) SqlPackage 170.2.70 new features and switches, (8) Always Encrypted with secure enclaves on 2025, (9) ledger tables, (10) Azure Arc-enabled SQL Server.
  Provides: SQL 2025 changelog, vector type usage, AI integration patterns, SqlPackage 170.2.70 reference, and migration guidance.
---

## 🚨 CRITICAL GUIDELINES

### Windows File Path Requirements

**MANDATORY: Always Use Backslashes on Windows for File Paths**

When using Edit or Write tools on Windows, you MUST use backslashes (`\`) in file paths, NOT forward slashes (`/`).

**Examples:**
- ❌ WRONG: `D:/repos/project/file.tsx`
- ✅ CORRECT: `D:\repos\project\file.tsx`

This applies to:
- Edit tool file_path parameter
- Write tool file_path parameter
- All file operations on Windows systems


### Documentation Guidelines

**NEVER create new documentation files unless explicitly requested by the user.**

- **Priority**: Update existing README.md files rather than creating new documentation
- **Repository cleanliness**: Keep repository root clean - only README.md unless user requests otherwise
- **Style**: Documentation should be concise, direct, and professional - avoid AI-generated tone
- **User preference**: Only create additional .md files when user specifically asks for documentation


---

# SQL Server 2025 & SqlPackage 170.2.70 Support

## Overview

**SQL Server 2025** is the enterprise AI-ready database with native vector database capabilities, built-in AI model integration, and semantic search from ground to cloud.

**SqlPackage 170.2.70** (October 14, 2025) - Latest production release with full SQL Server 2025 support, data virtualization, and parquet file enhancements.

## SqlPackage 170.x Series (2025 Releases)

### Latest Version: 170.2.70 (October 14, 2025)

Three major 2025 releases:
- **170.2.70** - October 14, 2025 (Current)
- **170.1.61** - July 30, 2025 (Data virtualization)
- **170.0.94** - April 15, 2025 (SQL Server 2025 initial support)

### Key 2025 Features

**Data Virtualization (170.1.61+)**:
- Support for Azure SQL Database data virtualization objects
- Import/export/extract/publish operations for external data sources
- Parquet file support for Azure SQL Database with Azure Blob Storage
- Automatic fallback to BCP for CLR types and LOBs > 1MB

**New Data Types**:
- **VECTOR** - Up to 3,996 dimensions with half-precision (2-byte) floating-point
- **JSON** - Native JSON data type for Azure SQL Database

**New Permissions (170.0+)**:
- `ALTER ANY INFORMATION PROTECTION` - SQL Server 2025 & Azure SQL
- `ALTER ANY EXTERNAL MIRROR` - Azure SQL & SQL database in Fabric
- `CREATE/ALTER ANY EXTERNAL MODEL` - AI/ML model management

**Deployment Options**:
- `/p:IgnorePreDeployScript=True/False` - Skip pre-deployment scripts
- `/p:IgnorePostDeployScript=True/False` - Skip post-deployment scripts

### SqlPackage Commands

```bash
# Publish to SQL Server 2025
sqlpackage /Action:Publish \
  /SourceFile:Database.dacpac \
  /TargetServerName:server2025.database.windows.net \
  /TargetDatabaseName:MyDatabase \
  /TargetDatabaseEdition:Premium \
  /p:TargetPlatform=SqlServer2025  # New target platform

# Extract from SQL Server 2025
sqlpackage /Action:Extract \
  /SourceServerName:server2025.database.windows.net \
  /SourceDatabaseName:MyDatabase \
  /TargetFile:Database.dacpac \
  /p:ExtractAllTableData=False \
  /p:VerifyExtraction=True

# Export with SQL Server 2025 features
sqlpackage /Action:Export \
  /SourceServerName:server2025.database.windows.net \
  /SourceDatabaseName:MyDatabase \
  /TargetFile:Database.bacpac
```

## ScriptDom Version 170.0.64

New ScriptDom version for SQL Server 2025 syntax parsing:

```csharp
// Package: Microsoft.SqlServer.TransactSql.ScriptDom 170.0.64

using Microsoft.SqlServer.TransactSql.ScriptDom;

// Parse SQL Server 2025 syntax
var parser = new TSql170Parser(true);
IList<ParseError> errors;
var fragment = parser.Parse(new StringReader(sql), out errors);

// Supports SQL Server 2025 new T-SQL features
```

## Microsoft.Build.Sql 2.0.0 GA (2025)

**MAJOR MILESTONE:** Microsoft.Build.Sql SDK entered General Availability in 2025!

### Latest Version: 2.0.0 (Production Ready)

**Breaking Change from Preview:**
- SDK is now production-ready and recommended for all new database projects
- No longer in preview status
- Full cross-platform support (Windows/Linux/macOS)
- Requires .NET 8+ (was .NET 6+ in preview)

### SQL Server 2025 Support

**Current Status:** SQL Server 2025 target platform support coming in future Microsoft.Build.Sql release (post-2.0.0).

**Workaround for SDK-Style Projects:**
```xml
<!-- Database.sqlproj (SDK-style with SQL Server 2025 compatibility) -->
<Project Sdk="Microsoft.Build.Sql/2.0.0">
  <PropertyGroup>
    <Name>MyDatabase</Name>
    <!-- Use SQL Server 2022 (160) provider until 2025 provider available -->
    <DSP>Microsoft.Data.Tools.Schema.Sql.Sql160DatabaseSchemaProvider</DSP>
    <TargetFramework>net8.0</TargetFramework>
    <SqlServerVersion>Sql160</SqlServerVersion>

    <!-- SQL Server 2025 features will still work in runtime database -->
    <!-- Only build-time validation uses Sql160 provider -->
  </PropertyGroup>

  <ItemGroup>
    <Folder Include="Tables\" />
    <Folder Include="Views\" />
    <Folder Include="StoredProcedures\" />
  </ItemGroup>
</Project>
```

### Visual Studio 2022 Support

**Requirement:** Visual Studio 2022 version 17.12 or later for SDK-style SQL projects.

**Note:** Side-by-side installation with original SQL projects (legacy SSDT) is NOT supported.

## SQL Server 2025 Release Status

**Current Status**: SQL Server 2025 (17.x) is in **Release Candidate (RC1)** stage as of October 2025. Public preview began May 2025.

**Predicted GA Date**: November 12, 2025 (based on historical release patterns - SQL Server 2019: Nov 4, SQL Server 2022: Nov 16). Expected announcement at Microsoft Ignite conference (November 18-21, 2025).

**Not Yet Production**: SQL Server 2025 is not yet generally available. All features described are available in RC builds for testing purposes only.

## SQL Server 2025 New Features

Full catalogue of engine features: native vector database (DiskANN indexing for AI / RAG workloads), JSON enhancements, regular expressions, fuzzy search, change event streaming, security and sensitivity classification, performance / Intelligent Query Processing additions, T-SQL improvements, and Always Encrypted updates lives in `references/sql-server-2025-features.md`. Load that reference when planning a 2025 upgrade or adopting any of those engine features in an SSDT project.

## Deployment to SQL Server 2025

### Using SqlPackage

```bash
# Publish with 2025 features
sqlpackage /Action:Publish \
  /SourceFile:Database.dacpac \
  /TargetConnectionString:"Server=tcp:server2025.database.windows.net;Database=MyDb;Authentication=ActiveDirectoryManagedIdentity;" \
  /p:BlockOnPossibleDataLoss=True \
  /p:IncludeCompositeObjects=True \
  /p:DropObjectsNotInSource=False \
  /p:DoNotDropObjectTypes=Users;RoleMembership \
  /p:GenerateSmartDefaults=True \
  /DiagnosticsFile:deploy.log
```

### Using MSBuild

```xml
<!-- Database.publish.xml -->
<Project>
  <PropertyGroup>
    <TargetConnectionString>Server=tcp:server2025.database.windows.net;Database=MyDb;Authentication=ActiveDirectoryManagedIdentity;</TargetConnectionString>
    <BlockOnPossibleDataLoss>True</BlockOnPossibleDataLoss>
    <TargetDatabaseName>MyDatabase</TargetDatabaseName>
    <ProfileVersionNumber>1</ProfileVersionNumber>
  </PropertyGroup>

  <ItemGroup>
    <SqlCmdVariable Include="Environment">
      <Value>Production</Value>
    </SqlCmdVariable>
  </ItemGroup>
</Project>
```

```bash
# Deploy using MSBuild
msbuild Database.sqlproj \
  /t:Publish \
  /p:PublishProfile=Database.publish.xml \
  /p:TargetPlatform=SqlServer2025
```

## CI/CD Best Practices 2025

### Key Principles

**State-Based Deployment (Recommended):**
- Source code represents current database state
- All objects (procedures, tables, triggers, views) in separate .sql files
- SqlPackage generates incremental scripts automatically
- Preferred over migration-based approaches

**Testing & Quality:**
- **tSQLt** - Unit testing for SQL Server stored procedures and functions
- Tests produce machine-readable results
- Abort pipeline on test failure with immediate notifications
- Never continue deployment if tests fail

**Security:**
- **Windows Authentication preferred** for CI/CD (avoid plain text passwords)
- Never commit credentials to source control
- Use Azure Key Vault or GitHub Secrets for connection strings

**Version Control:**
- All database objects in source control
- Test scripts versioned and executed in Build step
- Require comments on check-ins
- Configure custom check-in policies

### GitHub Actions (2025 Pattern)

```yaml
name: Deploy to SQL Server 2025

on:
  push:
    branches: [main]

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4

    - name: Setup .NET 8
      uses: actions/setup-dotnet@v4
      with:
        dotnet-version: '8.0.x'

    - name: Install SqlPackage 170.2.70
      run: dotnet tool install -g Microsoft.SqlPackage --version 170.2.70

    - name: Build DACPAC
      run: dotnet build Database.sqlproj -c Release

    - name: Run tSQLt Unit Tests
      run: |
        # Run unit tests and capture results
        # Abort if tests fail
        echo "Running tSQLt unit tests..."
        # Add your tSQLt test execution here

    - name: Generate Deployment Report
      run: |
        sqlpackage /Action:DeployReport \
          /SourceFile:bin/Release/Database.dacpac \
          /TargetConnectionString:"${{ secrets.SQL_CONNECTION_STRING }}" \
          /OutputPath:deploy-report.xml \
          /p:BlockOnPossibleDataLoss=True

    - name: Publish to SQL Server 2025
      run: |
        sqlpackage /Action:Publish \
          /SourceFile:bin/Release/Database.dacpac \
          /TargetConnectionString:"${{ secrets.SQL_CONNECTION_STRING }}" \
          /p:TargetPlatform=SqlServer2025 \
          /p:BlockOnPossibleDataLoss=True \
          /DiagnosticsFile:publish.log \
          /DiagnosticsLevel:Verbose

    - name: Upload Artifacts
      if: always()
      uses: actions/upload-artifact@v4
      with:
        name: deployment-logs
        path: |
          publish.log
          deploy-report.xml
```

### Azure DevOps

```yaml
trigger:
- main

pool:
  vmImage: 'windows-2022'

steps:
- task: MSBuild@1
  displayName: 'Build Database Project'
  inputs:
    solution: 'Database.sqlproj'
    configuration: 'Release'

- task: SqlAzureDacpacDeployment@1
  displayName: 'Deploy to SQL Server 2025'
  inputs:
    azureSubscription: 'Azure Subscription'
    authenticationType: 'servicePrincipal'
    serverName: 'server2025.database.windows.net'
    databaseName: 'MyDatabase'
    deployType: 'DacpacTask'
    deploymentAction: 'Publish'
    dacpacFile: '$(Build.SourcesDirectory)/bin/Release/Database.dacpac'
    additionalArguments: '/p:TargetPlatform=SqlServer2025'
```

## New SqlPackage Diagnostic Features

```bash
# Enable detailed diagnostics
sqlpackage /Action:Publish \
  /SourceFile:Database.dacpac \
  /TargetServerName:server2025.database.windows.net \
  /TargetDatabaseName:MyDatabase \
  /DiagnosticsLevel:Verbose \
  /DiagnosticPackageFile:diagnostics.zip

# Creates diagnostics.zip containing:
# - Deployment logs
# - Performance metrics
# - Error details
# - Schema comparison results
```

## Microsoft Fabric Data Warehouse Support

**New in SqlPackage 162.5+:** Full support for SQL database in Microsoft Fabric.

**Fabric Deployment:**
```bash
# Deploy to Fabric Warehouse
sqlpackage /Action:Publish \
  /SourceFile:Warehouse.dacpac \
  /TargetConnectionString:"Server=tcp:myworkspace.datawarehouse.fabric.microsoft.com;Database=mywarehouse;Authentication=ActiveDirectoryInteractive;" \
  /p:DatabaseEdition=Fabric \
  /p:DatabaseServiceObjective=SqlDbFabricDatabaseSchemaProvider

# Extract from Fabric
sqlpackage /Action:Extract \
  /SourceConnectionString:"Server=tcp:myworkspace.datawarehouse.fabric.microsoft.com;Database=mywarehouse;Authentication=ActiveDirectoryInteractive;" \
  /TargetFile:Fabric.dacpac

# New permission: ALTER ANY EXTERNAL MIRROR (Fabric-specific)
GRANT ALTER ANY EXTERNAL MIRROR TO [FabricAdmin];
```

## Best Practices for SQL Server 2025

1. **Use Target Platform Specification:**
```xml
<PropertyGroup>
  <TargetPlatform>SqlServer2025</TargetPlatform>
</PropertyGroup>
```

2. **Test Vector Operations:**
```sql
-- Verify vector support
SELECT SERVERPROPERTY('IsVectorSupported') AS VectorSupport;
```

3. **Monitor AI Model Performance:**
```sql
-- Track model execution
SELECT
    model_name,
    AVG(execution_time_ms) AS AvgExecutionTime,
    COUNT(*) AS ExecutionCount
FROM sys.dm_exec_external_model_stats
GROUP BY model_name;
```

4. **Implement Sensitivity Classification:**
```sql
-- Classify all PII columns
ADD SENSITIVITY CLASSIFICATION TO dbo.Customers.Email
WITH (LABEL = 'Confidential - GDPR', INFORMATION_TYPE = 'Email');
```

## Resources

- [SQL Server 2025 Preview](https://aka.ms/sqlserver2025)
- [SqlPackage Documentation](https://learn.microsoft.com/sql/tools/sqlpackage/)
- [SDK-Style Projects](https://learn.microsoft.com/sql/tools/sql-database-projects/concepts/sdk-style-projects)
- [Vector Database](https://learn.microsoft.com/sql/relational-databases/vectors/)
