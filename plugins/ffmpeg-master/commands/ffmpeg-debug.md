---
name: Debug FFmpeg
description: Debug FFmpeg issues - analyze errors, validate files, troubleshoot encoding problems
argument-hint: [file-or-error-message]
---

## CRITICAL GUIDELINES

### Windows File Path Requirements

**MANDATORY: Always Use Backslashes on Windows for File Paths**

When using Edit or Write tools on Windows, you MUST use backslashes (`\`) in file paths, NOT forward slashes (`/`).

---

# FFmpeg Debugging

## Purpose
Diagnose and resolve FFmpeg errors, validate media files, and troubleshoot encoding issues.

## Workflow

### 1. Validate Media File
```bash
# Check if file is valid
ffprobe -v error INPUT && echo "Valid" || echo "Invalid/Corrupt"

# Get detailed error info
ffprobe -v verbose INPUT 2>&1 | head -50

# Full validation (slow but thorough)
ffmpeg -v error -i INPUT -f null - && echo "Playable" || echo "Has errors"
```

### 2. Get Detailed File Info
```bash
# Comprehensive JSON info
ffprobe -v quiet -print_format json -show_format -show_streams INPUT

# Summary info
ffprobe -v error -show_entries format=duration,size,bit_rate:stream=codec_name,width,height,r_frame_rate -of default=noprint_wrappers=1 INPUT
```

### 3. Common Errors & Solutions

#### "Invalid data found when processing input"
```bash
# Try with error recovery
ffmpeg -err_detect ignore_err -i INPUT -c copy OUTPUT

# Force format detection
ffmpeg -f FORMAT -i INPUT -c copy OUTPUT
```

#### "No such file or directory"
```bash
# Check path (Windows Git Bash issue)
MSYS_NO_PATHCONV=1 ffmpeg -i INPUT OUTPUT

# Use quotes for paths with spaces
ffmpeg -i "path with spaces/file.mp4" output.mp4
```

#### "Avi/codec not found"
```bash
# Check available codecs
ffmpeg -encoders | grep -i CODEC_NAME
ffmpeg -decoders | grep -i CODEC_NAME

# Install missing codec or use alternative
ffmpeg -i INPUT -c:v libx264 OUTPUT.mp4
```

#### "Hardware acceleration failed"
```bash
# Check available hardware accelerators
ffmpeg -hwaccels

# Check GPU encoders
ffmpeg -encoders | grep nvenc
ffmpeg -encoders | grep qsv
ffmpeg -encoders | grep vaapi

# Fallback to software
ffmpeg -i INPUT -c:v libx264 OUTPUT.mp4
```

#### "Buffer overflow" / "Queue full"
```bash
# Increase buffer size
ffmpeg -thread_queue_size 1024 -i INPUT OUTPUT

# For streaming
ffmpeg -i INPUT -bufsize 10000k OUTPUT
```

### 4. Generate Debug Log
```bash
# Create detailed report
ffmpeg -report -i INPUT -c copy OUTPUT

# Or set log level
ffmpeg -v verbose -i INPUT OUTPUT 2>&1 | tee ffmpeg.log
```

### 5. Check FFmpeg Capabilities
```bash
# Version and build info
ffmpeg -version

# All encoders
ffmpeg -encoders

# All decoders
ffmpeg -decoders

# All formats
ffmpeg -formats

# All filters
ffmpeg -filters

# Specific encoder options
ffmpeg -h encoder=libx264
```

### 6. Test Commands
```bash
# Test input without processing
ffmpeg -i INPUT -t 5 -c copy /dev/null

# Generate test pattern
ffmpeg -f lavfi -i testsrc=size=1280x720:rate=30 -t 10 test.mp4

# Test encoding speed
ffmpeg -benchmark -i INPUT -c:v libx264 -f null -
```

### 7. Mobile Playback Debugging

Diagnose "video plays on desktop but not mobile" issues.

#### Check Codec Profile and Level
```bash
# Show video stream profile and level
ffprobe -v error -select_streams v:0 \
  -show_entries stream=codec_name,profile,level,pix_fmt,width,height \
  -of default=noprint_wrappers=1 INPUT

# Common output for mobile-incompatible video:
# profile=High 4:4:4 Predictive  <- FAILS on mobile
# level=51                        <- Too high for most mobile
# pix_fmt=yuv444p                 <- Not supported on mobile
```

#### Mobile Compatibility Checklist
```bash
# Run this diagnostic script to check mobile compatibility
check_mobile_compat() {
    local file="$1"
    echo "=== Mobile Compatibility Check: $file ==="

    # Get stream info
    PROFILE=$(ffprobe -v error -select_streams v:0 -show_entries stream=profile -of csv=p=0 "$file")
    LEVEL=$(ffprobe -v error -select_streams v:0 -show_entries stream=level -of csv=p=0 "$file")
    PIX_FMT=$(ffprobe -v error -select_streams v:0 -show_entries stream=pix_fmt -of csv=p=0 "$file")
    CODEC=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 "$file")
    AUDIO_CODEC=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of csv=p=0 "$file")

    echo "Video Codec: $CODEC"
    echo "Profile: $PROFILE"
    echo "Level: $LEVEL"
    echo "Pixel Format: $PIX_FMT"
    echo "Audio Codec: $AUDIO_CODEC"

    # Check for common mobile issues
    [[ "$PIX_FMT" != "yuv420p" ]] && echo "WARNING: Pixel format $PIX_FMT not supported on mobile (need yuv420p)"
    [[ "$LEVEL" -gt 41 ]] && echo "WARNING: Level $LEVEL may not play on older mobile devices (max 4.1 recommended)"
    [[ "$CODEC" == "hevc" ]] && echo "WARNING: HEVC/H.265 not universally supported on Android browsers"
    [[ "$AUDIO_CODEC" != "aac" ]] && echo "WARNING: Audio codec $AUDIO_CODEC may not be supported (use AAC)"

    # Check moov atom placement
    echo ""
    echo "Checking moov atom placement..."
    ffprobe -v trace "$file" 2>&1 | grep -E "moov|mdat" | head -4
    echo "(moov should appear BEFORE mdat for mobile streaming)"
}

check_mobile_compat INPUT
```

#### Common Mobile Incompatibilities

| Issue | Symptom | Diagnosis | Fix |
|-------|---------|-----------|-----|
| H.264 High profile on old Android | Black screen, no playback | `profile=High`, `level=51` | Re-encode with `-profile:v main -level 4.0` |
| Missing faststart | Long delay before playback | moov after mdat in trace | Add `-movflags +faststart` |
| Wrong pixel format | Green/purple video or no playback | `pix_fmt=yuv444p` or `yuv422p` | Add `-pix_fmt yuv420p` |
| HEVC on Android Chrome | Audio plays, no video | `codec_name=hevc` | Re-encode with `-c:v libx264` |
| High AAC profile | No audio on some devices | HE-AAC v2 | Use `-c:a aac -profile:a aac_low` |
| No moov atom | Video won't start on mobile data | moov at end of file | Run `-movflags +faststart` |

#### Verify Moov Atom Placement
```bash
# Check if moov atom is at the start (required for mobile streaming)
ffprobe -v trace INPUT 2>&1 | grep -E "type:'(moov|mdat)'" | head -4

# If moov appears AFTER mdat, fix it without re-encoding:
ffmpeg -i INPUT -c copy -movflags +faststart OUTPUT.mp4
```

#### iOS Safari-Specific Issues
```bash
# iOS Safari requires:
# 1. playsinline attribute in HTML (not an FFmpeg issue)
# 2. H.264 Baseline/Main/High profile (no High 4:4:4 Predictive)
# 3. yuv420p pixel format
# 4. AAC audio (not Opus, Vorbis, or AC-3)
# 5. Muted video for autoplay

# Fix video for iOS Safari compatibility
ffmpeg -i INPUT \
  -c:v libx264 -profile:v high -level 4.0 \
  -pix_fmt yuv420p \
  -c:a aac -b:a 128k -ar 44100 \
  -movflags +faststart \
  OUTPUT_ios.mp4
```

#### Android WebView Codec Limitations
```bash
# Android WebView has more limited codec support than Chrome
# Safe encoding for Android WebView:
ffmpeg -i INPUT \
  -c:v libx264 -profile:v main -level 3.1 \
  -pix_fmt yuv420p \
  -c:a aac -profile:a aac_low -b:a 128k -ar 44100 -ac 2 \
  -movflags +faststart \
  OUTPUT_android.mp4
```

#### Audio Codec Issues on Mobile
```bash
# Check audio codec compatibility
ffprobe -v error -select_streams a:0 \
  -show_entries stream=codec_name,profile,sample_rate,channels \
  -of default=noprint_wrappers=1 INPUT

# Mobile-safe audio codecs: AAC-LC only
# These may fail on some mobile browsers:
#   - HE-AAC v2 (aac with profile=HE-AACv2)
#   - Opus (in MP4 container)
#   - AC-3 / E-AC-3
#   - Vorbis (in MP4 container)

# Fix audio for universal mobile playback
ffmpeg -i INPUT -c:v copy \
  -c:a aac -profile:a aac_low -b:a 128k -ar 44100 -ac 2 \
  OUTPUT_fixed_audio.mp4
```

#### Test with Reduced Bandwidth
```bash
# Simulate mobile network conditions by limiting bitrate
# This helps identify buffering/loading issues on slow connections
ffmpeg -i INPUT \
  -c:v libx264 -preset fast -crf 28 \
  -maxrate 1500k -bufsize 3000k \
  -c:a aac -b:a 64k -ar 44100 \
  -vf "scale=-2:720" \
  -pix_fmt yuv420p \
  -movflags +faststart \
  OUTPUT_low_bandwidth.mp4
```

## Output

Provide:
1. Diagnosis of the specific error
2. Root cause explanation
3. Solution command(s)
4. Prevention tips for future
5. Alternative approaches if primary fix doesn't work
