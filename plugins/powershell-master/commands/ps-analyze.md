---
name: ps-analyze
description: Analyze PowerShell scripts for best practices, security issues, and compatibility
argument-hint: "<script.ps1 or directory path>"
allowed-tools:
  - Read
  - Glob
  - Grep
  - Task
---

# PowerShell Script Analyzer

Analyze PowerShell scripts for:
1. **Security issues** - Credential handling, injection vulnerabilities, plaintext secrets
2. **Best practices** - PSScriptAnalyzer rules, naming conventions, error handling
3. **Compatibility** - PowerShell 5.1 vs 7.x, cross-platform issues, deprecated cmdlets
4. **Performance** - Inefficient patterns, += in loops, unnecessary pipeline operations
5. **2025 changes** - MSOnline/AzureAD usage, WMIC calls, PowerShell 2.0 patterns

## Analysis Checklist

### Security Analysis
- [ ] Check for plaintext credentials in scripts
- [ ] Identify `ConvertTo-SecureString -AsPlainText` without proper handling
- [ ] Find hardcoded connection strings or API keys
- [ ] Check for command injection vulnerabilities (Invoke-Expression with user input)
- [ ] Verify SecretManagement usage for secrets

### Best Practices
- [ ] Function naming (Verb-Noun format)
- [ ] Parameter validation attributes
- [ ] Error handling (try/catch, $ErrorActionPreference)
- [ ] Comment-based help documentation
- [ ] Output type declarations

### Compatibility
- [ ] Check for Windows-only cmdlets used on cross-platform
- [ ] Identify deprecated MSOnline/AzureAD module usage
- [ ] Find WMIC calls that need replacement
- [ ] Check for PowerShell 2.0 patterns

### Performance
- [ ] Find `+=` in loops (recommend ArrayList/List[T] or 7.6 upgrade)
- [ ] Identify unnecessary `Where-Object` after `Get-*` cmdlets with -Filter
- [ ] Check for repeated expensive operations inside loops

## Output Format

Provide a structured report with:
1. **Summary** - Overall assessment and risk level
2. **Critical Issues** - Security vulnerabilities requiring immediate attention
3. **Warnings** - Best practice violations and compatibility issues
4. **Suggestions** - Performance improvements and modernization opportunities
5. **Code Examples** - Specific fixes for each identified issue
