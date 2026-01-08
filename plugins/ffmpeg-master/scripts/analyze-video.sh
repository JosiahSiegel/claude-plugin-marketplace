#!/bin/bash
# Analyze video file and provide encoding recommendations

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

if [ -z "$1" ]; then
    echo "Usage: $0 <video-file>"
    echo ""
    echo "Analyzes a video file and provides encoding recommendations"
    exit 1
fi

INPUT="$1"

if [ ! -f "$INPUT" ]; then
    echo -e "${RED}Error: File not found: $INPUT${NC}"
    exit 1
fi

echo "=== Video Analysis: $(basename "$INPUT") ==="
echo ""

# Get file info
echo "=== File Information ==="
FILE_SIZE=$(ls -lh "$INPUT" | awk '{print $5}')
FILE_SIZE_BYTES=$(stat -c %s "$INPUT" 2>/dev/null || stat -f %z "$INPUT" 2>/dev/null)
echo "File size: $FILE_SIZE"

# Get container format
FORMAT=$(ffprobe -v error -show_entries format=format_name -of default=noprint_wrappers=1:nokey=1 "$INPUT")
DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$INPUT")
DURATION_HMS=$(printf '%02d:%02d:%02d\n' $((${DURATION%.*}/3600)) $((${DURATION%.*}%3600/60)) $((${DURATION%.*}%60)))
BITRATE=$(ffprobe -v error -show_entries format=bit_rate -of default=noprint_wrappers=1:nokey=1 "$INPUT")
BITRATE_MBPS=$(echo "scale=2; $BITRATE / 1000000" | bc 2>/dev/null || echo "N/A")

echo "Container: $FORMAT"
echo "Duration: $DURATION_HMS"
echo "Overall bitrate: ${BITRATE_MBPS} Mbps"
echo ""

# Video stream info
echo "=== Video Stream ==="
VIDEO_CODEC=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$INPUT")
VIDEO_WIDTH=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of default=noprint_wrappers=1:nokey=1 "$INPUT")
VIDEO_HEIGHT=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of default=noprint_wrappers=1:nokey=1 "$INPUT")
VIDEO_FPS=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1 "$INPUT")
VIDEO_BITRATE=$(ffprobe -v error -select_streams v:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 "$INPUT")
PIXEL_FORMAT=$(ffprobe -v error -select_streams v:0 -show_entries stream=pix_fmt -of default=noprint_wrappers=1:nokey=1 "$INPUT")
COLOR_SPACE=$(ffprobe -v error -select_streams v:0 -show_entries stream=color_space -of default=noprint_wrappers=1:nokey=1 "$INPUT" 2>/dev/null || echo "unknown")

echo "Codec: $VIDEO_CODEC"
echo "Resolution: ${VIDEO_WIDTH}x${VIDEO_HEIGHT}"
echo "Frame rate: $VIDEO_FPS"
echo "Pixel format: $PIXEL_FORMAT"
[ "$COLOR_SPACE" != "unknown" ] && echo "Color space: $COLOR_SPACE"

if [ -n "$VIDEO_BITRATE" ] && [ "$VIDEO_BITRATE" != "N/A" ]; then
    VIDEO_BITRATE_MBPS=$(echo "scale=2; $VIDEO_BITRATE / 1000000" | bc 2>/dev/null || echo "N/A")
    echo "Video bitrate: ${VIDEO_BITRATE_MBPS} Mbps"
fi

echo ""

# Audio stream info
echo "=== Audio Stream ==="
AUDIO_CODEC=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$INPUT" 2>/dev/null || echo "none")

if [ "$AUDIO_CODEC" != "none" ] && [ -n "$AUDIO_CODEC" ]; then
    AUDIO_CHANNELS=$(ffprobe -v error -select_streams a:0 -show_entries stream=channels -of default=noprint_wrappers=1:nokey=1 "$INPUT")
    AUDIO_SAMPLE_RATE=$(ffprobe -v error -select_streams a:0 -show_entries stream=sample_rate -of default=noprint_wrappers=1:nokey=1 "$INPUT")
    AUDIO_BITRATE=$(ffprobe -v error -select_streams a:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 "$INPUT" 2>/dev/null || echo "N/A")

    echo "Codec: $AUDIO_CODEC"
    echo "Channels: $AUDIO_CHANNELS"
    echo "Sample rate: ${AUDIO_SAMPLE_RATE} Hz"
    [ "$AUDIO_BITRATE" != "N/A" ] && [ -n "$AUDIO_BITRATE" ] && echo "Bitrate: $((AUDIO_BITRATE / 1000)) kbps"
else
    echo "No audio stream found"
fi

echo ""

# Quality assessment
echo "=== Quality Assessment ==="

# Resolution classification
if [ "$VIDEO_WIDTH" -ge 3840 ]; then
    RESOLUTION_CLASS="4K/UHD"
elif [ "$VIDEO_WIDTH" -ge 2560 ]; then
    RESOLUTION_CLASS="1440p/QHD"
elif [ "$VIDEO_WIDTH" -ge 1920 ]; then
    RESOLUTION_CLASS="1080p/FHD"
elif [ "$VIDEO_WIDTH" -ge 1280 ]; then
    RESOLUTION_CLASS="720p/HD"
elif [ "$VIDEO_WIDTH" -ge 854 ]; then
    RESOLUTION_CLASS="480p/SD"
else
    RESOLUTION_CLASS="Low Resolution"
fi
echo "Resolution class: $RESOLUTION_CLASS"

# Frame rate classification
FPS_NUM=$(echo "$VIDEO_FPS" | cut -d'/' -f1)
FPS_DEN=$(echo "$VIDEO_FPS" | cut -d'/' -f2)
FPS_FLOAT=$(echo "scale=2; $FPS_NUM / $FPS_DEN" | bc 2>/dev/null || echo "30")

if (( $(echo "$FPS_FLOAT >= 50" | bc -l) )); then
    echo "Frame rate: High (${FPS_FLOAT} fps - good for gaming/sports)"
elif (( $(echo "$FPS_FLOAT >= 24" | bc -l) )); then
    echo "Frame rate: Standard (${FPS_FLOAT} fps)"
else
    echo -e "${YELLOW}Frame rate: Low (${FPS_FLOAT} fps)${NC}"
fi

echo ""

# Encoding recommendations
echo "=== Encoding Recommendations ==="
echo ""

echo -e "${CYAN}For Web Delivery (Maximum Compatibility):${NC}"
echo "ffmpeg -i \"$INPUT\" \\"
echo "  -c:v libx264 -preset slow -crf 20 \\"
echo "  -c:a aac -b:a 128k \\"
echo "  -movflags +faststart \\"
echo "  output.mp4"
echo ""

echo -e "${CYAN}For Smaller File Size (H.265):${NC}"
echo "ffmpeg -i \"$INPUT\" \\"
echo "  -c:v libx265 -preset medium -crf 23 \\"
echo "  -tag:v hvc1 -c:a aac -b:a 128k \\"
echo "  -movflags +faststart \\"
echo "  output_h265.mp4"
echo ""

if [ "$VIDEO_WIDTH" -ge 3840 ]; then
    echo -e "${CYAN}For 4K with VVC (FFmpeg 8.0+):${NC}"
    echo "ffmpeg -i \"$INPUT\" \\"
    echo "  -c:v libvvenc -qp 28 \\"
    echo "  -vvenc-params \"preset=medium:tiles=4x4\" \\"
    echo "  -c:a aac -b:a 192k \\"
    echo "  output_vvc.mp4"
    echo ""
fi

echo -e "${CYAN}With NVIDIA Hardware Acceleration:${NC}"
echo "ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i \"$INPUT\" \\"
echo "  -c:v h264_nvenc -preset p4 -cq 23 \\"
echo "  -c:a aac -b:a 128k \\"
echo "  output_nvenc.mp4"
echo ""

# File validation
echo "=== File Validation ==="
echo ""

echo "Checking file integrity..."
if ffmpeg -v error -i "$INPUT" -f null - 2>/dev/null; then
    echo -e "${GREEN}[✓] File is valid and playable${NC}"
else
    echo -e "${RED}[✗] File has errors or corruption${NC}"
fi

echo ""
echo "Done!"
