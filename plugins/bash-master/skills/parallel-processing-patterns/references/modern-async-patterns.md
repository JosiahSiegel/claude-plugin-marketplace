# Bash Parallel Processing: Modern Async Patterns

Detailed Bash async patterns: collecting PIDs, `wait -n`, bounded concurrency loops, fail-fast job pools, progress reporting, background-process cleanup, and signal-safe teardown. SKILL.md keeps GNU Parallel, xargs, job-control, performance, and error-handling essentials; this reference holds the longer async orchestration examples.

## Modern Async Patterns

### Promise-Like Pattern

```bash
#!/usr/bin/env bash
set -euo pipefail

# Async function wrapper
async() {
    local result_var="$1"
    shift
    local cmd=("$@")

    # Create temp file for result
    local result_file
    result_file=$(mktemp)

    # Run in background, save result
    {
        if "${cmd[@]}" > "$result_file" 2>&1; then
            echo "0" >> "$result_file.status"
        else
            echo "$?" >> "$result_file.status"
        fi
    } &

    # Store PID and result file location
    eval "${result_var}_pid=$!"
    eval "${result_var}_file='$result_file'"
}

# Await result
await() {
    local result_var="$1"
    local pid_var="${result_var}_pid"
    local file_var="${result_var}_file"

    # Wait for completion
    wait "${!pid_var}"

    # Get result
    cat "${!file_var}"
    local status
    status=$(cat "${!file_var}.status")

    # Cleanup
    rm -f "${!file_var}" "${!file_var}.status"

    return "$status"
}

# Usage
async result1 curl -s "https://api1.example.com/data"
async result2 curl -s "https://api2.example.com/data"
async result3 process_local_data

# Do other work here...

# Get results (blocks until complete)
data1=$(await result1)
data2=$(await result2)
data3=$(await result3)
```

### Event Loop Pattern

```bash
#!/usr/bin/env bash
set -euo pipefail

declare -A TASKS
declare -A TASK_RESULTS
TASK_COUNTER=0

# Register async task
schedule() {
    local cmd=("$@")
    local task_id=$((++TASK_COUNTER))
    local output_file="/tmp/task_${task_id}_$$"

    "${cmd[@]}" > "$output_file" 2>&1 &

    TASKS[$task_id]=$!
    TASK_RESULTS[$task_id]="$output_file"

    echo "$task_id"
}

# Check if task complete
is_complete() {
    local task_id="$1"
    ! kill -0 "${TASKS[$task_id]}" 2>/dev/null
}

# Get task result
get_result() {
    local task_id="$1"
    wait "${TASKS[$task_id]}" 2>/dev/null || true
    cat "${TASK_RESULTS[$task_id]}"
    rm -f "${TASK_RESULTS[$task_id]}"
}

# Event loop
run_event_loop() {
    local pending=("${!TASKS[@]}")

    while ((${#pending[@]} > 0)); do
        local still_pending=()

        for task_id in "${pending[@]}"; do
            if is_complete "$task_id"; then
                local result
                result=$(get_result "$task_id")
                on_task_complete "$task_id" "$result"
            else
                still_pending+=("$task_id")
            fi
        done

        pending=("${still_pending[@]}")

        # Small sleep to prevent busy-waiting
        ((${#pending[@]} > 0)) && sleep 0.1
    done
}

# Callback for completed tasks
on_task_complete() {
    local task_id="$1"
    local result="$2"
    echo "Task $task_id complete: ${result:0:50}..."
}
```

### Fan-Out/Fan-In Pattern

```bash
#!/usr/bin/env bash
set -euo pipefail

# Fan-out: distribute work
fan_out() {
    local -n items="$1"
    local workers="$2"
    local worker_func="$3"

    local chunk_size=$(( (${#items[@]} + workers - 1) / workers ))
    local pids=()

    for ((i=0; i<workers; i++)); do
        local start=$((i * chunk_size))
        local chunk=("${items[@]:start:chunk_size}")

        if ((${#chunk[@]} > 0)); then
            $worker_func "${chunk[@]}" &
            pids+=($!)
        fi
    done

    # Return PIDs for fan_in
    echo "${pids[*]}"
}

# Fan-in: collect results
fan_in() {
    local -a pids=($1)
    local results=()

    for pid in "${pids[@]}"; do
        wait "$pid"
    done
}

# Example worker
process_chunk() {
    local items=("$@")
    for item in "${items[@]}"; do
        echo "Processed: $item"
    done
}

# Usage
data=({1..100})
pids=$(fan_out data 4 process_chunk)
fan_in "$pids"
```

### Map-Reduce Pattern

```bash
#!/usr/bin/env bash
set -euo pipefail

# Map function
parallel_map() {
    local -n input="$1"
    local map_func="$2"
    local workers="${3:-$(nproc)}"

    printf '%s\n' "${input[@]}" | \
        parallel -j "$workers" "$map_func"
}

# Reduce function
reduce() {
    local reduce_func="$1"
    local accumulator="$2"

    while IFS= read -r value; do
        accumulator=$($reduce_func "$accumulator" "$value")
    done

    echo "$accumulator"
}

# Example: Sum of squares
square() { echo $(($1 * $1)); }
add() { echo $(($1 + $2)); }

numbers=({1..100})
sum_of_squares=$(
    parallel_map numbers square 4 | reduce add 0
)
echo "Sum of squares: $sum_of_squares"

# Word count example
word_count_map() {
    tr ' ' '\n' | sort | uniq -c
}

word_count_reduce() {
    sort -k2 | awk '{
        if ($2 == prev) { count += $1 }
        else { if (prev) print count, prev; count = $1; prev = $2 }
    } END { if (prev) print count, prev }'
}

cat large_text.txt | \
    parallel --pipe -N1000 word_count_map | \
    word_count_reduce
```

