# Modal.com Video Processing Patterns Reference

Advanced patterns for video processing on Modal.com serverless infrastructure.

## Image Configuration Patterns

### Standard Video Processing Image

```python
import modal

# Basic video processing
video_image = (
    modal.Image.debian_slim(python_version="3.12")
    .apt_install(
        "ffmpeg",           # Video I/O
        "libsm6",           # OpenCV dependency
        "libxext6",         # OpenCV dependency
        "libgl1",           # OpenCV dependency
        "libglib2.0-0"      # GLib for video backends
    )
    .pip_install(
        "opencv-python-headless==4.9.0.80",
        "ffmpeg-python==0.2.0",
        "numpy>=1.24.0",
        "Pillow>=10.0.0"
    )
)
```

### GPU-Accelerated Image with NVENC/NVDEC

```python
# GPU video processing with NVIDIA acceleration
gpu_video_image = (
    modal.Image.from_registry(
        "nvidia/cuda:12.1.0-runtime-ubuntu22.04",
        add_python="3.12"
    )
    .apt_install(
        "ffmpeg",
        "libsm6",
        "libxext6",
        "libgl1",
        "libglib2.0-0"
    )
    .pip_install(
        "opencv-python-headless",
        "ffmpeg-python",
        "numpy",
        "torch>=2.0.0",
        "torchvision"
    )
)

app = modal.App("gpu-video", image=gpu_video_image)

@app.function(gpu="A100")
def process_with_gpu():
    import torch
    assert torch.cuda.is_available()
    # GPU processing here
```

### ffmpegcv GPU Image

```python
# Image with ffmpegcv for GPU-accelerated video I/O
ffmpegcv_image = (
    modal.Image.from_registry(
        "nvidia/cuda:12.1.0-runtime-ubuntu22.04",
        add_python="3.12"
    )
    .apt_install("ffmpeg")
    .pip_install(
        "ffmpegcv",
        "numpy",
        "opencv-python-headless"
    )
)

@app.function(gpu="T4", image=ffmpegcv_image)
def gpu_video_io():
    import ffmpegcv

    # GPU decode with NVDEC
    cap = ffmpegcv.VideoCaptureNV('video.mp4', gpu=0)

    # GPU encode with NVENC
    out = ffmpegcv.VideoWriterNV('output.mp4', 'h264_nvenc', fps=30)

    while True:
        ret, frame = cap.read()
        if not ret:
            break
        # Process frame
        out.write(frame)

    cap.release()
    out.release()
```

### Deep Learning Video Image with Decord

```python
# Image optimized for ML video training
ml_video_image = (
    modal.Image.debian_slim()
    .apt_install("ffmpeg", "git")
    .pip_install(
        "decord",
        "torch>=2.0.0",
        "torchvision",
        "numpy",
        "opencv-python-headless"
    )
)

@app.function(gpu="A100", image=ml_video_image)
def train_on_videos(video_paths: list[str]):
    import decord
    from decord import VideoReader
    import torch

    decord.bridge.set_bridge('torch')

    for path in video_paths:
        vr = VideoReader(path, ctx=decord.cpu())

        # Batch random frames for training
        indices = torch.randint(0, len(vr), (32,)).tolist()
        frames = vr.get_batch(indices)  # Returns torch tensor

        # frames shape: (batch, height, width, channels)
        # Train your model...
```

## Storage Patterns

### Using Volumes for Video Files

```python
import modal

app = modal.App("video-storage")

# Create persistent volume for videos
video_volume = modal.Volume.from_name("video-library", create_if_missing=True)

@app.function(volumes={"/videos": video_volume})
def process_video(filename: str):
    """Process video from persistent storage."""
    import cv2

    input_path = f"/videos/input/{filename}"
    output_path = f"/videos/output/{filename}"

    cap = cv2.VideoCapture(input_path)
    # Process...
    cap.release()

    # CRITICAL: Commit changes to persist them
    video_volume.commit()

@app.function(volumes={"/videos": video_volume})
def list_videos() -> list[str]:
    """List all videos in storage."""
    import os
    return os.listdir("/videos/input")
```

### Cloud Bucket Mount for Large Video Libraries

```python
import modal

app = modal.App("video-bucket")

# S3 bucket for video storage
s3_credentials = modal.Secret.from_dict({
    "AWS_ACCESS_KEY_ID": "...",
    "AWS_SECRET_ACCESS_KEY": "...",
    "AWS_REGION": "us-east-1"
})

@app.function(
    volumes={
        "/videos": modal.CloudBucketMount(
            "my-video-bucket",
            secret=s3_credentials
        )
    }
)
def process_from_s3(video_key: str):
    """Process video directly from S3 bucket."""
    import cv2

    # S3 path mounted as local filesystem
    local_path = f"/videos/{video_key}"
    cap = cv2.VideoCapture(local_path)

    # Process video...

# Cloudflare R2 (no egress fees)
r2_credentials = modal.Secret.from_dict({
    "AWS_ACCESS_KEY_ID": "...",
    "AWS_SECRET_ACCESS_KEY": "...",
    "AWS_ENDPOINT_URL": "https://<account_id>.r2.cloudflarestorage.com"
})

@app.function(
    volumes={
        "/videos": modal.CloudBucketMount(
            "my-r2-bucket",
            secret=r2_credentials,
            read_only=True  # For source videos
        )
    }
)
def stream_from_r2(video_key: str):
    pass
```

## Parallel Processing Patterns

### Frame-Level Parallelism with map()

```python
import modal

app = modal.App("frame-parallel")
image = modal.Image.debian_slim().pip_install("opencv-python-headless", "numpy")

@app.function(image=image)
def process_frame(frame_data: tuple[int, bytes]) -> tuple[int, bytes]:
    """Process a single frame."""
    import cv2
    import numpy as np

    idx, data = frame_data
    nparr = np.frombuffer(data, np.uint8)
    frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

    # Apply processing
    processed = cv2.Canny(frame, 100, 200)
    processed = cv2.cvtColor(processed, cv2.COLOR_GRAY2BGR)

    _, encoded = cv2.imencode('.jpg', processed)
    return idx, encoded.tobytes()

@app.function(image=image)
def parallel_video_process(video_bytes: bytes) -> bytes:
    """Process video with parallel frame processing."""
    import cv2
    import numpy as np
    import tempfile

    # Decode video to frames
    with tempfile.NamedTemporaryFile(suffix='.mp4', delete=False) as f:
        f.write(video_bytes)
        temp_path = f.name

    cap = cv2.VideoCapture(temp_path)
    fps = cap.get(cv2.CAP_PROP_FPS)
    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))

    frame_data = []
    idx = 0
    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break
        _, encoded = cv2.imencode('.jpg', frame)
        frame_data.append((idx, encoded.tobytes()))
        idx += 1
    cap.release()

    # Process frames in parallel
    results = list(process_frame.map(frame_data))

    # Sort by frame index
    results.sort(key=lambda x: x[0])

    # Reconstruct video
    output_path = temp_path.replace('.mp4', '_out.mp4')
    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    out = cv2.VideoWriter(output_path, fourcc, fps, (width, height))

    for _, frame_bytes in results:
        nparr = np.frombuffer(frame_bytes, np.uint8)
        frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        out.write(frame)
    out.release()

    with open(output_path, 'rb') as f:
        return f.read()
```

### Video-Level Parallelism with starmap()

```python
import modal

app = modal.App("video-parallel")

@app.function(timeout=600)
def transcode_single(input_path: str, output_path: str, quality: str) -> dict:
    """Transcode a single video."""
    import ffmpeg
    import time

    start = time.time()

    crf_map = {'high': 18, 'medium': 23, 'low': 28}
    crf = crf_map.get(quality, 23)

    (
        ffmpeg
        .input(input_path)
        .output(output_path, vcodec='libx264', crf=crf, acodec='aac')
        .overwrite_output()
        .run(quiet=True)
    )

    return {
        'input': input_path,
        'output': output_path,
        'quality': quality,
        'time': time.time() - start
    }

@app.function()
def batch_transcode(video_list: list[dict]) -> list[dict]:
    """Transcode multiple videos in parallel."""
    tasks = [
        (v['input'], v['output'], v.get('quality', 'medium'))
        for v in video_list
    ]

    results = list(transcode_single.starmap(tasks))
    return results

# Usage
@app.local_entrypoint()
def main():
    videos = [
        {'input': 'video1.mp4', 'output': 'out1.mp4', 'quality': 'high'},
        {'input': 'video2.mp4', 'output': 'out2.mp4', 'quality': 'medium'},
        {'input': 'video3.mp4', 'output': 'out3.mp4', 'quality': 'low'},
    ]
    results = batch_transcode.remote(videos)
    print(results)
```

### Chunk-Based Parallelism for Large Videos

```python
import modal

app = modal.App("chunk-parallel")
vol = modal.Volume.from_name("chunk-storage", create_if_missing=True)

@app.function(gpu="T4", timeout=300)
def process_chunk(chunk_info: dict) -> str:
    """Process a video chunk with GPU."""
    import subprocess
    import cv2

    input_path = chunk_info['input']
    start_time = chunk_info['start_time']
    duration = chunk_info['duration']
    output_path = chunk_info['output']

    # Extract chunk with FFmpeg
    subprocess.run([
        'ffmpeg', '-y',
        '-ss', str(start_time),
        '-i', input_path,
        '-t', str(duration),
        '-c', 'copy',
        f'/tmp/chunk.mp4'
    ], check=True, capture_output=True)

    # Process chunk
    cap = cv2.VideoCapture('/tmp/chunk.mp4')
    fps = cap.get(cv2.CAP_PROP_FPS)
    w = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    h = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))

    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    out = cv2.VideoWriter(output_path, fourcc, fps, (w, h))

    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break
        # GPU processing here
        processed = cv2.GaussianBlur(frame, (5, 5), 0)
        out.write(processed)

    cap.release()
    out.release()

    return output_path

@app.function(volumes={"/data": vol}, timeout=7200)
def process_large_video(input_path: str, chunk_duration: float = 30.0) -> str:
    """Process large video by chunking."""
    import ffmpeg
    import subprocess
    import os

    full_path = f"/data/{input_path}"

    # Get video duration
    probe = ffmpeg.probe(full_path)
    duration = float(probe['format']['duration'])

    # Create chunk tasks
    chunks = []
    chunk_idx = 0
    current_time = 0

    while current_time < duration:
        chunk_output = f"/data/chunks/chunk_{chunk_idx:04d}.mp4"
        chunks.append({
            'input': full_path,
            'start_time': current_time,
            'duration': min(chunk_duration, duration - current_time),
            'output': chunk_output
        })
        current_time += chunk_duration
        chunk_idx += 1

    os.makedirs("/data/chunks", exist_ok=True)

    # Process all chunks in parallel
    chunk_outputs = list(process_chunk.map(chunks))

    # Concatenate chunks
    list_file = "/data/chunks/list.txt"
    with open(list_file, 'w') as f:
        for path in sorted(chunk_outputs):
            f.write(f"file '{path}'\n")

    output_path = f"/data/processed_{os.path.basename(input_path)}"
    subprocess.run([
        'ffmpeg', '-y',
        '-f', 'concat',
        '-safe', '0',
        '-i', list_file,
        '-c', 'copy',
        output_path
    ], check=True)

    vol.commit()
    return output_path
```

## Web Endpoint Patterns

### Video Upload and Process API

```python
import modal

app = modal.App("video-api")
vol = modal.Volume.from_name("api-videos", create_if_missing=True)

image = (
    modal.Image.debian_slim()
    .apt_install("ffmpeg")
    .pip_install(
        "fastapi",
        "python-multipart",
        "opencv-python-headless",
        "ffmpeg-python",
        "numpy"
    )
)

@app.function(image=image, volumes={"/data": vol}, timeout=600)
@modal.web_endpoint(method="POST")
def upload_and_process(request: dict):
    """Upload video and start processing."""
    import base64
    import uuid
    import os

    video_data = base64.b64decode(request['video_base64'])
    job_id = str(uuid.uuid4())

    input_path = f"/data/uploads/{job_id}/input.mp4"
    os.makedirs(os.path.dirname(input_path), exist_ok=True)

    with open(input_path, 'wb') as f:
        f.write(video_data)

    vol.commit()

    # Start async processing
    process_video_async.spawn(job_id)

    return {"job_id": job_id, "status": "processing"}

@app.function(image=image, volumes={"/data": vol}, timeout=3600)
def process_video_async(job_id: str):
    """Process video asynchronously."""
    import cv2
    import os

    input_path = f"/data/uploads/{job_id}/input.mp4"
    output_path = f"/data/outputs/{job_id}/processed.mp4"

    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    cap = cv2.VideoCapture(input_path)
    fps = cap.get(cv2.CAP_PROP_FPS)
    w = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    h = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))

    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    out = cv2.VideoWriter(output_path, fourcc, fps, (w, h))

    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break
        processed = cv2.GaussianBlur(frame, (5, 5), 0)
        out.write(processed)

    cap.release()
    out.release()

    # Mark job as complete
    with open(f"/data/outputs/{job_id}/status.txt", 'w') as f:
        f.write("complete")

    vol.commit()

@app.function(image=image, volumes={"/data": vol})
@modal.web_endpoint(method="GET")
def check_status(job_id: str):
    """Check processing status."""
    import os

    status_file = f"/data/outputs/{job_id}/status.txt"
    output_file = f"/data/outputs/{job_id}/processed.mp4"

    if os.path.exists(status_file):
        with open(status_file) as f:
            status = f.read().strip()

        if status == "complete" and os.path.exists(output_file):
            return {
                "job_id": job_id,
                "status": "complete",
                "download_ready": True
            }

    return {"job_id": job_id, "status": "processing"}
```

### Streaming Response for Processed Video

```python
import modal

app = modal.App("video-stream")
vol = modal.Volume.from_name("stream-videos", create_if_missing=True)

image = (
    modal.Image.debian_slim()
    .apt_install("ffmpeg")
    .pip_install("fastapi", "opencv-python-headless")
)

@app.function(image=image, volumes={"/data": vol})
@modal.web_endpoint(method="GET")
def stream_video(job_id: str):
    """Stream processed video."""
    from fastapi.responses import StreamingResponse
    import os

    output_path = f"/data/outputs/{job_id}/processed.mp4"

    if not os.path.exists(output_path):
        return {"error": "Video not found"}

    def iter_file():
        with open(output_path, 'rb') as f:
            while chunk := f.read(1024 * 1024):  # 1MB chunks
                yield chunk

    return StreamingResponse(
        iter_file(),
        media_type="video/mp4",
        headers={
            "Content-Disposition": f"attachment; filename=processed_{job_id}.mp4"
        }
    )
```

## Cost Optimization Patterns

### GPU Selection Based on Task

```python
import modal

app = modal.App("optimized-video")

# T4: Best for light transcoding ($0.59/hr)
@app.function(gpu="T4")
def transcode_small(video_path: str):
    """Use T4 for videos < 1080p or simple effects."""
    pass

# A10G: Good balance for HD processing ($1.10/hr)
@app.function(gpu="A10G")
def process_hd(video_path: str):
    """Use A10G for 1080p processing."""
    pass

# A100-40GB: For 4K or ML inference ($3.24/hr)
@app.function(gpu="A100-40GB")
def process_4k(video_path: str):
    """Use A100 for 4K or heavy ML workloads."""
    pass

# H100: For maximum throughput ($4.93/hr)
@app.function(gpu="H100")
def process_batch_heavy(video_paths: list[str]):
    """Use H100 for high-throughput batch processing."""
    pass
```

### CPU-Only for Simple Tasks

```python
import modal

app = modal.App("cpu-video")

# Use CPU for metadata extraction, simple transcoding
@app.function(cpu=2.0, memory=4096)  # No GPU
def extract_metadata(video_path: str) -> dict:
    """CPU is sufficient for ffprobe."""
    import ffmpeg
    return ffmpeg.probe(video_path)

@app.function(cpu=4.0, memory=8192)  # No GPU
def simple_transcode(input_path: str, output_path: str):
    """CPU transcoding for non-time-critical tasks."""
    import ffmpeg

    (
        ffmpeg
        .input(input_path)
        .output(output_path, vcodec='libx264', preset='slow', crf=23)
        .run()
    )
```

### Spot Instances for Batch Processing

```python
import modal

app = modal.App("batch-video")

# Use spot for non-urgent batch jobs (cheaper but interruptible)
@app.function(
    gpu="A100",
    timeout=3600,
    retries=3  # Retry on preemption
)
def batch_process_with_retry(video_path: str) -> str:
    """Process with automatic retry on spot preemption."""
    import cv2

    # Save progress periodically
    checkpoint_interval = 100

    cap = cv2.VideoCapture(video_path)
    frame_count = 0

    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break

        # Process frame
        frame_count += 1

        # Checkpoint every N frames
        if frame_count % checkpoint_interval == 0:
            save_checkpoint(frame_count)

    return "complete"
```

## Error Handling Patterns

### Robust Video Processing

```python
import modal

app = modal.App("robust-video")

@app.function(timeout=600, retries=2)
def robust_process(video_path: str) -> dict:
    """Process video with comprehensive error handling."""
    import cv2
    import ffmpeg
    import os

    result = {
        'status': 'unknown',
        'input': video_path,
        'output': None,
        'error': None
    }

    # Validate input
    if not os.path.exists(video_path):
        result['status'] = 'error'
        result['error'] = 'Input file not found'
        return result

    # Probe video
    try:
        probe = ffmpeg.probe(video_path)
    except ffmpeg.Error as e:
        result['status'] = 'error'
        result['error'] = f'Invalid video file: {e.stderr.decode()}'
        return result

    # Check for video stream
    video_streams = [s for s in probe['streams'] if s['codec_type'] == 'video']
    if not video_streams:
        result['status'] = 'error'
        result['error'] = 'No video stream found'
        return result

    # Process video
    try:
        cap = cv2.VideoCapture(video_path)

        if not cap.isOpened():
            result['status'] = 'error'
            result['error'] = 'Failed to open video with OpenCV'
            return result

        fps = cap.get(cv2.CAP_PROP_FPS)
        if fps <= 0:
            fps = 30  # Default fallback

        width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
        height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))

        if width <= 0 or height <= 0:
            result['status'] = 'error'
            result['error'] = 'Invalid video dimensions'
            cap.release()
            return result

        output_path = video_path.replace('.mp4', '_processed.mp4')
        fourcc = cv2.VideoWriter_fourcc(*'mp4v')
        out = cv2.VideoWriter(output_path, fourcc, fps, (width, height))

        frame_count = 0
        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break

            # Process frame with error handling
            try:
                processed = cv2.GaussianBlur(frame, (5, 5), 0)
                out.write(processed)
                frame_count += 1
            except Exception as e:
                # Log but continue on frame errors
                print(f"Frame {frame_count} error: {e}")
                continue

        cap.release()
        out.release()

        if frame_count == 0:
            result['status'] = 'error'
            result['error'] = 'No frames processed'
            return result

        result['status'] = 'success'
        result['output'] = output_path
        result['frames_processed'] = frame_count

    except Exception as e:
        result['status'] = 'error'
        result['error'] = str(e)

    return result
```

## Monitoring and Logging

### Progress Tracking

```python
import modal

app = modal.App("monitored-video")
vol = modal.Volume.from_name("progress-tracking", create_if_missing=True)

@app.function(volumes={"/data": vol}, timeout=3600)
def process_with_progress(job_id: str, video_path: str):
    """Track processing progress."""
    import cv2
    import json
    import os

    progress_file = f"/data/progress/{job_id}.json"
    os.makedirs(os.path.dirname(progress_file), exist_ok=True)

    def update_progress(current_frame: int, total_frames: int, status: str):
        progress = {
            'job_id': job_id,
            'current_frame': current_frame,
            'total_frames': total_frames,
            'percentage': round(current_frame / total_frames * 100, 2),
            'status': status
        }
        with open(progress_file, 'w') as f:
            json.dump(progress, f)
        vol.commit()

    cap = cv2.VideoCapture(video_path)
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))

    update_progress(0, total_frames, 'processing')

    frame_idx = 0
    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break

        # Process frame...
        frame_idx += 1

        # Update progress every 100 frames
        if frame_idx % 100 == 0:
            update_progress(frame_idx, total_frames, 'processing')

    cap.release()
    update_progress(total_frames, total_frames, 'complete')

@app.function(volumes={"/data": vol})
@modal.web_endpoint(method="GET")
def get_progress(job_id: str):
    """Get processing progress."""
    import json
    import os

    progress_file = f"/data/progress/{job_id}.json"

    if os.path.exists(progress_file):
        with open(progress_file) as f:
            return json.load(f)

    return {"error": "Job not found"}
```

## Additional Resources

- [Modal GPU Docs](https://modal.com/docs/guide/gpu)
- [Modal Volumes Docs](https://modal.com/docs/guide/volumes)
- [Modal Cloud Bucket Mounts](https://modal.com/docs/guide/cloud-bucket-mounts)
- [Modal Parallel Execution](https://modal.com/docs/guide/scale)
- [Modal Web Endpoints](https://modal.com/docs/guide/webhooks)
