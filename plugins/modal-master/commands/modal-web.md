---
name: Create Endpoint
description: Create web endpoints using FastAPI, ASGI, WSGI, or custom web servers
argument-hint: "<endpoint-type: fastapi|asgi|wsgi|server> [route]"
---

# Modal Web Command

Create web endpoints using FastAPI, ASGI, WSGI, or custom web servers.

## Task

Help create web endpoints for Modal applications with:

1. **Endpoint Type Selection**
   - Simple endpoints with `@modal.fastapi_endpoint()`
   - Full FastAPI apps with `@modal.asgi_app()`
   - Flask/Django with `@modal.wsgi_app()`
   - Custom servers with `@modal.web_server()`

2. **Configuration**
   - Request/response handling
   - Authentication and security
   - Custom domains
   - WebSocket support

3. **Performance**
   - Container warmup for low latency
   - Concurrency settings
   - Timeout configuration

## Endpoint Types

### Simple FastAPI Endpoint

Best for single-function APIs:

```python
import modal

app = modal.App("simple-api")

@app.function()
@modal.fastapi_endpoint()
def hello(name: str = "World"):
    return {"message": f"Hello, {name}!"}
```

### Full FastAPI Application

Best for complex APIs with multiple routes:

```python
import modal
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = modal.App("full-api")

web_app = FastAPI(title="My API", version="1.0.0")

class PredictRequest(BaseModel):
    text: str
    max_length: int = 100

class PredictResponse(BaseModel):
    result: str
    tokens: int

@web_app.get("/health")
def health():
    return {"status": "healthy"}

@web_app.post("/predict", response_model=PredictResponse)
def predict(request: PredictRequest):
    # Your logic here
    result = process(request.text)
    return PredictResponse(result=result, tokens=len(result.split()))

@web_app.get("/items/{item_id}")
def get_item(item_id: int):
    if item_id < 0:
        raise HTTPException(status_code=404, detail="Item not found")
    return {"item_id": item_id}

@app.function()
@modal.asgi_app()
def fastapi_app():
    return web_app
```

### FastAPI with GPU (ML Inference)

```python
import modal

app = modal.App("ml-api")

image = (
    modal.Image.debian_slim()
    .uv_pip_install("torch", "transformers", "fastapi")
)

@app.cls(gpu="A10G", image=image, container_idle_timeout=300)
class InferenceServer:

    @modal.enter()
    def load_model(self):
        from transformers import pipeline
        self.pipe = pipeline("text-generation", model="gpt2", device=0)

    @modal.asgi_app()
    def web(self):
        from fastapi import FastAPI

        web_app = FastAPI()

        @web_app.post("/generate")
        def generate(prompt: str, max_length: int = 50):
            result = self.pipe(prompt, max_length=max_length)
            return {"generated": result[0]["generated_text"]}

        return web_app
```

### Flask Application (WSGI)

```python
import modal
from flask import Flask, request, jsonify

app = modal.App("flask-api")

flask_app = Flask(__name__)

@flask_app.route("/")
def home():
    return jsonify({"message": "Hello from Flask!"})

@flask_app.route("/predict", methods=["POST"])
def predict():
    data = request.json
    result = process(data["text"])
    return jsonify({"result": result})

@app.function()
@modal.wsgi_app()
def flask_endpoint():
    return flask_app
```

### Custom Web Server

For any server listening on a port:

```python
import modal

app = modal.App("custom-server")

@app.function()
@modal.web_server(port=8080)
def gradio_server():
    import subprocess
    subprocess.run(["python", "gradio_app.py"])
```

### WebSocket Support

```python
import modal
from fastapi import FastAPI, WebSocket, WebSocketDisconnect

app = modal.App("websocket-api")

web_app = FastAPI()

@web_app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    try:
        while True:
            data = await websocket.receive_text()
            await websocket.send_text(f"Echo: {data}")
    except WebSocketDisconnect:
        print("Client disconnected")

@app.function()
@modal.asgi_app()
def ws_app():
    return web_app
```

## Custom Domains

```python
# Configure custom domain
@app.function()
@modal.asgi_app(custom_domains=["api.example.com"])
def production_api():
    return web_app
```

**Setup Steps:**
1. Add domain in Modal dashboard
2. Configure DNS records as instructed
3. Add `custom_domains` parameter to decorator
4. Deploy with `modal deploy`

## Authentication

### Proxy Auth Token

```python
# Protected endpoint (requires token)
@app.function()
@modal.asgi_app()
def protected_api():
    # Modal provides proxy auth token
    # Clients must include Authorization header
    return web_app
```

### Custom Authentication

```python
from fastapi import FastAPI, Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

web_app = FastAPI()
security = HTTPBearer()

def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    if credentials.credentials != os.environ["API_TOKEN"]:
        raise HTTPException(status_code=401, detail="Invalid token")
    return credentials

@web_app.get("/protected")
def protected_route(token: str = Depends(verify_token)):
    return {"message": "Authenticated!"}
```

## Configuration Options

```python
@app.function(
    timeout=150,  # HTTP timeout is 150s max
    memory=2048,  # Memory in MB
    cpu=2.0,  # CPU cores
    container_idle_timeout=60,  # Keep warm
    concurrency_limit=100,  # Max concurrent requests
)
@modal.asgi_app()
def configured_api():
    return web_app
```

## Development Workflow

```bash
# Hot-reload development
modal serve app.py

# Test locally (auto-generates URL)
# Output: https://your-workspace--app-name-fastapi-app-dev.modal.run

# Deploy to production
modal deploy app.py

# View logs
modal app logs app-name --follow
```

## Best Practices

1. **Use `@modal.asgi_app()`** for complex FastAPI apps
2. **Use `@modal.fastapi_endpoint()`** for simple single-function endpoints
3. **Set `container_idle_timeout`** to reduce cold starts
4. **Use class pattern with `@modal.enter()`** for ML models
5. **Add health check endpoint** for monitoring
6. **Configure appropriate timeout** (max 150s for HTTP)
7. **Use custom domains** for production APIs
8. **Implement proper error handling** with HTTPException
