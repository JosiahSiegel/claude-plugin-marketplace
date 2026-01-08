#!/bin/bash
# Validate streaming configuration and test stream setup

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo "=== FFmpeg Streaming Validation ==="
echo ""

# Check FFmpeg version
echo "=== FFmpeg Version Check ==="
FFMPEG_VERSION=$(ffmpeg -version 2>/dev/null | head -1)
echo "$FFMPEG_VERSION"

MAJOR_VERSION=$(echo "$FFMPEG_VERSION" | grep -oE 'ffmpeg version [0-9]+' | grep -oE '[0-9]+')
if [ "$MAJOR_VERSION" -ge 8 ] 2>/dev/null; then
    echo -e "${GREEN}[✓] FFmpeg 8.0+ detected - WHIP/WebRTC support available${NC}"
else
    echo -e "${YELLOW}[!] Consider updating to FFmpeg 8.0+ for WHIP/WebRTC support${NC}"
fi
echo ""

# Check streaming encoders
echo "=== Streaming Encoders ==="
echo ""

check_encoder() {
    local encoder=$1
    local name=$2
    if ffmpeg -encoders 2>/dev/null | grep -q "^ V..... $encoder "; then
        echo -e "${GREEN}[✓] $name${NC}"
        return 0
    else
        echo -e "${YELLOW}[!] $name (not available)${NC}"
        return 1
    fi
}

echo "Low-latency encoders:"
check_encoder "libx264" "libx264 (CPU)"
check_encoder "h264_nvenc" "NVENC H.264 (NVIDIA GPU)"
check_encoder "h264_qsv" "QSV H.264 (Intel GPU)"
check_encoder "h264_amf" "AMF H.264 (AMD GPU)"
check_encoder "h264_vaapi" "VAAPI H.264 (Linux)"

echo ""

# Check streaming protocols
echo "=== Streaming Protocols ==="
echo ""

check_protocol() {
    local protocol=$1
    local name=$2
    if ffmpeg -protocols 2>/dev/null | grep -q "$protocol"; then
        echo -e "${GREEN}[✓] $name${NC}"
        return 0
    else
        echo -e "${RED}[✗] $name (not available)${NC}"
        return 1
    fi
}

check_protocol "rtmp" "RTMP"
check_protocol "rtmps" "RTMPS (TLS)"
check_protocol "hls" "HLS"
check_protocol "srt" "SRT"
check_protocol "rtp" "RTP"

echo ""

# Check muxers
echo "=== Output Formats ==="
echo ""

check_muxer() {
    local muxer=$1
    local name=$2
    if ffmpeg -muxers 2>/dev/null | grep -q " $muxer "; then
        echo -e "${GREEN}[✓] $name${NC}"
        return 0
    else
        echo -e "${RED}[✗] $name${NC}"
        return 1
    fi
}

check_muxer "flv" "FLV (RTMP)"
check_muxer "hls" "HLS"
check_muxer "dash" "DASH"
check_muxer "mpegts" "MPEG-TS"
check_muxer "whip" "WHIP (WebRTC)"

echo ""

# Check input sources
echo "=== Input Sources ==="
echo ""

check_input() {
    local input=$1
    local name=$2
    if ffmpeg -devices 2>/dev/null | grep -q "$input"; then
        echo -e "${GREEN}[✓] $name${NC}"
        return 0
    else
        echo -e "${YELLOW}[!] $name (not available)${NC}"
        return 1
    fi
}

# OS-specific input checks
case "$(uname -s)" in
    Linux*)
        echo "Linux input devices:"
        check_input "v4l2" "V4L2 (webcam)"
        check_input "x11grab" "X11 screen capture"
        check_input "pulse" "PulseAudio"
        check_input "alsa" "ALSA"
        ;;
    Darwin*)
        echo "macOS input devices:"
        check_input "avfoundation" "AVFoundation (camera/screen)"
        ;;
    MINGW*|MSYS*|CYGWIN*)
        echo "Windows input devices:"
        check_input "dshow" "DirectShow (camera/audio)"
        check_input "gdigrab" "GDI screen capture"
        ;;
esac

echo ""

# Platform requirements
echo "=== Platform Requirements ==="
echo ""

echo -e "${CYAN}Twitch:${NC}"
echo "  Max bitrate: 6000 kbps (Partner/Affiliate)"
echo "  Keyframe: 2 seconds"
echo "  Recommended: 1080p60 @ 6000kbps or 720p60 @ 4500kbps"
echo "  Audio: AAC 160kbps @ 44100Hz"
echo ""

echo -e "${CYAN}YouTube:${NC}"
echo "  Max bitrate: 51000 kbps (4K60)"
echo "  Recommended: 1080p60 @ 4500-9000kbps"
echo "  Audio: AAC 128-384kbps @ 44100Hz"
echo ""

echo -e "${CYAN}Facebook:${NC}"
echo "  Max bitrate: 4000 kbps (1080p)"
echo "  Protocol: RTMPS (TLS required)"
echo "  Audio: AAC 128kbps @ 44100Hz"
echo ""

# Test commands
echo "=== Test Commands ==="
echo ""

echo -e "${CYAN}Generate test source:${NC}"
echo "ffmpeg -f lavfi -i testsrc=size=1920x1080:rate=30 \\"
echo "  -f lavfi -i sine=frequency=1000 \\"
echo "  -t 10 test_source.mp4"
echo ""

echo -e "${CYAN}Test Twitch stream (dry run):${NC}"
echo "ffmpeg -re -f lavfi -i testsrc=size=1920x1080:rate=30 \\"
echo "  -f lavfi -i sine=frequency=1000 \\"
echo "  -c:v libx264 -preset veryfast -b:v 6000k -g 60 \\"
echo "  -c:a aac -b:a 160k \\"
echo "  -t 10 -f flv /dev/null"
echo ""

echo -e "${CYAN}Test local HLS output:${NC}"
echo "ffmpeg -re -f lavfi -i testsrc=size=1280x720:rate=30 \\"
echo "  -c:v libx264 -preset ultrafast -b:v 2000k \\"
echo "  -c:a aac -b:a 128k \\"
echo "  -hls_time 4 -hls_list_size 5 \\"
echo "  -f hls test_stream.m3u8"
echo ""

# Run quick test
echo "=== Quick Encoding Test ==="
echo ""

echo "Testing encoding performance..."
START_TIME=$(date +%s.%N)
ffmpeg -f lavfi -i testsrc=size=1280x720:rate=30 -t 2 \
    -c:v libx264 -preset ultrafast -b:v 2000k \
    -f null - 2>/dev/null
END_TIME=$(date +%s.%N)
ELAPSED=$(echo "$END_TIME - $START_TIME" | bc)

echo "Encoded 2 seconds of 720p30 in ${ELAPSED}s"

# Calculate if real-time streaming is possible
if (( $(echo "$ELAPSED < 2" | bc -l) )); then
    echo -e "${GREEN}[✓] Real-time encoding is possible${NC}"
else
    echo -e "${YELLOW}[!] Encoding slower than real-time - use hardware acceleration${NC}"
fi

echo ""
echo "Done!"
