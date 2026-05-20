# Windows and Git Bash Compatibility Guide

## Overview

This guide provides essential information for using the azure-to-docker-master plugin on Windows with Git Bash, addressing path conversion issues and Docker Compose compatibility.

## Git Bash Path Conversion

### Understanding the Issue

Git Bash (MinGW) automatically converts Unix-style paths to Windows paths in certain scenarios:

- **Triggers Conversion:**
  - Leading forward slash (/) in arguments
  - Colon-separated path lists (`/foo:/bar`)
  - Arguments after `-` or `,` with path components

- **Does NOT Convert:**
  - Arguments containing `=` (variable assignments)
  - Drive specifiers (`C:`)
  - Arguments with `;` (already Windows format)
  - Arguments starting with `//` (Windows switches/options)

### Solutions for Docker Commands

#### Method 1: Disable Path Conversion Globally

```bash
# Add to your ~/.bashrc or ~/.bash_profile
export MSYS_NO_PATHCONV=1
```

#### Method 2: Disable Per-Command

```bash
# Temporarily disable for a single command
MSYS_NO_PATHCONV=1 docker run -v /c/data:/data myimage

# Or use function wrapper
docker() { (export MSYS_NO_PATHCONV=1; "docker.exe" "$@") }
```

#### Method 3: Use Double Slashes

```bash
# Add extra slash at the beginning
docker run -v //c/data:/data myimage
```

## Docker Compose on Windows Git Bash

### Volume Mount Syntax

**Correct volume mount syntax for cross-platform compatibility:**

```yaml
services:
  webapp:
    volumes:
      # Use forward slashes - works on all platforms
      - ./app:/app

      # For absolute Windows paths in Git Bash
      - /c/Users/username/project:/project

      # Named volumes (no conversion issues)
      - app-data:/var/lib/app
```

### Common Pitfalls and Solutions

#### Problem: Volume Mount Path Conversion

```bash
# WRONG (Git Bash converts /data to C:/Program Files/Git/data)
docker compose run web bash -c "ls /data"

# CORRECT (use MSYS_NO_PATHCONV)
MSYS_NO_PATHCONV=1 docker compose run web bash -c "ls /data"
```

#### Problem: Windows Paths in Compose Files

```yaml
# AVOID: Hardcoded Windows paths
services:
  app:
    volumes:
      - C:\Users\me\code:/app  # Backslashes cause issues

# PREFER: Relative or Unix-style paths
services:
  app:
    volumes:
      - ./code:/app  # Relative path
      - /c/Users/me/code:/app  # Unix-style absolute path
```

## Shell Detection in Scripts

### Detect Git Bash / MinGW

```bash
#!/usr/bin/env bash

# Method 1: Check MSYSTEM environment variable (most reliable)
if [[ -n "${MSYSTEM:-}" ]]; then
    echo "Running in Git Bash/MinGW"
    export MSYS_NO_PATHCONV=1  # Disable path conversion
fi

# Method 2: Check OSTYPE
case "$OSTYPE" in
    msys*)
        echo "Git Bash / MSYS detected"
        ;;
    cygwin*)
        echo "Cygwin detected"
        ;;
    linux-gnu*)
        echo "Linux detected"
        ;;
    darwin*)
        echo "macOS detected"
        ;;
esac

# Method 3: Full environment detection function
detect_shell_env() {
    if [[ -n "${MSYSTEM:-}" ]]; then
        echo "git-bash"  # MINGW64 or MINGW32
    elif [[ "$OSTYPE" == "msys" ]]; then
        echo "msys"
    elif [[ "$OSTYPE" == "cygwin" ]]; then
        echo "cygwin"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    else
        echo "unknown"
    fi
}

SHELL_ENV=$(detect_shell_env)
echo "Shell environment: $SHELL_ENV"
```

## Docker Compose Best Practices for Windows

### Environment Variables

```yaml
# .env file (works cross-platform)
DB_SA_PASSWORD=YourStrong!Password
COMPOSE_CONVERT_WINDOWS_PATHS=1  # Helps with path conversion

# Use in docker-compose.yml
services:
  sqlserver:
    environment:
      - SA_PASSWORD=${DB_SA_PASSWORD}
```

### Path Handling in Scripts

```bash
#!/usr/bin/env bash

# Good: Disable path conversion at script start
export MSYS_NO_PATHCONV=1

# Good: Use relative paths
BACKUP_DIR="./database/backups"

# Good: Convert Windows paths to Unix format if needed
if command -v cygpath &> /dev/null; then
    UNIX_PATH=$(cygpath -u "C:\\Users\\me\\project")
    echo "$UNIX_PATH"  # /c/Users/me/project
fi
```

### Running Docker Compose Commands

```bash
# Start services (no path issues)
docker compose up -d

# Execute commands in containers
MSYS_NO_PATHCONV=1 docker compose exec webapp bash

# Run one-time commands
MSYS_NO_PATHCONV=1 docker compose run --rm webapp npm install

# Volume mounts work correctly
docker compose run --rm -v ./data:/data webapp process-data
```

## Troubleshooting

### Issue: Paths are Incorrectly Converted

**Symptoms:**
```text
Error: /usr/bin/bash: line 1: C:UsersDavid...No such file
```

**Solution:**
```bash
# Set environment variable before running command
export MSYS_NO_PATHCONV=1
docker compose up
```

### Issue: Volume Mount Not Found

**Symptoms:**
```text
Error: Mount denied: Path does not exist
```

**Solution:**
```yaml
# Use relative paths or correct Unix-style absolute paths
services:
  app:
    volumes:
      - ./myapp:/app  # Relative (recommended)
      - /c/projects/myapp:/app  # Absolute Unix-style
```

### Issue: Script Fails on Windows

**Symptoms:**
```text
./script.sh: command not found
```

**Solutions:**
```bash
# 1. Ensure Unix line endings (LF, not CRLF)
git config core.autocrlf false
dos2unix script.sh

# 2. Make executable
chmod +x script.sh

# 3. Run with bash explicitly
bash script.sh
```

## Recommended Setup for Windows Users

### Git Configuration

```bash
# Configure Git to not convert line endings
git config --global core.autocrlf false

# For existing repositories
git config core.autocrlf false
git rm --cached -r .
git reset --hard
```

### Bash Profile Configuration

Add to `~/.bash_profile` or `~/.bashrc`:

```bash
# Disable MSYS path conversion globally
export MSYS_NO_PATHCONV=1

# Set Docker Compose variables
export COMPOSE_CONVERT_WINDOWS_PATHS=1

# Docker wrapper function (optional)
docker() {
    (export MSYS_NO_PATHCONV=1; "docker.exe" "$@")
}

docker-compose() {
    (export MSYS_NO_PATHCONV=1; "docker-compose.exe" "$@")
}
```

### Docker Desktop Settings

1. **Shared Drives**: Ensure your drives are shared in Docker Desktop settings
2. **File Sharing**: Add project directories to allowed file sharing paths
3. **WSL 2 Integration**: Enable WSL 2 backend for better performance (recommended)

## Platform-Specific Notes

### Git Bash (MinGW64/MinGW32)

- **Detection**: Check `$MSYSTEM` variable (MINGW64 or MINGW32)
- **Path Format**: Use `/c/path/to/file` instead of `C:\path\to\file`
- **Commands**: Prefer `winpty` prefix for interactive commands

### Cygwin

- **Detection**: Check `$OSTYPE == cygwin`
- **Path Conversion**: Use `cygpath` utility for conversions
- **Docker**: May require additional configuration

### WSL (Windows Subsystem for Linux)

- **Detection**: Check `/proc/version` for "Microsoft"
- **Path Format**: Use Linux paths directly
- **Docker**: Use Docker Desktop with WSL 2 integration

## Azure-to-Docker-Specific Guidance

### Extraction Scripts

```bash
# Run azure-infrastructure-extractor.sh on Windows
export MSYS_NO_PATHCONV=1
./scripts/azure-infrastructure-extractor.sh MyResourceGroup ./output
```

### Dockerfile Generation

```bash
# Generate Dockerfiles from Azure configs
export MSYS_NO_PATHCONV=1
./scripts/dockerfile-generator.sh ./webapps/myapp ./docker
```

### Database Export

```bash
# Export Azure SQL database (paths handled correctly)
export MSYS_NO_PATHCONV=1
sqlpackage /Action:Export \
  /SourceServerName:myserver.database.windows.net \
  /SourceDatabaseName:mydb \
  /TargetFile:./data/mydb.bacpac
```

## Testing Path Conversion

```bash
# Test if path conversion is disabled
echo "MSYS_NO_PATHCONV: ${MSYS_NO_PATHCONV:-not set}"

# Test Docker volume mount
docker run --rm -v $(pwd):/test alpine ls /test

# Test Docker Compose
docker compose config  # Validates compose file syntax
```

## Additional Resources

- [Git for Windows Path Conversion](https://github.com/git-for-windows/git/wiki/FAQ#some-native-console-programs-dont-work-when-run-from-git-bash-how-to-fix-it)
- [Docker Desktop for Windows](https://docs.docker.com/desktop/install/windows-install/)
- [Docker Compose File Reference](https://docs.docker.com/compose/compose-file/)
- [MSYS2 Path Conversion](https://www.msys2.org/docs/filesystem-paths/)

## Summary

Key takeaways for Windows Git Bash users:

1. **Set `MSYS_NO_PATHCONV=1`** at the beginning of scripts
2. **Use forward slashes** in Docker volume mounts
3. **Use relative paths** when possible in docker-compose.yml
4. **Detect shell environment** for platform-specific behavior
5. **Configure Git** to use LF line endings
6. **Test Docker commands** with path conversion disabled

Following these guidelines ensures smooth operation of the azure-to-docker-master plugin on Windows with Git Bash.
