#!/usr/bin/env bash
#
# shellcheck-batch.sh - Run ShellCheck on multiple scripts with summary reporting
# Version: 1.0.0
#
# Usage: ./shellcheck-batch.sh [OPTIONS] <files or directories>
#
# Options:
#   -f, --format FMT    Output format: text, json, gcc, checkstyle (default: text)
#   -s, --severity LVL  Minimum severity: error, warning, info, style (default: style)
#   -e, --exclude CODES Comma-separated list of codes to exclude (e.g., SC2086,SC2034)
#   -x, --external      Follow source directives (shellcheck -x)
#   -o, --output FILE   Write results to file
#   -c, --color         Force color output
#   -q, --quiet         Only show summary
#   -v, --verbose       Show detailed progress
#   --fix               Show suggested fixes (requires diff)
#   --ci                CI-friendly output (exit code 0 if only warnings)
#   -h, --help          Show this help message
#
# Examples:
#   ./shellcheck-batch.sh scripts/
#   ./shellcheck-batch.sh -s warning -e SC2086 *.sh
#   ./shellcheck-batch.sh --format json -o report.json src/

set -euo pipefail

# Script metadata
readonly VERSION="1.0.0"
readonly SCRIPT_NAME="${BASH_SOURCE[0]##*/}"

# Configuration
FORMAT="text"
SEVERITY="style"
EXCLUDE=""
EXTERNAL=false
OUTPUT=""
COLOR=false
QUIET=false
VERBOSE=false
SHOW_FIX=false
CI_MODE=false
declare -a PATHS=()

# Counters
TOTAL_FILES=0
PASSED_FILES=0
FAILED_FILES=0
declare -A ERROR_COUNTS=([error]=0 [warning]=0 [info]=0 [style]=0)

# Colors
setup_colors() {
    if [[ -t 1 ]] || $COLOR; then
        RED=$'\033[0;31m'
        GREEN=$'\033[0;32m'
        YELLOW=$'\033[0;33m'
        BLUE=$'\033[0;34m'
        CYAN=$'\033[0;36m'
        BOLD=$'\033[1m'
        RESET=$'\033[0m'
    else
        RED='' GREEN='' YELLOW='' BLUE='' CYAN='' BOLD='' RESET=''
    fi
}

show_help() {
    sed -n '/^# Usage:/,/^[^#]/p' "$0" | grep '^#' | sed 's/^# //' | sed 's/^#//'
    exit 0
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -f|--format)
                FORMAT="$2"
                shift 2
                ;;
            -s|--severity)
                SEVERITY="$2"
                shift 2
                ;;
            -e|--exclude)
                EXCLUDE="$2"
                shift 2
                ;;
            -x|--external)
                EXTERNAL=true
                shift
                ;;
            -o|--output)
                OUTPUT="$2"
                shift 2
                ;;
            -c|--color)
                COLOR=true
                shift
                ;;
            -q|--quiet)
                QUIET=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            --fix)
                SHOW_FIX=true
                shift
                ;;
            --ci)
                CI_MODE=true
                shift
                ;;
            -h|--help)
                show_help
                ;;
            --version)
                echo "$SCRIPT_NAME version $VERSION"
                exit 0
                ;;
            -*)
                echo "Unknown option: $1" >&2
                exit 1
                ;;
            *)
                PATHS+=("$1")
                shift
                ;;
        esac
    done

    if [[ ${#PATHS[@]} -eq 0 ]]; then
        PATHS=(".")
    fi
}

# Check if ShellCheck is installed
check_shellcheck() {
    if ! command -v shellcheck &>/dev/null; then
        echo "${RED}Error: ShellCheck is not installed${RESET}" >&2
        echo "Install with:" >&2
        echo "  apt-get install shellcheck  # Debian/Ubuntu" >&2
        echo "  brew install shellcheck     # macOS" >&2
        exit 1
    fi

    local version
    version=$(shellcheck --version | grep -oP 'version: \K[0-9.]+' || shellcheck --version | head -2 | tail -1)
    $VERBOSE && echo "${BLUE}Using ShellCheck $version${RESET}"
}

# Find all shell scripts
find_scripts() {
    local path="$1"

    if [[ -f "$path" ]]; then
        # Single file
        if is_shell_script "$path"; then
            echo "$path"
        fi
    elif [[ -d "$path" ]]; then
        # Directory - find all shell scripts
        find "$path" -type f \( -name "*.sh" -o -name "*.bash" \) 2>/dev/null

        # Also find scripts without extension but with shebang
        find "$path" -type f ! -name "*.*" -exec grep -l '^#!.*\(bash\|sh\)' {} \; 2>/dev/null || true
    fi
}

# Check if file is a shell script
is_shell_script() {
    local file="$1"

    # Check extension
    [[ "$file" == *.sh || "$file" == *.bash ]] && return 0

    # Check shebang
    if [[ -f "$file" ]] && head -1 "$file" | grep -qE '^#!.*(bash|sh)'; then
        return 0
    fi

    return 1
}

# Build ShellCheck arguments
build_shellcheck_args() {
    local args=("-f" "$FORMAT" "-S" "$SEVERITY")

    $EXTERNAL && args+=("-x")

    if [[ -n "$EXCLUDE" ]]; then
        IFS=',' read -ra codes <<< "$EXCLUDE"
        for code in "${codes[@]}"; do
            args+=("-e" "$code")
        done
    fi

    printf '%s\n' "${args[@]}"
}

# Run ShellCheck on a single file
check_file() {
    local file="$1"
    local result
    local exit_code

    ((TOTAL_FILES++))
    $VERBOSE && echo "${BLUE}Checking: $file${RESET}"

    # Build arguments
    mapfile -t args < <(build_shellcheck_args)

    # Run ShellCheck
    if result=$(shellcheck "${args[@]}" "$file" 2>&1); then
        ((PASSED_FILES++))
        $QUIET || echo "${GREEN}✓${RESET} $file"
        return 0
    else
        exit_code=$?
        ((FAILED_FILES++))

        # Parse and count issues
        count_issues "$result"

        if ! $QUIET; then
            echo "${RED}✗${RESET} $file"
            if [[ "$FORMAT" == "text" ]]; then
                echo "$result" | sed 's/^/  /'
            fi
        fi

        return "$exit_code"
    fi
}

# Count issues by severity
count_issues() {
    local result="$1"

    # Count by severity level in the output
    local errors warnings infos styles

    errors=$(echo "$result" | grep -c '\[error\]' || echo 0)
    warnings=$(echo "$result" | grep -c '\[warning\]' || echo 0)
    infos=$(echo "$result" | grep -c '\[info\]' || echo 0)
    styles=$(echo "$result" | grep -c '\[style\]' || echo 0)

    ((ERROR_COUNTS[error] += errors))
    ((ERROR_COUNTS[warning] += warnings))
    ((ERROR_COUNTS[info] += infos))
    ((ERROR_COUNTS[style] += styles))
}

# Print summary
print_summary() {
    local total_issues=$((ERROR_COUNTS[error] + ERROR_COUNTS[warning] + ERROR_COUNTS[info] + ERROR_COUNTS[style]))

    echo ""
    echo "${BOLD}═══════════════════════════════════════${RESET}"
    echo "${BOLD}ShellCheck Summary${RESET}"
    echo "${BOLD}═══════════════════════════════════════${RESET}"
    echo ""
    echo "Files checked:    $TOTAL_FILES"
    echo "  ${GREEN}Passed:${RESET}         $PASSED_FILES"
    echo "  ${RED}Failed:${RESET}         $FAILED_FILES"
    echo ""
    echo "Issues found:     $total_issues"
    echo "  ${RED}Errors:${RESET}         ${ERROR_COUNTS[error]}"
    echo "  ${YELLOW}Warnings:${RESET}       ${ERROR_COUNTS[warning]}"
    echo "  ${CYAN}Info:${RESET}           ${ERROR_COUNTS[info]}"
    echo "  ${BLUE}Style:${RESET}          ${ERROR_COUNTS[style]}"
    echo ""

    if ((FAILED_FILES == 0)); then
        echo "${GREEN}${BOLD}All checks passed!${RESET}"
    else
        echo "${RED}${BOLD}Some checks failed.${RESET}"
    fi

    echo "${BOLD}═══════════════════════════════════════${RESET}"
}

# Show common fixes
show_common_fixes() {
    echo ""
    echo "${BOLD}Common Fixes:${RESET}"
    echo ""
    echo "SC2086 - Quote to prevent word splitting:"
    echo "  ${RED}- echo \$var${RESET}"
    echo "  ${GREEN}+ echo \"\$var\"${RESET}"
    echo ""
    echo "SC2034 - Unused variable (prefix with _ or export):"
    echo "  ${RED}- unused_var=\"value\"${RESET}"
    echo "  ${GREEN}+ _unused_var=\"value\"${RESET}"
    echo ""
    echo "SC2155 - Declare and assign separately:"
    echo "  ${RED}- local var=\$(cmd)${RESET}"
    echo "  ${GREEN}+ local var${RESET}"
    echo "  ${GREEN}+ var=\$(cmd)${RESET}"
    echo ""
}

main() {
    setup_colors
    parse_args "$@"
    check_shellcheck

    echo "${BOLD}ShellCheck Batch Analysis${RESET}"
    echo "Severity: $SEVERITY | Format: $FORMAT"
    echo ""

    # Collect all files
    declare -a all_files=()
    for path in "${PATHS[@]}"; do
        while IFS= read -r file; do
            [[ -n "$file" ]] && all_files+=("$file")
        done < <(find_scripts "$path")
    done

    if [[ ${#all_files[@]} -eq 0 ]]; then
        echo "${YELLOW}No shell scripts found.${RESET}"
        exit 0
    fi

    echo "Found ${#all_files[@]} script(s) to check"
    echo ""

    # Output redirection
    local output_fd=1
    if [[ -n "$OUTPUT" ]]; then
        exec 3>"$OUTPUT"
        output_fd=3
    fi

    # Check all files
    local failed=false
    for file in "${all_files[@]}"; do
        if ! check_file "$file"; then
            failed=true
        fi
    done >&"$output_fd"

    # Close output file
    [[ -n "$OUTPUT" ]] && exec 3>&-

    # Print summary
    print_summary

    # Show fix suggestions
    $SHOW_FIX && show_common_fixes

    # Exit code
    if $CI_MODE; then
        # In CI mode, only fail on errors (not warnings)
        ((ERROR_COUNTS[error] > 0)) && exit 1
        exit 0
    else
        $failed && exit 1
        exit 0
    fi
}

main "$@"
