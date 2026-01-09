---
name: Deploy Model
description: Deploy custom ML models to fal.ai's serverless infrastructure with automatic scaling and GPU support
argument-hint: <app-file.py> [--gpu T4|A10G|A100|H100|H200|B200]
---

# Deploy Custom Model to fal Serverless

Deploy your own ML models to fal.ai's serverless infrastructure with automatic scaling and GPU support.

## What This Command Does

Guides you through deploying custom models to fal serverless, including:
- Setting up the fal.App structure
- Configuring GPU requirements
- Managing dependencies
- Handling persistent storage
- Setting up endpoints

## Steps

1. **Analyze Requirements**
   - Model type and size
   - GPU memory needs
   - Expected concurrency
   - Storage requirements

2. **Design App Structure**
   - Machine type selection
   - Endpoint definitions
   - Setup/teardown logic

3. **Generate Code**
   - Complete fal.App class
   - Deployment commands
   - Health checks

4. **Deploy and Monitor**
   - Deployment commands
   - Log access
   - Scaling configuration

## Quick Start Template

### Basic Model Deployment

```python
import fal
from pydantic import BaseModel

class PredictRequest(BaseModel):
    prompt: str
    max_tokens: int = 100

class PredictResponse(BaseModel):
    text: str
    tokens_used: int

class MyModel(fal.App):
    # Infrastructure configuration
    machine_type = "GPU-A100"
    num_gpus = 1
    requirements = [
        "torch>=2.0.0",
        "transformers>=4.35.0",
        "accelerate>=0.24.0"
    ]

    # Scaling configuration
    keep_alive = 300      # Keep warm for 5 minutes
    min_concurrency = 0   # Scale to zero when idle
    max_concurrency = 4   # Max concurrent requests

    def setup(self):
        """Called once when container starts - load model here"""
        import torch
        from transformers import AutoModelForCausalLM, AutoTokenizer

        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        self.tokenizer = AutoTokenizer.from_pretrained("model-name")
        self.model = AutoModelForCausalLM.from_pretrained(
            "model-name",
            torch_dtype=torch.float16,
            device_map="auto"
        )

    @fal.endpoint("/predict")
    def predict(self, request: PredictRequest) -> PredictResponse:
        """Main inference endpoint"""
        inputs = self.tokenizer(request.prompt, return_tensors="pt").to(self.device)

        outputs = self.model.generate(
            **inputs,
            max_new_tokens=request.max_tokens
        )

        text = self.tokenizer.decode(outputs[0], skip_special_tokens=True)

        return PredictResponse(
            text=text,
            tokens_used=len(outputs[0])
        )

    @fal.endpoint("/health")
    def health(self):
        """Health check endpoint"""
        return {"status": "healthy", "gpu": self.device}
```

### Deploy Command

```bash
# Install fal CLI
pip install fal

# Authenticate
fal auth login

# Deploy
fal deploy app.py::MyModel

# Deploy with specific configuration
fal deploy app.py::MyModel \
  --machine-type GPU-A100 \
  --num-gpus 1 \
  --min-concurrency 1 \
  --max-concurrency 4
```

## Machine Types

| Type | GPU | VRAM | Monthly Cost* | Best For |
|------|-----|------|---------------|----------|
| `CPU` | None | - | $ | Preprocessing |
| `GPU-T4` | NVIDIA T4 | 16GB | $$ | Development |
| `GPU-A10G` | NVIDIA A10G | 24GB | $$$ | Small models |
| `GPU-A100` | NVIDIA A100 | 40/80GB | $$$$ | Large models |
| `GPU-H100` | NVIDIA H100 | 80GB | $$$$$ | Cutting edge |
| `GPU-H200` | NVIDIA H200 | 141GB | $$$$$$ | Very large |
| `GPU-B200` | NVIDIA B200 | 192GB | $$$$$$$ | Frontier |

*Pricing is per-second for compute used

### GPU Selection Guide

```python
# Small models (< 7B params)
machine_type = "GPU-T4"

# Medium models (7B-13B params)
machine_type = "GPU-A10G"

# Large models (13B-70B params)
machine_type = "GPU-A100"
num_gpus = 1  # or 2 for very large

# Very large models (70B+ params)
machine_type = "GPU-H100"
num_gpus = 2  # or more
```

## Persistent Storage

```python
class ModelWithStorage(fal.App):
    machine_type = "GPU-A100"
    requirements = ["torch", "transformers"]

    # Define persistent volume
    volumes = {
        "/data": fal.Volume("model-cache")
    }

    def setup(self):
        import os
        from transformers import AutoModel

        cache_dir = "/data/models"
        os.makedirs(cache_dir, exist_ok=True)

        # Models persist across cold starts
        self.model = AutoModel.from_pretrained(
            "large-model-name",
            cache_dir=cache_dir
        )
```

## Secrets Management

```bash
# Set secrets via CLI
fal secrets set HF_TOKEN=hf_xxx OPENAI_KEY=sk_xxx

# List secrets
fal secrets list

# Delete secret
fal secrets delete HF_TOKEN
```

```python
import os

class SecureApp(fal.App):
    def setup(self):
        # Access secrets as environment variables
        hf_token = os.environ.get("HF_TOKEN")

        from huggingface_hub import login
        login(token=hf_token)

        # Load gated model
        self.model = AutoModel.from_pretrained("meta-llama/Llama-2-7b-hf")
```

## Advanced Patterns

### Image Generation App

```python
import fal
from pydantic import BaseModel
from typing import Optional

class GenerateRequest(BaseModel):
    prompt: str
    negative_prompt: Optional[str] = None
    width: int = 1024
    height: int = 1024
    steps: int = 28
    guidance_scale: float = 3.5
    seed: Optional[int] = None

class GenerateResponse(BaseModel):
    image_url: str
    seed: int

class ImageGenerator(fal.App):
    machine_type = "GPU-A100"
    num_gpus = 1
    requirements = [
        "torch",
        "diffusers",
        "transformers",
        "accelerate",
        "safetensors"
    ]
    keep_alive = 600
    max_concurrency = 2

    volumes = {
        "/data": fal.Volume("diffusion-cache")
    }

    def setup(self):
        import torch
        from diffusers import StableDiffusionXLPipeline

        self.pipe = StableDiffusionXLPipeline.from_pretrained(
            "stabilityai/stable-diffusion-xl-base-1.0",
            torch_dtype=torch.float16,
            cache_dir="/data/models"
        ).to("cuda")

        # Optimize for inference
        self.pipe.enable_model_cpu_offload()

    @fal.endpoint("/generate")
    def generate(self, request: GenerateRequest) -> GenerateResponse:
        import random

        seed = request.seed or random.randint(0, 2**32 - 1)
        generator = torch.Generator("cuda").manual_seed(seed)

        image = self.pipe(
            prompt=request.prompt,
            negative_prompt=request.negative_prompt,
            width=request.width,
            height=request.height,
            num_inference_steps=request.steps,
            guidance_scale=request.guidance_scale,
            generator=generator
        ).images[0]

        # Save and upload
        path = f"/tmp/output_{seed}.png"
        image.save(path)
        url = fal.upload_file(path)

        return GenerateResponse(image_url=url, seed=seed)
```

### Streaming Response

```python
import fal
from typing import Generator

class StreamingApp(fal.App):
    machine_type = "GPU-A100"
    requirements = ["torch", "transformers"]

    def setup(self):
        from transformers import AutoModelForCausalLM, AutoTokenizer, TextIteratorStreamer
        from threading import Thread

        self.tokenizer = AutoTokenizer.from_pretrained("model-name")
        self.model = AutoModelForCausalLM.from_pretrained("model-name")

    @fal.endpoint("/stream")
    def stream(self, prompt: str) -> Generator[str, None, None]:
        """Stream tokens as they're generated"""
        from transformers import TextIteratorStreamer
        from threading import Thread

        inputs = self.tokenizer(prompt, return_tensors="pt").to("cuda")

        streamer = TextIteratorStreamer(self.tokenizer, skip_prompt=True)

        generation_kwargs = {
            **inputs,
            "streamer": streamer,
            "max_new_tokens": 256
        }

        thread = Thread(target=self.model.generate, kwargs=generation_kwargs)
        thread.start()

        for text in streamer:
            yield text
```

### Multi-Endpoint App

```python
import fal
from pydantic import BaseModel

class TextRequest(BaseModel):
    text: str

class ImageRequest(BaseModel):
    image_url: str

class MultiModalApp(fal.App):
    machine_type = "GPU-A100"
    requirements = ["torch", "transformers", "Pillow"]

    def setup(self):
        # Load multiple models
        self.text_model = load_text_model()
        self.vision_model = load_vision_model()

    @fal.endpoint("/analyze-text")
    def analyze_text(self, request: TextRequest):
        return self.text_model(request.text)

    @fal.endpoint("/analyze-image")
    def analyze_image(self, request: ImageRequest):
        return self.vision_model(request.image_url)

    @fal.endpoint("/health")
    def health(self):
        return {"status": "ok"}
```

## Deployment Commands

```bash
# Deploy application
fal deploy app.py::MyModel

# View deployment status
fal list

# View logs
fal logs <app-id>

# Delete deployment
fal delete <app-id>

# Update deployment
fal deploy app.py::MyModel  # Redeploy with changes
```

## Calling Your Deployed Model

### JavaScript/TypeScript

```typescript
import { fal } from "@fal-ai/client";

fal.config({ credentials: process.env.FAL_KEY });

const result = await fal.subscribe("your-username/your-app", {
  input: {
    prompt: "Hello world",
    max_tokens: 100
  }
});
```

### Python

```python
import fal_client

result = fal_client.subscribe(
    "your-username/your-app",
    arguments={
        "prompt": "Hello world",
        "max_tokens": 100
    }
)
```

### cURL

```bash
curl -X POST "https://queue.fal.run/your-username/your-app/predict" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Hello world", "max_tokens": 100}'
```

## Best Practices

1. **Model Loading in setup()**
   - Load models once in setup(), not per request
   - Use persistent volumes for large model weights

2. **Error Handling**
   ```python
   @fal.endpoint("/predict")
   def predict(self, request: Request):
       try:
           result = self.model(request.input)
           return {"result": result}
       except RuntimeError as e:
           raise fal.HTTPException(500, str(e))
       except ValueError as e:
           raise fal.HTTPException(400, str(e))
   ```

3. **Resource Cleanup**
   ```python
   def teardown(self):
       """Called when container shuts down"""
       if hasattr(self, 'model'):
           del self.model
       torch.cuda.empty_cache()
   ```

4. **Concurrency Settings**
   - `min_concurrency=1` for always-warm endpoints
   - `max_concurrency` based on GPU memory per request
   - `keep_alive` to reduce cold starts

5. **Testing Locally**
   ```bash
   # Run locally before deploying
   fal run app.py::MyModel

   # Test endpoint
   curl http://localhost:8000/predict -d '{"prompt": "test"}'
   ```
