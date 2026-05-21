---
name: python-modal
description: |
  Modern Python patterns for Modal.com serverless platform.
  PROACTIVELY activate for: (1) Modal function deployment, (2) Type-safe Modal with Pydantic, (3) Async patterns in Modal, (4) GPU workloads (ML inference, training), (5) FastAPI web endpoints on Modal, (6) Scheduled tasks and cron jobs, (7) Modal Volumes and storage, (8) Testing Modal functions with pytest, (9) Modal classes and lifecycle methods, (10) Parallel processing with map/starmap.
  Provides: Type hints patterns, Pydantic integration, async/await patterns, pytest testing, FastAPI integration, scheduled tasks, Volume usage, cost optimization, and production-ready examples following Python 3.11+ best practices.
---

## Quick Reference

| Pattern | Decorator | Use Case |
|---------|-----------|----------|
| Simple function | `@app.function()` | Stateless compute |
| Class with state | `@app.cls()` | ML models, DB connections |
| Web endpoint | `@modal.asgi_app()` | FastAPI/Flask APIs |
| Scheduled | `@app.function(schedule=...)` | Cron jobs |
| Parallel | `.map()`, `.starmap()` | Batch processing |

## When to Use This Skill

Use for **Python on Modal**:
- Type-safe serverless functions with Pydantic
- Async/await patterns for concurrent operations
- GPU workloads (ML inference, training)
- FastAPI web endpoints
- Scheduled tasks and automation
- Testing Modal functions locally

---

# Modern Python on Modal.com (2025)

Complete guide to building type-safe, production-ready Python applications on Modal's serverless platform.

## Type-Safe Modal Functions

### Basic Function with Type Hints

```python
import modal

app = modal.App("typed-example")

image = modal.Image.debian_slim(python_version="3.11").pip_install("pydantic")

@app.function(image=image)
def process_data(
    items: list[str],
    multiplier: int = 1,
) -> dict[str, int]:
    """Process data with full type hints."""
    return {item: len(item) * multiplier for item in items}


@app.local_entrypoint()
def main():
    result: dict[str, int] = process_data.remote(["hello", "world"], multiplier=2)
    print(result)  # {'hello': 10, 'world': 10}
```

### Pydantic Models for Validation

```python
import modal
from pydantic import BaseModel, Field, field_validator
from datetime import datetime
from typing import Literal

app = modal.App("pydantic-example")

image = modal.Image.debian_slim(python_version="3.11").pip_install("pydantic>=2.0")


# === Input/Output Models ===

class ProcessingConfig(BaseModel):
    """Configuration with validation."""
    model_name: str = Field(..., min_length=1, max_length=100)
    batch_size: int = Field(32, ge=1, le=256)
    temperature: float = Field(0.7, ge=0.0, le=2.0)
    mode: Literal["fast", "balanced", "quality"] = "balanced"

    @field_validator("model_name")
    @classmethod
    def validate_model_name(cls, v: str) -> str:
        allowed = ["gpt2", "llama-7b", "mistral-7b"]
        if v not in allowed:
            raise ValueError(f"Model must be one of {allowed}")
        return v


class ProcessingRequest(BaseModel):
    """Request with automatic validation."""
    text: str = Field(..., min_length=1, max_length=10000)
    config: ProcessingConfig
    user_id: str = Field(..., pattern=r"^[a-zA-Z0-9_-]+$")


class ProcessingResponse(BaseModel):
    """Response with structured output."""
    result: str
    tokens_used: int
    latency_ms: float
    model_name: str
    timestamp: datetime


@app.function(image=image)
def process_with_validation(request: ProcessingRequest) -> ProcessingResponse:
    """Process with Pydantic validation on input and output."""
    import time

    start = time.time()

    # Your processing logic here
    result = f"Processed: {request.text[:50]}..."
    tokens = len(request.text.split())

    latency = (time.time() - start) * 1000

    return ProcessingResponse(
        result=result,
        tokens_used=tokens,
        latency_ms=round(latency, 2),
        model_name=request.config.model_name,
        timestamp=datetime.utcnow(),
    )


@app.local_entrypoint()
def main():
    # Pydantic validates automatically
    request = ProcessingRequest(
        text="Hello, world! This is a test.",
        config=ProcessingConfig(model_name="gpt2", batch_size=64),
        user_id="user_123",
    )

    response = process_with_validation.remote(request)
    print(f"Result: {response.result}")
    print(f"Tokens: {response.tokens_used}")
```

---

## Async Patterns

### Async Modal Functions

```python
import modal
import asyncio
from typing import Coroutine, Any

app = modal.App("async-example")

image = modal.Image.debian_slim(python_version="3.11").pip_install("httpx", "aiofiles")


@app.function(image=image)
async def fetch_url(url: str) -> dict[str, Any]:
    """Async function for HTTP requests."""
    import httpx

    async with httpx.AsyncClient() as client:
        response = await client.get(url, timeout=30)
        return {
            "url": url,
            "status": response.status_code,
            "length": len(response.content),
        }


@app.function(image=image)
async def fetch_multiple(urls: list[str]) -> list[dict[str, Any]]:
    """Fetch multiple URLs concurrently."""
    import httpx

    async with httpx.AsyncClient() as client:
        tasks = [client.get(url, timeout=30) for url in urls]
        responses = await asyncio.gather(*tasks, return_exceptions=True)

        results = []
        for url, response in zip(urls, responses):
            if isinstance(response, Exception):
                results.append({"url": url, "error": str(response)})
            else:
                results.append({
                    "url": url,
                    "status": response.status_code,
                    "length": len(response.content),
                })

        return results


@app.function(image=image)
async def async_file_processing(file_paths: list[str]) -> list[str]:
    """Process files asynchronously."""
    import aiofiles

    async def read_file(path: str) -> str:
        async with aiofiles.open(path, "r") as f:
            return await f.read()

    tasks = [read_file(path) for path in file_paths]
    contents = await asyncio.gather(*tasks)
    return contents


@app.local_entrypoint()
def main():
    urls = [
        "https://httpbin.org/get",
        "https://httpbin.org/json",
        "https://httpbin.org/headers",
    ]

    results = fetch_multiple.remote(urls)
    for result in results:
        print(f"{result['url']}: {result.get('status', result.get('error'))}")
```

### Async with Modal Classes

```python
import modal

app = modal.App("async-class")

image = modal.Image.debian_slim(python_version="3.11").pip_install("httpx", "redis")


@app.cls(image=image)
class AsyncService:
    """Service with async methods and connection pooling."""

    def __init__(self):
        self._http_client: httpx.AsyncClient | None = None

    @modal.enter()
    async def setup(self):
        """Async initialization - runs once per container."""
        import httpx
        self._http_client = httpx.AsyncClient(timeout=30)
        print("HTTP client initialized")

    @modal.exit()
    async def cleanup(self):
        """Async cleanup - runs on container shutdown."""
        if self._http_client:
            await self._http_client.aclose()
        print("HTTP client closed")

    @modal.method()
    async def fetch(self, url: str) -> dict:
        """Use persistent HTTP client."""
        response = await self._http_client.get(url)
        return {"url": url, "status": response.status_code}

    @modal.method()
    async def fetch_batch(self, urls: list[str]) -> list[dict]:
        """Fetch multiple URLs using persistent client."""
        import asyncio

        tasks = [self._http_client.get(url) for url in urls]
        responses = await asyncio.gather(*tasks, return_exceptions=True)

        return [
            {"url": url, "status": r.status_code}
            if not isinstance(r, Exception)
            else {"url": url, "error": str(r)}
            for url, r in zip(urls, responses)
        ]
```

---

## Modal Classes with Lifecycle

### ML Model Server

```python
import modal
from pydantic import BaseModel, Field

app = modal.App("ml-server")

image = (
    modal.Image.debian_slim(python_version="3.11")
    .pip_install("torch", "transformers", "pydantic")
)

models_volume = modal.Volume.from_name("models-cache", create_if_missing=True)


class InferenceRequest(BaseModel):
    text: str = Field(..., min_length=1, max_length=5000)
    max_tokens: int = Field(512, ge=1, le=2048)
    temperature: float = Field(0.7, ge=0.0, le=2.0)


class InferenceResponse(BaseModel):
    generated_text: str
    tokens_generated: int
    model_name: str


@app.cls(
    image=image,
    gpu="A100",
    volumes={"/models": models_volume},
    min_containers=1,      # Keep warm
    max_containers=10,     # Scale limit
    container_idle_timeout=300,
)
class ModelServer:
    """Type-safe ML model server with lifecycle management."""

    model_name: str = "gpt2"

    def __init__(self, model_name: str = "gpt2"):
        self.model_name = model_name
        self._model = None
        self._tokenizer = None

    @modal.enter()
    def load_model(self) -> None:
        """Load model once per container (not per request)."""
        from transformers import AutoModelForCausalLM, AutoTokenizer
        import torch

        print(f"Loading model: {self.model_name}")

        self._tokenizer = AutoTokenizer.from_pretrained(
            self.model_name,
            cache_dir="/models",
        )
        self._model = AutoModelForCausalLM.from_pretrained(
            self.model_name,
            torch_dtype=torch.float16,
            cache_dir="/models",
        ).to("cuda")

        print("Model loaded successfully")

    @modal.method()
    def generate(self, request: InferenceRequest) -> InferenceResponse:
        """Generate text with type-safe input/output."""
        import torch

        inputs = self._tokenizer(request.text, return_tensors="pt").to("cuda")

        with torch.no_grad():
            outputs = self._model.generate(
                **inputs,
                max_new_tokens=request.max_tokens,
                temperature=request.temperature,
                do_sample=True,
            )

        generated = self._tokenizer.decode(outputs[0], skip_special_tokens=True)
        tokens_generated = len(outputs[0]) - len(inputs.input_ids[0])

        return InferenceResponse(
            generated_text=generated,
            tokens_generated=tokens_generated,
            model_name=self.model_name,
        )

    @modal.method()
    def batch_generate(
        self,
        requests: list[InferenceRequest],
    ) -> list[InferenceResponse]:
        """Process multiple requests."""
        return [self.generate(req) for req in requests]


@app.local_entrypoint()
def main():
    server = ModelServer()

    request = InferenceRequest(
        text="Write a haiku about Python:",
        max_tokens=50,
        temperature=0.8,
    )

    response = server.generate.remote(request)
    print(f"Generated: {response.generated_text}")
    print(f"Tokens: {response.tokens_generated}")
```

---

## FastAPI Integration

### Type-Safe Web API

```python
import modal
from pydantic import BaseModel, Field
from datetime import datetime
from typing import Annotated

app = modal.App("fastapi-example")

image = (
    modal.Image.debian_slim(python_version="3.11")
    .pip_install("fastapi", "pydantic>=2.0")
)


# === Pydantic Models ===

class ItemCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    description: str = Field("", max_length=1000)
    price: float = Field(..., gt=0)
    tags: list[str] = []


class Item(ItemCreate):
    id: str
    created_at: datetime


class ItemList(BaseModel):
    items: list[Item]
    total: int


# === In-memory storage (use database in production) ===
items_db: dict[str, Item] = {}


@app.function(image=image)
@modal.concurrent(max_inputs=100, target_inputs=50)
@modal.asgi_app()
def api():
    from fastapi import FastAPI, HTTPException, Query, Path, Depends
    from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
    import uuid

    web_app = FastAPI(
        title="Items API",
        version="1.0.0",
        description="Type-safe REST API on Modal",
    )

    security = HTTPBearer()

    def verify_auth(
        creds: HTTPAuthorizationCredentials = Depends(security)
    ) -> str:
        if creds.credentials != "secret-token":
            raise HTTPException(401, "Invalid token")
        return creds.credentials

    # === Endpoints with full type hints ===

    @web_app.post("/items", response_model=Item, status_code=201)
    def create_item(
        item: ItemCreate,
        token: str = Depends(verify_auth),
    ) -> Item:
        """Create a new item."""
        item_id = str(uuid.uuid4())
        new_item = Item(
            id=item_id,
            created_at=datetime.utcnow(),
            **item.model_dump(),
        )
        items_db[item_id] = new_item
        return new_item

    @web_app.get("/items", response_model=ItemList)
    def list_items(
        skip: Annotated[int, Query(ge=0)] = 0,
        limit: Annotated[int, Query(ge=1, le=100)] = 10,
    ) -> ItemList:
        """List all items with pagination."""
        all_items = list(items_db.values())
        return ItemList(
            items=all_items[skip : skip + limit],
            total=len(all_items),
        )

    @web_app.get("/items/{item_id}", response_model=Item)
    def get_item(
        item_id: Annotated[str, Path(min_length=1)],
    ) -> Item:
        """Get a specific item."""
        if item_id not in items_db:
            raise HTTPException(404, "Item not found")
        return items_db[item_id]

    @web_app.delete("/items/{item_id}", status_code=204)
    def delete_item(
        item_id: str,
        token: str = Depends(verify_auth),
    ) -> None:
        """Delete an item."""
        if item_id not in items_db:
            raise HTTPException(404, "Item not found")
        del items_db[item_id]

    @web_app.get("/health")
    def health() -> dict[str, str]:
        return {"status": "healthy", "timestamp": datetime.utcnow().isoformat()}

    return web_app
```

---

## Scheduled Tasks

### Cron Jobs with Type Safety

```python
import modal
from pydantic import BaseModel
from datetime import datetime, timezone
import os

app = modal.App("scheduled-tasks")

image = modal.Image.debian_slim(python_version="3.11").pip_install(
    "httpx",
    "pydantic",
)


class ETLResult(BaseModel):
    """Result of ETL job."""
    records_processed: int
    errors: int
    duration_seconds: float
    timestamp: datetime


@app.function(
    image=image,
    schedule=modal.Cron("0 6 * * *", timezone="America/New_York"),  # 6 AM ET daily
    secrets=[modal.Secret.from_name("api-credentials")],
    timeout=3600,
)
def daily_etl_job() -> ETLResult:
    """Daily ETL job that runs at 6 AM."""
    import httpx
    import time

    start = time.time()
    api_key = os.environ["API_KEY"]

    records = 0
    errors = 0

    try:
        with httpx.Client() as client:
            response = client.get(
                "https://api.example.com/data",
                headers={"Authorization": f"Bearer {api_key}"},
                timeout=60,
            )
            response.raise_for_status()
            data = response.json()
            records = len(data.get("items", []))
    except httpx.HTTPError as e:
        errors += 1
        print(f"API error: {e}")

    duration = time.time() - start

    return ETLResult(
        records_processed=records,
        errors=errors,
        duration_seconds=round(duration, 2),
        timestamp=datetime.now(timezone.utc),
    )


@app.function(
    image=image,
    schedule=modal.Period(hours=1),  # Every hour
)
def hourly_health_check() -> dict[str, str]:
    """Hourly health check."""
    import httpx

    endpoints = [
        "https://api.example.com/health",
        "https://web.example.com/health",
    ]

    results = {}
    with httpx.Client() as client:
        for url in endpoints:
            try:
                response = client.get(url, timeout=10)
                results[url] = "healthy" if response.status_code == 200 else "unhealthy"
            except httpx.HTTPError:
                results[url] = "unreachable"

    return results


@app.function(
    image=image,
    schedule=modal.Cron("*/15 * * * *"),  # Every 15 minutes
)
def metrics_collector() -> dict[str, float]:
    """Collect metrics every 15 minutes."""
    import random  # Replace with actual metrics collection

    return {
        "cpu_usage": random.uniform(0, 100),
        "memory_usage": random.uniform(0, 100),
        "request_count": random.randint(0, 1000),
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }
```

---

## Parallel Processing, Modal Volumes & Testing

Full code for Modal's parallel/distributed primitives (`.map()`, `.starmap()`, batch processing, fan-out/fan-in patterns), Modal Volumes for persistent storage (datasets, model weights, fine-tuned checkpoints, caches), and the complete testing strategy (mocking Modal stubs, integration tests, pytest fixtures) lives in `references/parallel-volumes-testing.md`. Load that reference when scaling out, persisting state across runs, or wiring CI for Modal apps.

---

## Best Practices

### 1. Always Use Type Hints

```python
# Good
def process(items: list[str], count: int = 10) -> dict[str, int]:
    return {item: len(item) for item in items[:count]}

# Bad
def process(items, count=10):
    return {item: len(item) for item in items[:count]}
```

### 2. Use Pydantic for Validation

```python
# Good - validated at runtime
class Config(BaseModel):
    batch_size: int = Field(ge=1, le=256)

# Bad - no validation
config = {"batch_size": -1}  # Invalid but accepted
```

### 3. Use `@modal.enter()` for Initialization

```python
# Good - runs once per container
@app.cls(gpu="A100")
class ModelServer:
    @modal.enter()
    def setup(self):
        self.model = load_model()  # Expensive, done once

# Bad - runs every request
@app.function(gpu="A100")
def predict(data):
    model = load_model()  # Loads every time!
    return model.predict(data)
```

### 4. Commit Volume Changes

```python
# Good
@app.function(volumes={"/data": vol})
def save(data):
    Path("/data/file.txt").write_text(data)
    vol.commit()  # Persist changes

# Bad - changes lost!
@app.function(volumes={"/data": vol})
def save(data):
    Path("/data/file.txt").write_text(data)
    # Forgot to commit!
```

### 5. Use Async for I/O Operations

```python
# Good - concurrent I/O
async def fetch_all(urls: list[str]):
    async with httpx.AsyncClient() as client:
        tasks = [client.get(url) for url in urls]
        return await asyncio.gather(*tasks)

# Bad - sequential I/O
def fetch_all(urls: list[str]):
    results = []
    for url in urls:
        results.append(requests.get(url))  # Blocking!
    return results
```

---

## Common Pitfalls

### 1. Blocking I/O in Async Functions

```python
# Bad - blocks event loop
async def bad_fetch():
    return requests.get(url)  # Blocking!

# Good - use async client
async def good_fetch():
    async with httpx.AsyncClient() as client:
        return await client.get(url)
```

### 2. Not Using `@modal.concurrent`

```python
# Bad - one request at a time
@app.function()
@modal.asgi_app()
def api():
    return app

# Good - handle multiple requests
@app.function()
@modal.concurrent(max_inputs=100)
@modal.asgi_app()
def api():
    return app
```

### 3. Hardcoding Secrets

```python
# Bad
API_KEY = "sk-12345"

# Good
@app.function(secrets=[modal.Secret.from_name("api-keys")])
def process():
    api_key = os.environ["API_KEY"]
```

### 4. Forgetting Timeouts

```python
# Bad - default 300s may not be enough
@app.function()
def long_process():
    pass

# Good - explicit timeout
@app.function(timeout=3600)  # 1 hour
def long_process():
    pass
```

---

## Related Skills

- `python-type-hints` - Comprehensive type hints
- `python-asyncio` - Async patterns
- `python-fastapi` - FastAPI best practices
- `python-testing` - pytest patterns
