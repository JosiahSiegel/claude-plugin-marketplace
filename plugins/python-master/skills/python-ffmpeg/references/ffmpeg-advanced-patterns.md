# FFmpeg Advanced Patterns Reference

Advanced FFmpeg patterns for complex video processing workflows.

## Complex Filter Graphs

### Multiple Inputs and Outputs

```python
import ffmpeg

# Split video into multiple outputs with different qualities
input_file = ffmpeg.input('input.mp4')

# Split the stream
split = input_file.video.filter_multi_output('split', 3)

# Create different quality outputs
high = split[0].filter('scale', 1920, 1080)
medium = split[1].filter('scale', 1280, 720)
low = split[2].filter('scale', 640, 360)

# Output all three
(
    ffmpeg
    .merge_outputs(
        ffmpeg.output(high, input_file.audio, 'high.mp4', vcodec='libx264', crf=18),
        ffmpeg.output(medium, input_file.audio, 'medium.mp4', vcodec='libx264', crf=23),
        ffmpeg.output(low, input_file.audio, 'low.mp4', vcodec='libx264', crf=28)
    )
    .overwrite_output()
    .run()
)
```

### Side-by-Side Video Comparison

```python
video1 = ffmpeg.input('original.mp4')
video2 = ffmpeg.input('processed.mp4')

# Stack horizontally
(
    ffmpeg
    .filter([video1, video2], 'hstack')
    .output('comparison.mp4')
    .overwrite_output()
    .run()
)

# Stack vertically
(
    ffmpeg
    .filter([video1, video2], 'vstack')
    .output('comparison.mp4')
    .overwrite_output()
    .run()
)

# 2x2 Grid
v1 = ffmpeg.input('video1.mp4').filter('scale', 640, 360)
v2 = ffmpeg.input('video2.mp4').filter('scale', 640, 360)
v3 = ffmpeg.input('video3.mp4').filter('scale', 640, 360)
v4 = ffmpeg.input('video4.mp4').filter('scale', 640, 360)

row1 = ffmpeg.filter([v1, v2], 'hstack')
row2 = ffmpeg.filter([v3, v4], 'hstack')
(
    ffmpeg
    .filter([row1, row2], 'vstack')
    .output('grid.mp4')
    .overwrite_output()
    .run()
)
```

### Crossfade Transitions

```python
# Crossfade between two videos
video1 = ffmpeg.input('video1.mp4')
video2 = ffmpeg.input('video2.mp4')

# Video crossfade (last 1 second of video1 fades into first 1 second of video2)
v1 = video1.video.filter('trim', start=0, end=9).filter('setpts', 'PTS-STARTPTS')
v2 = video2.video.filter('trim', start=0, end=10).filter('setpts', 'PTS-STARTPTS')

# Apply xfade filter
video_out = ffmpeg.filter(
    [v1, v2],
    'xfade',
    transition='fade',
    duration=1,
    offset=8  # Start fade at 8 seconds
)

# Audio crossfade
a1 = video1.audio.filter('atrim', start=0, end=9).filter('asetpts', 'PTS-STARTPTS')
a2 = video2.audio.filter('atrim', start=0, end=10).filter('asetpts', 'PTS-STARTPTS')

audio_out = ffmpeg.filter(
    [a1, a2],
    'acrossfade',
    duration=1
)

(
    ffmpeg
    .output(video_out, audio_out, 'output.mp4')
    .overwrite_output()
    .run()
)

# Transition types: fade, wipeleft, wiperight, wipeup, wipedown,
# slideleft, slideright, slideup, slidedown, circlecrop, rectcrop,
# distance, fadeblack, fadewhite, radial, smoothleft, smoothright,
# smoothup, smoothdown, circleopen, circleclose, vertopen, vertclose,
# horzopen, horzclose, dissolve, pixelize, diagtl, diagtr, diagbl, diagbr
```

### Picture-in-Picture with Animation

```python
main = ffmpeg.input('main.mp4')
pip = ffmpeg.input('pip.mp4')

# Scale PIP video
pip_scaled = pip.video.filter('scale', 320, 180)

# Animate PIP position (slide in from right)
# Uses expressions for dynamic positioning
video_out = ffmpeg.overlay(
    main.video,
    pip_scaled,
    x="if(lt(t,1), W, W-w-10+((W-w-10)/1)*(1-t))",  # Slide in during first second
    y=10
)

(
    ffmpeg
    .output(video_out, main.audio, 'output.mp4')
    .overwrite_output()
    .run()
)
```

## Advanced Audio Processing

### Multiple Audio Tracks

```python
video = ffmpeg.input('video.mp4')
audio1 = ffmpeg.input('music.mp3')
audio2 = ffmpeg.input('voiceover.mp3')

# Mix multiple audio tracks
mixed_audio = ffmpeg.filter(
    [video.audio, audio1, audio2],
    'amix',
    inputs=3,
    duration='first',  # Match duration of first input
    dropout_transition=2
)

(
    ffmpeg
    .output(video.video, mixed_audio, 'output.mp4')
    .overwrite_output()
    .run()
)

# Adjust individual volumes before mixing
video = ffmpeg.input('video.mp4')
music = ffmpeg.input('music.mp3').filter('volume', 0.3)  # 30% volume
voice = ffmpeg.input('voiceover.mp3').filter('volume', 1.5)  # 150% volume

mixed = ffmpeg.filter([video.audio, music, voice], 'amix', inputs=3)
```

### Audio Ducking (Voice Over Music)

```python
# Duck music when voice is present
video = ffmpeg.input('video.mp4')
music = ffmpeg.input('music.mp3')
voice = ffmpeg.input('voiceover.mp3')

# Use sidechaincompress to duck music based on voice level
ducked_music = ffmpeg.filter(
    [music, voice],
    'sidechaincompress',
    threshold='0.02',
    ratio='10',
    attack='200',
    release='1000'
)

# Mix ducked music with voice
mixed = ffmpeg.filter([ducked_music, voice], 'amix', inputs=2)

(
    ffmpeg
    .output(video.video, mixed, 'output.mp4')
    .overwrite_output()
    .run()
)
```

### Audio Visualization

```python
# Create audio waveform visualization
audio = ffmpeg.input('audio.mp3')

# Showwaves filter
(
    ffmpeg
    .filter(audio, 'showwaves', s='1920x200', mode='line', rate=30)
    .output('waveform.mp4', vcodec='libx264')
    .overwrite_output()
    .run()
)

# Spectrum visualization
(
    ffmpeg
    .filter(audio, 'showspectrum', s='1920x1080', mode='combined', color='intensity', slide='scroll')
    .output('spectrum.mp4', vcodec='libx264')
    .overwrite_output()
    .run()
)

# Volume meter
(
    ffmpeg
    .filter(audio, 'showvolume', f=1, c='0xff0000', b=4, w=1920, h=100)
    .output('volume.mp4', vcodec='libx264')
    .overwrite_output()
    .run()
)
```

## Advanced Video Effects

### Stabilization

```python
import subprocess

# Step 1: Analyze video and generate transform data
subprocess.run([
    'ffmpeg', '-i', 'shaky.mp4',
    '-vf', 'vidstabdetect=shakiness=10:accuracy=15',
    '-f', 'null', '-'
])

# Step 2: Apply stabilization
(
    ffmpeg
    .input('shaky.mp4')
    .filter('vidstabtransform', smoothing=30)
    .output('stable.mp4', vcodec='libx264', crf=18)
    .overwrite_output()
    .run()
)

# One-pass (lower quality but simpler)
(
    ffmpeg
    .input('shaky.mp4')
    .filter('deshake')
    .output('stable.mp4')
    .overwrite_output()
    .run()
)
```

### Deinterlacing

```python
# High-quality deinterlacing with yadif
(
    ffmpeg
    .input('interlaced.mp4')
    .filter('yadif', mode=0, parity=-1, deint=0)
    .output('progressive.mp4')
    .overwrite_output()
    .run()
)

# Even better quality with bwdif
(
    ffmpeg
    .input('interlaced.mp4')
    .filter('bwdif')
    .output('progressive.mp4')
    .overwrite_output()
    .run()
)
```

### Noise Reduction

```python
# Video noise reduction
(
    ffmpeg
    .input('noisy.mp4')
    .filter('nlmeans', s=3.0, p=7, pc=5, r=15)  # Non-local means
    .output('clean.mp4')
    .overwrite_output()
    .run()
)

# Faster but lower quality
(
    ffmpeg
    .input('noisy.mp4')
    .filter('hqdn3d', luma_spatial=4, chroma_spatial=3, luma_tmp=6, chroma_tmp=4.5)
    .output('clean.mp4')
    .overwrite_output()
    .run()
)

# Audio noise reduction
(
    ffmpeg
    .input('noisy.mp3')
    .filter('afftdn', nf=-25)  # FFT-based denoiser
    .output('clean.mp3')
    .overwrite_output()
    .run()
)
```

### Green Screen / Chroma Key

```python
# Remove green screen and overlay on background
foreground = ffmpeg.input('greenscreen.mp4')
background = ffmpeg.input('background.mp4')

# Remove green (adjust color values as needed)
keyed = foreground.filter(
    'chromakey',
    color='0x00ff00',  # Green
    similarity=0.1,
    blend=0.1
)

(
    ffmpeg
    .overlay(background, keyed)
    .output('composited.mp4')
    .overwrite_output()
    .run()
)

# Alternative with colorkey (better edge handling)
keyed = foreground.filter(
    'colorkey',
    color='green',
    similarity=0.3,
    blend=0.1
)
```

### Motion Blur

```python
# Add motion blur effect
(
    ffmpeg
    .input('input.mp4')
    .filter('minterpolate', fps=120, mi_mode='mci', mc_mode='aobmc', me_mode='bidir', vsbmc=1)
    .filter('tblend', all_mode='average', all_opacity=0.5)
    .filter('fps', fps=30)
    .output('motion_blur.mp4')
    .overwrite_output()
    .run()
)
```

### Slow Motion with Frame Interpolation

```python
# High-quality slow motion using motion interpolation
(
    ffmpeg
    .input('input.mp4')
    .filter('minterpolate', fps=120, mi_mode='mci', mc_mode='aobmc', me_mode='bidir')
    .filter('setpts', '4*PTS')  # 4x slower
    .filter('fps', fps=30)
    .output('slowmo.mp4')
    .overwrite_output()
    .run()
)
```

### Time Lapse from Video

```python
# Create time lapse (keep every 30th frame = 30x speed)
(
    ffmpeg
    .input('input.mp4')
    .filter('select', 'not(mod(n,30))')
    .filter('setpts', 'N/30/TB')  # Adjust timestamps
    .output('timelapse.mp4', r=30)
    .overwrite_output()
    .run()
)
```

## Batch Processing

### Process Multiple Files

```python
from pathlib import Path
import ffmpeg
from concurrent.futures import ThreadPoolExecutor, as_completed

def convert_video(input_path: Path, output_dir: Path) -> bool:
    """Convert a single video file."""
    output_path = output_dir / f"{input_path.stem}.mp4"
    try:
        (
            ffmpeg
            .input(str(input_path))
            .output(str(output_path),
                vcodec='libx264',
                crf=23,
                preset='medium',
                acodec='aac',
                audio_bitrate='128k'
            )
            .overwrite_output()
            .run(quiet=True)
        )
        return True
    except ffmpeg.Error as e:
        print(f"Error processing {input_path}: {e.stderr.decode()}")
        return False

def batch_convert(input_dir: str, output_dir: str, max_workers: int = 4):
    """Batch convert all videos in a directory."""
    input_path = Path(input_dir)
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    video_files = list(input_path.glob('**/*.mov')) + \
                  list(input_path.glob('**/*.avi')) + \
                  list(input_path.glob('**/*.mkv'))

    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        futures = {
            executor.submit(convert_video, f, output_path): f
            for f in video_files
        }

        for future in as_completed(futures):
            file = futures[future]
            if future.result():
                print(f"Converted: {file.name}")
            else:
                print(f"Failed: {file.name}")

# Usage
batch_convert('input_videos/', 'output_videos/')
```

### Progress Reporting

```python
import re
import subprocess
from pathlib import Path

def transcode_with_progress(input_path: str, output_path: str):
    """Transcode video with progress reporting."""
    # Get duration first
    probe = ffmpeg.probe(input_path)
    duration = float(probe['format']['duration'])

    process = subprocess.Popen(
        [
            'ffmpeg', '-y',
            '-i', input_path,
            '-c:v', 'libx264',
            '-crf', '23',
            '-c:a', 'aac',
            '-progress', 'pipe:1',  # Output progress to stdout
            output_path
        ],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        universal_newlines=True
    )

    time_pattern = re.compile(r'out_time_ms=(\d+)')

    for line in process.stdout:
        match = time_pattern.search(line)
        if match:
            time_ms = int(match.group(1))
            time_s = time_ms / 1_000_000
            progress = min(100, (time_s / duration) * 100)
            print(f"\rProgress: {progress:.1f}%", end='', flush=True)

    process.wait()
    print("\nDone!")

    if process.returncode != 0:
        raise RuntimeError(f"FFmpeg error: {process.stderr.read()}")
```

## Live Streaming

### Stream Desktop to RTMP

```python
import subprocess
import platform

def stream_desktop(rtmp_url: str):
    """Stream desktop to RTMP server."""
    system = platform.system()

    if system == 'Windows':
        # Use gdigrab for Windows
        cmd = [
            'ffmpeg',
            '-f', 'gdigrab',
            '-framerate', '30',
            '-i', 'desktop',
            '-f', 'dshow',
            '-i', 'audio=Microphone',  # Adjust device name
            '-c:v', 'libx264',
            '-preset', 'ultrafast',
            '-tune', 'zerolatency',
            '-c:a', 'aac',
            '-b:a', '128k',
            '-f', 'flv',
            rtmp_url
        ]
    elif system == 'Linux':
        cmd = [
            'ffmpeg',
            '-f', 'x11grab',
            '-framerate', '30',
            '-s', '1920x1080',
            '-i', ':0.0',
            '-f', 'pulse',
            '-i', 'default',
            '-c:v', 'libx264',
            '-preset', 'ultrafast',
            '-tune', 'zerolatency',
            '-c:a', 'aac',
            '-b:a', '128k',
            '-f', 'flv',
            rtmp_url
        ]
    elif system == 'Darwin':
        cmd = [
            'ffmpeg',
            '-f', 'avfoundation',
            '-framerate', '30',
            '-i', '1:0',  # Screen:Audio device indices
            '-c:v', 'libx264',
            '-preset', 'ultrafast',
            '-tune', 'zerolatency',
            '-c:a', 'aac',
            '-b:a', '128k',
            '-f', 'flv',
            rtmp_url
        ]

    subprocess.run(cmd)
```

### Webcam Streaming

```python
def stream_webcam(rtmp_url: str, device: str = '0'):
    """Stream webcam to RTMP server."""
    import platform
    system = platform.system()

    if system == 'Windows':
        input_device = f'video={device}'
        input_format = 'dshow'
    elif system == 'Linux':
        input_device = f'/dev/video{device}'
        input_format = 'v4l2'
    elif system == 'Darwin':
        input_device = device
        input_format = 'avfoundation'

    cmd = [
        'ffmpeg',
        '-f', input_format,
        '-framerate', '30',
        '-video_size', '1280x720',
        '-i', input_device,
        '-c:v', 'libx264',
        '-preset', 'ultrafast',
        '-tune', 'zerolatency',
        '-b:v', '2500k',
        '-maxrate', '2500k',
        '-bufsize', '5000k',
        '-g', '60',  # Keyframe interval
        '-f', 'flv',
        rtmp_url
    ]

    subprocess.run(cmd)
```

## Subtitle Processing

### Burn Subtitles into Video

```python
# From SRT file
(
    ffmpeg
    .input('video.mp4')
    .output('output.mp4',
        vf="subtitles=subtitles.srt:force_style='FontSize=24,FontName=Arial'"
    )
    .overwrite_output()
    .run()
)

# From ASS file (preserves styling)
(
    ffmpeg
    .input('video.mp4')
    .output('output.mp4',
        vf="ass=subtitles.ass"
    )
    .overwrite_output()
    .run()
)

# Embedded subtitles
(
    ffmpeg
    .input('video.mp4')
    .output('output.mp4',
        vf="subtitles=video.mp4:si=0"  # si = subtitle stream index
    )
    .overwrite_output()
    .run()
)
```

### Extract Subtitles

```python
# Extract to SRT
(
    ffmpeg
    .input('video.mp4')
    .output('subtitles.srt',
        map='0:s:0',  # First subtitle stream
        c='srt'
    )
    .overwrite_output()
    .run()
)

# List available subtitle streams
probe = ffmpeg.probe('video.mp4')
for stream in probe['streams']:
    if stream['codec_type'] == 'subtitle':
        print(f"Index: {stream['index']}, Codec: {stream['codec_name']}, "
              f"Language: {stream.get('tags', {}).get('language', 'unknown')}")
```

### Add Subtitle Track

```python
video = ffmpeg.input('video.mp4')
subs = ffmpeg.input('subtitles.srt')

(
    ffmpeg
    .output(video, subs, 'output.mkv',
        **{'c:v': 'copy', 'c:a': 'copy', 'c:s': 'srt'}
    )
    .overwrite_output()
    .run()
)
```

## HDR and Color Processing

### HDR to SDR Conversion (Tone Mapping)

```python
(
    ffmpeg
    .input('hdr_video.mp4')
    .filter('zscale', t='linear', npl=100)
    .filter('format', 'gbrpf32le')
    .filter('zscale', p='bt709')
    .filter('tonemap', tonemap='hable', desat=0)
    .filter('zscale', t='bt709', m='bt709', r='tv')
    .filter('format', 'yuv420p')
    .output('sdr_video.mp4', vcodec='libx264', crf=18)
    .overwrite_output()
    .run()
)
```

### Color Space Conversion

```python
# Convert to BT.709 (standard HD)
(
    ffmpeg
    .input('input.mp4')
    .filter('colorspace', all='bt709')
    .output('output.mp4')
    .overwrite_output()
    .run()
)

# Convert to BT.2020 (HDR/UHD)
(
    ffmpeg
    .input('input.mp4')
    .filter('colorspace', all='bt2020')
    .output('output.mp4')
    .overwrite_output()
    .run()
)
```

### LUT Application

```python
# Apply 3D LUT for color grading
(
    ffmpeg
    .input('input.mp4')
    .filter('lut3d', file='color_grade.cube')
    .output('graded.mp4')
    .overwrite_output()
    .run()
)
```

## GPU Processing with CUDA

### CUDA-Accelerated Scaling

```python
# Requires FFmpeg compiled with --enable-cuda-nvcc
(
    ffmpeg
    .input('input.mp4', hwaccel='cuda')
    .filter('scale_cuda', 1920, 1080)
    .output('output.mp4',
        vcodec='h264_nvenc',
        preset='p4'
    )
    .overwrite_output()
    .run()
)
```

### Full GPU Pipeline

```python
(
    ffmpeg
    .input('input.mp4',
        hwaccel='cuda',
        hwaccel_output_format='cuda'
    )
    .filter('scale_cuda', 1920, 1080)
    .filter('yadif_cuda')  # GPU deinterlacing
    .output('output.mp4',
        vcodec='h264_nvenc',
        preset='p4',
        cq=23
    )
    .overwrite_output()
    .run()
)
```

## Error Recovery and Repair

### Fix Broken Video

```python
# Re-mux without re-encoding to fix container issues
(
    ffmpeg
    .input('broken.mp4')
    .output('fixed.mp4', c='copy')
    .overwrite_output()
    .run()
)

# Force keyframe at start
(
    ffmpeg
    .input('broken.mp4')
    .output('fixed.mp4',
        vcodec='libx264',
        crf=18,
        force_key_frames='expr:gte(t,0)'
    )
    .overwrite_output()
    .run()
)

# Recover from corrupt file (skip errors)
subprocess.run([
    'ffmpeg',
    '-err_detect', 'ignore_err',
    '-i', 'corrupt.mp4',
    '-c', 'copy',
    'recovered.mp4'
])
```

### Validate Video File

```python
def validate_video(filepath: str) -> dict:
    """Validate video file integrity."""
    try:
        # Quick probe
        probe = ffmpeg.probe(filepath)

        # Full decode test (slower but thorough)
        process = subprocess.run(
            ['ffmpeg', '-v', 'error', '-i', filepath, '-f', 'null', '-'],
            capture_output=True,
            text=True
        )

        return {
            'valid': process.returncode == 0,
            'duration': float(probe['format'].get('duration', 0)),
            'streams': len(probe['streams']),
            'errors': process.stderr if process.stderr else None
        }
    except ffmpeg.Error as e:
        return {
            'valid': False,
            'error': str(e)
        }
```

## Integration with OpenCV

### Read Video Frames with FFmpeg, Process with OpenCV

```python
import cv2
import numpy as np
import subprocess

def read_with_ffmpeg(filepath: str, width: int, height: int):
    """Read video frames using FFmpeg subprocess (faster than cv2.VideoCapture for some formats)."""
    process = subprocess.Popen(
        [
            'ffmpeg',
            '-i', filepath,
            '-f', 'rawvideo',
            '-pix_fmt', 'bgr24',  # OpenCV uses BGR
            '-s', f'{width}x{height}',
            'pipe:1'
        ],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL
    )

    frame_size = width * height * 3

    while True:
        raw_frame = process.stdout.read(frame_size)
        if len(raw_frame) != frame_size:
            break

        frame = np.frombuffer(raw_frame, np.uint8).reshape((height, width, 3))
        yield frame

    process.terminate()

# Usage
for frame in read_with_ffmpeg('video.mp4', 1920, 1080):
    # Process with OpenCV
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    # ...
```

### Write Processed Frames with FFmpeg

```python
import cv2
import numpy as np
import subprocess

def write_with_ffmpeg(output_path: str, width: int, height: int, fps: int = 30):
    """Create a writer context that accepts OpenCV frames."""
    process = subprocess.Popen(
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
            '-pix_fmt', 'yuv420p',
            '-crf', '18',
            output_path
        ],
        stdin=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    return process

# Usage
cap = cv2.VideoCapture('input.mp4')
width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
fps = int(cap.get(cv2.CAP_PROP_FPS))

writer = write_with_ffmpeg('output.mp4', width, height, fps)

try:
    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break

        # Process frame with OpenCV
        processed = cv2.GaussianBlur(frame, (5, 5), 0)

        # Write to FFmpeg
        writer.stdin.write(processed.tobytes())
finally:
    cap.release()
    writer.stdin.close()
    writer.wait()
```

## Performance Optimization

### Memory-Efficient Processing

```python
import ffmpeg
import tempfile
from pathlib import Path

def process_large_video(input_path: str, output_path: str, chunk_duration: int = 60):
    """Process large video in chunks to manage memory."""
    probe = ffmpeg.probe(input_path)
    duration = float(probe['format']['duration'])

    chunks = []
    temp_dir = Path(tempfile.mkdtemp())

    try:
        # Process in chunks
        for start in range(0, int(duration), chunk_duration):
            chunk_path = temp_dir / f"chunk_{start:06d}.mp4"
            (
                ffmpeg
                .input(input_path, ss=start, t=chunk_duration)
                .filter('scale', 1280, 720)  # Your processing here
                .output(str(chunk_path), vcodec='libx264', crf=23)
                .overwrite_output()
                .run(quiet=True)
            )
            chunks.append(chunk_path)

        # Concatenate chunks
        with open(temp_dir / 'list.txt', 'w') as f:
            for chunk in chunks:
                f.write(f"file '{chunk}'\n")

        (
            ffmpeg
            .input(str(temp_dir / 'list.txt'), f='concat', safe=0)
            .output(output_path, c='copy')
            .overwrite_output()
            .run()
        )
    finally:
        # Cleanup
        import shutil
        shutil.rmtree(temp_dir)
```

### Parallel Encoding

```python
from concurrent.futures import ThreadPoolExecutor
import ffmpeg

def encode_quality(input_path: str, output_path: str, height: int, crf: int):
    """Encode a single quality level."""
    (
        ffmpeg
        .input(input_path)
        .filter('scale', -2, height)
        .output(output_path, vcodec='libx264', crf=crf, preset='slow')
        .overwrite_output()
        .run(quiet=True)
    )

def create_quality_ladder(input_path: str):
    """Create multiple quality versions in parallel."""
    qualities = [
        ('1080p.mp4', 1080, 18),
        ('720p.mp4', 720, 23),
        ('480p.mp4', 480, 26),
        ('360p.mp4', 360, 28),
    ]

    with ThreadPoolExecutor(max_workers=4) as executor:
        futures = [
            executor.submit(encode_quality, input_path, output, height, crf)
            for output, height, crf in qualities
        ]

        for future in futures:
            future.result()  # Wait for completion

create_quality_ladder('input.mp4')
```

## Additional Resources

- [FFmpeg Filters Documentation](https://ffmpeg.org/ffmpeg-filters.html)
- [FFmpeg Codecs](https://ffmpeg.org/ffmpeg-codecs.html)
- [ffmpeg-python Source](https://github.com/kkroening/ffmpeg-python)
- [PyAV Cookbook](https://pyav.org/docs/stable/cookbook/)
- [FFmpeg Wiki - Encoding Guide](https://trac.ffmpeg.org/wiki/Encode/H.264)
