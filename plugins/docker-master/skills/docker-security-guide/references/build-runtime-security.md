# Build-Time & Runtime Security (Detailed Reference)

Complete recipes for Docker build-time secrets, multi-stage hardening, BuildKit isolation, capability drops, seccomp / AppArmor profiles, read-only root, user namespaces, resource limits, and rootless runtime. SKILL.md keeps the principle headlines; this reference has the full commands and examples.

## Build-Time Security

### Secrets Management

**NEVER:**
```dockerfile
# BAD - Secret in layer history
ENV API_KEY=abc123
RUN git clone https://user:password@github.com/repo.git
COPY .env /app/.env
```

**DO:**
```dockerfile
# Use BuildKit secrets
# syntax=docker/dockerfile:1

FROM alpine
RUN --mount=type=secret,id=github_token \
    git clone https://$(cat /run/secrets/github_token)@github.com/repo.git
```

```bash
# Build with secret (not in image)
docker build --secret id=github_token,src=./token.txt .
```

### BuildKit Frontend Security (2025)

**Threat:** Malicious or compromised BuildKit frontends can execute arbitrary code during build

**🚨 2025 CRITICAL WARNING:** BuildKit supports custom frontends (parsers) via `# syntax=` directive. Untrusted frontends have FULL BUILD-TIME code execution and can:
- Steal secrets from build context
- Modify build outputs
- Exfiltrate data
- Compromise the build environment

**Risk Example:**
```dockerfile
# 🔴 DANGER - Untrusted frontend (code execution risk!)
# syntax=docker/dockerfile:1@sha256:abc123...untrusted

FROM alpine
RUN echo "This frontend could do anything during build"
```

**Mitigation:**

1. **Only use official Docker frontends:**
```dockerfile
# ✅ Safe - Official Docker frontend
# syntax=docker/dockerfile:1

# ✅ Safe - Specific version
# syntax=docker/dockerfile:1.5

# ✅ Safe - Pinned with digest (verify from docker.com)
# syntax=docker/dockerfile:1@sha256:ac85f380a63b13dfcefa89046420e1781752bab202122f8f50032edf31be0021
```

2. **Verify frontend sources:**
- Use ONLY `docker/dockerfile:*` frontends
- Pin to specific versions with SHA256 digest
- Verify digests from official Docker documentation
- Never use third-party frontends without thorough vetting

3. **Audit all Dockerfiles for unsafe syntax directives:**
```bash
# Check all Dockerfiles for potentially malicious syntax directives
grep -r "^# syntax=" . --include="Dockerfile*"

# Verify all frontends are official Docker images
grep -r "^# syntax=" . --include="Dockerfile*" | grep -v "docker/dockerfile"
```

4. **BuildKit security configuration (defense in depth):**
```bash
# Restrict frontend sources in BuildKit config
# /etc/buildkit/buildkitd.toml
[frontend."dockerfile.v0"]
  # Only allow official Docker frontends
  allowedImages = ["docker.io/docker/dockerfile:*"]
```

**Supply Chain Protection:**
- Treat custom frontends as HIGH RISK code execution vectors
- Review ALL `# syntax=` directives in Dockerfiles before builds
- Use content trust for frontend images
- Monitor for frontend vulnerabilities
- Include frontend verification in CI/CD security gates

### SBOM (Software Bill of Materials) Generation (2025)

**Critical 2025 Requirement:** Document origin and history of all components for supply chain transparency and compliance.

**Why SBOM is Mandatory:**
- Supply chain security visibility
- Vulnerability tracking and response
- Compliance requirements (Executive Order 14028, etc.)
- License compliance
- Incident response readiness

**Generate SBOM with Docker Scout:**
```bash
# Generate SBOM for image
docker scout sbom IMAGE_NAME

# Export SBOM in different formats
docker scout sbom --format spdx IMAGE_NAME > sbom.spdx.json
docker scout sbom --format cyclonedx IMAGE_NAME > sbom.cyclonedx.json

# Include SBOM attestation during build
# ⚠️ WARNING: BuildKit attestations are NOT cryptographically signed!
docker buildx build \
  --sbom=true \
  --provenance=true \
  --tag my-image:latest \
  .

# View SBOM attestations (unsigned metadata only)
docker buildx imagetools inspect my-image:latest --format "{{ json .SBOM }}"
```

**🚨 CRITICAL SECURITY LIMITATION:**
BuildKit attestations (`--sbom=true`, `--provenance=true`) are **NOT cryptographically signed**. This means:
- Anyone with push access can create tampered attestations
- SBOMs can be incomplete or falsified
- Provenance data cannot be trusted without external verification
- **For production:** Use external signing tools (cosign, Notary) and Syft for SBOM generation

**Generate SBOM with Syft:**
```bash
# Install Syft
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh

# Generate SBOM from image
syft my-image:latest

# Generate in specific format
syft my-image:latest -o spdx-json > sbom.spdx.json
syft my-image:latest -o cyclonedx-json > sbom.cyclonedx.json

# Generate from Dockerfile
syft dir:. -o spdx-json > sbom.spdx.json
```

**SBOM in CI/CD Pipeline:**
```yaml
# GitHub Actions example
name: Build with SBOM

jobs:
  build:
    steps:
      - name: Build image with SBOM
        run: |
          docker buildx build \
            --sbom=true \
            --provenance=true \
            --tag my-image:${{ github.sha }} \
            --push \
            .

      - name: Generate SBOM with Syft
        run: |
          syft my-image:${{ github.sha }} -o spdx-json > sbom.json

      - name: Upload SBOM artifact
        uses: actions/upload-artifact@v3
        with:
          name: sbom
          path: sbom.json

      - name: Scan SBOM for vulnerabilities
        run: |
          grype sbom:sbom.json --fail-on high
```

**SBOM Best Practices:**

1. **Generate for every image:**
   - Production images: mandatory
   - Development images: recommended
   - Base images: critical

2. **Store SBOMs with provenance:**
   - Version control alongside Dockerfile
   - Artifact registry with image
   - Dedicated SBOM repository

3. **Automate SBOM generation:**
   - Integrate into CI/CD pipeline
   - Generate on every build
   - Fail builds if SBOM generation fails

4. **Use SBOM for vulnerability management:**
```bash
# Scan SBOM instead of image (faster)
grype sbom:sbom.json
trivy sbom sbom.json

# Compare SBOMs between versions
diff <(syft old-image:1.0 -o json) <(syft new-image:2.0 -o json)
```

5. **SBOM formats:**
   - **SPDX:** Industry standard, ISO/IEC 5962:2021
   - **CycloneDX:** OWASP standard, security-focused
   - Choose based on compliance requirements

**Chainguard Images with Built-in SBOM:**
```bash
# Chainguard images include SBOM attestation by default
docker buildx imagetools inspect cgr.dev/chainguard/node:latest

# Extract SBOM
cosign download sbom cgr.dev/chainguard/node:latest > chainguard-node-sbom.json
```

**Or use multi-stage and don't include secrets:**
```dockerfile
FROM node AS builder
ARG NPM_TOKEN
RUN echo "//registry.npmjs.org/:_authToken=${NPM_TOKEN}" > .npmrc && \
    npm install && \
    rm .npmrc  # Still in layer history!

# Better - secret only in build stage
FROM node AS dependencies
RUN --mount=type=secret,id=npmrc,target=/root/.npmrc \
    npm install

FROM node AS runtime
COPY --from=dependencies /app/node_modules ./node_modules
# No .npmrc in final image
```

### Secure Build Context

**Threat:** Sensitive files included in build context

**Mitigation:**
Create comprehensive `.dockerignore`:
```bash
# Secrets
.env
.env.local
*.key
*.pem
credentials.json
secrets/

# Version control
.git
.gitignore

# Cloud credentials
.aws/
.gcloud/

# Private data
database.sql
backups/

# SSH keys
.ssh/
id_rsa
id_rsa.pub

# Sensitive logs
*.log
logs/
```

### Image Signing

**Enable Docker Content Trust:**
```bash
# Enable image signing
export DOCKER_CONTENT_TRUST=1

# Set up keys
docker trust key generate my-key
docker trust signer add --key my-key.pub my-name my-image

# Push signed image
docker push my-image:tag

# Pull only signed images
docker pull my-image:tag  # Fails if not signed
```

## Runtime Security

### User Privileges

**Threat:** Container escape via root

**Mitigation:**
```dockerfile
# Create and use non-root user
FROM node:20-alpine
RUN addgroup -g 1001 appuser && \
    adduser -S appuser -u 1001 -G appuser
USER appuser
WORKDIR /home/appuser/app
COPY --chown=appuser:appuser . .
CMD ["node", "server.js"]
```

**Verification:**
```bash
# Check user in running container
docker exec container-name whoami  # Should not be root
docker exec container-name id       # Check UID/GID
```

### Capabilities

**Threat:** Excessive kernel capabilities

**Default Docker capabilities:**
- CHOWN, DAC_OVERRIDE, FOWNER, FSETID
- KILL, SETGID, SETUID, SETPCAP
- NET_BIND_SERVICE, NET_RAW
- SYS_CHROOT, MKNOD, AUDIT_WRITE, SETFCAP

**Mitigation:**
```bash
# Drop all, add only needed
docker run \
  --cap-drop=ALL \
  --cap-add=NET_BIND_SERVICE \
  my-image
```

**In docker-compose.yml:**
```yaml
services:
  app:
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
```

**Common needed capabilities:**
- `NET_BIND_SERVICE`: Bind to ports < 1024
- `NET_ADMIN`: Network configuration
- `SYS_TIME`: Set system time

### Read-Only Filesystem

**Threat:** Container modification, malware persistence

**Mitigation:**
```bash
docker run \
  --read-only \
  --tmpfs /tmp:noexec,nosuid,size=64M \
  --tmpfs /var/run:noexec,nosuid,size=64M \
  my-image
```

**In Compose:**
```yaml
services:
  app:
    read_only: true
    tmpfs:
      - /tmp:noexec,nosuid,size=64M
      - /var/run:noexec,nosuid,size=64M
```

### Security Options

**no-new-privileges:**
```bash
docker run --security-opt="no-new-privileges:true" my-image
```

Prevents privilege escalation via setuid/setgid binaries.

**AppArmor (Linux):**
```bash
docker run --security-opt="apparmor=docker-default" my-image
```

**SELinux (Linux):**
```bash
docker run --security-opt="label=type:container_runtime_t" my-image
```

**Seccomp (syscall filtering):**
```bash
# Use default profile
docker run --security-opt="seccomp=default" my-image

# Or custom profile
docker run --security-opt="seccomp=./seccomp-profile.json" my-image
```

### Resource Limits

**Threat:** DoS via resource exhaustion

**Mitigation:**
```bash
docker run \
  --memory="512m" \
  --memory-swap="512m" \  # Disable swap
  --cpus="1.0" \
  --pids-limit=100 \
  --ulimit nofile=1024:1024 \
  my-image
```

**In Compose:**
```yaml
services:
  app:
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
          pids: 100
        reservations:
          cpus: '0.5'
          memory: 256M
    ulimits:
      nofile:
        soft: 1024
        hard: 1024
```

### Comprehensive Secure Run Command

```bash
docker run \
  --name secure-app \
  --detach \
  --restart unless-stopped \
  --user 1000:1000 \
  --cap-drop=ALL \
  --cap-add=NET_BIND_SERVICE \
  --read-only \
  --tmpfs /tmp:noexec,nosuid,size=64M \
  --security-opt="no-new-privileges:true" \
  --security-opt="seccomp=default" \
  --memory="512m" \
  --cpus="1.0" \
  --pids-limit=100 \
  --network=isolated-network \
  --publish 127.0.0.1:8080:8080 \
  --volume secure-data:/data:ro \
  --health-cmd="curl -f http://localhost/health || exit 1" \
  --health-interval=30s \
  my-secure-image:1.2.3
```

