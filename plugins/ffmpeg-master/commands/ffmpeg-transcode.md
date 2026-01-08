---
name: Transcode Video
description: Transcode video/audio with FFmpeg using optimal settings for target format, quality, and compatibility
argument-hint: <input-file> [target-format] [quality]
---

## CRITICAL GUIDELINES

### Windows File Path Requirements

**MANDATORY: Always Use Backslashes on Windows for File Paths**

When using Edit or Write tools on Windows, you MUST use backslashes (`\`) in file paths, NOT forward slashes (`/`).

---

# FFmpeg Transcode

## Purpose
Analyze input media and generate optimal FFmpeg commands for transcoding to target format with best quality/size/compatibility balance.

## Workflow

### 1. Analyze Input
Before transcoding, analyze the source file:

```bash
# Get comprehensive media info
ffprobe -v quiet -print_format json -show_format -show_streams INPUT_FILE
```

Key information to extract:
- Video codec, resolution, frame rate, bitrate
- Audio codec, sample rate, channels, bitrate
- Duration and container format

### 2. Determine Target Requirements

Ask user about:
- **Target format**: MP4, WebM, MKV, etc.
- **Use case**: Web delivery, archival, editing, streaming
- **Quality preference**: Best quality, balanced, smaller size
- **Compatibility**: Universal, modern browsers, specific devices
- **Hardware acceleration**: Available GPU (NVIDIA, Intel, AMD)

### 3. Generate Transcode Command

#### Web Delivery (MP4)
```bash
ffmpeg -i INPUT \
  -c:v libx264 -preset medium -crf 23 \
  -c:a aac -b:a 128k \
  -movflags +faststart \
  -pix_fmt yuv420p \
  OUTPUT.mp4
```

#### High Quality Archival
```bash
ffmpeg -i INPUT \
  -c:v libx265 -preset slow -crf 20 \
  -c:a flac \
  -tag:v hvc1 \
  OUTPUT.mkv
```

#### WebM for Web
```bash
ffmpeg -i INPUT \
  -c:v libvpx-vp9 -crf 30 -b:v 0 \
  -c:a libopus -b:a 128k \
  OUTPUT.webm
```

#### With Hardware Acceleration (NVIDIA)
```bash
ffmpeg -hwaccel cuda -hwaccel_output_format cuda \
  -i INPUT \
  -c:v h264_nvenc -preset p4 -cq 23 \
  -c:a aac -b:a 128k \
  OUTPUT.mp4
```

### 4. Quality Settings Reference

| Quality | CRF (x264) | CRF (x265) | CRF (VP9) | Use Case |
|---------|------------|------------|-----------|----------|
| Lossless | 0 | 0 | 0 | Editing |
| Very High | 18 | 20 | 15 | Archival |
| High | 20-23 | 22-25 | 23-28 | General |
| Medium | 24-26 | 26-28 | 30-35 | Streaming |
| Low | 28+ | 30+ | 40+ | Preview |

### 5. Preset Reference

| Preset | Speed | Quality | Use Case |
|--------|-------|---------|----------|
| ultrafast | 10x | Lower | Live/preview |
| veryfast | 5x | Low | Quick encode |
| faster | 3x | Medium-low | Draft |
| fast | 2x | Medium | General |
| medium | 1x | **Balanced** | **Default** |
| slow | 0.5x | High | Quality focus |
| slower | 0.3x | Higher | Final render |
| veryslow | 0.1x | Highest | Archival |

### 6. Resolution & Scaling

```bash
# Scale to 1080p (maintain aspect ratio)
-vf "scale=1920:-2"

# Scale to 720p
-vf "scale=-2:720"

# Fit within bounds
-vf "scale='min(1920,iw)':'min(1080,ih)':force_original_aspect_ratio=decrease"
```

### 7. Verify Output

```bash
# Compare before/after
ffprobe -v error -show_entries format=duration,size,bit_rate -of default=noprint_wrappers=1 INPUT
ffprobe -v error -show_entries format=duration,size,bit_rate -of default=noprint_wrappers=1 OUTPUT

# Check for errors
ffmpeg -v error -i OUTPUT -f null - && echo "Valid" || echo "Error"
```

## Output

Provide:
1. Complete FFmpeg command with explanation of each option
2. Expected output size estimate
3. Encoding time estimate based on preset
4. Compatibility notes for target use case
5. Alternative commands for different quality/speed tradeoffs
6. Verification commands
