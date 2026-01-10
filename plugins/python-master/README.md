# Python Master Plugin

Comprehensive Python expertise for Claude Code, covering modern Python 3.13+ development, async programming, type hints, FastAPI, testing, Cloudflare deployment, and GitHub Actions optimization.

## Features

This plugin provides expertise in:

- **Python 3.13+ Features** - Free-threading, JIT, pattern matching, type parameters
- **Asyncio Mastery** - TaskGroup, semaphores, uvloop, async patterns
- **Type Hints** - Protocols, TypedDict, generics, mypy/pyright
- **Package Management** - uv, pyproject.toml, src layout, Ruff
- **FastAPI** - Production patterns, Pydantic, async handlers
- **Testing** - pytest, fixtures, mocking, coverage, async tests
- **Cloudflare** - Python Workers, Containers, cold start optimization
- **GitHub Actions** - uv CI/CD, caching, matrix builds, PyPI publishing
- **Security** - OWASP compliance, input validation, secrets management
- **Performance** - Memory profiling, optimization techniques
- **OpenCV** - Computer vision, image/video processing, BGR gotchas, DNN inference
- **FFmpeg** - Video/audio processing, encoding, streaming, ffmpeg-python, PyAV
- **Video Pipelines** - FFmpeg + OpenCV + Modal.com integration, parallel processing, GPU acceleration

## Skills

| Skill | Description |
|-------|-------------|
| `python-fundamentals-313` | Python 3.13+ features, syntax, memory optimizations |
| `python-asyncio` | Async/await patterns, TaskGroup, performance |
| `python-type-hints` | Modern type hints, Protocols, generics |
| `python-package-management` | uv, pyproject.toml, Ruff, project structure |
| `python-fastapi` | FastAPI production patterns, Pydantic, deployment |
| `python-testing` | pytest, fixtures, mocking, coverage |
| `python-cloudflare` | Workers, Containers, optimization |
| `python-github-actions` | CI/CD workflows, caching, publishing |
| `python-gotchas` | Common pitfalls and how to avoid them |
| `python-opencv` | Computer vision, image/video processing, BGR handling |
| `python-ffmpeg` | Video/audio encoding, streaming, ffmpeg-python, PyAV |
| `python-video-pipeline` | FFmpeg + OpenCV + Modal integration, parallel GPU processing |

## Commands

| Command | Description |
|---------|-------------|
| `/python-init` | Initialize a new Python project with best practices |
| `/python-test` | Run tests with coverage report |

## Quick Reference

### Modern Python (3.12+)

```python
# Type parameters
def first[T](items: list[T]) -> T:
    return items[0]

# Pattern matching
match command:
    case {"action": "create", "name": str(name)}:
        return create(name)
    case _:
        return error()

# Type alias
type JsonValue = str | int | float | bool | None | list["JsonValue"]
```

### Async Patterns

```python
import asyncio

async def fetch_all(urls: list[str]) -> list[dict]:
    async with asyncio.TaskGroup() as tg:
        tasks = [tg.create_task(fetch(url)) for url in urls]
    return [task.result() for task in tasks]
```

### FastAPI

```python
from fastapi import FastAPI, Depends
from pydantic import BaseModel

app = FastAPI()

class Item(BaseModel):
    name: str
    price: float

@app.post("/items/")
async def create_item(item: Item):
    return item
```

### uv Package Management

```bash
# Create project
uv init my-project

# Add dependencies
uv add fastapi pydantic

# Run with virtual env
uv run python main.py

# Sync from lockfile
uv sync
```

### pytest Testing

```python
import pytest

@pytest.fixture
def sample_data():
    return {"key": "value"}

@pytest.mark.asyncio
async def test_async_function(sample_data):
    result = await process(sample_data)
    assert result is not None
```

### Cloudflare Workers

```python
from workers import Response, WorkerEntrypoint

class Default(WorkerEntrypoint):
    async def fetch(self, request):
        return Response("Hello from Python Worker!")
```

### GitHub Actions

```yaml
- uses: astral-sh/setup-uv@v4
  with:
    enable-cache: true
- run: uv sync
- run: uv run pytest
```

### OpenCV

```python
import cv2
import numpy as np

# CRITICAL: OpenCV uses BGR, not RGB!
img = cv2.imread("image.jpg")  # BGR format

# Convert to RGB for Matplotlib/PIL
rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

# Coordinate gotcha: img[y, x] not img[x, y]
pixel = img[100, 200]  # row=100 (y), col=200 (x)

# Always check if image loaded
if img is None:
    raise FileNotFoundError("Image not found")

# Video capture with proper cleanup
cap = cv2.VideoCapture(0)
try:
    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break
        # Process frame...
finally:
    cap.release()
    cv2.destroyAllWindows()
```

### FFmpeg

```python
import ffmpeg

# CRITICAL: Video filters can drop audio!
# BAD: Audio is lost
ffmpeg.input('input.mp4').filter('scale', 1280, 720).output('out.mp4').run()

# GOOD: Explicitly handle both streams
input_file = ffmpeg.input('input.mp4')
video = input_file.video.filter('scale', 1280, 720)
audio = input_file.audio
ffmpeg.output(video, audio, 'output.mp4').overwrite_output().run()

# Get video info
probe = ffmpeg.probe('video.mp4')
duration = float(probe['format']['duration'])

# H.264 encoding with quality control
ffmpeg.input('input.mp4').output('output.mp4',
    vcodec='libx264',
    crf=23,           # 0=lossless, 23=default, 51=worst
    preset='medium',  # ultrafast to veryslow
    acodec='aac',
    audio_bitrate='192k'
).overwrite_output().run()

# Extract audio
ffmpeg.input('video.mp4').output('audio.mp3',
    acodec='libmp3lame',
    audio_bitrate='320k',
    vn=None  # No video
).overwrite_output().run()

# Always use overwrite_output() to avoid prompts
# Always handle errors with try/except ffmpeg.Error
```

### Video Pipeline (FFmpeg + OpenCV + Modal)

```python
import modal

# Modal image with FFmpeg and OpenCV
image = (
    modal.Image.debian_slim()
    .apt_install("ffmpeg", "libsm6", "libxext6", "libgl1")
    .pip_install("opencv-python-headless", "ffmpeg-python", "numpy")
)

app = modal.App("video-pipeline", image=image)

@app.function(gpu="T4")
def process_video(video_bytes: bytes) -> bytes:
    """Process video with GPU acceleration."""
    import cv2
    import numpy as np
    import tempfile

    # Write input to temp file
    with tempfile.NamedTemporaryFile(suffix='.mp4') as f:
        f.write(video_bytes)
        cap = cv2.VideoCapture(f.name)

    # Process frames...
    # CRITICAL: Color format - OpenCV=BGR, FFmpeg=RGB by default
    # CRITICAL: Frame shape - img[y, x] not img[x, y]

    return processed_bytes

# Parallel frame processing
@app.function()
def process_frame(frame_data: bytes) -> bytes:
    import cv2
    import numpy as np
    nparr = np.frombuffer(frame_data, np.uint8)
    frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    processed = cv2.GaussianBlur(frame, (5, 5), 0)
    _, encoded = cv2.imencode('.png', processed)
    return encoded.tobytes()

# Use .map() for parallel processing
results = list(process_frame.map(frame_list))
```

## Best Practices Covered

### Code Quality
- Type annotations for all public APIs
- Ruff for consistent formatting/linting
- Mypy strict mode for type safety

### Project Structure
- src layout for packages
- pyproject.toml for all configuration
- uv for fast, reproducible environments

### Testing
- pytest with fixtures
- 80%+ code coverage
- Async test support

### Performance
- Async for I/O-bound operations
- Memory profiling with memray/tracemalloc
- Efficient data structures

### Security
- Input validation with Pydantic
- Parameterized queries
- Dependency auditing with pip-audit

## Installation

### Via GitHub Marketplace (Recommended)

```bash
/plugin marketplace add claude-plugin-marketplace
/plugin install python-master@claude-plugin-marketplace
```

### Local Installation (Mac/Linux)

```bash
unzip python-master.zip -d ~/.local/share/claude/plugins/
```

## License

MIT

## Links

- **Plugin Repository:** [claude-plugin-marketplace](https://github.com/JosiahSiegel/claude-plugin-marketplace)
- **Python Docs:** https://docs.python.org/3/
- **FastAPI Docs:** https://fastapi.tiangolo.com/
- **uv Docs:** https://docs.astral.sh/uv/
- **Ruff Docs:** https://docs.astral.sh/ruff/
- **OpenCV Docs:** https://docs.opencv.org/
- **FFmpeg Docs:** https://ffmpeg.org/documentation.html
- **ffmpeg-python:** https://github.com/kkroening/ffmpeg-python
- **PyAV Docs:** https://pyav.org/docs/stable/
- **Modal.com Docs:** https://modal.com/docs
- **ffmpegcv:** https://github.com/chenxinfeng4/ffmpegcv
- **VidGear:** https://abhitronix.github.io/vidgear/
- **Decord:** https://github.com/dmlc/decord
