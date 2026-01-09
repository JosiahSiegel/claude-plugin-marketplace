---
name: Configure GPU
description: Configure GPU functions with optimal settings, fallbacks, and cost optimization
argument-hint: "<gpu-type: T4|L4|A10G|L40S|A100|H100|H200|B200> [workload: inference|training]"
---

# Modal GPU Command

Configure GPU functions with optimal settings, fallbacks, and cost optimization.

## Task

Help configure GPU-accelerated Modal functions with:

1. **GPU Selection**
   - Match GPU to workload requirements
   - Configure appropriate memory
   - Set up multi-GPU if needed

2. **Fallback Configuration**
   - Define GPU fallback chain
   - Handle availability issues

3. **Cost Optimization**
   - Choose cost-effective GPU for workload
   - Configure container idle timeout
   - Optimize cold start times

4. **Performance Patterns**
   - Use `@modal.enter()` for model loading
   - Configure concurrency appropriately
   - Set up warm containers

## Available GPUs

| GPU | Memory | Best For | ~Cost/hr |
|-----|--------|----------|----------|
| T4 | 16 GB | Small models, inference | $0.59 |
| L4 | 24 GB | Medium inference | $0.80 |
| A10G | 24 GB | Inference, fine-tuning | $1.10 |
| L40S | 48 GB | Heavy inference | $1.50 |
| A100-40GB | 40 GB | Training, large models | $2.00 |
| A100-80GB | 80 GB | Very large models | $3.00 |
| H100 | 80 GB | Cutting-edge training | $5.00 |
| H200 | 141 GB | Largest models | $5.00 |
| B200 | 180+ GB | Latest generation | $6.25 |

## GPU Configuration Examples

### Single GPU

```python
# Basic GPU
@app.function(gpu="T4")
def inference():
    pass

# Specific model
@app.function(gpu="A100")
def training():
    pass

# High memory variant
@app.function(gpu="A100-80GB")
def large_model():
    pass
```

### Multi-GPU

```python
# 2 GPUs
@app.function(gpu="A100:2")
def multi_gpu_training():
    import torch
    assert torch.cuda.device_count() == 2

# 4 GPUs for distributed training
@app.function(gpu="H100:4")
def distributed_training():
    pass
```

### GPU Fallbacks

```python
# Try H100 first, then A100, then any available
@app.function(gpu=["H100", "A100-80GB", "A100", "any"])
def flexible_workload():
    pass

# "any" = L4, A10G, or T4
@app.function(gpu="any")
def simple_inference():
    pass
```

## Optimal GPU Patterns

### ML Inference Server (Recommended Pattern)

```python
import modal

app = modal.App("inference-server")

image = (
    modal.Image.debian_slim(python_version="3.11")
    .uv_pip_install("torch", "transformers", "accelerate")
)

@app.cls(
    gpu="A10G",  # Good balance for inference
    image=image,
    container_idle_timeout=300,  # Keep warm for 5 minutes
    timeout=120,
)
class ModelServer:

    @modal.enter()
    def load_model(self):
        """Load model once when container starts"""
        import torch
        from transformers import AutoModelForCausalLM, AutoTokenizer

        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        self.model = AutoModelForCausalLM.from_pretrained(
            "microsoft/DialoGPT-medium"
        ).to(self.device)
        self.tokenizer = AutoTokenizer.from_pretrained(
            "microsoft/DialoGPT-medium"
        )

    @modal.method()
    def generate(self, prompt: str) -> str:
        inputs = self.tokenizer.encode(prompt, return_tensors="pt").to(self.device)
        outputs = self.model.generate(inputs, max_length=100)
        return self.tokenizer.decode(outputs[0])

    @modal.exit()
    def cleanup(self):
        """Clean up GPU memory"""
        import torch
        del self.model
        torch.cuda.empty_cache()
```

### Download Model During Build

```python
def download_model():
    from huggingface_hub import snapshot_download
    snapshot_download(
        "meta-llama/Llama-2-7b-chat-hf",
        local_dir="/models/llama"
    )

image = (
    modal.Image.debian_slim()
    .uv_pip_install("huggingface_hub", "torch", "transformers")
    .run_function(
        download_model,
        secrets=[modal.Secret.from_name("huggingface")]
    )
)
```

## Cost Optimization Tips

1. **Right-size GPU**: Don't use A100 for inference that fits on T4
2. **Use fallbacks**: Increase availability, potentially get better GPU
3. **Set `container_idle_timeout`**: Balance cold starts vs idle costs
4. **Use `@modal.enter()`**: Move model loading to warmup
5. **Monitor usage**: Check Modal dashboard for actual costs

## GPU Selection Guide

| Use Case | Recommended GPU |
|----------|-----------------|
| Small model inference (<7B) | T4 or L4 |
| Medium model inference (7B-13B) | A10G or L40S |
| Large model inference (13B-70B) | A100-80GB or H100 |
| Fine-tuning small models | A10G |
| Fine-tuning large models | A100-80GB |
| Distributed training | H100:4 or H100:8 |
| vLLM inference | A100 or H100 |
| Image generation (SD) | T4 or A10G |
| Video processing | T4 or L4 |

## Troubleshooting GPU Issues

1. **GPU not available**: Add fallbacks, try different regions
2. **CUDA out of memory**: Use larger GPU or reduce batch size
3. **Slow startup**: Move model loading to `@modal.enter()`
4. **High costs**: Review GPU selection, reduce idle timeout
5. **Inconsistent performance**: Pin to specific GPU type
