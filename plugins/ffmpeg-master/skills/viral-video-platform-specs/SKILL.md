---
name: viral-video-platform-specs
description: Complete platform upload specifications for viral video creation across TikTok, YouTube Shorts, Instagram Reels, Facebook Reels, Snapchat Spotlight, and Twitter/X. PROACTIVELY activate for: (1) Platform-specific video encoding, (2) Upload requirements lookup, (3) Multi-platform export, (4) File size optimization, (5) Aspect ratio conversion, (6) Duration limits, (7) Audio requirements, (8) Caption/subtitle specs, (9) Thumbnail requirements, (10) Quality vs compatibility trade-offs. Provides: Comprehensive spec tables, FFmpeg presets per platform, optimal encoding settings, file size calculators, batch export workflows, and 2025-2026 platform-specific algorithm insights.
---

## CRITICAL GUIDELINES

### Windows File Path Requirements

**MANDATORY: Always Use Backslashes on Windows for File Paths**

When using Edit or Write tools on Windows, you MUST use backslashes (`\`) in file paths, NOT forward slashes (`/`).

### Documentation Guidelines

**NEVER create new documentation files unless explicitly requested by the user.**

---

# Viral Video Platform Specifications (2025-2026)

Complete reference for all major short-form video platforms with FFmpeg encoding presets.

## Quick Reference Table

| Platform | Aspect | Resolution | Max Duration | Max Size | Codec | Audio |
|----------|--------|------------|--------------|----------|-------|-------|
| **TikTok** | 9:16 | 1080x1920 | 10 min | 287 MB | H.264 | AAC 128k |
| **YouTube Shorts** | 9:16 | 1080x1920 | 60 sec | 256 GB | H.264/VP9 | AAC 192k |
| **Instagram Reels** | 9:16 | 1080x1920 | 90 sec | 4 GB | H.264 | AAC 128k |
| **Facebook Reels** | 9:16 | 1080x1920 | 90 sec | 4 GB | H.264 | AAC 128k |
| **Snapchat Spotlight** | 9:16 | 1080x1920 | 60 sec | 300 MB | H.264 | AAC |
| **Twitter/X** | 9:16 | 1080x1920 | 2 min 20 sec | 512 MB | H.264 | AAC 128k |
| **Pinterest Idea Pins** | 9:16 | 1080x1920 | 60 sec | 2 GB | H.264 | AAC |
| **LinkedIn** | 9:16/1:1 | 1080x1920 | 10 min | 5 GB | H.264 | AAC |

---

## TikTok Specifications

### Technical Requirements

| Specification | Requirement |
|---------------|-------------|
| **Aspect Ratio** | 9:16 (vertical) - **REQUIRED** |
| **Resolution** | 1080x1920 (recommended), min 720x1280 |
| **Video Codec** | H.264 (required) |
| **Audio Codec** | AAC |
| **Audio Bitrate** | 128 kbps recommended |
| **Audio Sample Rate** | 44100 Hz |
| **Frame Rate** | 24-60 fps (30 fps recommended) |
| **Pixel Format** | yuv420p (required) |
| **Max File Size** | 287 MB (iOS), 72 MB (Android web upload) |
| **Max Duration** | 10 minutes |
| **Optimal Duration** | 15-60 seconds |
| **Min Duration** | 3 seconds |

### FFmpeg Preset

```bash
# TikTok optimized encoding
ffmpeg -i input.mp4 \
  -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black,setsar=1" \
  -c:v libx264 -preset fast -crf 23 -profile:v high -level 4.1 \
  -c:a aac -b:a 128k -ar 44100 -ac 2 \
  -pix_fmt yuv420p \
  -movflags +faststart \
  -max_muxing_queue_size 1024 \
  -t 60 \
  output_tiktok.mp4
```

### Algorithm Insights (2025-2026)

- **Hook Window**: 1.3 seconds to capture attention
- **Optimal Length**: 21-34 seconds for highest completion
- **Captions**: 80% boost in engagement when visible
- **Trending Audio**: 88% say it helps discoverability
- **Post Frequency**: 1-3x daily for growth phase

---

## YouTube Shorts Specifications

### Technical Requirements

| Specification | Requirement |
|---------------|-------------|
| **Aspect Ratio** | 9:16 (vertical) - **REQUIRED** for Shorts |
| **Resolution** | 1080x1920 (recommended), min 1920px on short side |
| **Video Codec** | H.264, VP9, HEVC (VP9 preferred) |
| **Audio Codec** | AAC, Opus (Opus for VP9) |
| **Audio Bitrate** | 192 kbps recommended |
| **Audio Sample Rate** | 48000 Hz preferred |
| **Frame Rate** | 24-60 fps (30 fps recommended) |
| **Pixel Format** | yuv420p, yuv420p10le (HDR) |
| **Max File Size** | 256 GB (practical: 500 MB) |
| **Max Duration** | 60 seconds (HARD LIMIT) |
| **Optimal Duration** | 50-60 seconds |
| **Min Duration** | ~15 seconds recommended |

### FFmpeg Preset (H.264)

```bash
# YouTube Shorts H.264 encoding
ffmpeg -i input.mp4 \
  -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black,setsar=1" \
  -c:v libx264 -preset slow -crf 20 -profile:v high -level 4.2 \
  -c:a aac -b:a 192k -ar 48000 -ac 2 \
  -pix_fmt yuv420p \
  -movflags +faststart \
  -max_muxing_queue_size 1024 \
  -t 59 \
  -metadata comment="#Shorts" \
  output_shorts.mp4
```

### FFmpeg Preset (VP9 - Higher Quality)

```bash
# YouTube Shorts VP9 encoding (preferred by YouTube)
ffmpeg -i input.mp4 \
  -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black,setsar=1" \
  -c:v libvpx-vp9 -crf 25 -b:v 0 -deadline good -cpu-used 2 \
  -c:a libopus -b:a 192k -ar 48000 \
  -row-mt 1 \
  -t 59 \
  output_shorts.webm
```

### Algorithm Insights (2025-2026)

- **Completion Rate**: 80-90% = algorithm boost
- **Optimal Length**: 50-60 seconds maximizes watch time
- **First 3 Seconds**: Critical for retention
- **Consistency**: Daily posting recommended for growth
- **Thumbnail**: Custom thumbnails increase CTR 30%+

---

## Instagram Reels Specifications

### Technical Requirements

| Specification | Requirement |
|---------------|-------------|
| **Aspect Ratio** | 9:16 (preferred), 4:5, 1:1 accepted |
| **Resolution** | 1080x1920 (recommended), min 720p |
| **Video Codec** | H.264 |
| **Audio Codec** | AAC |
| **Audio Bitrate** | 128 kbps |
| **Audio Sample Rate** | 44100 Hz |
| **Frame Rate** | 30 fps recommended (max 60) |
| **Pixel Format** | yuv420p |
| **Max File Size** | 4 GB |
| **Max Duration** | 90 seconds |
| **Optimal Duration** | 7-30 seconds (sweet spot) |
| **Cover Image** | 1080x1920, JPEG |

### FFmpeg Preset

```bash
# Instagram Reels optimized encoding
ffmpeg -i input.mp4 \
  -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black,setsar=1,fps=30" \
  -c:v libx264 -preset fast -crf 23 -profile:v high -level 4.1 \
  -c:a aac -b:a 128k -ar 44100 -ac 2 \
  -pix_fmt yuv420p \
  -movflags +faststart \
  -t 90 \
  output_reels.mp4
```

### Algorithm Insights (2025-2026)

- **Optimal Length**: 7-15 seconds for casual, 15-30 for tutorial
- **First 3 Seconds**: Must hook immediately
- **Trending Audio**: Significant boost in reach
- **Hashtags**: 3-5 relevant hashtags optimal
- **Post Time**: When followers most active

---

## Facebook Reels Specifications

### Technical Requirements

| Specification | Requirement |
|---------------|-------------|
| **Aspect Ratio** | 9:16 (required for Reels) |
| **Resolution** | 1080x1920 (minimum 1080p) |
| **Video Codec** | H.264, H.265 |
| **Audio Codec** | AAC |
| **Audio Bitrate** | 128 kbps |
| **Audio Sample Rate** | 44100 Hz |
| **Frame Rate** | 24-60 fps |
| **Pixel Format** | yuv420p |
| **Max File Size** | 4 GB |
| **Max Duration** | 90 seconds |
| **Optimal Duration** | 15-30 seconds |

### FFmpeg Preset

```bash
# Facebook Reels optimized encoding
ffmpeg -i input.mp4 \
  -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black,setsar=1" \
  -c:v libx264 -preset fast -crf 23 -profile:v high -level 4.1 \
  -c:a aac -b:a 128k -ar 44100 -ac 2 \
  -pix_fmt yuv420p \
  -movflags +faststart \
  -t 90 \
  output_fb_reels.mp4
```

### Algorithm Insights (2025-2026)

- **Cross-Post**: Instagram Reels can be shared to Facebook
- **Original Content**: Watermark-free content preferred
- **Engagement**: Comments boost reach significantly
- **Optimal Length**: 15-30 seconds

---

## Snapchat Spotlight Specifications

### Technical Requirements

| Specification | Requirement |
|---------------|-------------|
| **Aspect Ratio** | 9:16 (required) |
| **Resolution** | 1080x1920 |
| **Video Codec** | H.264 |
| **Audio Codec** | AAC |
| **Frame Rate** | 24-30 fps |
| **Pixel Format** | yuv420p |
| **Max File Size** | 300 MB |
| **Max Duration** | 60 seconds |
| **Min Duration** | 5 seconds |

### FFmpeg Preset

```bash
# Snapchat Spotlight optimized encoding
ffmpeg -i input.mp4 \
  -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black,setsar=1,fps=30" \
  -c:v libx264 -preset fast -crf 24 -profile:v main -level 4.0 \
  -c:a aac -b:a 128k -ar 44100 -ac 2 \
  -pix_fmt yuv420p \
  -movflags +faststart \
  -fs 300M \
  -t 60 \
  output_spotlight.mp4
```

---

## Twitter/X Video Specifications

### Technical Requirements

| Specification | Requirement |
|---------------|-------------|
| **Aspect Ratio** | 9:16, 16:9, 1:1 |
| **Resolution** | 1080x1920 (9:16), 1920x1080 (16:9) |
| **Video Codec** | H.264 |
| **Audio Codec** | AAC |
| **Audio Bitrate** | 128 kbps |
| **Audio Sample Rate** | 44100 Hz |
| **Frame Rate** | 30-60 fps (40 max for 1080p) |
| **Pixel Format** | yuv420p |
| **Max File Size** | 512 MB |
| **Max Duration** | 2 min 20 sec (140 seconds) |

### FFmpeg Preset

```bash
# Twitter/X optimized encoding
ffmpeg -i input.mp4 \
  -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black,setsar=1,fps=30" \
  -c:v libx264 -preset fast -crf 23 -profile:v high -level 4.1 \
  -c:a aac -b:a 128k -ar 44100 -ac 2 \
  -pix_fmt yuv420p \
  -movflags +faststart \
  -fs 512M \
  -t 140 \
  output_twitter.mp4
```

---

## Multi-Platform Export Script

```bash
#!/bin/bash
# export_all_platforms.sh - Export video for all platforms at once

INPUT="$1"
BASENAME=$(basename "$INPUT" .mp4)

echo "Exporting $INPUT for all platforms..."

# TikTok
ffmpeg -i "$INPUT" \
  -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black" \
  -c:v libx264 -preset fast -crf 23 \
  -c:a aac -b:a 128k -ar 44100 \
  -pix_fmt yuv420p -movflags +faststart \
  -t 60 \
  "${BASENAME}_tiktok.mp4" &

# YouTube Shorts
ffmpeg -i "$INPUT" \
  -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black" \
  -c:v libx264 -preset fast -crf 22 \
  -c:a aac -b:a 192k -ar 48000 \
  -pix_fmt yuv420p -movflags +faststart \
  -t 59 \
  "${BASENAME}_shorts.mp4" &

# Instagram Reels
ffmpeg -i "$INPUT" \
  -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black,fps=30" \
  -c:v libx264 -preset fast -crf 23 \
  -c:a aac -b:a 128k -ar 44100 \
  -pix_fmt yuv420p -movflags +faststart \
  -t 90 \
  "${BASENAME}_reels.mp4" &

# Snapchat Spotlight
ffmpeg -i "$INPUT" \
  -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black,fps=30" \
  -c:v libx264 -preset fast -crf 24 \
  -c:a aac -b:a 128k -ar 44100 \
  -pix_fmt yuv420p -movflags +faststart \
  -fs 300M -t 60 \
  "${BASENAME}_spotlight.mp4" &

# Twitter/X
ffmpeg -i "$INPUT" \
  -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black,fps=30" \
  -c:v libx264 -preset fast -crf 23 \
  -c:a aac -b:a 128k -ar 44100 \
  -pix_fmt yuv420p -movflags +faststart \
  -t 140 \
  "${BASENAME}_twitter.mp4" &

wait
echo "All platform exports complete!"
ls -lh "${BASENAME}_*.mp4"
```

---

## File Size Optimization

### Calculate Target Bitrate for File Size

```bash
# Formula: bitrate = (target_size_MB * 8192) / duration_seconds - audio_bitrate

# Example: 50MB file, 60 seconds, 128kbps audio
# Video bitrate = (50 * 8192) / 60 - 128 = 6697 kbps

ffmpeg -i input.mp4 \
  -vf "scale=1080:1920" \
  -c:v libx264 -b:v 6500k -maxrate 7000k -bufsize 14000k \
  -c:a aac -b:a 128k \
  -pix_fmt yuv420p -movflags +faststart \
  output_sized.mp4
```

### Two-Pass Encoding for Exact Size

```bash
# Pass 1
ffmpeg -y -i input.mp4 \
  -vf "scale=1080:1920" \
  -c:v libx264 -b:v 6500k -pass 1 -an -f null /dev/null

# Pass 2
ffmpeg -i input.mp4 \
  -vf "scale=1080:1920" \
  -c:v libx264 -b:v 6500k -pass 2 \
  -c:a aac -b:a 128k \
  -movflags +faststart \
  output_2pass.mp4
```

---

## Platform Comparison: Algorithm Factors

| Factor | TikTok | Shorts | Reels | Priority |
|--------|--------|--------|-------|----------|
| **Hook (1-3s)** | Critical | Critical | Critical | #1 |
| **Completion Rate** | High | Highest | High | #1 |
| **Watch Time** | High | Highest | Medium | #2 |
| **Shares** | High | Medium | High | #3 |
| **Comments** | High | Medium | High | #3 |
| **Saves** | Medium | Medium | High | #4 |
| **Likes** | Medium | Low | Medium | #5 |
| **Captions** | 80% boost | Helpful | Important | Must-have |
| **Trending Audio** | Essential | N/A | Important | Platform-specific |
| **Original Content** | Preferred | Required | Preferred | Important |
| **Posting Frequency** | 1-3x/day | Daily | Daily | Consistency |

---

## Verification Commands

```bash
# Verify platform compliance
verify_platform() {
    local file=$1
    echo "=== Checking: $file ==="
    ffprobe -v error -select_streams v:0 \
      -show_entries stream=width,height,codec_name,pix_fmt,r_frame_rate,bit_rate \
      -show_entries format=duration,size,bit_rate \
      -of default=noprint_wrappers=1 "$file"

    # File size in MB
    size_mb=$(ls -l "$file" | awk '{print $5/1024/1024}')
    echo "File Size: ${size_mb}MB"
}

verify_platform output_tiktok.mp4
```

---

## Related Skills

- `ffmpeg-viral-tiktok` - TikTok-specific viral optimization
- `ffmpeg-viral-shorts` - YouTube Shorts optimization
- `viral-video-hook-templates` - 10 proven hook patterns
- `viral-video-animated-captions` - CapCut-style captions
