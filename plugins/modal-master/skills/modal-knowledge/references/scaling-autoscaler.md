# Modal Scaling and Autoscaler Configuration

## Autoscaler Settings (Modal 1.0 SDK)

Modal's autoscaler manages container provisioning based on workload. Configure via `@app.function()` or `@app.cls()`:

```python
@app.function(
    min_containers=0,          # Minimum warm containers (default: 0)
    max_containers=100,        # Maximum concurrent containers
    buffer_containers=0,       # Pre-warm buffer containers
    scaledown_window=300,      # Seconds before scaling down (default: 300)
)
def scalable_func():
    pass
```

### Parameters Explained

| Parameter | Default | Description |
|-----------|---------|-------------|
| `min_containers` | 0 | Always keep this many containers warm |
| `max_containers` | None | Hard limit on concurrent containers |
| `buffer_containers` | 0 | Extra containers to pre-provision |
| `scaledown_window` | 300 | Wait time before scaling down idle containers |

### Scaling Patterns

#### High-Traffic API (Keep Warm)

```python
@app.cls(
    gpu="A10G",
    min_containers=2,        # Always warm
    buffer_containers=1,     # Extra headroom
    container_idle_timeout=600,
)
class ProductionAPI:
    @modal.enter()
    def load(self):
        self.model = load_model()

    @modal.method()
    def predict(self, data):
        return self.model(data)
```

#### Burst Processing (Scale Quickly)

```python
@app.function(
    max_containers=500,      # Allow massive scale-out
    scaledown_window=60,     # Scale down quickly when done
)
def burst_processor(item):
    return process(item)

# Process 10,000 items in parallel
results = list(burst_processor.map(items))
```

#### Cost-Optimized (Scale to Zero)

```python
@app.function(
    min_containers=0,        # Scale to zero
    max_containers=10,       # Limit costs
    scaledown_window=120,    # Quick scale down
)
def cost_optimized(data):
    return process(data)
```

## @modal.concurrent Decorator

Replaces the old `allow_concurrent_inputs` parameter. Allows one container to handle multiple requests:

```python
@app.cls(gpu="A100")
class ConcurrentServer:
    @modal.enter()
    def load(self):
        self.model = load_model()

    @modal.concurrent(max_inputs=100, target_inputs=80)
    @modal.method()
    def predict(self, data):
        # Container handles up to 100 concurrent requests
        # Autoscaler adds containers when hitting ~80 requests
        return self.model(data)
```

### Concurrent Parameters

| Parameter | Description |
|-----------|-------------|
| `max_inputs` | Maximum concurrent requests per container |
| `target_inputs` | Target utilization (triggers scaling when exceeded) |

### When to Use Concurrency

| Workload | Concurrency | Reason |
|----------|-------------|--------|
| GPU inference | 10-100 | GPU can batch requests |
| I/O-bound | 50-500 | Waiting on network/disk |
| CPU-bound | 1 | Each request needs full CPU |
| Memory-heavy | 1-10 | Prevent OOM |

## Scaling Limits

| Limit | Value | Notes |
|-------|-------|-------|
| Pending inputs per function | 2,000 | Queue limit |
| Total inputs per function | 25,000 | All states |
| Pending inputs with `.spawn()` | 1,000,000 | Async jobs |
| Concurrent `.map()` calls | 1,000 | Per map |
| Max containers (Team plan) | 1,000 | Soft limit |
| Max GPU containers (Team) | 50 | Per GPU type |

## Parallel Processing Methods

### .map() - Synchronized Batch

```python
# Process in parallel, wait for all
results = list(func.map(items))

# Unordered for better performance
results = list(func.map(items, order_outputs=False))

# With return exceptions
results = list(func.map(items, return_exceptions=True))
```

### .starmap() - Multiple Arguments

```python
# Each item is unpacked as positional args
pairs = [(1, 2), (3, 4), (5, 6)]
results = list(add.starmap(pairs))
```

### .spawn() - Fire and Forget

```python
# Submit without waiting
call = func.spawn(data)

# Get result later
result = call.get()

# Poll status
if call.status() == "completed":
    result = call.get()

# Cancel if needed
call.cancel()
```

### .for_each() - Side Effects

```python
# Execute for side effects, no return values
func.for_each(items)
```

## Performance Tuning

### Reduce Cold Starts

```python
@app.function(
    min_containers=1,           # Keep 1 warm
    container_idle_timeout=600, # Stay warm 10 min
)
def low_latency():
    pass
```

### Maximize Throughput

```python
@app.cls(
    gpu="A100",
    max_containers=100,
)
class HighThroughput:
    @modal.concurrent(max_inputs=50)
    @modal.method()
    def process(self, data):
        return self.batch_inference(data)
```

### Balance Cost and Latency

```python
@app.function(
    min_containers=0,           # Scale to zero when idle
    buffer_containers=1,        # 1 extra for bursts
    scaledown_window=180,       # 3 min before scale down
    container_idle_timeout=300, # 5 min idle timeout
)
def balanced():
    pass
```

## Monitoring Scaling

```bash
# View function metrics
modal app show my-app

# Watch container scaling
modal app logs my-app --follow

# Dashboard provides:
# - Active containers
# - Queue depth
# - Latency percentiles
# - Error rates
```
