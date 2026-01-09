---
name: Batch Social Export
description: Export video content for multiple social platforms simultaneously (TikTok, YouTube Shorts, Instagram Reels, Twitter/X) with platform-optimized encoding
argument-hint: <input-file> [--platforms] [--captions] [--clips]
---

## CRITICAL GUIDELINES

### Windows File Path Requirements

**MANDATORY: Always Use Backslashes on Windows for File Paths**

When using Edit or Write tools on Windows, you MUST use backslashes (`\`) in file paths, NOT forward slashes (`/`).

---

# Batch Social Media Export

## Purpose

Process a single video into multiple platform-optimized outputs simultaneously:
- **TikTok** (9:16, H.264, 60s max)
- **YouTube Shorts** (9:16, H.264/VP9, 59s max)
- **Instagram Reels** (9:16, H.264, 90s max)
- **Facebook Reels** (9:16, H.264, 90s max)
- **Twitter/X** (9:16, H.264, 140s max)
- **Snapchat Spotlight** (9:16, H.264, 60s max)

Also includes:
- Automatic caption generation
- Thumbnail extraction
- Content calendar-ready file organization

## Quick Start

### Export to All Platforms

```bash
# Basic batch export
./batch_social.sh input.mp4

# With captions
./batch_social.sh input.mp4 --captions

# Specific platforms only
./batch_social.sh input.mp4 --platforms tiktok,shorts,reels
```

## Complete Batch Export Script

```bash
#!/bin/bash
# batch_social.sh - Export video to all social platforms simultaneously
#
# Usage: ./batch_social.sh <input_video> [options]
# Options:
#   --captions      Generate and burn auto-captions
#   --platforms     Comma-separated list: tiktok,shorts,reels,facebook,twitter,snapchat
#   --output-dir    Output directory (default: ./social_exports)
#   --clips N       Extract N clips from longer video
#   --hook TEXT     Add text hook overlay to first 2 seconds

set -e

INPUT="$1"
shift

# Default settings
CAPTIONS=false
PLATFORMS="tiktok,shorts,reels,twitter"
OUTPUT_DIR="./social_exports"
CLIP_COUNT=0
HOOK_TEXT=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --captions)
            CAPTIONS=true
            shift
            ;;
        --platforms)
            PLATFORMS="$2"
            shift 2
            ;;
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --clips)
            CLIP_COUNT="$2"
            shift 2
            ;;
        --hook)
            HOOK_TEXT="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Validate input
if [ -z "$INPUT" ] || [ ! -f "$INPUT" ]; then
    echo "Error: Input file not found: $INPUT"
    exit 1
fi

BASENAME=$(basename "$INPUT" .mp4)
mkdir -p "$OUTPUT_DIR"

echo "==========================================="
echo "   BATCH SOCIAL MEDIA EXPORT"
echo "==========================================="
echo "Input: $INPUT"
echo "Platforms: $PLATFORMS"
echo "Captions: $CAPTIONS"
echo "Output: $OUTPUT_DIR"
echo "==========================================="

# Get video duration
DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$INPUT")
echo "Video duration: ${DURATION}s"

# Generate captions if requested
CAPTION_FILTER=""
if [ "$CAPTIONS" = true ]; then
    echo ""
    echo "[STEP] Generating captions with Whisper..."
    ffmpeg -y -i "$INPUT" -vn \
        -af "whisper=model=ggml-base.bin:language=auto:format=srt" \
        "${OUTPUT_DIR}/captions.srt" 2>/dev/null || echo "Warning: Whisper failed, continuing without captions"

    if [ -f "${OUTPUT_DIR}/captions.srt" ]; then
        CAPTION_FILTER=",subtitles=${OUTPUT_DIR}/captions.srt:force_style='FontName=Arial Black,FontSize=52,PrimaryColour=&HFFFFFF,OutlineColour=&H000000,Outline=4,Bold=1,Alignment=2,MarginV=200'"
    fi
fi

# Hook filter
HOOK_FILTER=""
if [ -n "$HOOK_TEXT" ]; then
    HOOK_FILTER=",drawtext=text='${HOOK_TEXT}':fontsize=64:fontcolor=yellow:borderw=4:bordercolor=black:x=(w-tw)/2:y=h*0.12:enable='between(t,0,2.5)'"
fi

# Function to export for a platform
export_platform() {
    local PLATFORM="$1"
    local OUTPUT="${OUTPUT_DIR}/${BASENAME}_${PLATFORM}.mp4"

    case $PLATFORM in
        tiktok)
            local MAX_DURATION=60
            local AUDIO_RATE=44100
            local AUDIO_BITRATE=128k
            local CRF=23
            ;;
        shorts)
            local MAX_DURATION=59
            local AUDIO_RATE=48000
            local AUDIO_BITRATE=192k
            local CRF=22
            ;;
        reels|facebook)
            local MAX_DURATION=90
            local AUDIO_RATE=44100
            local AUDIO_BITRATE=128k
            local CRF=23
            ;;
        twitter)
            local MAX_DURATION=140
            local AUDIO_RATE=44100
            local AUDIO_BITRATE=128k
            local CRF=23
            ;;
        snapchat)
            local MAX_DURATION=60
            local AUDIO_RATE=44100
            local AUDIO_BITRATE=128k
            local CRF=24
            ;;
        *)
            echo "Unknown platform: $PLATFORM"
            return 1
            ;;
    esac

    # Calculate actual duration to use
    local USE_DURATION=$(echo "$DURATION $MAX_DURATION" | awk '{if($1<$2) print $1; else print $2}')

    echo "[${PLATFORM^^}] Exporting (max ${MAX_DURATION}s)..."

    ffmpeg -y -i "$INPUT" \
        -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black,setsar=1${HOOK_FILTER}${CAPTION_FILTER}" \
        -c:v libx264 -preset fast -crf $CRF -profile:v high -level 4.1 \
        -c:a aac -b:a $AUDIO_BITRATE -ar $AUDIO_RATE -ac 2 \
        -pix_fmt yuv420p \
        -movflags +faststart \
        -t $USE_DURATION \
        "$OUTPUT" 2>/dev/null

    # Extract thumbnail
    ffmpeg -y -i "$OUTPUT" -ss 00:00:03 -vframes 1 -q:v 2 \
        "${OUTPUT_DIR}/${BASENAME}_${PLATFORM}_thumb.jpg" 2>/dev/null

    local SIZE=$(ls -lh "$OUTPUT" | awk '{print $5}')
    echo "[${PLATFORM^^}] Done: $OUTPUT ($SIZE)"
}

# Run exports in parallel
echo ""
echo "[STEP] Starting platform exports..."

IFS=',' read -ra PLATFORM_ARRAY <<< "$PLATFORMS"
PIDS=()

for PLATFORM in "${PLATFORM_ARRAY[@]}"; do
    export_platform "$PLATFORM" &
    PIDS+=($!)
done

# Wait for all exports to complete
for PID in "${PIDS[@]}"; do
    wait $PID
done

echo ""
echo "==========================================="
echo "   EXPORT COMPLETE"
echo "==========================================="
echo ""
ls -lh "$OUTPUT_DIR"/${BASENAME}_*
echo ""
echo "Files ready for upload in: $OUTPUT_DIR"
```

## Individual Platform Commands

### TikTok Export

```bash
ffmpeg -i input.mp4 \
  -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black,setsar=1" \
  -c:v libx264 -preset fast -crf 23 -profile:v high -level 4.1 \
  -c:a aac -b:a 128k -ar 44100 -ac 2 \
  -pix_fmt yuv420p \
  -movflags +faststart \
  -t 60 \
  output_tiktok.mp4
```

### YouTube Shorts Export

```bash
ffmpeg -i input.mp4 \
  -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black,setsar=1" \
  -c:v libx264 -preset fast -crf 22 -profile:v high -level 4.2 \
  -c:a aac -b:a 192k -ar 48000 -ac 2 \
  -pix_fmt yuv420p \
  -movflags +faststart \
  -t 59 \
  output_shorts.mp4
```

### Instagram Reels Export

```bash
ffmpeg -i input.mp4 \
  -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black,setsar=1,fps=30" \
  -c:v libx264 -preset fast -crf 23 -profile:v high -level 4.1 \
  -c:a aac -b:a 128k -ar 44100 -ac 2 \
  -pix_fmt yuv420p \
  -movflags +faststart \
  -t 90 \
  output_reels.mp4
```

### Twitter/X Export

```bash
ffmpeg -i input.mp4 \
  -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black,setsar=1,fps=30" \
  -c:v libx264 -preset fast -crf 23 -profile:v high -level 4.1 \
  -c:a aac -b:a 128k -ar 44100 -ac 2 \
  -pix_fmt yuv420p \
  -movflags +faststart \
  -t 140 \
  output_twitter.mp4
```

## Content Calendar Workflow

### Weekly Content Generation Script

```bash
#!/bin/bash
# weekly_content.sh - Generate a week's worth of social content from source videos
#
# Usage: ./weekly_content.sh source_videos_dir output_dir

SOURCE_DIR="$1"
OUTPUT_DIR="${2:-./weekly_content}"
WEEK=$(date +%Y-W%V)

mkdir -p "$OUTPUT_DIR/$WEEK"/{monday,tuesday,wednesday,thursday,friday,saturday,sunday}

DAYS=(monday tuesday wednesday thursday friday saturday sunday)
DAY_INDEX=0

for VIDEO in "$SOURCE_DIR"/*.mp4; do
    [ -f "$VIDEO" ] || continue

    BASENAME=$(basename "$VIDEO" .mp4)
    DAY="${DAYS[$DAY_INDEX]}"
    DAY_DIR="$OUTPUT_DIR/$WEEK/$DAY"

    echo "Processing $BASENAME for $DAY..."

    # Export to all platforms
    ffmpeg -y -i "$VIDEO" \
      -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black" \
      -c:v libx264 -preset fast -crf 23 \
      -c:a aac -b:a 128k \
      -pix_fmt yuv420p -movflags +faststart \
      -t 60 \
      "$DAY_DIR/${BASENAME}_tiktok.mp4" &

    ffmpeg -y -i "$VIDEO" \
      -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black" \
      -c:v libx264 -preset fast -crf 22 \
      -c:a aac -b:a 192k -ar 48000 \
      -pix_fmt yuv420p -movflags +faststart \
      -t 59 \
      "$DAY_DIR/${BASENAME}_shorts.mp4" &

    ffmpeg -y -i "$VIDEO" \
      -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black,fps=30" \
      -c:v libx264 -preset fast -crf 23 \
      -c:a aac -b:a 128k \
      -pix_fmt yuv420p -movflags +faststart \
      -t 90 \
      "$DAY_DIR/${BASENAME}_reels.mp4" &

    wait

    # Extract thumbnails
    ffmpeg -y -i "$DAY_DIR/${BASENAME}_tiktok.mp4" -ss 3 -vframes 1 "$DAY_DIR/${BASENAME}_thumb.jpg" 2>/dev/null

    DAY_INDEX=$(( (DAY_INDEX + 1) % 7 ))
done

echo ""
echo "Weekly content generated in: $OUTPUT_DIR/$WEEK"
find "$OUTPUT_DIR/$WEEK" -name "*.mp4" | wc -l
echo "videos created"
```

## Long Video to Clips Workflow

### Extract Multiple Clips from Long Video

```bash
#!/bin/bash
# extract_clips.sh - Extract viral clips from long-form content
#
# Usage: ./extract_clips.sh long_video.mp4 timestamps.txt output_dir
#
# timestamps.txt format (one per line):
# 00:01:30-00:02:15 Hook about topic A
# 00:05:00-00:05:45 Best moment
# 00:10:20-00:11:10 Viral potential clip

LONG_VIDEO="$1"
TIMESTAMPS="$2"
OUTPUT_DIR="${3:-./clips}"

mkdir -p "$OUTPUT_DIR"

CLIP_NUM=1
while IFS= read -r LINE; do
    # Skip empty lines and comments
    [[ -z "$LINE" || "$LINE" =~ ^# ]] && continue

    # Parse timestamp and description
    TIMERANGE=$(echo "$LINE" | awk '{print $1}')
    DESCRIPTION=$(echo "$LINE" | cut -d' ' -f2-)

    START=$(echo "$TIMERANGE" | cut -d'-' -f1)
    END=$(echo "$TIMERANGE" | cut -d'-' -f2)

    # Calculate duration
    START_SEC=$(echo "$START" | awk -F: '{print ($1*3600)+($2*60)+$3}')
    END_SEC=$(echo "$END" | awk -F: '{print ($1*3600)+($2*60)+$3}')
    DURATION=$((END_SEC - START_SEC))

    OUTPUT_NAME=$(printf "clip_%02d" $CLIP_NUM)

    echo "Extracting clip $CLIP_NUM: $DESCRIPTION ($DURATION seconds)"

    # Extract and process for all platforms
    ffmpeg -y -ss "$START" -i "$LONG_VIDEO" -t "$DURATION" \
      -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black" \
      -c:v libx264 -preset fast -crf 23 \
      -c:a aac -b:a 128k \
      -pix_fmt yuv420p -movflags +faststart \
      "$OUTPUT_DIR/${OUTPUT_NAME}_tiktok.mp4" &

    ffmpeg -y -ss "$START" -i "$LONG_VIDEO" -t "$DURATION" \
      -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black" \
      -c:v libx264 -preset fast -crf 22 \
      -c:a aac -b:a 192k -ar 48000 \
      -pix_fmt yuv420p -movflags +faststart \
      "$OUTPUT_DIR/${OUTPUT_NAME}_shorts.mp4" &

    wait

    CLIP_NUM=$((CLIP_NUM + 1))
done < "$TIMESTAMPS"

echo ""
echo "Extracted $((CLIP_NUM - 1)) clips to: $OUTPUT_DIR"
ls -lh "$OUTPUT_DIR"
```

## PowerShell Version (Windows)

```powershell
# batch_social.ps1 - Windows PowerShell version
# Usage: .\batch_social.ps1 -Input "input.mp4" -Platforms "tiktok,shorts,reels"

param(
    [Parameter(Mandatory=$true)]
    [string]$Input,

    [string]$Platforms = "tiktok,shorts,reels,twitter",

    [string]$OutputDir = ".\social_exports",

    [switch]$Captions
)

$BaseName = [System.IO.Path]::GetFileNameWithoutExtension($Input)

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

Write-Host "==========================================="
Write-Host "   BATCH SOCIAL MEDIA EXPORT (Windows)"
Write-Host "==========================================="
Write-Host "Input: $Input"
Write-Host "Platforms: $Platforms"
Write-Host "Output: $OutputDir"
Write-Host "==========================================="

$PlatformList = $Platforms -split ","

$Jobs = @()

foreach ($Platform in $PlatformList) {
    $Output = "$OutputDir\${BaseName}_${Platform}.mp4"

    switch ($Platform) {
        "tiktok" {
            $MaxDuration = 60
            $AudioRate = 44100
            $AudioBitrate = "128k"
            $CRF = 23
        }
        "shorts" {
            $MaxDuration = 59
            $AudioRate = 48000
            $AudioBitrate = "192k"
            $CRF = 22
        }
        "reels" {
            $MaxDuration = 90
            $AudioRate = 44100
            $AudioBitrate = "128k"
            $CRF = 23
        }
        "twitter" {
            $MaxDuration = 140
            $AudioRate = 44100
            $AudioBitrate = "128k"
            $CRF = 23
        }
    }

    Write-Host "[$($Platform.ToUpper())] Starting export..."

    $Job = Start-Job -ScriptBlock {
        param($Input, $Output, $MaxDuration, $AudioRate, $AudioBitrate, $CRF)

        ffmpeg -y -i $Input `
            -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black,setsar=1" `
            -c:v libx264 -preset fast -crf $CRF -profile:v high -level 4.1 `
            -c:a aac -b:a $AudioBitrate -ar $AudioRate -ac 2 `
            -pix_fmt yuv420p `
            -movflags +faststart `
            -t $MaxDuration `
            $Output

    } -ArgumentList $Input, $Output, $MaxDuration, $AudioRate, $AudioBitrate, $CRF

    $Jobs += $Job
}

# Wait for all jobs
$Jobs | Wait-Job | Out-Null

# Get results
foreach ($Job in $Jobs) {
    Receive-Job -Job $Job
    Remove-Job -Job $Job
}

Write-Host ""
Write-Host "==========================================="
Write-Host "   EXPORT COMPLETE"
Write-Host "==========================================="
Get-ChildItem "$OutputDir\${BaseName}_*" | Format-Table Name, Length
```

## Verification and Quality Check

```bash
#!/bin/bash
# verify_exports.sh - Verify all exported files meet platform requirements

OUTPUT_DIR="${1:-./social_exports}"

echo "Verifying exports in: $OUTPUT_DIR"
echo ""

for FILE in "$OUTPUT_DIR"/*.mp4; do
    [ -f "$FILE" ] || continue

    FILENAME=$(basename "$FILE")

    # Get video info
    INFO=$(ffprobe -v error -select_streams v:0 \
        -show_entries stream=width,height,codec_name,pix_fmt \
        -show_entries format=duration,size \
        -of csv=p=0 "$FILE")

    WIDTH=$(echo "$INFO" | cut -d',' -f1)
    HEIGHT=$(echo "$INFO" | cut -d',' -f2)
    CODEC=$(echo "$INFO" | cut -d',' -f3)
    PIX_FMT=$(echo "$INFO" | cut -d',' -f4)
    DURATION=$(echo "$INFO" | cut -d',' -f5)
    SIZE=$(echo "$INFO" | cut -d',' -f6)

    SIZE_MB=$(echo "scale=2; $SIZE / 1048576" | bc)

    # Check requirements
    STATUS="✅"
    ISSUES=""

    if [ "$WIDTH" != "1080" ] || [ "$HEIGHT" != "1920" ]; then
        STATUS="❌"
        ISSUES+=" Wrong resolution"
    fi

    if [ "$CODEC" != "h264" ]; then
        STATUS="❌"
        ISSUES+=" Wrong codec"
    fi

    if [ "$PIX_FMT" != "yuv420p" ]; then
        STATUS="⚠️"
        ISSUES+=" Check pixel format"
    fi

    printf "%-40s %s %.1fs %.1fMB %s\n" "$FILENAME" "$STATUS" "$DURATION" "$SIZE_MB" "$ISSUES"
done
```

## Output Structure

After running batch export, you'll have:

```
social_exports/
├── video_tiktok.mp4        # TikTok optimized (60s max)
├── video_tiktok_thumb.jpg  # TikTok thumbnail
├── video_shorts.mp4        # YouTube Shorts (59s max)
├── video_shorts_thumb.jpg  # Shorts thumbnail
├── video_reels.mp4         # Instagram Reels (90s max)
├── video_reels_thumb.jpg   # Reels thumbnail
├── video_twitter.mp4       # Twitter/X (140s max)
├── video_twitter_thumb.jpg # Twitter thumbnail
└── captions.srt            # Generated captions (if enabled)
```

## Related Skills

- `viral-video-platform-specs` - Platform requirements reference
- `ffmpeg-viral-tiktok` - TikTok-specific optimization
- `ffmpeg-viral-shorts` - YouTube Shorts optimization
- `viral-video-animated-captions` - Advanced caption styling
