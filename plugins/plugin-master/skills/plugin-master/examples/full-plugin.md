# Full Plugin Example

A complete plugin demonstrating all component types.

## Structure

```
docker-master/
├── .claude-plugin/
│   └── plugin.json
├── agents/
│   └── docker-expert.md
├── commands/
│   └── docker-compose-up.md
├── skills/
│   └── docker-patterns/
│       ├── SKILL.md
│       ├── references/
│       │   └── dockerfile-best-practices.md
│       └── examples/
│           └── multi-stage-build.md
├── hooks/
│   └── hooks.json
├── scripts/
│   └── validate-dockerfile.sh
└── README.md
```

## Files

### .claude-plugin/plugin.json

```json
{
  "name": "docker-master",
  "version": "1.0.0",
  "description": "Complete Docker expertise. PROACTIVELY activate for: (1) Dockerfile creation, (2) Docker Compose setup, (3) Container optimization, (4) Multi-stage builds. Provides: best practices, security hardening, performance optimization.",
  "author": {
    "name": "DevOps Team",
    "email": "devops@example.com"
  },
  "homepage": "https://github.com/example/docker-master",
  "repository": "https://github.com/example/docker-master",
  "license": "MIT",
  "keywords": [
    "docker",
    "containers",
    "devops",
    "dockerfile",
    "docker-compose",
    "kubernetes"
  ]
}
```

### agents/docker-expert.md

```markdown
---
name: docker-expert
description: |
  Use this agent for Docker and container expertise. Trigger for:
  - Dockerfile creation and optimization
  - Docker Compose configuration
  - Container troubleshooting
  - Security hardening

  <example>
  Context: User needs Dockerfile help
  user: "Create a Dockerfile for my Node.js app"
  assistant: "I'll use the docker-expert agent to create an optimized Dockerfile."
  <commentary>Dockerfile creation request, trigger docker-expert.</commentary>
  </example>

  <example>
  Context: User has container issues
  user: "My container keeps crashing on startup"
  assistant: "I'll use the docker-expert agent to diagnose the issue."
  <commentary>Container troubleshooting, trigger docker-expert.</commentary>
  </example>

model: inherit
color: cyan
---

You are a Docker and containerization expert with deep knowledge of:
- Dockerfile best practices
- Multi-stage builds
- Docker Compose orchestration
- Container security
- Performance optimization

## Core Responsibilities

1. Create optimized Dockerfiles following best practices
2. Configure Docker Compose for development and production
3. Troubleshoot container issues
4. Implement security hardening
5. Optimize image sizes and build times

## Process

When helping with Docker tasks:

1. **Analyze Requirements**
   - Understand the application stack
   - Identify dependencies
   - Determine environment needs

2. **Apply Best Practices**
   - Use official base images
   - Implement multi-stage builds
   - Minimize layers
   - Use .dockerignore
   - Run as non-root user

3. **Security Considerations**
   - Scan for vulnerabilities
   - Use minimal base images
   - Don't store secrets in images
   - Set proper permissions

4. **Optimization**
   - Cache dependencies properly
   - Order instructions by change frequency
   - Use COPY instead of ADD
   - Combine RUN commands

## Output Format

Provide:
- Complete, working configuration files
- Explanation of key decisions
- Security considerations
- Performance tips
```

### commands/docker-compose-up.md

```markdown
---
description: Start Docker Compose services with proper checks
---

Start Docker Compose services after validating configuration.

## Process

1. Check for docker-compose.yml or compose.yaml
2. Validate configuration syntax
3. Check if Docker daemon is running
4. Start services with appropriate flags
5. Show service status

## Commands

```bash
# Validate compose file
docker compose config --quiet

# Start services
docker compose up -d

# Show status
docker compose ps
```

## Error Handling

- If no compose file: prompt user to create one
- If syntax error: show specific error and line
- If Docker not running: provide start instructions
```

### skills/docker-patterns/SKILL.md

```markdown
---
name: docker-patterns
description: |
  Docker configuration patterns and best practices. Activate for:
  (1) Dockerfile optimization
  (2) Multi-stage builds
  (3) Docker Compose patterns
  (4) Container security
---

# Docker Patterns

## Quick Reference

| Pattern | Use Case |
|---------|----------|
| Multi-stage build | Reduce image size |
| Non-root user | Security hardening |
| .dockerignore | Faster builds |
| Health checks | Container monitoring |

## Multi-Stage Build

```dockerfile
# Build stage
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Production stage
FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY . .
USER node
CMD ["node", "server.js"]
```

## Security Hardening

1. Use official, minimal base images
2. Run as non-root user
3. Don't store secrets in images
4. Scan images for vulnerabilities

## Additional Resources

See `references/dockerfile-best-practices.md` for detailed guidance.
See `examples/multi-stage-build.md` for complete examples.
```

### hooks/hooks.json

```json
{
  "PostToolUse": [
    {
      "matcher": "Write",
      "hooks": [
        {
          "type": "command",
          "command": "${CLAUDE_PLUGIN_ROOT}/scripts/validate-dockerfile.sh ${TOOL_INPUT_FILE_PATH}",
          "timeout": 5000
        }
      ]
    }
  ]
}
```

### scripts/validate-dockerfile.sh

```bash
#!/bin/bash
# Validate Dockerfile if one was written

FILE_PATH="$1"

# Only validate Dockerfiles
if [[ "$FILE_PATH" == *"Dockerfile"* ]]; then
    echo "Validating Dockerfile: $FILE_PATH"

    # Check for common issues
    if grep -q "^ADD " "$FILE_PATH"; then
        echo "Warning: Consider using COPY instead of ADD"
    fi

    if ! grep -q "^USER " "$FILE_PATH"; then
        echo "Warning: No USER instruction - container will run as root"
    fi

    echo "Dockerfile validation complete"
fi
```

### README.md

```markdown
# Docker Master

Complete Docker expertise for Claude Code.

## Features

- Dockerfile creation and optimization
- Docker Compose configuration
- Multi-stage build patterns
- Security hardening guidance
- Automatic Dockerfile validation

## Installation

```
/plugin marketplace add example/marketplace
/plugin install docker-master@example
```

## Usage

Just ask about Docker:
- "Create a Dockerfile for my Python app"
- "Set up Docker Compose for my microservices"
- "Optimize my container image size"

## Components

- **docker-expert agent**: Main expertise interface
- **docker-compose-up command**: Start services
- **docker-patterns skill**: Best practices knowledge
- **Dockerfile validation hook**: Auto-validates on write

## License

MIT
```

## Marketplace Registration

If publishing to a marketplace, add to `.claude-plugin/marketplace.json`:

```json
{
  "name": "docker-master",
  "source": "./plugins/docker-master",
  "description": "Complete Docker expertise. PROACTIVELY activate for: (1) Dockerfile creation, (2) Docker Compose setup, (3) Container optimization, (4) Multi-stage builds. Provides: best practices, security hardening, performance optimization.",
  "version": "1.0.0",
  "author": {
    "name": "DevOps Team"
  },
  "keywords": [
    "docker",
    "containers",
    "devops",
    "dockerfile",
    "docker-compose",
    "kubernetes"
  ]
}
```
