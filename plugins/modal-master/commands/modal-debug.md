---
name: Debug App
description: Debug Modal issues including container failures, GPU errors, and deployment problems
argument-hint: "[app-name-or-issue]"
---

# Modal Debug Command

Debug Modal issues including container failures, GPU errors, and deployment problems.

## Task

Help diagnose and resolve Modal issues:

1. **Error Identification**
   - Parse error messages
   - Identify error category
   - Determine root cause

2. **Common Issues**
   - Container startup failures
   - GPU availability issues
   - Memory errors
   - Timeout problems
   - Secret/volume access errors

3. **Debugging Tools**
   - Interactive shell
   - Log analysis
   - Local testing

## Debugging Commands

```bash
# Interactive shell in container
modal shell app.py

# Shell with GPU
modal shell app.py --gpu A100

# View logs
modal app logs my-app
modal app logs my-app --follow

# List deployments
modal app list

# Check function status
modal app show my-app
```

## Common Errors and Solutions

### 1. Container Startup Failures

**Error:** `Container failed to start`

**Causes:**
- Bad import at module level
- Missing dependencies
- Image build failure

**Solutions:**
```python
# Test image locally
modal shell app.py

# Check imports work
python -c "import your_module"

# Simplify image for debugging
image = modal.Image.debian_slim().pip_install("package")
```

### 2. Import Errors

**Error:** `ModuleNotFoundError: No module named 'xxx'`

**Solutions:**
```python
# Add missing package
image = modal.Image.debian_slim().pip_install("missing_package")

# Use uv for faster installs
image = modal.Image.debian_slim().uv_pip_install("package")

# For local modules
image = image.add_local_python_source("my_module")

# Or use include_source
@app.function(include_source=True)
def my_func():
    pass
```

### 3. GPU Not Available

**Error:** `GPU type xxx not available`

**Solutions:**
```python
# Add fallbacks
@app.function(gpu=["H100", "A100-80GB", "A100", "any"])
def gpu_func():
    pass

# Use "any" for flexibility
@app.function(gpu="any")  # L4, A10G, or T4
def inference():
    pass
```

### 4. CUDA Out of Memory

**Error:** `CUDA out of memory`

**Solutions:**
```python
# Use larger GPU
@app.function(gpu="A100-80GB")  # Instead of A100-40GB

# Reduce batch size in code
batch_size = 8  # Instead of 32

# Clear cache in exit handler
@modal.exit()
def cleanup(self):
    import torch
    torch.cuda.empty_cache()

# Use gradient checkpointing for training
model.gradient_checkpointing_enable()
```

### 5. Timeout Errors

**Error:** `Function timed out after xxx seconds`

**Solutions:**
```python
# Increase timeout
@app.function(timeout=3600)  # 1 hour
def long_running():
    pass

# For web endpoints (max 150s)
@app.function(timeout=150)
@modal.asgi_app()
def web():
    return app
```

### 6. Memory Errors

**Error:** `Out of memory` (CPU memory)

**Solutions:**
```python
# Increase memory
@app.function(memory=16384)  # 16 GB
def memory_intensive():
    pass

# Process in chunks
def process_large_file(path):
    for chunk in pd.read_csv(path, chunksize=10000):
        process(chunk)
```

### 7. Secret Not Found

**Error:** `Secret 'xxx' not found`

**Solutions:**
```bash
# Check secret exists
modal secret list

# Create secret
modal secret create my-secret KEY=value

# Check environment
MODAL_ENVIRONMENT=prod modal secret list
```

```python
# Verify secret name matches
@app.function(secrets=[modal.Secret.from_name("exact-name")])
def func():
    pass
```

### 8. Volume Not Found

**Error:** `Volume 'xxx' not found`

**Solutions:**
```bash
# Create volume
modal volume create my-volume

# List volumes
modal volume list
```

```python
# Create if missing
vol = modal.Volume.from_name("my-volume", create_if_missing=True)
```

### 9. Network/DNS Errors

**Error:** `Name resolution failed` or connection errors

**Solutions:**
```python
# Add retries
@app.function(retries=3)
def network_func():
    pass

# Increase timeout for slow APIs
import requests
response = requests.get(url, timeout=30)
```

### 10. Image Build Failures

**Error:** `Image build failed`

**Solutions:**
```python
# Check package compatibility
image = (
    modal.Image.debian_slim(python_version="3.11")
    .apt_install("build-essential")  # For compiled packages
    .pip_install("package")
)

# Build in stages for debugging
base_image = modal.Image.debian_slim()
with_deps = base_image.pip_install("dep1", "dep2")
final = with_deps.pip_install("main_package")
```

## Debugging Workflow

### Step 1: Reproduce Locally

```bash
# Test the function
modal run app.py::function_name --arg value

# Get interactive shell
modal shell app.py
```

### Step 2: Check Logs

```bash
# View recent logs
modal app logs my-app

# Follow logs in real-time
modal app logs my-app --follow
```

### Step 3: Simplify

```python
# Minimal reproduction
@app.function()
def debug_func():
    # Add one thing at a time
    import torch
    print(f"CUDA available: {torch.cuda.is_available()}")
```

### Step 4: Check Resources

```python
# Log resource usage
@app.function(gpu="A100")
def check_resources():
    import torch
    import psutil

    print(f"GPU: {torch.cuda.get_device_name(0)}")
    print(f"GPU Memory: {torch.cuda.get_device_properties(0).total_memory / 1e9:.1f} GB")
    print(f"CPU Memory: {psutil.virtual_memory().total / 1e9:.1f} GB")
```

## Debug Logging Pattern

```python
import modal
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = modal.App("debug-app")

@app.function()
def debuggable_func(data):
    logger.info(f"Starting with data: {data}")

    try:
        logger.info("Step 1: Processing")
        result = process(data)
        logger.info(f"Step 1 complete: {len(result)} items")

        logger.info("Step 2: Transforming")
        transformed = transform(result)
        logger.info(f"Step 2 complete")

        return transformed

    except Exception as e:
        logger.error(f"Error: {e}", exc_info=True)
        raise
```

## Performance Debugging

```python
import time

@app.function()
def profile_func():
    start = time.time()

    # Phase 1
    t1 = time.time()
    step1()
    print(f"Step 1: {time.time() - t1:.2f}s")

    # Phase 2
    t2 = time.time()
    step2()
    print(f"Step 2: {time.time() - t2:.2f}s")

    print(f"Total: {time.time() - start:.2f}s")
```

## Getting Help

1. **Modal Discord**: Active community support
2. **Modal Docs**: docs.modal.com
3. **GitHub Issues**: github.com/modal-labs/modal-client
4. **Error Messages**: Usually contain helpful context

## Checklist

- [ ] Function runs locally with `modal run`?
- [ ] Image builds successfully?
- [ ] Secrets exist in correct environment?
- [ ] Volumes exist and are accessible?
- [ ] GPU type is available?
- [ ] Sufficient memory allocated?
- [ ] Timeout is adequate?
- [ ] Dependencies are installed correctly?
