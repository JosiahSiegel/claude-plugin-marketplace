---
name: cloudflare-debug
description: Debug Cloudflare Workers issues with diagnostic commands and solutions
arguments:
  - name: issue
    description: "Issue type: deploy, binding, performance, error, timeout, memory"
    required: false
---

# Debug Cloudflare Workers

Diagnose and fix common Cloudflare Workers issues.

## Instructions

1. **Identify issue category** (if not specified, run general diagnostics)
2. **Execute diagnostic commands**
3. **Analyze output**
4. **Provide solutions**

## Diagnostic Commands

### General Health Check

```bash
# Check wrangler version
npx wrangler --version

# Validate configuration
npx wrangler deploy --dry-run

# Check authentication
npx wrangler whoami

# List deployed workers
npx wrangler deployments list
```

### Deployment Issues

```bash
# Test build locally
npx wrangler dev

# Check bundle size (must be < 10MB compressed)
npx wrangler deploy --dry-run --outdir ./dist
ls -la ./dist

# View deployment logs
npx wrangler tail

# Check for TypeScript errors
npx tsc --noEmit
```

**Common deployment fixes:**

1. **Bundle too large**:
   ```typescript
   // Use dynamic imports
   const heavyLib = await import('./heavy-lib');

   // Check for accidental dependencies
   // Remove from package.json: "dependencies" that should be "devDependencies"
   ```

2. **Compatibility flags missing**:
   ```jsonc
   // wrangler.jsonc
   {
     "compatibility_flags": ["nodejs_compat"]
   }
   ```

3. **Entry point not found**:
   ```jsonc
   // Ensure main points to correct file
   {
     "main": "src/index.ts"
   }
   ```

### Binding Issues

```bash
# List KV namespaces
npx wrangler kv namespace list

# List D1 databases
npx wrangler d1 list

# List R2 buckets
npx wrangler r2 bucket list

# Verify binding IDs in config
cat wrangler.jsonc | grep -A5 "kv_namespaces\|d1_databases\|r2_buckets"
```

**Common binding fixes:**

1. **KV not found**:
   ```bash
   # Create namespace
   npx wrangler kv namespace create CACHE

   # Update wrangler.jsonc with returned ID
   ```

2. **D1 connection error**:
   ```bash
   # Verify database exists
   npx wrangler d1 info my-database

   # Run migrations
   npx wrangler d1 migrations apply my-database
   ```

3. **R2 permission denied**:
   ```bash
   # Check bucket exists
   npx wrangler r2 bucket list

   # Verify binding name matches
   ```

### Performance Issues

```bash
# Profile Worker execution
npx wrangler tail --format json | jq '.logs'

# Check CPU time (limit: 50ms on free, 30s on paid)
npx wrangler tail --format json | jq '.outcome, .cpuTime'

# Monitor memory usage
npx wrangler tail --format json | jq '.logs[] | select(.level == "log")'
```

**Performance optimization:**

1. **Slow cold starts**:
   ```typescript
   // Move initialization outside handler
   const client = new MyClient(); // ✅ Outside

   export default {
     async fetch(request: Request, env: Env) {
       // const client = new MyClient(); // ❌ Inside
       return client.handle(request);
     }
   };
   ```

2. **High CPU time**:
   ```typescript
   // Use streaming for large responses
   return new Response(stream, {
     headers: { "Content-Type": "application/json" }
   });

   // Cache expensive computations
   const cached = await env.KV.get(key);
   if (cached) return new Response(cached);
   ```

3. **Memory issues**:
   ```typescript
   // Stream large files instead of buffering
   const object = await env.BUCKET.get(key);
   return new Response(object.body); // Stream directly

   // Avoid: await object.arrayBuffer(); // Buffers entire file
   ```

### Error Debugging

```bash
# View real-time logs
npx wrangler tail

# Filter errors only
npx wrangler tail --format json | jq 'select(.outcome == "exception")'

# Get stack traces
npx wrangler tail --format json | jq '.exceptions'
```

**Error handling patterns:**

```typescript
export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    try {
      // Main logic
      return await handleRequest(request, env);
    } catch (error) {
      // Log error details
      console.error("Error:", {
        message: error.message,
        stack: error.stack,
        url: request.url,
        method: request.method,
      });

      // Return user-friendly error
      return Response.json(
        {
          error: "Internal Server Error",
          requestId: crypto.randomUUID(),
        },
        { status: 500 }
      );
    }
  },
};
```

### Timeout Issues

**CPU time limits:**
- Free: 10ms CPU time
- Paid: 30s CPU time (soft), 15 minutes (hard with Cron)

**Diagnosing timeouts:**

```bash
# Check CPU time in logs
npx wrangler tail --format json | jq '.cpuTime'
```

**Solutions:**

1. **Offload to Queue**:
   ```typescript
   // Instead of processing inline
   await env.QUEUE.send({ task: "process", data: payload });
   return new Response("Accepted", { status: 202 });
   ```

2. **Use Durable Objects for long operations**:
   ```typescript
   const id = env.PROCESSOR.idFromName("task-1");
   const stub = env.PROCESSOR.get(id);
   return stub.fetch(request);
   ```

3. **Split into multiple requests**:
   ```typescript
   // Pagination for large datasets
   const { cursor } = await request.json();
   const results = await env.DB.prepare(
     "SELECT * FROM items WHERE id > ? LIMIT 100"
   ).bind(cursor).all();

   return Response.json({
     items: results.results,
     nextCursor: results.results[results.results.length - 1]?.id,
   });
   ```

### Memory Issues

**Memory limit: 128MB**

```bash
# Monitor memory in logs
npx wrangler tail --format json | jq '.logs'
```

**Solutions:**

1. **Stream large responses**:
   ```typescript
   // Stream R2 object directly
   const object = await env.BUCKET.get(key);
   return new Response(object.body);
   ```

2. **Process in chunks**:
   ```typescript
   // Read file in chunks
   const reader = object.body.getReader();
   while (true) {
     const { done, value } = await reader.read();
     if (done) break;
     // Process chunk
   }
   ```

3. **Avoid large JSON parsing**:
   ```typescript
   // Use streaming JSON parser for large payloads
   import { JSONParser } from "@streamparser/json";
   ```

## Quick Reference

| Issue | Command | Solution |
|-------|---------|----------|
| Deploy fails | `npx wrangler deploy --dry-run` | Check errors in output |
| Binding missing | `npx wrangler kv namespace list` | Verify IDs match config |
| Slow response | `npx wrangler tail` | Check CPU time, add caching |
| Errors in prod | `npx wrangler tail --format json` | Review exception stack |
| Timeout | Check CPU time in logs | Offload to Queue/DO |
| Memory | Stream large data | Avoid buffering |

## Debug Checklist

- [ ] `wrangler.jsonc` is valid JSON
- [ ] All binding IDs match created resources
- [ ] `compatibility_date` is recent
- [ ] `nodejs_compat` flag if using Node APIs
- [ ] No circular dependencies
- [ ] Bundle size < 10MB compressed
- [ ] CPU time within limits
- [ ] Memory usage < 128MB
- [ ] Error handling in place
- [ ] Logs output useful information
