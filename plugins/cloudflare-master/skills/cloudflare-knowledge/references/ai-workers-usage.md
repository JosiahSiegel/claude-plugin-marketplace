# Workers AI Usage Examples

Reference for invoking Workers AI models from a Worker — text generation, streaming, TTS, STT, image generation, embeddings, vision. For the full model catalog (which model to pick), see `ai-workers-models.md`.

## Available Models (2025-2026)

### Text Generation

| Model | Context | Best For |
|-------|---------|----------|
| @cf/meta/llama-3.3-70b-instruct-fp8-fast | 128K | General, reasoning |
| @cf/mistral/mistral-7b-instruct-v0.2 | 32K | Fast, efficient |
| @cf/qwen/qwen2.5-72b-instruct | 128K | Multilingual |
| @cf/deepseek/deepseek-r1-distill-llama-70b | 64K | Complex reasoning |

### Text-to-Speech (TTS)

| Model | Languages | Notes |
|-------|-----------|-------|
| @deepgram/aura-2-en | English | Best quality, context-aware |
| @deepgram/aura-1 | English | Fast, good quality |
| @cf/myshell-ai/melotts | en, fr, es, zh, ja, ko | Multi-lingual |

### Speech-to-Text (STT)

| Model | Languages | Notes |
|-------|-----------|-------|
| @cf/openai/whisper-large-v3-turbo | 100+ | Fast, accurate |
| @cf/openai/whisper | 100+ | Original Whisper |

### Image Generation

| Model | Resolution | Notes |
|-------|------------|-------|
| @cf/black-forest-labs/flux-1-schnell | Up to 1024x1024 | Fast |
| @cf/stabilityai/stable-diffusion-xl-base-1.0 | Up to 1024x1024 | Detailed |

### Vision/Captioning

| Model | Capabilities |
|-------|--------------|
| @cf/meta/llama-3.2-11b-vision-instruct | Image understanding, captioning |
| @cf/llava-hf/llava-1.5-7b-hf | Visual Q&A |

### Embeddings

| Model | Dimensions | Notes |
|-------|------------|-------|
| @cf/baai/bge-large-en-v1.5 | 1024 | Best quality |
| @cf/baai/bge-small-en-v1.5 | 384 | Faster |

## Usage Examples

```typescript
interface Env {
  AI: Ai;
}

// Text generation
const response = await env.AI.run("@cf/meta/llama-3.3-70b-instruct-fp8-fast", {
  messages: [
    { role: "system", content: "You are a helpful assistant." },
    { role: "user", content: "What is Cloudflare?" },
  ],
  max_tokens: 512,
  temperature: 0.7,
});

// Streaming
const stream = await env.AI.run("@cf/meta/llama-3.3-70b-instruct-fp8-fast", {
  messages: [...],
  stream: true,
});
return new Response(stream, {
  headers: { "Content-Type": "text/event-stream" },
});

// Text-to-Speech
const audio = await env.AI.run("@deepgram/aura-2-en", {
  text: "Hello, this is a test.",
});
return new Response(audio, {
  headers: { "Content-Type": "audio/wav" },
});

// Speech-to-Text
const transcript = await env.AI.run("@cf/openai/whisper-large-v3-turbo", {
  audio: audioArrayBuffer,
});
// Returns { text: "...", segments: [...] }

// Image generation
const image = await env.AI.run("@cf/black-forest-labs/flux-1-schnell", {
  prompt: "A futuristic cityscape at sunset",
  num_steps: 4,
});
return new Response(image, {
  headers: { "Content-Type": "image/png" },
});

// Embeddings
const embeddings = await env.AI.run("@cf/baai/bge-large-en-v1.5", {
  text: ["Hello world", "Cloudflare Workers"],
});
// Returns { data: [{ embedding: [...] }, { embedding: [...] }] }

// Image captioning
const caption = await env.AI.run("@cf/meta/llama-3.2-11b-vision-instruct", {
  image: imageArrayBuffer,
  prompt: "Describe this image in detail.",
});
```

## MCP Servers on Workers

Building an MCP server on Workers:

```typescript
import { McpServer } from "@cloudflare/mcp-server";

interface Env {
  DB: D1Database;
}

const server = new McpServer({
  name: "my-mcp-server",
  version: "1.0.0",
});

// Define tools
server.addTool({
  name: "query_database",
  description: "Query the D1 database",
  parameters: {
    type: "object",
    properties: {
      query: { type: "string", description: "SQL query to execute" },
    },
    required: ["query"],
  },
  handler: async ({ query }, { env }) => {
    const result = await env.DB.prepare(query).all();
    return {
      content: [{ type: "text", text: JSON.stringify(result.results) }],
    };
  },
});

// Define resources
server.addResource({
  uri: "db://tables",
  name: "Database Tables",
  description: "List of all tables",
  handler: async ({ env }) => {
    const tables = await env.DB.prepare(
      "SELECT name FROM sqlite_master WHERE type='table'"
    ).all();
    return {
      contents: [{ uri: "db://tables", text: JSON.stringify(tables.results) }],
    };
  },
});

export default {
  async fetch(request: Request, env: Env) {
    return server.handleRequest(request, env);
  },
};
```

### MCP Transport Types

1. **Streamable HTTP** (Recommended, March 2025+) — Single HTTP endpoint, bidirectional messaging, standard for remote MCP
2. **stdio** (Local only) — Standard input/output, for local MCP connections
3. **SSE** (Deprecated) — Use Streamable HTTP instead

### Cloudflare's Managed MCP Servers

Available at `https://mcp.cloudflare.com/`:
- Workers management
- R2 bucket operations
- D1 database queries
- DNS management
- Analytics access

Connect from Claude/Cursor:

```json
{
  "mcpServers": {
    "cloudflare": {
      "url": "https://mcp.cloudflare.com/sse",
      "transport": "sse"
    }
  }
}
```

For detailed MCP server development guidance, see `mcp-server-development.md`.

## Zero Trust: Cloudflare Tunnel

Expose internal services securely without opening firewall ports.

**Installation:**

```bash
# macOS
brew install cloudflared

# Windows
winget install Cloudflare.cloudflared

# Linux
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o cloudflared
sudo chmod +x cloudflared && sudo mv cloudflared /usr/local/bin/
```

**Setup:**

```bash
# Login
cloudflared tunnel login

# Create tunnel
cloudflared tunnel create my-tunnel

# Create config file (~/.cloudflared/config.yml)
cat << EOF > ~/.cloudflared/config.yml
tunnel: <tunnel-id>
credentials-file: $HOME/.cloudflared/<tunnel-id>.json

ingress:
  - hostname: app.example.com
    service: http://localhost:3000
  - hostname: api.example.com
    service: http://localhost:8080
  - service: http_status:404
EOF

# Add DNS
cloudflared tunnel route dns my-tunnel app.example.com

# Run
cloudflared tunnel run my-tunnel
```

**Run as Service:**

```bash
# Linux
sudo cloudflared service install
sudo systemctl enable cloudflared
sudo systemctl start cloudflared

# macOS
sudo cloudflared service install
sudo launchctl load /Library/LaunchDaemons/com.cloudflare.cloudflared.plist
```

### Access Policies

Configure in Cloudflare dashboard (Zero Trust > Access > Applications):

```yaml
Application:
  name: Internal App
  type: Self-hosted
  domain: app.example.com

Policy:
  name: Allow Company
  action: Allow
  include:
    - email_domain: company.com
  require:
    - country: US
```

### WARP Client

- Device client for Zero Trust enrollment
- Routes traffic through Cloudflare network
- Enables identity-based access policies
- Split tunneling for selective routing

For deeper Zero Trust setup, see `zero-trust-setup.md`.
