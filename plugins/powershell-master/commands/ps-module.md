---
name: ps-module
description: Create a new PowerShell module with best practices structure
argument-hint: "<ModuleName> [type: script|binary|manifest]"
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
---

# PowerShell Module Generator

Create a production-ready PowerShell module with:
- Proper directory structure
- Module manifest (.psd1) with all metadata
- Root module (.psm1) with function organization
- Pester tests setup
- PSScriptAnalyzer configuration
- CI/CD pipeline templates

## Module Structure

```
ModuleName/
├── ModuleName.psd1          # Module manifest
├── ModuleName.psm1          # Root module
├── Public/                  # Exported functions
│   ├── Get-Something.ps1
│   └── Set-Something.ps1
├── Private/                 # Internal functions
│   └── Helper.ps1
├── Classes/                 # PowerShell classes (optional)
│   └── MyClass.ps1
├── Tests/
│   ├── ModuleName.Tests.ps1
│   └── Public/
│       └── Get-Something.Tests.ps1
├── .vscode/
│   └── settings.json
├── PSScriptAnalyzerSettings.psd1
├── build.ps1
└── README.md
```

## Module Manifest Template (.psd1)

```powershell
@{
    RootModule = 'ModuleName.psm1'
    ModuleVersion = '1.0.0'
    GUID = '<generated-guid>'
    Author = '<author>'
    CompanyName = '<company>'
    Copyright = '(c) 2025 <author>. All rights reserved.'
    Description = '<description>'
    PowerShellVersion = '7.0'
    CompatiblePSEditions = @('Core', 'Desktop')
    FunctionsToExport = @('Get-Something', 'Set-Something')
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('tag1', 'tag2')
            LicenseUri = 'https://github.com/user/repo/blob/main/LICENSE'
            ProjectUri = 'https://github.com/user/repo'
            ReleaseNotes = 'Initial release'
            Prerelease = ''
        }
    }
}
```

## Root Module Template (.psm1)

```powershell
#Requires -Version 7.0

# Get public and private function files
$Public = @(Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1" -ErrorAction SilentlyContinue)
$Private = @(Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" -ErrorAction SilentlyContinue)

# Dot source the files
foreach ($import in @($Public + $Private)) {
    try {
        . $import.FullName
    } catch {
        Write-Error "Failed to import function $($import.FullName): $_"
    }
}

# Export public functions
Export-ModuleMember -Function $Public.BaseName
```

## Function Template

```powershell
function Get-Something {
    <#
    .SYNOPSIS
        Brief description of the function.

    .DESCRIPTION
        Detailed description of the function.

    .PARAMETER Name
        Description of the Name parameter.

    .EXAMPLE
        Get-Something -Name "Example"
        Description of what this example does.

    .OUTPUTS
        System.String

    .NOTES
        Author: Your Name
        Version: 1.0.0
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    begin {
        # Initialization code
    }

    process {
        # Main logic
        Write-Output "Processing: $Name"
    }

    end {
        # Cleanup code
    }
}
```

## PSScriptAnalyzer Settings

```powershell
# PSScriptAnalyzerSettings.psd1
@{
    Severity = @('Error', 'Warning', 'Information')
    ExcludeRules = @()
    IncludeDefaultRules = $true
    Rules = @{
        PSUseCompatibleSyntax = @{
            Enable = $true
            TargetVersions = @('7.0', '5.1')
        }
        PSUseCompatibleCommands = @{
            Enable = $true
            TargetProfiles = @(
                'win-48_x64_10.0.17763.0_7.0.0_x64_4.0.30319.42000_core'
                'win-8_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework'
            )
        }
    }
}
```

## Pester Test Template

```powershell
BeforeAll {
    $ModulePath = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    Import-Module "$ModulePath\ModuleName.psd1" -Force
}

Describe 'Get-Something' {
    Context 'When called with valid input' {
        It 'Should return expected output' {
            $result = Get-Something -Name 'Test'
            $result | Should -Be 'Processing: Test'
        }
    }

    Context 'When called with pipeline input' {
        It 'Should process multiple items' {
            $result = @('A', 'B', 'C') | Get-Something
            $result | Should -HaveCount 3
        }
    }
}
```
