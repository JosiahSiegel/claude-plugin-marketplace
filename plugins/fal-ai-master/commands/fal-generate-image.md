# Generate Image with fal.ai

Generate AI images using fal.ai models like FLUX, Stable Diffusion, and more.

## What This Command Does

Guides you through generating images with fal.ai, selecting the optimal model and parameters for your use case.

## Steps

1. **Gather Requirements**
   - Prompt description
   - Image size and aspect ratio
   - Quality vs speed preference
   - Output format requirements

2. **Select Model**
   - FLUX.1 [dev] - High quality, open-source
   - FLUX.2 [pro] - Best quality, production
   - FLUX Schnell - Fast generation
   - Fast SDXL - Speed optimized
   - Recraft V3 - Design assets

3. **Configure Parameters**
   - num_inference_steps (quality)
   - guidance_scale (prompt adherence)
   - seed (reproducibility)
   - safety checker settings

4. **Generate Code**
   - JavaScript/TypeScript or Python
   - Error handling
   - Progress feedback

## Quick Reference

### Model Selection Guide

| Need | Recommended Model | Why |
|------|------------------|-----|
| Best quality | `fal-ai/flux-2-pro` | Latest FLUX, highest fidelity |
| Fast iteration | `fal-ai/flux/schnell` | 4-step generation |
| Open source | `fal-ai/flux/dev` | 12B parameter model |
| Budget friendly | `fal-ai/fast-sdxl` | Lower cost per image |
| Custom styles | `fal-ai/flux-lora` | Fine-tuned models |
| Design work | `fal-ai/recraft-v3` | Vector-style outputs |

### Image Sizes

| Preset | Dimensions | Use Case |
|--------|------------|----------|
| `square` | 512x512 | Thumbnails, icons |
| `square_hd` | 1024x1024 | Social media |
| `portrait_4_3` | 768x1024 | Portraits |
| `portrait_16_9` | 576x1024 | Mobile wallpapers |
| `landscape_4_3` | 1024x768 | Presentations |
| `landscape_16_9` | 1024x576 | Widescreen |

### JavaScript/TypeScript Example

```typescript
import { fal } from "@fal-ai/client";

fal.config({ credentials: process.env.FAL_KEY });

async function generateImage(prompt: string) {
  const result = await fal.subscribe("fal-ai/flux/dev", {
    input: {
      prompt,
      image_size: "landscape_16_9",
      num_inference_steps: 28,
      guidance_scale: 3.5,
      num_images: 1,
      enable_safety_checker: true,
      output_format: "jpeg"
    },
    logs: true,
    onQueueUpdate: (update) => {
      if (update.status === "IN_PROGRESS") {
        console.log("Generating...", update.logs);
      }
    }
  });

  return result.images[0].url;
}
```

### Python Example

```python
import fal_client

def generate_image(prompt: str) -> str:
    result = fal_client.subscribe(
        "fal-ai/flux/dev",
        arguments={
            "prompt": prompt,
            "image_size": "landscape_16_9",
            "num_inference_steps": 28,
            "guidance_scale": 3.5,
            "num_images": 1,
            "enable_safety_checker": True,
            "output_format": "jpeg"
        },
        with_logs=True,
        on_queue_update=lambda update: print(f"Status: {update}")
    )
    return result["images"][0]["url"]
```

### Advanced Features

**Image-to-Image:**
```typescript
const result = await fal.subscribe("fal-ai/flux/dev/image-to-image", {
  input: {
    image_url: "https://example.com/input.jpg",
    prompt: "Transform into oil painting style",
    strength: 0.75
  }
});
```

**Inpainting:**
```typescript
const result = await fal.subscribe("fal-ai/flux/dev/inpainting", {
  input: {
    image_url: "https://example.com/photo.jpg",
    mask_url: "https://example.com/mask.png",
    prompt: "A golden retriever"
  }
});
```

**ControlNet:**
```typescript
const result = await fal.subscribe("fal-ai/flux/dev/controlnet", {
  input: {
    prompt: "Modern architecture",
    control_image_url: "https://example.com/edges.png",
    controlnet_conditioning_scale: 0.8
  }
});
```

## Parameter Tuning

### num_inference_steps
- **Low (4-10):** Fast, lower quality - use with Schnell
- **Medium (20-30):** Balanced - recommended default
- **High (40-50):** Maximum quality, slower

### guidance_scale
- **Low (1-3):** More creative, less prompt adherence
- **Medium (3.5-7):** Balanced - recommended
- **High (8-15):** Strict prompt following

### Seed
- Use same seed for reproducible results
- Combine with identical parameters for variations

## Error Handling

```typescript
import { fal, ValidationError, ApiError } from "@fal-ai/client";

try {
  const result = await fal.subscribe("fal-ai/flux/dev", {
    input: { prompt: "Your prompt" }
  });
} catch (error) {
  if (error instanceof ValidationError) {
    console.error("Invalid parameters:", error.body);
  } else if (error instanceof ApiError) {
    if (error.status === 429) {
      console.error("Rate limited, retry later");
    } else {
      console.error("API error:", error.message);
    }
  }
}
```

## Cost Optimization

1. **Start with Schnell** for iteration, switch to dev/pro for final
2. **Use appropriate sizes** - don't generate larger than needed
3. **Batch similar requests** when possible
4. **Cache results** by seed for reproducible outputs
