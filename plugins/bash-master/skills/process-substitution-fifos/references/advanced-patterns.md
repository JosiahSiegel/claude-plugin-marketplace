# Bash Process Substitution and FIFOs: Advanced Patterns

Detailed recipes for multi-source comparison, tee-style stream splitting, process-substitution-driven diffing, streaming transforms, temporary FIFOs, and cleanup-heavy pipeline compositions. SKILL.md keeps process-substitution basics, named pipes, coprocesses, Bash 5.3 in-shell substitution, pipeline error handling, and best practices.

## Advanced Patterns

### Progress Monitoring with FIFO

```bash
#!/usr/bin/env bash
set -euo pipefail

PROGRESS_PIPE="/tmp/progress_$$"
mkfifo "$PROGRESS_PIPE"
trap 'rm -f "$PROGRESS_PIPE"' EXIT

# Progress monitor
monitor_progress() {
    local total="$1"
    local current=0

    while read -r update; do
        ((current++))
        local pct=$((current * 100 / total))
        printf "\rProgress: [%-50s] %d%%" \
            "$(printf '#%.0s' $(seq 1 $((pct/2))))" "$pct"
    done < "$PROGRESS_PIPE"
    echo
}

# Worker that reports progress
do_work() {
    local items=("$@")
    local item

    for item in "${items[@]}"; do
        process_item "$item"
        echo "done" > "$PROGRESS_PIPE"
    done
}

# Usage
items=(item1 item2 item3 ... item100)
monitor_progress "${#items[@]}" &
MONITOR_PID=$!

do_work "${items[@]}"

exec 3>"$PROGRESS_PIPE"  # Keep pipe open
exec 3>&-                 # Close to signal completion
wait "$MONITOR_PID"
```

### Log Aggregator with Multiple FIFOs

```bash
#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="/tmp/logs_$$"
mkdir -p "$LOG_DIR"

# Create FIFOs for each log level
for level in DEBUG INFO WARN ERROR; do
    mkfifo "$LOG_DIR/$level"
done

trap 'rm -rf "$LOG_DIR"' EXIT

# Aggregator process
aggregate_logs() {
    local output_file="$1"

    # Open all FIFOs for reading
    exec 3<"$LOG_DIR/DEBUG"
    exec 4<"$LOG_DIR/INFO"
    exec 5<"$LOG_DIR/WARN"
    exec 6<"$LOG_DIR/ERROR"

    while true; do
        # Use select-like behavior with read timeout
        read -t 0.1 -r msg <&3 && echo "[DEBUG] $(date '+%H:%M:%S') $msg" >> "$output_file"
        read -t 0.1 -r msg <&4 && echo "[INFO]  $(date '+%H:%M:%S') $msg" >> "$output_file"
        read -t 0.1 -r msg <&5 && echo "[WARN]  $(date '+%H:%M:%S') $msg" >> "$output_file"
        read -t 0.1 -r msg <&6 && echo "[ERROR] $(date '+%H:%M:%S') $msg" >> "$output_file"
    done
}

# Logging functions
log_debug() { echo "$*" > "$LOG_DIR/DEBUG"; }
log_info()  { echo "$*" > "$LOG_DIR/INFO"; }
log_warn()  { echo "$*" > "$LOG_DIR/WARN"; }
log_error() { echo "$*" > "$LOG_DIR/ERROR"; }

# Start aggregator
aggregate_logs "/var/log/app.log" &
AGGREGATOR_PID=$!

# Application code uses logging functions
log_info "Application started"
log_debug "Processing item"
log_warn "Resource running low"
log_error "Critical failure"

# Cleanup
kill "$AGGREGATOR_PID" 2>/dev/null
```

### Data Pipeline with Buffering

```bash
#!/usr/bin/env bash
set -euo pipefail

# Buffered pipeline stage
buffered_stage() {
    local name="$1"
    local buffer_size="${2:-100}"
    local buffer=()

    while IFS= read -r line || [[ ${#buffer[@]} -gt 0 ]]; do
        if [[ -n "$line" ]]; then
            buffer+=("$line")
        fi

        # Flush when buffer full or EOF
        if [[ ${#buffer[@]} -ge $buffer_size ]] || [[ -z "$line" && ${#buffer[@]} -gt 0 ]]; then
            printf '%s\n' "${buffer[@]}" | process_batch
            buffer=()
        fi
    done
}

# Parallel pipeline with process substitution
run_parallel_pipeline() {
    local input="$1"

    cat "$input" | \
        tee >(filter_a | transform_a > output_a.txt) \
            >(filter_b | transform_b > output_b.txt) \
            >(filter_c | transform_c > output_c.txt) \
        > /dev/null

    # Wait for all background processes
    wait
}
```

### Streaming JSON Processing

```bash
#!/usr/bin/env bash
set -euo pipefail

# Stream JSON array elements
stream_json_array() {
    local url="$1"

    # Use jq to stream array elements one per line
    curl -s "$url" | jq -c '.items[]' | while IFS= read -r item; do
        process_json_item "$item"
    done
}

# Parallel JSON processing with process substitution
parallel_json_process() {
    local input="$1"
    local workers=4

    # Split input across workers
    jq -c '.[]' "$input" | \
        parallel --pipe -N100 --jobs "$workers" '
            while IFS= read -r item; do
                echo "$item" | jq ".processed = true"
            done
        ' | jq -s '.'
}

# Transform JSON stream
transform_json_stream() {
    jq -c '.' | while IFS= read -r obj; do
        # Process with bash
        local id
        id=$(echo "$obj" | jq -r '.id')

        # Enrich and output
        echo "$obj" | jq --arg ts "$(date -Iseconds)" '. + {timestamp: $ts}'
    done
}
```

