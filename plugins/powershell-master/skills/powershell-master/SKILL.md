---
name: powershell-master
description: |
  Complete PowerShell expertise system across ALL platforms (Windows/Linux/macOS).
  PROACTIVELY activate for: (1) ANY PowerShell task (scripts/modules/cmdlets), (2) CI/CD automation (GitHub Actions/Azure DevOps/Bitbucket), (3) Cross-platform scripting, (4) Module discovery and management (PSGallery), (5) Azure/AWS/Microsoft 365 automation, (6) Script debugging and optimization, (7) Best practices and security.
  Provides: PowerShell 7+ features, popular module expertise (Az, Microsoft.Graph, PnP, AWS Tools), PSGallery integration, platform-specific guidance, CI/CD pipeline patterns, cmdlet syntax mastery, and production-ready scripting patterns.
  Ensures professional-grade, cross-platform PowerShell automation following industry standards.
---

# PowerShell Master

## CRITICAL GUIDELINES

### Windows File Path Requirements

**MANDATORY: Always Use Backslashes on Windows for File Paths**

When using Edit or Write tools on Windows, you MUST use backslashes (`\`) in file paths, NOT forward slashes (`/`).

Examples:
- WRONG: `D:/repos/project/file.tsx`
- CORRECT: `D:\repos\project\file.tsx`

This applies to:
- Edit tool file_path parameter
- Write tool file_path parameter
- All file operations on Windows systems

### Documentation Guidelines

NEVER create new documentation files unless explicitly requested by the user.

- **Priority**: Update existing README.md files rather than creating new documentation
- **Repository cleanliness**: Keep repository root clean - only README.md unless user requests otherwise
- **Style**: Documentation should be concise, direct, and professional - avoid AI-generated tone
- **User preference**: Only create additional .md files when user specifically asks for documentation

---

Complete PowerShell expertise across all platforms for scripting, automation, CI/CD, and cloud management.

---

## When to Activate

PROACTIVELY activate for ANY PowerShell-related task:

- **PowerShell Scripts** - Creating, reviewing, optimizing any .ps1 file
- **Cmdlets & Modules** - Finding, installing, using any PowerShell modules
- **Cross-Platform** - Windows, Linux, macOS PowerShell tasks
- **CI/CD Integration** - GitHub Actions, Azure DevOps, Bitbucket Pipelines
- **Cloud Automation** - Azure (Az), AWS, Microsoft 365 (Microsoft.Graph)
- **Module Management** - PSGallery search, installation, updates
- **Script Debugging** - Troubleshooting, performance, security
- **Best Practices** - Code quality, standards, production-ready scripts

---

## Reference Map

Detailed material lives in `references/`. Load only what the current task needs.

| Topic | File | When to load |
|-------|------|--------------|
| Cross-platform patterns (paths, platform detection, encoding, shell detection) | `references/cross-platform-patterns.md` | Writing scripts that run on Windows + Linux/macOS, or distinguishing PowerShell vs Git Bash |
| Module management (PSResourceGet, PSGallery, popular modules) | `references/modules-and-gallery.md` | Installing/finding modules, Az 14.5.0, Microsoft.Graph 2.32.0, PnP, AWS Tools, offline installs |
| CI/CD pipelines (GitHub Actions, Azure DevOps, Bitbucket) | `references/cicd-integration.md` | Setting up automated PowerShell builds/tests with multi-platform matrices |
| Syntax & cmdlet reference (variables, operators, flow, functions, pipeline, error handling, Pester, performance, REST) | `references/syntax-reference.md` | Authoring scripts, looking up cmdlets, writing Pester tests, performance tuning |
| Security (JEA, WDAC, Constrained Language Mode, Script Block Logging, credentials, code signing) | `references/security-2025.md` | Production security hardening, credential management, audit logging |

---

## PowerShell Overview

### PowerShell Versions & Platforms

**PowerShell 7+ (Recommended)**
- Cross-platform: Windows, Linux, macOS
- Open source, actively developed
- Better performance than PowerShell 5.1
- UTF-8 by default
- Parallel execution support
- Ternary operators, null-coalescing

**Windows PowerShell 5.1 (Legacy)**
- Windows-only
- Ships with Windows
- UTF-16LE default encoding
- Required for some Windows-specific modules

**Installation Locations:**
- **Windows:** `C:\Program Files\PowerShell\7\` (PS7) or `C:\Windows\System32\WindowsPowerShell\v1.0\` (5.1)
- **Linux:** `/opt/microsoft/powershell/7/` or `/usr/bin/pwsh`
- **macOS:** `/usr/local/microsoft/powershell/7/` or `/usr/local/bin/pwsh`

---

## Core Workflow

1. **Identify scope** — Is this a script, module, automation pipeline, or one-off command? Note target platform(s).
2. **Check version & modules** — `$PSVersionTable.PSVersion`, `Get-Module -ListAvailable`. Confirm PowerShell 7+ unless legacy required.
3. **Load the relevant reference(s)** from the Reference Map above. Avoid loading material you do not need.
4. **Apply the pre-flight checklist** (below) before authoring or running production scripts.
5. **Validate** — `Invoke-ScriptAnalyzer` for linting, `Invoke-Pester` for tests, `-WhatIf` for destructive cmdlets.

---

## Pre-Flight Checklist for Scripts

Before running any PowerShell script, ensure:

1. **Platform Detection** - Use `$IsWindows`, `$IsLinux`, `$IsMacOS` (see `references/cross-platform-patterns.md`)
2. **Version Check** - `#Requires -Version 7.0` if needed
3. **Module Requirements** - `#Requires -Modules` specified
4. **Error Handling** - `try/catch` blocks in place
5. **Input Validation** - Parameter validation attributes used (see `references/syntax-reference.md`)
6. **No Aliases** - Full cmdlet names in scripts
7. **Path Handling** - Use `Join-Path` or `[IO.Path]::Combine()`
8. **Encoding Specified** - UTF-8 for cross-platform
9. **Credentials Secure** - Never hardcoded (see `references/security-2025.md`)
10. **Verbose Logging** - `Write-Verbose` for debugging

---

## Quick Decision Guide

**Use PowerShell 7+ when:**
- Cross-platform compatibility needed
- New projects or scripts
- Performance is important
- Modern language features desired

**Use Windows PowerShell 5.1 when:**
- Windows-specific modules required (WSUS, GroupPolicy legacy)
- Corporate environments with strict version requirements
- Legacy script compatibility needed

**Choose Azure CLI when:**
- Simple one-liners needed
- JSON output preferred
- Bash scripting integration

**Choose PowerShell Az module when:**
- Complex automation required
- Object manipulation needed
- PowerShell scripting expertise available
- Reusable scripts and modules needed

---

## Minimal Script Skeleton

```powershell
#Requires -Version 7.0

<#
.SYNOPSIS
    Brief description
.DESCRIPTION
    Detailed description
.PARAMETER Name
    Parameter description
.EXAMPLE
    PS> .\script.ps1 -Name "John"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$Name
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

try {
    Write-Verbose "Starting script"
    # ... main logic ...
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

Expand this skeleton using patterns from `references/syntax-reference.md` (advanced functions, pipeline, error handling) and `references/security-2025.md` (input validation, credential handling).

---

## Additional Resources

- PowerShell Docs: https://learn.microsoft.com/powershell
- PowerShell Gallery: https://www.powershellgallery.com
- Az Module Docs: https://learn.microsoft.com/powershell/azure
- Microsoft Graph Docs: https://learn.microsoft.com/graph/powershell

For shell detection on Windows (PowerShell vs Git Bash), see the `powershell-shell-detection` skill.

---

Remember: ALWAYS research latest PowerShell documentation and module versions before implementing solutions. The PowerShell ecosystem evolves rapidly, and best practices are updated frequently.
