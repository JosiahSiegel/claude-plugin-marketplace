---
name: nextjs-modal-integration
description: |
  Modal.com integration patterns for Next.js applications.
  PROACTIVELY activate for: (1) Next.js + Modal backend setup, (2) AI inference from Next.js (LLMs, image generation), (3) Video/audio processing backends, (4) Heavy compute offloading from Vercel, (5) GPU workloads for Next.js apps, (6) Webhook integration between Next.js and Modal, (7) File upload processing, (8) Background job processing, (9) Serverless AI API endpoints, (10) Next.js + Modal authentication patterns.
  Provides: Architecture patterns, API route integration, webhook handling, file upload workflows, CORS configuration, warm container patterns, streaming responses, and production-ready examples.
---

## Quick Reference

| Pattern | Use Case | Cold Start |
|---------|----------|------------|
| API Route → Modal | Simple request/response | ~500ms |
| API Route → Modal (warm) | Production APIs | <100ms |
| Webhook + Spawn | Long-running jobs | N/A (async) |
| Streaming Response | LLM text generation | ~500ms first token |

## When to Use This Skill

Use for **Next.js + Modal integration**:
- AI inference that's too heavy for Edge/Vercel Functions
- Video/audio processing with FFmpeg
- Background jobs exceeding Vercel's 60s timeout
- GPU workloads (image generation, LLMs, embeddings)
- Cost-effective scaling for burst compute

**Architecture principle**: Next.js handles UI/auth/routing, Modal handles heavy compute.

---

# Next.js + Modal.com Integration (2025)

## Architecture Overview

```text
┌─────────────────────────────────────────────────────────────┐
│                    Next.js (Vercel)                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │   Pages/    │  │    API      │  │    Server           │ │
│  │   App       │  │   Routes    │  │    Actions          │ │
│  │   Router    │  │             │  │                     │ │
│  └──────┬──────┘  └──────┬──────┘  └──────────┬──────────┘ │
└─────────┼────────────────┼───────────────────┼─────────────┘
          │                │                   │
          └────────────────┼───────────────────┘
                           │ HTTPS
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                    Modal.com                                │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │   FastAPI   │  │    GPU      │  │    Background       │ │
│  │   Endpoint  │  │   Functions │  │    Jobs             │ │
│  │             │  │   (A100)    │  │    (.spawn())       │ │
│  └─────────────┘  └─────────────┘  └─────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Modal Backend Setup

### Basic FastAPI Endpoint

```python
# modal_backend/app.py
import modal
from datetime import datetime

app = modal.App("nextjs-backend")

image = (
    modal.Image.debian_slim(python_version="3.11")
    .pip_install("fastapi", "pydantic")
)

@app.function(image=image)
@modal.concurrent(max_inputs=100, target_inputs=50)
@modal.asgi_app()
def api():
    """FastAPI endpoint for Next.js frontend"""
    from fastapi import FastAPI, HTTPException, Depends
    from fastapi.middleware.cors import CORSMiddleware
    from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
    from pydantic import BaseModel, Field

    web_app = FastAPI(title="Next.js Backend API")

    # CORS configuration for Next.js
    web_app.add_middleware(
        CORSMiddleware,
        allow_origins=[
            "http://localhost:3000",           # Next.js dev
            "https://*.vercel.app",            # Vercel preview
            "https://yourdomain.com",          # Production
        ],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Simple API key auth
    security = HTTPBearer()
    API_KEY = "your-secret-key"  # Use modal.Secret in production

    def verify_token(creds: HTTPAuthorizationCredentials = Depends(security)):
        if creds.credentials != API_KEY:
            raise HTTPException(status_code=401, detail="Invalid API key")
        return creds.credentials

    # === Endpoints ===

    class ProcessRequest(BaseModel):
        data: str = Field(..., min_length=1)
        options: dict = {}

    class ProcessResponse(BaseModel):
        result: str
        processed_at: str

    @web_app.post("/process", response_model=ProcessResponse)
    def process_endpoint(
        req: ProcessRequest,
        token: str = Depends(verify_token)
    ):
        # Your processing logic here
        result = f"Processed: {req.data}"

        return ProcessResponse(
            result=result,
            processed_at=datetime.utcnow().isoformat()
        )

    @web_app.get("/health")
    def health():
        return {"status": "healthy", "timestamp": datetime.utcnow().isoformat()}

    return web_app
```

Deploy with:
```bash
modal deploy modal_backend/app.py
# Returns: https://your-workspace--nextjs-backend-api.modal.run
```

---

## Next.js API Route Integration

### Basic API Route (App Router)

```typescript
// app/api/process/route.ts
import { NextRequest, NextResponse } from 'next/server';

const MODAL_API_URL = process.env.MODAL_API_URL!;
const MODAL_API_KEY = process.env.MODAL_API_KEY!;

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();

    const response = await fetch(`${MODAL_API_URL}/process`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${MODAL_API_KEY}`,
      },
      body: JSON.stringify({
        data: body.data,
        options: body.options || {},
      }),
    });

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`Modal API error: ${response.status} - ${error}`);
    }

    const result = await response.json();
    return NextResponse.json(result);

  } catch (error) {
    console.error('Processing error:', error);
    return NextResponse.json(
      { error: 'Processing failed' },
      { status: 500 }
    );
  }
}
```

### Environment Variables

```env
# .env.local
MODAL_API_URL=https://your-workspace--nextjs-backend-api.modal.run
MODAL_API_KEY=your-secret-key
```

---

## AI Image Generation Example

### Modal Backend

```python
# modal_backend/image_gen.py
import modal

app = modal.App("image-generator")

image = (
    modal.Image.debian_slim(python_version="3.11")
    .pip_install(
        "fastapi",
        "torch",
        "diffusers",
        "transformers",
        "accelerate",
        "pydantic",
    )
)

models_volume = modal.Volume.from_name("sd-models", create_if_missing=True)

@app.cls(
    image=image,
    gpu="A100-40GB",
    volumes={"/models": models_volume},
    min_containers=1,  # Keep warm for fast response
    max_containers=5,
    container_idle_timeout=300,
)
class ImageGenerator:
    @modal.enter()
    def setup(self):
        import torch
        from diffusers import StableDiffusionXLPipeline

        print("Loading SDXL model...")
        self.pipe = StableDiffusionXLPipeline.from_pretrained(
            "stabilityai/stable-diffusion-xl-base-1.0",
            torch_dtype=torch.float16,
            cache_dir="/models",
        )
        self.pipe.to("cuda")
        print("Model ready!")

    @modal.method()
    def generate(
        self,
        prompt: str,
        negative_prompt: str = "",
        width: int = 1024,
        height: int = 1024,
        steps: int = 30,
    ) -> bytes:
        """Generate image and return as PNG bytes"""
        import io

        image = self.pipe(
            prompt=prompt,
            negative_prompt=negative_prompt,
            width=width,
            height=height,
            num_inference_steps=steps,
        ).images[0]

        buffer = io.BytesIO()
        image.save(buffer, format="PNG")
        return buffer.getvalue()


@app.function(image=image)
@modal.concurrent(max_inputs=50)
@modal.asgi_app()
def api():
    from fastapi import FastAPI, HTTPException
    from fastapi.middleware.cors import CORSMiddleware
    from fastapi.responses import Response
    from pydantic import BaseModel, Field

    web_app = FastAPI()

    web_app.add_middleware(
        CORSMiddleware,
        allow_origins=["http://localhost:3000", "https://*.vercel.app"],
        allow_methods=["*"],
        allow_headers=["*"],
    )

    class GenerateRequest(BaseModel):
        prompt: str = Field(..., min_length=1, max_length=1000)
        negative_prompt: str = ""
        width: int = Field(1024, ge=512, le=2048)
        height: int = Field(1024, ge=512, le=2048)
        steps: int = Field(30, ge=20, le=50)

    @web_app.post("/generate")
    def generate_endpoint(req: GenerateRequest):
        generator = ImageGenerator()

        try:
            image_bytes = generator.generate.remote(
                prompt=req.prompt,
                negative_prompt=req.negative_prompt,
                width=req.width,
                height=req.height,
                steps=req.steps,
            )
            return Response(content=image_bytes, media_type="image/png")
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))

    return web_app
```

### Next.js API Route

```typescript
// app/api/generate-image/route.ts
import { NextRequest, NextResponse } from 'next/server';

const MODAL_API_URL = process.env.MODAL_IMAGE_GEN_URL!;

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();

    const response = await fetch(`${MODAL_API_URL}/generate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        prompt: body.prompt,
        negative_prompt: body.negativePrompt || '',
        width: body.width || 1024,
        height: body.height || 1024,
        steps: body.steps || 30,
      }),
    });

    if (!response.ok) {
      throw new Error(`Generation failed: ${response.statusText}`);
    }

    const imageBuffer = await response.arrayBuffer();

    return new NextResponse(imageBuffer, {
      headers: {
        'Content-Type': 'image/png',
        'Cache-Control': 'public, max-age=31536000, immutable',
      },
    });
  } catch (error) {
    console.error('Image generation error:', error);
    return NextResponse.json({ error: 'Generation failed' }, { status: 500 });
  }
}
```

### React Component

```tsx
// components/ImageGenerator.tsx
'use client';

import { useState } from 'react';

export default function ImageGenerator() {
  const [prompt, setPrompt] = useState('');
  const [imageUrl, setImageUrl] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const generateImage = async () => {
    setLoading(true);
    setError('');

    try {
      const response = await fetch('/api/generate-image', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ prompt }),
      });

      if (!response.ok) {
        throw new Error('Generation failed');
      }

      const blob = await response.blob();
      const url = URL.createObjectURL(blob);
      setImageUrl(url);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unknown error');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="max-w-2xl mx-auto p-6">
      <h1 className="text-3xl font-bold mb-6">AI Image Generator</h1>

      <textarea
        className="w-full p-4 border rounded-lg mb-4 min-h-[100px]"
        placeholder="Describe the image you want to generate..."
        value={prompt}
        onChange={(e) => setPrompt(e.target.value)}
      />

      <button
        className="w-full bg-blue-600 text-white py-3 px-6 rounded-lg font-medium
                   disabled:opacity-50 disabled:cursor-not-allowed
                   hover:bg-blue-700 transition-colors"
        onClick={generateImage}
        disabled={loading || !prompt.trim()}
      >
        {loading ? 'Generating...' : 'Generate Image'}
      </button>

      {error && (
        <div className="mt-4 p-4 bg-red-100 text-red-700 rounded-lg">
          {error}
        </div>
      )}

      {imageUrl && (
        <div className="mt-6">
          <img
            src={imageUrl}
            alt="Generated image"
            className="w-full rounded-lg shadow-lg"
          />
        </div>
      )}
    </div>
  );
}
```

---

## Webhooks, File Uploads & Streaming LLM Responses

Complete patterns for long-running Modal jobs with webhook callbacks (async job queueing, polling vs webhook, retry / failure handling), file upload processing pipelines (presigned URLs, chunked uploads, virus scanning, image processing), and streaming LLM responses to Next.js clients (Server-Sent Events, ReadableStream, abort handling) live in `references/webhooks-uploads-streaming.md`. Load that reference when wiring async jobs, file pipelines, or LLM streaming endpoints between Next.js and Modal.

---

## Best Practices

### 1. Keep Modal API Keys Server-Side

```typescript
// GOOD: API key in server-side API route
// app/api/process/route.ts
const MODAL_API_KEY = process.env.MODAL_API_KEY; // Server only

// BAD: Exposing API key to client
// NEXT_PUBLIC_MODAL_API_KEY=... // Never do this!
```

### 2. Use Warm Containers for Production

```python
@app.cls(
    min_containers=1,           # Always keep 1 warm
    max_containers=10,          # Scale up to 10
    container_idle_timeout=300, # Keep warm for 5 min after use
)
class MyService:
    pass
```

### 3. Handle Vercel Timeouts

```typescript
// Vercel timeout limits:
// - Hobby: 60 seconds
// - Pro: 300 seconds
// - Enterprise: 900 seconds

// For longer jobs, use webhooks instead of waiting
```

### 4. Implement Request Timeouts

```typescript
const controller = new AbortController();
const timeoutId = setTimeout(() => controller.abort(), 55000); // 55s

try {
  const response = await fetch(url, { signal: controller.signal });
} finally {
  clearTimeout(timeoutId);
}
```

### 5. Cache Modal Responses

```typescript
// Next.js 15 cache pattern
import { unstable_cache } from 'next/cache';

const getCachedResult = unstable_cache(
  async (id: string) => {
    const response = await fetch(`${MODAL_API_URL}/process/${id}`);
    return response.json();
  },
  ['modal-result'],
  { revalidate: 3600 } // Cache for 1 hour
);
```

---

## Common Pitfalls

### 1. CORS Errors

```python
# Make sure CORS allows your Next.js domains
web_app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "https://*.vercel.app",  # All Vercel preview URLs
        "https://yourdomain.com",
    ],
    allow_methods=["*"],
    allow_headers=["*"],
)
```

### 2. Cold Start Latency

```python
# Use min_containers=1 for production APIs
@app.function(min_containers=1)  # ~$1-2/day idle cost
def api():
    pass
```

### 3. Large Payloads

```typescript
// For large files, upload directly to Modal or use signed URLs
// Don't pass >4MB through Next.js API routes

// Better: Use Modal's CloudBucketMount
```

### 4. Error Handling

```typescript
// Always handle Modal errors gracefully
try {
  const response = await fetch(MODAL_API_URL);
  if (!response.ok) {
    // Log for debugging
    console.error(`Modal error: ${response.status}`, await response.text());
    // Return user-friendly error
    return NextResponse.json(
      { error: 'Service temporarily unavailable' },
      { status: 503 }
    );
  }
} catch (error) {
  // Handle network errors
  console.error('Network error:', error);
  return NextResponse.json(
    { error: 'Could not connect to service' },
    { status: 503 }
  );
}
```

---

## Deployment Checklist

1. **Deploy Modal backend first**
   ```bash
   modal deploy modal_backend/app.py
   ```

2. **Set environment variables in Vercel**
   ```text
   MODAL_API_URL=https://your-workspace--app-api.modal.run
   MODAL_API_KEY=your-secret-key
   WEBHOOK_SECRET=your-webhook-secret
   ```

3. **Update CORS for production domain**

4. **Enable warm containers for production**
   ```python
   @app.function(min_containers=1)
   ```

5. **Monitor costs**
   ```bash
   modal app stats your-app-name
   ```

---

## Related Skills

- `nextjs-server-actions` - Server Actions patterns
- `nextjs-caching` - Caching strategies
- `nextjs-deployment` - Deployment configurations
