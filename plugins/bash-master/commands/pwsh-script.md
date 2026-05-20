---
name: pwsh-script
description: Create, review, or optimize bash/shell scripts following 2025 best practices and cross-platform standards
---

## 🚨 CRITICAL GUIDELINES

### Windows File Path Requirements

**MANDATORY: Always Use Backslashes on Windows for File Paths**

When using Edit or Write tools on Windows, you MUST use backslashes (`\`) in file paths, NOT forward slashes (`/`).

**Examples:**
- ❌ WRONG: `D:/repos/project/file.tsx`
- ✅ CORRECT: `D:\repos\project\file.tsx`

This applies to:
- Edit tool file_path parameter
- Write tool file_path parameter
- All file operations on Windows systems


### Documentation Guidelines

**NEVER create new documentation files unless explicitly requested by the user.**

- **Priority**: Update existing README.md files rather than creating new documentation
- **Repository cleanliness**: Keep repository root clean - only README.md unless user requests otherwise
- **Style**: Documentation should be concise, direct, and professional - avoid AI-generated tone
- **User preference**: Only create additional .md files when user specifically asks for documentation


---

# Create/Review Bash Scripts

## Purpose

Autonomously create professional, production-ready bash scripts or review/optimize existing scripts following 2025 industry standards.

## What This Command Does

**Automatic Actions:**
1. ✅ Creates scripts with mandatory error handling (set -euo pipefail)
2. ✅ Implements ShellCheck-compliant code
3. ✅ Follows Google Shell Style Guide (50-line recommendation)
4. ✅ Adds comprehensive error handling and cleanup
5. ✅ Ensures cross-platform compatibility
6. ✅ Includes proper documentation
7. ✅ Validates security patterns

**For Reviews:**
- Identifies ShellCheck issues
- Checks for security vulnerabilities
- Validates error handling
- Suggests performance optimizations
- Verifies cross-platform compatibility

## Usage

**Create a new script:**
```text
/pwsh-script Create a backup script that archives /data to S3 with error handling
```

**Review existing script:**
```text
/pwsh-script Review backup.sh for security issues and best practices
```

**Optimize performance:**
```text
/pwsh-script Optimize deploy.sh for better performance
```

## What You'll Get

### New Scripts Include:
- `#!/usr/bin/env bash` shebang
- Safety settings (set -euo pipefail, IFS=$'\n\t')
- Proper function structure
- Input validation
- Error handling with trap
- Usage/help text
- Logging capabilities
- Cross-platform considerations
- ShellCheck compliance

### Reviews Provide:
- ShellCheck validation results
- Security vulnerability assessment
- Anti-pattern identification
- Performance improvement suggestions
- Cross-platform compatibility notes
- Best practice recommendations

## Example Output

```bash
#!/usr/bin/env bash
#
# backup.sh - Archive data to S3 with error handling
# Version: 1.0.0

set -euo pipefail
IFS=$'\n\t'

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# Cleanup on exit
cleanup() {
    local exit_code=$?
    [[ -n "${TEMP_DIR:-}" ]] && rm -rf "$TEMP_DIR"
    exit "$exit_code"
}
trap cleanup EXIT INT TERM

# Main function
main() {
    local source_dir="${1:?Source directory required}"
    local s3_bucket="${2:?S3 bucket required}"

    # Validate source directory
    if [[ ! -d "$source_dir" ]]; then
        echo "Error: Source directory not found: $source_dir" >&2
        return 1
    fi

    # Create archive
    local archive_name="backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    tar -czf "$archive_name" -C "$source_dir" . || {
        echo "Error: Failed to create archive" >&2
        return 1
    }

    # Upload to S3
    aws s3 cp "$archive_name" "s3://$s3_bucket/" || {
        echo "Error: Failed to upload to S3" >&2
        rm -f "$archive_name"
        return 1
    }

    # Cleanup
    rm -f "$archive_name"
    echo "Backup completed successfully"
}

main "$@"
```

## 2025 Standards Applied

- **ShellCheck validation** - Zero warnings
- **Google Style Guide** - Modular functions under 50 lines
- **Modern error handling** - errexit, nounset, pipefail trio
- **Security hardening** - Input validation, path sanitization
- **Cross-platform** - Works on Linux/macOS/Windows (Git Bash/WSL)
- **Production-ready** - Proper cleanup, logging, exit codes

## When To Use

- Creating new bash scripts for any purpose
- Automating system tasks
- DevOps/CI/CD pipeline scripts
- Build and deployment automation
- Reviewing security of existing scripts
- Optimizing script performance
- Debugging script issues
- Converting manual commands to automated scripts

---

**After running this command, you'll have production-ready, secure, optimized bash scripts following all 2025 best practices.**
