# Bash Parallel Processing: Performance Optimization

Batch sizing, CPU-count tuning, memory-aware concurrency, avoiding process-spawn overhead, and practical benchmarking patterns for Bash parallel jobs. SKILL.md keeps command selection and core orchestration patterns; this reference holds optimization examples.

## Performance Optimization

### Batch Processing

```bash
#!/usr/bin/env bash
set -euo pipefail

# Process in optimal batch sizes
optimal_batch_process() {
    local items=("$@")
    local batch_size=100
    local workers=$(nproc)

    printf '%s\n' "${items[@]}" | \
        parallel --pipe -N"$batch_size" -j"$workers" '
            while IFS= read -r item; do
                process_item "$item"
            done
        '
}

# Dynamic batch sizing based on memory
dynamic_batch() {
    local mem_available
    mem_available=$(free -m | awk '/^Mem:/ {print $7}')

    # Adjust batch size based on available memory
    local batch_size=$((mem_available / 100))  # 100MB per batch
    ((batch_size < 10)) && batch_size=10
    ((batch_size > 1000)) && batch_size=1000

    parallel --pipe -N"$batch_size" process_batch
}
```

### I/O Optimization

```bash
#!/usr/bin/env bash
set -euo pipefail

# Use tmpfs for intermediate files
setup_fast_temp() {
    local tmpdir="/dev/shm/parallel_$$"
    mkdir -p "$tmpdir"
    trap 'rm -rf "$tmpdir"' EXIT
    echo "$tmpdir"
}

# Buffer I/O operations
buffered_parallel() {
    local input="$1"
    local tmpdir
    tmpdir=$(setup_fast_temp)

    # Split input into chunks
    split -l 1000 "$input" "$tmpdir/chunk_"

    # Process chunks in parallel
    parallel process_chunk {} ::: "$tmpdir"/chunk_*

    # Combine results
    cat "$tmpdir"/result_* > output.txt
}

# Avoid disk I/O with process substitution
no_disk_parallel() {
    # Instead of:
    #   command > temp.txt
    #   parallel process ::: temp.txt
    #   rm temp.txt

    # Do this:
    command | parallel --pipe process
}
```

### CPU Affinity

```bash
#!/usr/bin/env bash
set -euo pipefail

# Pin workers to specific CPUs
cpu_pinned_parallel() {
    local num_cpus
    num_cpus=$(nproc)

    for ((cpu=0; cpu<num_cpus; cpu++)); do
        taskset -c "$cpu" process_worker "$cpu" &
    done

    wait
}

# NUMA-aware processing
numa_parallel() {
    local num_nodes
    num_nodes=$(numactl --hardware | grep "available:" | awk '{print $2}')

    for ((node=0; node<num_nodes; node++)); do
        numactl --cpunodebind="$node" --membind="$node" \
            process_chunk "$node" &
    done

    wait
}
```

