# Modal Setup Command

Initialize a Modal project with proper structure, configuration, and best practices.

## Task

Set up a new Modal project with the following:

1. **Project Structure Analysis**
   - Determine project type (API server, batch processing, ML inference, scheduled tasks)
   - Identify existing dependencies and requirements
   - Check for existing Modal configuration

2. **Create Core Files**
   - Main Modal app file with proper structure
   - Requirements/dependencies file
   - Environment configuration

3. **Configure Based on Use Case**
   - For ML/AI: GPU configuration, model loading patterns
   - For APIs: Web endpoint setup with FastAPI
   - For Batch: Volume configuration, parallel processing
   - For Scheduled: Cron/Period configuration

4. **Best Practices Implementation**
   - Use `@modal.enter()` for initialization
   - Use `uv_pip_install` for faster builds
   - Set appropriate timeouts and retries
   - Configure secrets management

## Project Structure Template

```
project/
├── modal_app.py          # Main Modal application
├── requirements.txt      # Python dependencies
├── .env.example          # Environment variables template
├── src/                  # Source code
│   └── __init__.py
└── README.md             # Project documentation
```

## Questions to Ask

1. What type of Modal application? (API, batch processing, ML inference, scheduled tasks)
2. Do you need GPU support? If yes, what workload type?
3. What Python packages are required?
4. Do you need persistent storage (Volumes)?
5. Are there secrets/credentials to manage?

## Example Starter Code

```python
import modal

app = modal.App("my-app")

image = (
    modal.Image.debian_slim(python_version="3.11")
    .uv_pip_install("fastapi", "uvicorn")
)

@app.function(image=image)
def hello(name: str = "World") -> str:
    return f"Hello, {name}!"

@app.local_entrypoint()
def main():
    result = hello.remote()
    print(result)
```

## CLI Commands to Run

```bash
# Install Modal CLI
pip install modal

# Authenticate (opens browser)
modal setup

# Test the app
modal run modal_app.py

# Start development server
modal serve modal_app.py
```

## Checklist

- [ ] Modal CLI installed and authenticated
- [ ] App file created with proper structure
- [ ] Dependencies specified
- [ ] Secrets configured (if needed)
- [ ] Volumes configured (if needed)
- [ ] Local test successful with `modal run`
