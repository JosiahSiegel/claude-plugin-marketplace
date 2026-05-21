---
name: docker-watch-mode-2025
description: |
  Docker Compose Watch mode for hot reload during local development (2025 GA).
  PROACTIVELY activate for: (1) docker compose watch setup, (2) watch action types (sync, rebuild, sync+restart, sync+exec), (3) configuring path filters and ignore patterns, (4) hot-reload for Node/Python/Go/Rust apps in Compose, (5) sync-only vs rebuild trade-offs, (6) using watch with profiles, (7) debugging watch mode (verbose logs), (8) integrating watch with bind mounts, (9) Compose watch vs nodemon/air/cargo-watch.
  Provides: watch action reference, per-language hot-reload examples, path filter patterns, and troubleshooting steps.
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

## Core Procedure

1. Confirm the app already starts with `docker compose up` before adding watch rules.
2. Prefer `sync` for source directories when the runtime already reloads files.
3. Use `rebuild` for dependency manifests, Dockerfiles, compiled artifacts, or base-image changes.
4. Use `sync+restart` for configuration files that are read only at process startup.
5. Add narrow `ignore` rules for dependency folders, build outputs, VCS folders, caches, secrets, and generated files.
6. Run `docker compose up --watch` and verify both fast source edits and dependency changes.

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
          ignore: [node_modules/, .git/, dist/]
        - action: rebuild
          path: ./frontend/package.json
```

Start with: `docker compose up --watch`.

## Troubleshooting Checklist

- Change not detected: verify the watched path is relative to the Compose file and not excluded by `ignore`.
- Hot reload not firing: confirm the application inside the container has its own watcher enabled.
- Container restarts too often: split source `sync` from manifest `rebuild` rules.
- File ownership issues: prefer named volumes for dependency directories and sync only application code.
- Slow sync: narrow watched paths and exclude build outputs or large generated folders.

## References

Use `docker compose watch --help` and Docker's Compose Watch documentation for the current action set and CLI flags. Pair this skill with `compose-patterns-2025` when watch rules interact with service dependencies, profiles, networks, or volumes.

## Benefits
- Better performance than broad bind mounts
- Fewer host/container file permission issues
- Intelligent syncing with rebuild capability
- Works across supported Docker Desktop and Compose platforms
