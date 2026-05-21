# Complete SSDT CI/CD Pipelines (GitHub Actions + Azure DevOps)

Full, working pipeline YAMLs for GitHub Actions and Azure DevOps Pipelines covering DACPAC build, drift detection, deploy reports, environment promotion, and SqlPackage publish. SKILL.md keeps the key principles, recommended approach, and best-practice checklist; this reference holds the assembled YAMLs.

## Complete GitHub Actions Pipeline (2025 Best Practice)

```yaml
name: SQL Server CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  DOTNET_VERSION: '8.0.x'
  SQLPACKAGE_VERSION: '170.2.70'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup .NET 8
        uses: actions/setup-dotnet@v4
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}

      - name: Install SqlPackage
        run: dotnet tool install -g Microsoft.SqlPackage --version ${{ env.SQLPACKAGE_VERSION }}

      - name: Build Database Project
        run: dotnet build src/Database.sqlproj -c Release

      - name: Build Test Project
        run: dotnet build tests/DatabaseTests.sqlproj -c Release

      - name: Upload DACPAC Artifacts
        uses: actions/upload-artifact@v4
        with:
          name: dacpacs
          path: |
            src/bin/Release/*.dacpac
            tests/bin/Release/*.dacpac

  test:
    runs-on: windows-latest  # tSQLt requires SQL Server
    needs: build
    steps:
      - uses: actions/checkout@v4

      - name: Download Artifacts
        uses: actions/download-artifact@v4
        with:
          name: dacpacs

      - name: Setup Test Database
        run: |
          sqlcmd -S localhost -Q "CREATE DATABASE TestDB"

      - name: Deploy Database to Test
        run: |
          sqlpackage /Action:Publish `
            /SourceFile:Database.dacpac `
            /TargetConnectionString:"Server=localhost;Database=TestDB;Integrated Security=True;"

      - name: Deploy tSQLt Framework
        run: |
          sqlpackage /Action:Publish `
            /SourceFile:DatabaseTests.dacpac `
            /TargetConnectionString:"Server=localhost;Database=TestDB;Integrated Security=True;"

      - name: Run tSQLt Unit Tests
        run: |
          $results = Invoke-Sqlcmd -ServerInstance localhost `
                                    -Database TestDB `
                                    -Query "EXEC tSQLt.RunAll" `
                                    -Verbose

          $failures = $results | Where-Object { $_.Class -eq 'Failure' }
          if ($failures) {
            Write-Error "Tests failed: $($failures.Count) failures"
            exit 1
          }
          Write-Host "All tests passed!"

  deploy-dev:
    runs-on: [self-hosted, windows, sql-deploy]
    needs: test
    if: github.ref == 'refs/heads/develop'
    environment: dev
    steps:
      - name: Download Artifacts
        uses: actions/download-artifact@v4
        with:
          name: dacpacs

      - name: Deploy to Dev (Windows Auth)
        run: |
          sqlpackage /Action:Publish `
            /SourceFile:Database.dacpac `
            /TargetConnectionString:"Server=dev-sql;Database=MyDB;Integrated Security=True;" `
            /p:BlockOnPossibleDataLoss=False `
            /p:DropObjectsNotInSource=True

  deploy-staging:
    runs-on: [self-hosted, windows, sql-deploy]
    needs: test
    if: github.ref == 'refs/heads/main'
    environment: staging
    steps:
      - name: Download Artifacts
        uses: actions/download-artifact@v4
        with:
          name: dacpacs

      - name: Generate Deployment Report
        run: |
          sqlpackage /Action:DeployReport `
            /SourceFile:Database.dacpac `
            /TargetConnectionString:"Server=staging-sql;Database=MyDB;Integrated Security=True;" `
            /OutputPath:deploy-report.xml

      - name: Deploy to Staging (Windows Auth)
        run: |
          sqlpackage /Action:Publish `
            /SourceFile:Database.dacpac `
            /TargetConnectionString:"Server=staging-sql;Database=MyDB;Integrated Security=True;" `
            /p:BlockOnPossibleDataLoss=True `
            /p:BackupDatabaseBeforeChanges=True `
            /p:DropObjectsNotInSource=False

  deploy-production:
    runs-on: [self-hosted, windows, sql-deploy]
    needs: deploy-staging
    environment: production
    steps:
      - name: Download Artifacts
        uses: actions/download-artifact@v4
        with:
          name: dacpacs

      - name: Generate Deployment Report
        run: |
          sqlpackage /Action:DeployReport `
            /SourceFile:Database.dacpac `
            /TargetConnectionString:"Server=prod-sql;Database=MyDB;Integrated Security=True;" `
            /OutputPath:prod-deploy-report.xml

      - name: Manual Approval Required
        uses: trstringer/manual-approval@v1
        with:
          approvers: database-admins,devops-leads
          minimum-approvals: 2
          instructions: "Review prod-deploy-report.xml and approve deployment"

      - name: Deploy to Production (Windows Auth)
        run: |
          sqlpackage /Action:Publish `
            /SourceFile:Database.dacpac `
            /TargetConnectionString:"Server=prod-sql;Database=MyDB;Integrated Security=True;" `
            /p:BlockOnPossibleDataLoss=True `
            /p:BackupDatabaseBeforeChanges=True `
            /p:DropObjectsNotInSource=False `
            /p:DoNotDropObjectTypes=Users;Logins;RoleMembership `
            /DiagnosticsFile:prod-deploy.log

      - name: Upload Deployment Logs
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: production-deployment-logs
          path: prod-deploy.log
```

## Azure DevOps Pipeline Example (2025)

```yaml
trigger:
  branches:
    include:
      - main
      - develop

pool:
  vmImage: 'windows-2022'

variables:
  buildConfiguration: 'Release'
  dotnetVersion: '8.0.x'
  sqlPackageVersion: '170.2.70'

stages:
- stage: Build
  jobs:
  - job: BuildDatabase
    steps:
    - task: UseDotNet@2
      displayName: 'Install .NET 8'
      inputs:
        version: $(dotnetVersion)

    - task: DotNetCoreCLI@2
      displayName: 'Build Database Project'
      inputs:
        command: 'build'
        projects: '**/*.sqlproj'
        arguments: '-c $(buildConfiguration)'

    - task: PublishBuildArtifacts@1
      displayName: 'Publish DACPAC'
      inputs:
        PathtoPublish: '$(Build.SourcesDirectory)/bin/$(buildConfiguration)'
        ArtifactName: 'dacpacs'

- stage: Test
  dependsOn: Build
  jobs:
  - job: RunUnitTests
    steps:
    - task: DownloadBuildArtifacts@1
      inputs:
        artifactName: 'dacpacs'

    - task: SqlAzureDacpacDeployment@1
      displayName: 'Deploy to Test Database'
      inputs:
        authenticationType: 'integratedAuth'
        serverName: 'test-sql-server'
        databaseName: 'TestDB'
        dacpacFile: '$(System.ArtifactsDirectory)/dacpacs/Database.dacpac'

    - task: PowerShell@2
      displayName: 'Run tSQLt Tests'
      inputs:
        targetType: 'inline'
        script: |
          $results = Invoke-Sqlcmd -ServerInstance 'test-sql-server' `
                                    -Database 'TestDB' `
                                    -Query "EXEC tSQLt.RunAll"

          $failures = $results | Where-Object { $_.Class -eq 'Failure' }
          if ($failures) {
            throw "Tests failed: $($failures.Count) failures"
          }

- stage: DeployProduction
  dependsOn: Test
  condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
  jobs:
  - deployment: DeployToProduction
    environment: 'Production'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: SqlAzureDacpacDeployment@1
            displayName: 'Generate Deployment Report'
            inputs:
              deployType: 'DeployReport'
              authenticationType: 'integratedAuth'
              serverName: 'prod-sql-server'
              databaseName: 'ProductionDB'
              dacpacFile: '$(Pipeline.Workspace)/dacpacs/Database.dacpac'
              outputFile: 'deploy-report.xml'

          - task: SqlAzureDacpacDeployment@1
            displayName: 'Deploy to Production'
            inputs:
              authenticationType: 'integratedAuth'
              serverName: 'prod-sql-server'
              databaseName: 'ProductionDB'
              dacpacFile: '$(Pipeline.Workspace)/dacpacs/Database.dacpac'
              additionalArguments: '/p:BlockOnPossibleDataLoss=True /p:BackupDatabaseBeforeChanges=True'
```

