# Modal: Parallel Processing, Volumes, Testing

Larger Modal patterns: `.map()` / `.starmap()` parallelism, distributed batch processing, Modal Volumes for persistent storage (datasets, model weights, caches), and complete pytest-style test harnesses (mocking Modal stubs, integration tests). SKILL.md keeps type-safe functions, async patterns, classes, FastAPI, and scheduled tasks; this reference holds the heavier data + test material.

## Parallel Processing

### Map and Starmap with Types

```python
import modal
from pydantic import BaseModel
from typing import Iterator

app = modal.App("parallel-processing")

image = modal.Image.debian_slim(python_version="3.11").pip_install("pydantic", "httpx")


class ProcessingInput(BaseModel):
    id: str
    data: str


class ProcessingOutput(BaseModel):
    id: str
    result: str
    success: bool


@app.function(image=image, timeout=300)
def process_single(input_data: ProcessingInput) -> ProcessingOutput:
    """Process a single item."""
    try:
        # Your processing logic
        result = f"Processed: {input_data.data.upper()}"
        return ProcessingOutput(id=input_data.id, result=result, success=True)
    except Exception as e:
        return ProcessingOutput(id=input_data.id, result=str(e), success=False)


@app.function(image=image)
def process_batch(inputs: list[ProcessingInput]) -> list[ProcessingOutput]:
    """Process multiple items in parallel."""
    # map() distributes work across containers
    results = list(process_single.map(inputs))
    return results


@app.function(image=image, timeout=300)
def process_with_args(data: str, multiplier: int, prefix: str) -> str:
    """Function with multiple arguments."""
    return f"{prefix}: {data * multiplier}"


@app.function(image=image)
def process_batch_with_args(
    data_list: list[str],
    multipliers: list[int],
    prefixes: list[str],
) -> list[str]:
    """Use starmap for multiple arguments."""
    # starmap unpacks arguments
    args = list(zip(data_list, multipliers, prefixes))
    results = list(process_with_args.starmap(args))
    return results


@app.function(image=image)
def process_with_generator() -> Iterator[ProcessingOutput]:
    """Use map with generator for memory efficiency."""
    def input_generator() -> Iterator[ProcessingInput]:
        for i in range(1000):
            yield ProcessingInput(id=str(i), data=f"item_{i}")

    # Generator is consumed lazily
    for result in process_single.map(input_generator()):
        yield result


@app.local_entrypoint()
def main():
    # Batch processing example
    inputs = [
        ProcessingInput(id="1", data="hello"),
        ProcessingInput(id="2", data="world"),
        ProcessingInput(id="3", data="test"),
    ]

    results = process_batch.remote(inputs)
    for result in results:
        print(f"{result.id}: {result.result} (success={result.success})")

    # Starmap example
    data = ["a", "b", "c"]
    multipliers = [2, 3, 4]
    prefixes = ["Item", "Item", "Item"]

    starmap_results = process_batch_with_args.remote(data, multipliers, prefixes)
    print(starmap_results)  # ['Item: aa', 'Item: bbb', 'Item: cccc']
```

---

## Modal Volumes

### Type-Safe Volume Operations

```python
import modal
from pydantic import BaseModel
from pathlib import Path
from datetime import datetime
import json

app = modal.App("volume-example")

image = modal.Image.debian_slim(python_version="3.11").pip_install("pydantic")

# Create persistent volume
data_volume = modal.Volume.from_name("app-data", create_if_missing=True)


class DataRecord(BaseModel):
    """Data record with validation."""
    id: str
    content: str
    created_at: datetime
    metadata: dict[str, str] = {}


class StorageResult(BaseModel):
    """Result of storage operation."""
    success: bool
    path: str
    size_bytes: int
    message: str


@app.function(
    image=image,
    volumes={"/data": data_volume},
)
def save_record(record: DataRecord) -> StorageResult:
    """Save record to volume."""
    file_path = Path(f"/data/records/{record.id}.json")
    file_path.parent.mkdir(parents=True, exist_ok=True)

    # Write JSON
    content = record.model_dump_json(indent=2)
    file_path.write_text(content)

    # CRITICAL: Commit changes to persist
    data_volume.commit()

    return StorageResult(
        success=True,
        path=str(file_path),
        size_bytes=len(content),
        message=f"Saved record {record.id}",
    )


@app.function(
    image=image,
    volumes={"/data": data_volume},
)
def load_record(record_id: str) -> DataRecord | None:
    """Load record from volume."""
    file_path = Path(f"/data/records/{record_id}.json")

    if not file_path.exists():
        return None

    content = file_path.read_text()
    return DataRecord.model_validate_json(content)


@app.function(
    image=image,
    volumes={"/data": data_volume},
)
def list_records() -> list[str]:
    """List all record IDs."""
    records_dir = Path("/data/records")

    if not records_dir.exists():
        return []

    return [f.stem for f in records_dir.glob("*.json")]


@app.function(
    image=image,
    volumes={"/data": data_volume},
    ephemeral_disk=10 * 1024,  # 10GB temp disk
)
def process_large_files(input_path: str, output_path: str) -> StorageResult:
    """Process large files with ephemeral disk."""
    import shutil

    # Copy from volume to fast ephemeral disk
    volume_input = Path(f"/data/{input_path}")
    temp_input = Path(f"/tmp/{input_path}")
    temp_output = Path(f"/tmp/output_{input_path}")

    shutil.copy(volume_input, temp_input)

    # Process on ephemeral disk (faster I/O)
    content = temp_input.read_bytes()
    processed = content.upper()  # Example processing
    temp_output.write_bytes(processed)

    # Copy result back to volume
    volume_output = Path(f"/data/{output_path}")
    shutil.copy(temp_output, volume_output)

    # Commit changes
    data_volume.commit()

    return StorageResult(
        success=True,
        path=str(volume_output),
        size_bytes=len(processed),
        message="Processing complete",
    )


@app.local_entrypoint()
def main():
    # Save a record
    record = DataRecord(
        id="test-001",
        content="Hello, Modal!",
        created_at=datetime.utcnow(),
        metadata={"source": "test"},
    )

    result = save_record.remote(record)
    print(f"Saved: {result.path} ({result.size_bytes} bytes)")

    # Load it back
    loaded = load_record.remote("test-001")
    if loaded:
        print(f"Loaded: {loaded.content}")

    # List all records
    records = list_records.remote()
    print(f"All records: {records}")
```

---

## Testing Modal Functions

### pytest Integration

```python
# tests/test_modal_functions.py
import pytest
from datetime import datetime
from unittest.mock import Mock, patch

# Import your Modal functions
from app import (
    process_data,
    ProcessingRequest,
    ProcessingResponse,
    ProcessingConfig,
)


class TestProcessingModels:
    """Test Pydantic models."""

    def test_valid_config(self):
        config = ProcessingConfig(
            model_name="gpt2",
            batch_size=64,
            temperature=0.8,
        )
        assert config.model_name == "gpt2"
        assert config.batch_size == 64

    def test_invalid_model_name(self):
        with pytest.raises(ValueError, match="Model must be one of"):
            ProcessingConfig(model_name="invalid-model")

    def test_config_defaults(self):
        config = ProcessingConfig(model_name="gpt2")
        assert config.batch_size == 32  # Default
        assert config.temperature == 0.7  # Default
        assert config.mode == "balanced"  # Default

    def test_request_validation(self):
        config = ProcessingConfig(model_name="gpt2")
        request = ProcessingRequest(
            text="Hello, world!",
            config=config,
            user_id="user_123",
        )
        assert request.text == "Hello, world!"

    def test_invalid_user_id(self):
        config = ProcessingConfig(model_name="gpt2")
        with pytest.raises(ValueError):
            ProcessingRequest(
                text="Test",
                config=config,
                user_id="invalid@email",  # Doesn't match pattern
            )


class TestModalFunctions:
    """Test Modal functions locally."""

    def test_process_data_local(self):
        """Test function logic without Modal runtime."""
        # Call .local() to run without Modal
        result = process_data.local(["hello", "world"], multiplier=2)

        assert isinstance(result, dict)
        assert result["hello"] == 10  # len("hello") * 2
        assert result["world"] == 10

    def test_process_data_empty(self):
        result = process_data.local([], multiplier=1)
        assert result == {}

    @pytest.mark.asyncio
    async def test_async_function_local(self):
        """Test async Modal function."""
        from app import fetch_url

        # Mock the HTTP call
        with patch("httpx.AsyncClient") as mock_client:
            mock_response = Mock()
            mock_response.status_code = 200
            mock_response.content = b"test content"

            mock_client.return_value.__aenter__.return_value.get.return_value = mock_response

            result = await fetch_url.local("https://example.com")

            assert result["status"] == 200
            assert result["length"] == 12


class TestProcessingPipeline:
    """Integration tests for processing pipeline."""

    @pytest.fixture
    def sample_request(self):
        return ProcessingRequest(
            text="Test input for processing",
            config=ProcessingConfig(model_name="gpt2"),
            user_id="test_user",
        )

    def test_full_pipeline_local(self, sample_request):
        """Test full processing pipeline locally."""
        from app import process_with_validation

        response = process_with_validation.local(sample_request)

        assert isinstance(response, ProcessingResponse)
        assert response.model_name == "gpt2"
        assert response.tokens_used > 0
        assert response.latency_ms >= 0


# === Fixtures for Modal testing ===

@pytest.fixture
def mock_volume():
    """Mock Modal volume for testing."""
    with patch("modal.Volume.from_name") as mock:
        yield mock


@pytest.fixture
def mock_gpu():
    """Mock GPU availability."""
    with patch("torch.cuda.is_available", return_value=True):
        yield
```

### Running Tests

```bash
# Run all tests
pytest tests/ -v

# Run with coverage
pytest tests/ --cov=app --cov-report=html

# Run specific test class
pytest tests/test_modal_functions.py::TestProcessingModels -v

# Run async tests
pytest tests/ -v --asyncio-mode=auto
```

### pytest Configuration

```toml
# pyproject.toml
[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
python_functions = ["test_*"]
asyncio_mode = "auto"
addopts = "-v --tb=short"

[tool.coverage.run]
source = ["app"]
omit = ["tests/*"]
```

---

