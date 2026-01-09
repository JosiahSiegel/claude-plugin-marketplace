# Modal @modal.batched for Dynamic Batching

## Overview

The `@modal.batched` decorator enables automatic request batching for ML inference, combining multiple inputs into efficient batch operations.

## Basic Usage

```python
import modal

app = modal.App("batched-inference")

@app.cls(gpu="A100")
class BatchedModel:
    @modal.enter()
    def load(self):
        import torch
        self.model = load_model()
        self.model.eval()

    @modal.batched(max_batch_size=32, wait_ms=100)
    @modal.method()
    def predict(self, inputs: list[str]) -> list[str]:
        """
        Receives a batch of inputs automatically collected by Modal.
        Returns a list of outputs (one per input).
        """
        # Batch inference
        results = self.model.batch_predict(inputs)
        return results
```

## Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `max_batch_size` | Maximum items to batch together | Required |
| `wait_ms` | Max wait time to collect batch | 100 |

## How It Works

1. Client calls `predict(single_item)` multiple times
2. Modal collects requests up to `max_batch_size` or `wait_ms`
3. Your function receives a batch (list) of inputs
4. Your function returns a list of outputs
5. Modal distributes outputs back to individual callers

```
Client 1: predict("a") ──┐
Client 2: predict("b") ──┼──► batched predict(["a","b","c"]) ──► ["result_a","result_b","result_c"]
Client 3: predict("c") ──┘                                            │
                                                                      │
Client 1: receives "result_a" ◄───────────────────────────────────────┘
Client 2: receives "result_b" ◄───────────────────────────────────────┘
Client 3: receives "result_c" ◄───────────────────────────────────────┘
```

## Complete Example: LLM Inference

```python
import modal

app = modal.App("llm-batched")

image = (
    modal.Image.debian_slim(python_version="3.11")
    .pip_install("torch", "transformers", "accelerate")
)

@app.cls(
    gpu="A100",
    image=image,
    container_idle_timeout=300,
)
class LLMServer:

    @modal.enter()
    def load_model(self):
        from transformers import AutoModelForCausalLM, AutoTokenizer
        import torch

        model_id = "mistralai/Mistral-7B-Instruct-v0.2"

        self.tokenizer = AutoTokenizer.from_pretrained(model_id)
        self.tokenizer.pad_token = self.tokenizer.eos_token

        self.model = AutoModelForCausalLM.from_pretrained(
            model_id,
            torch_dtype=torch.float16,
            device_map="auto",
        )

    @modal.batched(max_batch_size=16, wait_ms=50)
    @modal.method()
    def generate(self, prompts: list[str]) -> list[str]:
        """Batch generate responses for multiple prompts"""
        import torch

        # Tokenize batch
        inputs = self.tokenizer(
            prompts,
            return_tensors="pt",
            padding=True,
            truncation=True,
            max_length=512,
        ).to("cuda")

        # Generate
        with torch.no_grad():
            outputs = self.model.generate(
                **inputs,
                max_new_tokens=256,
                do_sample=True,
                temperature=0.7,
            )

        # Decode
        responses = self.tokenizer.batch_decode(
            outputs, skip_special_tokens=True
        )

        return responses


# Usage (clients call with single items)
@app.local_entrypoint()
def main():
    model = LLMServer()

    # These will be automatically batched
    prompts = [
        "What is Python?",
        "Explain machine learning",
        "How does a GPU work?",
    ]

    # Parallel calls - batched automatically
    results = list(model.generate.map(prompts))

    for prompt, result in zip(prompts, results):
        print(f"Q: {prompt}")
        print(f"A: {result}\n")
```

## Batched Image Processing

```python
@app.cls(gpu="T4")
class ImageProcessor:

    @modal.enter()
    def load(self):
        from transformers import CLIPProcessor, CLIPModel

        self.processor = CLIPProcessor.from_pretrained("openai/clip-vit-base-patch32")
        self.model = CLIPModel.from_pretrained("openai/clip-vit-base-patch32").cuda()

    @modal.batched(max_batch_size=64, wait_ms=100)
    @modal.method()
    def embed_images(self, image_bytes_list: list[bytes]) -> list[list[float]]:
        """Batch image embedding"""
        from PIL import Image
        import io
        import torch

        # Decode images
        images = [Image.open(io.BytesIO(b)) for b in image_bytes_list]

        # Process batch
        inputs = self.processor(images=images, return_tensors="pt").to("cuda")

        with torch.no_grad():
            embeddings = self.model.get_image_features(**inputs)

        return embeddings.cpu().numpy().tolist()
```

## Tuning Batch Parameters

### High Throughput (Maximize GPU Utilization)

```python
@modal.batched(max_batch_size=64, wait_ms=200)
@modal.method()
def high_throughput(self, inputs: list):
    # Larger batches, longer wait
    pass
```

### Low Latency (Minimize Response Time)

```python
@modal.batched(max_batch_size=8, wait_ms=10)
@modal.method()
def low_latency(self, inputs: list):
    # Smaller batches, shorter wait
    pass
```

### Balanced

```python
@modal.batched(max_batch_size=32, wait_ms=50)
@modal.method()
def balanced(self, inputs: list):
    pass
```

## Combining with @modal.concurrent

For handling many requests while batching:

```python
@app.cls(gpu="A100")
class Server:

    @modal.concurrent(max_inputs=100)
    @modal.batched(max_batch_size=32)
    @modal.method()
    def process(self, items: list):
        # Container handles 100 concurrent callers
        # Requests batched into groups of 32
        return batch_process(items)
```

## Best Practices

1. **Match batch size to GPU memory** - Larger batches use more VRAM
2. **Set `wait_ms` based on latency requirements** - Lower = faster response, smaller batches
3. **Input/output must be lists** - Function receives list, returns list
4. **Same length requirement** - Output list must match input list length
5. **Use with GPU workloads** - Batching shines for GPU inference
6. **Monitor throughput** - Adjust parameters based on real traffic

## When to Use Batching

| Scenario | Use Batching? | Reason |
|----------|---------------|--------|
| GPU inference | Yes | GPU efficient with batches |
| LLM generation | Yes | Transformers batch well |
| Image processing | Yes | CNN batching improves throughput |
| CPU-bound work | Maybe | Less benefit than GPU |
| I/O-bound work | No | No batching benefit |
| Single requests | No | No batching opportunity |
