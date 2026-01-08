#!/bin/bash
# Check FFmpeg codec and encoder availability

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=== FFmpeg Codec Availability Check ==="
echo ""

# Check FFmpeg version
echo "=== FFmpeg Version ==="
FFMPEG_VERSION=$(ffmpeg -version 2>/dev/null | head -1)
if [ -n "$FFMPEG_VERSION" ]; then
    echo -e "${GREEN}$FFMPEG_VERSION${NC}"
else
    echo -e "${RED}FFmpeg not found!${NC}"
    exit 1
fi
echo ""

# Check for latest version
MAJOR_VERSION=$(echo "$FFMPEG_VERSION" | grep -oE 'ffmpeg version [0-9]+' | grep -oE '[0-9]+')
if [ "$MAJOR_VERSION" -lt 8 ] 2>/dev/null; then
    echo -e "${YELLOW}Note: FFmpeg 8.0.1 is the latest stable version${NC}"
    echo "  Visit https://ffmpeg.org/download.html to update"
    echo ""
fi

# Video Encoders
echo "=== Video Encoders ==="
echo ""

check_encoder() {
    local encoder=$1
    local name=$2
    if ffmpeg -encoders 2>/dev/null | grep -q "^ V..... $encoder "; then
        echo -e "${GREEN}[✓] $name ($encoder)${NC}"
        return 0
    else
        echo -e "${RED}[✗] $name ($encoder)${NC}"
        return 1
    fi
}

echo "Software Encoders:"
check_encoder "libx264" "H.264/AVC"
check_encoder "libx265" "H.265/HEVC"
check_encoder "libvpx-vp9" "VP9"
check_encoder "libaom-av1" "AV1 (libaom)"
check_encoder "libsvtav1" "AV1 (SVT-AV1)"
check_encoder "libvvenc" "VVC/H.266"
check_encoder "prores" "ProRes"

echo ""
echo "Hardware Encoders (NVIDIA):"
check_encoder "h264_nvenc" "NVENC H.264"
check_encoder "hevc_nvenc" "NVENC H.265"
check_encoder "av1_nvenc" "NVENC AV1"

echo ""
echo "Hardware Encoders (Intel QSV):"
check_encoder "h264_qsv" "QSV H.264"
check_encoder "hevc_qsv" "QSV H.265"
check_encoder "av1_qsv" "QSV AV1"
check_encoder "vp9_qsv" "QSV VP9"

echo ""
echo "Hardware Encoders (AMD/VAAPI):"
check_encoder "h264_vaapi" "VAAPI H.264"
check_encoder "hevc_vaapi" "VAAPI H.265"
check_encoder "av1_vaapi" "VAAPI AV1"
check_encoder "h264_amf" "AMF H.264"
check_encoder "hevc_amf" "AMF H.265"

echo ""
echo "Vulkan Encoders (FFmpeg 8.0+):"
check_encoder "h264_vulkan" "Vulkan H.264"
check_encoder "hevc_vulkan" "Vulkan H.265"

echo ""

# Video Decoders
echo "=== Video Decoders ==="
echo ""

check_decoder() {
    local decoder=$1
    local name=$2
    if ffmpeg -decoders 2>/dev/null | grep -q "^ V..... $decoder "; then
        echo -e "${GREEN}[✓] $name ($decoder)${NC}"
        return 0
    else
        echo -e "${RED}[✗] $name ($decoder)${NC}"
        return 1
    fi
}

echo "VVC/H.266 Decoders:"
check_decoder "vvc" "VVC Native"
check_decoder "libvvdec" "VVC (libvvdec)"

echo ""
echo "Hardware Decoders:"
check_decoder "h264_cuvid" "CUVID H.264"
check_decoder "hevc_cuvid" "CUVID H.265"
check_decoder "av1_cuvid" "CUVID AV1"
check_decoder "vvc_qsv" "QSV VVC (FFmpeg 8.0+)"

echo ""

# Audio Codecs
echo "=== Audio Codecs ==="
echo ""

echo "Encoders:"
check_encoder "aac" "AAC (native)"
check_encoder "libfdk_aac" "AAC (Fraunhofer FDK)"
check_encoder "libmp3lame" "MP3"
check_encoder "libopus" "Opus"
check_encoder "flac" "FLAC"
check_encoder "libvorbis" "Vorbis"

echo ""

# Filters
echo "=== Special Filters ==="
echo ""

check_filter() {
    local filter=$1
    local name=$2
    if ffmpeg -filters 2>/dev/null | grep -q " $filter "; then
        echo -e "${GREEN}[✓] $name ($filter)${NC}"
        return 0
    else
        echo -e "${RED}[✗] $name ($filter)${NC}"
        return 1
    fi
}

check_filter "whisper" "Whisper AI (FFmpeg 8.0+)"
check_filter "loudnorm" "EBU R128 Loudness"
check_filter "scale_cuda" "CUDA Scaling"
check_filter "scale_npp" "NPP Scaling"
check_filter "scale_qsv" "QSV Scaling"
check_filter "pad_cuda" "CUDA Padding (FFmpeg 8.0+)"
check_filter "colordetect" "Color Detection (FFmpeg 8.0+)"

echo ""

# Hardware Acceleration
echo "=== Hardware Acceleration ==="
echo ""

HWACCELS=$(ffmpeg -hwaccels 2>/dev/null | tail -n +2)
if [ -n "$HWACCELS" ]; then
    echo "Available hardware accelerators:"
    echo "$HWACCELS" | while read hw; do
        [ -n "$hw" ] && echo -e "  ${GREEN}[✓] $hw${NC}"
    done
else
    echo -e "${YELLOW}No hardware acceleration available${NC}"
fi

echo ""

# Muxers/Protocols
echo "=== Streaming Protocols ==="
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

check_muxer "flv" "RTMP (FLV)"
check_muxer "hls" "HLS"
check_muxer "dash" "DASH"
check_muxer "rtsp" "RTSP"
check_muxer "whip" "WHIP/WebRTC (FFmpeg 8.0+)"

echo ""

# Summary
echo "=== Summary ==="
echo ""

ENCODER_COUNT=$(ffmpeg -encoders 2>/dev/null | grep "^ V" | wc -l)
DECODER_COUNT=$(ffmpeg -decoders 2>/dev/null | grep "^ V" | wc -l)
FILTER_COUNT=$(ffmpeg -filters 2>/dev/null | wc -l)

echo "Video encoders: $ENCODER_COUNT"
echo "Video decoders: $DECODER_COUNT"
echo "Filters: $FILTER_COUNT"

echo ""
echo "Done!"
