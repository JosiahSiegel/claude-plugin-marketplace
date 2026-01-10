# FFmpeg Master Plugin v3.2.0

Master FFmpeg across all platforms with expert knowledge of encoding, streaming, hardware acceleration, containers, production workflows, **advanced creative effects**, and **VIRAL VIDEO CREATION** for TikTok, YouTube Shorts, Instagram Reels, and more.

## Overview

The FFmpeg Master plugin equips Claude Code with comprehensive FFmpeg expertise, enabling you to transcode, stream, process audio/video, and optimize media workflows following 2025 best practices.

## Features

### Commands

#### Viral Video Commands (NEW in v3.0)
- **`/ffmpeg-viral-tiktok`** - Create TikTok-optimized viral video (9:16, auto-captions, hooks, platform encoding)
- **`/ffmpeg-viral-shorts`** - Create YouTube Shorts-optimized video (9:16, retention optimization, thumbnails)
- **`/ffmpeg-batch-social`** - Export to all platforms simultaneously (TikTok, Shorts, Reels, Twitter, Snapchat)

#### Core Commands
- **`/ffmpeg-transcode`** - Transcode video/audio with optimal settings for target format, quality, and compatibility
- **`/ffmpeg-stream`** - Set up live streaming with RTMP, HLS, DASH, and platform-specific configurations
- **`/ffmpeg-audio`** - Process audio with extraction, conversion, normalization, and professional workflows
- **`/ffmpeg-debug`** - Debug FFmpeg issues, validate files, and troubleshoot encoding problems
- **`/ffmpeg-effects`** - Apply creative video effects (glitch, datamosh, VHS, chromatic aberration, distortion)
- **`/ffmpeg-color`** - Apply color grading, LUTs, chromakey (green screen), and cinematic color effects
- **`/ffmpeg-kinetic`** - Create kinetic captions with word-grow, bounce, pop, elastic, and karaoke effects (NEW in v3.2)

### Agents

- **FFmpeg Expert Agent** - Comprehensive FFmpeg expert with knowledge of:
  - Video encoding (H.264, H.265, VVC, AV1, VP9)
  - Audio processing (AAC, MP3, Opus, FLAC, normalization)
  - Hardware acceleration (NVENC, QSV, AMF, VAAPI, Vulkan)
  - Streaming protocols (RTMP, HLS, DASH, SRT, WebRTC)
  - Production workflows and optimization
  - **Color grading**: LUTs, curves, color balance, chromakey, green screen removal
  - **Glitch/Distortion**: Datamosh, VHS effects, chromatic aberration, displacement
  - **Karaoke/Animated text**: ASS karaoke timing, scrolling credits, kinetic typography

### Skills

#### Viral Video Skills (NEW in v3.0)
- **viral-video-platform-specs** - Complete platform upload specs for TikTok, YouTube Shorts, Instagram Reels, Twitter, Snapchat
- **viral-video-hook-templates** - 10 proven viral hook patterns with FFmpeg implementations
- **viral-video-animated-captions** - CapCut-style animated word-level captions (pop, sweep, karaoke, bounce)
- **ffmpeg-kinetic-captions** - Advanced kinetic caption techniques with word-grow karaoke, spring physics, elastic bounce, platform-specific timing (NEW in v3.2)

#### Core Skills
- **ffmpeg-fundamentals-2025** - FFmpeg 7.1/8.0 features, command syntax, codecs, and essential operations
- **ffmpeg-hardware-acceleration** - NVIDIA NVENC, Intel QSV, AMD AMF, VAAPI, Vulkan Video guides
- **ffmpeg-docker-containers** - Docker images, GPU support, Kubernetes patterns
- **ffmpeg-modal-containers** - Modal.com serverless video processing, GPU/CPU containers, parallel processing
- **ffmpeg-webassembly-workers** - ffmpeg.wasm, Cloudflare Workers limitations and workarounds
- **ffmpeg-cloudflare-containers** - Cloudflare Containers, native FFmpeg at edge, GPU support
- **ffmpeg-cicd-runners** - GitHub Actions, GitLab CI, Jenkins optimization
- **ffmpeg-streaming** - RTMP, HLS, DASH, SRT, ABR streaming patterns
- **ffmpeg-audio-processing** - Audio encoding, EBU R128 normalization, loudnorm
- **ffmpeg-captions-subtitles** - Subtitle formats (SRT, ASS, VTT), burning captions, extracting subtitles, styling
- **ffmpeg-waveforms-visualization** - Audio waveforms, spectrum analyzers, showwaves, showspectrum filters
- **ffmpeg-transitions-effects** - Video transitions (xfade), fades, dissolves, wipes, slides, creative effects
- **ffmpeg-shapes-graphics** - Drawing shapes, drawbox, drawtext, overlays, geometric patterns, graphics
- **ffmpeg-color-grading-chromakey** - Professional color grading, LUTs, curves, chromakey, green screen removal, cinematic looks
- **ffmpeg-glitch-distortion-effects** - Datamosh, VHS simulation, chromatic aberration, wave distortion, motion trails
- **ffmpeg-karaoke-animated-text** - ASS karaoke with word-by-word highlighting, scrolling credits, kinetic typography
- **ffmpeg-opencv-integration** - FFmpeg + OpenCV + Python integration guide (NEW in v3.1)

## Installation

### Via Marketplace

```bash
/plugin marketplace add JosiahSiegel/claude-plugin-marketplace
/plugin install ffmpeg-master@claude-plugin-marketplace
```

## Usage

### Basic Transcoding

```bash
/ffmpeg-transcode
```

Claude will:
1. Analyze your input file
2. Ask about target format and quality requirements
3. Generate optimal FFmpeg command with explanations
4. Provide verification commands

### Live Streaming Setup

```bash
/ffmpeg-stream
```

Claude will:
1. Determine platform (Twitch, YouTube, Facebook, custom)
2. Configure source (webcam, screen, file)
3. Generate platform-specific RTMP/HLS commands
4. Include hardware acceleration options

### Audio Processing

```bash
/ffmpeg-audio
```

Claude will:
1. Analyze audio properties
2. Recommend codec and bitrate for use case
3. Provide normalization settings (EBU R128)
4. Generate complete processing chain

### Debugging

```bash
/ffmpeg-debug
```

Claude will:
1. Analyze error messages
2. Diagnose root cause
3. Provide solution commands
4. Suggest prevention strategies

## Expert Consultation

For complex FFmpeg questions or architecture guidance:

```bash
/agent ffmpeg-expert
```

The FFmpeg Expert agent can help with:
- Encoding parameter optimization
- Hardware acceleration setup
- Streaming architecture design
- Quality vs. size tradeoffs
- Production workflow design
- Platform compatibility issues

## What's Covered

### FFmpeg Versions

**FFmpeg 8.0.1 (Released 2025-11-20) - Current Latest Stable**

The latest stable release from the 8.0 "Huffman" branch (cut from master 2025-08-09). Contains important bug fixes and security updates. One of the largest FFmpeg releases to date, named after the Huffman code algorithm.

**Check your version**: `ffmpeg -version`

**Official sources for updates**:
- https://ffmpeg.org/download.html
- https://github.com/FFmpeg/FFmpeg/releases

| Feature | Description |
|---------|-------------|
| **Whisper AI** | Built-in speech recognition via whisper.cpp for subtitle generation and transcription |
| **Vulkan Compute** | FFv1 encode/decode, ProRes RAW decode, AV1 encode, VP9 decode via Vulkan 1.3 |
| **APV Codec** | Samsung Advanced Professional Video encoder (via libopenapv) and native decoder |
| **VVC Hardware** | VA-API and QSV hardware decoding for H.266/VVC |
| **WHIP Muxer** | Sub-second latency WebRTC ingestion protocol |
| **New Codecs** | ProRes RAW, RealVideo 6.0, G.728, Sanyo LD-ADPCM, libx265 alpha |
| **New Filters** | whisper, colordetect, pad_cuda, scale_d3d11 |
| **Breaking** | Dropped OpenSSL 1.1.0, yasm; deprecated OpenMAX encoders |

**FFmpeg 7.1 "Péter" LTS (September 2024)**
- Production-ready VVC/H.266 decoder
- MV-HEVC for Apple Vision Pro
- xHE-AAC decoder
- Vulkan H.264/H.265 encoders
- Intel QSV VVC decoder

### Hardware Acceleration

| Platform | Encoders | Performance |
|----------|----------|-------------|
| NVIDIA NVENC | h264, hevc, av1 | 10-20x faster |
| Intel QSV | h264, hevc, av1, vvc | 8-15x faster |
| AMD AMF | h264, hevc, av1 | 8-15x faster |
| VAAPI (Linux) | h264, hevc, av1 | 8-15x faster |
| Vulkan Video | h264, hevc, av1 | Cross-platform |
| VideoToolbox | h264, hevc, prores | Apple native |

### Container/Edge/Serverless Deployment

- **Docker**: jrottenberg/ffmpeg, linuxserver/ffmpeg, GPU-enabled images
- **Modal.com**: Serverless GPU/CPU containers, parallel processing with map/starmap
- **Cloudflare Workers**: ffmpeg.wasm limitations and workarounds
- **Cloudflare Containers**: Native FFmpeg at edge with GPU support
- **WebAssembly**: ffmpeg.wasm with COOP/COEP configuration
- **CI/CD**: GitHub Actions, GitLab CI, Jenkins patterns

### Streaming Protocols

| Protocol | Latency | Use Case |
|----------|---------|----------|
| RTMP/RTMPS | 1-5s | Ingest to servers |
| HLS | 6-30s | CDN delivery |
| LL-HLS | 2-4s | Low-latency Apple |
| DASH | 6-30s | ABR streaming |
| LL-DASH | 2-4s | Low-latency |
| SRT | <1s | Contribution |
| WHIP/WebRTC | <0.5s | Real-time |

### Audio Processing

- **Codecs**: AAC, MP3, Opus, FLAC, AC3, EAC3
- **Normalization**: EBU R128, loudnorm, RMS
- **Filters**: EQ, compression, noise reduction, fade
- **Standards**: Broadcast (-23 LUFS), Streaming (-14 LUFS), Podcast (-16 LUFS)

### Captions and Subtitles

- **Formats**: SRT, ASS/SSA, VTT, TTML, CEA-608/708
- **Operations**: Burn-in, extract, convert, style, position
- **Whisper AI**: Automatic transcription (FFmpeg 8.0+)
- **Accessibility**: Font sizing, colors, positioning

### Audio Visualization

- **Waveforms**: showwaves, showwavespic - animated and static
- **Spectrum**: showspectrum, showspectrumpic, showcqt
- **Other**: showfreqs, avectorscope, ahistogram
- **Templates**: Music videos, podcast visuals, dashboards

### Video Transitions

- **xfade Filter**: 40+ built-in transitions
- **Types**: Fade, dissolve, wipe, slide, circle, zoom, pixelize
- **Features**: Custom expressions, audio crossfade sync
- **Multi-clip**: Slideshow creation, varied transitions

### Shapes and Graphics

- **Drawing**: drawbox, drawgrid, drawtext, geq
- **Overlays**: Logos, watermarks, lower thirds
- **Effects**: Blend modes, vignettes, color tints
- **Animation**: Moving, scaling, rotating graphics

## Quality Settings Reference

### CRF Values (Constant Rate Factor)

| Quality | x264 | x265 | VP9 | Use Case |
|---------|------|------|-----|----------|
| Lossless | 0 | 0 | 0 | Editing |
| Very High | 18 | 20 | 15 | Archival |
| High | 20-23 | 22-25 | 23-28 | General |
| Medium | 24-26 | 26-28 | 30-35 | Streaming |
| Low | 28+ | 30+ | 40+ | Preview |

### Encoding Presets

| Preset | Speed | Quality | Use Case |
|--------|-------|---------|----------|
| ultrafast | 10x | Lower | Live/preview |
| veryfast | 5x | Low | Streaming |
| fast | 2x | Medium | General |
| **medium** | **1x** | **Balanced** | **Default** |
| slow | 0.5x | High | Quality |
| veryslow | 0.1x | Highest | Archival |

## Examples

### Example: TikTok-Ready Viral Video (NEW)

```bash
# Convert any video to TikTok format with captions and hook
/ffmpeg-viral-tiktok

# Result:
ffmpeg -i input.mp4 \
  -filter_complex "
    [0:v]scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black[v1];
    [v1]drawtext=text='WAIT FOR IT...':fontsize=64:fontcolor=yellow:borderw=4:bordercolor=black:x=(w-tw)/2:y=h*0.12:enable='between(t,0,2.5)'[v2];
    [0:a]loudnorm=I=-16:TP=-1.5:LRA=11[a]
  " \
  -map "[v2]" -map "[a]" \
  -c:v libx264 -preset fast -crf 23 \
  -c:a aac -b:a 128k -ar 44100 \
  -pix_fmt yuv420p \
  -movflags +faststart \
  -t 60 \
  output_tiktok.mp4
```

### Example: Batch Export for All Platforms (NEW)

```bash
# Export to TikTok, Shorts, Reels, and Twitter simultaneously
/ffmpeg-batch-social

# Creates:
# - video_tiktok.mp4 (60s max, 128kbps audio)
# - video_shorts.mp4 (59s max, 192kbps audio)
# - video_reels.mp4 (90s max, 30fps)
# - video_twitter.mp4 (140s max)
# - Thumbnails for each
```

### Example: CapCut-Style Animated Captions (NEW)

```bash
# Generate word-by-word animated captions
# 1. Generate transcript
ffmpeg -i input.mp4 -vn \
  -af "whisper=model=ggml-base.bin:language=auto:destination=transcript.json:format=json" \
  -f null -

# 2. Convert to animated ASS (using provided Python script)
python json_to_ass.py transcript.json captions.ass pop

# 3. Burn animated captions
ffmpeg -i input.mp4 \
  -vf "ass=captions.ass" \
  -c:v libx264 -preset fast -crf 23 \
  -c:a copy \
  output_with_animated_captions.mp4
```

### Example: Viral Hook with Pattern Interrupt (NEW)

```bash
# Add zoom punch + text hook in first 2 seconds
ffmpeg -i input.mp4 \
  -vf "zoompan=z='if(lt(t,1),1.3-0.3*t,1)':d=1:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s=1080x1920,drawtext=text='STOP SCROLLING':fontsize=72:fontcolor=red:borderw=5:bordercolor=white:x=(w-tw)/2:y=h*0.12:enable='between(t,0,2)'" \
  -c:v libx264 -preset fast -crf 23 \
  -c:a copy \
  output_with_hook.mp4
```

### Example: Web-Ready MP4

```bash
# Ask for transcoding help
/ffmpeg-transcode

# Result:
ffmpeg -i input.mov \
  -c:v libx264 -preset medium -crf 23 \
  -c:a aac -b:a 128k \
  -movflags +faststart \
  -pix_fmt yuv420p \
  output.mp4
```

### Example: Stream to Twitch

```bash
# Ask for streaming setup
/ffmpeg-stream

# Result:
ffmpeg -re -i input.mp4 \
  -c:v libx264 -preset veryfast -b:v 6000k -maxrate 6000k -bufsize 12000k \
  -g 60 -keyint_min 60 \
  -c:a aac -b:a 160k -ar 44100 \
  -f flv rtmp://live.twitch.tv/app/YOUR_STREAM_KEY
```

### Example: Normalize Podcast Audio

```bash
# Ask for audio processing
/ffmpeg-audio

# Result:
ffmpeg -i podcast_raw.wav \
  -af "highpass=f=80,acompressor=threshold=-20dB:ratio=4,loudnorm=I=-16:TP=-1.5:LRA=11" \
  -c:a aac -b:a 96k \
  podcast.m4a
```

### Example: GPU-Accelerated Encoding

```bash
# NVIDIA GPU encoding
ffmpeg -hwaccel cuda -hwaccel_output_format cuda \
  -i input.mp4 \
  -c:v h264_nvenc -preset p4 -cq 23 \
  -c:a copy \
  output.mp4
```

### Example: Burn Subtitles

```bash
# Burn SRT subtitles with custom styling
ffmpeg -i video.mp4 \
  -vf "subtitles=subs.srt:force_style='FontSize=24,Outline=2'" \
  output.mp4
```

### Example: Whisper AI Transcription (FFmpeg 8.0+)

```bash
# Generate SRT subtitles automatically
ffmpeg -i video.mp4 -vn \
  -af "whisper=model=ggml-base.bin:language=auto:destination=subtitles.srt:format=srt" \
  -f null -
```

### Example: Generate Waveform Video

```bash
# Create waveform visualization
ffmpeg -i audio.mp3 \
  -filter_complex "[0:a]showwaves=s=1280x720:mode=cline:colors=green[v]" \
  -map "[v]" -map 0:a \
  waveform.mp4
```

### Example: Video Transition

```bash
# Crossfade between two clips
ffmpeg -i clip1.mp4 -i clip2.mp4 \
  -filter_complex "[0:v][1:v]xfade=transition=fade:duration=1:offset=4[v]" \
  -map "[v]" \
  output.mp4
```

### Example: WHIP WebRTC Streaming (FFmpeg 8.0+)

```bash
# Sub-second latency streaming to WebRTC endpoint
ffmpeg -re -i input.mp4 \
  -c:v libx264 -preset ultrafast -tune zerolatency \
  -c:a libopus \
  -f whip \
  "https://whip-server.example.com/publish/stream"
```

### Example: Vulkan FFv1 Lossless Capture (FFmpeg 8.0+)

```bash
# High-throughput lossless screen capture
ffmpeg -init_hw_device vulkan \
  -f gdigrab -framerate 60 -i desktop \
  -c:v ffv1_vulkan \
  screen_capture.mkv
```

### Example: Draw Shapes

```bash
# Add semi-transparent box with text
ffmpeg -i video.mp4 \
  -vf "drawbox=x=10:y=10:w=300:h=80:color=black@0.7:t=fill,\
       drawtext=text='LIVE':x=30:y=30:fontsize=48:fontcolor=red" \
  output.mp4
```

### Example: Green Screen Composite

```bash
# Remove green screen and composite over background
ffmpeg -i foreground.mp4 -i background.mp4 \
  -filter_complex "[0:v]chromakey=0x00FF00:0.3:0.1[fg];[1:v][fg]overlay" \
  -c:v libx264 -crf 18 output.mp4
```

### Example: Cinematic Color Grading

```bash
# Apply teal and orange blockbuster look
ffmpeg -i input.mp4 \
  -vf "curves=b='0/0.1 0.5/0.4 1/0.8':r='0/0 0.5/0.6 1/1',eq=saturation=1.2:contrast=1.1" \
  output.mp4
```

### Example: Datamosh Glitch Effect

```bash
# Create pixel-bleeding datamosh effect
ffmpeg -i input.mp4 \
  -vf "minterpolate='mi_mode=mci:mc_mode=aobmc:me_mode=bidir:vsbmc=1'" \
  -c:v libx264 -crf 18 glitch.mp4
```

### Example: VHS Retro Effect

```bash
# Simulate VHS tape with noise, color shift, and scanlines
ffmpeg -i input.mp4 \
  -vf "noise=c0s=15:c0f=t,eq=saturation=1.4,chromashift=cbh=3:crh=-3,curves=preset=vintage" \
  vhs_output.mp4
```

### Example: ASS Karaoke Subtitles

```bash
# Burn karaoke subtitles with word-by-word highlighting
ffmpeg -i music_video.mp4 \
  -vf "ass=karaoke.ass" \
  -c:v libx264 -crf 18 output.mp4
```

### Example: Scrolling End Credits

```bash
# Create scrolling credits overlay
ffmpeg -i video.mp4 \
  -vf "drawtext=textfile=credits.txt:fontsize=32:fontcolor=white:x=(w-tw)/2:y=h-100*t" \
  credits_output.mp4
```

### Example: Modal.com Batch Processing

```python
# Parallel video transcoding on Modal.com
import modal

app = modal.App("batch-transcode")
ffmpeg_image = modal.Image.debian_slim().apt_install("ffmpeg")

@app.function(image=ffmpeg_image)
def transcode(video_bytes: bytes) -> bytes:
    import subprocess, tempfile
    from pathlib import Path

    with tempfile.TemporaryDirectory() as tmpdir:
        input_path = Path(tmpdir) / "input"
        output_path = Path(tmpdir) / "output.mp4"
        input_path.write_bytes(video_bytes)

        subprocess.run([
            "ffmpeg", "-y", "-i", str(input_path),
            "-c:v", "libx264", "-preset", "fast", "-crf", "23",
            str(output_path)
        ], check=True)

        return output_path.read_bytes()

# Process 100 videos in parallel across 100 containers
results = list(transcode.map(video_list))
```

### Example: FFmpeg + OpenCV Pipeline (NEW in v3.1)

```python
import subprocess
import numpy as np
import cv2

def ffmpeg_to_opencv_pipe(input_path: str, width: int, height: int):
    """Read video with FFmpeg, process frames with OpenCV."""
    # CRITICAL: Use bgr24 for OpenCV (OpenCV uses BGR, not RGB!)
    cmd = [
        'ffmpeg', '-i', input_path,
        '-f', 'rawvideo', '-pix_fmt', 'bgr24',
        '-s', f'{width}x{height}', '-'
    ]
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
    frame_size = width * height * 3

    while True:
        raw_frame = process.stdout.read(frame_size)
        if len(raw_frame) != frame_size:
            break
        # Convert to NumPy array (already BGR for OpenCV)
        frame = np.frombuffer(raw_frame, dtype=np.uint8).reshape(height, width, 3)
        # GOTCHA: OpenCV uses img[y, x] not img[x, y]!
        edges = cv2.Canny(frame, 100, 200)
        yield edges
    process.wait()

# Usage
for edge_frame in ffmpeg_to_opencv_pipe("input.mp4", 1920, 1080):
    cv2.imshow("Edges", edge_frame)
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break
```

### Example: GPU Video I/O with ffmpegcv (NEW in v3.1)

```python
import ffmpegcv
import cv2

# GPU-accelerated reading (NVDEC) and writing (NVENC)
cap = ffmpegcv.VideoCapture("input.mp4", gpu=0)  # GPU 0
writer = ffmpegcv.VideoWriter("output.mp4", codec="h264_nvenc", fps=30, frameSize=(1920, 1080))

while True:
    ret, frame = cap.read()  # Returns BGR like OpenCV!
    if not ret:
        break
    # OpenCV processing
    processed = cv2.GaussianBlur(frame, (5, 5), 0)
    writer.write(processed)

cap.release()
writer.release()
```

### Example: FFmpeg + OpenCV + Modal Parallel Processing (NEW in v3.1)

```python
import modal

app = modal.App("ffmpeg-opencv-pipeline")

image = (
    modal.Image.debian_slim()
    .apt_install("ffmpeg", "libsm6", "libxext6", "libgl1")
    .pip_install("opencv-python-headless", "numpy")
)

@app.function(image=image)
def process_frame(frame_data: tuple[int, bytes]) -> tuple[int, bytes]:
    """Process single frame with OpenCV."""
    import cv2
    import numpy as np

    frame_idx, frame_bytes = frame_data
    nparr = np.frombuffer(frame_bytes, np.uint8)
    frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)  # BGR

    # Heavy OpenCV processing
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    edges = cv2.Canny(gray, 50, 150)
    result = cv2.cvtColor(edges, cv2.COLOR_GRAY2BGR)

    _, encoded = cv2.imencode('.png', result)
    return frame_idx, encoded.tobytes()

# Process 1000 frames in parallel across 100+ containers!
inputs = [(i, frame_bytes) for i, frame_bytes in enumerate(frames)]
results = list(process_frame.map(inputs))
```

### Utility Scripts

The plugin includes ready-to-use shell scripts for common advanced operations:

- **`apply-glitch-effects.sh`** - Apply datamosh, VHS, chromatic, trails, wave, or pixelate effects with intensity control (1-10)
- **`apply-color-grade.sh`** - Apply cinematic, vintage, noir, warm, cool, bleach, instagram, or matrix color presets
- **`generate-karaoke.sh`** - Convert timestamped lyrics to ASS karaoke format, apply to video, or generate templates

**Usage Examples:**
```bash
# Apply VHS effect at intensity 7
./scripts/apply-glitch-effects.sh vhs input.mp4 output.mp4 7

# Apply cinematic color grade
./scripts/apply-color-grade.sh cinematic input.mp4 graded.mp4

# Create karaoke from lyrics file
./scripts/generate-karaoke.sh create lyrics.txt karaoke.ass neon
./scripts/generate-karaoke.sh apply video.mp4 karaoke.ass output.mp4
```

## Requirements

- **FFmpeg 7.1+** for most features (8.0 for Whisper AI, Vulkan codecs)
- **Hardware acceleration** requires appropriate drivers:
  - NVIDIA: Driver 450+, NVIDIA Container Toolkit for Docker
  - Intel: Intel Media SDK or oneVPL
  - AMD: AMD drivers with AMF support

## Best Practices Applied

### Encoding
- Use CRF for quality-based encoding
- Match preset to time constraints
- Enable faststart for web delivery
- Test on samples before batch processing

### Streaming
- Use hardware encoding for live streaming
- Match keyframe interval to segment duration
- Leave 20% bandwidth headroom
- Use CBR for consistent delivery

### Audio
- Two-pass loudnorm for best results
- Avoid multiple lossy conversions
- Match sample rate to target platform
- Use appropriate bitrates for content type

### Containers
- Pin FFmpeg versions in production
- Use read-only mounts for input files
- Limit container resources
- Use GPU containers when available

## Contributing

Found an issue or want to add support for new FFmpeg features? Contributions are welcome.

## License

MIT

## Support

For issues or questions:
- Use `/ffmpeg-debug` for troubleshooting
- Use `/agent ffmpeg-expert` for complex questions
- Check skills for detailed documentation
- Refer to official FFmpeg documentation

---

**Master video and audio processing with confidence.** This plugin ensures you follow 2025 best practices, optimize for your use case, and handle platform-specific challenges effectively.

---

## What's New in v3.2.0

### Kinetic Captions (New Skill & Command)

**Professional kinetic caption animations for viral videos!**

#### New Command: `/ffmpeg-kinetic`
Create animated kinetic captions with:
- **Word Pop** - Words pop in from small to normal with overshoot (CapCut-style)
- **Word Grow** - Words smoothly scale up when highlighted (karaoke)
- **Bounce** - Elastic bounce with multiple oscillations
- **Elastic** - Spring physics with natural damping
- **Karaoke-Grow** - Combined karaoke fill + grow animation

#### New Skill: ffmpeg-kinetic-captions
Comprehensive guide covering:
- **ASS/SSA Timing Units** - Critical: `\k` uses centiseconds, `\t` uses milliseconds
- **Spring Physics** - Natural bouncy motion with damping formulas
- **Platform-Specific Timing** - TikTok (fast), YouTube (medium), Instagram (stylish)
- **Color Transitions** - Highlight colors on grow effects
- **Python Generator** - Automated kinetic ASS generation

#### Example: Word-Grow Karaoke Effect
```ass
{\k80\t(0,200,\fscx115\fscy115)\t(200,400,\fscx100\fscy100)}Word
```
- `\k80` = highlight for 0.8 seconds (centiseconds)
- `\t(0,200,...)` = grow animation over 200ms (milliseconds)

#### Updated Script: generate-karaoke.sh
```bash
# Create kinetic captions with bounce effect for TikTok
./scripts/generate-karaoke.sh kinetic lyrics.txt output.ass bounce tiktok
```

---

## What's New in v3.1.0

### FFmpeg + OpenCV Integration (New Skill)

**Complete guide to combining FFmpeg and OpenCV for video processing pipelines!**

#### New Skill: ffmpeg-opencv-integration
- **BGR/RGB Color Format Gotchas** - OpenCV uses BGR, FFmpeg uses RGB by default
- **Frame Dimension Order** - `img[y, x]` not `img[x, y]` (the #2 source of bugs!)
- **Audio Stream Loss** - Video filters drop audio in ffmpeg-python
- **Memory Management** - Proper VideoCapture cleanup and generators

#### Library Selection Guide
| Task | Best Library | Why |
|------|--------------|-----|
| Simple video read | `cv2.VideoCapture` | Built-in, easy API |
| GPU video I/O | **ffmpegcv** | NVDEC/NVENC, OpenCV-compatible |
| Multi-threaded streaming | **VidGear** | RTSP/RTMP, camera capture |
| ML batch loading | **Decord** | 2x faster than OpenCV |
| Frame-level precision | **PyAV** | Direct libav access |
| Complex filters | ffmpeg subprocess | Full FFmpeg power |

#### Patterns Included
- FFmpeg → OpenCV pipe (decode with FFmpeg, process with OpenCV)
- OpenCV → FFmpeg pipe (process with OpenCV, encode with FFmpeg)
- Bidirectional pipeline (FFmpeg ↔ OpenCV ↔ FFmpeg)
- Modal.com parallel frame processing with map()
- GPU-accelerated pipeline with ffmpegcv on Modal

---

## What's New in v3.0.0

### VIRAL VIDEO CREATION (Major Feature)

**The FFmpeg Master plugin now helps you create viral videos for TikTok, YouTube Shorts, Instagram Reels, and more!**

#### New Viral Video Commands
- **`/ffmpeg-viral-tiktok`** - One-command TikTok optimization (9:16, captions, hooks, platform encoding)
- **`/ffmpeg-viral-shorts`** - YouTube Shorts with retention optimization and thumbnail extraction
- **`/ffmpeg-batch-social`** - Export to ALL platforms simultaneously with platform-specific encoding

#### New Viral Video Skills
- **viral-video-platform-specs** - Complete 2025-2026 specs for TikTok, YouTube Shorts, Instagram Reels, Facebook Reels, Twitter/X, Snapchat Spotlight, Pinterest Idea Pins
- **viral-video-hook-templates** - 10 research-backed viral hook patterns with FFmpeg implementations:
  1. Pattern Interrupt (glitch, zoom punch, flash)
  2. Curiosity Gap ("You won't believe...")
  3. Direct Challenge ("Stop scrolling if...")
  4. Transformation Tease (before/after)
  5. Bold Claim ("This changed everything")
  6. Counter-Intuitive (myth vs reality)
  7. Social Proof (statistics, authority)
  8. Time-Sensitive Urgency (FOMO triggers)
  9. Storytelling Hook (narrative engagement)
  10. Question Hook (activates problem-solving)
- **viral-video-animated-captions** - CapCut-style word-level animations:
  - Word Pop (bounce in one at a time)
  - Highlight Sweep (color sweeps across words)
  - Karaoke (words light up with audio timing)
  - Typewriter (characters appear sequentially)
  - Scale Pulse (words pulse larger on appear)

#### Viral Video Features
- **Platform-Specific Presets** - Correct encoding for each platform's algorithm
- **9:16 Vertical Conversion** - Multiple options (crop, letterbox, blur background, split screen)
- **Auto-Caption Generation** - Whisper AI integration with styled burn-in
- **Hook Optimization** - First 1-3 second attention-grabbing techniques
- **Retention Boosters** - Subtle zoom, progress bars, pattern interrupts
- **Batch Processing** - Weekly content calendar generation
- **Multi-Platform Export** - Single video → 6 platform versions + thumbnails

---

## What's New in v2.1.0

### New Skills
- **ffmpeg-color-grading-chromakey** - Professional color grading with LUTs, curves, chromakey, green screen removal, and cinematic film emulation presets (Kodak Portra, Fuji, teal/orange)
- **ffmpeg-glitch-distortion-effects** - Creative glitch art including datamosh via minterpolate, VHS simulation, chromatic aberration, wave distortion, motion trails with lagfun
- **ffmpeg-karaoke-animated-text** - Complete karaoke system with ASS timing tags (\k), scrolling credits, typewriter effects, bouncing text, kinetic typography

### New Commands
- **`/ffmpeg-effects`** - Quick access to glitch, datamosh, VHS, chromatic aberration, and distortion effects
- **`/ffmpeg-color`** - Quick access to LUT application, chromakey, cinematic color grading

### New Scripts
- **apply-glitch-effects.sh** - 7 effect types with intensity control
- **apply-color-grade.sh** - 8 color presets with intensity control
- **generate-karaoke.sh** - ASS karaoke generation from timestamped lyrics

### Enhanced Agent
- FFmpeg Expert agent now includes 3 new detailed examples for green screen compositing, music video glitch effects, and karaoke subtitle creation
