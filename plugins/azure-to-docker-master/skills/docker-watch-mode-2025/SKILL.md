---
name: docker-watch-mode-2025
description: Docker Compose Watch mode for hot reload during local development (2025 GA). PROACTIVELY activate for: (1) docker compose watch setup, (2) watch action types (sync, rebuild, sync+restart, sync+exec), (3) configuring path filters and ignore patterns, (4) hot-reload for Node/Python/Go/Rust apps in Compose, (5) sync-only vs rebuild trade-offs, (6) using watch with profiles, (7) debugging watch mode (verbose logs), (8) integrating watch with bind mounts, (9) Compose watch vs nodemon/air/cargo-watch. Provides: watch action reference, per-language hot-reload examples, path filter patterns, and troubleshooting steps.
---

# Docker Compose Watch Mode (2025 GA)

Docker Compose Watch enables automatic hot reload during local development by synchronizing file changes instantly without manual container restarts.

## Three Watch Actions

### 1. sync - Hot Reload
For frameworks with hot reload (React, Next.js, Node.js, Flask).
Copies changed files directly into running container.

### 2. rebuild - Compilation
For compiled languages (Go, Rust, Java) or dependency changes.
Rebuilds image and recreates container when files change.

### 3. sync+restart - Config Changes
For configuration files requiring restart.
Syncs files and restarts container.

## Usage

```yaml
services:
  frontend:
    build: ./frontend
    develop:
      watch:
        - action: sync
          path: ./frontend/src
          target: /app/src
          ignore: [node_modules/, .git/]
        - action: rebuild
          path: ./frontend/package.json
```

Start with: `docker compose up --watch`

## Benefits
- Better performance than bind mounts
- No file permission issues
- Intelligent syncing
- Supports rebuild capability
- Works on all platforms
