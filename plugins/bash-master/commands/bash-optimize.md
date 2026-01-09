---
name: bash-optimize
description: Optimize bash scripts for performance, reducing execution time and resource usage
argument-hint: <script.sh> [target: speed|memory|both]
---

## CRITICAL GUIDELINES

### Windows File Path Requirements

**MANDATORY: Always Use Backslashes on Windows for File Paths**

When using Edit or Write tools on Windows, you MUST use backslashes (`\`) in file paths, NOT forward slashes (`/`).

---

# Bash Script Optimizer

## Purpose

Analyze and optimize bash scripts for maximum performance, reducing execution time and resource usage while maintaining correctness and readability.

## Optimization Targets

### Speed Optimization
- Reduce subshell spawning
- Replace external commands with bash builtins
- Optimize loop structures
- Implement parallel processing
- Use efficient I/O patterns

### Memory Optimization
- Stream processing instead of loading files
- Efficient array usage
- Proper variable scoping
- Cleanup temporary data
- Avoid unnecessary string copies

## Optimization Techniques

### 1. Subshell Elimination

**Before:**
```bash
# Spawns subshell for each
result=$(echo "$var" | tr 'a-z' 'A-Z')
count=$(cat file.txt | wc -l)
basename=$(basename "$path")
```

**After:**
```bash
# Pure bash - no subshells
result="${var^^}"
count=0; while IFS= read -r _; do ((count++)); done < file.txt
basename="${path##*/}"
```

### 2. External Command Replacement

| External | Bash Equivalent |
|----------|-----------------|
| `basename "$p"` | `"${p##*/}"` |
| `dirname "$p"` | `"${p%/*}"` |
| `echo "$s" \| tr a-z A-Z` | `"${s^^}"` |
| `expr $a + $b` | `$((a + b))` |
| `cat file` | `< file` or `mapfile` |
| `cut -d: -f1` | `"${var%%:*}"` |
| `sed 's/a/b/g'` | `"${var//a/b}"` |

### 3. Loop Optimization

**Before:**
```bash
# Creates subshell, variables lost
cat file.txt | while read -r line; do
    ((count++))
done
echo "$count"  # Always 0!
```

**After:**
```bash
# No subshell, variables preserved
while IFS= read -r line; do
    ((count++))
done < file.txt
echo "$count"  # Correct value
```

### 4. Array vs String Processing

**Before:**
```bash
# Slow: string manipulation
files="file1.txt file2.txt file3.txt"
for f in $files; do
    process "$f"
done
```

**After:**
```bash
# Fast: array iteration
files=("file1.txt" "file2.txt" "file3.txt")
for f in "${files[@]}"; do
    process "$f"
done
```

### 5. File Reading Optimization

**Before:**
```bash
# Multiple reads of same file
grep "pattern1" file.txt > result1.txt
grep "pattern2" file.txt > result2.txt
grep "pattern3" file.txt > result3.txt
```

**After:**
```bash
# Single pass with multiple outputs
while IFS= read -r line; do
    [[ "$line" == *pattern1* ]] && echo "$line" >> result1.txt
    [[ "$line" == *pattern2* ]] && echo "$line" >> result2.txt
    [[ "$line" == *pattern3* ]] && echo "$line" >> result3.txt
done < file.txt
```

### 6. Parallel Processing

**Before:**
```bash
# Sequential processing
for file in *.txt; do
    process_file "$file"
done
```

**After:**
```bash
# Parallel with GNU Parallel
parallel -j "$(nproc)" process_file ::: *.txt

# Or with xargs
printf '%s\0' *.txt | xargs -0 -P "$(nproc)" -I {} process_file {}

# Or with job control
max_jobs=4
for file in *.txt; do
    process_file "$file" &
    ((++running >= max_jobs)) && wait -n && ((running--))
done
wait
```

### 7. Process Substitution

**Before:**
```bash
# Temporary files
sort file1.txt > /tmp/sorted1
sort file2.txt > /tmp/sorted2
diff /tmp/sorted1 /tmp/sorted2
rm /tmp/sorted1 /tmp/sorted2
```

**After:**
```bash
# Process substitution - no temp files
diff <(sort file1.txt) <(sort file2.txt)
```

### 8. Here-String vs Echo Pipe

**Before:**
```bash
echo "$var" | command
```

**After:**
```bash
command <<< "$var"
```

## Optimization Process

When optimizing a script:

1. **Profile first** - Identify actual bottlenecks
2. **Measure baseline** - Record current execution time
3. **Apply optimizations** - Implement changes incrementally
4. **Verify correctness** - Ensure output matches original
5. **Measure improvement** - Quantify the gains

## Profiling Commands

```bash
# Time execution
time ./script.sh

# Detailed timing with bash
TIMEFORMAT='real: %R, user: %U, sys: %S'
time ./script.sh

# Line-by-line profiling
PS4='+ $(date +%s.%N) ${BASH_SOURCE}:${LINENO}: '
set -x
./script.sh
set +x

# Trace with timestamps
bash -x script.sh 2>&1 | ts -s '%.s'
```

## Usage Examples

**General optimization:**
```
/bash-optimize deploy.sh
```

**Focus on speed:**
```
/bash-optimize process.sh target: speed
```

**Focus on memory:**
```
/bash-optimize large-file-handler.sh target: memory
```

**Both speed and memory:**
```
/bash-optimize etl-script.sh target: both
```

## Output Format

```
## Optimization Report: <script>

### Performance Profile
- Original execution time: X.XXs
- Bottlenecks identified: N

### Optimizations Applied
1. [IMPACT: HIGH] Replace `cat | grep` with direct grep
   - Before: 150ms
   - After: 20ms
   - Improvement: 87%

2. [IMPACT: MEDIUM] Use bash string manipulation
   - Replaced: external `basename`
   - With: parameter expansion

### Summary
- Total optimizations: N
- Estimated speedup: X.Xx faster
- Subshells eliminated: N
- External commands replaced: N

### Optimized Script
[Full optimized script or diff]
```

## After Optimization

I will:
1. Show a detailed report of changes
2. Provide the optimized script
3. Explain each optimization
4. Offer to apply changes automatically
5. Suggest further improvements if applicable

---

**Transform slow bash scripts into high-performance automation using proven optimization techniques.**
