---
name: docker-platform-guide
description: |
  Platform-specific Docker considerations for Windows, Linux, and macOS.
  PROACTIVELY activate for: (1) Docker Desktop on Windows (WSL2 vs Hyper-V backends), (2) Docker Desktop on macOS (Apple Silicon, Rosetta, virtiofs), (3) native Docker Engine on Linux, (4) rootless Docker setup, (5) cross-platform image building (--platform, buildx, multi-arch manifests), (6) ARM64 vs x86_64 image selection, (7) volume performance differences (bind mount vs named volume across platforms), (8) Docker Desktop resource tuning per OS.
  Provides: per-platform setup steps, multi-arch build recipes, rootless setup, performance-tuning checklist, and known platform-specific gotchas.
---

# Docker Platform-Specific Guide

This skill provides detailed guidance on Docker differences, considerations, and optimizations for Windows, Linux, and macOS platforms.

## Shell and path conventions used in this skill

Docker commands are mostly identical across platforms, but the surrounding shell utilities are not. This guide uses the following conventions:

- **Inside `docker exec` / `docker run` containers** — commands target a Linux shell regardless of host OS (containers run Linux).
- **On the host (Linux / macOS / WSL2)** — examples use bash with `/dev/null`, `grep`, `sed`, `awk`, package managers (`apt-get`, `brew`).
- **On the host (Windows native PowerShell)** — substitute: `/dev/null` -> `$null`, `grep pattern` -> `Select-String pattern`, `sed -i 's/a/b/' f` -> `(Get-Content f) -replace 'a','b' | Set-Content f`. Pipe object output rather than text.
- **Docker Desktop on Windows** uses a WSL2 Linux VM — bash examples work inside WSL distros. PowerShell users can still run the `docker` CLI itself; only the supporting Unix tools need translation.

Path quoting: when bind-mounting Windows paths into Docker Desktop, use forward slashes or escaped backslashes (`-v C:/Users/me/code:/app` or `-v "C:\Users\me\code:/app"`). The PowerShell host path uses Windows separators; the container path is always Linux-style.

## Linux

### Advantages

- **Native containers:** No virtualization layer overhead
- **Best performance:** Direct kernel features (cgroups, namespaces)
- **Full feature set:** All Docker features available
- **Production standard:** Most production deployments run on Linux
- **Flexibility:** Multiple distributions supported

### Platform Features

**Container Technologies:**
- Namespaces: PID, network, IPC, mount, UTS, user
- cgroups v1 and v2 for resource control
- Overlay2 storage driver (recommended)
- SELinux and AppArmor for mandatory access control

**Storage Drivers:**
```bash
# Check current driver
docker info | grep "Storage Driver"

# Recommended: overlay2
# /etc/docker/daemon.json
{
  "storage-driver": "overlay2"
}
```

### Linux-Specific Configuration

**Daemon Configuration** (`/etc/docker/daemon.json`):
```json
{
  "storage-driver": "overlay2",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "live-restore": true,
  "userland-proxy": false,
  "userns-remap": "default",
  "icc": false,
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 64000,
      "Soft": 64000
    }
  }
}
```

**User Namespace Remapping:**
```bash
# Enable in daemon.json
{
  "userns-remap": "default"
}

# Restart Docker
sudo systemctl restart docker

# Result: root in container = unprivileged user on host
```

### SELinux Integration

```bash
# Check SELinux status
sestatus

# Run container with SELinux enabled
docker run --security-opt label=type:svirt_sandbox_file_t myimage

# Volume labels
docker run -v /host/path:/container/path:z myimage  # Private label
docker run -v /host/path:/container/path:Z myimage  # Shared label
```

### AppArmor Integration

```bash
# Check AppArmor status
sudo aa-status

# Run with default Docker profile
docker run --security-opt apparmor=docker-default myimage

# Create custom profile
sudo aa-genprof docker run myimage
```

### Systemd Integration

```bash
# Check Docker service status
sudo systemctl status docker

# Enable on boot
sudo systemctl enable docker

# Restart Docker
sudo systemctl restart docker

# View logs
sudo journalctl -u docker -f

# Configure service
sudo systemctl edit docker
```

### cgroup v1 vs v2

```bash
# Check cgroup version
stat -fc %T /sys/fs/cgroup/

# If using cgroup v2, ensure Docker version >= 20.10

# /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"]
}
```

### Linux Distribution Specifics

**Ubuntu/Debian:**
```bash
# Install Docker
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io

# Non-root user
sudo usermod -aG docker $USER
```

**RHEL/CentOS/Fedora:**
```bash
# Install Docker
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install docker-ce docker-ce-cli containerd.io

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker

# Non-root user
sudo usermod -aG docker $USER
```

**Alpine:**
```bash
# Install Docker
apk add docker docker-compose

# Start Docker
rc-update add docker boot
service docker start
```

## macOS

### Architecture

- **Docker Desktop:** Required (no native Docker on macOS)
- **Virtualization:** Uses HyperKit (Intel) or Virtualization.framework (Apple Silicon)
- **Linux VM:** Containers run in lightweight Linux VM
- **File sharing:** osxfs or VirtioFS for bind mounts

### macOS-Specific Considerations

**Resource Allocation:**
```text
Docker Desktop → Preferences → Resources → Advanced
- CPUs: Allocate based on workload (default: half available)
- Memory: Allocate generously (default: 2GB, recommend 4-8GB)
- Swap: 1GB minimum
- Disk image size: 60GB+ for development
```

**File Sharing Performance:**

Traditional osxfs is slow. Improvements:
1. **VirtioFS:** Enable in Docker Desktop settings (faster)
2. **Delegated/Cached mounts:**

```yaml
volumes:
  # Host writes delayed (best for source code)
  - ./src:/app/src:delegated

  # Container writes cached (best for build outputs)
  - ./build:/app/build:cached

  # Default consistency (slowest but safest)
  - ./data:/app/data:consistent
```

**Network Access:**

```bash
# Access host from container
host.docker.internal

# Example: Connect to host PostgreSQL
docker run -e DATABASE_URL=postgresql://host.docker.internal:5432/db myapp
```

### Apple Silicon (M1/M2/M3) Specifics

**Architecture Considerations:**
```bash
# Check image architecture
docker image inspect node:20-alpine | grep Architecture

# M-series Macs are ARM64
# Some images only available for AMD64

# Build multi-platform
docker buildx build --platform linux/amd64,linux/arm64 -t myapp .

# Run AMD64 image on ARM (via emulation)
docker run --platform linux/amd64 myimage  # Slower
```

**Rosetta 2 Integration:**
```text
Docker Desktop → Features in development → Use Rosetta for x86/amd64 emulation
```
Faster AMD64 emulation on Apple Silicon.

### macOS Docker Desktop Settings

**General:**
- ✅ Start Docker Desktop when you log in
- ✅ Use VirtioFS (better performance)
- ✅ Use Virtualization framework (Apple Silicon)

**Resources:**
```yaml
CPUs: 4-6 (for development)
Memory: 6-8 GB (for development)
Swap: 1-2 GB
Disk image size: 100+ GB (grows dynamically)
```

**Docker Engine:**
```json
{
  "builder": {
    "gc": {
      "enabled": true,
      "defaultKeepStorage": "20GB"
    }
  },
  "experimental": false,
  "features": {
    "buildkit": true
  }
}
```

### macOS File Permissions

```bash
# macOS user ID and group ID
id -u  # Usually 501
id -g  # Usually 20

# Match in container
docker run --user 501:20 myimage

# Or in Dockerfile
RUN adduser -u 501 -g 20 appuser
USER appuser
```

### macOS Development Workflow

```yaml
# docker-compose.yml for development
version: '3.8'

services:
  app:
    build: .
    volumes:
      # Source code with delegated (better performance)
      - ./src:/app/src:delegated
      # node_modules in volume (much faster than bind mount)
      - node_modules:/app/node_modules
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=development

volumes:
  node_modules:
```

### Common macOS Issues

**Problem:** Slow file sync
**Solution:**
- Use VirtioFS
- Use delegated/cached mounts
- Store dependencies in volumes (not bind mounts)

**Problem:** High CPU usage
**Solution:**
- Reduce file watching
- Exclude large directories from file sharing
- Allocate more resources

**Problem:** Port already in use
**Solution:**
```bash
# Find process using port
lsof -i :PORT
kill -9 PID
```

## Windows

For Windows Docker specifics (container types, WSL2, image variants `nanoserver` / `windowsservercore`, licensing, networking, mount semantics, Visual Studio integration), see `references/windows-platform-detail.md`. Highlights:

- **Container types:** Windows Server Containers (process isolation) vs Hyper-V Containers (kernel isolation).
- **WSL2 backend:** Docker Desktop default; gives near-native Linux performance.
- **Image variants:** `mcr.microsoft.com/windows/nanoserver` (smallest) vs `windowsservercore` (full API).
- **Mounts:** convert `S:eposx` to `/s/repos/x` in Git Bash or set `MSYS_NO_PATHCONV=1`.


## Platform Comparison

| Feature | Linux | macOS | Windows |
|---------|-------|-------|---------|
| **Performance** | Excellent (native) | Good (VM overhead) | Good (WSL2) to Fair (Hyper-V) |
| **File sharing** | Native | Slow (improving with VirtioFS) | Slow (better in WSL2) |
| **Resource efficiency** | Best | Good | Good (WSL2) |
| **Feature set** | Complete | Complete | Complete (LCOW) |
| **Production** | Standard | Dev only | Dev only (LCOW) |
| **Ease of use** | Moderate | Easy (Docker Desktop) | Easy (Docker Desktop) |
| **Cost** | Free | Free (Docker Desktop Personal) | Free (Docker Desktop Personal) |

## Cross-Platform Best Practices

### Multi-Platform Images

```bash
# Create buildx builder
docker buildx create --name multiplatform --driver docker-container --use

# Build for multiple platforms
docker buildx build \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  -t myimage:latest \
  --push \
  .
```

### Platform-Agnostic Dockerfiles

```dockerfile
# Works on all platforms
FROM node:20-alpine

# Use COPY with --chmod (not RUN chmod, which is slower)
COPY --chmod=755 script.sh /usr/local/bin/

# Use environment variables for paths
ENV APP_HOME=/app
WORKDIR ${APP_HOME}

# Use exec form for CMD/ENTRYPOINT (works on Windows containers too)
CMD ["node", "server.js"]
```

### Cross-Platform Compose Files

```yaml
version: '3.8'

services:
  app:
    build: .
    volumes:
      # Relative paths work everywhere
      - ./src:/app/src
      # Named volumes (platform-agnostic)
      - data:/app/data
    environment:
      # Use environment variables
      - NODE_ENV=${NODE_ENV:-development}

volumes:
  data:
```

### Testing Across Platforms

```bash
# Test on different platforms with buildx
docker buildx build --platform linux/amd64 -t myapp:amd64 --load .
docker run --rm myapp:amd64

docker buildx build --platform linux/arm64 -t myapp:arm64 --load .
docker run --rm myapp:arm64
```

## Platform Selection Guide

**Choose Linux for:**
- Production deployments
- Maximum performance
- Full Docker feature set
- Minimal overhead
- CI/CD pipelines

**Choose macOS for:**
- Development on Mac hardware
- When you need macOS tools
- Docker Desktop ease of use
- M1/M2/M3 development

**Choose Windows for:**
- Development on Windows hardware
- Windows-specific applications
- When team uses Windows
- WSL2 for better Linux container support

This platform guide covers the major differences. Always test on your target deployment platform before going to production.
