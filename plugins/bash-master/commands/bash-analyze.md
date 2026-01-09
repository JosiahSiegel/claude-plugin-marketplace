---
name: bash-analyze
description: Deep analysis of bash scripts for security, performance, portability, and best practices compliance
argument-hint: <script.sh or directory>
---

## CRITICAL GUIDELINES

### Windows File Path Requirements

**MANDATORY: Always Use Backslashes on Windows for File Paths**

When using Edit or Write tools on Windows, you MUST use backslashes (`\`) in file paths, NOT forward slashes (`/`).

---

# Bash Script Analyzer

## Purpose

Perform comprehensive analysis of bash scripts covering security vulnerabilities, performance issues, portability concerns, and adherence to modern best practices.

## Analysis Categories

### 1. Security Analysis
- Command injection vulnerabilities
- Path traversal risks
- Unsafe temporary file handling
- Unquoted variable expansions
- Privilege escalation risks
- Sensitive data exposure
- Race condition vulnerabilities

### 2. Performance Analysis
- Unnecessary subshell spawning
- Inefficient loops (UUOC, UUOG)
- External command overuse vs bash builtins
- Pipeline optimization opportunities
- Array usage efficiency
- Process substitution opportunities

### 3. Portability Analysis
- Bash version compatibility (4.x, 5.x features)
- POSIX compliance level
- Platform-specific issues (Linux/macOS/BSD)
- GNU vs BSD tool differences
- Shebang portability

### 4. Best Practices Compliance
- ShellCheck warnings (all severity levels)
- Google Shell Style Guide adherence
- Error handling patterns
- Cleanup and trap usage
- Function structure and modularity
- Documentation and comments

## Analysis Output Format

For each script analyzed, provide:

```
## Script: <filename>

### Security Issues
- [CRITICAL] <issue description>
- [HIGH] <issue description>
- [MEDIUM] <issue description>

### Performance Issues
- [IMPACT: HIGH] <issue description>
- [IMPACT: MEDIUM] <issue description>

### Portability Issues
- [Bash 5.x required] <feature used>
- [GNU-specific] <command/flag used>

### Best Practice Violations
- [ShellCheck SC####] <description>
- [Style] <description>

### Recommendations
1. <actionable recommendation>
2. <actionable recommendation>

### Score: X/100
- Security: X/25
- Performance: X/25
- Portability: X/25
- Best Practices: X/25
```

## Analysis Checklist

When analyzing scripts, systematically check:

### Security Checklist
- [ ] All variables quoted in command arguments
- [ ] No eval with user input
- [ ] No unvalidated external input in commands
- [ ] Temp files created securely (mktemp)
- [ ] No world-readable sensitive data
- [ ] Proper file permission handling
- [ ] No symlink following vulnerabilities

### Performance Checklist
- [ ] Using bash builtins over external commands
- [ ] Avoiding unnecessary subshells
- [ ] Using arrays instead of string parsing
- [ ] Efficient file reading patterns
- [ ] Process substitution where appropriate
- [ ] Avoiding cat | grep (UUOC)
- [ ] Using mapfile for file reading

### Portability Checklist
- [ ] Shebang uses /usr/bin/env bash or /bin/bash
- [ ] Bash version requirements documented
- [ ] No undocumented bashisms
- [ ] GNU/BSD command compatibility
- [ ] Works on major platforms

### Best Practices Checklist
- [ ] set -euo pipefail at start
- [ ] trap for cleanup on EXIT
- [ ] Functions under 50 lines
- [ ] Proper error messages to stderr
- [ ] Meaningful exit codes
- [ ] ShellCheck passes with zero warnings
- [ ] Consistent coding style

## Usage Examples

**Analyze single script:**
```
/bash-analyze backup.sh
```

**Analyze directory:**
```
/bash-analyze scripts/
```

**Focus on security:**
```
/bash-analyze deploy.sh focus on security vulnerabilities
```

**Check portability:**
```
/bash-analyze build.sh check POSIX compliance
```

## After Analysis

Based on findings, I will:
1. Provide detailed analysis report
2. List all issues with severity ratings
3. Give specific fix recommendations
4. Offer to fix issues automatically if requested
5. Suggest architectural improvements if needed

---

**Comprehensive bash script analysis using 2025 best practices and security standards.**
