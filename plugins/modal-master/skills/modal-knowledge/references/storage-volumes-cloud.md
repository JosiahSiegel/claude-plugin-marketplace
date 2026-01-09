# Modal Storage: Volumes, Dict, Queue, and CloudBucketMount

## Volumes

Persistent file storage for Modal functions. Data persists across function invocations.

### Creating Volumes

```python
# Reference existing or create new
vol = modal.Volume.from_name("my-volume", create_if_missing=True)

# CLI creation
# modal volume create my-volume
```

### Using Volumes

```python
@app.function(volumes={"/data": vol})
def process_data():
    # Read from volume
    with open("/data/input.txt") as f:
        data = f.read()

    # Write to volume
    with open("/data/output.txt", "w") as f:
        f.write(processed)

    # CRITICAL: Commit changes!
    vol.commit()
```

### Volume Operations

```python
# Reload from remote (get latest changes)
vol.reload()

# Commit local changes
vol.commit()

# Both (sync)
vol.reload()
# ... make changes ...
vol.commit()
```

### CLI Commands

```bash
# Create
modal volume create my-vol

# List
modal volume list

# Upload file
modal volume put my-vol local_file.txt /remote/path/file.txt

# Download file
modal volume get my-vol /remote/path/file.txt local_file.txt

# List contents
modal volume ls my-vol /path

# Delete file
modal volume rm my-vol /path/file.txt
```

### Volume Best Practices

```python
@app.function(volumes={"/data": vol})
def safe_volume_usage():
    # Reload to get latest state
    vol.reload()

    try:
        # Your operations
        process_files()

        # Commit only on success
        vol.commit()
    except Exception:
        # Don't commit on failure
        raise
```

## Modal Dict

Distributed key-value store with optional TTL.

### Basic Usage

```python
d = modal.Dict.from_name("cache", create_if_missing=True)

# Set value
d["key"] = "value"

# Get value
value = d["key"]

# With TTL (expires in 1 hour)
d.put("key", "value", ttl=3600)

# Check existence
if "key" in d:
    value = d["key"]

# Delete
del d["key"]
```

### Use Cases

```python
# Caching expensive computations
@app.function()
def cached_compute(key: str):
    cache = modal.Dict.from_name("compute-cache", create_if_missing=True)

    if key in cache:
        return cache[key]

    result = expensive_computation(key)
    cache.put(key, result, ttl=3600)  # Cache for 1 hour
    return result

# Rate limiting
@app.function()
def rate_limited_api(user_id: str):
    limits = modal.Dict.from_name("rate-limits", create_if_missing=True)

    count = limits.get(user_id, 0)
    if count >= 100:
        raise Exception("Rate limit exceeded")

    limits.put(user_id, count + 1, ttl=3600)
    return process_request()
```

## Modal Queue

Distributed message queue for async task processing.

### Basic Usage

```python
q = modal.Queue.from_name("tasks", create_if_missing=True)

# Producer
@app.function()
def submit_task(data):
    q.put(data)

# Consumer
@app.function()
def process_tasks():
    while True:
        task = q.get()
        if task is None:
            break
        process(task)
```

### Queue with Timeout

```python
@app.function()
def consumer():
    q = modal.Queue.from_name("tasks")

    # Wait up to 10 seconds for item
    task = q.get(timeout=10)

    # Non-blocking check
    task = q.get(block=False)  # Returns None if empty
```

### Fan-Out Pattern

```python
@app.function()
def coordinator(items):
    q = modal.Queue.from_name("work-queue", create_if_missing=True)
    results_q = modal.Queue.from_name("results-queue", create_if_missing=True)

    # Submit all work
    for item in items:
        q.put(item)

    # Signal end
    for _ in range(NUM_WORKERS):
        q.put(None)

    # Collect results
    results = []
    for _ in range(len(items)):
        results.append(results_q.get())

    return results

@app.function()
def worker():
    q = modal.Queue.from_name("work-queue")
    results_q = modal.Queue.from_name("results-queue")

    while True:
        item = q.get()
        if item is None:
            break
        result = process(item)
        results_q.put(result)
```

## CloudBucketMount

Mount S3 or GCS buckets directly into Modal functions.

### S3 Mount

```python
# Read-only mount
s3_mount = modal.CloudBucketMount(
    bucket_name="my-bucket",
    secret=modal.Secret.from_name("aws-creds"),
)

@app.function(volumes={"/s3": s3_mount})
def read_from_s3():
    with open("/s3/path/to/file.txt") as f:
        return f.read()

# Read-write mount (for writing)
s3_mount_rw = modal.CloudBucketMount(
    bucket_name="my-bucket",
    secret=modal.Secret.from_name("aws-creds"),
    read_only=False,
)

@app.function(volumes={"/s3": s3_mount_rw})
def write_to_s3():
    with open("/s3/output/result.txt", "w") as f:
        f.write("data")
```

### GCS Mount

```python
gcs_mount = modal.CloudBucketMount(
    bucket_name="my-gcs-bucket",
    secret=modal.Secret.from_name("gcp-creds"),
)

@app.function(volumes={"/gcs": gcs_mount})
def process_from_gcs():
    # Access files like local filesystem
    for file in os.listdir("/gcs/data"):
        process(f"/gcs/data/{file}")
```

### Required Secrets

```bash
# AWS credentials
modal secret create aws-creds \
  AWS_ACCESS_KEY_ID=xxx \
  AWS_SECRET_ACCESS_KEY=xxx

# GCP credentials (JSON key file)
modal secret create gcp-creds \
  GOOGLE_APPLICATION_CREDENTIALS_JSON='{"type":"service_account",...}'
```

## Storage Comparison

| Feature | Volume | Dict | Queue | CloudBucket |
|---------|--------|------|-------|-------------|
| Persistence | Yes | Optional (TTL) | No | Yes (external) |
| Use case | Files | Key-value | Messages | External data |
| Access | Mount path | API | API | Mount path |
| Concurrency | Single writer | Multi | Multi | Multi |
| Latency | ~10-100ms | ~10ms | ~10ms | ~50-200ms |

## Complete Example: Data Pipeline

```python
import modal

app = modal.App("data-pipeline")

# Storage setup
data_vol = modal.Volume.from_name("pipeline-data", create_if_missing=True)
task_queue = modal.Queue.from_name("tasks", create_if_missing=True)
status_dict = modal.Dict.from_name("status", create_if_missing=True)

s3_input = modal.CloudBucketMount(
    bucket_name="input-data",
    secret=modal.Secret.from_name("aws-creds"),
)

@app.function(
    volumes={"/input": s3_input, "/output": data_vol},
)
def process_file(filename: str):
    status_dict[filename] = "processing"

    # Read from S3
    with open(f"/input/{filename}") as f:
        data = f.read()

    # Process
    result = transform(data)

    # Write to volume
    with open(f"/output/{filename}", "w") as f:
        f.write(result)
    data_vol.commit()

    status_dict[filename] = "completed"
    return filename

@app.function()
def coordinator(files: list[str]):
    # Submit all files
    for f in files:
        task_queue.put(f)

    # Process in parallel
    results = list(process_file.map(files))

    # Check status
    for f in files:
        print(f"{f}: {status_dict[f]}")

    return results
```
