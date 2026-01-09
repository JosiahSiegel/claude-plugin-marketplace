# Modal Sandboxes for Code Execution

## Overview

Modal Sandboxes provide isolated execution environments for running untrusted code safely. Used by Poe, Quora, and other platforms for AI code execution.

## Basic Usage

```python
import modal

app = modal.App("sandbox-demo")

@app.function()
def execute_user_code(code: str) -> dict:
    """Execute untrusted Python code in a sandbox"""
    sb = modal.Sandbox.create(
        app=app,
        image=modal.Image.debian_slim().pip_install("numpy", "pandas"),
        timeout=60,
    )

    try:
        # Execute code
        process = sb.exec("python", "-c", code)
        process.wait()

        return {
            "stdout": process.stdout.read(),
            "stderr": process.stderr.read(),
            "return_code": process.returncode,
        }
    finally:
        sb.terminate()
```

## Sandbox Configuration

```python
sb = modal.Sandbox.create(
    app=app,
    image=image,                    # Container image
    timeout=300,                    # Max execution time
    cpu=2.0,                        # CPU cores
    memory=4096,                    # Memory in MB
    gpu="T4",                       # Optional GPU
    workdir="/app",                 # Working directory
    encrypted_ports=[8080],         # Expose ports
    block_network=True,             # Block network access
)
```

### Security Options

| Option | Description |
|--------|-------------|
| `block_network` | Prevent all network access |
| `timeout` | Hard limit on execution time |
| `memory` | Limit memory to prevent OOM attacks |
| `cpu` | Limit CPU to prevent resource exhaustion |

## Running Commands

### Simple Execution

```python
# Run command and wait
process = sb.exec("python", "script.py")
process.wait()

# Get output
stdout = process.stdout.read()
stderr = process.stderr.read()
exit_code = process.returncode
```

### Interactive Execution

```python
# Start process
process = sb.exec("python", "-i")

# Send input
process.stdin.write("print('hello')\n")
process.stdin.write("exit()\n")

# Read output
output = process.stdout.read()
```

### File Operations

```python
# Write file to sandbox
sb.fs.write("/app/data.json", json.dumps(data))

# Read file from sandbox
content = sb.fs.read("/app/result.txt")

# List files
files = sb.fs.ls("/app")
```

## Complete Example: Code Playground

```python
import modal
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = modal.App("code-playground")

image = (
    modal.Image.debian_slim(python_version="3.11")
    .pip_install(
        "numpy", "pandas", "matplotlib",
        "scikit-learn", "requests"
    )
)

class CodeRequest(BaseModel):
    code: str
    timeout: int = 30

class CodeResponse(BaseModel):
    stdout: str
    stderr: str
    return_code: int
    execution_time: float

@app.cls()
class CodeExecutor:

    @modal.method()
    def execute(self, request: CodeRequest) -> CodeResponse:
        import time
        start = time.time()

        sb = modal.Sandbox.create(
            app=app,
            image=image,
            timeout=min(request.timeout, 60),  # Max 60s
            memory=2048,
            cpu=1.0,
            block_network=True,  # Secure
        )

        try:
            # Write code to file
            sb.fs.write("/tmp/code.py", request.code)

            # Execute
            process = sb.exec("python", "/tmp/code.py")
            process.wait()

            return CodeResponse(
                stdout=process.stdout.read(),
                stderr=process.stderr.read(),
                return_code=process.returncode,
                execution_time=time.time() - start,
            )
        finally:
            sb.terminate()

    @modal.asgi_app()
    def web(self):
        web_app = FastAPI(title="Code Playground")

        @web_app.post("/execute", response_model=CodeResponse)
        def execute_code(request: CodeRequest):
            return self.execute.local(request)

        return web_app
```

## GPU Sandboxes

For AI model execution in sandboxes:

```python
@app.function()
def execute_ml_code(code: str) -> dict:
    sb = modal.Sandbox.create(
        app=app,
        image=modal.Image.debian_slim()
            .pip_install("torch", "transformers"),
        gpu="T4",
        timeout=120,
        memory=16384,
    )

    try:
        process = sb.exec("python", "-c", code)
        process.wait()
        return {
            "output": process.stdout.read(),
            "error": process.stderr.read(),
        }
    finally:
        sb.terminate()
```

## Sandbox Pooling

For high-throughput code execution:

```python
@app.cls()
class SandboxPool:
    def __init__(self):
        self.sandbox = None

    @modal.enter()
    def create_sandbox(self):
        self.sandbox = modal.Sandbox.create(
            app=app,
            image=image,
            timeout=300,
        )

    @modal.method()
    def execute(self, code: str) -> str:
        sb.fs.write("/tmp/code.py", code)
        process = self.sandbox.exec("python", "/tmp/code.py")
        process.wait()
        return process.stdout.read()

    @modal.exit()
    def cleanup(self):
        self.sandbox.terminate()
```

## Best Practices

1. **Always set timeouts** - Prevent infinite loops
2. **Block network for untrusted code** - Security
3. **Limit resources** - CPU, memory, GPU
4. **Terminate sandboxes** - Clean up resources
5. **Sanitize output** - Don't expose internal paths
6. **Use dedicated images** - Only needed packages
7. **Log executions** - For debugging and security

## Security Considerations

| Risk | Mitigation |
|------|------------|
| Resource exhaustion | Set CPU, memory, timeout limits |
| Network attacks | Use `block_network=True` |
| Filesystem escape | Sandboxes are isolated by gVisor |
| Information leakage | Sanitize stdout/stderr |
| Denial of service | Rate limit API endpoints |

## Use Cases

- **AI Code Assistants**: Execute generated code safely
- **Online IDEs**: Browser-based development environments
- **Code Interview Platforms**: Run candidate solutions
- **Education Platforms**: Student code execution
- **CI/CD**: Isolated test execution
