# fal.ai Text-to-Video Workflow Examples

Production workflow and batch-generation examples for fal.ai text-to-video models, including fast preview iteration with Runway Turbo and final rendering with Kling Pro. SKILL.md keeps model selection, prompt engineering, parameter reference, and best practices.

## Workflow Examples

### Production Workflow

```typescript
// 1. Fast preview with Runway Turbo
const preview = await fal.subscribe("fal-ai/runway-gen3/turbo/text-to-video", {
  input: {
    prompt: "A woman walking through a rainy city street at night",
    duration: 5,
    ratio: "16:9"
  }
});

console.log("Preview:", preview.video.url);
// Review and refine prompt...

// 2. Final render with Kling Pro
const final = await fal.subscribe("fal-ai/kling-video/v2.6/pro/text-to-video", {
  input: {
    prompt: "A stylish woman walking confidently through a rainy Tokyo street at night, neon reflections on wet pavement, cinematic lighting, slow motion, tracking shot",
    duration: "10",
    aspect_ratio: "16:9"
  }
});

console.log("Final:", final.video.url);
```

### Batch Generation

```typescript
const prompts = [
  "A sunrise over mountains",
  "A sunset over the ocean",
  "A storm rolling in"
];

const videos = await Promise.all(
  prompts.map(prompt =>
    fal.subscribe("fal-ai/ltx-video", {
      input: { prompt, aspect_ratio: "16:9" }
    })
  )
);

videos.forEach((v, i) => console.log(`Video ${i + 1}: ${v.video.url}`));
```
