# cloudflare-master

Expert Cloudflare platform system with comprehensive 2025-2026 knowledge for all Cloudflare services and development patterns.

## Features

- **Workers Development**: JavaScript, TypeScript, Python, WASM edge compute
- **AI Workers**: TTS (Aura-2, MeloTTS), STT (Whisper), LLM inference, vision, embeddings
- **Storage Services**: R2, D1, KV, Durable Objects, Queues, Vectorize
- **Hyperdrive**: Database connection pooling for PostgreSQL/MySQL
- **Zero Trust**: Cloudflare Tunnel, WARP, Access policies
- **MCP Servers**: Model Context Protocol development on Workers
- **CI/CD**: GitHub Actions, Workers Builds
- **Observability**: Workers Logs, OpenTelemetry export

## Installation

```bash
claude plugins add cloudflare-master
```

## Usage

The `cloudflare-expert` agent activates automatically for any Cloudflare-related task. You can also use the slash commands directly:

### Commands

| Command | Description |
|---------|-------------|
| `/cloudflare-worker <name> [bindings]` | Create a new Worker with optional bindings (kv,r2,d1,do,queue,ai,hyperdrive) |
| `/cloudflare-deploy [env]` | Deploy Worker to production, staging, or preview |
| `/cloudflare-tunnel <name> <service> <hostname>` | Create Zero Trust tunnel |
| `/cloudflare-ai <task>` | Generate AI Workers code (tts, stt, image, chat, vision, embedding, rag) |
| `/cloudflare-debug [issue]` | Debug Workers issues (deploy, binding, performance, error) |

### Examples

```bash
# Create a Worker with KV and D1 bindings
/cloudflare-worker my-api kv,d1

# Deploy to staging
/cloudflare-deploy staging

# Create a tunnel to expose local service
/cloudflare-tunnel my-tunnel http://localhost:3000 app.example.com

# Generate TTS Worker code
/cloudflare-ai tts

# Debug deployment issues
/cloudflare-debug deploy
```

## Agent Capabilities

The `cloudflare-expert` agent can help with:

### Workers Development
- Project scaffolding and configuration
- Wrangler CLI commands and options
- TypeScript/JavaScript patterns
- Python Workers with `workers-python`
- WebAssembly modules

### Storage Solutions
- **KV**: Key-value caching, TTL strategies
- **R2**: S3-compatible object storage, presigned URLs
- **D1**: SQLite databases, migrations
- **Durable Objects**: Stateful coordination, WebSocket handling
- **Queues**: Async message processing
- **Vectorize**: Vector database for RAG

### AI Workers
- Text-to-Speech (Aura-2 for English, MeloTTS for multilingual)
- Speech-to-Text (Whisper large-v3-turbo)
- LLM inference (Llama 3.3 70B, Mistral, Qwen, DeepSeek)
- Image generation (FLUX.1, Stable Diffusion XL)
- Vision/captioning (Llama 3.2 Vision)
- Embeddings and RAG patterns

### Zero Trust
- Cloudflare Tunnel setup and configuration
- WARP client deployment
- Access policies and Service Auth
- Gateway DNS filtering
- JWT validation in Workers

### MCP Development
- Streamable HTTP transport
- Tools, Resources, and Prompts
- OAuth authorization
- Cloudflare service integration

### CI/CD & Observability
- GitHub Actions with wrangler-action
- Workers Builds
- Workers Logs and analytics
- OpenTelemetry export

## Skill Reference

The plugin includes comprehensive reference documentation:

- **cloudflare-knowledge**: Main skill with Wrangler CLI, storage services, AI models, Zero Trust, and CI/CD
- **ai-workers-models.md**: Complete AI model catalog with usage examples
- **mcp-server-development.md**: MCP server development guide
- **zero-trust-setup.md**: Zero Trust configuration reference

## Requirements

- Node.js 18+
- Wrangler CLI (`npm install -g wrangler`)
- Cloudflare account

## Version

1.0.0

## License

MIT
