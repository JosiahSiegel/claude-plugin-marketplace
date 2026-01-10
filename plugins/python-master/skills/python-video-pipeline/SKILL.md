# Python Video Processing Pipeline Skill

Comprehensive guide to building video processing pipelines combining FFmpeg, OpenCV, and Modal.com for scalable, GPU-accelerated workflows.

## Quick Reference: Library Selection

| Use Case | Library | Why |
|----------|---------|-----|
| Simple frame extraction | OpenCV `VideoCapture` | Built-in, easy API |
| High-performance reading | ffmpegcv or Decord | 2x faster than OpenCV |
| Complex filter graphs | ffmpeg-python | Readable filter chains |
| Frame-level processing | PyAV | Direct FFmpeg bindings |
| Streaming (RTSP/RTMP) | VidGear | Multi-threaded, robust |
| Deep learning training | Decord | Batch loading, GPU decode |
| Serverless processing | Modal + any above | Auto-scaling, pay-per-use |

## Critical Integration Gotchas

### 1. Color Format Mismatch (MOST COMMON BUG)

```python
# CRITICAL: Different libraries use different color formats!

# OpenCV uses BGR
import cv2
frame_bgr = cv2.imread('image.jpg')  # BGR format

# FFmpeg outputs RGB by default
import ffmpeg
# When piping to OpenCV, specify bgr24
process = (
    ffmpeg
    .input('video.mp4')
    .output('pipe:', format='rawvideo', pix_fmt='bgr24')  # NOT rgb24!
    .run_async(pipe_stdout=True)
)

# PyAV outputs RGB
import av
container = av.open('video.mp4')
for frame in container.decode(video=0):
    rgb_array = frame.to_ndarray(format='rgb24')
    bgr_array = rgb_array[:, :, ::-1]  # Convert to BGR for OpenCV

# PIL/Pillow uses RGB
from PIL import Image
pil_image = Image.open('image.jpg')  # RGB
opencv_image = cv2.cvtColor(np.array(pil_image), cv2.COLOR_RGB2BGR)
```

### 2. Frame Dimension Order

```python
# NumPy/OpenCV: (height, width, channels) - img[y, x]
# Some ML frameworks: (channels, height, width) - img[c, y, x]

import numpy as np

# OpenCV frame shape
frame = cv2.imread('image.jpg')
height, width, channels = frame.shape  # (1080, 1920, 3)

# Access pixel: frame[row, col] = frame[y, x]
pixel = frame[100, 200]  # Row 100, Column 200

# Transpose for CHW format (PyTorch, etc.)
chw_frame = frame.transpose(2, 0, 1)  # (3, 1080, 1920)

# Or use np.moveaxis
chw_frame = np.moveaxis(frame, -1, 0)
```

### 3. Audio Stream Loss in Pipelines

```python
import ffmpeg

# BAD: Processing video loses audio!
input_file = ffmpeg.input('input.mp4')
processed = input_file.filter('scale', 1280, 720)
ffmpeg.output(processed, 'output.mp4').run()  # NO AUDIO!

# GOOD: Explicitly preserve audio
input_file = ffmpeg.input('input.mp4')
video = input_file.video.filter('scale', 1280, 720)
audio = input_file.audio
ffmpeg.output(video, audio, 'output.mp4').overwrite_output().run()

# When processing with OpenCV, re-mux audio separately
# Step 1: Process video frames with OpenCV
# Step 2: Extract original audio
ffmpeg.input('input.mp4').output('audio.aac', vn=None, acodec='copy').run()
# Step 3: Combine processed video with original audio
ffmpeg.input('processed_video.mp4').input('audio.aac').output(
    'final.mp4', vcodec='copy', acodec='copy'
).run()
```

### 4. Memory Management with Large Videos

```python
# BAD: Loading all frames into memory
frames = []
cap = cv2.VideoCapture('large_video.mp4')
while True:
    ret, frame = cap.read()
    if not ret:
        break
    frames.append(frame)  # OOM for large videos!

# GOOD: Generator pattern
def read_frames(video_path: str):
    """Generator that yields frames one at a time."""
    cap = cv2.VideoCapture(video_path)
    try:
        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break
            yield frame
    finally:
        cap.release()

# Process frames without storing all in memory
for frame in read_frames('large_video.mp4'):
    process(frame)

# GOOD: Batch processing with fixed memory
def read_frame_batches(video_path: str, batch_size: int = 32):
    """Yield batches of frames."""
    batch = []
    for frame in read_frames(video_path):
        batch.append(frame)
        if len(batch) >= batch_size:
            yield np.stack(batch)
            batch = []
    if batch:
        yield np.stack(batch)
```

## FFmpeg + OpenCV Integration

### Pattern 1: FFmpeg Decode → OpenCV Process → FFmpeg Encode

```python
import subprocess
import cv2
import numpy as np

def process_with_ffmpeg_opencv(
    input_path: str,
    output_path: str,
    width: int,
    height: int,
    fps: int = 30
):
    """
    Use FFmpeg for I/O, OpenCV for processing.
    Best of both worlds: FFmpeg codec support + OpenCV algorithms.
    """
    # FFmpeg reader process
    reader = subprocess.Popen(
        [
            'ffmpeg',
            '-i', input_path,
            '-f', 'rawvideo',
            '-pix_fmt', 'bgr24',  # OpenCV format
            '-s', f'{width}x{height}',
            'pipe:1'
        ],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL
    )

    # FFmpeg writer process
    writer = subprocess.Popen(
        [
            'ffmpeg',
            '-y',
            '-f', 'rawvideo',
            '-vcodec', 'rawvideo',
            '-s', f'{width}x{height}',
            '-pix_fmt', 'bgr24',
            '-r', str(fps),
            '-i', 'pipe:0',
            '-c:v', 'libx264',
            '-preset', 'fast',
            '-crf', '23',
            '-pix_fmt', 'yuv420p',
            output_path
        ],
        stdin=subprocess.PIPE,
        stderr=subprocess.DEVNULL
    )

    frame_size = width * height * 3

    try:
        while True:
            raw_frame = reader.stdout.read(frame_size)
            if len(raw_frame) != frame_size:
                break

            # Convert to numpy array
            frame = np.frombuffer(raw_frame, dtype=np.uint8)
            frame = frame.reshape((height, width, 3))

            # OpenCV processing
            processed = cv2.GaussianBlur(frame, (5, 5), 0)
            # Add more processing here...

            # Write processed frame
            writer.stdin.write(processed.tobytes())
    finally:
        reader.stdout.close()
        writer.stdin.close()
        reader.wait()
        writer.wait()
```

### Pattern 2: Using ffmpegcv (OpenCV-Compatible API)

```python
import ffmpegcv

# Drop-in replacement for cv2.VideoCapture
# Supports more codecs, GPU acceleration, network streams

# Basic usage (same as OpenCV)
cap = ffmpegcv.VideoCapture('video.mp4')
while True:
    ret, frame = cap.read()
    if not ret:
        break
    # frame is BGR numpy array, just like OpenCV
    cv2.imshow('Frame', frame)
cap.release()

# GPU-accelerated decoding (NVIDIA only)
cap = ffmpegcv.VideoCaptureNV('video.mp4')  # Uses NVDEC

# GPU decoding with specific GPU
cap = ffmpegcv.VideoCaptureNV('video.mp4', gpu=0)

# Network streams
cap = ffmpegcv.VideoCapture('rtsp://192.168.1.100:554/stream')

# With resize during decode (more efficient than post-resize)
cap = ffmpegcv.VideoCapture('video.mp4', resize=(1280, 720))

# ROI cropping during decode
cap = ffmpegcv.VideoCapture('video.mp4', crop_xywh=(100, 100, 640, 480))

# Writing with GPU encoding
out = ffmpegcv.VideoWriterNV('output.mp4', 'h264_nvenc', fps=30)
out.write(frame)
out.release()

# Direct to CUDA memory (for deep learning)
cap = ffmpegcv.VideoCaptureNV('video.mp4', pix_fmt='cuda')
cuda_frame = cap.read()  # Returns GPU memory pointer
```

### Pattern 3: Using VidGear for Streaming

```python
from vidgear.gears import CamGear, WriteGear

# High-performance capture with multi-threading
stream = CamGear(
    source='rtsp://192.168.1.100:554/stream',
    stream_mode=True,  # Enable network stream mode
    logging=True
).start()

# Capture from YouTube live stream
stream = CamGear(
    source='https://youtu.be/live_stream_id',
    stream_mode=True,
    STREAM_RESOLUTION="1080p"
).start()

while True:
    frame = stream.read()
    if frame is None:
        break

    # OpenCV processing
    processed = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

    cv2.imshow('Stream', processed)
    if cv2.waitKey(1) == ord('q'):
        break

stream.stop()

# Writing with FFmpeg backend
output_params = {
    '-vcodec': 'libx264',
    '-crf': 23,
    '-preset': 'fast'
}
writer = WriteGear(output='output.mp4', **output_params)

for frame in frames:
    writer.write(frame)

writer.close()

# RTMP streaming output
output_params = {
    '-vcodec': 'libx264',
    '-preset': 'ultrafast',
    '-tune': 'zerolatency',
    '-f': 'flv'
}
writer = WriteGear(output='rtmp://server/live/stream', **output_params)
```

### Pattern 4: Using Decord for Deep Learning

```python
import decord
from decord import VideoReader, gpu

# CPU decoding
decord.bridge.set_bridge('torch')  # or 'mxnet', 'tensorflow'
vr = VideoReader('video.mp4', ctx=decord.cpu())

# GPU decoding (requires build from source with CUDA)
vr = VideoReader('video.mp4', ctx=decord.gpu(0))

# Get video info
print(f"Frames: {len(vr)}, FPS: {vr.get_avg_fps()}")

# Random access (efficient!)
frame_10 = vr[10]  # Get frame 10
frames = vr[10:20]  # Get frames 10-19

# Batch loading for training (most efficient)
frame_indices = [0, 10, 20, 30, 40]  # Non-sequential access
batch = vr.get_batch(frame_indices)  # Returns stacked tensor

# VideoLoader for training with shuffling
from decord import VideoLoader

# Multiple videos, shuffled for training
vl = VideoLoader(
    ['video1.mp4', 'video2.mp4', 'video3.mp4'],
    ctx=decord.cpu(),
    shape=(8, 224, 224, 3),  # (batch, height, width, channels)
    interval=1,  # Sample every frame
    skip=0,
    shuffle=1  # 1=shuffle filenames, 2=random order, 3=random frames
)

for batch in vl:
    # batch shape: (batch_size, num_frames, H, W, C)
    train_on_batch(batch)
```

## Modal.com Video Processing

### Basic Setup: FFmpeg + OpenCV on Modal

```python
import modal

# Define image with FFmpeg and OpenCV
image = (
    modal.Image.debian_slim(python_version="3.12")
    .apt_install("ffmpeg", "libsm6", "libxext6", "libgl1")  # System deps
    .pip_install(
        "opencv-python-headless",  # Headless for servers
        "ffmpeg-python",
        "numpy"
    )
)

app = modal.App("video-processing", image=image)
vol = modal.Volume.from_name("video-storage", create_if_missing=True)

@app.function(volumes={"/data": vol})
def process_video(input_path: str, output_path: str):
    """Process a single video file."""
    import cv2
    import ffmpeg

    cap = cv2.VideoCapture(f"/data/{input_path}")
    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    fps = cap.get(cv2.CAP_PROP_FPS)

    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    out = cv2.VideoWriter(f"/data/{output_path}", fourcc, fps, (width, height))

    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break

        # Process frame
        processed = cv2.GaussianBlur(frame, (5, 5), 0)
        out.write(processed)

    cap.release()
    out.release()

    # Commit changes to volume
    vol.commit()
    return output_path

@app.local_entrypoint()
def main():
    process_video.remote("input.mp4", "output.mp4")
```

### GPU-Accelerated Processing on Modal

```python
import modal

# Image with CUDA + OpenCV + FFmpeg
gpu_image = (
    modal.Image.from_registry("nvidia/cuda:12.1.0-runtime-ubuntu22.04")
    .apt_install("ffmpeg", "python3-pip", "libsm6", "libxext6", "libgl1")
    .run_commands("pip install opencv-python-headless numpy torch ffmpeg-python")
)

app = modal.App("gpu-video-processing", image=gpu_image)

@app.function(gpu="A100", timeout=3600)
def process_video_gpu(video_bytes: bytes) -> bytes:
    """Process video using GPU acceleration."""
    import torch
    import cv2
    import numpy as np
    import tempfile

    # Write input to temp file
    with tempfile.NamedTemporaryFile(suffix='.mp4', delete=False) as f:
        f.write(video_bytes)
        input_path = f.name

    # Read video
    cap = cv2.VideoCapture(input_path)
    frames = []

    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break
        frames.append(frame)
    cap.release()

    # Process on GPU
    device = torch.device('cuda')
    frames_tensor = torch.from_numpy(np.stack(frames)).to(device)

    # GPU processing (example: normalize)
    frames_tensor = frames_tensor.float() / 255.0
    # Add your GPU processing here...
    frames_tensor = (frames_tensor * 255).byte()

    processed_frames = frames_tensor.cpu().numpy()

    # Write output
    output_path = input_path.replace('.mp4', '_processed.mp4')
    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    fps = cap.get(cv2.CAP_PROP_FPS) or 30
    h, w = processed_frames[0].shape[:2]
    out = cv2.VideoWriter(output_path, fourcc, fps, (w, h))

    for frame in processed_frames:
        out.write(frame)
    out.release()

    with open(output_path, 'rb') as f:
        return f.read()
```

### Parallel Frame Processing with Modal

```python
import modal

image = (
    modal.Image.debian_slim()
    .apt_install("ffmpeg")
    .pip_install("opencv-python-headless", "numpy", "ffmpeg-python")
)

app = modal.App("parallel-video", image=image)
vol = modal.Volume.from_name("video-frames", create_if_missing=True)

@app.function()
def process_frame(frame_data: bytes, frame_idx: int) -> tuple[int, bytes]:
    """Process a single frame."""
    import cv2
    import numpy as np

    # Decode frame
    nparr = np.frombuffer(frame_data, np.uint8)
    frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

    # Process (example: edge detection)
    edges = cv2.Canny(frame, 100, 200)
    edges_bgr = cv2.cvtColor(edges, cv2.COLOR_GRAY2BGR)

    # Encode result
    _, encoded = cv2.imencode('.png', edges_bgr)
    return frame_idx, encoded.tobytes()

@app.function(volumes={"/data": vol}, timeout=3600)
def process_video_parallel(input_path: str) -> str:
    """Process video frames in parallel using Modal map."""
    import cv2
    import ffmpeg
    import numpy as np

    # Extract frames
    cap = cv2.VideoCapture(f"/data/{input_path}")
    fps = cap.get(cv2.CAP_PROP_FPS)
    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))

    frame_data_list = []
    frame_idx = 0

    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break
        _, encoded = cv2.imencode('.png', frame)
        frame_data_list.append((encoded.tobytes(), frame_idx))
        frame_idx += 1
    cap.release()

    # Process frames in parallel
    results = list(process_frame.starmap(frame_data_list))

    # Sort by frame index
    results.sort(key=lambda x: x[0])

    # Reconstruct video
    output_path = input_path.replace('.mp4', '_processed.mp4')
    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    out = cv2.VideoWriter(f"/data/{output_path}", fourcc, fps, (width, height))

    for _, frame_bytes in results:
        nparr = np.frombuffer(frame_bytes, np.uint8)
        frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        out.write(frame)

    out.release()
    vol.commit()

    return output_path
```

### Chunk-Based Video Processing for Large Files

```python
import modal

image = (
    modal.Image.debian_slim()
    .apt_install("ffmpeg")
    .pip_install("opencv-python-headless", "numpy", "ffmpeg-python")
)

app = modal.App("chunked-video", image=image)
vol = modal.Volume.from_name("video-chunks", create_if_missing=True)

@app.function(gpu="T4", timeout=600)
def process_chunk(
    input_path: str,
    output_path: str,
    start_frame: int,
    end_frame: int
) -> str:
    """Process a chunk of video frames."""
    import cv2
    import subprocess

    # Use FFmpeg to extract specific frame range
    chunk_input = f"/tmp/chunk_{start_frame}.mp4"
    subprocess.run([
        'ffmpeg', '-y',
        '-i', input_path,
        '-vf', f'select=between(n\\,{start_frame}\\,{end_frame}),setpts=PTS-STARTPTS',
        '-an',  # No audio for chunks
        chunk_input
    ], check=True, capture_output=True)

    # Process chunk
    cap = cv2.VideoCapture(chunk_input)
    fps = cap.get(cv2.CAP_PROP_FPS)
    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))

    chunk_output = f"/tmp/processed_{start_frame}.mp4"
    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    out = cv2.VideoWriter(chunk_output, fourcc, fps, (width, height))

    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break
        # GPU processing here
        processed = cv2.GaussianBlur(frame, (5, 5), 0)
        out.write(processed)

    cap.release()
    out.release()

    return chunk_output

@app.function(volumes={"/data": vol}, timeout=7200)
def process_large_video(input_path: str, chunk_size: int = 1000) -> str:
    """Process large video by splitting into chunks."""
    import cv2
    import subprocess

    full_path = f"/data/{input_path}"

    # Get video info
    cap = cv2.VideoCapture(full_path)
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    fps = cap.get(cv2.CAP_PROP_FPS)
    cap.release()

    # Create chunks
    chunks = []
    for start in range(0, total_frames, chunk_size):
        end = min(start + chunk_size - 1, total_frames - 1)
        chunks.append((full_path, f"/tmp/chunk_{start}.mp4", start, end))

    # Process chunks in parallel
    chunk_outputs = list(process_chunk.starmap(chunks))

    # Concatenate chunks with FFmpeg
    list_file = "/tmp/chunks.txt"
    with open(list_file, 'w') as f:
        for path in chunk_outputs:
            f.write(f"file '{path}'\n")

    output_path = input_path.replace('.mp4', '_processed.mp4')
    subprocess.run([
        'ffmpeg', '-y',
        '-f', 'concat',
        '-safe', '0',
        '-i', list_file,
        '-c', 'copy',
        f"/data/{output_path}"
    ], check=True)

    vol.commit()
    return output_path
```

### Video Transcoding Pipeline on Modal

```python
import modal

image = (
    modal.Image.debian_slim()
    .apt_install("ffmpeg")
    .pip_install("ffmpeg-python")
)

app = modal.App("transcoding-pipeline", image=image)
vol = modal.Volume.from_name("transcoded-videos", create_if_missing=True)

# Quality presets
QUALITY_PRESETS = {
    '4k': {'width': 3840, 'height': 2160, 'bitrate': '15M', 'crf': 18},
    '1080p': {'width': 1920, 'height': 1080, 'bitrate': '5M', 'crf': 23},
    '720p': {'width': 1280, 'height': 720, 'bitrate': '2.5M', 'crf': 26},
    '480p': {'width': 854, 'height': 480, 'bitrate': '1M', 'crf': 28},
}

@app.function(gpu="T4", timeout=3600)  # Use GPU for NVENC
def transcode_video(
    input_path: str,
    output_path: str,
    quality: str,
    use_hardware: bool = True
) -> dict:
    """Transcode video to specific quality."""
    import ffmpeg
    import time

    preset = QUALITY_PRESETS[quality]

    start_time = time.time()

    input_stream = ffmpeg.input(input_path)
    video = input_stream.video.filter('scale', preset['width'], preset['height'])
    audio = input_stream.audio

    if use_hardware:
        # NVIDIA NVENC encoding
        output = ffmpeg.output(
            video, audio, output_path,
            vcodec='h264_nvenc',
            preset='p4',  # Quality preset
            cq=preset['crf'],  # Constant quality
            acodec='aac',
            audio_bitrate='192k'
        )
    else:
        # CPU encoding
        output = ffmpeg.output(
            video, audio, output_path,
            vcodec='libx264',
            preset='medium',
            crf=preset['crf'],
            acodec='aac',
            audio_bitrate='192k'
        )

    output.overwrite_output().run(quiet=True)

    elapsed = time.time() - start_time

    return {
        'quality': quality,
        'output_path': output_path,
        'encoding_time': elapsed
    }

@app.function(volumes={"/data": vol})
def create_quality_ladder(input_path: str) -> list[dict]:
    """Create multiple quality versions (adaptive streaming ready)."""
    import os

    full_path = f"/data/{input_path}"
    base_name = os.path.splitext(input_path)[0]

    # Transcode to all qualities in parallel
    tasks = [
        (full_path, f"/data/{base_name}_{q}.mp4", q, True)
        for q in ['1080p', '720p', '480p']
    ]

    results = list(transcode_video.starmap(tasks))

    vol.commit()
    return results
```

### HLS Streaming Generation on Modal

```python
import modal

image = (
    modal.Image.debian_slim()
    .apt_install("ffmpeg")
    .pip_install("ffmpeg-python")
)

app = modal.App("hls-generator", image=image)
vol = modal.Volume.from_name("hls-streams", create_if_missing=True)

@app.function(gpu="T4", volumes={"/data": vol}, timeout=3600)
def generate_hls(input_path: str, output_dir: str) -> dict:
    """Generate HLS stream with multiple quality levels."""
    import ffmpeg
    import os

    os.makedirs(f"/data/{output_dir}", exist_ok=True)

    input_stream = ffmpeg.input(f"/data/{input_path}")

    # Create multiple quality streams
    qualities = [
        ('1080p', 1920, 1080, '5000k'),
        ('720p', 1280, 720, '2500k'),
        ('480p', 854, 480, '1000k'),
    ]

    for name, w, h, bitrate in qualities:
        stream_dir = f"/data/{output_dir}/{name}"
        os.makedirs(stream_dir, exist_ok=True)

        video = input_stream.video.filter('scale', w, h)
        audio = input_stream.audio

        output = ffmpeg.output(
            video, audio,
            f"{stream_dir}/stream.m3u8",
            vcodec='h264_nvenc',
            video_bitrate=bitrate,
            acodec='aac',
            audio_bitrate='128k',
            f='hls',
            hls_time=10,
            hls_list_size=0,
            hls_segment_filename=f"{stream_dir}/segment_%03d.ts"
        )
        output.overwrite_output().run(quiet=True)

    # Create master playlist
    master_playlist = f"/data/{output_dir}/master.m3u8"
    with open(master_playlist, 'w') as f:
        f.write("#EXTM3U\n")
        f.write("#EXT-X-VERSION:3\n")
        for name, w, h, bitrate in qualities:
            bandwidth = int(bitrate.replace('k', '')) * 1000
            f.write(f"#EXT-X-STREAM-INF:BANDWIDTH={bandwidth},RESOLUTION={w}x{h}\n")
            f.write(f"{name}/stream.m3u8\n")

    vol.commit()

    return {
        'master_playlist': f"{output_dir}/master.m3u8",
        'qualities': [q[0] for q in qualities]
    }
```

## Complete Pipeline Example

### End-to-End: Upload → Process → Transcode → HLS

```python
import modal

image = (
    modal.Image.debian_slim()
    .apt_install("ffmpeg", "libsm6", "libxext6", "libgl1")
    .pip_install(
        "opencv-python-headless",
        "ffmpeg-python",
        "numpy",
        "boto3"  # For S3 integration
    )
)

app = modal.App("video-pipeline", image=image)
vol = modal.Volume.from_name("pipeline-storage", create_if_missing=True)

# S3 credentials
s3_secret = modal.Secret.from_name("aws-credentials")

@app.function()
def analyze_video(video_bytes: bytes) -> dict:
    """Analyze video metadata."""
    import ffmpeg
    import tempfile

    with tempfile.NamedTemporaryFile(suffix='.mp4', delete=False) as f:
        f.write(video_bytes)
        temp_path = f.name

    probe = ffmpeg.probe(temp_path)
    video_info = next(s for s in probe['streams'] if s['codec_type'] == 'video')

    return {
        'duration': float(probe['format']['duration']),
        'width': video_info['width'],
        'height': video_info['height'],
        'fps': eval(video_info['r_frame_rate']),
        'codec': video_info['codec_name'],
        'size_mb': int(probe['format']['size']) / (1024 * 1024)
    }

@app.function(gpu="A100")
def apply_cv_effects(frame_batch: list[bytes]) -> list[bytes]:
    """Apply computer vision effects to a batch of frames."""
    import cv2
    import numpy as np

    processed = []
    for frame_bytes in frame_batch:
        nparr = np.frombuffer(frame_bytes, np.uint8)
        frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

        # Apply effects
        frame = cv2.GaussianBlur(frame, (5, 5), 0)
        frame = cv2.Canny(frame, 100, 200)
        frame = cv2.cvtColor(frame, cv2.COLOR_GRAY2BGR)

        _, encoded = cv2.imencode('.png', frame)
        processed.append(encoded.tobytes())

    return processed

@app.function(
    volumes={"/data": vol},
    secrets=[s3_secret],
    timeout=7200
)
def run_pipeline(
    s3_input_key: str,
    s3_output_prefix: str,
    apply_effects: bool = True
) -> dict:
    """Complete video processing pipeline."""
    import boto3
    import cv2
    import ffmpeg
    import numpy as np
    import os

    # Download from S3
    s3 = boto3.client('s3')
    bucket = os.environ['S3_BUCKET']
    local_input = "/data/input.mp4"

    s3.download_file(bucket, s3_input_key, local_input)

    # Analyze
    with open(local_input, 'rb') as f:
        metadata = analyze_video.remote(f.read())

    # Extract and process frames if needed
    if apply_effects:
        cap = cv2.VideoCapture(local_input)
        fps = metadata['fps']
        width = metadata['width']
        height = metadata['height']

        # Batch frames for parallel processing
        batch_size = 100
        batches = []
        current_batch = []

        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break
            _, encoded = cv2.imencode('.png', frame)
            current_batch.append(encoded.tobytes())

            if len(current_batch) >= batch_size:
                batches.append(current_batch)
                current_batch = []

        if current_batch:
            batches.append(current_batch)

        cap.release()

        # Process batches in parallel
        processed_batches = list(apply_cv_effects.map(batches))

        # Reconstruct video
        local_processed = "/data/processed.mp4"
        fourcc = cv2.VideoWriter_fourcc(*'mp4v')
        out = cv2.VideoWriter(local_processed, fourcc, fps, (width, height))

        for batch in processed_batches:
            for frame_bytes in batch:
                nparr = np.frombuffer(frame_bytes, np.uint8)
                frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
                out.write(frame)

        out.release()

        # Add back audio
        ffmpeg.input(local_processed).input(local_input).output(
            "/data/with_audio.mp4",
            vcodec='copy',
            acodec='copy',
            map=['0:v:0', '1:a:0']
        ).overwrite_output().run()

        local_input = "/data/with_audio.mp4"

    # Generate HLS
    hls_result = generate_hls.remote(
        os.path.basename(local_input),
        "hls_output"
    )

    # Upload results to S3
    for root, dirs, files in os.walk("/data/hls_output"):
        for file in files:
            local_path = os.path.join(root, file)
            s3_key = f"{s3_output_prefix}/{os.path.relpath(local_path, '/data/hls_output')}"
            s3.upload_file(local_path, bucket, s3_key)

    vol.commit()

    return {
        'metadata': metadata,
        'hls': hls_result,
        's3_output': f"s3://{bucket}/{s3_output_prefix}/"
    }
```

## Performance Optimization Tips

### 1. Use Hardware Acceleration When Available

```python
# Check for NVENC support
import subprocess
result = subprocess.run(['ffmpeg', '-encoders'], capture_output=True, text=True)
has_nvenc = 'h264_nvenc' in result.stdout

# Use appropriate encoder
vcodec = 'h264_nvenc' if has_nvenc else 'libx264'
```

### 2. Optimize Batch Sizes for GPU Memory

```python
import torch

def get_optimal_batch_size(frame_shape: tuple, gpu_memory_gb: float = 40) -> int:
    """Calculate optimal batch size for GPU memory."""
    h, w, c = frame_shape
    bytes_per_frame = h * w * c * 4  # float32
    available_bytes = gpu_memory_gb * 1e9 * 0.8  # 80% utilization
    return int(available_bytes / bytes_per_frame)
```

### 3. Use Efficient Pixel Formats

```python
# For deep learning: Use fp32 CHW directly on GPU
import ffmpegcv

# Skip CPU conversion, go straight to GPU
cap = ffmpegcv.VideoCaptureNV(
    'video.mp4',
    pix_fmt='cuda',
    resize=(224, 224)
)
cuda_frame = cap.read()  # Already on GPU, CHW format
```

### 4. Stream Processing for Large Videos

```python
# Never load entire video into memory
def process_streaming(input_path: str, output_path: str):
    """Process video frame-by-frame without memory accumulation."""
    import cv2

    cap = cv2.VideoCapture(input_path)
    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    out = None

    try:
        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break

            if out is None:
                h, w = frame.shape[:2]
                fps = cap.get(cv2.CAP_PROP_FPS)
                out = cv2.VideoWriter(output_path, fourcc, fps, (w, h))

            processed = process_single_frame(frame)
            out.write(processed)
    finally:
        cap.release()
        if out:
            out.release()
```

## Additional Resources

- [ffmpegcv GitHub](https://github.com/chenxinfeng4/ffmpegcv)
- [VidGear Documentation](https://abhitronix.github.io/vidgear/)
- [Decord GitHub](https://github.com/dmlc/decord)
- [Modal.com Docs - GPU](https://modal.com/docs/guide/gpu)
- [Modal.com Docs - Volumes](https://modal.com/docs/guide/volumes)
- [OpenCV CUDA Module](https://docs.opencv.org/4.x/d2/dbc/cuda_intro.html)
- [FFmpeg Hardware Acceleration](https://trac.ffmpeg.org/wiki/HWAccelIntro)
