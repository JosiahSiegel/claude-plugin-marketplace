# Bash Master Plugin v2.0.0

Comprehensive bash scripting expertise with **Bash 5.3 features**, **2025 security-first practices**, advanced array patterns, parallel processing, and cross-platform support. This plugin makes Claude a master of modern bash scripting, cloud-native automation, and production-ready DevOps patterns.

## What's New in v2.0.0

### New Skills
- **Advanced Array Patterns** - mapfile, readarray, associative arrays, set operations, stack/queue implementations
- **Process Substitution & FIFOs** - Named pipes, coprocesses, bidirectional IPC, streaming patterns
- **Parallel Processing Patterns** - GNU Parallel, xargs -P, job pools, worker patterns, map-reduce
- **String Manipulation Mastery** - Parameter expansion, regex matching, pattern substitution, case transformation

### New Commands
- `/bash-analyze <script>` - Deep analysis for security, performance, portability, and best practices
- `/bash-template <type>` - Generate production-ready templates (cli, daemon, library, installer, ci)
- `/bash-optimize <script>` - Performance optimization with profiling and benchmarking

### New Agent
- **bash-expert** - Autonomous agent for complex multi-file bash development, debugging, and optimization

### New Utility Scripts
- `parallel-runner.sh` - Execute commands in parallel with job control and retry support
- `shellcheck-batch.sh` - Batch ShellCheck analysis with summary reporting
- `script-profiler.sh` - Profile script execution with timing information

## Features

### Core Capabilities
- **Cross-platform scripting** - Linux, macOS, Windows (Git Bash/WSL), containers
- **Bash 5.3 features** - `${ }` in-shell substitution, `${| }` REPLY syntax, BASH_TRAPSIG, GLOBSORT, fltexpr
- **Security-first patterns** - Input validation, command injection prevention, secure temp files
- **ShellCheck v0.11.0** - Latest rules (SC2327/SC2328), POSIX.1-2024 compliance
- **Performance optimization** - Subshell elimination, builtin usage, parallel processing

### Skills Library (10 skills)

| Skill | Description |
|-------|-------------|
| `bash-master` | Core bash scripting mastery |
| `bash-53-features` | Complete Bash 5.3 feature guide |
| `security-first-2025` | Security patterns and hardening |
| `modern-automation-patterns` | Container/CI/CD/cloud automation |
| `debugging-troubleshooting-2025` | Debug, trace, and profile techniques |
| `shellcheck-cicd-2025` | ShellCheck v0.11.0 integration |
| `advanced-array-patterns` | Array manipulation and data structures |
| `process-substitution-fifos` | IPC with pipes and coprocesses |
| `parallel-processing-patterns` | Concurrent execution patterns |
| `string-manipulation-mastery` | String operations without external commands |

### Commands

| Command | Description | Usage |
|---------|-------------|-------|
| `/bash-analyze` | Analyze scripts for issues | `/bash-analyze deploy.sh` |
| `/bash-template` | Generate templates | `/bash-template cli --full` |
| `/bash-optimize` | Optimize performance | `/bash-optimize slow.sh` |
| `/pwsh-script` | Create/review scripts | `/pwsh-script Create backup script` |

### Agent

**bash-expert** - Use for complex tasks:
- Multi-file script development
- Difficult debugging scenarios
- Performance optimization projects
- Cross-platform automation

## Installation

### Via GitHub Marketplace (Recommended)

```bash
/plugin marketplace add JosiahSiegel/claude-plugin-marketplace
/plugin install bash-master@claude-plugin-marketplace
```

### Local Installation

```bash
unzip bash-master.zip -d ~/.local/share/claude/plugins/
```

## Usage Examples

### Create a Script
```
Create a backup script that archives /data to S3 with error handling and logging
```

### Analyze Existing Script
```
/bash-analyze deploy.sh focus on security vulnerabilities
```

### Generate Template
```
/bash-template daemon --full --logging
```

### Optimize Performance
```
/bash-optimize process.sh target: speed
```

### Complex Task (Agent)
```
I need to create a complete CI/CD deployment system with parallel builds and rollback support
```

## Quality Standards

Every script created with this plugin will:

- Pass ShellCheck with no warnings
- Include `set -euo pipefail` safety settings
- Validate all inputs (security-first)
- Quote all variable expansions
- Use modern Bash 5.x features where applicable
- Work across target platforms
- Follow Google Shell Style Guide
- Include proper error handling with trap
- Be secure, robust, and maintainable

## Skills Deep Dive

### Advanced Array Patterns
```bash
# Associative arrays for caching
declare -A CACHE
cached_lookup() {
    local key="$1"
    [[ -n "${CACHE[$key]+x}" ]] && { echo "${CACHE[$key]}"; return; }
    CACHE[$key]=$(expensive_operation "$key")
    echo "${CACHE[$key]}"
}

# Set operations
array_intersection arr1 arr2  # Elements in both
array_union arr1 arr2         # All unique elements
array_difference arr1 arr2    # Elements only in arr1
```

### Parallel Processing
```bash
# GNU Parallel
parallel -j 8 --bar process_file ::: *.txt

# Job pool with bash
for item in "${items[@]}"; do
    run_with_limit process "$item"
done
wait
```

### Process Substitution
```bash
# Compare sorted outputs without temp files
diff <(sort file1.txt) <(sort file2.txt)

# Multiple output streams
tar cf - /data | tee >(gzip > backup.tar.gz) >(sha256sum > checksum.txt)
```

### String Manipulation
```bash
# Pure bash - no external commands
basename="${path##*/}"      # Instead of basename
dirname="${path%/*}"        # Instead of dirname
upper="${str^^}"            # Instead of tr a-z A-Z
trimmed="${str#"${str%%[![:space:]]*}"}"  # Trim whitespace
```

## Platform Support

| Platform | Support Level | Notes |
|----------|--------------|-------|
| Linux | Full | Bash 5.3 on Ubuntu 24.04+ |
| macOS | Full | Bash 5.3 via Homebrew |
| Windows (Git Bash) | Full | Path conversion guide included |
| Windows (WSL) | Full | Full Linux compatibility |
| Containers | Full | Docker/Kubernetes aware |

## Resources

- [Bash 5.3 Release Notes](https://lists.gnu.org/archive/html/bash-announce/2025-07/msg00000.html)
- [GNU Parallel Tutorial](https://www.gnu.org/software/parallel/parallel_tutorial.html)
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- [ShellCheck](https://www.shellcheck.net/)
- [Bash Pitfalls](https://mywiki.wooledge.org/BashPitfalls)

## Changelog

### v2.0.0 (2025)
- Added 4 new comprehensive skills
- Added 3 new commands with argument hints
- Added bash-expert agent
- Added 3 utility scripts
- Enhanced plugin description for better discoverability
- Updated keywords for new capabilities

### v1.5.1
- Windows Git Bash path conversion guide
- Bash 5.3 complete features
- ShellCheck v0.11.0 support
- Security-first 2025 patterns
- Debugging and troubleshooting guide

## License

MIT License

---

**Empower your bash scripting with modern best practices and expert-level automation.**
