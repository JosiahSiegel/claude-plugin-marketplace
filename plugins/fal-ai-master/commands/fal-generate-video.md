---
name: Generate Video
description: Generate AI videos using fal.ai models like Veo 3, Sora 2, Kling 2.6, and more
argument-hint: <prompt> [--model veo|sora|kling|ltx] [--duration 5|10|20]
---

# Generate Video with fal.ai

Generate AI videos using fal.ai models like Kling, Sora, LTX, and more.

## What This Command Does

Guides you through generating videos with fal.ai, selecting the optimal model and parameters for your use case.

## Steps

1. **Gather Requirements**
   - Text-to-video or image-to-video
   - Duration needed
   - Aspect ratio
   - Quality requirements
   - Audio needs

2. **Select Model**
   - Kling 2.6 Pro - Cinematic with audio
   - Sora 2 - OpenAI advanced
   - LTX-2 Pro - High fidelity
   - MiniMax Hailuo - Image-to-video
   - Runway Gen-3 - Fast generation

3. **Configure Parameters**
   - Duration
   - Resolution/aspect ratio
   - Motion settings
   - Audio options

4. **Generate Code**
   - JavaScript/TypeScript or Python
   - Progress tracking
   - Error handling

## Model Selection Guide

| Model | Endpoint | Best For | Audio | Duration |
|-------|----------|----------|-------|----------|
| Kling 2.6 Pro | `fal-ai/kling-video/v2.6/pro` | Cinematic quality | Native | 5-10s |
| Kling O1 | `fal-ai/kling-video/o1` | Video editing | Yes | 5s |
| Sora 2 | `fal-ai/sora` | High quality | Optional | 5-20s |
| LTX-2 Pro | `fal-ai/ltx-video-2-pro` | Fast, high fidelity | Yes | 5s |
| MiniMax Hailuo | `fal-ai/minimax/video-01` | Image animation | No | 6s |
| Runway Gen-3 | `fal-ai/runway/gen3/turbo` | Fast iteration | No | 5-10s |
| Luma | `fal-ai/luma-dream-machine` | Creative | No | 5s |
| CogVideoX | `fal-ai/cogvideox` | Open source | No | 6s |

## Text-to-Video Examples

### JavaScript/TypeScript

```typescript
import { fal } from "@fal-ai/client";

fal.config({ credentials: process.env.FAL_KEY });

// Kling 2.6 Pro - Best quality
async function generateWithKling(prompt: string) {
  const result = await fal.subscribe("fal-ai/kling-video/v2.6/pro", {
    input: {
      prompt,
      duration: 5,
      aspect_ratio: "16:9",
      negative_prompt: "blurry, low quality, distorted",
      cfg_scale: 0.5
    },
    logs: true,
    onQueueUpdate: (update) => {
      console.log("Status:", update.status);
    }
  });

  return {
    videoUrl: result.video.url,
    audioUrl: result.audio?.url
  };
}

// LTX-2 Pro - Fast with audio
async function generateWithLTX(prompt: string) {
  const result = await fal.subscribe("fal-ai/ltx-video-2-pro", {
    input: {
      prompt,
      negative_prompt: "worst quality, inconsistent motion",
      num_inference_steps: 30,
      guidance_scale: 3.5,
      resolution: "720p",
      enable_audio: true
    }
  });

  return result.video.url;
}

// Runway Gen-3 Turbo - Fast iteration
async function generateWithRunway(prompt: string) {
  const result = await fal.subscribe("fal-ai/runway/gen3/turbo", {
    input: {
      prompt,
      duration: 5,
      ratio: "16:9"
    }
  });

  return result.video.url;
}
```

### Python

```python
import fal_client

def generate_video_kling(prompt: str) -> dict:
    """Generate video with Kling 2.6 Pro"""
    result = fal_client.subscribe(
        "fal-ai/kling-video/v2.6/pro",
        arguments={
            "prompt": prompt,
            "duration": 5,
            "aspect_ratio": "16:9",
            "negative_prompt": "blurry, low quality",
            "cfg_scale": 0.5
        },
        with_logs=True,
        on_queue_update=lambda u: print(f"Status: {u}")
    )
    return {
        "video_url": result["video"]["url"],
        "audio_url": result.get("audio", {}).get("url")
    }

def generate_video_ltx(prompt: str) -> str:
    """Generate video with LTX-2 Pro"""
    result = fal_client.subscribe(
        "fal-ai/ltx-video-2-pro",
        arguments={
            "prompt": prompt,
            "negative_prompt": "worst quality",
            "num_inference_steps": 30,
            "guidance_scale": 3.5,
            "resolution": "720p",
            "enable_audio": True
        }
    )
    return result["video"]["url"]
```

## Image-to-Video Examples

### Animate an Image

```typescript
// MiniMax Hailuo - Image to video
async function animateImage(imageUrl: string, prompt: string) {
  const result = await fal.subscribe("fal-ai/minimax/video-01", {
    input: {
      image_url: imageUrl,
      prompt,
      prompt_optimizer: true
    }
  });

  return result.video.url;
}

// Kling Image-to-Video
async function animateWithKling(imageUrl: string, prompt: string) {
  const result = await fal.subscribe("fal-ai/kling-video/v2.6/pro/image-to-video", {
    input: {
      image_url: imageUrl,
      prompt,
      duration: 5,
      aspect_ratio: "16:9"
    }
  });

  return result.video.url;
}

// Luma Dream Machine
async function animateWithLuma(imageUrl: string, prompt: string) {
  const result = await fal.subscribe("fal-ai/luma-dream-machine", {
    input: {
      image_url: imageUrl,
      prompt,
      loop: false,
      aspect_ratio: "16:9"
    }
  });

  return result.video.url;
}
```

### Python Image-to-Video

```python
def animate_image(image_url: str, prompt: str) -> str:
    """Animate image with MiniMax"""
    result = fal_client.subscribe(
        "fal-ai/minimax/video-01",
        arguments={
            "image_url": image_url,
            "prompt": prompt,
            "prompt_optimizer": True
        }
    )
    return result["video"]["url"]
```

## Video-to-Video (Editing)

```typescript
// Kling O1 for video editing
async function editVideo(videoUrl: string, prompt: string) {
  const result = await fal.subscribe("fal-ai/kling-video/o1", {
    input: {
      video_url: videoUrl,
      prompt,
      negative_prompt: "distorted, glitchy"
    }
  });

  return result.video.url;
}
```

## Parameter Reference

### Common Parameters

| Parameter | Description | Typical Values |
|-----------|-------------|----------------|
| `prompt` | Description of video | Detailed, cinematic |
| `negative_prompt` | What to avoid | "blurry, low quality" |
| `duration` | Length in seconds | 5, 10, 20 |
| `aspect_ratio` | Video dimensions | "16:9", "9:16", "1:1" |
| `cfg_scale` | Prompt adherence | 0.3-0.7 |
| `num_inference_steps` | Quality steps | 20-50 |

### Aspect Ratios

| Ratio | Use Case |
|-------|----------|
| `16:9` | Widescreen, YouTube |
| `9:16` | Vertical, TikTok/Reels |
| `1:1` | Square, Instagram |
| `4:3` | Traditional video |
| `21:9` | Cinematic ultrawide |

## Prompt Tips for Video

1. **Be Specific About Motion**
   - Bad: "A person walking"
   - Good: "A woman walking gracefully through a sunlit forest, camera tracking alongside her"

2. **Describe Camera Movement**
   - "Slow zoom in on..."
   - "Panning shot across..."
   - "Drone shot flying over..."

3. **Include Temporal Details**
   - "Starting with... then transitioning to..."
   - "The sun slowly sets as..."

4. **Specify Style/Mood**
   - "Cinematic, film grain, warm colors"
   - "Hyper-realistic, 4K, sharp focus"

## Error Handling

```typescript
try {
  const result = await fal.subscribe("fal-ai/kling-video/v2.6/pro", {
    input: { prompt: "Your video prompt" }
  });
} catch (error) {
  if (error.status === 429) {
    console.error("Rate limited - implement backoff");
  } else if (error.status === 400) {
    console.error("Invalid parameters:", error.body);
  } else {
    console.error("Generation failed:", error.message);
  }
}
```

## Cost Optimization

1. **Use shorter durations** for testing
2. **Lower resolution** for iterations
3. **Runway Gen-3 Turbo** for quick previews
4. **Kling Pro** only for final renders
5. **Batch process** during off-peak hours

## Workflow Example

```typescript
// Production workflow: iterate fast, render high quality
async function productionWorkflow(prompt: string) {
  // 1. Quick preview with fast model
  const preview = await fal.subscribe("fal-ai/runway/gen3/turbo", {
    input: { prompt, duration: 5, ratio: "16:9" }
  });
  console.log("Preview:", preview.video.url);

  // 2. Review and refine prompt...

  // 3. Final render with Kling Pro
  const final = await fal.subscribe("fal-ai/kling-video/v2.6/pro", {
    input: {
      prompt,
      duration: 10,
      aspect_ratio: "16:9",
      cfg_scale: 0.5
    }
  });

  return final;
}
```
