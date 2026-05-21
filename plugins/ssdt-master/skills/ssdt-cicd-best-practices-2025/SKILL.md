---
name: ssdt-cicd-best-practices-2025
description: |
  Modern SSDT CI/CD best practices for SQL Server database development (2025).
  PROACTIVELY activate for: (1) SSDT CI/CD pipeline design, (2) state-based deployment with DACPACs, (3) tSQLt unit testing integration, (4) database build validation in CI, (5) drift detection via SqlPackage Extract + Compare, (6) Azure DevOps and GitHub Actions templates for SSDT, (7) publish profile management per environment, (8) pre/post deploy scripts with idempotent MERGE, (9) DACPAC versioning and artifacts, (10) handling reference databases.
  Provides: end-to-end pipeline YAML for ADO and GHA, tSQLt setup, drift-detection scripts, and a publish-profile pattern for dev/test/prod.
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

# SSDT CI/CD Best Practices 2025

## Overview

This skill provides comprehensive guidance on implementing modern CI/CD pipelines for SQL Server database projects using SSDT, SqlPackage, and contemporary DevOps practices.

## Key Principles (2025 Recommended Approach)

### 1. State-Based Deployment (Recommended)

**Definition**: Source code represents the current database state, not migration scripts.

**How it Works**:
- All database objects (tables, procedures, views, functions) stored in separate .sql files
- SqlPackage automatically generates incremental deployment scripts
- Declarative approach: "This is what the database should look like"
- SSDT compares source to target and calculates differences

**Advantages**:
- Easier to maintain and understand
- No risk of missing migration scripts
- Git history shows complete object definitions
- Branching and merging simplified
- Rollback by redeploying previous version

**Implementation**:
```yaml
# GitHub Actions example
- name: Build DACPAC (State-Based)
  run: dotnet build Database.sqlproj -c Release

- name: Deploy State to Target
  run: |
    sqlpackage /Action:Publish \
      /SourceFile:Database.dacpac \
      /TargetConnectionString:"${{ secrets.SQL_CONN }}" \
      /p:BlockOnPossibleDataLoss=True
```

**Contrast with Migration-Based**:
- Migration-based: Sequential scripts (001_CreateTable.sql, 002_AddColumn.sql)
- State-based: Object definitions (Tables/Customer.sql contains complete CREATE TABLE)

### 2. tSQLt Unit Testing (Critical for CI/CD)

**Why tSQLt**:
- Open-source SQL Server unit testing framework
- Write tests in T-SQL language
- Produces machine-readable XML/JSON results
- Integrates seamlessly with CI/CD pipelines

**Key Features**:
- **Automatic Transactions**: Each test runs in a transaction and rolls back
- **Schema Grouping**: Group related tests in schemas
- **Mocking**: Fake tables and procedures for isolated testing
- **Assertions**: Built-in assertion methods (assertEquals, assertEmpty, etc.)

**Pipeline Abort on Failure**:
```yaml
# GitHub Actions with tSQLt
- name: Run tSQLt Unit Tests
  run: |
    # Deploy test framework
    sqlpackage /Action:Publish \
      /SourceFile:DatabaseTests.dacpac \
      /TargetConnectionString:"${{ secrets.TEST_SQL_CONN }}"

    # Execute tests and capture results
    sqlcmd -S test-server -d TestDB -Q "EXEC tSQLt.RunAll" -o test-results.txt

    # Parse results and fail pipeline if tests fail
    if grep -q "Failure" test-results.txt; then
      echo "Unit tests failed!"
      exit 1
    fi

    echo "All tests passed!"

- name: Deploy to Production (only runs if tests pass)
  run: |
    sqlpackage /Action:Publish \
      /SourceFile:Database.dacpac \
      /TargetConnectionString:"${{ secrets.PROD_SQL_CONN }}"
```

**Test Structure**:
```sql
-- tSQLt test example
CREATE SCHEMA CustomerTests;
GO

CREATE PROCEDURE CustomerTests.[test Customer Insert Sets Correct Defaults]
AS
BEGIN
    -- Arrange
    EXEC tSQLt.FakeTable 'dbo.Customers';

    -- Act
    INSERT INTO dbo.Customers (FirstName, LastName, Email)
    VALUES ('John', 'Doe', 'john@example.com');

    -- Assert
    EXEC tSQLt.AssertEquals @Expected = 1,
                             @Actual = (SELECT COUNT(*) FROM dbo.Customers);
    EXEC tSQLt.AssertNotEquals @Expected = NULL,
                                @Actual = (SELECT CreatedDate FROM dbo.Customers);
END;
GO

-- Run all tests
EXEC tSQLt.RunAll;
```

**Azure DevOps Integration**:
```yaml
- task: PowerShell@2
  displayName: 'Run tSQLt Tests'
  inputs:
    targetType: 'inline'
    script: |
      # Execute tSQLt tests
      $results = Invoke-Sqlcmd -ServerInstance $(testServer) `
                                -Database $(testDatabase) `
                                -Query "EXEC tSQLt.RunAll" `
                                -Verbose

      # Check for failures
      $failures = $results | Where-Object { $_.Class -eq 'Failure' }
      if ($failures) {
        Write-Error "Tests failed: $($failures.Count) failures"
        exit 1
      }
```

### 3. Windows Authentication Over SQL Authentication

**Security Best Practice**: Prefer Windows Authentication (Integrated Security) for CI/CD agents.

**Why Windows Auth**:
- No passwords stored in connection strings
- Leverages existing Active Directory infrastructure
- Service accounts with minimal permissions
- Audit trail via Windows Security logs
- No credential rotation needed

**Implementation**:

**Self-Hosted Agents (Recommended)**:
```yaml
# GitHub Actions with self-hosted Windows agent
runs-on: [self-hosted, windows, sql-deploy]

steps:
  - name: Deploy with Windows Auth
    run: |
      sqlpackage /Action:Publish \
        /SourceFile:Database.dacpac \
        /TargetConnectionString:"Server=prod-sql;Database=MyDB;Integrated Security=True;" \
        /p:BlockOnPossibleDataLoss=True
```

**Azure DevOps with Service Connection**:
```yaml
- task: SqlAzureDacpacDeployment@1
  inputs:
    authenticationType: 'integratedAuth'  # Uses Windows Auth
    serverName: 'prod-sql.domain.com'
    databaseName: 'MyDatabase'
    dacpacFile: '$(Build.ArtifactStagingDirectory)/Database.dacpac'
```

**Alternative for Cloud Agents (Azure SQL)**:
```yaml
# Use Managed Identity instead of SQL auth
- name: Deploy with Managed Identity
  run: |
    sqlpackage /Action:Publish \
      /SourceFile:Database.dacpac \
      /TargetConnectionString:"Server=tcp:server.database.windows.net;Database=MyDB;Authentication=ActiveDirectoryManagedIdentity;" \
      /p:BlockOnPossibleDataLoss=True
```

**Never Do This**:
```yaml
# BAD: Plain text SQL auth password
TargetConnectionString: "Server=prod;Database=MyDB;User=sa;Password=P@ssw0rd123"
```

**If SQL Auth Required**:
```yaml
# Use secrets/variables (least preferred method)
- name: Deploy with SQL Auth (Not Recommended)
  run: |
    sqlpackage /Action:Publish \
      /SourceFile:Database.dacpac \
      /TargetServerName:"${{ secrets.SQL_SERVER }}" \
      /TargetDatabaseName:"${{ secrets.SQL_DATABASE }}" \
      /TargetUser:"${{ secrets.SQL_USER }}" \
      /TargetPassword:"${{ secrets.SQL_PASSWORD }}" \
      /p:BlockOnPossibleDataLoss=True
  # Still not as secure as Windows Auth!
```

### 4. Version Control Everything

**What to Version**:
```text
DatabaseProject/
├── Tables/
│   ├── Customer.sql
│   └── Order.sql
├── StoredProcedures/
│   └── GetCustomerOrders.sql
├── Tests/
│   ├── CustomerTests/
│   │   └── test_CustomerInsert.sql
│   └── OrderTests/
│       └── test_OrderValidation.sql
├── Scripts/
│   ├── Script.PreDeployment.sql
│   └── Script.PostDeployment.sql
├── Database.sqlproj
├── Database.Dev.publish.xml
├── Database.Prod.publish.xml
└── .gitignore
```

**.gitignore**:
```text
# Build outputs
bin/
obj/
*.dacpac

# User-specific files
*.user
*.suo

# Visual Studio folders
.vs/

# Never commit credentials
*.publish.xml.user
```

**Check-in Requirements**:
- Require code review for database changes
- Mandate comments on all commits
- Run automated tests before merge
- Enforce naming conventions via branch policies

### 5. Deployment Reports Always Required

**Before Production Deployment**:
```yaml
- name: Generate Deployment Report
  run: |
    sqlpackage /Action:DeployReport \
      /SourceFile:Database.dacpac \
      /TargetConnectionString:"${{ secrets.PROD_SQL_CONN }}" \
      /OutputPath:deploy-report.xml \
      /p:BlockOnPossibleDataLoss=True

- name: Parse and Review Report
  run: |
    # Extract key metrics from XML
    echo "=== DEPLOYMENT REPORT ==="
    # Parse XML for operations count
    # Check for data loss warnings
    # Display to user or post to PR

- name: Require Manual Approval
  uses: trstringer/manual-approval@v1
  with:
    approvers: database-admins
    minimum-approvals: 1
    instructions: "Review deploy-report.xml before approving"

- name: Deploy After Approval
  run: |
    sqlpackage /Action:Publish \
      /SourceFile:Database.dacpac \
      /TargetConnectionString:"${{ secrets.PROD_SQL_CONN }}"
```

### 6. Environment Promotion Strategy

**Standard Flow**: Dev → QA → Staging → Production

**Consistent Deployment Options**:
```yaml
# Define environment-specific properties
environments:
  dev:
    blockOnDataLoss: false
    dropObjectsNotInSource: true
    backupBeforeChanges: false

  qa:
    blockOnDataLoss: true
    dropObjectsNotInSource: false
    backupBeforeChanges: true

  staging:
    blockOnDataLoss: true
    dropObjectsNotInSource: false
    backupBeforeChanges: true

  production:
    blockOnDataLoss: true
    dropObjectsNotInSource: false
    backupBeforeChanges: true
    requireApproval: true
```

## Complete CI/CD Pipelines (GitHub Actions + Azure DevOps)

Full working pipeline YAMLs for GitHub Actions and Azure DevOps Pipelines (DACPAC build, drift detection, deploy reports, environment promotion, SqlPackage publish, approval gates) live in `references/complete-pipelines.md`. Load that reference when wiring CI/CD for an SSDT project.

## Best Practices Checklist

### Source Control
- [ ] All database objects in source control
- [ ] .gitignore configured for build outputs
- [ ] No credentials committed
- [ ] Test scripts versioned separately
- [ ] Branching strategy defined (gitflow, trunk-based, etc.)

### Testing
- [ ] tSQLt framework deployed
- [ ] Unit tests cover critical stored procedures
- [ ] Tests grouped logically in schemas
- [ ] Pipeline aborts on test failure
- [ ] Test results published to dashboard

### Security
- [ ] Windows Authentication used for CI/CD
- [ ] Service accounts follow principle of least privilege
- [ ] Secrets stored in Azure Key Vault / GitHub Secrets
- [ ] No plain text passwords
- [ ] Audit logging enabled

### Deployment
- [ ] State-based deployment strategy
- [ ] Deployment reports generated before production
- [ ] Manual approval gates for production
- [ ] Backup before changes (production)
- [ ] BlockOnPossibleDataLoss enabled (production)
- [ ] DoNotDropObjectTypes configured
- [ ] Rollback plan documented

### Monitoring
- [ ] Deployment logs captured
- [ ] Failed deployments trigger alerts
- [ ] Performance metrics tracked
- [ ] Schema drift detection automated

## Resources

- [tSQLt Official Site](https://tsqlt.org/)
- [Microsoft.Build.Sql Documentation](https://learn.microsoft.com/sql/tools/sql-database-projects/)
- [SqlPackage Reference](https://learn.microsoft.com/sql/tools/sqlpackage/)
- [Azure DevOps SQL Tasks](https://learn.microsoft.com/azure/devops/pipelines/tasks/deploy/sql-azure-dacpac-deployment)
- [GitHub Actions for SQL](https://github.com/marketplace?type=actions&query=sql+)
