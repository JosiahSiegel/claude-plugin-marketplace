---
name: bash-template
description: Generate production-ready bash script templates with modern patterns, error handling, and configurable features
argument-hint: <type> [options] (types: cli, daemon, library, installer, ci)
---

## CRITICAL GUIDELINES

### Windows File Path Requirements

**MANDATORY: Always Use Backslashes on Windows for File Paths**

When using Edit or Write tools on Windows, you MUST use backslashes (`\`) in file paths, NOT forward slashes (`/`).

---

# Bash Template Generator

## Purpose

Generate production-ready bash script templates with modern 2025 patterns, comprehensive error handling, and configurable features based on script type and requirements.

## Available Template Types

### 1. CLI Tool (`cli`)
Full-featured command-line tool with:
- Argument parsing (getopts/long options)
- Help and version commands
- Configuration file support
- Logging with verbosity levels
- Progress indicators
- Color output support

### 2. Daemon/Service (`daemon`)
Background service script with:
- Daemonization support
- PID file management
- Signal handling (SIGHUP, SIGTERM)
- Log rotation integration
- Systemd unit file generation
- Health check endpoint

### 3. Library (`library`)
Reusable function library with:
- Namespaced functions
- Dependency checking
- Self-documentation
- Version tracking
- Safe sourcing patterns
- Unit test integration

### 4. Installer (`installer`)
Software installation script with:
- Dependency verification
- Platform detection
- Root privilege handling
- Rollback support
- Progress reporting
- Post-install verification

### 5. CI/CD Pipeline (`ci`)
CI/CD pipeline script with:
- Environment detection
- Secret handling
- Artifact management
- Test execution
- Deployment patterns
- Notification integration

## Template Options

Specify additional options for customization:

| Option | Description |
|--------|-------------|
| `--minimal` | Basic template without advanced features |
| `--full` | All features enabled |
| `--config` | Include configuration file handling |
| `--logging` | Include structured logging |
| `--parallel` | Include parallel processing support |
| `--interactive` | Include user prompts and menus |
| `--docker` | Include Docker integration |
| `--aws` | Include AWS CLI patterns |
| `--k8s` | Include Kubernetes patterns |

## Usage Examples

**Basic CLI tool:**
```
/bash-template cli
```

**Full-featured daemon:**
```
/bash-template daemon --full --logging
```

**Minimal installer:**
```
/bash-template installer --minimal
```

**CI script with Docker:**
```
/bash-template ci --docker --parallel
```

**Library with tests:**
```
/bash-template library my-utils
```

## Template Structure

All templates include:

```bash
#!/usr/bin/env bash
#
# script-name - Brief description
# Version: 1.0.0
# Author: <author>
# License: MIT
#
# Usage: script-name [OPTIONS] <arguments>
#
# Description:
#   Longer description of what the script does.
#

# Strict mode
set -euo pipefail

# Script metadata
readonly VERSION="1.0.0"
readonly SCRIPT_NAME="${BASH_SOURCE[0]##*/}"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Configuration defaults
declare -A CONFIG=(
    [verbose]=false
    [dry_run]=false
    [config_file]=""
)

# Cleanup handler
cleanup() {
    local exit_code=$?
    # Cleanup logic here
    exit "$exit_code"
}
trap cleanup EXIT INT TERM

# Main function
main() {
    parse_args "$@"
    validate_environment
    execute
}

main "$@"
```

## Feature Modules

Templates can include these feature modules:

### Argument Parsing
```bash
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help) show_help; exit 0 ;;
            -v|--version) echo "$VERSION"; exit 0 ;;
            -V|--verbose) CONFIG[verbose]=true ;;
            --) shift; break ;;
            -*) die "Unknown option: $1" ;;
            *) ARGS+=("$1") ;;
        esac
        shift
    done
}
```

### Logging System
```bash
declare -A LOG_LEVELS=([DEBUG]=0 [INFO]=1 [WARN]=2 [ERROR]=3)
LOG_LEVEL="${LOG_LEVEL:-INFO}"

log() {
    local level="$1"; shift
    local msg="$*"
    local ts; ts=$(date '+%Y-%m-%d %H:%M:%S')

    if [[ ${LOG_LEVELS[$level]} -ge ${LOG_LEVELS[$LOG_LEVEL]} ]]; then
        printf '[%s] [%s] %s\n' "$ts" "$level" "$msg" >&2
    fi
}

debug() { log DEBUG "$@"; }
info()  { log INFO "$@"; }
warn()  { log WARN "$@"; }
error() { log ERROR "$@"; }
```

### Color Output
```bash
setup_colors() {
    if [[ -t 2 ]] && [[ -z "${NO_COLOR:-}" ]]; then
        RED=$'\033[0;31m'
        GREEN=$'\033[0;32m'
        YELLOW=$'\033[0;33m'
        BLUE=$'\033[0;34m'
        RESET=$'\033[0m'
    else
        RED='' GREEN='' YELLOW='' BLUE='' RESET=''
    fi
}
```

### Progress Indicator
```bash
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'

    while kill -0 "$pid" 2>/dev/null; do
        for ((i=0; i<${#spinstr}; i++)); do
            printf '\r%s %s' "${spinstr:$i:1}" "$2"
            sleep "$delay"
        done
    done
    printf '\r✓ %s\n' "$2"
}
```

## Output

When you request a template, I will:

1. Generate the complete script with requested features
2. Include inline documentation
3. Provide usage examples
4. Add ShellCheck-compliant code
5. Include relevant test patterns

---

**Generate modern, production-ready bash scripts instantly with best practices built-in.**
