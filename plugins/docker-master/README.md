# Docker Master Plugin

Master Docker across Windows, Linux, and macOS with expert knowledge of best practices, security, optimization, and industry standards.

## Overview

The Docker Master plugin equips Claude Code with comprehensive Docker expertise, enabling you to build, run, optimize, secure, and debug containers following current industry standards across all platforms.

## Features

### Commands

- **`/docker-ai`** - Use Docker AI Assistant (Project Gordon) for intelligent container development (Docker Desktop 4.47+)
- **`/docker-build`** - Build Docker images following current best practices and industry standards
- **`/docker-run`** - Run Docker containers with proper configuration and best practices
- **`/docker-compose`** - Manage multi-container applications with Docker Compose v2.40.3+ using best practices
- **`/docker-optimize`** - Optimize Docker images for size, build time, and runtime performance
- **`/docker-security`** - Scan and harden Docker containers following security best practices
- **`/docker-debug`** - Debug Docker containers and troubleshoot common issues across all platforms
- **`/docker-cleanup`** - Clean up Docker resources safely and efficiently across all platforms
- **`/docker-registry`** - Manage container registry operations (Docker Hub, GitHub, AWS ECR, Azure ACR, Google Artifact Registry)
- **`/docker-network`** - Master Docker networking including bridge, host, overlay networks, and advanced configurations

### Agents

- **Docker Expert Agent** - A comprehensive Docker expert with knowledge of:
  - Container architecture and internals
  - Cross-platform mastery (Windows, Linux, macOS)
  - Security hardening and compliance
  - Performance optimization
  - Current best practices and industry standards
  - Systematic troubleshooting
  - Production operations

### Skills

- **docker-2025-features** - Latest Docker 2025 features including AI Assistant, Enhanced Container Isolation, and Moby 25
- **docker-best-practices** - Comprehensive Docker best practices for images, containers, and production deployments
- **docker-security-guide** - Complete security guidelines and threat mitigation strategies
- **docker-platform-guide** - Platform-specific considerations for Windows, Linux, and macOS
- **docker-git-bash-guide** - Comprehensive Windows Git Bash/MINGW path conversion guide for Docker volume mounts (NEW)

## Installation

### Via Marketplace

```bash
/plugin marketplace add JosiahSiegel/claude-plugin-marketplace
/plugin install docker-master@claude-plugin-marketplace
```

## Usage

### Using Docker AI Assistant (NEW 2025)

```bash
/docker-ai
```

Claude will help you leverage Docker's AI Assistant (Project Gordon) for:
1. Natural language Docker queries
2. Intelligent troubleshooting
3. Automated Dockerfile optimization
4. Context-aware best practice recommendations
5. Local AI model execution (Model Runner)

**Requires:** Docker Desktop 4.38+ with AI beta features enabled

### Building Optimized Images

```bash
/docker-build
```

Claude will:
1. Check latest Docker best practices (2025 standards)
2. Analyze your current Dockerfile
3. Detect target platform (Windows/Linux/macOS)
4. Apply security and optimization best practices
5. **Generate SBOM** (Software Bill of Materials) for supply chain security
6. Provide build commands with recommended flags
7. Validate the result

### Running Containers Securely

```bash
/docker-run
```

Claude will:
1. Research latest security recommendations
2. Configure proper resource limits
3. Set up network isolation
4. Apply security hardening
5. Implement health checks
6. Provide complete run command

### Managing Multi-Container Apps

```bash
/docker-compose
```

Claude will:
1. Review or create docker-compose.yml
2. Apply current best practices
3. Configure security, networking, and resources
4. Provide platform-specific optimizations

### Optimizing for Performance

```bash
/docker-optimize
```

Claude will:
1. Analyze current image size and layers
2. Implement multi-stage builds
3. Optimize layer caching
4. Reduce image size
5. Improve build performance
6. Provide before/after comparison

### Security Scanning & Hardening

```bash
/docker-security
```

Claude will:
1. Scan for vulnerabilities (CVEs) with Docker Scout/Trivy
2. Check against **CIS Docker Benchmark v1.7.0** (2025)
3. **Generate SBOM** for supply chain transparency
4. Recommend **Wolfi/Chainguard images** for zero-CVE deployments
5. Harden Dockerfile and runtime config
6. Implement secrets management
7. Apply principle of least privilege
8. Provide comprehensive security audit report

### Debugging Issues

```bash
/docker-debug
```

Claude will:
1. Systematically diagnose the issue
2. Provide platform-specific solutions
3. Show debugging commands
4. Explain root cause
5. Suggest prevention strategies

### Cleaning Up Resources

```bash
/docker-cleanup
```

Claude will:
1. Assess current disk usage
2. Provide safe cleanup commands
3. Warn about data loss risks
4. Show platform-specific cleanup methods
5. Verify space reclaimed

## Expert Consultation

For complex Docker questions or architectural guidance:

```bash
/agent docker-expert
```

The Docker Expert agent can help with:
- Dockerfile reviews and optimization
- Security hardening strategies
- Architecture design for multi-container apps
- CI/CD integration
- Production deployment planning
- Performance troubleshooting
- Platform-specific challenges

## Platform Support

### Linux ✅
- Full native Docker support
- Best performance
- All features available
- SELinux/AppArmor integration
- Production-ready configurations

### macOS ✅
- Docker Desktop support
- Apple Silicon (M1/M2/M3) optimization
- File sharing performance tips
- Development workflow optimization
- Multi-platform build support

### Windows ✅
- Docker Desktop support
- WSL2 and Hyper-V backends
- Path format handling
- Windows containers support
- Cross-platform compatibility
- **Git Bash/MINGW path conversion fixes** (MSYS_NO_PATHCONV)

## What's New in 2025

### v1.5.0 - Git Bash/MINGW Path Conversion Support

**NEW: Comprehensive Windows Git Bash compatibility:**
- **docker-git-bash-guide skill** - Complete guide to MSYS_NO_PATHCONV and Docker volume mount path conversion
- **Shell detection** - Automatic detection of Git Bash/MINGW environments
- **Path conversion fixes** - Solutions for `$(pwd)`, bind mounts, and absolute paths
- **Troubleshooting guidance** - Common issues and step-by-step solutions
- **Best practices** - Recommended ~/.bashrc configuration for Git Bash users

**Updates:**
- **docker-run.md** - Added Git Bash path conversion section with MSYS_NO_PATHCONV examples
- **docker-compose.md** - Added Git Bash command-line override guidance
- **docker-platform-guide.md** - Expanded Windows section with comprehensive Git Bash coverage
- **README.md** - Updated platform support and skill list

**Problem Solved:**
Git Bash on Windows automatically converts Docker volume mount paths incorrectly:
```bash
# Before (BROKEN):
docker run -v $(pwd):/app myimage
# Converts to: C:\Program Files\Git\d\repos\project:/app

# After (WORKS):
MSYS_NO_PATHCONV=1 docker run -v $(pwd):/app myimage
```

### v1.4.0 - Docker Engine 28 & Desktop 4.47

This plugin includes the latest Docker 2025 features:

### Docker Engine 28
- **Image Type Mounts** - Mount images directly as read-only filesystems without extraction
- **Versioned Debug Endpoints** - Access profiling and debug data through standard API paths
- **Component Updates** - Buildx v0.26.1, Compose v2.40.3, BuildKit v0.25.1
- **Security Fixes** - CVE-2025-54388 firewalld port binding fix

### Docker Desktop 4.47
- **MCP Catalog** - 100+ verified Model Context Protocol servers for AI workflows
- **Model Runner Enhancements** - Improved UI, `docker model requests` monitoring, model cards
- **Silent Component Updates** - Automatic background updates without full restart
- **Security Fixes** - CVE-2025-10657 (ECI), CVE-2025-9074 (container escape)

### Docker Compose v2.40.3
- **Compose Bridge** - Convert compose.yaml to Kubernetes manifests
- **No Version Field** - Modern format removes version requirement
- **Watch Enhancements** - `initial_sync`, `--prune`, `--quiet` options

### Previous 2025 Features
- **Docker AI (Project Gordon)** - AI-powered assistant for intelligent Docker development
- **Enhanced Container Isolation (ECI)** - Advanced security layer for Docker Desktop
- **Model Runner** - Run AI models locally without cloud APIs
- **Multi-Node Kubernetes** - Test realistic cluster scenarios in Docker Desktop

## Key Principles

This plugin ensures Claude always:

1. **Checks Latest Standards** - Searches for current best practices before making recommendations
2. **Platform-Aware** - Provides platform-specific guidance for Windows, Linux, and macOS
3. **Security-First** - Prioritizes security in all recommendations
4. **Explains Why** - Teaches principles, not just commands
5. **Production-Ready** - Provides configurations suitable for production use
6. **Comprehensive** - Covers full Docker lifecycle from build to deployment
7. **Future-Ready** - Includes 2025 features (AI, ECI, Moby 25)

## Best Practices Applied

### Images
- Official, minimal base images with exact version tags
- **2025:** Wolfi/Chainguard images for zero-CVE production deployments
- Multi-stage builds for smaller, more secure images (60-80% size reduction)
- Efficient layer caching for faster builds
- Comprehensive .dockerignore files
- **MANDATORY:** SBOM generation for every build

### Security (2025 Standards)
- **CIS Docker Benchmark v1.7.0** compliance
- Non-root users (always)
- Dropped capabilities
- Read-only filesystems where possible
- BuildKit secrets (no hardcoded secrets)
- Regular vulnerability scanning (Docker Scout, Trivy)
- **SBOM** generation and continuous monitoring
- BuildKit frontend verification

### Performance
- Optimized layer ordering
- BuildKit features for faster builds
- Resource limits and health checks
- Proper logging configuration
- Multi-platform builds when needed

### Production Operations
- Health checks and monitoring
- Proper restart policies
- Network isolation
- Backup strategies
- Update and rollback procedures

## Examples

### Example: Secure Production Deployment

```bash
# 1. Build optimized image
/docker-build

# 2. Scan for security issues
/docker-security

# 3. Create production-ready compose file
/docker-compose

# Result: Secure, optimized, production-ready configuration
```

### Example: Debug Container Issue

```bash
# Container won't start
/docker-debug

# Claude will:
# - Check logs and exit code
# - Test configuration
# - Identify root cause
# - Provide platform-specific fix
# - Show verification commands
```

### Example: Optimize Existing Project

```bash
# 1. Optimize Dockerfile
/docker-optimize

# 2. Improve security
/docker-security

# 3. Clean up old resources
/docker-cleanup

# Result: Smaller, faster, more secure images
```

## Requirements

- Docker Engine 28+ (latest features and security fixes)
- Docker Compose v2.40.3+ (for modern compose format and Compose Bridge)
- Docker Desktop 4.47+ (for AI Assistant, MCP Catalog, Model Runner, ECI, and 2025 features)
- Platform-specific:
  - **Linux:** Docker CE/EE installed
  - **macOS:** Docker Desktop for Mac (Intel or Apple Silicon)
  - **Windows:** Docker Desktop for Windows with WSL2 (recommended)

## Recommended Tools

This plugin references these tools (install as needed):
- **Docker Scout** - Built-in CVE scanning and SBOM generation
- **Trivy** - Comprehensive security scanner with secret detection
- **Syft** - Industry-standard SBOM generation tool (2025 recommended)
- **Grype** - Vulnerability scanner for images and SBOMs
- **Dive** - Image layer analyzer for optimization
- **docker-bench-security** - CIS Docker Benchmark v1.7.0 compliance checker

## Learning Resources

The plugin provides links to:
- Official Docker documentation
- CIS Docker Benchmark
- OWASP Docker Security Cheat Sheet
- Platform-specific guides
- Security best practices

## Contributing

Found an outdated best practice or want to add a new command? This plugin encourages continuous improvement to stay current with Docker's evolution.

## License

MIT

## Support

For issues or questions:
- Check command outputs for detailed guidance
- Use `/agent docker-expert` for complex questions
- Refer to official Docker documentation
- Check platform-specific sections in skills

---

**Master Docker across all platforms with confidence.** This plugin ensures you follow current best practices, maintain security, optimize performance, and handle platform-specific challenges effectively.
