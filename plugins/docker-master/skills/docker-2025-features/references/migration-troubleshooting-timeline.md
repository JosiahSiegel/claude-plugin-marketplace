# Docker 2025 Migration, Troubleshooting & Adoption Timeline

Migration paths to Docker Desktop 4.38+, troubleshooting for new 2025 features, and the recommended feature-adoption timeline. SKILL.md keeps a brief summary; this reference has the procedures.

## Migration Guide

### Updating to Docker Desktop 4.38+

**1. Backup existing configurations:**
```bash
# Export current settings
docker context export desktop-linux > backup.tar
```

**2. Update Docker Desktop:**
- Download latest from docker.com
- Run installer
- Restart machine if required

**3. Enable new features:**
```bash
# Enable AI Assistant (beta)
docker desktop settings set enableAI=true

# Enable Enhanced Container Isolation
docker desktop settings set enhancedContainerIsolation=true
```

**4. Test existing containers:**
```bash
# Verify containers work with ECI
docker compose up -d
docker compose ps
docker compose logs
```

### Updating Compose Files

**Before:**
```yaml
version: '3.8'

services:
  app:
    image: nginx:latest
    volumes:
      - data:/data

volumes:
  data:
```

**After:**
```yaml
services:
  app:
    image: nginx:1.26.0  # Specific version
    volumes:
      - data:/data
    develop:
      watch:
        - action: sync
          path: ./config
          target: /etc/nginx/conf.d
          initial_sync: full

volumes:
  data:
    driver: local
```

## Troubleshooting 2025 Features

### Docker AI Issues

**Problem:** AI Assistant not responding
**Solution:**
```bash
# Check Docker Desktop version
docker version

# Ensure beta features enabled
docker desktop settings get enableAI

# Restart Docker Desktop
```

**Problem:** Model Runner slow
**Solution:**
- Update GPU drivers
- Increase Docker Desktop memory (Settings > Resources)
- Close other GPU-intensive applications
- Use smaller models for faster inference

### Enhanced Container Isolation Issues

**Problem:** Container fails with socket permission error
**Solution:**
```bash
# Identify socket dependencies
docker inspect CONTAINER | grep -i socket

# If truly needed, add socket access explicitly
# (Document why in docker-compose.yml comments)
docker run -v /var/run/docker.sock:/var/run/docker.sock ...
```

**Problem:** ECI breaks CI/CD pipeline
**Solution:**
- Disable ECI temporarily: `docker desktop settings set enhancedContainerIsolation=false`
- Review which containers need socket access
- Refactor to eliminate socket dependencies
- Re-enable ECI with exceptions documented

### Compose v2.40 Issues

**Problem:** "version field is obsolete" warning
**Solution:**
```yaml
# Simply remove the version field
# OLD:
version: '3.8'
services: ...

# NEW:
services: ...
```

**Problem:** watch with initial_sync fails
**Solution:**
```bash
# Check file permissions
ls -la ./src

# Ensure paths are correct
docker compose config | grep -A 5 watch

# Verify sync target exists in container
docker compose exec app ls -la /app/src
```

## Recommended Feature Adoption Timeline

**Immediate (Production-Ready):**
- Bake for complex builds
- Compose v2.40 features (remove version field)
- Moby 25 engine (via regular Docker updates)
- BuildKit improvements (automatic)

**Testing (Beta but Stable):**
- Docker AI for development workflows
- Model Runner for local AI testing
- Multi-node Kubernetes for pre-production

**Evaluation (Security-Critical):**
- Enhanced Container Isolation (test thoroughly)
- ECI with existing production containers
- Socket access elimination strategies

This skill ensures you stay current with Docker's 2025 evolution while maintaining stability, security, and production-readiness.
