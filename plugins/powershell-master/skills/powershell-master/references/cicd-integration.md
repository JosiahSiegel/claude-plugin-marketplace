# PowerShell CI/CD Integration

Reference for GitHub Actions, Azure DevOps Pipelines, and Bitbucket Pipelines with PowerShell.

## GitHub Actions

```yaml
name: PowerShell CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install PowerShell modules
        shell: pwsh
        run: |
          Install-Module -Name Pester -Force -Scope CurrentUser
          Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser

      - name: Run Pester tests
        shell: pwsh
        run: |
          Invoke-Pester -Path ./tests -OutputFormat NUnitXml -OutputFile TestResults.xml

      - name: Run PSScriptAnalyzer
        shell: pwsh
        run: |
          Invoke-ScriptAnalyzer -Path . -Recurse -ReportSummary
```

### Multi-Platform Matrix

```yaml
jobs:
  test:
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - name: Test on ${{ matrix.os }}
        shell: pwsh
        run: |
          ./test-script.ps1
```

## Azure DevOps Pipelines

```yaml
trigger:
  - main

pool:
  vmImage: 'ubuntu-latest'

steps:
- task: PowerShell@2
  inputs:
    targetType: 'inline'
    script: |
      Install-Module -Name Pester -Force -Scope CurrentUser
      Invoke-Pester -Path ./tests -OutputFormat NUnitXml
  displayName: 'Run Pester Tests'

- task: PowerShell@2
  inputs:
    filePath: '$(System.DefaultWorkingDirectory)/build.ps1'
    arguments: '-Configuration Release'
  displayName: 'Run Build Script'

- task: PublishTestResults@2
  inputs:
    testResultsFormat: 'NUnit'
    testResultsFiles: '**/TestResults.xml'
```

### Cross-Platform Pipeline

```yaml
strategy:
  matrix:
    linux:
      imageName: 'ubuntu-latest'
    windows:
      imageName: 'windows-latest'
    mac:
      imageName: 'macos-latest'

pool:
  vmImage: $(imageName)

steps:
- pwsh: |
    Write-Host "Running on $($PSVersionTable.OS)"
    ./test-script.ps1
  displayName: 'Cross-platform test'
```

## Bitbucket Pipelines

```yaml
image: mcr.microsoft.com/powershell:latest

pipelines:
  default:
    - step:
        name: Test with PowerShell
        script:
          - pwsh -Command "Install-Module -Name Pester -Force"
          - pwsh -Command "Invoke-Pester -Path ./tests"

    - step:
        name: Deploy
        deployment: production
        script:
          - pwsh -File ./deploy.ps1
```
