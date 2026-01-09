---
name: ps-test
description: Run Pester tests for PowerShell scripts and modules with coverage
argument-hint: "<path to tests or module> [coverage threshold: 80]"
allowed-tools:
  - Read
  - Bash
  - Glob
  - Grep
---

# PowerShell Pester Test Runner

Run Pester tests with code coverage analysis.

## Quick Commands

```powershell
# Install latest Pester
Install-PSResource -Name Pester -Scope CurrentUser

# Run all tests in current directory
Invoke-Pester

# Run tests with verbose output
Invoke-Pester -Output Detailed

# Run specific test file
Invoke-Pester -Path "./Tests/MyFunction.Tests.ps1"

# Run tests matching pattern
Invoke-Pester -Path "./Tests" -TagFilter "Unit"

# Run with code coverage
Invoke-Pester -CodeCoverage "./Public/*.ps1" -CodeCoverageOutputFile "coverage.xml"
```

## Pester Configuration (Pester 5.x)

```powershell
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
$config.TestResult.OutputFormat = "NUnitXml"

Invoke-Pester -Configuration $config
```

## Test Structure Best Practices

```powershell
# MyFunction.Tests.ps1
BeforeAll {
    # Import module or dot-source function
    . $PSScriptRoot/../Public/MyFunction.ps1
}

Describe 'MyFunction' {
    BeforeEach {
        # Setup before each test
    }

    AfterEach {
        # Cleanup after each test
    }

    Context 'When given valid input' {
        It 'Should return expected result' {
            $result = MyFunction -Param "value"
            $result | Should -Be "expected"
        }

        It 'Should not throw' {
            { MyFunction -Param "value" } | Should -Not -Throw
        }
    }

    Context 'When given invalid input' {
        It 'Should throw for null input' {
            { MyFunction -Param $null } | Should -Throw
        }

        It 'Should throw specific error' {
            { MyFunction -Param "invalid" } | Should -Throw "*invalid*"
        }
    }

    Context 'With mocked dependencies' {
        BeforeAll {
            Mock Get-Something { return "mocked" }
        }

        It 'Should call Get-Something' {
            MyFunction -Param "test"
            Should -Invoke Get-Something -Times 1 -Exactly
        }
    }
}
```

## Common Assertions

```powershell
# Equality
$result | Should -Be "expected"
$result | Should -BeExactly "Expected"  # Case-sensitive
$result | Should -Not -Be "unexpected"

# Collections
$array | Should -Contain "item"
$array | Should -HaveCount 3
$array | Should -BeNullOrEmpty

# Types
$result | Should -BeOfType [string]
$result | Should -BeOfType [PSCustomObject]

# Strings
$result | Should -Match "pattern"
$result | Should -BeLike "*wildcard*"
$result | Should -BeNullOrEmpty

# Numbers
$result | Should -BeGreaterThan 5
$result | Should -BeLessThan 10
$result | Should -BeIn @(1, 2, 3)

# Booleans
$result | Should -BeTrue
$result | Should -BeFalse

# Exceptions
{ ThrowingFunction } | Should -Throw
{ ThrowingFunction } | Should -Throw "specific message"
{ ThrowingFunction } | Should -Throw -ExceptionType [System.ArgumentException]
```

## Coverage Thresholds

```powershell
$config = New-PesterConfiguration
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.CoveragePercentTarget = 80

$result = Invoke-Pester -Configuration $config -PassThru

if ($result.CodeCoverage.CoveragePercent -lt 80) {
    throw "Code coverage $($result.CodeCoverage.CoveragePercent)% is below 80% threshold"
}
```

## CI/CD Integration

### GitHub Actions

```yaml
- name: Run Pester Tests
  shell: pwsh
  run: |
    $config = New-PesterConfiguration
    $config.Run.Path = "./Tests"
    $config.Run.Exit = $true
    $config.CodeCoverage.Enabled = $true
    $config.CodeCoverage.OutputPath = "coverage.xml"
    $config.TestResult.Enabled = $true
    $config.TestResult.OutputPath = "testResults.xml"
    Invoke-Pester -Configuration $config
```

### Azure DevOps

```yaml
- task: PowerShell@2
  inputs:
    targetType: 'inline'
    script: |
      Install-Module Pester -Force -SkipPublisherCheck
      Invoke-Pester -OutputFile testResults.xml -OutputFormat NUnitXml -CodeCoverage ./src/*.ps1
    pwsh: true

- task: PublishTestResults@2
  inputs:
    testResultsFormat: 'NUnit'
    testResultsFiles: 'testResults.xml'
```

## Output Formats

| Format | Use Case | Flag |
|--------|----------|------|
| NUnitXml | Azure DevOps, Jenkins | `-OutputFormat NUnitXml` |
| JUnit | GitHub Actions, GitLab | `-OutputFormat JUnitXml` |
| JaCoCo | SonarQube coverage | `CodeCoverageOutputFormat = "JaCoCo"` |
| Cobertura | Codecov, Coveralls | `CodeCoverageOutputFormat = "Cobertura"` |
