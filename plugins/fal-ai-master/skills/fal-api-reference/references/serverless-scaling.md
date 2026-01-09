# fal.ai Serverless Scaling Configuration

## Overview

fal.ai's serverless platform (fal.App) provides auto-scaling infrastructure for custom AI models with GPU support, configurable concurrency, and cost optimization features.

## Basic Serverless App

```python
import fal

class TextToImage(fal.App, keep_alive=300):
    """Custom image generation model."""

    machine_type = "GPU-A100"
    requirements = ["torch", "diffusers", "transformers"]

    def setup(self):
        """Load model on cold start."""
        import torch
        from diffusers import StableDiffusionXLPipeline

        self.pipe = StableDiffusionXLPipeline.from_pretrained(
            "stabilityai/stable-diffusion-xl-base-1.0",
            torch_dtype=torch.float16,
            use_safetensors=True
        ).to("cuda")

    @fal.endpoint("/generate")
    def generate(self, prompt: str, steps: int = 30) -> dict:
        """Generate image from prompt."""
        image = self.pipe(prompt, num_inference_steps=steps).images[0]

        # Save and return URL
        url = self.save_image(image)
        return {"image_url": url}
```

## Machine Types and Pricing (2025)

| Machine Type | GPU | VRAM | Cost/sec | Use Case |
|-------------|-----|------|----------|----------|
| GPU-T4 | NVIDIA T4 | 16GB | $0.000164 | Small models, inference |
| GPU-A10G | NVIDIA A10G | 24GB | $0.000306 | Medium models, SDXL |
| GPU-A100 | NVIDIA A100 | 40GB | $0.000556 | Large models, training |
| GPU-A100-80GB | NVIDIA A100 | 80GB | $0.000833 | 70B models |
| GPU-H100 | NVIDIA H100 | 80GB | $0.001389 | Maximum performance |
| GPU-H200 | NVIDIA H200 | 141GB | $0.001389 | Largest models |
| GPU-B200 | NVIDIA B200 | 180GB+ | $0.001736 | Next-gen workloads |

## Scaling Configuration

### keep_alive
Time in seconds to keep container warm after last request:

```python
class MyModel(fal.App, keep_alive=300):  # 5 minutes
    pass
```

- Default: 60 seconds
- Set to 0 for immediate scale-to-zero
- Higher values = lower cold start latency, higher cost

### min_concurrency / max_concurrency
Control parallel request handling:

```python
class HighThroughput(fal.App):
    machine_type = "GPU-H100"
    min_concurrency = 2   # Always have 2 containers ready
    max_concurrency = 10  # Scale up to 10 containers
```

### num_gpus
Multi-GPU configuration for large models:

```python
class LargeModel(fal.App):
    machine_type = "GPU-H100"
    num_gpus = 4  # 4x H100 = 320GB VRAM
```

## Volume Mounts

Persistent storage for model weights and data:

```python
class ModelWithStorage(fal.App):
    machine_type = "GPU-A100"

    volumes = {
        "/models": fal.Volume("model-cache"),
        "/data": fal.Volume("user-data")
    }

    def setup(self):
        # Models persist across cold starts
        self.model = load_model("/models/my-model")
```

## Environment Variables and Secrets

```python
class SecureModel(fal.App):
    machine_type = "GPU-A10G"

    # Public environment variables
    env = {
        "MODEL_VERSION": "v2.0",
        "DEBUG": "false"
    }

    # Secrets (encrypted)
    secrets = ["HF_TOKEN", "API_KEY"]

    def setup(self):
        import os
        hf_token = os.environ["HF_TOKEN"]
        # Use token for private model access
```

## Production Patterns

### Health Checks

```python
class ProductionModel(fal.App):
    machine_type = "GPU-A100"

    @fal.endpoint("/health")
    def health(self) -> dict:
        """Health check endpoint."""
        return {
            "status": "healthy",
            "gpu_available": torch.cuda.is_available(),
            "model_loaded": hasattr(self, 'model')
        }
```

### Batched Processing

```python
class BatchProcessor(fal.App):
    machine_type = "GPU-H100"

    @fal.endpoint("/batch")
    def process_batch(self, items: list[str]) -> list[dict]:
        """Process multiple items efficiently."""
        results = []
        for item in items:
            result = self.process_single(item)
            results.append(result)
        return results
```

### Error Handling

```python
class RobustModel(fal.App):
    machine_type = "GPU-A100"

    @fal.endpoint("/generate")
    def generate(self, prompt: str) -> dict:
        try:
            result = self._generate(prompt)
            return {"success": True, "result": result}
        except torch.cuda.OutOfMemoryError:
            return {"success": False, "error": "GPU OOM - reduce input size"}
        except Exception as e:
            return {"success": False, "error": str(e)}
```

## Deployment Commands

```bash
# Deploy to fal.ai
fal deploy my_app.py

# Deploy with specific name
fal deploy my_app.py --name my-custom-model

# Check deployment status
fal list

# View logs
fal logs my-custom-model

# Delete deployment
fal delete my-custom-model
```

## Cost Optimization Tips

1. **Right-size GPU**: Use smallest GPU that fits your model
2. **Scale to zero**: Set `keep_alive=0` for infrequent workloads
3. **Batch requests**: Process multiple items per invocation
4. **Cache models**: Use volumes to avoid re-downloading
5. **Monitor usage**: Check fal.ai dashboard for optimization opportunities
