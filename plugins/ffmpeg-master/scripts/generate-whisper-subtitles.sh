#!/bin/bash
# Generate subtitles using FFmpeg 8.0 Whisper filter

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo "=== FFmpeg Whisper Subtitle Generator ==="
echo ""

# Check for arguments
if [ -z "$1" ]; then
    echo "Usage: $0 <input-video> [model] [language]"
    echo ""
    echo "Arguments:"
    echo "  input-video  Path to video file"
    echo "  model        Whisper model (tiny, base, small, medium, large) [default: base]"
    echo "  language     Language code (en, es, fr, auto, etc.) [default: auto]"
    echo ""
    echo "Examples:"
    echo "  $0 video.mp4"
    echo "  $0 video.mp4 medium en"
    echo "  $0 video.mp4 base auto"
    exit 1
fi

INPUT="$1"
MODEL="${2:-base}"
LANGUAGE="${3:-auto}"

if [ ! -f "$INPUT" ]; then
    echo -e "${RED}Error: Input file not found: $INPUT${NC}"
    exit 1
fi

# Check FFmpeg version
FFMPEG_VERSION=$(ffmpeg -version 2>/dev/null | head -1)
MAJOR_VERSION=$(echo "$FFMPEG_VERSION" | grep -oE 'ffmpeg version [0-9]+' | grep -oE '[0-9]+')

if [ "$MAJOR_VERSION" -lt 8 ] 2>/dev/null; then
    echo -e "${RED}Error: FFmpeg 8.0+ required for Whisper filter${NC}"
    echo "Current version: $FFMPEG_VERSION"
    echo ""
    echo "Please update FFmpeg from: https://ffmpeg.org/download.html"
    exit 1
fi

# Check for Whisper filter
if ! ffmpeg -filters 2>/dev/null | grep -q whisper; then
    echo -e "${RED}Error: Whisper filter not available in this FFmpeg build${NC}"
    echo ""
    echo "The Whisper filter requires FFmpeg built with whisper.cpp support."
    echo "See: https://github.com/FFmpeg/FFmpeg/blob/master/doc/filters.texi"
    exit 1
fi

echo "FFmpeg version: $FFMPEG_VERSION"
echo "Input: $INPUT"
echo "Model: $MODEL"
echo "Language: $LANGUAGE"
echo ""

# Model file paths
MODEL_DIR="${WHISPER_MODEL_DIR:-$HOME/.cache/whisper}"
MODEL_FILE="$MODEL_DIR/ggml-${MODEL}.bin"

# Download model if not present
if [ ! -f "$MODEL_FILE" ]; then
    echo -e "${YELLOW}Model not found, downloading...${NC}"
    mkdir -p "$MODEL_DIR"

    MODEL_URL="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-${MODEL}.bin"

    if command -v wget &> /dev/null; then
        wget -O "$MODEL_FILE" "$MODEL_URL"
    elif command -v curl &> /dev/null; then
        curl -L -o "$MODEL_FILE" "$MODEL_URL"
    else
        echo -e "${RED}Error: wget or curl required to download model${NC}"
        exit 1
    fi

    echo -e "${GREEN}Model downloaded to: $MODEL_FILE${NC}"
    echo ""
fi

# Generate output filename
BASENAME=$(basename "$INPUT" | sed 's/\.[^.]*$//')
OUTPUT_SRT="${BASENAME}.srt"
OUTPUT_VTT="${BASENAME}.vtt"

# Extract audio first (for long videos, this is faster)
echo "=== Extracting audio ==="
TEMP_AUDIO="/tmp/whisper_audio_$$.wav"
ffmpeg -y -i "$INPUT" -vn -c:a pcm_s16le -ar 16000 -ac 1 "$TEMP_AUDIO" 2>/dev/null
echo -e "${GREEN}Audio extracted${NC}"
echo ""

# Generate subtitles
echo "=== Generating subtitles ==="
echo "This may take a while for long videos..."
echo ""

START_TIME=$(date +%s)

ffmpeg -y -i "$TEMP_AUDIO" \
    -af "whisper=model=$MODEL_FILE:language=$LANGUAGE:format=srt" \
    -f srt "$OUTPUT_SRT" 2>&1 | grep -v "^$"

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

# Convert to VTT as well
ffmpeg -y -i "$OUTPUT_SRT" "$OUTPUT_VTT" 2>/dev/null

# Cleanup
rm -f "$TEMP_AUDIO"

# Results
echo ""
echo "=== Results ==="
echo ""
echo -e "${GREEN}Generated:${NC}"
echo "  SRT: $OUTPUT_SRT"
echo "  VTT: $OUTPUT_VTT"
echo ""
echo "Processing time: ${ELAPSED}s"

# Show preview
echo ""
echo "=== Subtitle Preview (first 5 entries) ==="
head -20 "$OUTPUT_SRT"
echo ""

# Suggest burn-in command
echo "=== To Burn Subtitles into Video ==="
echo ""
echo "ffmpeg -i \"$INPUT\" -vf \"subtitles=$OUTPUT_SRT\" \\"
echo "  -c:v libx264 -crf 20 -c:a copy \\"
echo "  \"${BASENAME}_with_subs.mp4\""
echo ""

# Show accuracy tips
echo "=== Tips for Better Accuracy ==="
echo ""
echo "1. Use a larger model (medium or large) for better accuracy"
echo "2. Specify the language explicitly if known (e.g., 'en' instead of 'auto')"
echo "3. Clean up audio with noise reduction before transcription:"
echo "   ffmpeg -i input.mp4 -vn -af \"afftdn=nf=-25\" clean_audio.wav"
echo ""

echo "Done!"
