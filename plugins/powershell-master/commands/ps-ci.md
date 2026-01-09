---
name: ps-ci
description: Generate CI/CD pipeline for PowerShell module (GitHub Actions, Azure DevOps, GitLab)
argument-hint: "<platform: github|azure|gitlab> [module path]"
allowed-tools:
  - Read
  - Write
  - Glob
---

# PowerShell CI/CD Pipeline Generator

Generate production-ready CI/CD pipelines for PowerShell modules.

## GitHub Actions Workflow

```yaml
# .github/workflows/ci.yml
name: PowerShell CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup PowerShell
        uses: actions/setup-powershell@v1
        with:
          pwsh-version: '7.5.x'

      - name: Install PSScriptAnalyzer
        shell: pwsh
        run: Install-PSResource -Name PSScriptAnalyzer -Scope CurrentUser -TrustRepository

      - name: Run PSScriptAnalyzer
        shell: pwsh
        run: |
          $results = Invoke-ScriptAnalyzer -Path . -Recurse -Settings PSScriptAnalyzerSettings.psd1
          $results | Format-Table -AutoSize
          if ($results | Where-Object Severity -eq 'Error') {
            throw "PSScriptAnalyzer found errors"
          }

  test:
    needs: lint
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        pwsh: ['7.4.x', '7.5.x']
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4

      - name: Setup PowerShell ${{ matrix.pwsh }}
        uses: actions/setup-powershell@v1
        with:
          pwsh-version: ${{ matrix.pwsh }}

      - name: Install Pester
        shell: pwsh
        run: Install-PSResource -Name Pester -Scope CurrentUser -TrustRepository

      - name: Run Tests
        shell: pwsh
        run: |
          $config = New-PesterConfiguration
          $config.Run.Path = "./Tests"
          $config.Run.Exit = $true
          $config.Output.Verbosity = "Detailed"
          $config.CodeCoverage.Enabled = $true
          $config.CodeCoverage.Path = @("./Public/*.ps1", "./Private/*.ps1")
          $config.CodeCoverage.OutputPath = "coverage.xml"
          $config.CodeCoverage.OutputFormat = "JaCoCo"
          $config.TestResult.Enabled = $true
          $config.TestResult.OutputPath = "testResults.xml"
          Invoke-Pester -Configuration $config

      - name: Upload Coverage
        uses: codecov/codecov-action@v4
        with:
          files: coverage.xml
          fail_ci_if_error: true

  publish:
    needs: test
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup PowerShell
        uses: actions/setup-powershell@v1
        with:
          pwsh-version: '7.5.x'

      - name: Publish to PSGallery
        shell: pwsh
        env:
          PSGALLERY_API_KEY: ${{ secrets.PSGALLERY_API_KEY }}
        run: |
          Install-PSResource -Name Microsoft.PowerShell.PSResourceGet -Scope CurrentUser -TrustRepository
          Publish-PSResource -Path ./ModuleName -Repository PSGallery -ApiKey $env:PSGALLERY_API_KEY
```

## Azure DevOps Pipeline

```yaml
# azure-pipelines.yml
trigger:
  branches:
    include:
      - main
      - develop

pool:
  vmImage: 'ubuntu-latest'

stages:
  - stage: Build
    jobs:
      - job: Lint
        steps:
          - task: PowerShell@2
            displayName: 'Install PSScriptAnalyzer'
            inputs:
              targetType: 'inline'
              script: Install-Module PSScriptAnalyzer -Force -SkipPublisherCheck
              pwsh: true

          - task: PowerShell@2
            displayName: 'Run PSScriptAnalyzer'
            inputs:
              targetType: 'inline'
              script: |
                $results = Invoke-ScriptAnalyzer -Path . -Recurse
                $results | Format-Table -AutoSize
                if ($results | Where-Object Severity -eq 'Error') {
                  throw "PSScriptAnalyzer found errors"
                }
              pwsh: true

  - stage: Test
    dependsOn: Build
    jobs:
      - job: Test
        strategy:
          matrix:
            Windows:
              vmImage: 'windows-latest'
            Linux:
              vmImage: 'ubuntu-latest'
            macOS:
              vmImage: 'macos-latest'
        pool:
          vmImage: $(vmImage)
        steps:
          - task: PowerShell@2
            displayName: 'Install Pester'
            inputs:
              targetType: 'inline'
              script: Install-Module Pester -Force -SkipPublisherCheck
              pwsh: true

          - task: PowerShell@2
            displayName: 'Run Pester Tests'
            inputs:
              targetType: 'inline'
              script: |
                $config = New-PesterConfiguration
                $config.Run.Path = "./Tests"
                $config.Run.Exit = $true
                $config.CodeCoverage.Enabled = $true
                $config.CodeCoverage.OutputPath = "$(Build.ArtifactStagingDirectory)/coverage.xml"
                $config.TestResult.Enabled = $true
                $config.TestResult.OutputPath = "$(Build.ArtifactStagingDirectory)/testResults.xml"
                $config.TestResult.OutputFormat = "NUnitXml"
                Invoke-Pester -Configuration $config
              pwsh: true

          - task: PublishTestResults@2
            inputs:
              testResultsFormat: 'NUnit'
              testResultsFiles: '$(Build.ArtifactStagingDirectory)/testResults.xml'

          - task: PublishCodeCoverageResults@2
            inputs:
              codeCoverageTool: 'JaCoCo'
              summaryFileLocation: '$(Build.ArtifactStagingDirectory)/coverage.xml'

  - stage: Publish
    dependsOn: Test
    condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
    jobs:
      - deployment: PublishPSGallery
        environment: 'production'
        strategy:
          runOnce:
            deploy:
              steps:
                - task: PowerShell@2
                  displayName: 'Publish to PSGallery'
                  inputs:
                    targetType: 'inline'
                    script: |
                      Publish-Module -Path ./ModuleName -NuGetApiKey $(PSGalleryApiKey)
                    pwsh: true
```

## GitLab CI Pipeline

```yaml
# .gitlab-ci.yml
stages:
  - lint
  - test
  - publish

variables:
  PWSH_VERSION: "7.5"

.pwsh_setup: &pwsh_setup
  before_script:
    - pwsh -Command "Install-PSResource -Name Pester, PSScriptAnalyzer -Scope CurrentUser -TrustRepository"

lint:
  stage: lint
  image: mcr.microsoft.com/powershell:${PWSH_VERSION}
  <<: *pwsh_setup
  script:
    - pwsh -Command |
        $results = Invoke-ScriptAnalyzer -Path . -Recurse
        $results | Format-Table -AutoSize
        if ($results | Where-Object Severity -eq 'Error') { exit 1 }

test:
  stage: test
  image: mcr.microsoft.com/powershell:${PWSH_VERSION}
  <<: *pwsh_setup
  script:
    - pwsh -Command |
        $config = New-PesterConfiguration
        $config.Run.Path = "./Tests"
        $config.CodeCoverage.Enabled = $true
        $config.CodeCoverage.OutputPath = "coverage.xml"
        $config.TestResult.Enabled = $true
        $config.TestResult.OutputPath = "testResults.xml"
        Invoke-Pester -Configuration $config
  artifacts:
    reports:
      junit: testResults.xml
      coverage_report:
        coverage_format: cobertura
        path: coverage.xml

publish:
  stage: publish
  image: mcr.microsoft.com/powershell:${PWSH_VERSION}
  only:
    - main
  script:
    - pwsh -Command "Publish-Module -Path ./ModuleName -NuGetApiKey $env:PSGALLERY_API_KEY"
```

## Pipeline Components

| Component | Purpose |
|-----------|---------|
| PSScriptAnalyzer | Static code analysis |
| Pester | Unit/integration tests |
| Code Coverage | Coverage reporting |
| Multi-platform | Windows, Linux, macOS testing |
| Multi-version | PowerShell 7.4, 7.5 testing |
| Publish | PSGallery deployment |
