# fal.ai Master Plugin

Complete fal.ai generative media platform expertise for Claude Code, covering 600+ AI models for image, video, audio, and 3D generation, plus serverless deployment and GPU compute.

## Features

This plugin provides comprehensive expertise in:

- **Model APIs** - Access to 600+ production-ready AI models
- **Image Generation** - FLUX, Stable Diffusion, Recraft, Ideogram, and more
- **Video Generation** - Kling, Sora, LTX, Runway, Luma, MiniMax
- **Audio Processing** - Whisper STT, F5-TTS, ElevenLabs, Kokoro TTS
- **3D Generation** - TripoSR, InstantMesh, Stable Zero123
- **Serverless Deployment** - Deploy custom ML models with automatic scaling
- **GPU Compute** - H100/H200/B200 clusters for heavy workloads

## Skills

### Core Skills

| Skill | Description |
|-------|-------------|
| `fal-api-reference` | Complete API reference for client libraries and REST endpoints |
| `fal-model-guide` | Model selection guidance for all use cases |
| `fal-serverless-guide` | Deploy custom models to fal serverless |
| `fal-optimization` | Performance and cost optimization strategies |

### Model-Specific Skills

| Skill | Description |
|-------|-------------|
| `fal-text-to-image` | Complete reference for FLUX, SD, Recraft, Ideogram, Playground models |
| `fal-image-to-image` | ControlNet, inpainting, upscaling, background removal, face enhancement |
| `fal-text-to-video` | Kling, Sora, LTX, Wan, MiniMax, Runway, Luma, CogVideoX, Hunyuan |
| `fal-image-to-video` | Image animation with Kling, MiniMax, LTX, Runway, Luma, SVD |
| `fal-video-to-video` | Video editing, style transfer, upscaling, frame interpolation |
| `fal-audio` | Complete STT (Whisper) and TTS (F5-TTS, ElevenLabs, Kokoro, XTTS) |

## Commands

| Command | Description |
|---------|-------------|
| `/fal-generate-image` | Generate images with FLUX, SDXL, and other models |
| `/fal-generate-video` | Generate videos with Kling, Sora, LTX, and more |
| `/fal-deploy` | Deploy custom ML models to fal serverless |
| `/fal-debug` | Debug fal.ai integration issues |

## Agents

| Agent | Description |
|-------|-------------|
| `fal-ai-expert` | Complete fal.ai expertise for model selection, implementation, and deployment |

## Complete Model Catalog

### TEXT-TO-IMAGE (12 models)

| Model | Endpoint | Best For |
|-------|----------|----------|
| FLUX.2 Pro | `fal-ai/flux-2-pro` | Best quality, commercial |
| FLUX.1.1 Pro | `fal-ai/flux-pro/v1.1` | High quality production |
| FLUX.1.1 Pro Ultra | `fal-ai/flux-pro/v1.1-ultra` | High resolution (up to 4MP) |
| FLUX.1 Dev | `fal-ai/flux/dev` | Open-source, high quality |
| FLUX Schnell | `fal-ai/flux/schnell` | Fast iteration (4 steps) |
| FLUX LoRA | `fal-ai/flux-lora` | Custom styles with adapters |
| FLUX Realism | `fal-ai/flux-realism` | Photorealistic images |
| FLUX Fill | `fal-ai/flux-pro/v1/fill` | Inpainting/outpainting |
| Stable Diffusion 3.5 Large | `fal-ai/stable-diffusion-v35-large` | Open-source alternative |
| SDXL | `fal-ai/fast-sdxl` | Speed, lower cost |
| Recraft v3 | `fal-ai/recraft-v3` | Design/illustration |
| Ideogram v2 | `fal-ai/ideogram/v2` | Text rendering |

### IMAGE-TO-IMAGE (8 models)

| Model | Endpoint | Best For |
|-------|----------|----------|
| FLUX Image-to-Image | `fal-ai/flux/dev/image-to-image` | Image transformation |
| FLUX ControlNet | `fal-ai/flux-controlnet` | Structural control |
| FLUX Redux | `fal-ai/flux-redux` | Style transfer |
| FLUX Fill (Inpainting) | `fal-ai/flux-pro/v1/fill` | Object removal/addition |
| IP-Adapter | `fal-ai/ip-adapter-face-id` | Face consistency |
| SDXL ControlNet | `fal-ai/sdxl-controlnet` | Pose/edge/depth control |
| Playground v2.5 | `fal-ai/playground-v25` | Aesthetic tuning |
| IC-Light | `fal-ai/ic-light` | Relighting images |

### UPSCALING (6 models)

| Model | Endpoint | Best For |
|-------|----------|----------|
| Real-ESRGAN | `fal-ai/real-esrgan` | General upscaling |
| ESRGAN | `fal-ai/esrgan` | Fast upscaling |
| Clarity Upscaler | `fal-ai/clarity-upscaler` | AI-enhanced upscaling |
| GFPGAN | `fal-ai/gfpgan` | Face restoration |
| CodeFormer | `fal-ai/codeformer` | Face enhancement |
| AuraSR | `fal-ai/aura-sr` | Fast AI upscaling |

### BACKGROUND REMOVAL (3 models)

| Model | Endpoint | Best For |
|-------|----------|----------|
| BiRefNet | `fal-ai/birefnet` | High quality removal |
| RemBG | `fal-ai/rembg` | Fast removal |
| BRIA Background Removal | `fal-ai/bria/background-removal` | Production use |

### TEXT-TO-VIDEO (12 models)

| Model | Endpoint | Best For |
|-------|----------|----------|
| Kling 2.6 Pro | `fal-ai/kling-video/v2.6/pro/text-to-video` | Best quality with audio |
| Kling 2.5 Pro | `fal-ai/kling-video/v2.5/pro/text-to-video` | Professional quality |
| Kling 2.0 | `fal-ai/kling-video/v2.0/text-to-video` | Good quality, cost-effective |
| Sora 2 | `fal-ai/sora` | OpenAI advanced video |
| LTX-2 Pro | `fal-ai/ltx-2-pro` | Fast with audio support |
| LTX Video v2 | `fal-ai/ltx-video/v2` | Improved quality |
| LTX Video | `fal-ai/ltx-video` | Fast, efficient |
| MiniMax | `fal-ai/minimax-video/text-to-video` | Balanced quality/speed |
| Runway Gen-3 Turbo | `fal-ai/runway-gen3/turbo/text-to-video` | Fast iteration |
| Luma Dream Machine | `fal-ai/luma-dream-machine` | Creative, artistic |
| CogVideoX-5B | `fal-ai/cogvideox-5b` | Open-source |
| Hunyuan Video | `fal-ai/hunyuan-video` | Chinese model |

### IMAGE-TO-VIDEO (8 models)

| Model | Endpoint | Best For |
|-------|----------|----------|
| Kling 2.6 Pro i2v | `fal-ai/kling-video/v2.6/pro/image-to-video` | Highest quality animation |
| Kling 2.5 Pro i2v | `fal-ai/kling-video/v2.5/pro/image-to-video` | Professional animation |
| Kling 2.0 i2v | `fal-ai/kling-video/v2.0/image-to-video` | Standard animation |
| MiniMax i2v | `fal-ai/minimax-video/image-to-video` | Reliable with optimizer |
| LTX v2 i2v | `fal-ai/ltx-video/v2/image-to-video` | Fast animation |
| Runway Gen-3 i2v | `fal-ai/runway-gen3/turbo/image-to-video` | Quick previews |
| Luma | `fal-ai/luma-dream-machine` | Looping videos |
| Stable Video Diffusion | `fal-ai/stable-video-diffusion` | Open-source |

### VIDEO-TO-VIDEO (3 models)

| Model | Endpoint | Best For |
|-------|----------|----------|
| Kling O1 Edit | `fal-ai/kling-video/o1/video-to-video/edit` | Style transfer, editing |
| Sora Remix | `fal-ai/sora/remix` | Creative remixing |
| Video Upscaler | `fal-ai/video-upscaler` | Resolution enhancement |

### SPEECH-TO-TEXT (3 models)

| Model | Endpoint | Best For |
|-------|----------|----------|
| Whisper | `fal-ai/whisper` | Accurate transcription |
| Whisper Turbo | `fal-ai/whisper-turbo` | Fast transcription |
| Whisper Large v3 | `fal-ai/whisper-large-v3` | Maximum accuracy |

### TEXT-TO-SPEECH (4 models)

| Model | Endpoint | Best For |
|-------|----------|----------|
| F5-TTS | `fal-ai/f5-tts` | Voice cloning |
| ElevenLabs | `fal-ai/elevenlabs/tts` | Premium quality |
| Kokoro | `fal-ai/kokoro/american-english` | Multi-language |
| XTTS | `fal-ai/xtts` | Open-source cloning |

### 3D GENERATION (3 models)

| Model | Endpoint | Best For |
|-------|----------|----------|
| TripoSR | `fal-ai/triposr` | Fast 3D from image |
| InstantMesh | `fal-ai/instant-mesh` | Quality meshes |
| Stable Zero123 | `fal-ai/stable-zero123` | Multi-view generation |

## Quick Reference

### Installation

```bash
# JavaScript/TypeScript
npm install @fal-ai/client

# Python Client
pip install fal-client

# Python Serverless
pip install fal
```

### Authentication

```bash
# Set API key
export FAL_KEY="your-api-key"
```

### Generate Image (JavaScript)

```typescript
import { fal } from "@fal-ai/client";

const result = await fal.subscribe("fal-ai/flux/dev", {
  input: {
    prompt: "A serene mountain landscape at sunset",
    image_size: "landscape_16_9",
    num_inference_steps: 28,
    guidance_scale: 3.5
  },
  logs: true,
  onQueueUpdate: (update) => {
    console.log("Status:", update.status);
  }
});

console.log(result.images[0].url);
```

### Generate Image (Python)

```python
import fal_client

result = fal_client.subscribe(
    "fal-ai/flux/dev",
    arguments={
        "prompt": "A serene mountain landscape at sunset",
        "image_size": "landscape_16_9",
        "num_inference_steps": 28,
        "guidance_scale": 3.5
    },
    with_logs=True
)

print(result["images"][0]["url"])
```

### Generate Video

```typescript
const result = await fal.subscribe("fal-ai/kling-video/v2.6/pro/text-to-video", {
  input: {
    prompt: "A majestic eagle soaring over mountains, cinematic",
    duration: "5",
    aspect_ratio: "16:9"
  }
});

console.log(result.video.url);
```

### Image-to-Video Animation

```typescript
const result = await fal.subscribe("fal-ai/kling-video/v2.5/pro/image-to-video", {
  input: {
    prompt: "The person slowly turns their head and smiles",
    image_url: "https://example.com/portrait.jpg",
    duration: "5",
    aspect_ratio: "16:9"
  }
});

console.log(result.video.url);
```

### Speech-to-Text

```typescript
const result = await fal.subscribe("fal-ai/whisper", {
  input: {
    audio_url: "https://example.com/speech.mp3",
    task: "transcribe",
    chunk_level: "segment"
  }
});

console.log(result.text);
```

### Text-to-Speech

```typescript
const result = await fal.subscribe("fal-ai/f5-tts", {
  input: {
    gen_text: "Hello, welcome to the demonstration.",
    ref_audio_url: "https://example.com/voice-sample.wav",
    ref_text: "This is my voice sample."
  }
});

console.log(result.audio_url);
```

### Deploy Custom Model

```python
import fal
from pydantic import BaseModel

class MyModel(fal.App):
    machine_type = "GPU-A100"
    requirements = ["torch", "transformers"]

    def setup(self):
        self.model = load_model()

    @fal.endpoint("/predict")
    def predict(self, prompt: str) -> dict:
        return {"result": self.model(prompt)}
```

```bash
fal deploy app.py::MyModel
```

## API Methods

### JavaScript (@fal-ai/client)

| Method | Use Case |
|--------|----------|
| `fal.subscribe()` | Queue-based execution (recommended) |
| `fal.run()` | Direct execution (fast endpoints) |
| `fal.stream()` | Progressive output via SSE |
| `fal.realtime.connect()` | WebSocket for interactive apps |
| `fal.storage.upload()` | Upload files to CDN |

### Python (fal-client)

| Method | Use Case |
|--------|----------|
| `fal_client.subscribe()` | Queue-based with status updates |
| `fal_client.run()` | Synchronous execution |
| `fal_client.run_async()` | Async execution |
| `fal_client.upload_file()` | Upload to CDN |

## Serverless Machine Types

| Type | GPU | VRAM | Best For |
|------|-----|------|----------|
| `GPU-T4` | NVIDIA T4 | 16GB | Development |
| `GPU-A10G` | NVIDIA A10G | 24GB | Medium models |
| `GPU-A100` | NVIDIA A100 | 40/80GB | Large models |
| `GPU-H100` | NVIDIA H100 | 80GB | Production |
| `GPU-H200` | NVIDIA H200 | 141GB | Largest models |
| `GPU-B200` | NVIDIA B200 | 192GB | Maximum compute |

## Best Practices

### Performance
- Use `subscribe()` for generation tasks (not `run()`)
- Implement streaming for progress feedback
- Use WebSockets for interactive applications
- Cache results using seeds for reproducibility

### Cost
- Use Schnell/Fast models for development
- Generate at target size (don't upscale unnecessarily)
- Use webhooks instead of polling for high volume
- Scale to zero when not in use

### Security
- Never expose FAL_KEY in client-side code
- Use server-side proxy for browser apps
- Validate user inputs before API calls

## Installation

### Via GitHub Marketplace (Recommended)

```bash
# Add the marketplace
/plugin marketplace add claude-plugin-marketplace

# Install the plugin
/plugin install fal-ai-master@claude-plugin-marketplace
```

### Local Installation (Mac/Linux)

```bash
unzip fal-ai-master.zip -d ~/.local/share/claude/plugins/
```

### Local Installation (Windows)

```powershell
Expand-Archive fal-ai-master.zip -DestinationPath "$env:APPDATA\claude\plugins\"
```

## Resources

- **fal.ai Documentation:** https://docs.fal.ai
- **Model Explorer:** https://fal.ai/models
- **API Reference:** https://docs.fal.ai/model-apis
- **Serverless Guide:** https://docs.fal.ai/serverless
- **GitHub:** https://github.com/fal-ai
- **Blog:** https://blog.fal.ai
- **Discord:** https://discord.gg/fal-ai

## License

MIT

## Links

- **Plugin Repository:** [claude-plugin-marketplace](https://github.com/JosiahSiegel/claude-plugin-marketplace)
