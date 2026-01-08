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

## Output

Provide:
1. Diagnosis of the specific error
2. Root cause explanation
3. Solution command(s)
4. Prevention tips for future
5. Alternative approaches if primary fix doesn't work
