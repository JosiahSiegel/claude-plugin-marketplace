---
name: YouTube Shorts Viral Video
description: Create YouTube Shorts-optimized viral video with 9:16 aspect ratio, auto-captions, retention optimization, and thumbnail extraction
argument-hint: <input-file> [--caption] [--thumbnail-time] [--output]
---

## CRITICAL GUIDELINES

### Windows File Path Requirements

**MANDATORY: Always Use Backslashes on Windows for File Paths**

When using Edit or Write tools on Windows, you MUST use backslashes (`\`) in file paths, NOT forward slashes (`/`).

---

# YouTube Shorts Viral Video Creator

## Purpose

Transform any video into a YouTube Shorts-optimized viral format with:
- **9:16 vertical aspect ratio** (1080x1920)
- **Auto-generated captions** with engaging styling
- **Optimal duration** (50-60 seconds for max retention)
- **Thumbnail extraction** for custom cover selection
- **YouTube-compliant encoding** (VP9/H.264, HDR support)
- **Loop-friendly endings** for increased watch time

## Quick Start

### Basic Shorts Conversion

```bash
# Simple conversion to YouTube Shorts format
ffmpeg -i input.mp4 \
  -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black,setsar=1" \
  -c:v libx264 -preset fast -crf 22 \
  -c:a aac -b:a 192k -ar 48000 \
  -pix_fmt yuv420p \
  -movflags +faststart \
  -t 59 \
  output_shorts.mp4
```

## Complete YouTube Shorts Workflow

### Step 1: Analyze Input

```bash
# Check source video properties
ffprobe -v quiet -print_format json -show_format -show_streams input.mp4
```

Key metrics:
- Duration (Shorts max: 60s, optimal: 50-60s)
- Resolution (need 9:16 vertical)
- Audio quality (YouTube supports higher bitrate than TikTok)

### Step 2: Create 9:16 Vertical Format

#### From Horizontal (16:9) Video - Smart Cropping

```bash
# Option A: Intelligent center crop with face detection zone
ffmpeg -i horizontal.mp4 \
  -vf "crop=ih*9/16:ih:(iw-ih*9/16)/2:0,scale=1080:1920" \
  -c:v libx264 -preset fast -crf 22 \
  -c:a aac -b:a 192k \
  -pix_fmt yuv420p -movflags +faststart \
  output_shorts.mp4

# Option B: Cinematic letterbox with gradient bars
ffmpeg -i horizontal.mp4 \
  -filter_complex "
    [0:v]scale=1080:-2[main];
    color=c=black:s=1080x1920:d=1[bg];
    [bg][main]overlay=0:(H-h)/2:shortest=1,
    drawbox=x=0:y=0:w=1080:h=300:c=black@0.7:t=fill,
    drawbox=x=0:y=1620:w=1080:h=300:c=black@0.7:t=fill
  " \
  -c:v libx264 -preset fast -crf 22 \
  -c:a aac -b:a 192k \
  -pix_fmt yuv420p -movflags +faststart \
  output_shorts.mp4

# Option C: Picture-in-picture with blurred background
ffmpeg -i horizontal.mp4 \
  -filter_complex "
    [0:v]scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,boxblur=25:25[bg];
    [0:v]scale=1080:-2[fg];
    [bg][fg]overlay=0:(H-h)/2
  " \
  -c:v libx264 -preset fast -crf 22 \
  -c:a aac -b:a 192k \
  -pix_fmt yuv420p -movflags +faststart \
  output_shorts.mp4
```

#### From Long-Form YouTube Video (Clip Extraction)

```bash
# Extract viral clip from longer video
ffmpeg -i long_video.mp4 \
  -ss 00:05:30 -t 00:00:58 \
  -vf "crop=ih*9/16:ih,scale=1080:1920" \
  -c:v libx264 -preset fast -crf 22 \
  -c:a aac -b:a 192k \
  -pix_fmt yuv420p -movflags +faststart \
  shorts_clip.mp4
```

### Step 3: Optimize Duration for Algorithm

YouTube Shorts algorithm favors videos that are watched to completion.

```bash
# Trim to optimal 50-58 second range
ffmpeg -i input.mp4 \
  -ss 00:00:00 -t 00:00:55 \
  -c:v libx264 -preset fast -crf 22 \
  -c:a aac -b:a 192k \
  -pix_fmt yuv420p -movflags +faststart \
  output_optimal_length.mp4
```

### Step 4: Add Captions for Retention

#### Auto-Generate with Whisper (FFmpeg 8.0+)

```bash
# Generate captions (FFmpeg 8.0+ with Whisper)
ffmpeg -i input.mp4 -vn \
  -af "whisper=model=ggml-medium.bin:language=auto:format=srt" \
  captions.srt

# Burn captions with YouTube-optimized style
ffmpeg -i shorts_base.mp4 \
  -vf "subtitles=captions.srt:force_style='FontName=Montserrat,FontSize=52,PrimaryColour=&HFFFFFF,OutlineColour=&H000000,BackColour=&H40000000,Outline=3,Shadow=2,Bold=1,Alignment=2,MarginV=250'" \
  -c:v libx264 -preset fast -crf 22 \
  -c:a copy \
  shorts_with_captions.mp4
```

#### Caption Styles for Different Content Types

```bash
# Gaming/Energetic style
-vf "subtitles=caps.srt:force_style='FontName=Impact,FontSize=56,PrimaryColour=&H00FFFF,OutlineColour=&H000000,Outline=4,Bold=1,Alignment=2,MarginV=200'"

# Educational/Professional style
-vf "subtitles=caps.srt:force_style='FontName=Roboto,FontSize=44,PrimaryColour=&HFFFFFF,OutlineColour=&H333333,Outline=2,Shadow=1,Alignment=2,MarginV=280'"

# Storytelling/Dramatic style
-vf "subtitles=caps.srt:force_style='FontName=Georgia,FontSize=48,PrimaryColour=&HFFD700,OutlineColour=&H000000,Outline=3,Italic=1,Alignment=2,MarginV=240'"
```

### Step 5: Add Hook Elements

#### Opening Text Hook (First 2 Seconds)

```bash
# Curiosity gap hook
ffmpeg -i input.mp4 \
  -vf "drawtext=text='This changed everything...':fontsize=60:fontcolor=white:borderw=4:bordercolor=black:x=(w-tw)/2:y=h*0.15:enable='between(t,0,2.5)',drawtext=text='Watch till the end':fontsize=36:fontcolor=yellow:borderw=2:bordercolor=black:x=(w-tw)/2:y=h*0.22:enable='between(t,0,2.5)'" \
  -c:v libx264 -preset fast -crf 22 \
  -c:a copy \
  output_with_hook.mp4
```

#### Visual Pattern Interrupt

```bash
# Flash/brightness pulse at start
ffmpeg -i input.mp4 \
  -vf "eq=brightness=0.1*sin(t*12)*between(t,0,0.5)" \
  -c:v libx264 -preset fast -crf 22 \
  -c:a copy \
  output_flash_hook.mp4
```

### Step 6: Create Loop-Friendly Ending

```bash
# Crossfade last 1 second with first 1 second for smooth loop
ffmpeg -i input.mp4 \
  -filter_complex "
    [0:v]trim=0:1,setpts=PTS-STARTPTS[start];
    [0:v]trim=54:55,setpts=PTS-STARTPTS[end];
    [end][start]xfade=transition=fade:duration=0.5:offset=0.5[loop];
    [0:v]trim=0:54,setpts=PTS-STARTPTS[main];
    [main][loop]concat=n=2:v=1:a=0
  " \
  -c:v libx264 -preset fast -crf 22 \
  output_looped.mp4
```

### Step 7: Extract Thumbnails

```bash
# Extract multiple thumbnail options
ffmpeg -i output_shorts.mp4 -vf "select='eq(n,0)+eq(n,60)+eq(n,120)+eq(n,180)'" -vsync vfr thumbnail_%02d.jpg

# Extract at specific timestamp with text overlay
ffmpeg -i output_shorts.mp4 -ss 00:00:15 -vframes 1 \
  -vf "drawtext=text='YOUR TITLE':fontsize=72:fontcolor=white:borderw=5:bordercolor=black:x=(w-tw)/2:y=h*0.4" \
  thumbnail_with_text.jpg

# High-quality thumbnail
ffmpeg -i output_shorts.mp4 -ss 00:00:10 -vframes 1 \
  -q:v 2 \
  thumbnail_hq.jpg
```

### Step 8: Encode for Quality

#### Standard Quality (H.264)

```bash
ffmpeg -i input.mp4 \
  -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black" \
  -c:v libx264 -preset slow -crf 20 \
  -c:a aac -b:a 192k -ar 48000 \
  -pix_fmt yuv420p \
  -movflags +faststart \
  output_hq.mp4
```

#### Premium Quality (VP9 - YouTube's Preferred)

```bash
ffmpeg -i input.mp4 \
  -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black" \
  -c:v libvpx-vp9 -crf 25 -b:v 0 -deadline good \
  -c:a libopus -b:a 192k \
  -row-mt 1 \
  output_vp9.webm
```

#### HDR Content (If Source is HDR)

```bash
ffmpeg -i hdr_input.mp4 \
  -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black" \
  -c:v libx265 -preset slow -crf 22 \
  -tag:v hvc1 \
  -color_primaries bt2020 -color_trc smpte2084 -colorspace bt2020nc \
  -c:a aac -b:a 192k \
  output_hdr.mp4
```

## Complete One-Command Preset

```bash
# Full YouTube Shorts optimization pipeline
ffmpeg -i input.mp4 \
  -filter_complex "
    [0:v]scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black[v1];
    [v1]drawtext=text='YOUR HOOK':fontsize=56:fontcolor=white:borderw=4:bordercolor=black:x=(w-tw)/2:y=h*0.12:enable='between(t,0,2.5)'[v2];
    [0:a]loudnorm=I=-14:TP=-1.5:LRA=11[a]
  " \
  -map "[v2]" -map "[a]" \
  -c:v libx264 -preset fast -crf 22 \
  -c:a aac -b:a 192k -ar 48000 \
  -pix_fmt yuv420p \
  -movflags +faststart \
  -t 59 \
  -metadata title="Your Shorts Title" \
  -metadata comment="#Shorts" \
  output_shorts_final.mp4
```

## YouTube Shorts Technical Requirements (2025-2026)

| Specification | Requirement | Optimal Value |
|---------------|-------------|---------------|
| **Aspect Ratio** | 9:16 (vertical) | Required for Shorts shelf |
| **Resolution** | 1080x1920 (recommended) | 1080x1920 (limited to 1080p playback) |
| **Video Codec** | H.264, VP9, HEVC | H.264 (compatibility), VP9 (quality) |
| **Audio Codec** | AAC, Opus | AAC-LC (most compatible) |
| **Audio Bitrate** | 192-384 kbps | 192 kbps minimum, 384 kbps YouTube recommendation |
| **Audio Loudness** | -13 to -15 LUFS | -14 LUFS (YouTube normalizes to this) |
| **True Peak** | -1 to -3 dB | -1.5 dBTP recommended |
| **Frame Rate** | 24-60 fps | 30 fps (upload at source frame rate) |
| **Bitrate (1080p30)** | 8 Mbps | 8 Mbps (YouTube official) |
| **Bitrate (1080p60)** | 12 Mbps | 12 Mbps |
| **CRF (H.264)** | 18-23 | CRF 20 (high quality), CRF 22 (standard) |
| **Preset** | slow, medium, fast | slow (best quality for uploads) |
| **Max File Size** | 256 GB | Practical: 20-100 MB for Shorts |
| **Max Duration** | 60 seconds (HARD LIMIT) | Strict enforcement |
| **Optimal Duration** | 50-60 seconds | Maximizes watch time metric |
| **Min Duration** | ~15 seconds recommended | Shorter = harder to rank |
| **Pixel Format** | yuv420p (SDR) | yuv420p10le for HDR |
| **Color Space** | Rec.709 (SDR) | Rec.2100 for HDR only |
| **Audio Sample Rate** | 48000 Hz preferred | YouTube production standard |

## Algorithm Optimization Tips

### Duration Strategy

| Length | Performance |
|--------|-------------|
| 15-30s | Good for simple concepts, high completion |
| 30-45s | Balanced, good for tutorials |
| **50-60s** | **Algorithm favorite**, max watch time |

### Retention Techniques

```bash
# Add progress bar (increases completion rate)
ffmpeg -i input.mp4 \
  -vf "drawbox=x=0:y=1900:w='(t/60)*1080':h=20:c=red:t=fill" \
  -c:v libx264 -preset fast -crf 22 \
  -c:a copy \
  output_with_progress.mp4

# Subtle continuous zoom - 0.15%/sec for YouTube (larger screens need more movement)
# YouTube Shorts viewers often watch on TVs, requiring 1.5x TikTok's zoom rate
ffmpeg -i input.mp4 \
  -vf "zoompan=z='1+0.0015*t':d=1:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s=1080x1920" \
  -c:v libx264 -preset fast -crf 22 \
  output_slow_zoom.mp4
```

### Audio Optimization (2025-2026 Research)

**YouTube Shorts Audio Targets**:
- **Loudness**: -13 to -15 LUFS (YouTube normalizes to -14 LUFS)
- **True Peak**: -1 to -3 dBTP (recommended: -1.5 dBTP)
- **Strategy**: Upload at -14 LUFS for minimal platform processing

```bash
# Normalize audio for YouTube Shorts - -14 LUFS target
ffmpeg -i input.mp4 \
  -af "loudnorm=I=-14:TP=-1.5:LRA=11" \
  -c:v copy \
  output_normalized_shorts.mp4

# Voice clarity with YouTube-optimized loudness
ffmpeg -i input.mp4 \
  -af "highpass=f=80,lowpass=f=12000,compand=attacks=0:points=-80/-900|-45/-15|-27/-9|0/-7|20/-7:gain=3,loudnorm=I=-14:TP=-1.5" \
  -c:v copy \
  output_voice_optimized.mp4
```

### End Screen Call-to-Action

```bash
# Add subscribe reminder in last 5 seconds
ffmpeg -i input.mp4 \
  -vf "drawtext=text='SUBSCRIBE':fontsize=48:fontcolor=red:borderw=3:bordercolor=white:x=(w-tw)/2:y=h*0.85:enable='gte(t,55)'" \
  -c:v libx264 -preset fast -crf 22 \
  -c:a copy \
  output_with_cta.mp4
```

## Batch Processing for Content Repurposing

```bash
#!/bin/bash
# batch_shorts.sh - Convert multiple clips to Shorts format

for input in *.mp4; do
    output="shorts_${input}"

    # Get duration
    duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$input")

    # Cap at 59 seconds
    if (( $(echo "$duration > 59" | bc -l) )); then
        trim="-t 59"
    else
        trim=""
    fi

    ffmpeg -i "$input" \
      -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black" \
      -c:v libx264 -preset fast -crf 22 \
      -c:a aac -b:a 192k \
      -pix_fmt yuv420p -movflags +faststart \
      $trim \
      "$output"

    # Extract thumbnail
    ffmpeg -i "$output" -ss 00:00:05 -vframes 1 "thumb_${input%.mp4}.jpg"
done
```

## Output Verification

```bash
# Verify Shorts compliance
ffprobe -v error -select_streams v:0 \
  -show_entries stream=width,height,codec_name,pix_fmt,r_frame_rate \
  -show_entries format=duration \
  -of csv=p=0 output_shorts.mp4

# Expected: 1080,1920,h264,yuv420p,30/1 and duration < 60

# Check file integrity
ffmpeg -v error -i output_shorts.mp4 -f null - && echo "Valid" || echo "Error"
```

## Related Skills

- `viral-video-platform-specs` - All platform upload requirements
- `viral-video-hook-templates` - 10 proven hook patterns
- `viral-video-animated-captions` - CapCut-style word highlighting
- `ffmpeg-captions-subtitles` - Full caption system
