# MCP Server Development on Cloudflare

## Overview

Model Context Protocol (MCP) is an open standard that connects AI systems with external applications. Cloudflare supports building and deploying MCP servers on Workers, enabling AI assistants to interact with your services.

## Core Concepts

### MCP Components

1. **MCP Hosts**: AI assistants (Claude, Cursor, custom agents) that need external capabilities
2. **MCP Clients**: Clients embedded within hosts that connect to MCP servers
3. **MCP Servers**: Applications that expose tools, prompts, and resources

### Transport Types

1. **Streamable HTTP** (Recommended for remote, March 2025+)
   - Single HTTP endpoint for bidirectional messaging
   - Standard for remote MCP connections

2. **stdio** (Local only)
   - Standard input/output communication
   - For local MCP connections

3. **SSE** (Deprecated)
   - Server-Sent Events
   - Legacy, use Streamable HTTP instead

---

## Building MCP Server on Workers

### Basic Setup

```bash
npm create cloudflare@latest my-mcp-server
cd my-mcp-server
npm install @cloudflare/mcp-server
```

### wrangler.jsonc

```jsonc
{
  "$schema": "./node_modules/wrangler/config-schema.json",
  "name": "my-mcp-server",
  "main": "src/index.ts",
  "compatibility_date": "2024-01-01",
  "compatibility_flags": ["nodejs_compat"]
}
```

### Basic MCP Server

```typescript
import { McpServer } from "@cloudflare/mcp-server";

interface Env {
  // Your bindings
}

const server = new McpServer({
  name: "my-mcp-server",
  version: "1.0.0",
  description: "My custom MCP server for Cloudflare services",
});

export default {
  async fetch(request: Request, env: Env, ctx: ExecutionContext) {
    return server.handleRequest(request, env, ctx);
  },
};
```

---

## Defining Tools

Tools are functions that AI assistants can invoke.

### Basic Tool

```typescript
server.addTool({
  name: "get_current_time",
  description: "Get the current UTC time",
  parameters: {
    type: "object",
    properties: {},
  },
  handler: async () => {
    return {
      content: [
        {
          type: "text",
          text: new Date().toISOString(),
        },
      ],
    };
  },
});
```

### Tool with Parameters

```typescript
server.addTool({
  name: "search_products",
  description: "Search for products in the catalog",
  parameters: {
    type: "object",
    properties: {
      query: {
        type: "string",
        description: "Search query",
      },
      category: {
        type: "string",
        description: "Product category filter",
        enum: ["electronics", "clothing", "books", "home"],
      },
      limit: {
        type: "number",
        description: "Maximum number of results",
        default: 10,
      },
    },
    required: ["query"],
  },
  handler: async ({ query, category, limit }, { env }) => {
    // Access your D1 database or other services
    const products = await searchProducts(env.DB, query, category, limit);

    return {
      content: [
        {
          type: "text",
          text: JSON.stringify(products, null, 2),
        },
      ],
    };
  },
});
```

### Tool with Complex Response

```typescript
server.addTool({
  name: "analyze_image",
  description: "Analyze an image and return description",
  parameters: {
    type: "object",
    properties: {
      url: {
        type: "string",
        description: "URL of the image to analyze",
      },
    },
    required: ["url"],
  },
  handler: async ({ url }, { env }) => {
    // Fetch image
    const response = await fetch(url);
    const imageData = await response.arrayBuffer();

    // Analyze with Workers AI
    const analysis = await env.AI.run("@cf/meta/llama-3.2-11b-vision-instruct", {
      image: imageData,
      prompt: "Describe this image in detail.",
    });

    return {
      content: [
        {
          type: "text",
          text: analysis.response,
        },
      ],
      isError: false,
    };
  },
});
```

---

## Defining Resources

Resources are data sources that AI assistants can read.

### Static Resource

```typescript
server.addResource({
  uri: "config://app-settings",
  name: "Application Settings",
  description: "Current application configuration",
  mimeType: "application/json",
  handler: async () => {
    return {
      contents: [
        {
          uri: "config://app-settings",
          text: JSON.stringify({
            version: "1.0.0",
            features: ["search", "analytics", "export"],
          }),
        },
      ],
    };
  },
});
```

### Dynamic Resource

```typescript
server.addResource({
  uri: "db://users/{id}",
  name: "User Profile",
  description: "Get user profile by ID",
  mimeType: "application/json",
  handler: async ({ uri }, { env }) => {
    const id = uri.split("/").pop();
    const user = await env.DB.prepare(
      "SELECT * FROM users WHERE id = ?"
    ).bind(id).first();

    return {
      contents: [
        {
          uri,
          text: JSON.stringify(user),
        },
      ],
    };
  },
});
```

### List Resources

```typescript
server.addResource({
  uri: "db://tables",
  name: "Database Tables",
  description: "List all tables in the database",
  handler: async ({ env }) => {
    const tables = await env.DB.prepare(
      "SELECT name FROM sqlite_master WHERE type='table'"
    ).all();

    return {
      contents: [
        {
          uri: "db://tables",
          text: JSON.stringify(tables.results),
        },
      ],
    };
  },
});
```

---

## Defining Prompts

Prompts are reusable templates for AI interactions.

```typescript
server.addPrompt({
  name: "summarize_data",
  description: "Summarize data from the database",
  arguments: [
    {
      name: "table",
      description: "Table name to summarize",
      required: true,
    },
    {
      name: "format",
      description: "Output format (brief, detailed)",
      required: false,
    },
  ],
  handler: async ({ table, format = "brief" }, { env }) => {
    const data = await env.DB.prepare(`SELECT * FROM ${table} LIMIT 100`).all();

    return {
      messages: [
        {
          role: "user",
          content: {
            type: "text",
            text: `Please provide a ${format} summary of this data:\n\n${JSON.stringify(data.results)}`,
          },
        },
      ],
    };
  },
});
```

---

## OAuth Authorization

MCP uses OAuth 2.1 for authorization.

### Setup OAuth Provider

```typescript
import { McpServer, OAuthProvider } from "@cloudflare/mcp-server";

const oauth = new OAuthProvider({
  clientId: "your-client-id",
  clientSecret: env.OAUTH_CLIENT_SECRET,
  authorizationEndpoint: "https://auth.example.com/authorize",
  tokenEndpoint: "https://auth.example.com/token",
  scopes: ["read", "write"],
});

const server = new McpServer({
  name: "my-secure-mcp-server",
  version: "1.0.0",
  oauth,
});

// Tools will have access to the authenticated user
server.addTool({
  name: "get_my_data",
  description: "Get data for the authenticated user",
  handler: async (params, { env, user }) => {
    // user contains OAuth user info
    const data = await fetchUserData(user.id);
    return {
      content: [{ type: "text", text: JSON.stringify(data) }],
    };
  },
});
```

### Using Cloudflare Access

```typescript
// Verify Cloudflare Access JWT
async function verifyAccess(request: Request, env: Env) {
  const jwt = request.headers.get("CF-Access-JWT-Assertion");
  if (!jwt) return null;

  // Verify with Access public keys
  const response = await fetch(
    `https://${env.TEAM_DOMAIN}/cdn-cgi/access/certs`
  );
  const certs = await response.json();

  // Verify JWT signature and claims
  // ... verification logic

  return decodedToken;
}
```

---

## Complete Example: Database MCP Server

```typescript
import { McpServer } from "@cloudflare/mcp-server";

interface Env {
  DB: D1Database;
  AI: Ai;
}

const server = new McpServer({
  name: "database-mcp",
  version: "1.0.0",
  description: "MCP server for database operations",
});

// Tool: Query database
server.addTool({
  name: "query_database",
  description: "Execute a read-only SQL query",
  parameters: {
    type: "object",
    properties: {
      query: {
        type: "string",
        description: "SQL query (SELECT only)",
      },
    },
    required: ["query"],
  },
  handler: async ({ query }, { env }) => {
    // Security: Only allow SELECT
    if (!query.trim().toUpperCase().startsWith("SELECT")) {
      return {
        content: [{ type: "text", text: "Error: Only SELECT queries allowed" }],
        isError: true,
      };
    }

    try {
      const result = await env.DB.prepare(query).all();
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify(result.results, null, 2),
          },
        ],
      };
    } catch (error) {
      return {
        content: [{ type: "text", text: `Error: ${error.message}` }],
        isError: true,
      };
    }
  },
});

// Tool: Describe table
server.addTool({
  name: "describe_table",
  description: "Get schema information for a table",
  parameters: {
    type: "object",
    properties: {
      table: {
        type: "string",
        description: "Table name",
      },
    },
    required: ["table"],
  },
  handler: async ({ table }, { env }) => {
    const schema = await env.DB.prepare(
      `PRAGMA table_info(${table})`
    ).all();

    return {
      content: [
        {
          type: "text",
          text: JSON.stringify(schema.results, null, 2),
        },
      ],
    };
  },
});

// Tool: Generate SQL
server.addTool({
  name: "generate_sql",
  description: "Generate SQL query from natural language",
  parameters: {
    type: "object",
    properties: {
      description: {
        type: "string",
        description: "Natural language description of the query",
      },
    },
    required: ["description"],
  },
  handler: async ({ description }, { env }) => {
    // Get schema context
    const tables = await env.DB.prepare(
      "SELECT name FROM sqlite_master WHERE type='table'"
    ).all();

    const schemaInfo = [];
    for (const table of tables.results) {
      const schema = await env.DB.prepare(
        `PRAGMA table_info(${table.name})`
      ).all();
      schemaInfo.push({ table: table.name, columns: schema.results });
    }

    // Use AI to generate SQL
    const response = await env.AI.run("@cf/meta/llama-3.3-70b-instruct-fp8-fast", {
      messages: [
        {
          role: "system",
          content: `You are a SQL expert. Generate a SQLite query based on the user's request.
Schema:
${JSON.stringify(schemaInfo, null, 2)}

Only respond with the SQL query, no explanation.`,
        },
        {
          role: "user",
          content: description,
        },
      ],
    });

    return {
      content: [{ type: "text", text: response.response }],
    };
  },
});

// Resource: List tables
server.addResource({
  uri: "db://tables",
  name: "Database Tables",
  description: "List all tables in the database",
  handler: async ({ env }) => {
    const tables = await env.DB.prepare(
      "SELECT name FROM sqlite_master WHERE type='table'"
    ).all();

    return {
      contents: [
        {
          uri: "db://tables",
          text: JSON.stringify(tables.results.map((t) => t.name)),
        },
      ],
    };
  },
});

export default {
  async fetch(request: Request, env: Env, ctx: ExecutionContext) {
    return server.handleRequest(request, env, ctx);
  },
};
```

---

## Connecting to MCP Server

### From Claude Desktop

```json
// ~/.claude/config.json
{
  "mcpServers": {
    "my-server": {
      "url": "https://my-mcp-server.your-subdomain.workers.dev",
      "transport": "streamable-http"
    }
  }
}
```

### From Cursor

```json
// .cursor/mcp.json
{
  "servers": {
    "my-server": {
      "url": "https://my-mcp-server.your-subdomain.workers.dev",
      "transport": "streamable-http"
    }
  }
}
```

### Cloudflare's Managed MCP Servers

Connect to Cloudflare's built-in MCP servers:

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

Available tools:
- Workers management (deploy, list, logs)
- R2 bucket operations
- D1 database queries
- DNS management
- Analytics access

---

## Best Practices

### Security

1. **Validate all inputs** - Never trust user/AI input
2. **Use OAuth** for authenticated access
3. **Limit tool permissions** - Only allow necessary operations
4. **Log all tool invocations** for audit

### Performance

1. **Use caching** for frequently accessed resources
2. **Set timeouts** for external API calls
3. **Batch operations** when possible

### Error Handling

```typescript
server.addTool({
  name: "risky_operation",
  handler: async (params, { env }) => {
    try {
      const result = await riskyOperation(params);
      return {
        content: [{ type: "text", text: JSON.stringify(result) }],
        isError: false,
      };
    } catch (error) {
      // Return structured error
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({
              error: error.message,
              code: error.code || "UNKNOWN",
              suggestion: "Try with different parameters",
            }),
          },
        ],
        isError: true,
      };
    }
  },
});
```

---

## Testing

### Local Testing

```bash
npx wrangler dev

# In another terminal
curl -X POST http://localhost:8787/mcp \
  -H "Content-Type: application/json" \
  -d '{"method": "tools/list"}'
```

### MCP Inspector

Use the MCP Inspector tool for interactive testing:

```bash
npx @modelcontextprotocol/inspector http://localhost:8787
```

---

## Deployment

```bash
# Deploy
npx wrangler deploy

# Your MCP server is now available at:
# https://my-mcp-server.your-subdomain.workers.dev
```
