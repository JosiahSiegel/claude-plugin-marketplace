# Third-Party AI Service Integrations with Cloudflare Workers

## Overview

Cloudflare Workers can integrate with external AI services like ElevenLabs, OpenAI, Anthropic, and fal.ai. This guide covers integration patterns, cost comparisons, and gotchas.

---

## ElevenLabs TTS Integration

### Method 1: Direct API Integration

Call ElevenLabs API directly from Workers:

```typescript
interface Env {
  ELEVENLABS_API_KEY: string;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const { text, voice_id = "JBFqnCBsd6RMkjVDRZzb" } = await request.json();

    const response = await fetch(
      `https://api.elevenlabs.io/v1/text-to-speech/${voice_id}?output_format=mp3_44100_128`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "xi-api-key": env.ELEVENLABS_API_KEY,
        },
        body: JSON.stringify({
          text,
          model_id: "eleven_multilingual_v2",
          voice_settings: {
            stability: 0.5,
            similarity_boost: 0.75,
          },
        }),
      }
    );

    if (!response.ok) {
      return Response.json(
        { error: await response.text() },
        { status: response.status }
      );
    }

    return new Response(response.body, {
      headers: {
        "Content-Type": "audio/mpeg",
        "Content-Disposition": "attachment; filename=speech.mp3",
      },
    });
  },
};
```

### Method 2: Via Cloudflare AI Gateway

Route ElevenLabs requests through AI Gateway for caching, logging, and rate limiting:

```typescript
interface Env {
  ELEVENLABS_API_KEY: string;
  CF_ACCOUNT_ID: string;
  AI_GATEWAY_ID: string;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const { text, voice_id = "JBFqnCBsd6RMkjVDRZzb" } = await request.json();

    // Route through AI Gateway
    const gatewayUrl = `https://gateway.ai.cloudflare.com/v1/${env.CF_ACCOUNT_ID}/${env.AI_GATEWAY_ID}/elevenlabs/v1/text-to-speech/${voice_id}?output_format=mp3_44100_128`;

    const response = await fetch(gatewayUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "xi-api-key": env.ELEVENLABS_API_KEY,
      },
      body: JSON.stringify({
        text,
        model_id: "eleven_multilingual_v2",
      }),
    });

    return new Response(response.body, {
      headers: { "Content-Type": "audio/mpeg" },
    });
  },
};
```

**AI Gateway Benefits:**
- Request logging and analytics
- Response caching (reduce API costs)
- Rate limiting
- Fallback to alternative providers
- Unified billing dashboard

### Method 3: ElevenLabs WebSocket Streaming

For real-time TTS with Durable Objects:

```typescript
import { DurableObject } from "cloudflare:workers";

interface Env {
  ELEVENLABS_API_KEY: string;
  TTS_SESSION: DurableObjectNamespace;
}

export class TTSSession extends DurableObject {
  private elevenLabsWs: WebSocket | null = null;

  async fetch(request: Request): Promise<Response> {
    if (request.headers.get("Upgrade") === "websocket") {
      const pair = new WebSocketPair();
      const [client, server] = Object.values(pair);

      this.ctx.acceptWebSocket(server);
      await this.connectToElevenLabs();

      return new Response(null, { status: 101, webSocket: client });
    }
    return new Response("Expected WebSocket", { status: 400 });
  }

  private async connectToElevenLabs() {
    const voiceId = "JBFqnCBsd6RMkjVDRZzb";
    const modelId = "eleven_turbo_v2_5";

    // ElevenLabs WebSocket endpoint
    const wsUrl = `wss://api.elevenlabs.io/v1/text-to-speech/${voiceId}/stream-input?model_id=${modelId}&inactivity_timeout=60`;

    this.elevenLabsWs = new WebSocket(wsUrl, {
      headers: {
        "xi-api-key": this.env.ELEVENLABS_API_KEY,
      },
    });

    this.elevenLabsWs.addEventListener("message", (event) => {
      // Forward audio chunks to connected clients
      for (const ws of this.ctx.getWebSockets()) {
        ws.send(event.data);
      }
    });
  }

  async webSocketMessage(ws: WebSocket, message: string) {
    // Forward text to ElevenLabs
    if (this.elevenLabsWs?.readyState === WebSocket.OPEN) {
      this.elevenLabsWs.send(
        JSON.stringify({
          text: message,
          try_trigger_generation: true,
        })
      );
    }
  }

  async webSocketClose() {
    // Send EOS to ElevenLabs
    if (this.elevenLabsWs?.readyState === WebSocket.OPEN) {
      this.elevenLabsWs.send(JSON.stringify({ text: "" })); // EOS signal
      this.elevenLabsWs.close();
    }
  }
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const id = env.TTS_SESSION.idFromName("session");
    const stub = env.TTS_SESSION.get(id);
    return stub.fetch(request);
  },
};
```

### Method 4: Cloudflare Realtime Agents SDK

For voice agents with ElevenLabs:

```typescript
import {
  DeepgramSTT,
  ElevenLabsTTS,
  RealtimeAgent,
} from "@cloudflare/realtime-agents";

export class VoiceAgent extends RealtimeAgent {
  async onStart() {
    // Pipeline: Audio -> STT -> LLM -> TTS -> Audio
    await this.initPipeline([
      this.transport,
      new DeepgramSTT(this.env.DEEPGRAM_API_KEY),
      this.textHandler.bind(this),
      new ElevenLabsTTS(this.env.ELEVENLABS_API_KEY, {
        voice_id: "JBFqnCBsd6RMkjVDRZzb",
        model_id: "eleven_turbo_v2_5",
      }),
      this.transport,
    ]);
  }

  async textHandler(text: string): Promise<string> {
    // Process with LLM
    const response = await this.env.AI.run(
      "@cf/meta/llama-3.3-70b-instruct-fp8-fast",
      {
        messages: [
          { role: "system", content: "You are a helpful assistant." },
          { role: "user", content: text },
        ],
      }
    );
    return response.response;
  }
}
```

---

## ElevenLabs + Cloudflare Workers AI LLM

Connect ElevenLabs Conversational AI agents to Cloudflare Workers AI as the LLM:

### Configure in ElevenLabs Dashboard

1. Add Cloudflare API token as secret in AI Agent settings
2. Select "Custom LLM" from dropdown
3. Server URL: `https://api.cloudflare.com/client/v4/accounts/{ACCOUNT_ID}/ai/v1/`
4. Model ID: `@cf/deepseek-ai/deepseek-r1-distill-qwen-32b`

### Test the Connection

```bash
curl https://api.cloudflare.com/client/v4/accounts/{ACCOUNT_ID}/ai/v1/chat/completions \
  -X POST \
  -H "Authorization: Bearer {API_TOKEN}" \
  -d '{
    "model": "@cf/deepseek-ai/deepseek-r1-distill-qwen-32b",
    "messages": [
      {"role": "system", "content": "You are a helpful assistant."},
      {"role": "user", "content": "Hello, how are you?"}
    ],
    "stream": false
  }'
```

**Recommended models for ElevenLabs agents:**
- `@cf/deepseek-ai/deepseek-r1-distill-qwen-32b` - Strong reasoning, function calling
- `@cf/meta/llama-3.3-70b-instruct-fp8-fast` - General purpose, fast

---

## fal.ai Integration

### ElevenLabs via fal.ai

fal.ai provides ElevenLabs as a hosted service with simplified billing:

```typescript
interface Env {
  FAL_KEY: string;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const { text, voice = "Rachel" } = await request.json();

    const response = await fetch(
      "https://fal.run/fal-ai/elevenlabs/tts/multilingual-v2",
      {
        method: "POST",
        headers: {
          Authorization: `Key ${env.FAL_KEY}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          text,
          voice,
          model_id: "eleven_multilingual_v2",
        }),
      }
    );

    const result = await response.json();
    return Response.json(result);
  },
};
```

### Other fal.ai TTS Options

```typescript
// Kokoro TTS - $0.02/1K chars (cheapest quality option)
const kokoroResponse = await fetch(
  "https://fal.run/fal-ai/kokoro/american-english",
  {
    method: "POST",
    headers: {
      Authorization: `Key ${env.FAL_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ text }),
  }
);

// F5-TTS - $0.05/1K chars (zero-shot voice cloning)
const f5Response = await fetch("https://fal.run/fal-ai/f5-tts", {
  method: "POST",
  headers: {
    Authorization: `Key ${env.FAL_KEY}`,
    "Content-Type": "application/json",
  },
  body: JSON.stringify({
    gen_text: text,
    ref_audio_url: "https://example.com/reference-voice.mp3",
  }),
});
```

---

## OpenAI TTS Integration

```typescript
interface Env {
  OPENAI_API_KEY: string;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const { text, voice = "alloy" } = await request.json();

    const response = await fetch("https://api.openai.com/v1/audio/speech", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${env.OPENAI_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "tts-1", // or "tts-1-hd" for higher quality
        input: text,
        voice, // alloy, echo, fable, onyx, nova, shimmer
      }),
    });

    return new Response(response.body, {
      headers: { "Content-Type": "audio/mpeg" },
    });
  },
};
```

---

## Gotchas and Limitations

### Cloudflare Workers Limits

| Limit | Free | Paid |
|-------|------|------|
| CPU time | 10ms | 30s (soft), 15min (Cron) |
| Memory | 128MB | 128MB |
| Concurrent connections | 6 | 6 |
| Subrequest limit | 50 | 1000 |
| WebSocket duration | 100s | 100s (Enterprise: custom) |

### ElevenLabs WebSocket Gotchas

1. **Inactivity timeout**: Default 20 seconds, max 180 seconds
   - Send single space `" "` to keep alive
   - Empty string `""` sends EOS and closes connection

2. **Workers WebSocket limitation**: Cannot store WebSocket in global variable
   - Use Durable Objects for persistent connections

3. **Streaming buffer**: Workers have 128MB memory limit
   - Stream audio directly, don't buffer entire response

### ElevenLabs API Gotchas

1. **Rate limits**: Vary by plan (check ElevenLabs dashboard)
2. **Character counting**: Includes spaces and punctuation
3. **Model latency**:
   - Turbo v2.5: ~75ms (real-time)
   - Multilingual v2: ~150-300ms (higher quality)

### Cost Considerations

1. **Cloudflare AI Gateway**: Free logging, but 100K log limit on free tier
2. **ElevenLabs via fal.ai**: No subscription, pure pay-per-use
3. **Direct ElevenLabs**: Monthly minimums, better for high volume

---

## Architecture Patterns

### Pattern 1: Fallback Chain

Use AI Gateway to fallback between providers:

```typescript
async function textToSpeech(text: string, env: Env): Promise<Response> {
  // Try Cloudflare Aura first (cheapest)
  try {
    const audio = await env.AI.run("@deepgram/aura-2-en", { text });
    return new Response(audio, {
      headers: { "Content-Type": "audio/wav", "X-TTS-Provider": "cloudflare" },
    });
  } catch (e) {
    console.log("Cloudflare TTS failed, trying ElevenLabs");
  }

  // Fallback to ElevenLabs
  const response = await fetch(
    `https://gateway.ai.cloudflare.com/v1/${env.CF_ACCOUNT_ID}/${env.AI_GATEWAY_ID}/elevenlabs/v1/text-to-speech/JBFqnCBsd6RMkjVDRZzb`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "xi-api-key": env.ELEVENLABS_API_KEY,
      },
      body: JSON.stringify({ text, model_id: "eleven_turbo_v2_5" }),
    }
  );

  return new Response(response.body, {
    headers: { "Content-Type": "audio/mpeg", "X-TTS-Provider": "elevenlabs" },
  });
}
```

### Pattern 2: Quality-Based Routing

Route based on quality requirements:

```typescript
type Quality = "fast" | "standard" | "premium";

async function selectTTSProvider(
  text: string,
  quality: Quality,
  env: Env
): Promise<Response> {
  switch (quality) {
    case "fast":
      // Cloudflare MeloTTS - cheapest, multilingual
      return new Response(
        await env.AI.run("@cf/myshell-ai/melotts", { text }),
        { headers: { "Content-Type": "audio/wav" } }
      );

    case "standard":
      // Cloudflare Aura-2 - good quality, English
      return new Response(
        await env.AI.run("@deepgram/aura-2-en", { text }),
        { headers: { "Content-Type": "audio/wav" } }
      );

    case "premium":
      // ElevenLabs - best quality, voice cloning
      const response = await fetch(
        "https://api.elevenlabs.io/v1/text-to-speech/JBFqnCBsd6RMkjVDRZzb",
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "xi-api-key": env.ELEVENLABS_API_KEY,
          },
          body: JSON.stringify({
            text,
            model_id: "eleven_multilingual_v2",
          }),
        }
      );
      return new Response(response.body, {
        headers: { "Content-Type": "audio/mpeg" },
      });
  }
}
```

### Pattern 3: Cache Audio with R2

Cache generated audio to reduce costs:

```typescript
interface Env {
  AI: Ai;
  AUDIO_CACHE: R2Bucket;
  ELEVENLABS_API_KEY: string;
}

async function getCachedOrGenerate(
  text: string,
  provider: string,
  env: Env
): Promise<Response> {
  // Create cache key from text hash
  const hash = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(`${provider}:${text}`)
  );
  const cacheKey = Array.from(new Uint8Array(hash))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");

  // Check cache
  const cached = await env.AUDIO_CACHE.get(cacheKey);
  if (cached) {
    return new Response(cached.body, {
      headers: {
        "Content-Type": cached.httpMetadata?.contentType || "audio/mpeg",
        "X-Cache": "HIT",
      },
    });
  }

  // Generate audio
  let audio: ArrayBuffer;
  let contentType: string;

  if (provider === "cloudflare") {
    audio = await env.AI.run("@deepgram/aura-2-en", { text });
    contentType = "audio/wav";
  } else {
    const response = await fetch(
      "https://api.elevenlabs.io/v1/text-to-speech/JBFqnCBsd6RMkjVDRZzb",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "xi-api-key": env.ELEVENLABS_API_KEY,
        },
        body: JSON.stringify({ text, model_id: "eleven_multilingual_v2" }),
      }
    );
    audio = await response.arrayBuffer();
    contentType = "audio/mpeg";
  }

  // Cache for 7 days
  await env.AUDIO_CACHE.put(cacheKey, audio, {
    httpMetadata: { contentType },
    customMetadata: { text: text.substring(0, 100), provider },
  });

  return new Response(audio, {
    headers: { "Content-Type": contentType, "X-Cache": "MISS" },
  });
}
```

---

## Best Practices

### 1. Use AI Gateway for Third-Party APIs
- Centralizes logging and analytics
- Enables caching to reduce costs
- Provides rate limiting protection
- Simplifies fallback configuration

### 2. Stream Large Responses
- Don't buffer entire audio files in memory
- Use `response.body` streams directly
- Workers have 128MB memory limit

### 3. Cache Aggressively
- Audio generation is expensive
- Use R2 for long-term caching
- Use KV for metadata/mappings

### 4. Monitor Costs
- Set up billing alerts
- Track per-provider usage
- Use AI Gateway analytics

### 5. Handle Failures Gracefully
- Implement retry with exponential backoff
- Have fallback providers
- Return cached/default audio on failure
