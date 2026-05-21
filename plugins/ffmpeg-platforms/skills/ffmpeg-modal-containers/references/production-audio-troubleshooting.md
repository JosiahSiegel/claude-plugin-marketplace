# FFmpeg on Modal: Production Patterns, Audio (Whisper), Troubleshooting

Production-grade patterns for running FFmpeg jobs on Modal containers (queueing, retries, progress reporting, monitoring, cost guards), Whisper-based audio transcription pipelines, and a troubleshooting catalogue. SKILL.md keeps the basic setup, GPU containers, parallel processing, and volumes; this reference holds the production + audio material.

## Production Patterns

### Error Handling and Retries

```python
import modal
from modal import Retries

app = modal.App("production-ffmpeg")

ffmpeg_image = modal.Image.debian_slim().apt_install("ffmpeg")

@app.function(
    image=ffmpeg_image,
    retries=Retries(
        max_retries=3,
        initial_delay=1.0,
        backoff_coefficient=2.0,
    ),
    timeout=600,
)
def reliable_transcode(video_bytes: bytes) -> bytes:
    """Transcode with automatic retries."""
    import subprocess
    import tempfile

    with tempfile.TemporaryDirectory() as tmpdir:
        input_path = Path(tmpdir) / "input"
        output_path = Path(tmpdir) / "output.mp4"

        input_path.write_bytes(video_bytes)

        result = subprocess.run([
            "ffmpeg", "-y",
            "-i", str(input_path),
            "-c:v", "libx264",
            "-preset", "fast",
            "-crf", "23",
            str(output_path)
        ], capture_output=True, text=True)

        if result.returncode != 0:
            # Log error for debugging
            print(f"FFmpeg stderr: {result.stderr}")
            raise RuntimeError(f"FFmpeg failed: {result.returncode}")

        return output_path.read_bytes()
```

### Webhook Integration

```python
import modal

app = modal.App("ffmpeg-webhook")

ffmpeg_image = modal.Image.debian_slim().apt_install("ffmpeg", "curl")

@app.function(image=ffmpeg_image)
def transcode_with_webhook(
    video_bytes: bytes,
    webhook_url: str,
    job_id: str
) -> str:
    """Transcode and notify webhook on completion."""
    import subprocess
    import tempfile
    import json

    with tempfile.TemporaryDirectory() as tmpdir:
        input_path = Path(tmpdir) / "input"
        output_path = Path(tmpdir) / "output.mp4"

        input_path.write_bytes(video_bytes)

        try:
            subprocess.run([
                "ffmpeg", "-y",
                "-i", str(input_path),
                "-c:v", "libx264",
                "-preset", "fast",
                "-crf", "23",
                str(output_path)
            ], check=True, capture_output=True)

            status = "success"
            output_size = output_path.stat().st_size

        except subprocess.CalledProcessError as e:
            status = "failed"
            output_size = 0

        # Notify webhook
        payload = json.dumps({
            "job_id": job_id,
            "status": status,
            "output_size": output_size
        })

        subprocess.run([
            "curl", "-X", "POST",
            "-H", "Content-Type: application/json",
            "-d", payload,
            webhook_url
        ], check=True)

        return status
```

### Web Endpoint

```python
import modal
from fastapi import FastAPI, UploadFile, BackgroundTasks
from fastapi.responses import StreamingResponse
import io

app = modal.App("ffmpeg-api")

ffmpeg_image = (
    modal.Image.debian_slim()
    .apt_install("ffmpeg")
    .pip_install("fastapi[standard]", "python-multipart")
)

web_app = FastAPI()

@web_app.post("/transcode")
async def transcode_endpoint(file: UploadFile):
    """HTTP endpoint for video transcoding."""
    import subprocess
    import tempfile

    with tempfile.TemporaryDirectory() as tmpdir:
        input_path = Path(tmpdir) / "input"
        output_path = Path(tmpdir) / "output.mp4"

        # Save uploaded file
        content = await file.read()
        input_path.write_bytes(content)

        # Transcode
        subprocess.run([
            "ffmpeg", "-y",
            "-i", str(input_path),
            "-c:v", "libx264",
            "-preset", "ultrafast",
            "-crf", "28",
            str(output_path)
        ], check=True, capture_output=True)

        # Stream response
        output_bytes = output_path.read_bytes()
        return StreamingResponse(
            io.BytesIO(output_bytes),
            media_type="video/mp4",
            headers={"Content-Disposition": "attachment; filename=output.mp4"}
        )

@app.function(image=ffmpeg_image)
@modal.asgi_app()
def fastapi_app():
    return web_app
```

## Audio Processing with Whisper

Complete pattern for audio transcription and processing:

```python
import modal

app = modal.App("whisper-ffmpeg")

# Image with FFmpeg and Whisper dependencies
whisper_image = (
    modal.Image.debian_slim(python_version="3.12")
    .apt_install("ffmpeg")
    .pip_install(
        "transformers[torch]",
        "accelerate",
        "torch",
        "torchaudio",
    )
)

@app.function(image=whisper_image, gpu="T4", timeout=600)
def transcribe_video(video_bytes: bytes) -> dict:
    """Extract audio from video and transcribe with Whisper."""
    import subprocess
    import tempfile
    from transformers import pipeline

    with tempfile.TemporaryDirectory() as tmpdir:
        video_path = Path(tmpdir) / "video.mp4"
        audio_path = Path(tmpdir) / "audio.wav"

        video_path.write_bytes(video_bytes)

        # Extract audio with FFmpeg
        subprocess.run([
            "ffmpeg", "-y",
            "-i", str(video_path),
            "-vn",                    # No video
            "-acodec", "pcm_s16le",   # WAV format
            "-ar", "16000",           # 16kHz for Whisper
            "-ac", "1",               # Mono
            str(audio_path)
        ], check=True, capture_output=True)

        # Transcribe with Whisper
        transcriber = pipeline(
            "automatic-speech-recognition",
            model="openai/whisper-base",
            device="cuda"
        )

        result = transcriber(str(audio_path))

        return {
            "text": result["text"],
            "audio_duration": get_duration(str(audio_path))
        }

def get_duration(audio_path: str) -> float:
    """Get audio duration using FFprobe."""
    import subprocess
    import json

    result = subprocess.run([
        "ffprobe",
        "-v", "quiet",
        "-print_format", "json",
        "-show_format",
        audio_path
    ], capture_output=True, text=True)

    data = json.loads(result.stdout)
    return float(data["format"]["duration"])
```

## Troubleshooting

### Common Issues

**FFmpeg not found:**
```python
# Verify FFmpeg is installed in your image
@app.function(image=ffmpeg_image)
def check_ffmpeg():
    import subprocess
    result = subprocess.run(["ffmpeg", "-version"], capture_output=True, text=True)
    print(result.stdout)
    return result.returncode == 0
```

**Out of memory:**
```python
# Increase memory allocation
@app.function(image=ffmpeg_image, memory=16384)  # 16 GB
def process_large_video(video_bytes: bytes):
    pass
```

**Timeout errors:**
```python
# Increase timeout for long operations
@app.function(image=ffmpeg_image, timeout=3600)  # 1 hour
def transcode_4k_video(video_bytes: bytes):
    pass
```

**Volume not persisting:**
```python
# Always call commit() after writing to volume
@app.function(volumes={"/data": video_volume})
def write_to_volume():
    Path("/data/output.mp4").write_bytes(data)
    video_volume.commit()  # Critical!
```

### Debugging FFmpeg Commands

```python
@app.function(image=ffmpeg_image)
def debug_transcode(video_bytes: bytes):
    """Transcode with full debugging output."""
    import subprocess

    result = subprocess.run([
        "ffmpeg", "-y",
        "-v", "verbose",  # Verbose logging
        "-i", "input.mp4",
        "-c:v", "libx264",
        "output.mp4"
    ], capture_output=True, text=True)

    print("STDOUT:", result.stdout)
    print("STDERR:", result.stderr)
    print("Return code:", result.returncode)

    return result.returncode == 0
```

## Cost Optimization

### CPU vs GPU Pricing

```python
# Modal pricing (approximate, 2025):
# - CPU: ~$0.000024/vCPU-second
# - Memory: ~$0.0000025/GiB-second
# - T4 GPU: ~$0.000164/second ($0.59/hour)
# - A10G GPU: ~$0.000306/second ($1.10/hour)
# - L40S GPU: ~$0.000542/second ($1.95/hour)

# For a 10-second video transcode:
# - CPU (4 cores, 10 seconds): ~$0.001
# - GPU (T4, 2 seconds): ~$0.0003

# For 1000 videos:
# - CPU: ~$1.00, parallelized across 100 containers = ~10 seconds wall time
# - GPU: ~$0.30, but harder to parallelize

# Recommendation: Use CPU for transcoding, GPU for ML inference
```

### Resource Configuration

```python
@app.function(
    image=ffmpeg_image,
    cpu=4,          # 4 CPU cores
    memory=8192,    # 8 GB RAM
    timeout=300,    # 5 minute timeout
)
def optimized_transcode(video_bytes: bytes) -> bytes:
    """Transcode with optimized resource allocation."""
    # Use all available CPU cores
    subprocess.run([
        "ffmpeg", "-y",
        "-threads", "4",  # Match CPU allocation
        "-i", "input.mp4",
        "-c:v", "libx264",
        "-preset", "fast",
        "-crf", "23",
        "output.mp4"
    ], check=True)
```

### When to Use GPU

| Task | Recommendation | Reason |
|------|---------------|--------|
| Transcoding only | CPU | libx264 is fast, parallelizes well |
| Whisper transcription | GPU | ML inference, 10x+ faster |
| Video analysis (YOLO) | GPU | ML inference required |
| Thumbnail generation | CPU | Simple extraction |
| Audio normalization | CPU | No GPU benefit |
| NVENC encoding | GPU (verify) | May not be available |

