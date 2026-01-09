# fal.ai Real-time WebSocket API Reference

## Overview

fal.ai provides WebSocket-based real-time connections for streaming inference, enabling low-latency interactive applications like live image generation, real-time video processing, and interactive AI chat.

## JavaScript Client Setup

```javascript
import { fal } from "@fal-ai/client";

// Configure client
fal.config({
  credentials: process.env.FAL_KEY
});

// Create real-time connection
const connection = fal.realtime.connect("fal-ai/flux-lora-realtime", {
  connectionKey: "unique-session-id",
  throttleInterval: 64, // ms between sends (default: 64)

  onResult: (result) => {
    console.log("Generated:", result.images[0].url);
  },

  onError: (error) => {
    console.error("Stream error:", error.message);
  },

  onOpen: () => {
    console.log("WebSocket connected");
  },

  onClose: () => {
    console.log("WebSocket disconnected");
  }
});

// Send generation request
connection.send({
  prompt: "a serene mountain landscape at sunset",
  image_size: "landscape_16_9",
  num_inference_steps: 4,
  guidance_scale: 3.5
});

// Close when done
connection.close();
```

## Python Real-time Client

```python
import fal_client
import asyncio

async def realtime_generation():
    """Stream real-time image generations."""

    async def on_result(result):
        print(f"Generated: {result['images'][0]['url']}")

    async def on_error(error):
        print(f"Error: {error}")

    # Connect to real-time endpoint
    connection = await fal_client.realtime.connect(
        "fal-ai/flux-lora-realtime",
        on_result=on_result,
        on_error=on_error,
        throttle_interval=0.064  # 64ms
    )

    # Send requests
    await connection.send({
        "prompt": "cyberpunk cityscape with neon lights",
        "image_size": "landscape_16_9"
    })

    # Keep connection alive
    await asyncio.sleep(5)
    await connection.close()

asyncio.run(realtime_generation())
```

## Connection Configuration

### throttleInterval
Controls rate limiting for input sends:
- Default: 64ms (roughly 15 requests/second)
- Minimum recommended: 32ms
- Use higher values for rate-limited scenarios

### connectionKey
Unique identifier for the connection session:
- Use for reconnection scenarios
- Helps with debugging and logging
- Required for multi-user applications

## Event Handlers

| Handler | Purpose | Required |
|---------|---------|----------|
| onResult | Receives generation results | Yes |
| onError | Handles errors and failures | Recommended |
| onOpen | Connection established callback | Optional |
| onClose | Connection closed callback | Optional |

## Real-time Model Endpoints

### Image Generation
- `fal-ai/flux-lora-realtime` - FLUX with LoRA, 4-step generation
- `fal-ai/lcm-sd15-i2i` - LCM for fast image-to-image
- `fal-ai/sdxl-turbo-realtime` - SDXL Turbo for interactive generation

### Video Streaming (Preview)
- `fal-ai/ltx-video-realtime` - LTX Video streaming preview
- `fal-ai/cogvideox-realtime` - CogVideoX streaming

## Error Handling

```javascript
const connection = fal.realtime.connect("fal-ai/flux-lora-realtime", {
  onError: (error) => {
    switch (error.code) {
      case "RATE_LIMITED":
        // Increase throttleInterval
        break;
      case "CONNECTION_LOST":
        // Implement reconnection logic
        break;
      case "INVALID_INPUT":
        // Validate input parameters
        break;
      default:
        console.error("Unknown error:", error);
    }
  }
});
```

## Best Practices

1. **Connection Management**
   - Reuse connections for multiple requests
   - Close connections when no longer needed
   - Implement reconnection logic for production

2. **Rate Limiting**
   - Start with default throttleInterval (64ms)
   - Increase if receiving rate limit errors
   - Monitor connection health

3. **Error Recovery**
   - Always implement onError handler
   - Log errors for debugging
   - Gracefully degrade on connection loss

4. **Resource Cleanup**
   - Call `connection.close()` when done
   - Handle page unload events in browsers
   - Clean up connections on component unmount (React)
