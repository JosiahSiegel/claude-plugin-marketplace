---
name: Debug Integration
description: Diagnose and fix common issues with fal.ai integrations including authentication, API errors, and timeouts
argument-hint: [error-type: auth|rate-limit|timeout|validation|upload|websocket]
---

# Debug fal.ai Integration Issues

Diagnose and fix common issues with fal.ai integrations, including authentication, API errors, timeouts, and deployment problems.

## What This Command Does

Helps troubleshoot fal.ai integration issues by:
- Identifying common error patterns
- Providing diagnostic steps
- Suggesting fixes for specific errors
- Offering best practices to prevent issues

## Common Issues and Solutions

### 1. Authentication Errors

**Symptoms:**
- `401 Unauthorized`
- `Invalid API key`
- `Authentication required`

**Diagnostic Steps:**
```bash
# Check if FAL_KEY is set
echo $FAL_KEY

# Verify key format (should start with specific prefix)
# Keys typically look like: fal_xxx...

# Test authentication
curl -H "Authorization: Key $FAL_KEY" https://fal.run/fal-ai/flux/dev
```

**Solutions:**

```typescript
// JavaScript - Ensure proper configuration
import { fal } from "@fal-ai/client";

// Method 1: Environment variable (recommended)
// Set FAL_KEY in your environment
// The client automatically reads process.env.FAL_KEY

// Method 2: Explicit configuration
fal.config({
  credentials: process.env.FAL_KEY  // Don't hardcode!
});

// Method 3: Per-request credentials
const result = await fal.subscribe("fal-ai/flux/dev", {
  input: { prompt: "test" },
  credentials: process.env.FAL_KEY
});
```

```python
# Python - Set environment variable
import os
os.environ["FAL_KEY"] = "your-key"  # Before importing fal_client

# Or use .env file
# FAL_KEY=your-key
```

**Browser/Client-Side Security:**
```typescript
// NEVER expose FAL_KEY in browser code!
// Use a server-side proxy instead

// API Route (Next.js example)
// app/api/generate/route.ts
import { fal } from "@fal-ai/client";

fal.config({ credentials: process.env.FAL_KEY });

export async function POST(request: Request) {
  const { prompt } = await request.json();
  const result = await fal.subscribe("fal-ai/flux/dev", {
    input: { prompt }
  });
  return Response.json(result);
}

// Client component calls your API route, not fal directly
```

### 2. Rate Limiting (429 Errors)

**Symptoms:**
- `429 Too Many Requests`
- `Rate limit exceeded`
- Requests failing after many successful ones

**Solutions:**

```typescript
// Implement exponential backoff
async function generateWithRetry(
  prompt: string,
  maxRetries = 3
): Promise<any> {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await fal.subscribe("fal-ai/flux/dev", {
        input: { prompt }
      });
    } catch (error) {
      if (error.status === 429 && i < maxRetries - 1) {
        const delay = Math.pow(2, i) * 1000; // 1s, 2s, 4s
        console.log(`Rate limited, retrying in ${delay}ms`);
        await new Promise(r => setTimeout(r, delay));
      } else {
        throw error;
      }
    }
  }
}

// Use queue for high-volume
async function batchGenerate(prompts: string[]) {
  const results = [];
  for (const prompt of prompts) {
    results.push(await generateWithRetry(prompt));
    // Add small delay between requests
    await new Promise(r => setTimeout(r, 100));
  }
  return results;
}
```

```python
import time
import fal_client
from fal_client import FalClientError

def generate_with_retry(prompt: str, max_retries: int = 3):
    for i in range(max_retries):
        try:
            return fal_client.subscribe(
                "fal-ai/flux/dev",
                arguments={"prompt": prompt}
            )
        except FalClientError as e:
            if e.status == 429 and i < max_retries - 1:
                delay = 2 ** i
                print(f"Rate limited, retrying in {delay}s")
                time.sleep(delay)
            else:
                raise
```

### 3. Timeout Errors

**Symptoms:**
- `Request timeout`
- `Gateway timeout`
- Long-running requests failing

**Solutions:**

```typescript
// Use subscribe instead of run for long operations
// subscribe handles queue automatically

const result = await fal.subscribe("fal-ai/flux/dev", {
  input: { prompt: "test" },
  // Optional: configure polling
  pollInterval: 1000,  // Poll every second
  logs: true,
  onQueueUpdate: (update) => {
    console.log("Status:", update.status);
    if (update.status === "IN_PROGRESS") {
      console.log("Progress:", update.logs);
    }
  }
});

// For very long operations, use webhooks
const result = await fal.subscribe("fal-ai/flux/dev", {
  input: { prompt: "test" },
  webhookUrl: "https://your-server.com/webhook"
});
```

```python
# Use subscribe for long-running tasks
result = fal_client.subscribe(
    "fal-ai/flux/dev",
    arguments={"prompt": "test"},
    with_logs=True,
    on_queue_update=lambda u: print(f"Status: {u}")
)

# Or manual queue management with custom timeout handling
import asyncio

async def generate_with_timeout(prompt: str, timeout: int = 300):
    handler = await fal_client.submit_async(
        "fal-ai/flux/dev",
        arguments={"prompt": prompt}
    )

    start = time.time()
    while time.time() - start < timeout:
        status = await handler.status_async()
        if status.status == "COMPLETED":
            return await handler.get_async()
        await asyncio.sleep(1)

    raise TimeoutError("Generation timed out")
```

### 4. Validation Errors (400 Bad Request)

**Symptoms:**
- `400 Bad Request`
- `Validation error`
- `Invalid input`

**Common Causes and Fixes:**

```typescript
// Issue: Invalid image_size
// Wrong
{ image_size: "1920x1080" }
// Right
{ image_size: "landscape_16_9" }
// Or custom dimensions
{ image_size: { width: 1920, height: 1080 } }

// Issue: Invalid URL for image_url
// Wrong - local file path
{ image_url: "/path/to/image.jpg" }
// Right - upload first
const url = await fal.storage.upload(file);
{ image_url: url }

// Issue: Out of range parameters
// Wrong
{ num_inference_steps: 100 }  // Max is usually 50
// Right
{ num_inference_steps: 50 }

// Issue: Missing required parameters
// Wrong
{ image_size: "square_hd" }  // Missing prompt
// Right
{ prompt: "A beautiful landscape", image_size: "square_hd" }
```

**Validate before sending:**
```typescript
function validateFluxInput(input: any): void {
  if (!input.prompt || typeof input.prompt !== 'string') {
    throw new Error("prompt is required and must be a string");
  }
  if (input.num_inference_steps && (input.num_inference_steps < 1 || input.num_inference_steps > 50)) {
    throw new Error("num_inference_steps must be between 1 and 50");
  }
  if (input.guidance_scale && (input.guidance_scale < 1 || input.guidance_scale > 20)) {
    throw new Error("guidance_scale must be between 1 and 20");
  }
}
```

### 5. File Upload Issues

**Symptoms:**
- `Invalid image URL`
- `Failed to fetch image`
- `Unsupported file type`

**Solutions:**

```typescript
// Upload files to fal CDN before using
import { fal } from "@fal-ai/client";

// From File object (browser)
const file = document.querySelector('input[type="file"]').files[0];
const url = await fal.storage.upload(file);

// From Blob
const blob = new Blob([data], { type: "image/png" });
const file = new File([blob], "image.png", { type: "image/png" });
const url = await fal.storage.upload(file);

// From URL (fetch and re-upload)
const response = await fetch("https://example.com/image.jpg");
const blob = await response.blob();
const file = new File([blob], "image.jpg", { type: "image/jpeg" });
const url = await fal.storage.upload(file);
```

```python
import fal_client

# Upload local file
url = fal_client.upload_file("path/to/image.png")

# Upload bytes
with open("image.png", "rb") as f:
    url = fal_client.upload(f.read(), "image/png")

# For small files, use data URL
data_url = fal_client.encode_file("small_image.png")
# Use in request
result = fal_client.run(
    "fal-ai/flux/dev/image-to-image",
    arguments={"image_url": data_url, "prompt": "enhance"}
)
```

### 6. Serverless Deployment Errors

**Symptoms:**
- Deployment fails
- Container crashes
- Out of memory errors

**Diagnostic Steps:**
```bash
# Check deployment logs
fal logs <app-id>

# List deployments
fal list

# Check status
fal status <app-id>
```

**Common Fixes:**

```python
# Issue: Out of memory during model loading
# Solution: Use appropriate machine type
class MyApp(fal.App):
    machine_type = "GPU-A100"  # Upgrade from T4/A10G
    num_gpus = 1

# Issue: Missing dependencies
# Solution: List all requirements
class MyApp(fal.App):
    requirements = [
        "torch>=2.0.0",
        "transformers>=4.35.0",
        "accelerate",
        "safetensors",
        "sentencepiece",  # Often forgotten
    ]

# Issue: Slow cold starts
# Solution: Use persistent storage and keep_alive
class MyApp(fal.App):
    keep_alive = 600  # 10 minutes
    min_concurrency = 1  # Always keep one warm

    volumes = {
        "/data": fal.Volume("model-cache")
    }

    def setup(self):
        # Models cached in persistent volume
        self.model = load_model(cache_dir="/data/models")

# Issue: Request timeout
# Solution: Move heavy work to setup()
class MyApp(fal.App):
    def setup(self):
        # Load model once, not per request
        self.model = load_large_model()

    @fal.endpoint("/predict")
    def predict(self, request):
        # Fast inference only
        return self.model(request.input)
```

### 7. WebSocket/Realtime Issues

**Symptoms:**
- Connection drops
- No results received
- Throttling issues

**Solutions:**

```typescript
// Proper WebSocket handling
const connection = fal.realtime.connect("fal-ai/lcm-sd15-i2i", {
  connectionKey: "unique-key-per-user",  // Important!
  throttleInterval: 128,  // Adjust based on needs

  onResult: (result) => {
    console.log("Result:", result);
  },

  onError: (error) => {
    console.error("WebSocket error:", error);
    // Implement reconnection logic
  },

  onOpen: () => {
    console.log("Connected");
  },

  onClose: () => {
    console.log("Disconnected");
    // Implement reconnection if needed
  }
});

// Clean up on unmount
useEffect(() => {
  return () => {
    connection.close();
  };
}, []);

// Handle connection state
if (!connection.connected) {
  // Show reconnecting UI
}
```

### 8. Debugging Checklist

```markdown
## Pre-flight Checks

[ ] FAL_KEY environment variable is set
[ ] Key has correct permissions for the model
[ ] Using latest version of client library
[ ] Network connectivity to fal.ai endpoints

## Request Checks

[ ] Required parameters are provided
[ ] Parameter values are within valid ranges
[ ] Image URLs are publicly accessible
[ ] File uploads completed successfully

## Response Checks

[ ] Checking correct response field (images vs image)
[ ] Handling all possible status codes
[ ] Implementing proper error handling
[ ] Not assuming response structure

## Deployment Checks (Serverless)

[ ] All dependencies listed in requirements
[ ] Machine type has sufficient memory
[ ] setup() loads models, not request handlers
[ ] Secrets are set via fal secrets
[ ] Volume paths exist before use
```

## Getting Help

1. **Check Documentation:** https://docs.fal.ai
2. **Model Explorer:** https://fal.ai/models (see model-specific parameters)
3. **Discord Community:** https://discord.gg/fal-ai
4. **GitHub Issues:** https://github.com/fal-ai

**When reporting issues, include:**
- Full error message and stack trace
- Request payload (without API key)
- Client library version
- Language/runtime version
- Steps to reproduce
