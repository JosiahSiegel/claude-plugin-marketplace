# Bash Text Processing Without External Commands

Detailed examples for replacing common `sed`, `awk`, `cut`, `tr`, and `basename` patterns with Bash parameter expansion, loops, arrays, and built-ins. SKILL.md keeps parameter expansion, pattern matching, case transformation, regex, splitting/joining, extglob, Bash 5.3 features, and performance guidance.

## Text Processing Without External Commands

### Trim Whitespace

```bash
#!/usr/bin/env bash
set -euo pipefail

# Trim leading whitespace
trim_leading() {
    local str="$1"
    echo "${str#"${str%%[![:space:]]*}"}"
}

# Trim trailing whitespace
trim_trailing() {
    local str="$1"
    echo "${str%"${str##*[![:space:]]}"}"
}

# Trim both
trim() {
    local str="$1"
    str="${str#"${str%%[![:space:]]*}"}"
    str="${str%"${str##*[![:space:]]}"}"
    echo "$str"
}

# Extended pattern matching version (requires shopt -s extglob)
trim_extglob() {
    shopt -s extglob
    local str="$1"
    str="${str##+([[:space:]])}"
    str="${str%%+([[:space:]])}"
    echo "$str"
}

str="   hello world   "
trim "$str"  # "hello world"
```

### String Repetition

```bash
#!/usr/bin/env bash
set -euo pipefail

# Repeat string N times
repeat() {
    local str="$1"
    local n="$2"
    local result=""

    for ((i=0; i<n; i++)); do
        result+="$str"
    done

    echo "$result"
}

repeat "ab" 5  # ababababab

# Using printf
repeat_printf() {
    local str="$1"
    local n="$2"
    printf '%s' $(printf '%.0s'"$str" $(seq 1 "$n"))
}

# Create separator line
separator() {
    local char="${1:--}"
    local width="${2:-80}"
    printf '%*s\n' "$width" '' | tr ' ' "$char"
}

separator "=" 40  # ========================================
```

### Character Replacement

```bash
#!/usr/bin/env bash
set -euo pipefail

str="hello world"

# Using tr-like replacement via expansion
# Replace all 'l' with 'L'
echo "${str//l/L}"  # heLLo worLd

# Delete characters
echo "${str//o/}"   # hell wrld

# Translate character by character
translate() {
    local str="$1"
    local from="$2"
    local to="$3"

    for ((i=0; i<${#from}; i++)); do
        str="${str//${from:$i:1}/${to:$i:1}}"
    done

    echo "$str"
}

translate "hello" "el" "ip"  # hippo
```

### Padding and Alignment

```bash
#!/usr/bin/env bash
set -euo pipefail

# Right pad to width
pad_right() {
    local str="$1"
    local width="$2"
    local char="${3:- }"
    printf "%-${width}s" "$str" | tr ' ' "$char"
}

# Left pad to width
pad_left() {
    local str="$1"
    local width="$2"
    local char="${3:- }"
    printf "%${width}s" "$str" | tr ' ' "$char"
}

# Center align
center() {
    local str="$1"
    local width="$2"
    local len=${#str}
    local padding=$(( (width - len) / 2 ))

    printf "%*s%s%*s" $padding "" "$str" $((width - len - padding)) ""
}

# Zero-pad numbers
zero_pad() {
    local num="$1"
    local width="$2"
    printf "%0${width}d" "$num"
}

zero_pad 42 5  # 00042

# Format table
print_table_row() {
    printf "| %-20s | %10s | %-15s |\n" "$1" "$2" "$3"
}

print_table_row "Name" "Age" "City"
print_table_row "Alice" "30" "New York"
```

