# MCP Integration Patterns

Model Context Protocol server integration for Claude Code plugins.

## Overview

MCP (Model Context Protocol) enables Claude to interact with external tools, APIs, and services through standardized server interfaces.

## Server Types

### stdio Server

Most common type - communicates via stdin/stdout.

```json
{
  "mcpServers": {
    "my-server": {
      "command": "node",
      "args": ["${CLAUDE_PLUGIN_ROOT}/mcp/server.js"]
    }
  }
}
```

### SSE Server

Server-sent events for real-time communication.

```json
{
  "mcpServers": {
    "streaming-server": {
      "type": "sse",
      "url": "https://api.example.com/mcp"
    }
  }
}
```

### HTTP Server

Standard HTTP request/response.

```json
{
  "mcpServers": {
    "http-server": {
      "type": "http",
      "url": "https://api.example.com/mcp"
    }
  }
}
```

## Configuration Locations

### Inline in plugin.json

```json
{
  "name": "my-plugin",
  "mcpServers": {
    "server-name": {
      "command": "...",
      "args": ["..."]
    }
  }
}
```

### Separate .mcp.json

```json
{
  "mcpServers": {
    "server-name": {
      "command": "...",
      "args": ["..."]
    }
  }
}
```

## Common Patterns

### NPM Package Server

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/dir"]
    }
  }
}
```

### Python Server

```json
{
  "mcpServers": {
    "python-tools": {
      "command": "python",
      "args": ["${CLAUDE_PLUGIN_ROOT}/mcp/server.py"]
    }
  }
}
```

### Docker Container

```json
{
  "mcpServers": {
    "containerized-server": {
      "command": "docker",
      "args": ["run", "-i", "--rm", "my-mcp-server:latest"]
    }
  }
}
```

## API Integrations

### Stripe

```json
{
  "mcpServers": {
    "stripe": {
      "command": "npx",
      "args": ["-y", "@stripe/mcp-server"],
      "env": {
        "STRIPE_API_KEY": "${STRIPE_API_KEY}"
      }
    }
  }
}
```

### GitHub

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}"
      }
    }
  }
}
```

### Database

```json
{
  "mcpServers": {
    "postgres": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres"],
      "env": {
        "DATABASE_URL": "${DATABASE_URL}"
      }
    }
  }
}
```

### Slack

```json
{
  "mcpServers": {
    "slack": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-slack"],
      "env": {
        "SLACK_BOT_TOKEN": "${SLACK_BOT_TOKEN}"
      }
    }
  }
}
```

## Environment Variables

### Using Plugin Variables

```json
{
  "mcpServers": {
    "server": {
      "command": "node",
      "args": ["${CLAUDE_PLUGIN_ROOT}/mcp/server.js"],
      "env": {
        "CONFIG_PATH": "${CLAUDE_PLUGIN_ROOT}/config.json"
      }
    }
  }
}
```

### Using System Variables

```json
{
  "mcpServers": {
    "server": {
      "command": "node",
      "args": ["${CLAUDE_PLUGIN_ROOT}/mcp/server.js"],
      "env": {
        "HOME_DIR": "${HOME}",
        "API_KEY": "${MY_API_KEY}"
      }
    }
  }
}
```

## Creating Custom Servers

### Basic Node.js Server

```javascript
// mcp/server.js
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';

const server = new Server({
  name: 'my-server',
  version: '1.0.0'
}, {
  capabilities: {
    tools: {}
  }
});

// Register tools
server.setRequestHandler('tools/list', async () => ({
  tools: [{
    name: 'my-tool',
    description: 'Does something useful',
    inputSchema: {
      type: 'object',
      properties: {
        input: { type: 'string' }
      },
      required: ['input']
    }
  }]
}));

server.setRequestHandler('tools/call', async (request) => {
  const { name, arguments: args } = request.params;

  if (name === 'my-tool') {
    // Implement tool logic
    return {
      content: [{
        type: 'text',
        text: `Result: ${args.input}`
      }]
    };
  }

  throw new Error(`Unknown tool: ${name}`);
});

// Start server
const transport = new StdioServerTransport();
await server.connect(transport);
```

### Basic Python Server

```python
# mcp/server.py
import asyncio
from mcp.server import Server
from mcp.server.stdio import stdio_server

app = Server("my-server")

@app.list_tools()
async def list_tools():
    return [{
        "name": "my-tool",
        "description": "Does something useful",
        "inputSchema": {
            "type": "object",
            "properties": {
                "input": {"type": "string"}
            },
            "required": ["input"]
        }
    }]

@app.call_tool()
async def call_tool(name: str, arguments: dict):
    if name == "my-tool":
        return f"Result: {arguments['input']}"
    raise ValueError(f"Unknown tool: {name}")

if __name__ == "__main__":
    asyncio.run(stdio_server(app))
```

## Best Practices

### Security

- Never hardcode API keys
- Use environment variables for secrets
- Document required credentials
- Validate all inputs

### Reliability

- Handle connection failures gracefully
- Implement retry logic
- Set appropriate timeouts
- Log errors for debugging

### Documentation

- List all required environment variables
- Provide setup instructions
- Document available tools
- Include usage examples

### Testing

- Test server independently first
- Verify environment variables are set
- Check MCP server logs for errors
- Use `/mcp` command to verify registration

## Troubleshooting

### Server not starting

- Check command path is correct
- Verify dependencies are installed
- Test command manually in terminal
- Check for missing environment variables

### Tools not appearing

- Verify server starts without errors
- Check tool registration in server code
- Use `claude --debug` to see MCP logs
- Restart Claude Code after changes

### Connection errors

- Check network connectivity
- Verify URLs and ports
- Check authentication credentials
- Review server logs

### Timeout issues

- Increase timeout in configuration
- Optimize server response time
- Consider async operations
- Add progress indicators
