#!/usr/bin/env bash
#
# parallel-runner.sh - Execute commands in parallel with job control
# Version: 1.0.0
#
# Usage: ./parallel-runner.sh [OPTIONS] -- <command> [args...]
#        ./parallel-runner.sh [OPTIONS] -f <file>
#
# Options:
#   -j, --jobs N      Maximum parallel jobs (default: number of CPUs)
#   -f, --file FILE   Read commands from file (one per line)
#   -t, --timeout N   Timeout per command in seconds (default: none)
#   -r, --retries N   Number of retries on failure (default: 0)
#   -v, --verbose     Show command output
#   -q, --quiet       Suppress all output except errors
#   -d, --dry-run     Show commands without executing
#   -h, --help        Show this help message
#
# Examples:
#   ./parallel-runner.sh -j 4 -- echo {} ::: arg1 arg2 arg3
#   ./parallel-runner.sh -f commands.txt -j 8
#   find . -name "*.txt" | ./parallel-runner.sh -j 4 -- wc -l

set -euo pipefail

# Script metadata
readonly VERSION="1.0.0"
readonly SCRIPT_NAME="${BASH_SOURCE[0]##*/}"

# Default configuration
MAX_JOBS=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
TIMEOUT=""
RETRIES=0
VERBOSE=false
QUIET=false
DRY_RUN=false
COMMAND_FILE=""
declare -a COMMAND=()
declare -a INPUTS=()

# Stats
TOTAL=0
COMPLETED=0
FAILED=0
RUNNING=0

# Job tracking
declare -A JOB_PIDS=()
declare -A JOB_CMDS=()
declare -A JOB_STARTS=()

# Colors (if terminal)
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

# Logging
log_info()  { $QUIET || echo "${BLUE}[INFO]${RESET} $*" >&2; }
log_warn()  { echo "${YELLOW}[WARN]${RESET} $*" >&2; }
log_error() { echo "${RED}[ERROR]${RESET} $*" >&2; }
log_ok()    { $QUIET || echo "${GREEN}[OK]${RESET} $*" >&2; }

show_help() {
    sed -n '/^# Usage:/,/^[^#]/p' "$0" | grep '^#' | sed 's/^# //' | sed 's/^#//'
    exit 0
}

show_version() {
    echo "$SCRIPT_NAME version $VERSION"
    exit 0
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -j|--jobs)
                MAX_JOBS="$2"
                shift 2
                ;;
            -f|--file)
                COMMAND_FILE="$2"
                shift 2
                ;;
            -t|--timeout)
                TIMEOUT="$2"
                shift 2
                ;;
            -r|--retries)
                RETRIES="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -q|--quiet)
                QUIET=true
                shift
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -h|--help)
                show_help
                ;;
            --version)
                show_version
                ;;
            --)
                shift
                # Everything after -- is the command template
                while [[ $# -gt 0 ]]; do
                    if [[ "$1" == ":::" ]]; then
                        shift
                        INPUTS=("$@")
                        break
                    fi
                    COMMAND+=("$1")
                    shift
                done
                break
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
}

# Execute single command with retry support
run_command() {
    local cmd="$1"
    local attempt=0
    local max_attempts=$((RETRIES + 1))
    local exit_code

    while ((attempt < max_attempts)); do
        ((attempt++))

        if $DRY_RUN; then
            echo "[DRY-RUN] $cmd"
            return 0
        fi

        $VERBOSE && log_info "Running: $cmd"

        if [[ -n "$TIMEOUT" ]]; then
            if timeout "$TIMEOUT" bash -c "$cmd"; then
                return 0
            else
                exit_code=$?
            fi
        else
            if bash -c "$cmd"; then
                return 0
            else
                exit_code=$?
            fi
        fi

        if ((attempt < max_attempts)); then
            log_warn "Command failed (attempt $attempt/$max_attempts), retrying..."
            sleep 1
        fi
    done

    return "$exit_code"
}

# Start a new job
start_job() {
    local cmd="$1"
    local job_id="$2"

    run_command "$cmd" &
    local pid=$!

    JOB_PIDS[$job_id]=$pid
    JOB_CMDS[$job_id]="$cmd"
    JOB_STARTS[$job_id]=$(date +%s)
    ((RUNNING++))
}

# Wait for any job to complete
wait_for_slot() {
    if ((RUNNING >= MAX_JOBS)); then
        # Wait for any job to complete
        local completed_pid
        wait -n -p completed_pid 2>/dev/null || wait -n

        # Find which job completed
        for job_id in "${!JOB_PIDS[@]}"; do
            if ! kill -0 "${JOB_PIDS[$job_id]}" 2>/dev/null; then
                # Get exit status
                wait "${JOB_PIDS[$job_id]}" 2>/dev/null
                local exit_code=$?

                if ((exit_code == 0)); then
                    ((COMPLETED++))
                    $QUIET || log_ok "Completed: ${JOB_CMDS[$job_id]}"
                else
                    ((FAILED++))
                    log_error "Failed (exit $exit_code): ${JOB_CMDS[$job_id]}"
                fi

                unset "JOB_PIDS[$job_id]"
                unset "JOB_CMDS[$job_id]"
                unset "JOB_STARTS[$job_id]"
                ((RUNNING--))
                break
            fi
        done
    fi
}

# Wait for all remaining jobs
wait_all() {
    while ((RUNNING > 0)); do
        wait_for_slot
    done
}

# Process commands from file
process_file() {
    local file="$1"

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" == \#* ]] && continue

        ((TOTAL++))
        wait_for_slot
        start_job "$line" "$TOTAL"
    done < "$file"
}

# Process stdin
process_stdin() {
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" ]] && continue

        # Replace {} with input
        local cmd="${COMMAND[*]}"
        cmd="${cmd//\{\}/$line}"

        ((TOTAL++))
        wait_for_slot
        start_job "$cmd" "$TOTAL"
    done
}

# Process input list
process_inputs() {
    for input in "${INPUTS[@]}"; do
        # Replace {} with input
        local cmd="${COMMAND[*]}"
        cmd="${cmd//\{\}/$input}"

        ((TOTAL++))
        wait_for_slot
        start_job "$cmd" "$TOTAL"
    done
}

# Print summary
print_summary() {
    $QUIET && return

    echo ""
    echo "================================"
    echo "Parallel Runner Summary"
    echo "================================"
    echo "Total jobs:     $TOTAL"
    echo "Completed:      $COMPLETED"
    echo "Failed:         $FAILED"
    echo "Max parallel:   $MAX_JOBS"
    echo "================================"

    if ((FAILED > 0)); then
        echo "${RED}Some jobs failed!${RESET}"
    else
        echo "${GREEN}All jobs completed successfully${RESET}"
    fi
}

# Cleanup on exit
cleanup() {
    local exit_code=$?

    # Kill any remaining jobs
    for pid in "${JOB_PIDS[@]}"; do
        kill "$pid" 2>/dev/null || true
    done

    print_summary
    exit "$exit_code"
}

trap cleanup EXIT INT TERM

main() {
    setup_colors
    parse_args "$@"

    log_info "Starting parallel runner with $MAX_JOBS jobs"

    if [[ -n "$COMMAND_FILE" ]]; then
        # Process commands from file
        process_file "$COMMAND_FILE"
    elif [[ ${#COMMAND[@]} -gt 0 ]]; then
        if [[ ${#INPUTS[@]} -gt 0 ]]; then
            # Process with ::: input list
            process_inputs
        elif [[ ! -t 0 ]]; then
            # Process stdin
            process_stdin
        else
            log_error "No input provided. Use ::: or pipe input."
            exit 1
        fi
    else
        log_error "No command specified. Use -- <command> or -f <file>"
        exit 1
    fi

    wait_all

    # Return failure if any job failed
    ((FAILED > 0)) && exit 1
    exit 0
}

main "$@"
