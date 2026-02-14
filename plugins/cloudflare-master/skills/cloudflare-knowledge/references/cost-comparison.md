# Cloudflare Workers AI Cost Comparison Guide (2025-2026)

## TTS (Text-to-Speech) Cost Comparison

### Cost Per 1,000 Characters

| Provider | Model | Cost/1K chars | Quality | Latency | Languages |
|----------|-------|---------------|---------|---------|-----------|
| **Cloudflare** | MeloTTS | ~$0.0002/min* | Good | Fast | 6 (en,fr,es,zh,ja,ko) |
| **Cloudflare** | Aura-1 | $0.015 | Good | Fast | English |
| **Cloudflare** | Aura-2 | $0.030 | Excellent | Fast | English, Spanish |
| **OpenAI** | tts-1 | $0.015 | Good | Fast | Multi |
| **OpenAI** | tts-1-hd | $0.030 | Excellent | Medium | Multi |
| **fal.ai** | Kokoro | $0.020 | Good | Fast | English |
| **fal.ai** | F5-TTS | $0.050 | Good | Medium | Multi (clone) |
| **fal.ai** | ElevenLabs | $0.100 | Premium | Medium | 29 |
| **ElevenLabs** | Turbo v2.5 | ~$0.083** | Premium | ~75ms | 32 |
| **ElevenLabs** | Multilingual v2 | ~$0.165** | Premium | ~150ms | 29 |

*MeloTTS is priced per audio minute ($0.0002/min), not characters
**ElevenLabs direct pricing varies by subscription plan

### Monthly Cost Estimates (100K characters/day)

| Provider | Model | Monthly Cost | Notes |
|----------|-------|--------------|-------|
| Cloudflare MeloTTS | ~$0.60 | Based on ~100 min audio/month |
| Cloudflare Aura-1 | $45 | |
| Cloudflare Aura-2 | $90 | Best quality on Cloudflare |
| OpenAI tts-1 | $45 | |
| OpenAI tts-1-hd | $90 | |
| fal.ai Kokoro | $60 | No subscription |
| fal.ai ElevenLabs | $300 | Premium quality, no subscription |
| ElevenLabs Pro | $99 | 500K chars included |
| ElevenLabs Scale | $330 | 2M chars included |

### Cost Decision Tree

```
Is English sufficient?
├── Yes → Is premium voice quality required?
│   ├── Yes → Cloudflare Aura-2 ($0.030/1K)
│   └── No → Cloudflare Aura-1 ($0.015/1K)
└── No → Is voice cloning required?
    ├── Yes → ElevenLabs or F5-TTS
    └── No → Do you need 6+ languages?
        ├── Yes → ElevenLabs Multilingual
        └── No → Cloudflare MeloTTS ($0.0002/min)
```

---

## LLM Inference Cost Comparison

### Cost Per 1M Tokens (Input)

| Provider | Model | Input/1M | Output/1M | Context | Notes |
|----------|-------|----------|-----------|---------|-------|
| **Cloudflare** | Llama 3.3 70B | $0.27 | $0.27 | 128K | Best value large |
| **Cloudflare** | Llama 3.1 8B | $0.05 | $0.05 | 128K | Fast, cheap |
| **Cloudflare** | DeepSeek-R1-Distill | $0.14 | $0.14 | 64K | Reasoning |
| **Cloudflare** | Qwen 2.5 72B | $0.35 | $0.35 | 128K | Multilingual |
| **OpenAI** | GPT-4o | $2.50 | $10.00 | 128K | Premium |
| **OpenAI** | GPT-4o-mini | $0.15 | $0.60 | 128K | Balanced |
| **OpenAI** | GPT-3.5-turbo | $0.50 | $1.50 | 16K | Legacy |
| **Anthropic** | Claude 3.5 Sonnet | $3.00 | $15.00 | 200K | Premium |
| **Anthropic** | Claude 3 Haiku | $0.25 | $1.25 | 200K | Fast |

### Cloudflare Neuron Pricing

Cloudflare charges $0.011 per 1,000 Neurons with 10,000 free daily neurons.

**Converting to familiar terms:**
- Llama 3.3 70B: ~24,545 neurons per 1M tokens
- Llama 3.1 8B: ~4,545 neurons per 1M tokens
- Whisper: ~472 neurons per minute

---

## STT (Speech-to-Text) Cost Comparison

### Cost Per Minute of Audio

| Provider | Model | Cost/min | Quality | Languages |
|----------|-------|----------|---------|-----------|
| **Cloudflare** | Whisper Large v3 Turbo | $0.0052 | Excellent | 100+ |
| **Cloudflare** | Deepgram Nova-3 | $0.0052 | Excellent | Multi |
| **Cloudflare** | Deepgram Nova-3 WS | $0.0092 | Excellent | Multi |
| **OpenAI** | Whisper | $0.006 | Excellent | 100+ |
| **Deepgram** | Nova-2 | $0.0043 | Excellent | Multi |
| **AssemblyAI** | Universal | $0.0065 | Excellent | Multi |

### Monthly Cost Estimates (100 hours of audio)

| Provider | Model | Monthly Cost |
|----------|-------|--------------|
| Cloudflare Whisper | $31.20 |
| Cloudflare Deepgram | $31.20 |
| OpenAI Whisper | $36.00 |
| Deepgram Nova-2 | $25.80 |

---

## Image Generation Cost Comparison

### Cost Per Image

| Provider | Model | Cost/image | Resolution | Speed |
|----------|-------|------------|------------|-------|
| **Cloudflare** | FLUX.1 Schnell | ~$0.01 | 1024x1024 | Fast (4 steps) |
| **Cloudflare** | SDXL | ~$0.02 | 1024x1024 | Medium (20 steps) |
| **OpenAI** | DALL-E 3 | $0.04-0.12 | 1024x1024 | Medium |
| **fal.ai** | FLUX.2 | $0.025 | 1024x1024 | Fast |
| **fal.ai** | SDXL | $0.01 | 1024x1024 | Medium |

---

## Embedding Cost Comparison

### Cost Per 1M Tokens

| Provider | Model | Cost/1M | Dimensions | Quality |
|----------|-------|---------|------------|---------|
| **Cloudflare** | BGE Large | ~$0.01 | 1024 | Best |
| **Cloudflare** | BGE Base | ~$0.008 | 768 | Good |
| **Cloudflare** | BGE Small | ~$0.005 | 384 | Fast |
| **OpenAI** | text-embedding-3-large | $0.13 | 3072 | Best |
| **OpenAI** | text-embedding-3-small | $0.02 | 1536 | Good |
| **Cohere** | embed-v3 | $0.10 | 1024 | Best |

---

## Platform Costs

### Cloudflare Workers

| Resource | Free | Paid ($5/month) |
|----------|------|-----------------|
| Requests | 100K/day | 10M/month |
| CPU time | 10ms | 30s |
| Workers AI neurons | None | 10K/day free |
| KV reads | 100K/day | 10M/month |
| KV writes | 1K/day | 1M/month |
| R2 storage | 10GB | 10GB free, $0.015/GB |
| R2 operations | 1M Class A | 10M Class A |
| D1 rows read | 5M/day | 25B/month |
| D1 rows written | 100K/day | 50M/month |

### Durable Objects

| Resource | Cost |
|----------|------|
| Requests | $0.15/million |
| Duration | $12.50/million GB-s |
| WebSocket messages | $0.15/million |

**WebSocket Cost Example:**
- 1M concurrent connections for 1 hour
- ~$11,500 (128MB × 3600s × 1M / 1B × $12.50)

---

## Cost Optimization Strategies

### 1. Use Cloudflare Native When Possible

**Savings potential: 50-90%**

```
ElevenLabs Multilingual: $0.165/1K chars
Cloudflare Aura-2:       $0.030/1K chars
Savings:                 82%
```

### 2. Cache Aggressively with R2

**For TTS with R2 caching:**
- R2 storage: $0.015/GB/month
- R2 Class A ops: $4.50/million
- R2 Class B ops: $0.36/million

**Break-even analysis:**
- 1KB audio file
- Cloudflare Aura-2: $0.030 to generate
- R2 retrieval: $0.00000036
- After 1 cache hit, you save $0.029+

### 3. Use AI Gateway for Third-Party APIs

**Benefits:**
- Response caching (reduce API calls by 30-50%)
- Request logging (100K free, $0.60/million after)
- Rate limiting (prevent overage charges)

### 4. Right-Size Your Models

| Use Case | Recommended Model | Why |
|----------|-------------------|-----|
| Simple Q&A | Llama 3.1 8B | 5x cheaper than 70B |
| Complex reasoning | DeepSeek-R1-Distill | Better than 70B for logic |
| Multilingual | Qwen 2.5 72B | Best non-English |
| English TTS | Aura-1 | 50% cheaper than Aura-2 |
| Multilingual TTS | MeloTTS | 100x cheaper than ElevenLabs |

### 5. Batch Requests

**Embeddings example:**
```typescript
// Bad: 100 separate requests
for (const text of texts) {
  await env.AI.run("@cf/baai/bge-large-en-v1.5", { text });
}

// Good: 1 batched request
await env.AI.run("@cf/baai/bge-large-en-v1.5", { text: texts });
```

### 6. Use Queue for Non-Real-Time Tasks

**Queue pricing:**
- $0.40/million operations
- No CPU time limits

Move expensive AI tasks to queues:
```typescript
// Worker receives request
await env.AI_QUEUE.send({ task: "generate-audio", text });
return new Response("Accepted", { status: 202 });

// Queue consumer processes without timeout pressure
```

---

## Cost Monitoring

### Cloudflare Dashboard

1. **Workers & Pages → Usage**
   - Requests, CPU time, duration

2. **AI → Workers AI**
   - Neurons consumed per model

3. **AI Gateway → Analytics**
   - Third-party API costs

### Setting Alerts

```bash
# Use Cloudflare API to check usage
curl -X GET "https://api.cloudflare.com/client/v4/accounts/{account_id}/ai/usage" \
  -H "Authorization: Bearer {api_token}"
```

### Cost Estimation Formula

```
Monthly Cost =
  (Requests × $0.30/million) +
  (AI Neurons × $0.011/1000) +
  (R2 Storage × $0.015/GB) +
  (R2 Ops × $4.50/million Class A) +
  (D1 Reads × $0.001/million) +
  (External API calls × provider rate)
```

---

## Summary: When to Use What

| Scenario | First Choice | Fallback | Avoid |
|----------|--------------|----------|-------|
| English TTS | Cloudflare Aura | OpenAI tts-1 | ElevenLabs (cost) |
| Premium TTS | ElevenLabs | OpenAI tts-1-hd | - |
| Multilingual TTS | MeloTTS | ElevenLabs | OpenAI (quality) |
| Voice cloning | ElevenLabs | F5-TTS | - |
| Real-time voice | ElevenLabs Turbo | Cloudflare Aura | Multilingual v2 |
| Transcription | Cloudflare Whisper | Deepgram | AssemblyAI (cost) |
| LLM (cheap) | Llama 3.1 8B | GPT-4o-mini | GPT-4o |
| LLM (quality) | Llama 3.3 70B | Claude 3.5 | - |
| Embeddings | Cloudflare BGE | OpenAI small | OpenAI large |
| Images | FLUX.1 Schnell | SDXL | DALL-E 3 (cost) |
