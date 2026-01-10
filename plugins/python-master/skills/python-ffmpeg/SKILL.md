# Python FFmpeg Skill

Comprehensive guide to using FFmpeg with Python for video/audio processing, encoding, streaming, and media manipulation.

## Quick Reference

| Library | Best For | Performance | Complexity |
|---------|----------|-------------|------------|
| `ffmpeg-python` | Complex filter graphs, readable code | Medium | Low |
| `PyAV` | Frame-level access, real-time processing | High | Medium |
| `subprocess` | Simple tasks, full FFmpeg control | Medium | Low |
| `moviepy` | Quick edits, simple compositing | Low | Very Low |

## Installation

```bash
# System FFmpeg (REQUIRED for ffmpeg-python and subprocess)
# Windows: winget install ffmpeg
# macOS: brew install ffmpeg
# Ubuntu: sudo apt install ffmpeg

# Python libraries
uv add ffmpeg-python  # Wrapper library
uv add av             # PyAV - Cython bindings
uv add moviepy        # High-level editing
```

## Critical Gotchas

### 1. Audio Stream Loss (MOST COMMON BUG)

```python
import ffmpeg

# BAD: Video filters can drop audio!
(
    ffmpeg
    .input('input.mp4')
    .filter('scale', 1280, 720)
    .output('output.mp4')
    .run()
)
# Result: Video only, NO AUDIO!

# GOOD: Explicitly handle audio stream
input_file = ffmpeg.input('input.mp4')
video = input_file.video.filter('scale', 1280, 720)
audio = input_file.audio
(
    ffmpeg
    .output(video, audio, 'output.mp4')
    .run()
)

# ALTERNATIVE: Copy audio stream
(
    ffmpeg
    .input('input.mp4')
    .output('output.mp4', vf='scale=1280:720', acodec='copy')
    .run()
)
```

### 2. Subprocess Deadlock

```python
import subprocess

# BAD: Can deadlock with large outputs!
process = subprocess.Popen(
    ['ffmpeg', '-i', 'input.mp4', '-f', 'rawvideo', 'pipe:1'],
    stdout=subprocess.PIPE
)
output = process.stdout.read()  # DEADLOCK if output > buffer size

# GOOD: Use communicate() for small outputs
process = subprocess.Popen(
    ['ffmpeg', '-i', 'input.mp4', '-f', 'null', '-'],
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE
)
stdout, stderr = process.communicate()

# GOOD: Stream processing for large outputs
process = subprocess.Popen(
    ['ffmpeg', '-i', 'input.mp4', '-f', 'rawvideo', '-pix_fmt', 'rgb24', 'pipe:1'],
    stdout=subprocess.PIPE,
    stderr=subprocess.DEVNULL
)
while True:
    # Read frame by frame (width * height * 3 bytes for RGB24)
    frame_data = process.stdout.read(1920 * 1080 * 3)
    if not frame_data:
        break
    # Process frame...
```

### 3. Overwrite Without Prompt

```python
# BAD: FFmpeg prompts for overwrite, blocking script
ffmpeg.input('input.mp4').output('output.mp4').run()

# GOOD: Always use overwrite_output()
ffmpeg.input('input.mp4').output('output.mp4').overwrite_output().run()

# Or with subprocess
subprocess.run(['ffmpeg', '-y', '-i', 'input.mp4', 'output.mp4'])
```

### 4. Error Handling

```python
import ffmpeg

# BAD: No error handling
ffmpeg.input('input.mp4').output('output.mp4').run()

# GOOD: Catch and log errors
try:
    ffmpeg.input('input.mp4').output('output.mp4').overwrite_output().run(
        capture_stdout=True,
        capture_stderr=True
    )
except ffmpeg.Error as e:
    print(f"FFmpeg error: {e.stderr.decode()}")
    raise

# Check if file exists first
from pathlib import Path
if not Path('input.mp4').exists():
    raise FileNotFoundError("Input file not found")
```

### 5. Path Handling on Windows

```python
from pathlib import Path

# BAD: Backslashes can cause issues
path = "C:\\Users\\video.mp4"

# GOOD: Use forward slashes or Path
path = "C:/Users/video.mp4"
# Or
path = str(Path("C:\\Users\\video.mp4").as_posix())

# GOOD: Quote paths with spaces
ffmpeg.input('my video.mp4')  # ffmpeg-python handles quoting
subprocess.run(['ffmpeg', '-i', 'my video.mp4', 'output.mp4'])  # List handles quoting
```

## Video Encoding

### H.264 (Best Compatibility)

```python
import ffmpeg

# CRF encoding (recommended for quality)
# CRF 0 = lossless, 23 = default, 51 = worst
# Lower = better quality, larger file
(
    ffmpeg
    .input('input.mp4')
    .output('output.mp4',
        vcodec='libx264',
        crf=23,           # Quality (18-28 typical range)
        preset='medium',  # Speed vs compression
        acodec='aac',
        audio_bitrate='192k'
    )
    .overwrite_output()
    .run()
)

# Presets (fastest to slowest, worst to best compression):
# ultrafast, superfast, veryfast, faster, fast, medium, slow, slower, veryslow, placebo
# Use 'medium' or 'slow' for best quality/time tradeoff

# Two-pass encoding for target file size
import os

# Calculate bitrate for target size (in kbps)
duration_seconds = 120
target_size_mb = 50
video_bitrate = (target_size_mb * 8192 / duration_seconds) - 192  # Subtract audio bitrate

# Pass 1
(
    ffmpeg
    .input('input.mp4')
    .output('NUL' if os.name == 'nt' else '/dev/null',
        vcodec='libx264',
        video_bitrate=f'{int(video_bitrate)}k',
        preset='slow',
        **{'pass': 1},
        f='null'
    )
    .overwrite_output()
    .run()
)

# Pass 2
(
    ffmpeg
    .input('input.mp4')
    .output('output.mp4',
        vcodec='libx264',
        video_bitrate=f'{int(video_bitrate)}k',
        preset='slow',
        **{'pass': 2},
        acodec='aac',
        audio_bitrate='192k'
    )
    .overwrite_output()
    .run()
)
```

### H.265/HEVC (Better Compression)

```python
# CRF 28 for H.265 ≈ CRF 23 for H.264
(
    ffmpeg
    .input('input.mp4')
    .output('output.mp4',
        vcodec='libx265',
        crf=28,
        preset='medium',
        acodec='aac',
        audio_bitrate='128k',
        **{'tag:v': 'hvc1'}  # For Apple compatibility
    )
    .overwrite_output()
    .run()
)
```

### VP9/WebM (Web Streaming)

```python
(
    ffmpeg
    .input('input.mp4')
    .output('output.webm',
        vcodec='libvpx-vp9',
        crf=30,
        video_bitrate='0',  # Required for CRF mode
        acodec='libopus',
        audio_bitrate='128k'
    )
    .overwrite_output()
    .run()
)
```

### AV1 (Best Compression, Slowest)

```python
(
    ffmpeg
    .input('input.mp4')
    .output('output.mp4',
        vcodec='libaom-av1',
        crf=30,
        cpu_used=4,  # 0-8, higher = faster but lower quality
        acodec='libopus'
    )
    .overwrite_output()
    .run()
)
```

## Hardware Acceleration

### NVIDIA NVENC

```python
# Check if NVENC is available
import subprocess
result = subprocess.run(
    ['ffmpeg', '-encoders'],
    capture_output=True,
    text=True
)
nvenc_available = 'h264_nvenc' in result.stdout

if nvenc_available:
    (
        ffmpeg
        .input('input.mp4')
        .output('output.mp4',
            vcodec='h264_nvenc',
            preset='p4',  # p1 (fastest) to p7 (best quality)
            cq=23,        # Constant quality (like CRF)
            acodec='copy'
        )
        .overwrite_output()
        .run()
    )
```

### Intel Quick Sync (QSV)

```python
(
    ffmpeg
    .input('input.mp4', hwaccel='qsv')
    .output('output.mp4',
        vcodec='h264_qsv',
        preset='medium',
        global_quality=23,
        acodec='copy'
    )
    .overwrite_output()
    .run()
)
```

### AMD AMF (Windows) / VAAPI (Linux)

```python
# Linux VAAPI
(
    ffmpeg
    .input('input.mp4', hwaccel='vaapi', hwaccel_device='/dev/dri/renderD128')
    .output('output.mp4',
        vcodec='h264_vaapi',
        acodec='copy'
    )
    .overwrite_output()
    .run()
)
```

## Audio Processing

### Extract Audio

```python
# Extract to MP3
(
    ffmpeg
    .input('video.mp4')
    .output('audio.mp3',
        acodec='libmp3lame',
        audio_bitrate='320k',
        vn=None  # No video
    )
    .overwrite_output()
    .run()
)

# Extract to WAV (lossless)
(
    ffmpeg
    .input('video.mp4')
    .output('audio.wav',
        acodec='pcm_s16le',
        ar=44100,  # Sample rate
        ac=2,      # Channels (stereo)
        vn=None
    )
    .overwrite_output()
    .run()
)

# Extract to FLAC (lossless compressed)
(
    ffmpeg
    .input('video.mp4')
    .output('audio.flac',
        acodec='flac',
        vn=None
    )
    .overwrite_output()
    .run()
)
```

### Audio Conversion

```python
# MP3 with variable bitrate (recommended)
(
    ffmpeg
    .input('audio.wav')
    .output('audio.mp3',
        acodec='libmp3lame',
        q=2  # VBR quality 0-9 (0 = best, ~245kbps; 2 ≈ 190kbps)
    )
    .overwrite_output()
    .run()
)

# AAC (best for video)
(
    ffmpeg
    .input('audio.wav')
    .output('audio.m4a',
        acodec='aac',
        audio_bitrate='256k'
    )
    .overwrite_output()
    .run()
)

# Opus (best quality per bitrate)
(
    ffmpeg
    .input('audio.wav')
    .output('audio.opus',
        acodec='libopus',
        audio_bitrate='128k'
    )
    .overwrite_output()
    .run()
)
```

### Audio Filters

```python
# Volume adjustment
(
    ffmpeg
    .input('audio.mp3')
    .filter('volume', 1.5)  # 1.5x volume
    .output('louder.mp3')
    .overwrite_output()
    .run()
)

# Normalize audio (loudnorm)
(
    ffmpeg
    .input('audio.mp3')
    .filter('loudnorm', I=-16, TP=-1.5, LRA=11)
    .output('normalized.mp3')
    .overwrite_output()
    .run()
)

# Fade in/out
(
    ffmpeg
    .input('audio.mp3')
    .filter('afade', type='in', duration=3)
    .filter('afade', type='out', start_time=57, duration=3)
    .output('faded.mp3')
    .overwrite_output()
    .run()
)

# Resample
(
    ffmpeg
    .input('audio.mp3')
    .filter('aresample', 48000)
    .output('resampled.mp3')
    .overwrite_output()
    .run()
)
```

## Video Filters

### Scaling/Resizing

```python
# Scale to specific size
(
    ffmpeg
    .input('input.mp4')
    .filter('scale', 1920, 1080)
    .output('output.mp4', acodec='copy')
    .overwrite_output()
    .run()
)

# Scale maintaining aspect ratio
(
    ffmpeg
    .input('input.mp4')
    .filter('scale', 1280, -1)  # -1 = auto-calculate
    .output('output.mp4', acodec='copy')
    .overwrite_output()
    .run()
)

# Scale with padding (letterbox/pillarbox)
(
    ffmpeg
    .input('input.mp4')
    .filter('scale', 1920, 1080, force_original_aspect_ratio='decrease')
    .filter('pad', 1920, 1080, '(ow-iw)/2', '(oh-ih)/2')
    .output('output.mp4', acodec='copy')
    .overwrite_output()
    .run()
)

# Scale algorithms
# fast_bilinear, bilinear, bicubic, lanczos (best for downscaling)
(
    ffmpeg
    .input('input.mp4')
    .filter('scale', 1280, 720, flags='lanczos')
    .output('output.mp4', acodec='copy')
    .overwrite_output()
    .run()
)
```

### Cropping

```python
# Crop to size (width:height:x:y)
(
    ffmpeg
    .input('input.mp4')
    .filter('crop', 1280, 720, 100, 50)  # 1280x720 starting at (100, 50)
    .output('output.mp4', acodec='copy')
    .overwrite_output()
    .run()
)

# Center crop
(
    ffmpeg
    .input('input.mp4')
    .filter('crop', 1280, 720, '(in_w-1280)/2', '(in_h-720)/2')
    .output('output.mp4', acodec='copy')
    .overwrite_output()
    .run()
)

# Crop to aspect ratio (16:9)
(
    ffmpeg
    .input('input.mp4')
    .filter('crop', 'min(iw,ih*16/9)', 'min(ih,iw*9/16)')
    .output('output.mp4', acodec='copy')
    .overwrite_output()
    .run()
)
```

### Rotation

```python
# Rotate 90 degrees clockwise
(
    ffmpeg
    .input('input.mp4')
    .filter('transpose', 1)  # 0=ccw+vflip, 1=cw, 2=ccw, 3=cw+vflip
    .output('output.mp4', acodec='copy')
    .overwrite_output()
    .run()
)

# Rotate arbitrary angle
(
    ffmpeg
    .input('input.mp4')
    .filter('rotate', 'PI/6')  # 30 degrees in radians
    .output('output.mp4', acodec='copy')
    .overwrite_output()
    .run()
)

# Horizontal flip
(
    ffmpeg
    .input('input.mp4')
    .filter('hflip')
    .output('output.mp4', acodec='copy')
    .overwrite_output()
    .run()
)

# Vertical flip
(
    ffmpeg
    .input('input.mp4')
    .filter('vflip')
    .output('output.mp4', acodec='copy')
    .overwrite_output()
    .run()
)
```

### Text Overlay

```python
# Simple text
(
    ffmpeg
    .input('input.mp4')
    .filter('drawtext',
        text='Hello World',
        fontsize=48,
        fontcolor='white',
        x='(w-text_w)/2',  # Center horizontally
        y='h-th-20'        # Bottom with padding
    )
    .output('output.mp4', acodec='copy')
    .overwrite_output()
    .run()
)

# Text with background box
(
    ffmpeg
    .input('input.mp4')
    .filter('drawtext',
        text='Watermark',
        fontsize=24,
        fontcolor='white',
        box=1,
        boxcolor='black@0.5',
        boxborderw=5,
        x=10,
        y=10
    )
    .output('output.mp4', acodec='copy')
    .overwrite_output()
    .run()
)

# Timestamp
(
    ffmpeg
    .input('input.mp4')
    .filter('drawtext',
        text='%{pts\\:hms}',  # Escape colons
        fontsize=24,
        fontcolor='white',
        x=10,
        y=10
    )
    .output('output.mp4', acodec='copy')
    .overwrite_output()
    .run()
)

# Custom font (specify path)
(
    ffmpeg
    .input('input.mp4')
    .filter('drawtext',
        text='Custom Font',
        fontfile='/path/to/font.ttf',
        fontsize=48,
        fontcolor='yellow'
    )
    .output('output.mp4', acodec='copy')
    .overwrite_output()
    .run()
)
```

### Image Overlay (Watermark)

```python
# Overlay image in corner
main = ffmpeg.input('video.mp4')
logo = ffmpeg.input('logo.png')

(
    ffmpeg
    .overlay(main, logo, x=10, y=10)  # Top-left
    .output('output.mp4', acodec='copy')
    .overwrite_output()
    .run()
)

# Overlay with scaling
main = ffmpeg.input('video.mp4')
logo = ffmpeg.input('logo.png').filter('scale', 100, -1)

(
    ffmpeg
    .overlay(main, logo, x='main_w-overlay_w-10', y=10)  # Top-right
    .output('output.mp4', acodec='copy')
    .overwrite_output()
    .run()
)

# Semi-transparent overlay
logo = ffmpeg.input('logo.png').filter('format', 'rgba').filter('colorchannelmixer', aa=0.5)
```

### Color Adjustments

```python
# Brightness, contrast, saturation
(
    ffmpeg
    .input('input.mp4')
    .filter('eq',
        brightness=0.1,    # -1 to 1, default 0
        contrast=1.2,      # 0 to 2, default 1
        saturation=1.3     # 0 to 3, default 1
    )
    .output('output.mp4', acodec='copy')
    .overwrite_output()
    .run()
)

# Gamma correction
(
    ffmpeg
    .input('input.mp4')
    .filter('eq', gamma=1.5)
    .output('output.mp4', acodec='copy')
    .overwrite_output()
    .run()
)

# Grayscale
(
    ffmpeg
    .input('input.mp4')
    .filter('format', 'gray')
    .output('output.mp4', acodec='copy')
    .overwrite_output()
    .run()
)

# Color balance
(
    ffmpeg
    .input('input.mp4')
    .filter('colorbalance',
        rs=0.1,  # Red shadows
        gm=0.1,  # Green midtones
        bh=0.1   # Blue highlights
    )
    .output('output.mp4', acodec='copy')
    .overwrite_output()
    .run()
)
```

## Trimming and Concatenation

### Trimming

```python
# Trim by time
(
    ffmpeg
    .input('input.mp4', ss=10, t=30)  # Start at 10s, duration 30s
    .output('output.mp4', c='copy')   # Stream copy (fast, no re-encode)
    .overwrite_output()
    .run()
)

# Trim to end time
(
    ffmpeg
    .input('input.mp4', ss=10, to=40)  # Start at 10s, end at 40s
    .output('output.mp4', c='copy')
    .overwrite_output()
    .run()
)

# Accurate trimming (re-encode, slower but precise)
(
    ffmpeg
    .input('input.mp4')
    .trim(start=10, end=40)
    .setpts('PTS-STARTPTS')  # Reset timestamps
    .output('output.mp4', vcodec='libx264', crf=18)
    .overwrite_output()
    .run()
)

# Trim with audio (both streams)
input_file = ffmpeg.input('input.mp4')
video = input_file.video.trim(start=10, end=40).setpts('PTS-STARTPTS')
audio = input_file.audio.filter('atrim', start=10, end=40).filter('asetpts', 'PTS-STARTPTS')
(
    ffmpeg
    .output(video, audio, 'output.mp4')
    .overwrite_output()
    .run()
)
```

### Concatenation

```python
# Method 1: Concat demuxer (same codec, fast)
# Create file list
with open('filelist.txt', 'w') as f:
    f.write("file 'video1.mp4'\n")
    f.write("file 'video2.mp4'\n")
    f.write("file 'video3.mp4'\n")

(
    ffmpeg
    .input('filelist.txt', f='concat', safe=0)
    .output('output.mp4', c='copy')
    .overwrite_output()
    .run()
)

# Method 2: Concat filter (different codecs, re-encodes)
video1 = ffmpeg.input('video1.mp4')
video2 = ffmpeg.input('video2.mp4')

(
    ffmpeg
    .concat(video1, video2, v=1, a=1)  # v=video streams, a=audio streams
    .output('output.mp4')
    .overwrite_output()
    .run()
)

# Concatenate multiple videos
videos = [ffmpeg.input(f'video{i}.mp4') for i in range(1, 5)]
(
    ffmpeg
    .concat(*videos, v=1, a=1)
    .output('output.mp4')
    .overwrite_output()
    .run()
)
```

## Streaming

### HLS (HTTP Live Streaming)

```python
# Create HLS stream
(
    ffmpeg
    .input('input.mp4')
    .output('stream.m3u8',
        vcodec='libx264',
        crf=23,
        preset='fast',
        acodec='aac',
        audio_bitrate='128k',
        f='hls',
        hls_time=10,           # Segment duration
        hls_list_size=0,       # Keep all segments
        hls_segment_filename='segment_%03d.ts'
    )
    .overwrite_output()
    .run()
)

# Multi-bitrate HLS (adaptive streaming)
input_file = ffmpeg.input('input.mp4')

# Create multiple quality streams
streams = []
for height, bitrate in [(1080, '5000k'), (720, '2500k'), (480, '1000k')]:
    stream = (
        input_file
        .filter('scale', -2, height)
        .output(f'stream_{height}p.m3u8',
            vcodec='libx264',
            video_bitrate=bitrate,
            preset='fast',
            acodec='aac',
            f='hls',
            hls_time=10,
            hls_segment_filename=f'segment_{height}p_%03d.ts'
        )
    )
    streams.append(stream)

# Create master playlist manually
```

### DASH (Dynamic Adaptive Streaming)

```python
(
    ffmpeg
    .input('input.mp4')
    .output('manifest.mpd',
        vcodec='libx264',
        acodec='aac',
        f='dash',
        seg_duration=10,
        adaptation_sets='id=0,streams=v id=1,streams=a'
    )
    .overwrite_output()
    .run()
)
```

### RTMP Streaming

```python
# Stream to RTMP server
(
    ffmpeg
    .input('input.mp4', re=None)  # Read at native rate
    .output('rtmp://server/live/stream',
        vcodec='libx264',
        preset='ultrafast',
        tune='zerolatency',
        acodec='aac',
        f='flv'
    )
    .overwrite_output()
    .run()
)

# Stream from webcam
(
    ffmpeg
    .input('0', f='dshow', i='video="Webcam Name"')  # Windows
    # .input('/dev/video0', f='v4l2')  # Linux
    .output('rtmp://server/live/stream',
        vcodec='libx264',
        preset='ultrafast',
        tune='zerolatency',
        f='flv'
    )
    .run()
)
```

## Metadata and Probing

### Get Video Information

```python
import ffmpeg
import json

# Probe file
probe = ffmpeg.probe('video.mp4')

# Get format info
format_info = probe['format']
duration = float(format_info['duration'])
size_bytes = int(format_info['size'])
bitrate = int(format_info['bit_rate'])

print(f"Duration: {duration:.2f}s")
print(f"Size: {size_bytes / 1024 / 1024:.2f}MB")
print(f"Bitrate: {bitrate / 1000:.0f}kbps")

# Get video stream info
video_stream = next(
    (s for s in probe['streams'] if s['codec_type'] == 'video'),
    None
)
if video_stream:
    width = video_stream['width']
    height = video_stream['height']
    fps = eval(video_stream['r_frame_rate'])  # e.g., "30/1"
    codec = video_stream['codec_name']
    print(f"Resolution: {width}x{height}")
    print(f"FPS: {fps:.2f}")
    print(f"Codec: {codec}")

# Get audio stream info
audio_stream = next(
    (s for s in probe['streams'] if s['codec_type'] == 'audio'),
    None
)
if audio_stream:
    sample_rate = audio_stream['sample_rate']
    channels = audio_stream['channels']
    audio_codec = audio_stream['codec_name']
    print(f"Audio: {audio_codec}, {sample_rate}Hz, {channels}ch")
```

### Using ffprobe Directly

```python
import subprocess
import json

def get_video_info(filepath: str) -> dict:
    """Get detailed video information using ffprobe."""
    cmd = [
        'ffprobe',
        '-v', 'quiet',
        '-print_format', 'json',
        '-show_format',
        '-show_streams',
        filepath
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    return json.loads(result.stdout)

# Get specific field
def get_duration(filepath: str) -> float:
    """Get video duration in seconds."""
    cmd = [
        'ffprobe',
        '-v', 'error',
        '-show_entries', 'format=duration',
        '-of', 'default=noprint_wrappers=1:nokey=1',
        filepath
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    return float(result.stdout.strip())

# Get frame count
def get_frame_count(filepath: str) -> int:
    """Get total frame count."""
    cmd = [
        'ffprobe',
        '-v', 'error',
        '-select_streams', 'v:0',
        '-count_frames',
        '-show_entries', 'stream=nb_read_frames',
        '-of', 'default=noprint_wrappers=1:nokey=1',
        filepath
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    return int(result.stdout.strip())
```

### Set Metadata

```python
# Set video metadata
(
    ffmpeg
    .input('input.mp4')
    .output('output.mp4',
        c='copy',
        **{
            'metadata': 'title=My Video',
            'metadata:s:v:0': 'title=Video Track',
            'metadata:s:a:0': 'title=Audio Track',
        }
    )
    .overwrite_output()
    .run()
)

# Copy all metadata from another file
(
    ffmpeg
    .input('input.mp4')
    .output('output.mp4',
        c='copy',
        map_metadata=0
    )
    .overwrite_output()
    .run()
)

# Strip all metadata
(
    ffmpeg
    .input('input.mp4')
    .output('output.mp4',
        c='copy',
        map_metadata=-1
    )
    .overwrite_output()
    .run()
)
```

## Thumbnail Generation

### Single Thumbnail

```python
# Extract frame at specific time
(
    ffmpeg
    .input('video.mp4', ss=10)  # Seek to 10 seconds
    .output('thumbnail.jpg',
        vframes=1,
        q=2  # Quality 1-31 (lower is better)
    )
    .overwrite_output()
    .run()
)

# Extract at percentage
import ffmpeg

probe = ffmpeg.probe('video.mp4')
duration = float(probe['format']['duration'])
timestamp = duration * 0.25  # 25% into video

(
    ffmpeg
    .input('video.mp4', ss=timestamp)
    .output('thumbnail.jpg', vframes=1)
    .overwrite_output()
    .run()
)
```

### Multiple Thumbnails

```python
# Extract every N seconds
(
    ffmpeg
    .input('video.mp4')
    .filter('fps', fps=1/10)  # 1 frame every 10 seconds
    .output('thumb_%04d.jpg', q=2)
    .overwrite_output()
    .run()
)

# Extract specific number of thumbnails
probe = ffmpeg.probe('video.mp4')
duration = float(probe['format']['duration'])
num_thumbnails = 10

(
    ffmpeg
    .input('video.mp4')
    .filter('fps', fps=num_thumbnails/duration)
    .output('thumb_%04d.jpg', q=2)
    .overwrite_output()
    .run()
)

# Create thumbnail grid/sprite sheet
(
    ffmpeg
    .input('video.mp4')
    .filter('fps', fps=1/5)
    .filter('scale', 160, -1)
    .filter('tile', '5x5')
    .output('sprite_%04d.jpg')
    .overwrite_output()
    .run()
)
```

## PyAV (High Performance)

PyAV provides direct access to FFmpeg's libraries via Cython bindings, offering better performance for frame-level operations.

```python
import av
import numpy as np

# Read video frames
def read_frames(filepath: str):
    """Generator yielding video frames as numpy arrays."""
    container = av.open(filepath)
    for frame in container.decode(video=0):
        yield frame.to_ndarray(format='rgb24')

# Process video frame by frame
with av.open('input.mp4') as input_container:
    with av.open('output.mp4', 'w') as output_container:
        # Create output stream matching input
        input_stream = input_container.streams.video[0]
        output_stream = output_container.add_stream('libx264', rate=input_stream.rate)
        output_stream.width = input_stream.width
        output_stream.height = input_stream.height
        output_stream.pix_fmt = 'yuv420p'

        for frame in input_container.decode(video=0):
            # Convert to numpy, process, convert back
            img = frame.to_ndarray(format='rgb24')
            # Process image...
            processed = av.VideoFrame.from_ndarray(img, format='rgb24')
            processed.pts = frame.pts

            # Encode and write
            for packet in output_stream.encode(processed):
                output_container.mux(packet)

        # Flush encoder
        for packet in output_stream.encode():
            output_container.mux(packet)

# Extract audio samples
with av.open('video.mp4') as container:
    audio_stream = container.streams.audio[0]
    for frame in container.decode(audio=0):
        # frame.to_ndarray() returns audio samples
        samples = frame.to_ndarray()
        # Shape: (channels, samples)
```

## Subprocess Patterns

For full FFmpeg control when libraries don't support specific features.

```python
import subprocess
from pathlib import Path
from typing import Optional

def run_ffmpeg(
    input_path: str,
    output_path: str,
    options: list[str],
    timeout: Optional[int] = None
) -> tuple[int, str, str]:
    """Run FFmpeg with proper error handling."""
    cmd = [
        'ffmpeg',
        '-y',  # Overwrite output
        '-i', input_path,
        *options,
        output_path
    ]

    result = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        timeout=timeout
    )

    return result.returncode, result.stdout, result.stderr

# Example usage
returncode, stdout, stderr = run_ffmpeg(
    'input.mp4',
    'output.mp4',
    ['-c:v', 'libx264', '-crf', '23', '-c:a', 'aac']
)

if returncode != 0:
    print(f"Error: {stderr}")

# Pipe frames to FFmpeg
def write_frames_to_video(
    frames: list[np.ndarray],
    output_path: str,
    fps: int = 30,
    width: int = 1920,
    height: int = 1080
):
    """Write numpy array frames to video file."""
    process = subprocess.Popen(
        [
            'ffmpeg',
            '-y',
            '-f', 'rawvideo',
            '-vcodec', 'rawvideo',
            '-s', f'{width}x{height}',
            '-pix_fmt', 'rgb24',
            '-r', str(fps),
            '-i', 'pipe:0',
            '-c:v', 'libx264',
            '-pix_fmt', 'yuv420p',
            '-crf', '18',
            output_path
        ],
        stdin=subprocess.PIPE,
        stderr=subprocess.PIPE
    )

    for frame in frames:
        process.stdin.write(frame.tobytes())

    process.stdin.close()
    process.wait()

    if process.returncode != 0:
        raise RuntimeError(f"FFmpeg error: {process.stderr.read().decode()}")
```

## Common Patterns

### Video to GIF

```python
# Basic GIF
(
    ffmpeg
    .input('video.mp4', ss=0, t=5)
    .filter('fps', fps=10)
    .filter('scale', 480, -1)
    .output('output.gif')
    .overwrite_output()
    .run()
)

# High quality GIF with palette
# Step 1: Generate palette
(
    ffmpeg
    .input('video.mp4', ss=0, t=5)
    .filter('fps', fps=10)
    .filter('scale', 480, -1, flags='lanczos')
    .filter('palettegen')
    .output('palette.png')
    .overwrite_output()
    .run()
)

# Step 2: Use palette
input_video = ffmpeg.input('video.mp4', ss=0, t=5)
palette = ffmpeg.input('palette.png')
(
    ffmpeg
    .filter([input_video, palette], 'paletteuse')
    .filter('fps', fps=10)
    .filter('scale', 480, -1, flags='lanczos')
    .output('output.gif')
    .overwrite_output()
    .run()
)
```

### Speed Change

```python
# Speed up 2x (video and audio)
input_file = ffmpeg.input('input.mp4')
video = input_file.video.filter('setpts', '0.5*PTS')  # Halve presentation timestamps
audio = input_file.audio.filter('atempo', 2.0)        # Double audio speed
(
    ffmpeg
    .output(video, audio, 'output.mp4')
    .overwrite_output()
    .run()
)

# Slow down 0.5x
input_file = ffmpeg.input('input.mp4')
video = input_file.video.filter('setpts', '2*PTS')
audio = input_file.audio.filter('atempo', 0.5)
(
    ffmpeg
    .output(video, audio, 'output.mp4')
    .overwrite_output()
    .run()
)

# Speed change > 2x (chain atempo filters)
# atempo only supports 0.5 to 2.0
audio = input_file.audio.filter('atempo', 2.0).filter('atempo', 2.0)  # 4x speed
```

### Picture-in-Picture

```python
main = ffmpeg.input('main.mp4')
pip = ffmpeg.input('pip.mp4').filter('scale', 320, 180)

(
    ffmpeg
    .overlay(main, pip, x='main_w-overlay_w-10', y=10)
    .output('output.mp4', acodec='copy')
    .overwrite_output()
    .run()
)
```

### Blur Detection / Quality Check

```python
def check_blur(filepath: str) -> float:
    """Check video for blur using Laplacian variance."""
    import cv2
    import numpy as np

    cap = cv2.VideoCapture(filepath)
    blur_scores = []

    try:
        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break

            gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
            laplacian_var = cv2.Laplacian(gray, cv2.CV_64F).var()
            blur_scores.append(laplacian_var)
    finally:
        cap.release()

    return np.mean(blur_scores)  # Higher = sharper
```

## Error Reference

| Error | Cause | Solution |
|-------|-------|----------|
| `No such file or directory` | Input file not found | Check path, use absolute paths |
| `Invalid data found` | Corrupt input or wrong format | Verify file integrity with ffprobe |
| `Output file already exists` | Missing -y flag | Use `overwrite_output()` |
| `Avi: avisynth not found` | Windows path issue | Use forward slashes |
| `Unknown encoder` | Codec not available | Install FFmpeg with codec support |
| `Device or resource busy` | File locked | Close other applications using file |
| `Too many packets buffered` | Stream sync issue | Add `-max_muxing_queue_size 1024` |
| `No frame!` | Empty input | Check input has video/audio streams |

## Performance Tips

1. **Use stream copy when possible**: `-c copy` avoids re-encoding
2. **Use hardware acceleration**: NVENC, QSV, VAAPI for encoding
3. **Use PyAV for frame-level operations**: 10-50x faster than ffmpeg-python for frame access
4. **Avoid pipes for large files**: Use temporary files instead
5. **Use appropriate presets**: `ultrafast` for real-time, `slow` for final output
6. **Process in parallel**: Split video and process chunks simultaneously
7. **Match input/output formats**: Reduces transcoding overhead

## Additional Resources

- [FFmpeg Documentation](https://ffmpeg.org/documentation.html)
- [ffmpeg-python Examples](https://github.com/kkroening/ffmpeg-python/tree/master/examples)
- [PyAV Documentation](https://pyav.org/docs/stable/)
- [FFmpeg Wiki](https://trac.ffmpeg.org/wiki)
- [FFmpeg Filters](https://ffmpeg.org/ffmpeg-filters.html)
