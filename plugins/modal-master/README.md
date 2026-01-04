# Modal Master Plugin

Comprehensive Modal.com serverless cloud platform expertise for Claude Code. GPU-accelerated Python functions, web endpoints, scheduled tasks, and AI/ML deployments with automatic scaling and per-second billing.

## Features

- **modal-expert Agent**: Expert guidance for all Modal.com features
- **GPU Configuration**: Optimize GPU selection, fallbacks, and costs
- **Web Endpoints**: FastAPI, Flask, Django, WebSocket support
- **Scheduling**: Cron jobs and periodic tasks with timezone support
- **Storage**: Volumes, secrets, Dict, and Queue primitives
- **Deployment**: CI/CD workflows and environment management
- **Debugging**: Troubleshooting common Modal issues

## Installation

### From Claude Plugin Marketplace (Recommended)

```bash
claude plugin add modal-master
```

### From GitHub

```bash
claude plugin add https://github.com/anthropics/claude-code-marketplace/tree/main/plugins/modal-master
```

### Manual Installation

Clone and add to your Claude Code plugins directory:

```bash
git clone https://github.com/anthropics/claude-code-marketplace.git
cd claude-code-marketplace/plugins/modal-master
```

## Usage

### Agent

Invoke the Modal expert agent for comprehensive guidance:

```
@modal-expert Help me set up an LLM inference server with vLLM
```

```
@modal-expert What GPU should I use for fine-tuning a 7B model?
```

### Slash Commands

| Command | Description |
|---------|-------------|
| `/modal-setup` | Initialize a Modal project with proper structure |
| `/modal-deploy` | Deploy Modal application with CI/CD setup |
| `/modal-gpu` | Configure GPU functions with optimization |
| `/modal-web` | Create web endpoints (FastAPI, ASGI, WSGI) |
| `/modal-schedule` | Set up scheduled/cron functions |
| `/modal-debug` | Debug Modal issues and errors |

## Quick Start

### 1. Install Modal CLI

```bash
pip install modal
modal setup
```

### 2. Create Your First App

```python
import modal

app = modal.App("hello-world")

@app.function()
def hello(name: str = "World") -> str:
    return f"Hello, {name}!"

@app.local_entrypoint()
def main():
    print(hello.remote("Modal"))
```

### 3. Run and Deploy

```bash
# Test locally
modal run app.py

# Deploy to production
modal deploy app.py
```

## Example Use Cases

### GPU-Accelerated ML Inference

```python
@app.cls(gpu="A100", container_idle_timeout=300)
class LLMServer:
    @modal.enter()
    def load(self):
        from vllm import LLM
        self.llm = LLM(model="meta-llama/Llama-2-7b-chat-hf")

    @modal.method()
    def generate(self, prompt: str):
        return self.llm.generate([prompt])
```

### Web API Endpoint

```python
from fastapi import FastAPI

web_app = FastAPI()

@web_app.post("/predict")
def predict(text: str):
    return {"result": process(text)}

@app.function()
@modal.asgi_app()
def api():
    return web_app
```

### Scheduled Job

```python
@app.function(
    schedule=modal.Cron("0 6 * * *", timezone="America/New_York")
)
def daily_job():
    run_etl_pipeline()
```

### Batch Processing

```python
@app.function()
def process_item(item):
    return transform(item)

@app.local_entrypoint()
def main():
    items = list(range(1000))
    results = list(process_item.map(items))
```

## GPU Reference

| GPU | Memory | Best For | ~Cost/hr |
|-----|--------|----------|----------|
| T4 | 16 GB | Small inference | $0.59 |
| L4 | 24 GB | Medium inference | $0.80 |
| A10G | 24 GB | Inference/fine-tuning | $1.10 |
| L40S | 48 GB | Heavy inference | $1.50 |
| A100-40GB | 40 GB | Training | $2.00 |
| A100-80GB | 80 GB | Large models | $3.00 |
| H100 | 80 GB | Cutting-edge | $5.00 |
| B200 | 180+ GB | Latest gen | $6.25 |

## Best Practices

1. **Use `@modal.enter()`** for model loading to reduce request latency
2. **Use `uv_pip_install`** for 10-100x faster package installation
3. **Use GPU fallbacks** like `gpu=["H100", "A100", "any"]` for availability
4. **Download models during image build**, not at runtime
5. **Set appropriate `container_idle_timeout`** to balance cost vs cold starts
6. **Use environments** (dev/staging/prod) for proper separation
7. **Test with `modal run`** before deploying with `modal deploy`

## Resources

- [Modal Documentation](https://modal.com/docs)
- [Modal Examples](https://github.com/modal-labs/modal-examples)
- [Modal Pricing](https://modal.com/pricing)
- [Modal Discord](https://discord.com/invite/modal)
- [Modal Blog](https://modal.com/blog)

## Requirements

- Python 3.8+
- Modal CLI (`pip install modal`)
- Modal account (free tier available)

## License

MIT License

## Contributing

Contributions welcome! Please submit issues and pull requests to the [Claude Plugin Marketplace repository](https://github.com/anthropics/claude-code-marketplace).
