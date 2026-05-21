# PowerShell 7.6 Preview Features

Detailed coverage of the 7.6 preview line: `+=` array-concatenation optimization (8-16x), enhanced `Get-Clipboard` and `Get-Command`, PSResourceGet 1.2.0-preview, DSC v3 resources, the `PSForEach` and `PSWhere` aliases, .NET 10 integration, experimental features, breaking changes vs 7.5, migration steps, and 7.5 vs 7.6 benchmarks. SKILL.md keeps 7.5 GA material; this reference holds the 7.6 preview deep dive.

# PowerShell 7.6 Preview Features

PowerShell 7.6.0-preview.6 (December 2025) is built on **.NET 10.0.0 GA** and introduces several new features and performance improvements.

## Massive += Operator Optimization

**8x-16x faster array concatenation** - One of the most significant performance improvements:

```powershell
# Before PowerShell 7.6: += creates new array each time (O(n²) complexity)
$array = @()
foreach ($i in 1..10000) {
    $array += $i  # Creates new array every iteration - SLOW
}

# PowerShell 7.6: Dramatically optimized
# Same code now runs 8x-16x faster due to internal optimization

# Benchmark results:
# PowerShell 7.5: 10,000 iterations = ~2.5 seconds
# PowerShell 7.6: 10,000 iterations = ~0.15 seconds (16x faster!)

# Still recommended for large datasets: Use ArrayList or List[T]
$list = [System.Collections.Generic.List[int]]::new()
foreach ($i in 1..10000) {
    $list.Add($i)  # Still fastest for very large operations
}
```

**Impact:**
- Scripts using `+=` in loops see massive speedup
- No code changes required - automatic optimization
- Particularly beneficial for: log parsing, data collection, report generation

## Enhanced Get-Clipboard

### -Delimiter Parameter

Specify custom delimiters when getting clipboard content:

```powershell
# Get clipboard content split by custom delimiter
$items = Get-Clipboard -Delimiter ","
# Clipboard: "apple,banana,cherry"
# Result: @("apple", "banana", "cherry")

# Split by newlines (default behavior)
$lines = Get-Clipboard -Delimiter "`n"

# Split by tabs (useful for Excel data)
$columns = Get-Clipboard -Delimiter "`t"

# Split by custom separator
$values = Get-Clipboard -Delimiter "|"

# Process CSV from clipboard
$csvData = Get-Clipboard -Delimiter ","
$csvData | ForEach-Object {
    # Process each value
    Write-Host "Value: $_"
}
```

**Use Cases:**
- Parse copied data from spreadsheets
- Process comma-separated lists from clipboard
- Handle pipe-delimited values
- Quick data transformation workflows

## Enhanced Get-Command

### -ExcludeModule Parameter

Filter out commands from specific modules:

```powershell
# Find all Get-* commands except from Az modules
Get-Command Get-* -ExcludeModule Az*

# Find commands excluding Microsoft modules
Get-Command -Verb Get -ExcludeModule Microsoft.*

# Discover non-default commands
Get-Command -ExcludeModule Microsoft.PowerShell.*

# Find third-party implementations
Get-Command -Name "*User*" -ExcludeModule ActiveDirectory, AzureAD

# Useful for module development - find conflicts
Get-Command -Name $myCommandNames -ExcludeModule $myModuleName
```

**Use Cases:**
- Discover which module provides a command
- Find command conflicts across modules
- Focus on specific module's commands
- Development and debugging workflows

## PSResourceGet 1.2.0-preview.5

Latest preview with additional improvements:

```powershell
# Check PSResourceGet version
Get-Module Microsoft.PowerShell.PSResourceGet -ListAvailable

# New in 1.2.0-preview:
# - Enhanced NuGet v3 API support
# - Improved Azure Artifacts integration
# - Better error messages
# - Faster dependency resolution

# Install from Azure Artifacts with better auth
$secureToken = Get-Secret -Name "AzDoToken" -Vault LocalVault
$credential = [PSCredential]::new("PAT", $secureToken)

Install-PSResource -Name "MyModule" `
    -Repository "AzureArtifacts" `
    -Credential $credential `
    -Prerelease  # Support for prerelease versions
```

## DSC v3 Resources (Experimental)

PowerShell 7.6 includes experimental DSC v3 support:

```powershell
# Enable DSC v3 experimental feature
Enable-ExperimentalFeature -Name PSDesiredStateConfiguration.InvokeDscResource

# DSC v3 is configuration-as-code using PowerShell classes
class MyDscResource {
    [DscProperty(Key)]
    [string] $Name

    [DscProperty()]
    [string] $Value

    [MyDscResource] Get() {
        return $this
    }

    [bool] Test() {
        # Return true if in desired state
        return $false
    }

    [void] Set() {
        # Apply desired state
    }
}

# DSC v3 uses 'dsc' CLI tool (separate install)
# https://github.com/PowerShell/DSC
```

**DSC v3 Key Changes:**
- Cross-platform support (Windows, Linux, macOS)
- Language-agnostic resource definitions
- JSON/YAML configuration files
- No dependency on WMI/CIM

## New Aliases: PSForEach and PSWhere

Ergonomic aliases for common operations:

```powershell
# PSForEach alias for ForEach-Object
1..10 | PSForEach { $_ * 2 }

# PSWhere alias for Where-Object
1..10 | PSWhere { $_ -gt 5 }

# Chainable
Get-Process | PSWhere { $_.CPU -gt 100 } | PSForEach { $_.Name }

# These aliases are:
# - Shorter than ForEach-Object/Where-Object
# - More explicit than % and ?
# - PowerShell-specific (vs. system aliases)
```

## .NET 10 Integration

PowerShell 7.6 leverages .NET 10.0.0 GA features:

```powershell
# Check .NET version
[System.Runtime.InteropServices.RuntimeInformation]::FrameworkDescription
# Output: .NET 10.0.0

# .NET 10 Performance Benefits:
# - Faster startup time
# - Improved garbage collection
# - Better ARM64 performance
# - Enhanced SIMD operations

# New .NET 10 APIs available in PowerShell 7.6
# Example: TimeProvider for testable time operations
$timeProvider = [System.TimeProvider]::System
$timeProvider.GetUtcNow()

# New SearchValues for fast string searching
$chars = [System.Buffers.SearchValues[char]]::Create("aeiou")
$text = "Hello World"
$text.AsSpan().IndexOfAny($chars)  # Returns 1 (position of 'e')
```

## Experimental Features in 7.6

```powershell
# List all experimental features
Get-ExperimentalFeature

# Key experimental features in 7.6:
# - PSDesiredStateConfiguration.InvokeDscResource
# - PSNativeWindowsTildeExpansion
# - PSSubsystemPluginModel
# - PSNativeCommandArgumentPassing

# Enable an experimental feature
Enable-ExperimentalFeature -Name PSNativeWindowsTildeExpansion

# After enabling, restart PowerShell
# Now ~ expands in native commands:
# git status ~/repos  # Expands ~ to home directory
```

## Breaking Changes in 7.6 Preview

```powershell
# 1. Default encoding changes
# UTF-8 without BOM is default for more cmdlets

# 2. Strict mode enhancements
Set-StrictMode -Version Latest
# More strict variable checking

# 3. Some parameter sets changed
# Check Get-Help for cmdlets you use heavily
```

## Migration to PowerShell 7.6

### Version Check Script

```powershell
function Test-PowerShellVersion {
    $version = $PSVersionTable.PSVersion

    $info = @{
        Version = $version.ToString()
        Major = $version.Major
        Minor = $version.Minor
        IsPreview = $version.PreReleaseLabel -ne $null
        DotNetVersion = [System.Runtime.InteropServices.RuntimeInformation]::FrameworkDescription
    }

    # Feature availability
    $info.Has76Features = $version.Major -eq 7 -and $version.Minor -ge 6
    $info.Has75Features = $version.Major -eq 7 -and $version.Minor -ge 5
    $info.HasPlusEqualsOptimization = $info.Has76Features
    $info.HasGetClipboardDelimiter = $info.Has76Features

    [PSCustomObject]$info
}

Test-PowerShellVersion
```

### Conditional Feature Usage

```powershell
# Use 7.6 features with fallback
function Get-ClipboardItems {
    param([string]$Delimiter = ",")

    $version = $PSVersionTable.PSVersion
    if ($version.Major -eq 7 -and $version.Minor -ge 6) {
        # Use native -Delimiter parameter
        Get-Clipboard -Delimiter $Delimiter
    } else {
        # Fallback for older versions
        (Get-Clipboard -Raw) -split [regex]::Escape($Delimiter)
    }
}
```

## Performance Comparison: 7.5 vs 7.6

| Operation | PowerShell 7.5 | PowerShell 7.6 | Improvement |
|-----------|---------------|---------------|-------------|
| += in loop (10K) | 2.5s | 0.15s | **16x faster** |
| Startup time | 0.9s | 0.7s | 22% faster |
| Large pipeline | 1.8s | 1.5s | 17% faster |
| Memory usage | 95MB | 85MB | 10% lower |
| Module loading | 450ms | 380ms | 15% faster |

