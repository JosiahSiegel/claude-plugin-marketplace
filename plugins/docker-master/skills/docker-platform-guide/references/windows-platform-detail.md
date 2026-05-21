# Windows Docker Platform (Detailed Reference)

Windows container types (Server containers, Hyper-V, process isolation), WSL2 integration, image variants (`nanoserver`, `windowsservercore`), licensing, networking peculiarities, mount semantics, and Visual Studio integration.

## Windows

### Windows Container Types

**1. Linux Containers on Windows (LCOW):**
- Most common for development
- Uses WSL2 or Hyper-V backend
- Runs Linux containers
- Good compatibility

**2. Windows Containers:**
- Native Windows containers
- For Windows-specific workloads
- Requires Windows Server base images
- Less common in development

### Windows Backend Options

**WSL2 Backend (Recommended):**
- Faster
- Better resource usage
- Native Linux kernel
- Requires Windows 10/11 (recent versions)

**Hyper-V Backend:**
- Older option
- More resource intensive
- Works on older Windows versions

### WSL2 Configuration

**Enable WSL2:**
```powershell
# Run as Administrator
wsl --install

# Or manually
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# Set WSL2 as default
wsl --set-default-version 2

# Install Ubuntu (or other distro)
wsl --install -d Ubuntu
```

**Docker Desktop Integration:**
```text
Settings → Resources → WSL Integration
- Enable integration with default distro
- Select additional distros
```

### Windows Path Considerations

**Path Formats:**
```bash
# Forward slashes (recommended, works everywhere)
docker run -v C:/Users/name/project:/app myimage

# Backslashes (need escaping in some contexts)
docker run -v C:\Users\name\project:/app myimage

# In docker-compose.yml (forward slashes)
volumes:
  - C:/Users/name/project:/app

# Or relative paths
volumes:
  - ./src:/app/src
```

### Git Bash / MINGW Path Conversion Issues

**CRITICAL ISSUE:** When using Docker in Git Bash (MINGW) on Windows, automatic path conversion breaks volume mounts.

**The Problem:**
```bash
# What you type in Git Bash:
docker run -v $(pwd):/app myimage

# What Git Bash converts it to (BROKEN):
docker run -v C:\Program Files\Git\d\repos\project:/app myimage
```

**Solutions:**

**1. MSYS_NO_PATHCONV (Recommended):**
```bash
# Per-command fix
MSYS_NO_PATHCONV=1 docker run -v $(pwd):/app myimage

# Session-wide fix (add to ~/.bashrc)
export MSYS_NO_PATHCONV=1

# Function wrapper (automatic for all Docker commands)
docker() {
  (export MSYS_NO_PATHCONV=1; command docker.exe "$@")
}
export -f docker
```

**2. Double Slash Workaround:**
```bash
# Use double leading slash to prevent conversion
docker run -v //c/Users/project:/app myimage

# Works with $(pwd) too
docker run -v //$(pwd):/app myimage
```

**3. Named Volumes (No Path Issues):**
```bash
# Named volumes work without any fixes
docker run -v my-data:/data myimage
```

**What Works Without Modification:**
- Docker Compose YAML files with relative paths
- Named volumes
- Network and image commands
- Container commands without volumes

**What Needs MSYS_NO_PATHCONV:**
- Bind mounts with `$(pwd)`
- Bind mounts with absolute Unix-style paths
- Volume mounts specified on command line

**Shell Detection:**
```bash
# Detect Git Bash/MINGW and auto-configure
if [ -n "$MSYSTEM" ] || [[ "$(uname -s)" == MINGW* ]]; then
  export MSYS_NO_PATHCONV=1
  echo "Git Bash detected - Docker path conversion fix enabled"
fi
```

**Recommended ~/.bashrc Configuration:**
```bash
# Docker on Git Bash fix
if [ -n "$MSYSTEM" ]; then
  export MSYS_NO_PATHCONV=1
fi
```

See the `docker-git-bash-guide` skill for comprehensive path conversion documentation, troubleshooting, and examples.

### Windows File Sharing

**Configure Shared Drives:**
```text
Docker Desktop → Settings → Resources → File Sharing
Add: C:\, D:\, etc.
```

**Performance Considerations:**
- File sharing is slower than Linux/Mac
- Use WSL2 backend for better performance
- Store frequently accessed files in WSL2 filesystem

### Windows Line Endings

**Problem:** CRLF vs LF line endings

**Solution:**
```bash
# Git configuration
git config --global core.autocrlf input

# Or per-repo (.gitattributes)
* text=auto
*.sh text eol=lf
*.bat text eol=crlf
```

```dockerfile
# In Dockerfile for scripts
FROM alpine
COPY --chmod=755 script.sh /
# Ensure LF endings
RUN dos2unix /script.sh || sed -i 's/\r$//' /script.sh
```

### Windows Firewall

```powershell
# Allow Docker Desktop
New-NetFirewallRule -DisplayName "Docker Desktop" -Direction Inbound -Program "C:\Program Files\Docker\Docker\Docker Desktop.exe" -Action Allow

# Check blocked ports
netstat -ano | findstr :PORT
```

### Windows-Specific Docker Commands

```powershell
# Run PowerShell in container
docker run -it mcr.microsoft.com/powershell:lts-7.4-windowsservercore-ltsc2022

# Windows container example
docker run -it mcr.microsoft.com/windows/servercore:ltsc2022 cmd

# Check container type
docker info | Select-String "OSType"
```

### WSL2 Disk Management

**Problem:** WSL2 VHDX grows but doesn't shrink

**Solution:**
```powershell
# Stop Docker Desktop and WSL
wsl --shutdown

# Compact disk image (run as Administrator)
# Method 1: Optimize-VHD (requires Hyper-V tools)
Optimize-VHD -Path "$env:LOCALAPPDATA\Docker\wsl\data\ext4.vhdx" -Mode Full

# Method 2: diskpart
diskpart
# In diskpart:
select vdisk file="C:\Users\YourName\AppData\Local\Docker\wsl\data\ext4.vhdx"
attach vdisk readonly
compact vdisk
detach vdisk
exit
```

### Windows Development Workflow

```yaml
# docker-compose.yml for Windows
version: '3.8'

services:
  app:
    build: .
    volumes:
      # Use forward slashes
      - ./src:/app/src
      # Named volumes for better performance
      - node_modules:/app/node_modules
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=development
    # Windows-specific: ensure proper line endings
    command: sh -c "dos2unix /app/scripts/*.sh && npm start"

volumes:
  node_modules:
```

### Common Windows Issues

**Problem:** Permission denied errors
**Solution:**
```powershell
# Run Docker Desktop as Administrator
# Or grant permissions to Docker Desktop
icacls "C:\ProgramData\DockerDesktop" /grant Users:F /T
```

**Problem:** Slow performance
**Solution:**
- Use WSL2 backend
- Store project in WSL2 filesystem (`\\wsl$\Ubuntu\home\user\project`)
- Use named volumes for node_modules, etc.

**Problem:** Path not found
**Solution:**
- Use forward slashes
- Ensure drive is shared in Docker Desktop
- Use absolute paths or `${PWD}`

