# Next.js + Modal: Webhooks, File Uploads, Streaming LLM Responses

Complete patterns for long-running Modal jobs with webhook callbacks (async job queueing, polling vs webhook, retry/failure handling), file upload processing pipelines (presigned URLs, chunked uploads, virus scanning, image processing), and streaming LLM responses to Next.js clients (Server-Sent Events, ReadableStream, abort handling). SKILL.md keeps the basic Modal backend setup, Next.js API route integration, and the AI image generation example; this reference holds the heavier async patterns.

## Long-Running Jobs with Webhooks

For jobs exceeding Vercel's 60-second timeout, use webhooks.

### Modal Backend with Webhooks

```python
# modal_backend/jobs.py
import modal
import httpx

app = modal.App("job-processor")

image = modal.Image.debian_slim().pip_install("fastapi", "httpx", "pydantic")

@app.function(image=image, timeout=3600)  # 1 hour max
def process_long_job(job_id: str, data: dict, callback_url: str):
    """Long-running job that calls back when complete"""
    import time

    # Simulate long processing
    print(f"Processing job {job_id}...")
    time.sleep(60)  # Your actual processing here

    result = {"job_id": job_id, "status": "completed", "output": "processed data"}

    # Callback to Next.js webhook
    httpx.post(
        callback_url,
        json=result,
        headers={"X-Webhook-Secret": "your-webhook-secret"},
        timeout=30,
    )

    return result


@app.function(image=image)
@modal.asgi_app()
def api():
    from fastapi import FastAPI, BackgroundTasks
    from pydantic import BaseModel
    import uuid

    web_app = FastAPI()

    class JobRequest(BaseModel):
        data: dict
        callback_url: str

    @web_app.post("/submit-job")
    def submit_job(req: JobRequest):
        job_id = str(uuid.uuid4())

        # Spawn async job (returns immediately)
        process_long_job.spawn(job_id, req.data, req.callback_url)

        return {
            "job_id": job_id,
            "status": "processing",
            "message": "Job submitted successfully"
        }

    return web_app
```

### Next.js Webhook Handler

```typescript
// app/api/webhooks/job-complete/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma'; // Your database client

const WEBHOOK_SECRET = process.env.WEBHOOK_SECRET!;

export async function POST(req: NextRequest) {
  // Verify webhook signature
  const signature = req.headers.get('X-Webhook-Secret');
  if (signature !== WEBHOOK_SECRET) {
    return NextResponse.json({ error: 'Invalid signature' }, { status: 401 });
  }

  try {
    const body = await req.json();
    const { job_id, status, output } = body;

    // Update job in database
    await prisma.job.update({
      where: { id: job_id },
      data: {
        status,
        output,
        completedAt: new Date(),
      },
    });

    // Optional: Send notification to user
    // await sendNotification(job.userId, `Job ${job_id} completed!`);

    return NextResponse.json({ received: true });
  } catch (error) {
    console.error('Webhook error:', error);
    return NextResponse.json({ error: 'Processing failed' }, { status: 500 });
  }
}
```

### Job Submission from Next.js

```typescript
// app/api/jobs/submit/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { auth } from '@/lib/auth';

const MODAL_API_URL = process.env.MODAL_JOBS_URL!;
const APP_URL = process.env.NEXT_PUBLIC_APP_URL!;

export async function POST(req: NextRequest) {
  const session = await auth();
  if (!session?.user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  try {
    const body = await req.json();

    // Create job record
    const job = await prisma.job.create({
      data: {
        userId: session.user.id,
        status: 'pending',
        input: body,
      },
    });

    // Submit to Modal
    const response = await fetch(`${MODAL_API_URL}/submit-job`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        data: body,
        callback_url: `${APP_URL}/api/webhooks/job-complete`,
      }),
    });

    if (!response.ok) {
      throw new Error('Failed to submit job');
    }

    return NextResponse.json({
      jobId: job.id,
      status: 'processing',
    });
  } catch (error) {
    console.error('Job submission error:', error);
    return NextResponse.json({ error: 'Submission failed' }, { status: 500 });
  }
}
```

---

## File Upload Processing

### Modal Backend for File Processing

```python
# modal_backend/files.py
import modal

app = modal.App("file-processor")

image = modal.Image.debian_slim().pip_install(
    "fastapi",
    "python-multipart",
    "pillow",
)

@app.function(image=image, timeout=300)
@modal.asgi_app()
def api():
    from fastapi import FastAPI, UploadFile, File, HTTPException
    from fastapi.responses import Response
    from PIL import Image
    import io

    web_app = FastAPI()

    @web_app.post("/resize-image")
    async def resize_image(
        file: UploadFile = File(...),
        width: int = 800,
        height: int = 600,
    ):
        if not file.content_type.startswith('image/'):
            raise HTTPException(400, "File must be an image")

        contents = await file.read()

        # Process image
        img = Image.open(io.BytesIO(contents))
        img = img.resize((width, height), Image.Resampling.LANCZOS)

        # Return processed image
        buffer = io.BytesIO()
        img.save(buffer, format="PNG")

        return Response(
            content=buffer.getvalue(),
            media_type="image/png",
        )

    return web_app
```

### Next.js File Upload Handler

```typescript
// app/api/resize/route.ts
import { NextRequest, NextResponse } from 'next/server';

const MODAL_API_URL = process.env.MODAL_FILES_URL!;

export async function POST(req: NextRequest) {
  try {
    const formData = await req.formData();
    const file = formData.get('file') as File;
    const width = formData.get('width') || '800';
    const height = formData.get('height') || '600';

    if (!file) {
      return NextResponse.json({ error: 'No file provided' }, { status: 400 });
    }

    // Forward to Modal
    const modalFormData = new FormData();
    modalFormData.append('file', file);

    const response = await fetch(
      `${MODAL_API_URL}/resize-image?width=${width}&height=${height}`,
      {
        method: 'POST',
        body: modalFormData,
      }
    );

    if (!response.ok) {
      throw new Error('Processing failed');
    }

    const imageBuffer = await response.arrayBuffer();

    return new NextResponse(imageBuffer, {
      headers: { 'Content-Type': 'image/png' },
    });
  } catch (error) {
    console.error('Resize error:', error);
    return NextResponse.json({ error: 'Processing failed' }, { status: 500 });
  }
}
```

---

## Streaming LLM Responses

### Modal Backend with Streaming

```python
# modal_backend/llm.py
import modal

app = modal.App("llm-api")

image = modal.Image.debian_slim().pip_install(
    "fastapi",
    "transformers",
    "torch",
    "accelerate",
    "sse-starlette",
)

@app.cls(image=image, gpu="A100", min_containers=1)
class LLMServer:
    @modal.enter()
    def setup(self):
        from transformers import AutoTokenizer, AutoModelForCausalLM
        import torch

        self.tokenizer = AutoTokenizer.from_pretrained("meta-llama/Llama-2-7b-chat-hf")
        self.model = AutoModelForCausalLM.from_pretrained(
            "meta-llama/Llama-2-7b-chat-hf",
            torch_dtype=torch.float16,
        ).to("cuda")

    @modal.method()
    def generate_stream(self, prompt: str, max_tokens: int = 512):
        """Generator that yields tokens one at a time"""
        from transformers import TextIteratorStreamer
        from threading import Thread

        inputs = self.tokenizer(prompt, return_tensors="pt").to("cuda")

        streamer = TextIteratorStreamer(self.tokenizer, skip_special_tokens=True)

        generation_kwargs = dict(
            **inputs,
            max_new_tokens=max_tokens,
            streamer=streamer,
        )

        thread = Thread(target=self.model.generate, kwargs=generation_kwargs)
        thread.start()

        for token in streamer:
            yield token

        thread.join()


@app.function(image=image)
@modal.asgi_app()
def api():
    from fastapi import FastAPI
    from sse_starlette.sse import EventSourceResponse
    from pydantic import BaseModel

    web_app = FastAPI()

    class GenerateRequest(BaseModel):
        prompt: str
        max_tokens: int = 512

    @web_app.post("/generate-stream")
    async def generate_stream_endpoint(req: GenerateRequest):
        llm = LLMServer()

        async def event_generator():
            for token in llm.generate_stream.remote_gen(req.prompt, req.max_tokens):
                yield {"data": token}

        return EventSourceResponse(event_generator())

    return web_app
```

### Next.js Streaming Handler

```typescript
// app/api/chat/route.ts
import { NextRequest } from 'next/server';

const MODAL_API_URL = process.env.MODAL_LLM_URL!;

export async function POST(req: NextRequest) {
  const { prompt } = await req.json();

  const response = await fetch(`${MODAL_API_URL}/generate-stream`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ prompt }),
  });

  // Stream the response directly to client
  return new Response(response.body, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
    },
  });
}
```

### React Component with Streaming

```tsx
// components/Chat.tsx
'use client';

import { useState } from 'react';

export default function Chat() {
  const [prompt, setPrompt] = useState('');
  const [response, setResponse] = useState('');
  const [loading, setLoading] = useState(false);

  const sendMessage = async () => {
    setLoading(true);
    setResponse('');

    const res = await fetch('/api/chat', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ prompt }),
    });

    const reader = res.body?.getReader();
    const decoder = new TextDecoder();

    while (reader) {
      const { done, value } = await reader.read();
      if (done) break;

      const chunk = decoder.decode(value);
      // Parse SSE format
      const lines = chunk.split('\n');
      for (const line of lines) {
        if (line.startsWith('data: ')) {
          const token = line.slice(6);
          setResponse(prev => prev + token);
        }
      }
    }

    setLoading(false);
  };

  return (
    <div className="max-w-2xl mx-auto p-6">
      <textarea
        className="w-full p-4 border rounded-lg mb-4"
        value={prompt}
        onChange={(e) => setPrompt(e.target.value)}
        placeholder="Ask something..."
      />

      <button
        className="bg-blue-600 text-white py-2 px-6 rounded-lg"
        onClick={sendMessage}
        disabled={loading}
      >
        {loading ? 'Generating...' : 'Send'}
      </button>

      {response && (
        <div className="mt-6 p-4 bg-gray-100 rounded-lg whitespace-pre-wrap">
          {response}
        </div>
      )}
    </div>
  );
}
```

---

