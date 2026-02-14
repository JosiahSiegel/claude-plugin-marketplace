---
name: cloudflare-ai
description: Generate code for Cloudflare Workers AI tasks (TTS, STT, image, LLM)
arguments:
  - name: task
    description: "AI task type: tts, stt, image, chat, vision, embedding, rag"
    required: true
  - name: model
    description: "Specific model to use (optional, uses best default)"
    required: false
---

# Generate Cloudflare Workers AI Code

Generate production-ready code for various AI tasks using Workers AI.

## Instructions

1. **Parse task type**:
   - `tts` - Text-to-Speech
   - `stt` - Speech-to-Text
   - `image` - Image generation
   - `chat` - LLM chat/completion
   - `vision` - Image understanding
   - `embedding` - Text embeddings
   - `rag` - RAG with Vectorize

2. **Select appropriate model** (if not specified)

3. **Generate complete Worker code** with:
   - Type definitions
   - Request handling
   - Error handling
   - Response formatting

## Task Templates

### TTS (Text-to-Speech)

**Default model**: `@deepgram/aura-2-en`

```typescript
interface Env {
  AI: Ai;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method !== "POST") {
      return new Response("POST text to convert to speech", { status: 405 });
    }

    try {
      const { text, language } = await request.json();

      if (!text) {
        return Response.json({ error: "text is required" }, { status: 400 });
      }

      // Aura-2 for English (best quality)
      // MeloTTS for multilingual (en, fr, es, zh, ja, ko)
      const model = language && language !== "en"
        ? "@cf/myshell-ai/melotts"
        : "@deepgram/aura-2-en";

      const audio = await env.AI.run(model, {
        text,
        ...(language && language !== "en" ? { language } : {}),
      });

      return new Response(audio, {
        headers: {
          "Content-Type": "audio/wav",
          "Content-Disposition": `attachment; filename="speech.wav"`,
        },
      });
    } catch (error) {
      return Response.json(
        { error: error.message },
        { status: 500 }
      );
    }
  },
};
```

### STT (Speech-to-Text)

**Default model**: `@cf/openai/whisper-large-v3-turbo`

```typescript
interface Env {
  AI: Ai;
}

interface TranscriptSegment {
  start: number;
  end: number;
  text: string;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method !== "POST") {
      return new Response("POST audio data to transcribe", { status: 405 });
    }

    try {
      const contentType = request.headers.get("Content-Type") || "";

      let audioData: ArrayBuffer;
      let sourceLanguage: string | undefined;

      if (contentType.includes("multipart/form-data")) {
        const formData = await request.formData();
        const file = formData.get("audio") as File;
        sourceLanguage = formData.get("language") as string | undefined;

        if (!file) {
          return Response.json({ error: "audio file required" }, { status: 400 });
        }
        audioData = await file.arrayBuffer();
      } else {
        audioData = await request.arrayBuffer();
      }

      const result = await env.AI.run("@cf/openai/whisper-large-v3-turbo", {
        audio: audioData,
        ...(sourceLanguage ? { source_lang: sourceLanguage } : {}),
      });

      return Response.json({
        text: result.text,
        segments: result.segments as TranscriptSegment[],
      });
    } catch (error) {
      return Response.json(
        { error: error.message },
        { status: 500 }
      );
    }
  },
};
```

### Image Generation

**Default model**: `@cf/black-forest-labs/flux-1-schnell`

```typescript
interface Env {
  AI: Ai;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method !== "POST") {
      return new Response("POST prompt to generate image", { status: 405 });
    }

    try {
      const { prompt, steps = 4 } = await request.json();

      if (!prompt) {
        return Response.json({ error: "prompt is required" }, { status: 400 });
      }

      const image = await env.AI.run("@cf/black-forest-labs/flux-1-schnell", {
        prompt,
        num_steps: Math.min(Math.max(steps, 1), 8), // 1-8 steps
      });

      return new Response(image, {
        headers: {
          "Content-Type": "image/png",
          "Cache-Control": "public, max-age=3600",
        },
      });
    } catch (error) {
      return Response.json(
        { error: error.message },
        { status: 500 }
      );
    }
  },
};
```

### Chat/LLM

**Default model**: `@cf/meta/llama-3.3-70b-instruct-fp8-fast`

```typescript
interface Env {
  AI: Ai;
}

interface Message {
  role: "system" | "user" | "assistant";
  content: string;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method !== "POST") {
      return new Response("POST messages for chat", { status: 405 });
    }

    try {
      const { messages, stream = false, max_tokens = 1024 } = await request.json();

      if (!messages || !Array.isArray(messages)) {
        return Response.json({ error: "messages array required" }, { status: 400 });
      }

      const response = await env.AI.run("@cf/meta/llama-3.3-70b-instruct-fp8-fast", {
        messages: messages as Message[],
        max_tokens,
        temperature: 0.7,
        stream,
      });

      if (stream) {
        return new Response(response as ReadableStream, {
          headers: {
            "Content-Type": "text/event-stream",
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
          },
        });
      }

      return Response.json({
        response: response.response,
      });
    } catch (error) {
      return Response.json(
        { error: error.message },
        { status: 500 }
      );
    }
  },
};
```

### Vision/Image Understanding

**Default model**: `@cf/meta/llama-3.2-11b-vision-instruct`

```typescript
interface Env {
  AI: Ai;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method !== "POST") {
      return new Response("POST image for analysis", { status: 405 });
    }

    try {
      const contentType = request.headers.get("Content-Type") || "";

      let imageData: ArrayBuffer;
      let prompt = "Describe this image in detail.";

      if (contentType.includes("multipart/form-data")) {
        const formData = await request.formData();
        const file = formData.get("image") as File;
        prompt = (formData.get("prompt") as string) || prompt;

        if (!file) {
          return Response.json({ error: "image file required" }, { status: 400 });
        }
        imageData = await file.arrayBuffer();
      } else if (contentType.includes("application/json")) {
        const { image_url, prompt: jsonPrompt } = await request.json();
        prompt = jsonPrompt || prompt;

        if (!image_url) {
          return Response.json({ error: "image_url required" }, { status: 400 });
        }

        const imageResponse = await fetch(image_url);
        imageData = await imageResponse.arrayBuffer();
      } else {
        imageData = await request.arrayBuffer();
      }

      const result = await env.AI.run("@cf/meta/llama-3.2-11b-vision-instruct", {
        image: imageData,
        prompt,
      });

      return Response.json({
        description: result.response,
      });
    } catch (error) {
      return Response.json(
        { error: error.message },
        { status: 500 }
      );
    }
  },
};
```

### Embeddings

**Default model**: `@cf/baai/bge-large-en-v1.5`

```typescript
interface Env {
  AI: Ai;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method !== "POST") {
      return new Response("POST text to generate embeddings", { status: 405 });
    }

    try {
      const { text } = await request.json();

      if (!text) {
        return Response.json({ error: "text is required" }, { status: 400 });
      }

      // Accepts string or array of strings
      const result = await env.AI.run("@cf/baai/bge-large-en-v1.5", {
        text: Array.isArray(text) ? text : [text],
      });

      return Response.json({
        embeddings: result.data.map((d: { embedding: number[] }) => d.embedding),
        dimensions: result.data[0]?.embedding.length || 1024,
      });
    } catch (error) {
      return Response.json(
        { error: error.message },
        { status: 500 }
      );
    }
  },
};
```

### RAG with Vectorize

```typescript
interface Env {
  AI: Ai;
  VECTORS: VectorizeIndex;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    // Index documents
    if (url.pathname === "/index" && request.method === "POST") {
      const { documents } = await request.json();

      for (const doc of documents) {
        // Generate embedding
        const embedding = await env.AI.run("@cf/baai/bge-large-en-v1.5", {
          text: doc.content,
        });

        // Store in Vectorize
        await env.VECTORS.insert({
          id: doc.id,
          values: embedding.data[0].embedding,
          metadata: {
            content: doc.content,
            title: doc.title,
          },
        });
      }

      return Response.json({ indexed: documents.length });
    }

    // Query with RAG
    if (url.pathname === "/query" && request.method === "POST") {
      const { question } = await request.json();

      // 1. Embed the question
      const queryEmbedding = await env.AI.run("@cf/baai/bge-large-en-v1.5", {
        text: question,
      });

      // 2. Search vector database
      const matches = await env.VECTORS.query(
        queryEmbedding.data[0].embedding,
        { topK: 3, returnMetadata: true }
      );

      // 3. Build context from matches
      const context = matches.matches
        .map((m) => m.metadata?.content)
        .filter(Boolean)
        .join("\n\n");

      // 4. Generate answer with context
      const response = await env.AI.run(
        "@cf/meta/llama-3.3-70b-instruct-fp8-fast",
        {
          messages: [
            {
              role: "system",
              content: `Answer based on this context:\n\n${context}\n\nIf the answer isn't in the context, say so.`,
            },
            { role: "user", content: question },
          ],
        }
      );

      return Response.json({
        answer: response.response,
        sources: matches.matches.map((m) => ({
          id: m.id,
          score: m.score,
          title: m.metadata?.title,
        })),
      });
    }

    return new Response("POST to /index or /query", { status: 404 });
  },
};
```

## wrangler.jsonc for AI Tasks

```jsonc
{
  "$schema": "./node_modules/wrangler/config-schema.json",
  "name": "ai-worker",
  "main": "src/index.ts",
  "compatibility_date": "2024-01-01",
  "compatibility_flags": ["nodejs_compat"],

  "ai": {
    "binding": "AI"
  },

  // For RAG
  "vectorize": [
    {
      "binding": "VECTORS",
      "index_name": "my-index"
    }
  ]
}
```

## Model Selection Guide

| Task | Best Quality | Best Speed | Notes |
|------|--------------|------------|-------|
| TTS (English) | @deepgram/aura-2-en | @deepgram/aura-1 | Aura-2 is context-aware |
| TTS (Multilingual) | @cf/myshell-ai/melotts | - | en, fr, es, zh, ja, ko |
| STT | @cf/openai/whisper-large-v3-turbo | - | 100+ languages |
| Image Gen | @cf/stabilityai/stable-diffusion-xl-base-1.0 | @cf/black-forest-labs/flux-1-schnell | FLUX is 4 steps |
| LLM | @cf/meta/llama-3.3-70b-instruct-fp8-fast | @cf/meta/llama-3.1-8b-instruct | 70B for complex |
| Vision | @cf/meta/llama-3.2-11b-vision-instruct | - | Q&A, captioning |
| Embeddings | @cf/baai/bge-large-en-v1.5 | @cf/baai/bge-small-en-v1.5 | 1024 vs 384 dims |
