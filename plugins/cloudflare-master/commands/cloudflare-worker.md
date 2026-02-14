---
name: cloudflare-worker
description: Create a new Cloudflare Worker with specified bindings and configuration
arguments:
  - name: name
    description: Worker name (lowercase, hyphens only)
    required: true
  - name: bindings
    description: "Comma-separated bindings: kv,r2,d1,do,queue,ai,hyperdrive"
    required: false
---

# Create Cloudflare Worker

Create a new Cloudflare Worker project with the specified name and bindings.

## Instructions

1. **Parse arguments**:
   - `name`: Worker name (required)
   - `bindings`: Comma-separated list of bindings (optional)
     - `kv` - KV Namespace
     - `r2` - R2 Bucket
     - `d1` - D1 Database
     - `do` - Durable Objects
     - `queue` - Queues
     - `ai` - Workers AI
     - `hyperdrive` - Hyperdrive

2. **Create project structure**:
   ```
   {name}/
   ├── src/
   │   └── index.ts
   ├── wrangler.jsonc
   ├── package.json
   └── tsconfig.json
   ```

3. **Generate wrangler.jsonc** with requested bindings

4. **Generate TypeScript types** for the Env interface

5. **Create example handler** demonstrating each binding

## Example Output

For `/cloudflare-worker my-api kv,d1,ai`:

### wrangler.jsonc

```jsonc
{
  "$schema": "./node_modules/wrangler/config-schema.json",
  "name": "my-api",
  "main": "src/index.ts",
  "compatibility_date": "2024-01-01",
  "compatibility_flags": ["nodejs_compat"],

  "kv_namespaces": [
    {
      "binding": "CACHE",
      "id": "<run: npx wrangler kv namespace create CACHE>"
    }
  ],

  "d1_databases": [
    {
      "binding": "DB",
      "database_id": "<run: npx wrangler d1 create my-api-db>",
      "database_name": "my-api-db"
    }
  ],

  "ai": {
    "binding": "AI"
  }
}
```

### src/index.ts

```typescript
interface Env {
  CACHE: KVNamespace;
  DB: D1Database;
  AI: Ai;
}

export default {
  async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    const url = new URL(request.url);

    // KV example
    if (url.pathname === '/cache') {
      const cached = await env.CACHE.get('data');
      if (cached) return new Response(cached);

      const data = JSON.stringify({ time: Date.now() });
      await env.CACHE.put('data', data, { expirationTtl: 300 });
      return new Response(data);
    }

    // D1 example
    if (url.pathname === '/users') {
      const { results } = await env.DB.prepare('SELECT * FROM users').all();
      return Response.json(results);
    }

    // AI example
    if (url.pathname === '/chat') {
      const { message } = await request.json();
      const response = await env.AI.run('@cf/meta/llama-3.3-70b-instruct-fp8-fast', {
        messages: [{ role: 'user', content: message }],
      });
      return Response.json(response);
    }

    return new Response('Hello from Cloudflare Workers!');
  },
};
```

## Setup Commands

After creating the files, run:

```bash
cd {name}
npm install
npx wrangler kv namespace create CACHE
npx wrangler d1 create my-api-db
# Update wrangler.jsonc with the IDs from above
npx wrangler dev
```
