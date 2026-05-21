---
name: docker-security-guide
description: |
  Comprehensive Docker security guidelines and threat mitigation.
  PROACTIVELY activate for: (1) container security review, (2) running as non-root user, (3) read-only root filesystems and tmpfs mounts, (4) capability dropping (--cap-drop ALL), (5) seccomp and AppArmor profiles, (6) image vulnerability scanning (Docker Scout, Trivy, Grype), (7) supply-chain security (signed images, SBOM, provenance), (8) secrets management (Docker secrets, BuildKit --secret, external vaults), (9) network segmentation (user-defined networks, no --net=host), (10) CIS Docker Benchmark compliance.
  Provides: hardening checklist, scan-tool integration recipes, CIS benchmark mapping, secret handling patterns, and capability-drop reference.
---

## 🚨 CRITICAL GUIDELINES

### Windows File Path Requirements

**MANDATORY: Always Use Backslashes on Windows for File Paths**

When using Edit or Write tools on Windows, you MUST use backslashes (`\`) in file paths, NOT forward slashes (`/`).

**Examples:**
- ❌ WRONG: `D:/repos/project/file.tsx`
- ✅ CORRECT: `D:\repos\project\file.tsx`

This applies to:
- Edit tool file_path parameter
- Write tool file_path parameter
- All file operations on Windows systems


### Documentation Guidelines

**NEVER create new documentation files unless explicitly requested by the user.**

- **Priority**: Update existing README.md files rather than creating new documentation
- **Repository cleanliness**: Keep repository root clean - only README.md unless user requests otherwise
- **Style**: Documentation should be concise, direct, and professional - avoid AI-generated tone
- **User preference**: Only create additional .md files when user specifically asks for documentation


---

# Docker Security Guide

This skill provides comprehensive security guidelines for Docker across all platforms, covering threats, mitigations, and compliance requirements.

## Security Principles

### Defense in Depth

Apply security at multiple layers:
1. **Image security:** Minimal, scanned, signed images
2. **Build security:** Secure build process, no secrets in layers
3. **Runtime security:** Restricted capabilities, resource limits
4. **Network security:** Isolation, least privilege
5. **Host security:** Hardened host OS, updated Docker daemon
6. **Orchestration security:** Secure configuration, RBAC
7. **Monitoring:** Detection, logging, alerting

### Least Privilege

Grant only the minimum permissions necessary:
- Non-root users
- Dropped capabilities
- Read-only filesystems
- Minimal network exposure
- Restricted syscalls (seccomp)
- Limited resources

## Image Security

### Base Image Selection

**Threat:** Vulnerable or malicious base images

**Mitigation:**
```dockerfile
# Use official images only
FROM node:20.11.0-alpine3.19  # Official, specific version

# NOT
FROM randomuser/node  # Unverified source
FROM node:latest      # Unpredictable, can break
```

**Verification:**
```bash
# Verify image source
docker image inspect node:20-alpine | grep -A 5 "Author"

# Enable Docker Content Trust (image signing)
export DOCKER_CONTENT_TRUST=1
docker pull node:20-alpine
```

### Minimal Images

**Threat:** Larger attack surface, more vulnerabilities

**Mitigation:**
```dockerfile
# Prefer minimal distributions
FROM alpine:3.19           # ~7MB
FROM gcr.io/distroless/static  # ~2MB
FROM scratch               # 0MB (for static binaries)

# vs
FROM ubuntu:22.04          # ~77MB with more packages
```

**Benefits:**
- Fewer packages = fewer vulnerabilities
- Smaller attack surface
- Faster downloads and starts
- Less disk space

### Micro-Distros for Security-Critical Applications (2025)

**Wolfi/Chainguard Images:**
- Zero-CVE goal, SBOM included by default
- Nightly security patches, signed with provenance
- Available for: Node, Python, Go, Java, .NET, etc.

**Usage:**
```dockerfile
# Development stage (includes build tools)
FROM cgr.dev/chainguard/node:latest-dev AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Production stage (minimal, zero-CVE goal)
FROM cgr.dev/chainguard/node:latest
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY . .
USER node
ENTRYPOINT ["node", "server.js"]
```

**When to use:** Security-critical apps, compliance requirements (SOC2, HIPAA, PCI-DSS), zero-trust environments, supply chain security emphasis.

See `docker-best-practices` skill for full image comparison table.

### Vulnerability Scanning

**Tools:**
- Docker Scout (built-in)
- Trivy
- Grype
- Snyk
- Clair

**Process:**
```bash
# Scan with Docker Scout
docker scout cves IMAGE_NAME
docker scout recommendations IMAGE_NAME

# Scan with Trivy
trivy image IMAGE_NAME
trivy image --severity HIGH,CRITICAL IMAGE_NAME

# Scan Dockerfile
trivy config Dockerfile

# Scan for secrets
trivy fs --scanners secret .
```

**CI/CD Integration:**
```yaml
# GitHub Actions example
- name: Scan image
  run: |
    docker scout cves my-image:${{ github.sha }}
    trivy image --exit-code 1 --severity CRITICAL my-image:${{ github.sha }}
```

### Multi-Stage Builds for Security

**Threat:** Build tools and secrets in final image

**Mitigation:**
```dockerfile
# Build stage with build tools
FROM golang:1.21 AS builder
WORKDIR /app
COPY . .
RUN go build -o app

# Final stage - minimal, no build tools
FROM gcr.io/distroless/base-debian11
COPY --from=builder /app/app /
USER nonroot:nonroot
ENTRYPOINT ["/app"]
```

**Benefits:**
- No compiler/build tools in production image
- Secrets used in build don't persist
- Smaller, more secure final image

## Build-Time & Runtime Security

Complete recipes for build secrets (`--mount=type=secret`, BuildKit), multi-stage hardening, capability drops (`--cap-drop=ALL`), seccomp / AppArmor profiles, read-only root, user namespaces, resource limits, and rootless runtime live in `references/build-runtime-security.md`. Core principles:

- **Build secrets:** use `--mount=type=secret` and `--mount=type=ssh`; never `ARG`/`ENV` for sensitive values.
- **Runtime:** drop all capabilities and add back what is needed; run read-only root; non-root user; resource limits; pinned image digests.
- **Profiles:** apply seccomp, AppArmor, and SELinux; combine with user namespaces.

See `references/build-runtime-security.md` for all commands and recipes.

## Network Security

### Network Isolation

**Threat:** Lateral movement between containers

**Mitigation:**
```yaml
networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true  # No external access

services:
  web:
    networks:
      - frontend

  api:
    networks:
      - frontend
      - backend

  database:
    networks:
      - backend  # Isolated from frontend
```

### Port Exposure

**Threat:** Unnecessary network exposure

**Mitigation:**
```bash
# Bind to localhost only
docker run -p 127.0.0.1:8080:8080 my-image

# NOT (binds to all interfaces)
docker run -p 8080:8080 my-image
```

**In Compose:**
```yaml
services:
  app:
    ports:
      - "127.0.0.1:8080:8080"  # Localhost only
```

### Inter-Container Communication

```yaml
# Disable default inter-container communication
# /etc/docker/daemon.json
{
  "icc": false
}
```

Then explicitly allow via networks:
```yaml
services:
  app1:
    networks:
      - app-network
  app2:
    networks:
      - app-network  # Can communicate with app1

networks:
  app-network:
    driver: bridge
```

## Secrets Management

### Docker Secrets (Swarm Mode)

```bash
# Create secret
echo "mypassword" | docker secret create db_password -

# Use in service
docker service create \
  --name my-service \
  --secret db_password \
  my-image

# Access in container at /run/secrets/db_password
```

**In stack file:**
```yaml
version: '3.8'

services:
  app:
    image: my-image
    secrets:
      - db_password

secrets:
  db_password:
    external: true
```

### Secrets Best Practices

1. **Never in environment variables** (visible in `docker inspect`)
2. **Never in images** (in layer history)
3. **Never in version control** (Git history)
4. **Mount as files** with restricted permissions
5. **Use secret management systems** (Vault, AWS Secrets Manager, etc.)
6. **Rotate regularly**

**Alternative: Mounted secrets:**
```bash
docker run -v /secure/secrets:/run/secrets:ro my-image
```

## Compliance & Benchmarking

### CIS Docker Benchmark

Automated checking:
```bash
# Clone docker-bench-security
git clone https://github.com/docker/docker-bench-security.git
cd docker-bench-security
sudo sh docker-bench-security.sh

# Or run as container
docker run --rm --net host --pid host --userns host \
  --cap-add audit_control \
  -v /var/lib:/var/lib:ro \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -v /usr/lib/systemd:/usr/lib/systemd:ro \
  -v /etc:/etc:ro \
  docker/docker-bench-security
```

### Key CIS Recommendations

1. **Host Configuration**
   - Keep Docker up to date
   - Restrict network traffic between containers
   - Set logging level to 'info'
   - Enable Docker Content Trust

2. **Docker Daemon**
   - Use TLS for Docker daemon socket
   - Don't expose daemon on TCP without TLS
   - Enable user namespace support

3. **Docker Files**
   - Verify Docker files ownership and permissions
   - Audit Docker files and directories

4. **Container Images**
   - Create user for container
   - Use trusted base images
   - Don't install unnecessary packages

5. **Container Runtime**
   - Run containers with limited privileges
   - Set resource limits
   - Don't share host network namespace

## Monitoring & Detection

### Logging

```yaml
services:
  app:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
        labels: "service,env"
        env: "ENV,VERSION"
```

**Centralized logging:**
```yaml
services:
  app:
    logging:
      driver: "syslog"
      options:
        syslog-address: "tcp://log-server:514"
        tag: "{{.Name}}/{{.ID}}"
```

### Runtime Monitoring

**Tools:**
- Falco: Runtime security monitoring
- Sysdig: Container visibility
- Prometheus + cAdvisor: Metrics
- Docker events: Real-time events

**Monitor for:**
- Unexpected processes
- File modifications
- Network connections
- Resource spikes
- Failed authentication
- Privilege escalation attempts

```bash
# Monitor Docker events
docker events --filter 'type=container' --filter 'event=start'

# Watch specific container
docker events --filter "container=my-container"

# Runtime security with Falco
docker run --rm -it \
  --privileged \
  -v /var/run/docker.sock:/host/var/run/docker.sock \
  -v /dev:/host/dev \
  -v /proc:/host/proc:ro \
  falcosecurity/falco
```

## Platform-Specific Security

### Linux

**User namespace remapping:**
```json
// /etc/docker/daemon.json
{
  "userns-remap": "default"
}
```

Benefits: Root in container → unprivileged on host

**SELinux:**
```bash
# Enable SELinux for Docker
setenforce 1

# Run with SELinux labels
docker run --security-opt label=type:svirt_sandbox_file_t my-image

# Volumes with SELinux
docker run -v /host/path:/container/path:z my-image
```

**AppArmor:**
```bash
# Check AppArmor status
aa-status

# Run with AppArmor profile
docker run --security-opt apparmor=docker-default my-image
```

### Windows

**Hyper-V isolation:**
```powershell
# More isolated than process isolation
docker run --isolation=hyperv my-image
```

**Windows Defender:**
- Ensure real-time protection enabled
- Configure exclusions carefully
- Scan images regularly

### macOS

**Docker Desktop security:**
- Keep Docker Desktop updated
- Enable "Use gRPC FUSE for file sharing"
- Limit file sharing to necessary paths
- Review resource allocation

## Security Checklist

**Image:**
- [ ] Based on official, minimal image
- [ ] Specific version tag (not `latest`)
- [ ] Scanned for vulnerabilities
- [ ] No secrets in layers
- [ ] Runs as non-root user
- [ ] Signed (Content Trust)

**Build:**
- [ ] .dockerignore configured
- [ ] Multi-stage build (if applicable)
- [ ] Build secrets handled properly
- [ ] Build from trusted sources only

**Runtime:**
- [ ] Non-root user
- [ ] Capabilities dropped
- [ ] Read-only filesystem (where possible)
- [ ] Security options set
- [ ] Resource limits configured
- [ ] Isolated network
- [ ] Minimal port exposure
- [ ] Secrets mounted securely

**Operations:**
- [ ] CIS benchmark compliance
- [ ] Logging configured
- [ ] Monitoring in place
- [ ] Regular vulnerability scans
- [ ] Incident response plan
- [ ] Regular updates
- [ ] Audit logs enabled

## Common Security Mistakes

❌ **NEVER:**
- Run as root
- Use `--privileged`
- Mount Docker socket (`/var/run/docker.sock`)
- Hardcode secrets
- Use `latest` tag
- Skip vulnerability scanning
- Expose unnecessary ports
- Disable security features
- Ignore security updates
- Trust unverified images

✅ **ALWAYS:**
- Run as non-root
- Drop capabilities
- Scan for vulnerabilities
- Use secrets management
- Tag with specific versions
- Enable security options
- Apply least privilege
- Keep systems updated
- Monitor runtime behavior
- Use official images

This security guide represents current best practices. Security threats evolve constantly—always check the latest Docker security documentation and CVE databases.
