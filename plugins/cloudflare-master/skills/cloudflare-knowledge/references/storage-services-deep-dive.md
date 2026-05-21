# Cloudflare Storage Services Deep Dive

Reference for KV, R2, D1, Durable Objects, Queues, and Hyperdrive — characteristics, APIs, and patterns.

## KV (Key-Value Store)

**Characteristics:**
- Eventually consistent (up to 60s propagation)
- Max value size: 25 MiB
- Max key size: 512 bytes
- Best for: Configuration, session data, caching
- Free tier: 100,000 reads/day, 1,000 writes/day

```typescript
interface Env {
  MY_KV: KVNamespace;
}

// Write operations
await env.MY_KV.put("key", "string value");
await env.MY_KV.put("key", JSON.stringify(object));
await env.MY_KV.put("key", arrayBuffer);

// With TTL (seconds)
await env.MY_KV.put("session", data, { expirationTtl: 3600 });

// With absolute expiration
await env.MY_KV.put("session", data, { expiration: Math.floor(Date.now() / 1000) + 3600 });

// With metadata
await env.MY_KV.put("user:123", userData, {
  metadata: { type: "user", version: 2 }
});

// Read operations
const value = await env.MY_KV.get("key");  // Returns string or null
const json = await env.MY_KV.get("key", "json");  // Parses JSON
const buffer = await env.MY_KV.get("key", "arrayBuffer");
const stream = await env.MY_KV.get("key", "stream");

// With metadata
const { value, metadata } = await env.MY_KV.getWithMetadata("key");

// List keys
const list = await env.MY_KV.list();
const filtered = await env.MY_KV.list({ prefix: "user:", limit: 100 });
// Pagination: use list.cursor for next page

// Delete
await env.MY_KV.delete("key");
```

## R2 (Object Storage)

**Characteristics:**
- S3-compatible API
- Zero egress fees
- Max object size: 5 TB
- Single upload max: 5 GB (use multipart for larger)
- Best for: Media files, backups, data lakes, large files

```typescript
interface Env {
  MY_BUCKET: R2Bucket;
}

// Put object
await env.MY_BUCKET.put("path/to/file.json", JSON.stringify(data), {
  httpMetadata: {
    contentType: "application/json",
    cacheControl: "max-age=3600",
  },
  customMetadata: {
    uploadedBy: "worker",
    version: "1.0",
  },
});

// Put with checksums
await env.MY_BUCKET.put("file.bin", data, {
  md5: expectedMd5,  // Validates on upload
  sha256: expectedSha256,
});

// Get object
const object = await env.MY_BUCKET.get("path/to/file.json");
if (object) {
  const text = await object.text();
  const json = await object.json();
  const buffer = await object.arrayBuffer();
  const blob = await object.blob();
  const stream = object.body;  // ReadableStream

  // Metadata
  console.log(object.key, object.size, object.etag);
  console.log(object.httpMetadata.contentType);
  console.log(object.customMetadata.uploadedBy);
}

// Head (metadata only)
const head = await env.MY_BUCKET.head("path/to/file.json");

// List objects
const list = await env.MY_BUCKET.list();
const filtered = await env.MY_BUCKET.list({
  prefix: "uploads/",
  delimiter: "/",
  limit: 1000,
});

// Delete
await env.MY_BUCKET.delete("path/to/file.json");
await env.MY_BUCKET.delete(["file1.json", "file2.json"]);  // Batch delete

// Multipart upload (for files > 5GB)
const upload = await env.MY_BUCKET.createMultipartUpload("large-file.zip");
const part1 = await upload.uploadPart(1, chunk1);
const part2 = await upload.uploadPart(2, chunk2);
await upload.complete([part1, part2]);

// Or abort
await upload.abort();
```

## D1 (SQLite Database)

**Characteristics:**
- Serverless SQLite
- Strong consistency
- Max database size: 10 GB (GA)
- Best for: Relational data, complex queries, ACID transactions

```typescript
interface Env {
  DB: D1Database;
}

// Prepared statements (recommended)
const stmt = env.DB.prepare("SELECT * FROM users WHERE id = ?");
const { results } = await stmt.bind(userId).all();
const user = await stmt.bind(userId).first();
const value = await stmt.bind(userId).first("name");  // Single column

// Insert/Update
const { meta } = await env.DB.prepare(
  "INSERT INTO users (name, email) VALUES (?, ?)"
).bind(name, email).run();
console.log(meta.last_row_id, meta.changes);

// Batch operations (single transaction)
const results = await env.DB.batch([
  env.DB.prepare("INSERT INTO users (name) VALUES (?)").bind("Alice"),
  env.DB.prepare("INSERT INTO users (name) VALUES (?)").bind("Bob"),
  env.DB.prepare("UPDATE counters SET value = value + 1 WHERE name = 'users'"),
]);

// Raw execution
await env.DB.exec("PRAGMA table_info(users)");

// Transaction pattern (using batch)
await env.DB.batch([
  env.DB.prepare("UPDATE accounts SET balance = balance - ? WHERE id = ?").bind(100, fromId),
  env.DB.prepare("UPDATE accounts SET balance = balance + ? WHERE id = ?").bind(100, toId),
]);
```

### D1 Best Practices

```sql
-- Create indexes for WHERE clause columns
CREATE INDEX idx_users_email ON users(email);

-- Use EXPLAIN QUERY PLAN to verify index usage
EXPLAIN QUERY PLAN SELECT * FROM users WHERE email = 'test@example.com';

-- Batch large migrations
DELETE FROM logs WHERE created_at < '2024-01-01' LIMIT 1000;

-- Run after schema changes
PRAGMA optimize;
```

## Durable Objects

**Characteristics:**
- Single-threaded, globally unique instances
- Built-in SQLite storage
- WebSocket support with Hibernation
- Best for: Real-time coordination, chat, games, counters

```typescript
// Durable Object class
export class Counter {
  state: DurableObjectState;
  value: number = 0;

  constructor(state: DurableObjectState, env: Env) {
    this.state = state;
    // Restore state from storage
    this.state.blockConcurrencyWhile(async () => {
      this.value = (await this.state.storage.get("value")) || 0;
    });
  }

  async fetch(request: Request): Promise<Response> {
    const url = new URL(request.url);

    switch (url.pathname) {
      case "/increment":
        this.value++;
        await this.state.storage.put("value", this.value);
        return Response.json({ value: this.value });

      case "/value":
        return Response.json({ value: this.value });

      default:
        return new Response("Not found", { status: 404 });
    }
  }
}

// Worker that uses the Durable Object
export default {
  async fetch(request: Request, env: Env) {
    const id = env.COUNTER.idFromName("global");
    const stub = env.COUNTER.get(id);
    return stub.fetch(request);
  },
};
```

### WebSocket Hibernation

```typescript
export class ChatRoom {
  state: DurableObjectState;

  constructor(state: DurableObjectState, env: Env) {
    this.state = state;
  }

  async fetch(request: Request): Promise<Response> {
    if (request.headers.get("Upgrade") === "websocket") {
      const pair = new WebSocketPair();
      const [client, server] = Object.values(pair);

      // Use Hibernation API
      this.state.acceptWebSocket(server);

      return new Response(null, { status: 101, webSocket: client });
    }
    return new Response("Expected WebSocket", { status: 400 });
  }

  // Called when hibernated DO receives WebSocket message
  async webSocketMessage(ws: WebSocket, message: string | ArrayBuffer) {
    // Broadcast to all connected clients
    for (const client of this.state.getWebSockets()) {
      if (client !== ws && client.readyState === WebSocket.READY_STATE_OPEN) {
        client.send(message);
      }
    }
  }

  async webSocketClose(ws: WebSocket, code: number, reason: string) {
    // Handle disconnect
  }

  async webSocketError(ws: WebSocket, error: unknown) {
    // Handle error
    ws.close(1011, "Internal error");
  }
}
```

## Queues

**Characteristics:**
- Async message processing
- At-least-once delivery
- Automatic retries with dead letter queues
- Best for: Decoupling, background jobs, event processing

```typescript
// Producer
interface Env {
  MY_QUEUE: Queue;
}

export default {
  async fetch(request: Request, env: Env) {
    // Send single message
    await env.MY_QUEUE.send({ type: "email", to: "user@example.com" });

    // Send with options
    await env.MY_QUEUE.send(
      { type: "process", id: 123 },
      { contentType: "json" }
    );

    // Batch send
    await env.MY_QUEUE.sendBatch([
      { body: { id: 1 } },
      { body: { id: 2 } },
      { body: { id: 3 } },
    ]);

    return new Response("Queued");
  },
};

// Consumer
interface QueueMessage {
  type: string;
  id?: number;
  to?: string;
}

export default {
  async queue(batch: MessageBatch<QueueMessage>, env: Env): Promise<void> {
    for (const message of batch.messages) {
      try {
        console.log(`Processing: ${JSON.stringify(message.body)}`);
        await processMessage(message.body);
        message.ack();  // Mark as processed
      } catch (e) {
        console.error(`Failed: ${e}`);
        message.retry();  // Will retry (up to max_retries)
      }
    }
  },
};
```

## Hyperdrive

Hyperdrive accelerates database connections by maintaining connection pools close to your database.

### Setup

```bash
# Create Hyperdrive config
npx wrangler hyperdrive create my-db \
  --connection-string="postgres://user:pass@host:5432/database"

# Add to wrangler.jsonc
```

### Usage

```typescript
import { Client } from "pg";

interface Env {
  MY_DB: Hyperdrive;
}

export default {
  async fetch(request: Request, env: Env) {
    // Connect using Hyperdrive connection string
    const client = new Client({
      connectionString: env.MY_DB.connectionString,
    });

    await client.connect();
    const result = await client.query("SELECT * FROM users WHERE id = $1", [1]);

    // No need to call client.end() - Hyperdrive manages pooling
    return Response.json(result.rows);
  },
};
```

### When to Use Hyperdrive

**Use Hyperdrive when:**
- Connecting to remote PostgreSQL/MySQL databases
- High-latency database connections (different regions)
- Frequent identical read queries (caching)
- Many concurrent database connections needed

**Don't use Hyperdrive when:**
- Using D1 (already edge-native)
- Local development (use direct connection)
- Need prepared statements across requests (transaction mode limitation)
- Using Durable Objects storage

### Performance Benefits

Without Hyperdrive:

```text
Worker -> TCP handshake (1 RTT)
       -> TLS negotiation (3 RTTs)
       -> DB authentication (3 RTTs)
       -> Query (1 RTT)
Total: 8 round-trips before first query
```

With Hyperdrive:

```text
Worker -> Hyperdrive pool (cached connection)
       -> Query (1 RTT to pool, reuses DB connection)
Total: 1 round-trip to query
```
