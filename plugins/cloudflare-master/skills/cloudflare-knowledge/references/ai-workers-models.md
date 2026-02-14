# AI Workers Models Reference (2025-2026)

## Text Generation Models

### Large Language Models

| Model ID | Parameters | Context | Best For | Notes |
|----------|-----------|---------|----------|-------|
| @cf/meta/llama-3.3-70b-instruct-fp8-fast | 70B | 128K | General, reasoning | Latest Llama |
| @cf/meta/llama-3.1-70b-instruct | 70B | 128K | General purpose | Stable |
| @cf/meta/llama-3.1-8b-instruct | 8B | 128K | Fast inference | Good quality |
| @cf/mistral/mistral-7b-instruct-v0.2 | 7B | 32K | Fast, efficient | Low latency |
| @cf/qwen/qwen2.5-72b-instruct | 72B | 128K | Multilingual | Excellent Chinese |
| @cf/deepseek/deepseek-r1-distill-llama-70b | 70B | 64K | Complex reasoning | Chain-of-thought |
| @cf/google/gemma-7b-it | 7B | 8K | Lightweight | Google model |

### Usage

```typescript
interface Env {
  AI: Ai;
}

// Basic generation
const response = await env.AI.run("@cf/meta/llama-3.3-70b-instruct-fp8-fast", {
  messages: [
    { role: "system", content: "You are a helpful assistant." },
    { role: "user", content: "Explain serverless computing." },
  ],
  max_tokens: 1024,
  temperature: 0.7,
  top_p: 0.9,
});

console.log(response.response);

// Streaming
const stream = await env.AI.run("@cf/meta/llama-3.3-70b-instruct-fp8-fast", {
  messages: [
    { role: "user", content: "Write a poem about the edge." },
  ],
  stream: true,
});

return new Response(stream, {
  headers: {
    "Content-Type": "text/event-stream",
    "Cache-Control": "no-cache",
    "Connection": "keep-alive",
  },
});

// JSON mode
const structured = await env.AI.run("@cf/meta/llama-3.3-70b-instruct-fp8-fast", {
  messages: [
    { role: "system", content: "Respond with valid JSON only." },
    { role: "user", content: "List 3 programming languages with their use cases." },
  ],
  response_format: { type: "json_object" },
});
```

---

## Text-to-Speech (TTS) Models

| Model ID | Languages | Quality | Latency | Notes |
|----------|-----------|---------|---------|-------|
| @deepgram/aura-2-en | English | Excellent | Medium | Context-aware, natural |
| @deepgram/aura-1 | English | Good | Fast | Reliable |
| @cf/myshell-ai/melotts | en, fr, es, zh, ja, ko | Good | Fast | Multi-lingual |

### Usage

```typescript
// Aura-2 (Best quality English TTS)
const audio = await env.AI.run("@deepgram/aura-2-en", {
  text: "Hello! This is a demonstration of Cloudflare Workers AI text-to-speech capabilities.",
});

// Returns ArrayBuffer containing audio/wav
return new Response(audio, {
  headers: {
    "Content-Type": "audio/wav",
    "Content-Disposition": "attachment; filename='speech.wav'",
  },
});

// MeloTTS (Multi-lingual)
const frenchAudio = await env.AI.run("@cf/myshell-ai/melotts", {
  text: "Bonjour! Comment allez-vous aujourd'hui?",
  language: "fr",
});

// Supported languages: en, fr, es, zh, ja, ko
const japaneseAudio = await env.AI.run("@cf/myshell-ai/melotts", {
  text: "こんにちは、世界！",
  language: "ja",
});
```

### Real-Time TTS with WebSocket

```typescript
// For real-time voice applications
export class VoiceAgent {
  state: DurableObjectState;

  async fetch(request: Request) {
    if (request.headers.get("Upgrade") === "websocket") {
      const pair = new WebSocketPair();
      const [client, server] = Object.values(pair);
      this.state.acceptWebSocket(server);
      return new Response(null, { status: 101, webSocket: client });
    }
    return new Response("Expected WebSocket", { status: 400 });
  }

  async webSocketMessage(ws: WebSocket, message: string) {
    // Generate speech from text message
    const audio = await this.env.AI.run("@deepgram/aura-2-en", {
      text: message,
    });

    // Send audio back to client
    ws.send(audio);
  }
}
```

---

## Speech-to-Text (STT) Models

| Model ID | Languages | Speed | Quality | Notes |
|----------|-----------|-------|---------|-------|
| @cf/openai/whisper-large-v3-turbo | 100+ | Fast | Excellent | Recommended |
| @cf/openai/whisper | 100+ | Slower | Excellent | Original |

### Usage

```typescript
// Basic transcription
export default {
  async fetch(request: Request, env: Env) {
    if (request.method !== "POST") {
      return new Response("POST audio data to transcribe", { status: 405 });
    }

    const audioData = await request.arrayBuffer();

    const result = await env.AI.run("@cf/openai/whisper-large-v3-turbo", {
      audio: audioData,
    });

    return Response.json({
      text: result.text,
      segments: result.segments,  // Timestamped segments
    });
  },
};

// With language hint
const result = await env.AI.run("@cf/openai/whisper-large-v3-turbo", {
  audio: audioData,
  source_lang: "es",  // Spanish
});

// Process audio from R2
const object = await env.MY_BUCKET.get("recordings/meeting.mp3");
if (object) {
  const audioData = await object.arrayBuffer();
  const transcript = await env.AI.run("@cf/openai/whisper-large-v3-turbo", {
    audio: audioData,
  });

  // Store transcript
  await env.MY_BUCKET.put("transcripts/meeting.txt", transcript.text);
}
```

### Response Format

```typescript
interface WhisperResponse {
  text: string;  // Full transcript
  segments: Array<{
    start: number;   // Start time in seconds
    end: number;     // End time in seconds
    text: string;    // Segment text
  }>;
}
```

---

## Image Generation Models

| Model ID | Max Resolution | Steps | Notes |
|----------|---------------|-------|-------|
| @cf/black-forest-labs/flux-1-schnell | 1024x1024 | 4 | Fast, good quality |
| @cf/stabilityai/stable-diffusion-xl-base-1.0 | 1024x1024 | 20+ | Detailed |

### Usage

```typescript
// FLUX.1 Schnell (Fast)
const image = await env.AI.run("@cf/black-forest-labs/flux-1-schnell", {
  prompt: "A majestic mountain landscape at sunset, photorealistic, 8k",
  num_steps: 4,  // 1-8
});

return new Response(image, {
  headers: { "Content-Type": "image/png" },
});

// Stable Diffusion XL
const sdImage = await env.AI.run("@cf/stabilityai/stable-diffusion-xl-base-1.0", {
  prompt: "A cyberpunk cityscape with neon lights, digital art style",
  negative_prompt: "blurry, low quality, distorted",
  num_steps: 20,
  guidance: 7.5,
  width: 1024,
  height: 1024,
});

// Image-to-Image
const modifiedImage = await env.AI.run("@cf/stabilityai/stable-diffusion-xl-base-1.0", {
  prompt: "Convert to watercolor painting style",
  image: originalImageArrayBuffer,
  strength: 0.75,  // 0-1, higher = more change
});
```

---

## Vision/Captioning Models

| Model ID | Capabilities | Notes |
|----------|--------------|-------|
| @cf/meta/llama-3.2-11b-vision-instruct | Image understanding, Q&A, captioning | Recommended |
| @cf/llava-hf/llava-1.5-7b-hf | Visual Q&A | Lighter |

### Usage

```typescript
// Image captioning
const caption = await env.AI.run("@cf/meta/llama-3.2-11b-vision-instruct", {
  image: imageArrayBuffer,
  prompt: "Describe this image in detail.",
});

// Visual Q&A
const answer = await env.AI.run("@cf/meta/llama-3.2-11b-vision-instruct", {
  image: imageArrayBuffer,
  prompt: "What objects are visible in this image? List them.",
});

// Image analysis for accessibility
const altText = await env.AI.run("@cf/meta/llama-3.2-11b-vision-instruct", {
  image: imageArrayBuffer,
  prompt: "Generate a concise alt text for this image suitable for screen readers.",
});

// Multi-image comparison (with base64)
const image1 = await env.MY_BUCKET.get("img1.jpg");
const image2 = await env.MY_BUCKET.get("img2.jpg");

const comparison = await env.AI.run("@cf/meta/llama-3.2-11b-vision-instruct", {
  image: [await image1?.arrayBuffer(), await image2?.arrayBuffer()],
  prompt: "Compare these two images and describe the differences.",
});
```

---

## Embedding Models

| Model ID | Dimensions | Best For | Notes |
|----------|------------|----------|-------|
| @cf/baai/bge-large-en-v1.5 | 1024 | Best quality | Recommended |
| @cf/baai/bge-base-en-v1.5 | 768 | Balanced | Good quality |
| @cf/baai/bge-small-en-v1.5 | 384 | Fast | Lightweight |
| @cf/sentence-transformers/all-minilm-l6-v2 | 384 | General | Fast |

### Usage

```typescript
// Single text
const embedding = await env.AI.run("@cf/baai/bge-large-en-v1.5", {
  text: "Cloudflare Workers enables serverless computing at the edge.",
});
// Returns { data: [{ embedding: [0.1, 0.2, ...] }] }

// Batch embeddings
const embeddings = await env.AI.run("@cf/baai/bge-large-en-v1.5", {
  text: [
    "First document text",
    "Second document text",
    "Third document text",
  ],
});
// Returns { data: [{ embedding: [...] }, { embedding: [...] }, { embedding: [...] }] }

// Store in Vectorize
for (let i = 0; i < texts.length; i++) {
  await env.MY_VECTORS.insert({
    id: `doc-${i}`,
    values: embeddings.data[i].embedding,
    metadata: { text: texts[i] },
  });
}

// Query Vectorize
const queryEmbedding = await env.AI.run("@cf/baai/bge-large-en-v1.5", {
  text: "What is serverless?",
});

const results = await env.MY_VECTORS.query(queryEmbedding.data[0].embedding, {
  topK: 5,
  returnMetadata: true,
});
```

---

## RAG Pattern with Vectorize

```typescript
interface Env {
  AI: Ai;
  VECTORS: VectorizeIndex;
}

export default {
  async fetch(request: Request, env: Env) {
    const { query } = await request.json();

    // 1. Embed the query
    const queryEmbedding = await env.AI.run("@cf/baai/bge-large-en-v1.5", {
      text: query,
    });

    // 2. Search vector database
    const matches = await env.VECTORS.query(queryEmbedding.data[0].embedding, {
      topK: 3,
      returnMetadata: true,
    });

    // 3. Build context from matches
    const context = matches.matches
      .map((m) => m.metadata?.text)
      .join("\n\n");

    // 4. Generate response with context
    const response = await env.AI.run("@cf/meta/llama-3.3-70b-instruct-fp8-fast", {
      messages: [
        {
          role: "system",
          content: `Answer the question based on the following context:\n\n${context}`,
        },
        { role: "user", content: query },
      ],
    });

    return Response.json({
      answer: response.response,
      sources: matches.matches.map((m) => m.id),
    });
  },
};
```

---

---

## AI Workers vs Third-Party: Cost Scenarios

### When Cloudflare AI Workers SAVES Money

#### Scenario 1: High-Volume English TTS
```
Use Case: 1M characters/day English TTS for automated phone system

Cloudflare Aura-2:
  Cost: $0.030/1K chars × 1,000K = $30/day = $900/month
  Quality: Excellent, context-aware

ElevenLabs Direct (Pro Plan):
  Cost: $99/month base + overage at $0.18/1K chars
  For 30M chars/month: $99 + (30M - 500K) × $0.18/1K = ~$5,409/month

fal.ai ElevenLabs:
  Cost: $0.10/1K chars × 30,000K = $3,000/month

SAVINGS: 83-94% by using Cloudflare AI Workers
```

#### Scenario 2: Multilingual TTS (Supported Languages)
```
Use Case: 100K chars/day in French, Spanish, Chinese, Japanese, Korean

Cloudflare MeloTTS:
  Cost: ~$0.0002/min (roughly 100 mins/day) = $0.60/month

ElevenLabs Multilingual v2:
  Cost: ~$0.165/1K × 3,000K = $495/month

SAVINGS: 99.8% by using Cloudflare AI Workers
```

#### Scenario 3: LLM Inference for RAG
```
Use Case: Customer support bot, 10M tokens/month input + 2M output

Cloudflare Llama 3.3 70B:
  Cost: (10M + 2M) × $0.27/1M = $3.24/month

OpenAI GPT-4o-mini:
  Cost: 10M × $0.15/1M + 2M × $0.60/1M = $2.70/month

OpenAI GPT-4o:
  Cost: 10M × $2.50/1M + 2M × $10/1M = $45/month

Anthropic Claude 3.5 Sonnet:
  Cost: 10M × $3.00/1M + 2M × $15/1M = $60/month

NOTE: Cloudflare is 1.2x GPT-4o-mini but 14x cheaper than GPT-4o
For quality comparable to GPT-4o, Llama 3.3 70B offers massive savings.
```

#### Scenario 4: Speech-to-Text Transcription
```
Use Case: Transcribe 500 hours of audio/month

Cloudflare Whisper large-v3-turbo:
  Cost: $0.0052/min × 30,000 min = $156/month

OpenAI Whisper:
  Cost: $0.006/min × 30,000 min = $180/month

AssemblyAI:
  Cost: $0.0065/min × 30,000 min = $195/month

SAVINGS: 13-20% by using Cloudflare AI Workers
```

#### Scenario 5: Embeddings at Scale
```
Use Case: Embed 100M tokens for search index

Cloudflare BGE-large:
  Cost: ~$0.01/1M tokens × 100 = $1.00

OpenAI text-embedding-3-small:
  Cost: $0.02/1M × 100 = $2.00

OpenAI text-embedding-3-large:
  Cost: $0.13/1M × 100 = $13.00

Cohere embed-v3:
  Cost: $0.10/1M × 100 = $10.00

SAVINGS: 50-92% by using Cloudflare AI Workers
```

### When Third-Party is WORTH the Extra Cost

#### Scenario 1: Premium Voice Quality Requirements
```
Use Case: Audiobook narration, premium customer experience

Why ElevenLabs is worth it:
- Voice cloning (custom brand voice)
- Emotional expressiveness control
- 29+ languages with native quality
- Professional studio-grade output
- Voice consistency across long content

When to pay premium:
- Brand voice consistency is critical
- Content will be published/permanent
- Customer experience justifies cost
- Need voice cloning capabilities
```

#### Scenario 2: Real-Time Voice Agents
```
Use Case: Live conversational AI with <100ms latency

ElevenLabs Turbo v2.5:
- Latency: ~75ms
- Real-time streaming WebSocket
- Optimized for conversations

Cloudflare Aura-2:
- Latency: ~200-500ms (request/response)
- No native WebSocket streaming

Verdict: For real-time voice agents, ElevenLabs is necessary.
Use Cloudflare for batch processing, ElevenLabs for live.
```

#### Scenario 3: Languages Not Supported by Cloudflare
```
Use Case: TTS in Portuguese, Italian, Hindi, Arabic

Cloudflare MeloTTS supports: en, fr, es, zh, ja, ko (6 languages)
ElevenLabs supports: 32 languages

For unsupported languages, third-party is required.

Cost-Effective Path:
1. Use Cloudflare for supported languages (99.8% savings)
2. Use ElevenLabs only for unsupported languages
3. Route via AI Gateway for caching/logging
```

#### Scenario 4: Cutting-Edge Reasoning Models
```
Use Case: Complex mathematical reasoning, code generation

If you need GPT-4o/Claude-level reasoning:
- Cloudflare has DeepSeek-R1-Distill (good for CoT)
- But GPT-4o/Claude may outperform on edge cases

Cost-Performance Tradeoff:
- Cloudflare Llama 3.3 70B: $0.27/1M - 90% of tasks
- Fall back to GPT-4o: $2.50/1M - complex 10%

Hybrid Strategy: Route 90% to Cloudflare, 10% to OpenAI
Average cost: ~$0.50/1M vs $2.50/1M (80% savings)
```

### Cost Decision Matrix

| Requirement | Cloudflare AI Workers | Third-Party |
|-------------|----------------------|-------------|
| English TTS, high volume | ✅ Aura-2 (82% savings) | ❌ Overkill |
| Premium voice quality | ⚠️ Good, not premium | ✅ ElevenLabs |
| Voice cloning | ❌ Not available | ✅ ElevenLabs/F5-TTS |
| Real-time voice (<100ms) | ❌ Too slow | ✅ ElevenLabs Turbo |
| Multilingual TTS (6 langs) | ✅ MeloTTS (99% savings) | ❌ Overkill |
| TTS in Portuguese/Arabic | ❌ Not supported | ✅ ElevenLabs |
| STT transcription | ✅ Whisper (15% savings) | ⚠️ Similar price |
| LLM (most tasks) | ✅ Llama 3.3 (10-20x savings) | ❌ Overkill |
| LLM (cutting-edge) | ⚠️ May need hybrid | ✅ GPT-4o/Claude |
| Embeddings | ✅ BGE (50-90% savings) | ❌ Overkill |
| Image generation | ✅ FLUX.1 (3x savings) | ❌ DALL-E 3 costly |
| Vision/captioning | ✅ Llama 3.2 Vision | ⚠️ GPT-4V for complex |

---

## Hybrid Architecture: Best of Both Worlds

### Pattern: AI Gateway Router

Route requests to optimal provider based on requirements:

```typescript
interface Env {
  AI: Ai;
  ELEVENLABS_API_KEY: string;
  CF_ACCOUNT_ID: string;
  AI_GATEWAY_ID: string;
}

type TTSProvider = "cloudflare" | "elevenlabs";

interface TTSRequest {
  text: string;
  language?: string;
  voice_quality?: "standard" | "premium";
  voice_id?: string;  // For ElevenLabs custom voice
}

async function generateTTS(request: TTSRequest, env: Env): Promise<ArrayBuffer> {
  const provider = selectProvider(request);

  if (provider === "cloudflare") {
    return await cloudflareNativeTTS(request, env);
  } else {
    return await elevenLabsViaTGateway(request, env);
  }
}

function selectProvider(request: TTSRequest): TTSProvider {
  // Premium quality or custom voice = ElevenLabs
  if (request.voice_quality === "premium" || request.voice_id) {
    return "elevenlabs";
  }

  // Unsupported language = ElevenLabs
  const cloudflareLanguages = ["en", "fr", "es", "zh", "ja", "ko"];
  if (request.language && !cloudflareLanguages.includes(request.language)) {
    return "elevenlabs";
  }

  // Default to Cloudflare for cost savings
  return "cloudflare";
}

async function cloudflareNativeTTS(request: TTSRequest, env: Env): Promise<ArrayBuffer> {
  if (request.language === "en") {
    // Use Aura-2 for English (best quality)
    return await env.AI.run("@deepgram/aura-2-en", { text: request.text });
  } else {
    // Use MeloTTS for other supported languages
    return await env.AI.run("@cf/myshell-ai/melotts", {
      text: request.text,
      language: request.language || "en",
    });
  }
}

async function elevenLabsViaGateway(request: TTSRequest, env: Env): Promise<ArrayBuffer> {
  const voiceId = request.voice_id || "JBFqnCBsd6RMkjVDRZzb";  // Default voice
  const gatewayUrl = `https://gateway.ai.cloudflare.com/v1/${env.CF_ACCOUNT_ID}/${env.AI_GATEWAY_ID}/elevenlabs/v1/text-to-speech/${voiceId}?output_format=mp3_44100_128`;

  const response = await fetch(gatewayUrl, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "xi-api-key": env.ELEVENLABS_API_KEY,
    },
    body: JSON.stringify({
      text: request.text,
      model_id: request.voice_quality === "premium"
        ? "eleven_multilingual_v2"
        : "eleven_turbo_v2_5",
    }),
  });

  return await response.arrayBuffer();
}
```

### Pattern: Cache-First AI

Dramatically reduce AI costs with R2 caching:

```typescript
interface Env {
  AI: Ai;
  AUDIO_CACHE: R2Bucket;
}

async function getCachedTTS(text: string, env: Env): Promise<ArrayBuffer> {
  // Create deterministic cache key
  const hash = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(text)
  );
  const cacheKey = `tts/${Array.from(new Uint8Array(hash.slice(0, 8)))
    .map(b => b.toString(16).padStart(2, "0"))
    .join("")}.wav`;

  // Check R2 cache first
  const cached = await env.AUDIO_CACHE.get(cacheKey);
  if (cached) {
    console.log(`Cache HIT: ${cacheKey}`);
    return await cached.arrayBuffer();
  }

  // Generate new audio
  console.log(`Cache MISS: ${cacheKey}`);
  const audio = await env.AI.run("@deepgram/aura-2-en", { text });

  // Store in cache (fire-and-forget)
  env.AUDIO_CACHE.put(cacheKey, audio, {
    httpMetadata: { contentType: "audio/wav" },
  });

  return audio;
}

// Cost analysis:
// - First request: $0.030/1K chars (Aura-2)
// - Subsequent: $0.00000036 (R2 GET)
// - Break-even: 1 cache hit saves $0.029+
// - For 100 requests of same text: 99.7% savings
```

---

## AI Workers Neuron Pricing Deep Dive

Cloudflare charges $0.011 per 1,000 Neurons. Understanding neuron consumption helps optimize costs.

### Neuron Consumption by Model Type

| Model Category | Neurons per Unit | Cost Equivalent |
|----------------|------------------|-----------------|
| **Llama 3.3 70B** | ~24,545 per 1M tokens | $0.27/1M tokens |
| **Llama 3.1 8B** | ~4,545 per 1M tokens | $0.05/1M tokens |
| **Qwen 2.5 72B** | ~31,818 per 1M tokens | $0.35/1M tokens |
| **DeepSeek-R1-Distill** | ~12,727 per 1M tokens | $0.14/1M tokens |
| **Whisper STT** | ~472 per minute | $0.0052/min |
| **Aura-2 TTS** | ~2,727 per 1K chars | $0.030/1K chars |
| **BGE Embeddings** | ~909 per 1M tokens | $0.01/1M tokens |
| **FLUX.1 Image** | ~1,818 per image | $0.02/image |

### Free Tier Utilization

Workers AI includes **10,000 free neurons per day**.

Daily free allocation examples:
- ~400K tokens of Llama 3.1 8B inference
- ~21 minutes of Whisper transcription
- ~3,600 characters of Aura-2 TTS
- ~11M tokens of BGE embeddings

### Cost Optimization Formula

```
Monthly AI Cost =
  (Total Neurons - (10,000 × 30 days)) × $0.011 / 1000

Example: 5M neurons/month
  Free: 300,000 neurons
  Billable: 4,700,000 neurons
  Cost: 4,700 × $0.011 = $51.70/month
```

---

## Pricing Notes

AI Workers pricing varies by model (via neuron consumption):
- Text generation: $0.05-0.35 per 1M tokens (model dependent)
- TTS Aura-2: $0.030 per 1K characters
- TTS Aura-1: $0.015 per 1K characters
- TTS MeloTTS: $0.0002 per audio minute
- STT Whisper: $0.0052 per minute of audio
- Image FLUX.1: ~$0.02 per image
- Embeddings BGE: ~$0.01 per 1M tokens

Check Cloudflare dashboard for current pricing.

## Best Practices

1. **Use streaming** for long text generation responses
2. **Cache audio in R2** - one cache hit saves 99%+ cost
3. **Batch embeddings** - single request for multiple texts
4. **Use appropriate model size** - Llama 8B is 5x cheaper than 70B
5. **Set max_tokens** to limit costs and improve latency
6. **Handle errors gracefully** - AI models can fail
7. **Route to Cloudflare first** - use third-party only when necessary
8. **Use AI Gateway** for third-party - enables caching and logging
9. **Monitor neuron usage** - stay within free tier when possible
10. **Hybrid architecture** - route 90% to Cloudflare, 10% to premium
