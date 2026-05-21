# PowerShell Syntax and Cmdlets Reference

Detailed reference for PowerShell language constructs, common cmdlets, REST patterns, testing, and performance tips.

## Cmdlet Structure

```powershell
# Verb-Noun pattern
Get-ChildItem
Set-Location
New-Item
Remove-Item

# Common parameters (available on all cmdlets)
Get-Process -Verbose
Set-Content -Path file.txt -WhatIf
Remove-Item -Path folder -Confirm
Invoke-RestMethod -Uri $url -ErrorAction Stop
```

## Variables & Data Types

```powershell
# Variables (loosely typed)
$string = "Hello World"
$number = 42
$array = @(1, 2, 3, 4, 5)
$hashtable = @{Name="John"; Age=30}

# Strongly typed
[string]$name = "John"
[int]$age = 30
[datetime]$date = Get-Date

# Special variables
$PSScriptRoot   # Directory containing the script
$PSCommandPath  # Full path to the script
$args           # Script arguments
$_              # Current pipeline object
```

## Operators

```powershell
# Comparison operators
-eq        # Equal
-ne        # Not equal
-gt        # Greater than
-lt        # Less than
-match     # Regex match
-like      # Wildcard match
-contains  # Array contains

# Logical operators
-and
-or
-not

# PowerShell 7+ ternary operator
$result = $condition ? "true" : "false"

# Null-coalescing (PS 7+)
$value = $null ?? "default"
```

## Control Flow

```powershell
# If-ElseIf-Else
if ($condition) {
    # Code
} elseif ($otherCondition) {
    # Code
} else {
    # Code
}

# Switch
switch ($value) {
    1 { "One" }
    2 { "Two" }
    {$_ -gt 10} { "Greater than 10" }
    default { "Other" }
}

# Loops
foreach ($item in $collection) {
    # Process item
}

for ($i = 0; $i -lt 10; $i++) {
    # Loop code
}

while ($condition) {
    # Loop code
}

do {
    # Loop code
} while ($condition)
```

## Functions

```powershell
function Get-Something {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,

        [Parameter()]
        [int]$Count = 1,

        [Parameter(ValueFromPipeline=$true)]
        [string[]]$InputObject
    )

    begin {
        # Initialization
    }

    process {
        # Process each pipeline object
        foreach ($item in $InputObject) {
            # Work with $item
        }
    }

    end {
        # Cleanup
        return $result
    }
}
```

## Pipeline & Filtering

```powershell
# Pipeline basics
Get-Process | Where-Object {$_.CPU -gt 100} | Select-Object Name, CPU

# Simplified syntax (PS 3.0+)
Get-Process | Where CPU -gt 100 | Select Name, CPU

# ForEach-Object
Get-ChildItem | ForEach-Object {
    Write-Host $_.Name
}

# Simplified (PS 4.0+)
Get-ChildItem | % Name

# Group, Sort, Measure
Get-Process | Group-Object ProcessName
Get-Service | Sort-Object Status
Get-ChildItem | Measure-Object -Property Length -Sum
```

## Error Handling

```powershell
# Try-Catch-Finally
try {
    Get-Content -Path "nonexistent.txt" -ErrorAction Stop
}
catch [System.IO.FileNotFoundException] {
    Write-Error "File not found"
}
catch {
    Write-Error "An error occurred: $_"
}
finally {
    # Cleanup code
}

# Error action preference
$ErrorActionPreference = "Stop"              # Treat all errors as terminating
$ErrorActionPreference = "Continue"          # Default
$ErrorActionPreference = "SilentlyContinue"  # Suppress errors
```

## Performance Optimization

### PowerShell 7+ Features

```powershell
# Parallel ForEach (PS 7+)
1..10 | ForEach-Object -Parallel {
    Start-Sleep -Seconds 1
    "Processed $_"
} -ThrottleLimit 5

# Ternary operator
$result = $value ? "true" : "false"

# Null-coalescing
$name = $userName ?? "default"

# Null-conditional member access
$length = $string?.Length
```

### Efficient Filtering

```powershell
# Use .NET methods for performance
# Instead of: Get-Content large.txt | Where-Object {$_ -match "pattern"}
[System.IO.File]::ReadLines("large.txt") | Where-Object {$_ -match "pattern"}

# Use -Filter parameter when available
Get-ChildItem -Path C:\ -Filter *.log -Recurse
# Instead of: Get-ChildItem -Path C:\ -Recurse | Where-Object {$_.Extension -eq ".log"}
```

### ArrayList vs Array

```powershell
# Arrays are immutable - slow for additions
$array = @()
1..1000 | ForEach-Object { $array += $_ }  # SLOW

# Use ArrayList for dynamic collections
$list = [System.Collections.ArrayList]::new()
1..1000 | ForEach-Object { [void]$list.Add($_) }  # FAST

# Or use generic List
$list = [System.Collections.Generic.List[int]]::new()
1..1000 | ForEach-Object { $list.Add($_) }
```

### Common Pitfall: Array Concatenation Performance

```powershell
# Bad: $array += $item (recreates array each time)

# Good: Use ArrayList or List
$list = [System.Collections.Generic.List[object]]::new()
$list.Add($item)
```

## Testing with Pester

```powershell
# Install Pester
Install-Module -Name Pester -Force

# Basic test structure
Describe "Get-Something Tests" {
    Context "When input is valid" {
        It "Should return expected value" {
            $result = Get-Something -Name "Test"
            $result | Should -Be "Expected"
        }
    }

    Context "When input is invalid" {
        It "Should throw an error" {
            { Get-Something -Name $null } | Should -Throw
        }
    }
}

# Run tests
Invoke-Pester -Path ./tests
Invoke-Pester -Path ./tests -OutputFormat NUnitXml -OutputFile TestResults.xml

# Code coverage
Invoke-Pester -Path ./tests -CodeCoverage ./src/*.ps1
```

## Script Requirements & Versioning

```powershell
# Require specific PowerShell version
#Requires -Version 7.0

# Require modules
#Requires -Modules Az.Accounts, Az.Compute

# Require admin/elevated privileges (Windows)
#Requires -RunAsAdministrator

# Combine multiple requirements
#Requires -Version 7.0
#Requires -Modules @{ModuleName='Pester'; ModuleVersion='5.0.0'}

# Use strict mode
Set-StrictMode -Version Latest
```

## Common Cmdlets Reference

### File System

```powershell
Get-ChildItem (gci, ls, dir)
Set-Location (cd, sl)
New-Item (ni)
Remove-Item (rm, del)
Copy-Item (cp, copy)
Move-Item (mv, move)
Rename-Item (rn, ren)
Get-Content (gc, cat, type)
Set-Content (sc)
Add-Content (ac)
```

### Process Management

```powershell
Get-Process (ps, gps)
Stop-Process (kill, spps)
Start-Process (start, saps)
Wait-Process
```

### Service Management

```powershell
Get-Service (gsv)
Start-Service (sasv)
Stop-Service (spsv)
Restart-Service (srsv)
Set-Service
```

### Network

```powershell
Test-Connection (ping)
Test-NetConnection
Invoke-WebRequest (curl, wget, iwr)
Invoke-RestMethod (irm)
```

### Object Manipulation

```powershell
Select-Object (select)
Where-Object (where, ?)
ForEach-Object (foreach, %)
Sort-Object (sort)
Group-Object (group)
Measure-Object (measure)
Compare-Object (compare, diff)
```

## REST API & Web Requests

```powershell
# GET request
$response = Invoke-RestMethod -Uri "https://api.example.com/data" -Method Get

# POST with JSON body
$body = @{
    name = "John"
    age = 30
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "https://api.example.com/users" `
    -Method Post -Body $body -ContentType "application/json"

# With headers and authentication
$headers = @{
    "Authorization" = "Bearer $token"
    "Accept" = "application/json"
}

$response = Invoke-RestMethod -Uri $url -Headers $headers

# Download file
Invoke-WebRequest -Uri $url -OutFile "file.zip"
```

## Script Structure Best Practices

```powershell
<#
.SYNOPSIS
    Brief description

.DESCRIPTION
    Detailed description

.PARAMETER Name
    Parameter description

.EXAMPLE
    PS> .\script.ps1 -Name "John"
    Example usage

.NOTES
    Author: Your Name
    Version: 1.0.0
    Date: 2025-01-01
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$Name
)

# Script-level error handling
$ErrorActionPreference = "Stop"

# Use strict mode
Set-StrictMode -Version Latest

try {
    # Main script logic
    Write-Verbose "Starting script"

    # ... script code ...

    Write-Verbose "Script completed successfully"
}
catch {
    Write-Error "Script failed: $_"
    exit 1
}
finally {
    # Cleanup
}
```

## Common Pitfalls

### Out-GridView Search Broken in 7.5

```powershell
# Known Issue: Out-GridView search doesn't work in PowerShell 7.5 due to .NET 9 changes
# Workaround: Use Where-Object or Select-Object for filtering
Get-Process | Where-Object CPU -gt 100 | Format-Table

# Or export to CSV and use external tools
Get-Process | Export-Csv processes.csv -NoTypeInformation
```

### Execution Policy

```powershell
# Solution: Set for current user
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Or bypass for session
powershell.exe -ExecutionPolicy Bypass -File script.ps1
```
