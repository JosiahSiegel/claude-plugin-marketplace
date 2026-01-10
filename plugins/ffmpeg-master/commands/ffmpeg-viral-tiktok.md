---
name: TikTok Viral Video
description: Create TikTok-optimized viral video with 9:16 aspect ratio, auto-captions, hook optimization, and platform-specific encoding
argument-hint: <input-file> [--caption] [--hook-style] [--output]
---

## CRITICAL GUIDELINES

### Windows File Path Requirements

**MANDATORY: Always Use Backslashes on Windows for File Paths**

When using Edit or Write tools on Windows, you MUST use backslashes (`\`) in file paths, NOT forward slashes (`/`).

---

# TikTok Viral Video Creator

## Purpose

Transform any video into a TikTok-optimized viral format with:
- **9:16 vertical aspect ratio** (1080x1920)
- **Auto-generated captions** with CapCut-style word highlighting
- **Hook optimization** for the critical first 1-3 seconds
- **Platform-compliant encoding** (H.264, yuv420p, max 287MB)
- **Optimal duration** guidance (15-60 seconds sweet spot)

## Quick Start

### Basic TikTok Conversion

```bash
# Simple conversion to TikTok format
ffmpeg -i input.mp4 \
  -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black,setsar=1" \
  -c:v libx264 -preset fast -crf 23 \
  -c:a aac -b:a 128k -ar 44100 \
  -pix_fmt yuv420p \
  -movflags +faststart \
  -t 60 \
  output_tiktok.mp4
```

## Complete TikTok Workflow

### Step 1: Analyze Input

```bash
# Check source video properties
ffprobe -v quiet -print_format json -show_format -show_streams input.mp4
```

Key metrics to evaluate:
- Duration (TikTok optimal: 15-60s, max 10 min)
- Resolution (need to crop/scale for 9:16)
- Audio quality (TikTok requires good audio)

### Step 2: Create 9:16 Vertical Format

#### From Horizontal (16:9) Video

```bash
# Option A: Center crop (best for talking head/single subject)
ffmpeg -i horizontal.mp4 \
  -vf "crop=ih*9/16:ih,scale=1080:1920" \
  -c:v libx264 -preset fast -crf 23 \
  -c:a aac -b:a 128k \
  -pix_fmt yuv420p -movflags +faststart \
  output_tiktok.mp4

# Option B: Letterbox with blur background (preserves full frame)
ffmpeg -i horizontal.mp4 \
  -filter_complex "[0:v]scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2[fg];[0:v]scale=1080:1920,boxblur=20:20[bg];[bg][fg]overlay=(W-w)/2:(H-h)/2" \
  -c:v libx264 -preset fast -crf 23 \
  -c:a aac -b:a 128k \
  -pix_fmt yuv420p -movflags +faststart \
  output_tiktok.mp4

# Option C: Split screen (original top + zoomed bottom)
ffmpeg -i horizontal.mp4 \
  -filter_complex "[0:v]scale=1080:-2[top];[0:v]crop=ih*9/16:ih,scale=1080:-2[bottom];[top][bottom]vstack=inputs=2,scale=1080:1920" \
  -c:v libx264 -preset fast -crf 23 \
  -c:a aac -b:a 128k \
  -pix_fmt yuv420p -movflags +faststart \
  output_tiktok.mp4
```

#### From Square (1:1) Video

```bash
# Extend vertically with blur background
ffmpeg -i square.mp4 \
  -filter_complex "[0:v]scale=1080:1080[fg];[0:v]scale=1080:1920,boxblur=15:15[bg];[bg][fg]overlay=0:(H-h)/2" \
  -c:v libx264 -preset fast -crf 23 \
  -c:a aac -b:a 128k \
  -pix_fmt yuv420p -movflags +faststart \
  output_tiktok.mp4
```

### Step 3: Add Viral Captions

#### Auto-Generate Captions with Whisper (FFmpeg 8.0+)

```bash
# Generate SRT from video (FFmpeg 8.0+ with Whisper)
ffmpeg -i input.mp4 -vn \
  -af "whisper=model=ggml-base.bin:language=auto:format=srt" \
  captions.srt

# Burn captions with TikTok-style appearance
ffmpeg -i input_tiktok.mp4 \
  -vf "subtitles=captions.srt:force_style='FontName=Arial Black,FontSize=48,PrimaryColour=&HFFFFFF,OutlineColour=&H000000,Outline=4,Shadow=0,Bold=1,Alignment=2,MarginV=200'" \
  -c:v libx264 -preset fast -crf 23 \
  -c:a copy \
  output_with_captions.mp4
```

#### Animated Word-by-Word Captions (CapCut Style)

See the `viral-video-animated-captions` skill for advanced word-level highlighting similar to CapCut's auto-captions.

### Step 4: Add Hook Elements (First 1-3 Seconds)

#### Text Hook Overlay

```bash
# Add attention-grabbing text in first 3 seconds
ffmpeg -i input.mp4 \
  -vf "drawtext=text='WAIT FOR IT...':fontfile=/path/to/bold-font.ttf:fontsize=72:fontcolor=yellow:borderw=4:bordercolor=black:x=(w-tw)/2:y=h*0.15:enable='between(t,0,3)'" \
  -c:v libx264 -preset fast -crf 23 \
  -c:a copy \
  output_with_hook.mp4
```

#### Visual Hook Effects

```bash
# Zoom pulse effect - 60fps for smooth motion, optimized timing for 1.3s attention window
# 12% amplitude at ~1.3Hz (sin(t*8) = 8 rad/s) creates highly visible pulsing on mobile
ffmpeg -i input.mp4 \
  -vf "fps=60,zoompan=z='if(lt(t,1.5),1+0.12*sin(t*8),1)':d=1:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s=1080x1920" \
  -c:v libx264 -preset fast -crf 23 \
  -c:a aac -b:a 128k \
  output_hook_zoom.mp4
```

### Step 5: Optimize Duration

```bash
# Trim to optimal TikTok length (15-60s)
ffmpeg -i input.mp4 \
  -ss 00:00:00 -t 00:00:45 \
  -c:v libx264 -preset fast -crf 23 \
  -c:a aac -b:a 128k \
  -pix_fmt yuv420p -movflags +faststart \
  output_trimmed.mp4
```

### Step 6: Extract Cover Frame

```bash
# Extract thumbnail at peak moment (adjust time)
ffmpeg -i output_tiktok.mp4 -ss 00:00:03 -vframes 1 \
  -vf "scale=1080:1920" \
  cover_image.jpg
```

## Complete One-Command Preset

```bash
# Full TikTok optimization pipeline
ffmpeg -i input.mp4 \
  -filter_complex "
    [0:v]scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black[v1];
    [v1]drawtext=text='YOUR HOOK TEXT':fontsize=64:fontcolor=white:borderw=3:bordercolor=black:x=(w-tw)/2:y=h*0.12:enable='between(t,0,2.5)'[v2];
    [0:a]loudnorm=I=-16:TP=-1.5:LRA=11[a]
  " \
  -map "[v2]" -map "[a]" \
  -c:v libx264 -preset fast -crf 23 \
  -c:a aac -b:a 128k -ar 44100 \
  -pix_fmt yuv420p \
  -movflags +faststart \
  -t 60 \
  -metadata title="Your Video Title" \
  output_tiktok_final.mp4
```

## TikTok Technical Requirements (2025-2026)

| Specification | Requirement | Optimal Value |
|---------------|-------------|---------------|
| **Aspect Ratio** | 9:16 (vertical) | Required |
| **Resolution** | 1080x1920 (recommended) | 1080x1920 (TikTok compresses 4K) |
| **Video Codec** | H.264 (required) | H.264 High Profile, Level 4.1 |
| **Audio Codec** | AAC | AAC-LC, 192 kbps |
| **Audio Loudness** | -10 to -12 LUFS | -11 LUFS (mobile-optimized) |
| **True Peak** | -1.5 dBTP max | Prevents distortion |
| **Frame Rate** | 24-60 fps | 30 fps (60 fps for sports/action only) |
| **Bitrate (30fps)** | 6-8.5 Mbps | 7 Mbps VBR optimal |
| **CRF** | 21-23 | CRF 22 (best balance) |
| **Keyframe Interval** | 2-3 seconds | Every 60-90 frames at 30fps |
| **Max File Size** | 287 MB (iOS), 72 MB (Android web) | Target: <100 MB |
| **Max Duration** | 10 minutes | Optimal: 21-34 seconds |
| **Optimal Duration** | 21-34 seconds | Highest completion rate |
| **Pixel Format** | yuv420p | Required, Rec.709 |

## Viral Optimization Tips

### Hook Strategies (First 1-3 Seconds)

1. **Pattern Interrupt**: Unexpected visual/sound
2. **Curiosity Gap**: "You won't believe what happens..."
3. **Direct Address**: "Stop scrolling if you..."
4. **Controversy**: Bold claim or opinion
5. **Transformation**: Before/after tease

### Retention Boosters

```bash
# Add subtle zoom throughout video - 0.2%/sec is minimum perceptible on mobile
# Keeps viewers engaged with subconscious motion without being distracting
ffmpeg -i input.mp4 \
  -vf "zoompan=z='1+0.002*t':d=1:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s=1080x1920" \
  -c:v libx264 -preset fast -crf 23 \
  output_slow_zoom.mp4

# Add subtle shake/movement
ffmpeg -i input.mp4 \
  -vf "crop=1060:1900:(10+5*sin(t*8)):(10+5*cos(t*6)),scale=1080:1920" \
  -c:v libx264 -preset fast -crf 23 \
  output_subtle_shake.mp4
```

### Audio Optimization (2025-2026 Research)

**TikTok Audio Targets**:
- **Loudness**: -10 to -12 LUFS (louder wins on mobile speakers)
- **True Peak**: -1.5 dBTP maximum (prevent distortion)
- **Strategy**: Upload hotter than platform target for better mobile experience

```bash
# Normalize audio for TikTok - optimized for mobile playback
# -11 LUFS target: louder than YouTube (-14) but prevents over-compression
ffmpeg -i input.mp4 \
  -af "loudnorm=I=-11:TP=-1.5:LRA=11" \
  -c:v copy \
  output_normalized_tiktok.mp4

# Boost voice clarity with compression
ffmpeg -i input.mp4 \
  -af "highpass=f=100,lowpass=f=8000,compand=attacks=0:points=-80/-900|-45/-15|-27/-9|0/-7|20/-7:gain=5,loudnorm=I=-11:TP=-1.5" \
  -c:v copy \
  output_voice_boost.mp4

# Bass boost for music content
ffmpeg -i input.mp4 \
  -af "bass=g=6:f=100,loudnorm=I=-11:TP=-1.5:LRA=11" \
  -c:v copy \
  output_bass_boost.mp4
```

## Batch Processing

```bash
#!/bin/bash
# batch_tiktok.sh - Convert multiple videos to TikTok format

for input in *.mp4; do
    output="tiktok_${input}"
    ffmpeg -i "$input" \
      -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black" \
      -c:v libx264 -preset fast -crf 23 \
      -c:a aac -b:a 128k \
      -pix_fmt yuv420p -movflags +faststart \
      -t 60 \
      "$output"
done
```

## Output Checklist

Before uploading, verify:

```bash
# Verify TikTok compliance
ffprobe -v error -select_streams v:0 \
  -show_entries stream=width,height,codec_name,pix_fmt,r_frame_rate \
  -of csv=p=0 output_tiktok.mp4

# Expected: 1080,1920,h264,yuv420p,30/1

# Check file size (must be under 287MB)
ls -lh output_tiktok.mp4
```

## Related Skills

- `viral-video-platform-specs` - All platform upload requirements
- `viral-video-hook-templates` - 10 proven hook patterns
- `viral-video-animated-captions` - CapCut-style word highlighting
- `ffmpeg-captions-subtitles` - Full caption system
