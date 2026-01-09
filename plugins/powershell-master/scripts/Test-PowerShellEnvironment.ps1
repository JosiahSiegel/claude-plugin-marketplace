#Requires -Version 5.1
<#
.SYNOPSIS
    Test PowerShell environment and report version, features, and compatibility.

.DESCRIPTION
    Comprehensive PowerShell environment diagnostic script that checks:
    - PowerShell version and edition
    - .NET runtime version
    - Available experimental features
    - Module availability (PSResourceGet, SecretManagement)
    - 2025 deprecation warnings (MSOnline, AzureAD)
    - Cross-platform compatibility

.EXAMPLE
    ./Test-PowerShellEnvironment.ps1
    Run full environment check.

.EXAMPLE
    ./Test-PowerShellEnvironment.ps1 -IncludeModules
    Include detailed module analysis.

.OUTPUTS
    PSCustomObject with environment details.
#>

[CmdletBinding()]
param(
    [switch]$IncludeModules,
    [switch]$JsonOutput
)

function Get-EnvironmentInfo {
    $info = [ordered]@{
        # PowerShell Version
        PSVersion = $PSVersionTable.PSVersion.ToString()
        PSEdition = $PSVersionTable.PSEdition
        PSCompatibleVersions = $PSVersionTable.PSCompatibleVersions -join ", "

        # .NET Runtime
        DotNetVersion = [System.Runtime.InteropServices.RuntimeInformation]::FrameworkDescription

        # Platform
        OS = [System.Runtime.InteropServices.RuntimeInformation]::OSDescription
        Platform = if ($IsWindows) { "Windows" } elseif ($IsLinux) { "Linux" } elseif ($IsMacOS) { "macOS" } else { "Unknown" }
        Architecture = [System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture

        # Feature Detection
        Is75OrHigher = $PSVersionTable.PSVersion.Major -eq 7 -and $PSVersionTable.PSVersion.Minor -ge 5
        Is76OrHigher = $PSVersionTable.PSVersion.Major -eq 7 -and $PSVersionTable.PSVersion.Minor -ge 6
        IsPreview = $PSVersionTable.PSVersion.PreReleaseLabel -ne $null
        IsCoreCLR = $PSVersionTable.PSEdition -eq "Core"
    }

    [PSCustomObject]$info
}

function Get-ModuleStatus {
    $modules = @{
        # Modern PowerShell Modules
        "Microsoft.PowerShell.PSResourceGet" = @{ Required = $true; Purpose = "Modern package management" }
        "Microsoft.PowerShell.SecretManagement" = @{ Required = $true; Purpose = "Secure credential storage" }
        "Microsoft.PowerShell.SecretStore" = @{ Required = $false; Purpose = "Local secret vault" }
        "Pester" = @{ Required = $false; Purpose = "Testing framework" }
        "PSScriptAnalyzer" = @{ Required = $false; Purpose = "Static code analysis" }

        # Deprecated Modules (2025)
        "MSOnline" = @{ Required = $false; Purpose = "DEPRECATED - Use Microsoft.Graph"; Deprecated = $true }
        "AzureAD" = @{ Required = $false; Purpose = "DEPRECATED - Use Microsoft.Graph"; Deprecated = $true }
        "AzureADPreview" = @{ Required = $false; Purpose = "DEPRECATED - Use Microsoft.Graph"; Deprecated = $true }

        # Microsoft Graph
        "Microsoft.Graph" = @{ Required = $false; Purpose = "Microsoft Graph SDK (replaces MSOnline/AzureAD)" }
        "Microsoft.Graph.Authentication" = @{ Required = $false; Purpose = "Graph authentication" }
    }

    $results = foreach ($moduleName in $modules.Keys) {
        $config = $modules[$moduleName]
        $installed = Get-Module -Name $moduleName -ListAvailable -ErrorAction SilentlyContinue

        [PSCustomObject]@{
            Module = $moduleName
            Installed = $null -ne $installed
            Version = if ($installed) { ($installed | Select-Object -First 1).Version.ToString() } else { "N/A" }
            Purpose = $config.Purpose
            Deprecated = $config.Deprecated -eq $true
            Required = $config.Required
        }
    }

    $results
}

function Get-FeatureAvailability {
    $features = @(
        @{ Name = "ConvertTo-CliXml"; MinVersion = "7.5"; Check = { Get-Command ConvertTo-CliXml -ErrorAction SilentlyContinue } }
        @{ Name = "ConvertFrom-CliXml"; MinVersion = "7.5"; Check = { Get-Command ConvertFrom-CliXml -ErrorAction SilentlyContinue } }
        @{ Name = "Test-Path -OlderThan"; MinVersion = "7.5"; Check = { (Get-Command Test-Path).Parameters.ContainsKey('OlderThan') } }
        @{ Name = "+= Optimization"; MinVersion = "7.6"; Check = { $PSVersionTable.PSVersion.Minor -ge 6 } }
        @{ Name = "Get-Clipboard -Delimiter"; MinVersion = "7.6"; Check = { $PSVersionTable.PSVersion.Minor -ge 6 } }
        @{ Name = "Get-Command -ExcludeModule"; MinVersion = "7.6"; Check = { $PSVersionTable.PSVersion.Minor -ge 6 } }
    )

    foreach ($feature in $features) {
        $available = try { & $feature.Check } catch { $false }
        [PSCustomObject]@{
            Feature = $feature.Name
            MinVersion = $feature.MinVersion
            Available = $available
        }
    }
}

function Get-DeprecationWarnings {
    $warnings = @()

    # Check for MSOnline module
    if (Get-Module -Name MSOnline -ListAvailable -ErrorAction SilentlyContinue) {
        $warnings += [PSCustomObject]@{
            Type = "Module Deprecation"
            Item = "MSOnline"
            Warning = "MSOnline module was retired March 2025. Migrate to Microsoft.Graph"
            Action = "Install-PSResource -Name Microsoft.Graph.Users"
        }
    }

    # Check for AzureAD module
    if (Get-Module -Name AzureAD -ListAvailable -ErrorAction SilentlyContinue) {
        $warnings += [PSCustomObject]@{
            Type = "Module Deprecation"
            Item = "AzureAD"
            Warning = "AzureAD module was retired May 2025. Migrate to Microsoft.Graph"
            Action = "Install-PSResource -Name Microsoft.Graph"
        }
    }

    # Check PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        $warnings += [PSCustomObject]@{
            Type = "Version"
            Item = "PowerShell $($PSVersionTable.PSVersion)"
            Warning = "PowerShell 5.1 is in maintenance mode. Consider upgrading to PowerShell 7.5+"
            Action = "winget install Microsoft.PowerShell"
        }
    }

    # Check for WMIC usage (Windows only)
    if ($IsWindows -and (Get-Command wmic -ErrorAction SilentlyContinue)) {
        $warnings += [PSCustomObject]@{
            Type = "Command Deprecation"
            Item = "WMIC"
            Warning = "WMIC is removed in Windows 11 24H2. Use Get-CimInstance instead"
            Action = "Replace: wmic os get caption -> Get-CimInstance Win32_OperatingSystem"
        }
    }

    $warnings
}

# Main execution
Write-Host "`n=== PowerShell Environment Report ===" -ForegroundColor Cyan
Write-Host "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"

# Environment Info
Write-Host "== Environment ==" -ForegroundColor Yellow
$envInfo = Get-EnvironmentInfo
$envInfo | Format-List

# Feature Availability
Write-Host "== Feature Availability ==" -ForegroundColor Yellow
$features = Get-FeatureAvailability
$features | Format-Table -AutoSize

# Deprecation Warnings
$warnings = Get-DeprecationWarnings
if ($warnings) {
    Write-Host "== Deprecation Warnings ==" -ForegroundColor Red
    $warnings | Format-Table -AutoSize
} else {
    Write-Host "== No Deprecation Warnings ==" -ForegroundColor Green
}

# Module Status
if ($IncludeModules) {
    Write-Host "`n== Module Status ==" -ForegroundColor Yellow
    $moduleStatus = Get-ModuleStatus
    $moduleStatus | Format-Table -AutoSize
}

# JSON Output
if ($JsonOutput) {
    $output = @{
        Environment = $envInfo
        Features = $features
        Warnings = $warnings
    }
    if ($IncludeModules) {
        $output.Modules = $moduleStatus
    }
    $output | ConvertTo-Json -Depth 5
}

# Summary
Write-Host "`n== Summary ==" -ForegroundColor Cyan
Write-Host "PowerShell Version: $($envInfo.PSVersion) ($($envInfo.PSEdition))"
Write-Host ".NET Runtime: $($envInfo.DotNetVersion)"
Write-Host "Platform: $($envInfo.Platform) ($($envInfo.Architecture))"

$available = ($features | Where-Object Available).Count
$total = $features.Count
Write-Host "Features Available: $available/$total"

if ($warnings) {
    Write-Host "Warnings: $($warnings.Count)" -ForegroundColor Red
} else {
    Write-Host "Warnings: 0" -ForegroundColor Green
}
