---
name: cloudflare-knowledge
description: |
  Cloudflare platform knowledge — Workers, Pages, R2, D1, KV, Durable Objects, AI, and Zero Trust.
  PROACTIVELY activate for: (1) Cloudflare Workers (handlers, bindings, wrangler), (2) Cloudflare Pages and Pages Functions, (3) R2 object storage, (4) D1 SQL database, (5) Workers KV and Durable Objects, (6) Workers AI inference (LLMs, embeddings, image gen), (7) Vectorize (vector database), (8) Queues and Email Workers, (9) Zero Trust (Access, Tunnel/cloudflared, Gateway), (10) DNS, WAF, Rate Limiting, Page Rules.
  Provides: wrangler.toml templates, binding patterns, R2/D1/KV usage, Workers AI examples, and Zero Trust config.
---

# Cloudflare Knowledge Skill

Comprehensive Cloudflare platform knowledge covering Workers, edge storage, AI, MCP, and Zero Trust. Acts as a lean orchestrator over deep references in `references/`.

## Activation Triggers

Activate this skill when users ask about:

- Cloudflare Workers development, Wrangler CLI, `wrangler.jsonc` configuration
- Storage services (R2, D1, KV, Durable Objects, Queues, Hyperdrive)
- Workers AI inference (LLM, TTS, STT, image, embeddings, vision)
- MCP server development on Workers
- Zero Trust (tunnels, WARP, Access policies)
- Workflows and durable execution, Vectorize, Pages, cron triggers
- CI/CD with GitHub Actions or Workers Builds
- Observability, load balancing, cost optimization

## Reference Map

Load only the reference(s) the current task needs:

| Topic | File | When to load |
|-------|------|--------------|
| All Wrangler CLI commands, complete `wrangler.jsonc` schema, GitHub Actions, Workers Builds | `references/wrangler-cli-and-config.md` | Initializing projects, configuring bindings, writing CI pipelines, troubleshooting wrangler |
| KV, R2, D1, Durable Objects, Queues, Hyperdrive — characteristics, TypeScript APIs, best practices, WebSocket Hibernation, multipart upload | `references/storage-services-deep-dive.md` | Picking a storage service, writing handler code for any binding, designing schema or partitioning |
| Workers AI catalog (text/TTS/STT/image/vision/embeddings), invocation examples, MCP server on Workers, Cloudflare Tunnel install + Access policies + WARP | `references/ai-workers-usage.md` | Invoking AI models, building an MCP server, setting up `cloudflared`, configuring Zero Trust ingress |
| Workers AI model selection (which model for which task, context windows, perf) | `references/ai-workers-models.md` | Deciding between Llama, Mistral, Qwen, DeepSeek, Whisper variants, etc. |
| Deeper MCP server development (transport types, auth, tool schemas) | `references/mcp-server-development.md` | Building production MCP servers, debugging transport |
| Deeper Zero Trust setup (org policies, identity providers, posture checks) | `references/zero-trust-setup.md` | Production Zero Trust rollout |
| Cost comparison vs AWS/Azure/GCP, pricing tables, optimization tactics | `references/cost-comparison.md` | Budget planning, plan selection, cost optimization |
| Integrating non-Cloudflare services (Stripe, OpenAI, GitHub, third-party APIs from Workers) | `references/third-party-integrations.md` | Wiring external APIs into a Worker |

## Platform Overview

Cloudflare is a global edge computing platform with 300+ data centers providing:

- **Workers** — Serverless JavaScript/TypeScript/Python/WASM at the edge
- **Pages** — Static site and full-stack app hosting
- **R2** — S3-compatible object storage with zero egress fees
- **D1** — Serverless SQLite database (strongly consistent, 10 GB max)
- **KV** — Eventually consistent key-value store
- **Durable Objects** — Stateful coordination with WebSocket Hibernation
- **Queues** — Async message processing with DLQ
- **Hyperdrive** — Database connection pooling for remote Postgres/MySQL
- **Workers AI** — LLM/TTS/STT/image/embeddings/vision at the edge
- **Zero Trust** — Identity-based security platform
- **Vectorize** — Vector database for RAG
- **Workflows** — Durable multi-step execution

## Core Workflow

1. **Scaffold** — `npm create cloudflare@latest` then `npx wrangler login`. Wrangler CLI details: `wrangler-cli-and-config.md`.
2. **Pick a storage primitive** — KV for config/sessions, R2 for blobs, D1 for relational, Durable Objects for coordination, Queues for async, Hyperdrive for remote SQL. Characteristics and trade-offs: `storage-services-deep-dive.md`.
3. **Add bindings to `wrangler.jsonc`** — KV namespaces, R2 buckets, D1 databases, DO, Queues, AI, Vectorize, service bindings, cron triggers, routes, observability. Full schema: `wrangler-cli-and-config.md`.
4. **Implement handlers** — `fetch`, `scheduled`, `queue`, `email`. Per-binding APIs: `storage-services-deep-dive.md`. AI invocations: `ai-workers-usage.md`.
5. **Develop locally** — `npx wrangler dev` (use `--remote` for remote bindings; trigger crons via `/__scheduled?cron=*+*+*+*+*`).
6. **Deploy** — `npx wrangler deploy [--env staging]`. Roll back with `npx wrangler rollback`. CI/CD recipes (GitHub Actions, Workers Builds): `wrangler-cli-and-config.md`.

## Quick Decision Guide

| Task | Choice | Reference |
|------|--------|-----------|
| Store user sessions, config flags | KV (eventually consistent) | `storage-services-deep-dive.md` |
| Store media, backups, datasets | R2 (zero egress, 5 TB objects) | `storage-services-deep-dive.md` |
| Relational queries, ACID | D1 (SQLite, strong consistency) | `storage-services-deep-dive.md` |
| Real-time coordination, chat, counters | Durable Objects (+ WebSocket Hibernation) | `storage-services-deep-dive.md` |
| Background jobs, decoupling | Queues (at-least-once, DLQ) | `storage-services-deep-dive.md` |
| Remote Postgres/MySQL with low latency | Hyperdrive | `storage-services-deep-dive.md` |
| LLM/embedding/TTS/STT at the edge | Workers AI | `ai-workers-usage.md` + `ai-workers-models.md` |
| Expose internal app without opening firewall | Cloudflare Tunnel (`cloudflared`) | `ai-workers-usage.md` (quickstart) + `zero-trust-setup.md` (production) |
| Build MCP server on Workers | `@cloudflare/mcp-server` | `ai-workers-usage.md` (quickstart) + `mcp-server-development.md` (deep) |
| Integrate Stripe, OpenAI, GitHub, etc. | Third-party API patterns | `third-party-integrations.md` |
| Plan budget vs AWS/Azure/GCP | Pricing comparison | `cost-comparison.md` |

## Best Practices

### Performance

1. **Use edge caching** — cache API responses via `caches.default`.
2. **Minimize cold starts** — keep Workers small, prefer dynamic imports.
3. **Use Service Bindings** — zero-cost Worker-to-Worker calls.
4. **Batch operations** — combine KV/R2/D1 operations.
5. **Use Hyperdrive** for remote PostgreSQL/MySQL.

### Security

1. Use `wrangler secret put` for credentials, never hardcode.
2. Validate and sanitize all user input.
3. Always use HTTPS; enforce on routes.
4. Implement rate limiting (Workers Rate Limiting API or WAF rules).
5. Use Zero Trust Access for internal services (see `zero-trust-setup.md`).

### Cost Optimization

1. Use **Static Assets** (free, unlimited static file serving).
2. Sample logs via `observability.logs.head_sampling_rate` for high-traffic Workers.
3. Use KV/R2 for caching to reduce D1 or external API calls.
4. Batch Queue messages to reduce per-message overhead.
5. Choose model size to fit task in Workers AI — see `ai-workers-models.md`.
6. Full pricing tables and cross-cloud comparison: `cost-comparison.md`.

## Quick Reference

| Task | Command |
|------|---------|
| New project | `npm create cloudflare@latest` |
| Local dev | `npx wrangler dev` |
| Deploy | `npx wrangler deploy` |
| Create D1 | `npx wrangler d1 create <name>` |
| Create KV | `npx wrangler kv namespace create <NAME>` |
| Create R2 | `npx wrangler r2 bucket create <name>` |
| Set secret | `npx wrangler secret put <NAME>` |
| Create queue | `npx wrangler queues create <name>` |
| Create tunnel | `cloudflared tunnel create <name>` |
| Create Hyperdrive | `npx wrangler hyperdrive create <name> --connection-string=...` |

Full command surface (every flag, every subcommand) is in `references/wrangler-cli-and-config.md`.
