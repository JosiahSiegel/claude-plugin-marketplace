#!/usr/bin/env bash
#
# script-profiler.sh - Profile bash script execution with timing information
# Version: 1.0.0
#
# Usage: ./script-profiler.sh [OPTIONS] <script> [script-args...]
#
# Options:
#   -o, --output FILE   Write profile data to file (default: stdout)
#   -f, --format FMT    Output format: text, csv, json (default: text)
#   -t, --threshold MS  Only show lines taking >= MS milliseconds (default: 0)
#   -n, --top N         Show only top N slowest lines (default: all)
#   -s, --summary       Show only summary, not line-by-line
#   -c, --commands      Profile external command calls
#   -h, --help          Show this help message
#
# Examples:
#   ./script-profiler.sh myscript.sh arg1 arg2
#   ./script-profiler.sh -n 10 -t 100 slow_script.sh
#   ./script-profiler.sh -f csv -o profile.csv build.sh

set -euo pipefail

# Script metadata
readonly VERSION="1.0.0"
readonly SCRIPT_NAME="${BASH_SOURCE[0]##*/}"

# Configuration
OUTPUT=""
FORMAT="text"
THRESHOLD=0
TOP_N=0
SUMMARY_ONLY=false
PROFILE_COMMANDS=false
TARGET_SCRIPT=""
declare -a SCRIPT_ARGS=()

# Temporary files
TRACE_FILE=""
TIMING_FILE=""

# Colors
setup_colors() {
    if [[ -t 1 ]]; then
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
            -o|--output)
                OUTPUT="$2"
                shift 2
                ;;
            -f|--format)
                FORMAT="$2"
                shift 2
                ;;
            -t|--threshold)
                THRESHOLD="$2"
                shift 2
                ;;
            -n|--top)
                TOP_N="$2"
                shift 2
                ;;
            -s|--summary)
                SUMMARY_ONLY=true
                shift
                ;;
            -c|--commands)
                PROFILE_COMMANDS=true
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
                TARGET_SCRIPT="$1"
                shift
                SCRIPT_ARGS=("$@")
                break
                ;;
        esac
    done

    if [[ -z "$TARGET_SCRIPT" ]]; then
        echo "Error: No script specified" >&2
        show_help
    fi

    if [[ ! -f "$TARGET_SCRIPT" ]]; then
        echo "Error: Script not found: $TARGET_SCRIPT" >&2
        exit 1
    fi
}

# Create temporary files
setup_temp() {
    TRACE_FILE=$(mktemp)
    TIMING_FILE=$(mktemp)
}

# Cleanup
cleanup() {
    rm -f "$TRACE_FILE" "$TIMING_FILE" 2>/dev/null || true
}
trap cleanup EXIT

# Profile the script
run_profile() {
    local script="$1"
    shift

    echo "${BOLD}Profiling: $script${RESET}"
    echo "Arguments: $*"
    echo ""

    # Set PS4 for timing information
    # Format: +<nanoseconds> <source>:<lineno>: <command>
    local ps4_format='+$(date +%s%N) ${BASH_SOURCE[0]:-$0}:${LINENO}: '

    # Run with tracing
    local start_time
    start_time=$(date +%s%N)

    PS4="$ps4_format" bash -x "$script" "$@" 2>"$TRACE_FILE" || true

    local end_time
    end_time=$(date +%s%N)

    local total_ns=$((end_time - start_time))
    local total_ms=$((total_ns / 1000000))

    echo ""
    echo "${BOLD}Total execution time: ${total_ms}ms${RESET}"
    echo ""

    # Parse trace output
    parse_trace "$total_ms"
}

# Parse trace file and generate timing data
parse_trace() {
    local total_ms="$1"
    local prev_time=0
    local line_count=0
    local -A line_times=()
    local -A line_counts=()
    local -A line_sources=()

    echo "${BOLD}Analyzing trace data...${RESET}"

    # Parse each trace line
    while IFS= read -r line; do
        # Match: +<timestamp> <source>:<lineno>: <command>
        if [[ "$line" =~ ^\+([0-9]+)\ ([^:]+):([0-9]+):\ (.*)$ ]]; then
            local timestamp="${BASH_REMATCH[1]}"
            local source="${BASH_REMATCH[2]}"
            local lineno="${BASH_REMATCH[3]}"
            local command="${BASH_REMATCH[4]}"

            # Calculate time spent
            if ((prev_time > 0)); then
                local duration_ns=$((timestamp - prev_time))
                local duration_ms=$((duration_ns / 1000000))

                # Store timing data
                local key="${source}:${lineno}"
                ((line_times[$key] += duration_ms))
                ((line_counts[$key]++))
                line_sources[$key]="$command"
            fi

            prev_time="$timestamp"
            ((line_count++))
        fi
    done < "$TRACE_FILE"

    echo "Processed $line_count trace lines"
    echo ""

    # Output results
    output_results line_times line_counts line_sources "$total_ms"
}

# Output profiling results
output_results() {
    local -n times="$1"
    local -n counts="$2"
    local -n sources="$3"
    local total_ms="$4"

    # Sort by time (descending)
    local -a sorted_keys=()
    for key in "${!times[@]}"; do
        sorted_keys+=("${times[$key]}:$key")
    done

    IFS=$'\n' sorted_keys=($(sort -t: -k1 -rn <<<"${sorted_keys[*]}"))
    unset IFS

    case "$FORMAT" in
        text)
            output_text sorted_keys times counts sources "$total_ms"
            ;;
        csv)
            output_csv sorted_keys times counts sources "$total_ms"
            ;;
        json)
            output_json sorted_keys times counts sources "$total_ms"
            ;;
    esac
}

output_text() {
    local -n sorted="$1"
    local -n times="$2"
    local -n counts="$3"
    local -n sources="$4"
    local total_ms="$5"

    if $SUMMARY_ONLY; then
        echo "${BOLD}Profile Summary${RESET}"
        echo "═══════════════════════════════════════════════════════════════════"
        printf "%-12s %-8s %-8s %s\n" "Time (ms)" "Calls" "Avg (ms)" "Location"
        echo "───────────────────────────────────────────────────────────────────"
    else
        echo "${BOLD}Detailed Profile${RESET}"
        echo "═══════════════════════════════════════════════════════════════════"
        printf "%-12s %-8s %-8s %-6s %s\n" "Time (ms)" "Calls" "Avg (ms)" "%Total" "Location"
        echo "───────────────────────────────────────────────────────────────────"
    fi

    local count=0
    for entry in "${sorted[@]}"; do
        local key="${entry#*:}"
        local time_ms="${times[$key]}"
        local call_count="${counts[$key]}"
        local avg_ms=$((time_ms / call_count))
        local pct=$((time_ms * 100 / (total_ms + 1)))

        # Apply threshold filter
        ((time_ms < THRESHOLD)) && continue

        # Color based on time
        local color=""
        if ((time_ms >= 1000)); then
            color="$RED"
        elif ((time_ms >= 100)); then
            color="$YELLOW"
        elif ((time_ms >= 10)); then
            color="$CYAN"
        fi

        if $SUMMARY_ONLY; then
            printf "${color}%-12s %-8s %-8s %s${RESET}\n" \
                "$time_ms" "$call_count" "$avg_ms" "$key"
        else
            printf "${color}%-12s %-8s %-8s %-6s %s${RESET}\n" \
                "$time_ms" "$call_count" "$avg_ms" "${pct}%" "$key"
            # Show command on next line
            printf "             └─ %s\n" "${sources[$key]:0:60}"
        fi

        ((count++))
        ((TOP_N > 0 && count >= TOP_N)) && break
    done

    echo "═══════════════════════════════════════════════════════════════════"
}

output_csv() {
    local -n sorted="$1"
    local -n times="$2"
    local -n counts="$3"
    local -n sources="$4"
    local total_ms="$5"

    echo "time_ms,calls,avg_ms,pct_total,source,lineno,command"

    local count=0
    for entry in "${sorted[@]}"; do
        local key="${entry#*:}"
        local time_ms="${times[$key]}"
        local call_count="${counts[$key]}"
        local avg_ms=$((time_ms / call_count))
        local pct=$((time_ms * 100 / (total_ms + 1)))

        ((time_ms < THRESHOLD)) && continue

        local source="${key%:*}"
        local lineno="${key#*:}"
        local command="${sources[$key]//\"/\\\"}"

        printf '%s,%s,%s,%s,"%s",%s,"%s"\n' \
            "$time_ms" "$call_count" "$avg_ms" "$pct" "$source" "$lineno" "$command"

        ((count++))
        ((TOP_N > 0 && count >= TOP_N)) && break
    done
}

output_json() {
    local -n sorted="$1"
    local -n times="$2"
    local -n counts="$3"
    local -n sources="$4"
    local total_ms="$5"

    echo "{"
    echo "  \"total_ms\": $total_ms,"
    echo "  \"lines\": ["

    local count=0
    local first=true
    for entry in "${sorted[@]}"; do
        local key="${entry#*:}"
        local time_ms="${times[$key]}"
        local call_count="${counts[$key]}"
        local avg_ms=$((time_ms / call_count))
        local pct=$((time_ms * 100 / (total_ms + 1)))

        ((time_ms < THRESHOLD)) && continue

        local source="${key%:*}"
        local lineno="${key#*:}"
        local command="${sources[$key]//\"/\\\"}"

        $first || echo ","
        first=false

        printf '    {"time_ms": %s, "calls": %s, "avg_ms": %s, "pct": %s, "source": "%s", "line": %s, "command": "%s"}' \
            "$time_ms" "$call_count" "$avg_ms" "$pct" "$source" "$lineno" "$command"

        ((count++))
        ((TOP_N > 0 && count >= TOP_N)) && break
    done

    echo ""
    echo "  ]"
    echo "}"
}

main() {
    setup_colors
    parse_args "$@"
    setup_temp

    # Run profiler
    local output
    if [[ -n "$OUTPUT" ]]; then
        run_profile "$TARGET_SCRIPT" "${SCRIPT_ARGS[@]}" > "$OUTPUT"
        echo "Profile written to: $OUTPUT"
    else
        run_profile "$TARGET_SCRIPT" "${SCRIPT_ARGS[@]}"
    fi

    echo ""
    echo "${GREEN}${BOLD}Profiling complete.${RESET}"
}

main "$@"
