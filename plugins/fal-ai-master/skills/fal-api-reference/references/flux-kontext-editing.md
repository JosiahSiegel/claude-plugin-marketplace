# FLUX Kontext Image Editing Reference

## Overview

FLUX Kontext is an instruction-based image editing model that modifies images using natural language commands without requiring masks or manual region selection. It understands context and can make precise edits while preserving unrelated areas.

## Basic Usage

### JavaScript

```javascript
import { fal } from "@fal-ai/client";

const result = await fal.subscribe("fal-ai/flux-kontext", {
  input: {
    prompt: "Change the car color to red",
    image_url: "https://example.com/blue-car.jpg",
    guidance_scale: 7.5,
    num_inference_steps: 28
  }
});

console.log("Edited image:", result.data.images[0].url);
```

### Python

```python
import fal_client

result = fal_client.subscribe(
    "fal-ai/flux-kontext",
    arguments={
        "prompt": "Add sunglasses to the person",
        "image_url": "https://example.com/portrait.jpg",
        "guidance_scale": 7.5,
        "num_inference_steps": 28
    }
)

print(f"Edited: {result['images'][0]['url']}")
```

## Edit Types

### Color Changes
```javascript
// Change object colors
{ prompt: "Make the dress blue instead of red" }
{ prompt: "Change hair color to blonde" }
{ prompt: "Turn the sky to sunset orange" }
```

### Adding Elements
```javascript
// Add objects or features
{ prompt: "Add a hat to the person" }
{ prompt: "Put a coffee cup on the table" }
{ prompt: "Add mountains in the background" }
```

### Removing Elements
```javascript
// Remove unwanted objects
{ prompt: "Remove the person in the background" }
{ prompt: "Remove text/watermark from the image" }
{ prompt: "Remove the car from the street" }
```

### Style Transfer
```javascript
// Apply artistic styles
{ prompt: "Convert to watercolor painting style" }
{ prompt: "Make it look like a vintage photograph" }
{ prompt: "Apply cyberpunk aesthetic" }
```

### Background Changes
```javascript
// Modify backgrounds
{ prompt: "Change the background to a beach sunset" }
{ prompt: "Replace the sky with a starry night" }
{ prompt: "Blur the background for portrait effect" }
```

### Clothing/Appearance
```javascript
// Modify clothing and appearance
{ prompt: "Change the outfit to a business suit" }
{ prompt: "Add a winter jacket" }
{ prompt: "Make the person look older" }
```

## Advanced Parameters

```javascript
const result = await fal.subscribe("fal-ai/flux-kontext", {
  input: {
    prompt: "Your edit instruction",
    image_url: "https://example.com/image.jpg",

    // Guidance scale: how closely to follow the prompt
    // Higher = more literal, Lower = more creative
    guidance_scale: 7.5,  // Default: 7.5, Range: 1-20

    // Inference steps: quality vs speed tradeoff
    num_inference_steps: 28,  // Default: 28, Range: 1-50

    // Output format
    output_format: "png",  // "png" or "jpeg"

    // Seed for reproducibility
    seed: 12345  // Optional
  }
});
```

## Multi-Step Editing Pipeline

```javascript
// Step 1: Initial edit
const step1 = await fal.subscribe("fal-ai/flux-kontext", {
  input: {
    prompt: "Change the background to a modern office",
    image_url: originalImageUrl
  }
});

// Step 2: Refine the edit
const step2 = await fal.subscribe("fal-ai/flux-kontext", {
  input: {
    prompt: "Add a laptop on the desk",
    image_url: step1.data.images[0].url
  }
});

// Step 3: Final touches
const final = await fal.subscribe("fal-ai/flux-kontext", {
  input: {
    prompt: "Improve lighting to look more professional",
    image_url: step2.data.images[0].url
  }
});
```

## Best Practices

### Prompt Writing

**Good prompts:**
- "Change the car from blue to red" (specific)
- "Add a subtle smile to the person's face" (precise)
- "Replace the cloudy sky with clear blue sky" (clear target)

**Avoid:**
- "Make it better" (too vague)
- "Fix the image" (no specific instruction)
- "Change everything" (too broad)

### Preserving Quality

1. **Use high-resolution source images** (1024x1024 or higher)
2. **Set appropriate inference steps** (28 for balanced, 40+ for quality)
3. **Adjust guidance scale** based on edit type:
   - Color changes: 5-7 (more creative)
   - Adding objects: 7-10 (balanced)
   - Precise edits: 10-15 (more literal)

### Handling Complex Edits

For complex edits, break them into steps:

```javascript
// Instead of: "Add sunglasses and change hair to blonde and add a hat"

// Do this:
const step1 = await edit("Add sunglasses", imageUrl);
const step2 = await edit("Change hair color to blonde", step1.url);
const step3 = await edit("Add a stylish hat", step2.url);
```

## Comparison with Other Models

| Feature | FLUX Kontext | SDXL Inpainting | DALL-E 3 |
|---------|-------------|-----------------|----------|
| Mask required | No | Yes | No |
| Natural language | Yes | Limited | Yes |
| Context understanding | Excellent | Good | Good |
| Fine control | Good | Excellent | Limited |
| Price/edit | ~$0.03 | ~$0.02 | ~$0.04 |

## Error Handling

```javascript
try {
  const result = await fal.subscribe("fal-ai/flux-kontext", {
    input: {
      prompt: "Your edit",
      image_url: imageUrl
    }
  });
} catch (error) {
  if (error.message.includes("NSFW")) {
    console.error("Content flagged as inappropriate");
  } else if (error.message.includes("invalid image")) {
    console.error("Could not process image - check URL/format");
  } else {
    console.error("Edit failed:", error.message);
  }
}
```

## Use Cases

1. **E-commerce**: Product color variations, background removal
2. **Marketing**: Ad creative variations, A/B testing visuals
3. **Social Media**: Quick edits, style applications
4. **Photography**: Retouching, background replacement
5. **Design**: Concept iteration, mood board generation
