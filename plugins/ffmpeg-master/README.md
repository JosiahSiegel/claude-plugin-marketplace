# FFmpeg Master Plugin

Master FFmpeg across all platforms with expert knowledge of encoding, streaming, hardware acceleration, containers, and production workflows.

## Overview

The FFmpeg Master plugin equips Claude Code with comprehensive FFmpeg expertise, enabling you to transcode, stream, process audio/video, and optimize media workflows following 2025 best practices.

## Features

### Commands

- **`/ffmpeg-transcode`** - Transcode video/audio with optimal settings for target format, quality, and compatibility
- **`/ffmpeg-stream`** - Set up live streaming with RTMP, HLS, DASH, and platform-specific configurations
- **`/ffmpeg-audio`** - Process audio with extraction, conversion, normalization, and professional workflows
- **`/ffmpeg-debug`** - Debug FFmpeg issues, validate files, and troubleshoot encoding problems

### Agents

- **FFmpeg Expert Agent** - Comprehensive FFmpeg expert with knowledge of:
  - Video encoding (H.264, H.265, VVC, AV1, VP9)
  - Audio processing (AAC, MP3, Opus, FLAC, normalization)
  - Hardware acceleration (NVENC, QSV, AMF, VAAPI, Vulkan)
  - Streaming protocols (RTMP, HLS, DASH, SRT, WebRTC)
  - Production workflows and optimization

### Skills

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

**FFmpeg 8.0 "Huffman" (August 2025) - Current Stable**

One of the largest FFmpeg releases to date, named after the Huffman code algorithm.

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
