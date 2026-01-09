# fal.ai Video Generation Reference

## Overview

fal.ai provides access to the latest video generation models including Veo 3, Sora 2, Kling 2.6, and open-source alternatives like LTX Video and CogVideoX.

## Model Comparison (2025)

| Model | Max Duration | Resolution | Native Audio | Price/sec | Best For |
|-------|-------------|------------|--------------|-----------|----------|
| Veo 3.1 | 8s | 1080p | Yes | ~$0.40 | Cinematic quality |
| Sora 2 Pro | 20s | 1080p | No | ~$0.35 | Long-form content |
| GPT-Image 1.5 | 5s | 1080p | No | ~$0.25 | Creative animation |
| Kling 2.6 Pro | 10s | 1080p | Yes | ~$0.15 | Cost-effective |
| LTX Video | 5s | 720p | No | ~$0.07 | Budget option |
| CogVideoX | 6s | 720p | No | ~$0.08 | Open-source |

## Text-to-Video Generation

### Kling 2.6 Pro (Recommended)

```javascript
import { fal } from "@fal-ai/client";

const result = await fal.subscribe("fal-ai/kling-video/v2.6/pro/text-to-video", {
  input: {
    prompt: "A majestic eagle soaring through golden sunset clouds, cinematic slow motion",
    negative_prompt: "blurry, low quality, distorted",
    duration: "10",          // 5 or 10 seconds
    aspect_ratio: "16:9",    // 16:9, 9:16, 1:1
    cfg_scale: 0.5,          // Creativity (0.0-1.0)
  },
  logs: true,
  onQueueUpdate: (update) => {
    if (update.status === "IN_PROGRESS") {
      console.log("Progress:", update.logs);
    }
  }
});

console.log("Video URL:", result.data.video.url);
```

### Veo 3.1 (Premium Quality)

```javascript
const result = await fal.subscribe("fal-ai/veo-3.1", {
  input: {
    prompt: "Cinematic drone shot flying through a mystical forest, rays of sunlight filtering through ancient trees",
    aspect_ratio: "16:9",
    duration: 8,
    generate_audio: true  // Native audio generation
  }
});

console.log("Video:", result.data.video.url);
console.log("Audio:", result.data.audio?.url);
```

### Sora 2 (Long-form)

```javascript
const result = await fal.subscribe("fal-ai/sora-2-pro", {
  input: {
    prompt: "A timelapse of a flower blooming from seed to full bloom, macro photography",
    duration: 20,
    resolution: "1080p"
  }
});
```

## Image-to-Video Generation

### Starting from FLUX Image

```javascript
// Step 1: Generate base image with FLUX.2
const imageResult = await fal.subscribe("fal-ai/flux-pro/v1.1", {
  input: {
    prompt: "Portrait of a woman with flowing hair, studio lighting",
    image_size: "landscape_16_9",
    num_inference_steps: 28
  }
});

const baseImageUrl = imageResult.data.images[0].url;

// Step 2: Animate with Kling 2.6
const videoResult = await fal.subscribe("fal-ai/kling-video/v2.6/pro/image-to-video", {
  input: {
    prompt: "Hair flowing gently in the wind, subtle smile",
    image_url: baseImageUrl,
    duration: "5"
  }
});

console.log("Video:", videoResult.data.video.url);
```

### LTX Video (Budget Option)

```python
import fal_client

result = fal_client.subscribe(
    "fal-ai/ltx-video/image-to-video",
    arguments={
        "prompt": "Gentle camera push-in, subtle movement",
        "image_url": "https://example.com/my-image.jpg",
        "num_frames": 97,  # ~4 seconds at 24fps
        "fps": 24
    }
)

print(f"Video: {result['video']['url']}")
```

## Video-to-Video (Style Transfer)

```javascript
const result = await fal.subscribe("fal-ai/cogvideox-5b/video-to-video", {
  input: {
    prompt: "Convert to anime style, vibrant colors",
    video_url: "https://example.com/original.mp4",
    strength: 0.7  // How much to modify (0.0-1.0)
  }
});
```

## Native Audio Generation

Models with native audio support generate synchronized soundscapes:

```javascript
// Veo 3 with native audio
const result = await fal.subscribe("fal-ai/veo-3", {
  input: {
    prompt: "Ocean waves crashing on rocky shore at sunset, seagulls flying",
    duration: 8,
    generate_audio: true  // Enable native audio
  }
});

// Video has synchronized ocean/seagull sounds
console.log("Video with audio:", result.data.video.url);
```

```javascript
// Kling 2.6 with native audio
const result = await fal.subscribe("fal-ai/kling-video/v2.6/pro/text-to-video", {
  input: {
    prompt: "Thunderstorm with lightning over a city skyline",
    duration: "10",
    enable_audio: true  // Native thunder/rain sounds
  }
});
```

## Python Queue-based Execution

For long-running video generation:

```python
import fal_client
import time

# Submit job to queue
handler = fal_client.submit(
    "fal-ai/veo-3",
    arguments={
        "prompt": "Astronaut walking on Mars surface",
        "duration": 8,
        "generate_audio": True
    }
)

print(f"Request ID: {handler.request_id}")

# Poll for status
while True:
    status = fal_client.status("fal-ai/veo-3", handler.request_id)
    print(f"Status: {status['status']}")

    if status["status"] == "COMPLETED":
        result = fal_client.result("fal-ai/veo-3", handler.request_id)
        print(f"Video: {result['video']['url']}")
        break
    elif status["status"] == "FAILED":
        print(f"Error: {status.get('error')}")
        break

    time.sleep(5)
```

## Webhook Notifications

For production workflows:

```javascript
const result = await fal.queue.submit("fal-ai/kling-video/v2.6/pro/text-to-video", {
  input: {
    prompt: "Cinematic scene of a spaceship landing",
    duration: "10"
  },
  webhookUrl: "https://your-server.com/webhook"
});

// Your webhook receives:
// {
//   "request_id": "abc123",
//   "status": "COMPLETED",
//   "result": { "video": { "url": "..." } }
// }
```

## Cost Optimization

1. **Start with LTX/CogVideoX** for prototyping (~$0.07-0.08/sec)
2. **Use Kling 2.6** for production balance (~$0.15/sec)
3. **Reserve Veo 3/Sora 2** for final renders (~$0.35-0.40/sec)
4. **Use shorter durations** when possible (5s vs 10s)
5. **Generate image first** with FLUX, then animate - often cheaper
