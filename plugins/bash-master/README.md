# Bash Master Plugin

Empower Claude with comprehensive bash scripting expertise across all platforms with **Bash 5.3 features** and **2025 security-first practices**. This plugin makes Claude a master of modern bash scripting, cloud-native automation, and production-ready DevOps patterns.

## 🎯 What This Plugin Does

When installed, Claude becomes an expert in:

### 2025 New Features (v1.5.0)
- **Windows Git Bash / MINGW Path Conversion** - Comprehensive path conversion guide (automatic conversion, MSYS_NO_PATHCONV, MSYS2_ARG_CONV_EXCL, cygpath usage)
- **Shell Detection Methods** - Complete guide to detecting Git Bash/MINGW environments ($OSTYPE, uname -s, $MSYSTEM)
- **Claude Code Issue #2602** - Solutions for snapshot path conversion failures on Windows
- **Cross-Platform Path Handling** - Patterns and functions for seamless Windows/Linux/macOS path handling
- **Bash 5.3 Complete** - In-shell command substitution (${ }), REPLY variable syntax (${| }), BASH_TRAPSIG for signal handlers, C23 conformance, GLOBSORT variable
- **ShellCheck v0.11.0** - Latest rules (SC2327/SC2328/SC2294/SC2295), POSIX.1-2024 compliance, Bash 5.3 support
- **Security-First 2025** - Mandatory input validation (60%+ exploits from poor validation), HISTFILE protection, absolute path usage, injection prevention
- **Comprehensive Debugging** - Tracing, profiling, breakpoints, interactive debugging, error recovery, performance analysis
- **Container-Aware Scripting** - Docker/Kubernetes detection, health checks, PID 1 signal handling, minimal Alpine scripts
- **Cloud Provider Integration** - AWS/Azure helpers, secrets management (Secrets Manager/Key Vault), cloud-native patterns
- **Modern CI/CD** - GitHub Actions, Azure DevOps, GitLab CI integration, multi-platform detection
- **DevOps Automation** - Blue-green deployments, canary releases, parallel processing (GNU Parallel/job pools)

### Core Capabilities
- **Cross-platform bash scripting** - Linux, macOS, Windows (Git Bash/WSL), containers
- **Industry best practices** - Google Shell Style Guide (50-line scripts), ShellCheck v0.11.0 mandatory validation
- **POSIX.1-2024 compliance** - Latest POSIX standard support, portable scripts that work everywhere
- **Performance optimization** - Bash 5.3 no-fork substitution (~40% faster), built-in optimizations
- **Debugging & Troubleshooting** - Comprehensive tracing, profiling, breakpoints, and error recovery techniques
- **Testing** - Unit testing with BATS, integration testing, CI/CD integration
- **Error handling** - Robust error management (set -euo pipefail), exit codes, trap handlers with BASH_TRAPSIG

## 📦 Installation

### Via GitHub Marketplace (Recommended)

```bash
/plugin marketplace add JosiahSiegel/claude-code-marketplace
/plugin install bash-master@claude-plugin-marketplace
```

### Local Installation (Mac/Linux)

⚠️ **Windows users:** Use the GitHub marketplace method instead.

```bash
# Extract to plugins directory
unzip bash-master.zip -d ~/.local/share/claude/plugins/
```

## 🚀 Features

### Comprehensive Skill Knowledge

This plugin includes comprehensive bash-master skills that teach Claude:

1. **Bash 5.3 Features (2025) - Complete**
   - In-shell command substitution (${ command; }) - runs in current shell context
   - REPLY variable substitution (${| command; })
   - BASH_TRAPSIG variable for signal handlers (know which signal triggered trap)
   - Enhanced read builtin with -E option (readline support)
   - Enhanced source builtin with -p PATH option
   - compgen variable output option
   - GLOBSORT variable for sorting glob results
   - fltexpr loadable builtin for floating-point arithmetic
   - C23 language standard conformance
   - Performance improvements (~40% faster in benchmarks)
   - Latest stable version (no Bash 5.4 as of October 2025)

2. **Security-First Patterns (2025 Enhanced)**
   - Mandatory input validation (pattern matching, length checks)
   - Command injection prevention (no eval, array usage, -- separator)
   - Path traversal protection (sanitization, validation)
   - Secure temporary file handling (mktemp, proper permissions)
   - Secrets management (no hardcoding, cloud secret managers)
   - Privilege management (least privilege, root rejection)
   - Environment variable sanitization
   - **HISTFILE protection** (disable history for credential operations)
   - **Absolute path usage** (prevent PATH hijacking attacks)
   - Automated security scanning patterns

3. **Modern Automation Patterns (2025)**
   - Container-aware scripting (Docker/Kubernetes detection)
   - Health check patterns (quick probes, HTTP endpoints)
   - CI/CD platform helpers (GitHub Actions, Azure DevOps, GitLab)
   - Cloud provider integration (AWS, Azure helpers)
   - Parallel processing (GNU Parallel, job pools)
   - Deployment patterns (blue-green, canary)
   - Structured logging (JSON logs)

4. **ShellCheck v0.11.0 CI/CD Integration (2025)**
   - **Latest version (August 2025)** with Bash 5.3 support
   - **New rules**: SC2327/SC2328 (capture groups), SC2294 (eval arrays), SC2295 (quote expansions)
   - **POSIX.1-2024 compliance** (SC3013 removed - operators now standard)
   - Mandatory validation in pipelines
   - GitHub Actions integration patterns
   - Azure DevOps integration patterns
   - Git hook pre-commit validation
   - VS Code integration
   - Docker build validation

5. **Platform-Specific Expertise**
   - Linux-specific features (systemd, /proc, package managers)
   - macOS BSD vs GNU command differences
   - Git Bash limitations and workarounds
   - WSL1 vs WSL2 considerations
   - Container environments (Docker, Kubernetes)
   - Cross-platform compatibility patterns

6. **Debugging & Troubleshooting (2025 New)**
   - Debug mode techniques (set -x, PS4 customization)
   - Execution time profiling and performance analysis
   - Function call tracing and variable inspection
   - Trap-based error handlers with stack traces
   - Dry-run mode and rollback on failure
   - Interactive breakpoints for debugging
   - Common issue patterns and solutions
   - Structured logging and log rotation

7. **Best Practices & Standards**
   - Script structure templates (with 2025 standards)
   - Safety settings (set -euo pipefail)
   - Naming conventions and style guidelines
   - Function design patterns
   - Input validation
   - Documentation standards
   - Production-ready checklists

## 💡 Usage

Once installed, simply ask Claude to help with any bash scripting task:

### Examples

**Create a professional bash script:**
```
Create a bash script that backs up a directory to S3 with error handling,
logging, and proper cleanup
```

Claude will create a script following all 2025 best practices, with:
- Bash 5.3 features (if applicable)
- Proper shebang and safety settings
- Security-first input validation
- Error handling with trap
- Cross-platform compatibility
- ShellCheck compliance
- Comprehensive documentation

**Create container-aware script:**
```
Create a health check script for my Docker container
```

Claude will create:
- Container environment detection
- Quick health checks (< 1 second)
- Proper PID 1 signal handling
- HTTP endpoint validation
- File-based readiness checks

**Create CI/CD helper:**
```
Create a script that works in both GitHub Actions and Azure DevOps
```

Claude will implement:
- Multi-platform CI detection
- Universal output/error functions
- Platform-specific annotations
- Job summaries and logs

**Review existing scripts:**
```
Review this bash script for security issues and best practices
```

Claude will analyze using knowledge of:
- Security vulnerabilities (60%+ exploit patterns)
- Common anti-patterns
- Performance issues
- Platform compatibility problems
- ShellCheck warnings

## 🎓 What Claude Learns

### Script Safety (2025)
- Always use `set -euo pipefail`
- Safe IFS settings (`IFS=$'\n\t'`)
- Proper variable quoting
- Trap handlers for cleanup
- Error messages to stderr

### Security-First (2025)
- Mandatory input validation with regex
- Maximum length enforcement
- Command injection prevention (no eval, arrays, --)
- Path traversal protection
- Secure temporary files (mktemp + chmod 600)
- Secrets from secure storage (not hardcoded)
- Privilege management (no root unless necessary)

### Performance (2025)
- Bash 5.3 in-shell substitution (~40% faster)
- Avoiding unnecessary subshells
- Using bash built-ins
- Efficient loops
- Array operations
- Process substitution

### Container Awareness (2025)
- Detecting Docker/Kubernetes environments
- PID 1 signal handling
- Health check patterns
- Minimal Alpine scripts (/bin/sh)
- Container-specific paths

### Cloud Integration (2025)
- AWS helpers (Secrets Manager, S3, STS)
- Azure helpers (Key Vault, Blob Storage, Managed Identity)
- Cloud-native patterns
- Retry logic with backoff

### CI/CD Integration (2025)
- GitHub Actions outputs and annotations
- Azure DevOps logging and variables
- GitLab CI patterns
- Multi-platform detection
- Structured logging

### Testing
- Unit testing with BATS
- Integration testing patterns
- CI/CD integration
- ShellCheck validation
- Cross-platform testing

## 📚 Reference Materials

The plugin includes comprehensive reference documentation:

- **windows-git-bash-paths.md** - Complete Windows Git Bash path conversion and shell detection guide
- **bash-53-features.md** - Complete Bash 5.3 feature guide (BASH_TRAPSIG, C23, all features)
- **security-first-2025.md** - Security-first patterns (HISTFILE, absolute paths, validation)
- **modern-automation-patterns.md** - Container, cloud, and CI/CD patterns
- **shellcheck-cicd-2025.md** - ShellCheck v0.11.0 integration with latest rules
- **debugging-troubleshooting-2025.md** - **NEW** Comprehensive debugging techniques
- **platform_specifics.md** - Detailed platform differences and workarounds
- **best_practices.md** - Industry standards and comprehensive guidelines
- **patterns_antipatterns.md** - Common patterns and pitfalls with solutions
- **resources.md** - Authoritative sources and tools directory

## 🔍 Quality Assurance

Every script Claude creates with this plugin will:

- ✅ Pass ShellCheck with no warnings
- ✅ Include mandatory input validation (security-first)
- ✅ Include proper error handling (`set -euo pipefail`)
- ✅ Quote all variable expansions
- ✅ Use Bash 5.3 features where applicable (with fallbacks)
- ✅ Work across target platforms
- ✅ Follow industry standards (Google Shell Style Guide)
- ✅ Include appropriate documentation
- ✅ Handle edge cases properly
- ✅ Be secure, robust, and maintainable

## 🌐 Platform Support

- **Linux** - Full support, all features (Bash 5.3 on Ubuntu 24.04+)
- **macOS** - Full support with BSD compatibility notes (Bash 5.3 via Homebrew)
- **Windows (Git Bash)** - Comprehensive support with path conversion guide (windows-git-bash-paths.md)
- **Windows (WSL)** - Full Linux support with WSL-specific guidance
- **Containers** - Docker and Kubernetes-aware scripting (Alpine/Debian/Ubuntu)

## 🛠️ Tools & Standards

This plugin teaches Claude to use and recommend:

- **Bash 5.3** - Latest bash features (July 2025, no 5.4 yet)
- **ShellCheck v0.11.0** - Latest static analysis (August 2025, mandatory)
- **POSIX.1-2024** - Latest POSIX standard compliance
- **shfmt** - Shell script formatter
- **BATS** - Bash Automated Testing System
- **checkbashisms** - POSIX compliance checker
- **Google Shell Style Guide** - Industry-standard practices (50-line recommendation)
- **Security scanners** - Custom security linting patterns
- **Debugging tools** - Tracing, profiling, and troubleshooting utilities

## 🤝 Contributing

This plugin is part of the claude-code-marketplace. Contributions welcome!

## 📄 License

MIT License - Feel free to use, modify, and distribute.

## 🔗 Resources

- [Bash 5.3 Release Notes](https://lists.gnu.org/archive/html/bash-announce/2025-07/msg00000.html)
- [Bash Manual](https://www.gnu.org/software/bash/manual/)
- [POSIX Shell Standard](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html)
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- [ShellCheck](https://www.shellcheck.net/)
- [Bash Pitfalls](https://mywiki.wooledge.org/BashPitfalls)
- [Container Best Practices](https://cloud.google.com/architecture/best-practices-for-building-containers)

## 🎯 Next Steps

1. Install the plugin
2. Ask Claude to create or review a bash script
3. Watch Claude apply professional 2025 best practices automatically
4. Learn from Claude's comprehensive knowledge of modern bash scripting

---

**Made with ❤️ for the Claude Code community**

Empower your bash scripting with Bash 5.3 and 2025 security-first expertise!
