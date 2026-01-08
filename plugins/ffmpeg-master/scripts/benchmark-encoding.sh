#!/bin/bash
# Benchmark FFmpeg encoding performance with different presets and encoders

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

INPUT="$1"
DURATION="${2:-10}"  # Default 10 seconds for benchmark

echo "=== FFmpeg Encoding Benchmark ==="
echo ""

# Create test source if no input provided
if [ -z "$INPUT" ]; then
    echo "No input file provided, generating test source..."
    INPUT="/tmp/ffmpeg_benchmark_source.mp4"
    ffmpeg -y -f lavfi -i testsrc=size=1920x1080:rate=30 \
        -f lavfi -i sine=frequency=1000 \
        -t $DURATION -c:v libx264 -preset ultrafast -c:a aac \
        "$INPUT" 2>/dev/null
    echo "Generated test source: ${DURATION}s of 1080p30"
    echo ""
fi

if [ ! -f "$INPUT" ]; then
    echo -e "${RED}Error: Input file not found: $INPUT${NC}"
    exit 1
fi

# Get input info
VIDEO_INFO=$(ffprobe -v error -select_streams v:0 \
    -show_entries stream=width,height,r_frame_rate \
    -of csv=p=0 "$INPUT")
WIDTH=$(echo "$VIDEO_INFO" | cut -d',' -f1)
HEIGHT=$(echo "$VIDEO_INFO" | cut -d',' -f2)
FPS=$(echo "$VIDEO_INFO" | cut -d',' -f3)

echo "Input: ${WIDTH}x${HEIGHT} @ ${FPS} fps"
echo "Benchmark duration: ${DURATION}s"
echo ""

# Benchmark function
benchmark_encode() {
    local name="$1"
    local encoder="$2"
    local preset="$3"
    local extra_args="$4"

    echo -e "${CYAN}Testing: $name${NC}"

    # Check if encoder is available
    if ! ffmpeg -encoders 2>/dev/null | grep -q "^ V..... $encoder "; then
        echo -e "${YELLOW}  [SKIP] Encoder not available${NC}"
        echo ""
        return
    fi

    OUTPUT="/tmp/ffmpeg_benchmark_output_$$.mp4"

    START_TIME=$(date +%s.%N)

    if ffmpeg -y -i "$INPUT" -t $DURATION \
        -c:v $encoder $preset $extra_args \
        -c:a aac -b:a 128k \
        "$OUTPUT" 2>/dev/null; then

        END_TIME=$(date +%s.%N)
        ELAPSED=$(echo "$END_TIME - $START_TIME" | bc)
        SPEED=$(echo "scale=2; $DURATION / $ELAPSED" | bc)
        OUTPUT_SIZE=$(ls -lh "$OUTPUT" | awk '{print $5}')
        OUTPUT_BYTES=$(stat -c %s "$OUTPUT" 2>/dev/null || stat -f %z "$OUTPUT" 2>/dev/null)
        BITRATE=$(echo "scale=0; $OUTPUT_BYTES * 8 / $DURATION / 1000" | bc)

        echo "  Time: ${ELAPSED}s"
        echo "  Speed: ${SPEED}x real-time"
        echo "  Output size: $OUTPUT_SIZE"
        echo "  Bitrate: ${BITRATE} kbps"

        if (( $(echo "$SPEED >= 1" | bc -l) )); then
            echo -e "  ${GREEN}[✓] Real-time capable${NC}"
        else
            echo -e "  ${YELLOW}[!] Slower than real-time${NC}"
        fi

        rm -f "$OUTPUT"
    else
        echo -e "  ${RED}[FAIL] Encoding failed${NC}"
    fi

    echo ""
}

echo "=== Software Encoders ==="
echo ""

# x264 presets
benchmark_encode "x264 ultrafast" "libx264" "-preset ultrafast -crf 23"
benchmark_encode "x264 veryfast" "libx264" "-preset veryfast -crf 23"
benchmark_encode "x264 medium" "libx264" "-preset medium -crf 23"
benchmark_encode "x264 slow" "libx264" "-preset slow -crf 23"

# x265
benchmark_encode "x265 medium" "libx265" "-preset medium -crf 23" "-tag:v hvc1"

# VP9
benchmark_encode "VP9 good quality" "libvpx-vp9" "-crf 30 -b:v 0"

# AV1 (slow but best compression)
benchmark_encode "AV1 (libaom)" "libaom-av1" "-crf 30 -cpu-used 8"
benchmark_encode "AV1 (SVT-AV1)" "libsvtav1" "-crf 30 -preset 8"

echo "=== Hardware Encoders ==="
echo ""

# NVIDIA NVENC
benchmark_encode "NVENC H.264 p1" "h264_nvenc" "-preset p1 -cq 23"
benchmark_encode "NVENC H.264 p4" "h264_nvenc" "-preset p4 -cq 23"
benchmark_encode "NVENC H.264 p7" "h264_nvenc" "-preset p7 -cq 23"
benchmark_encode "NVENC H.265" "hevc_nvenc" "-preset p4 -cq 23"
benchmark_encode "NVENC AV1" "av1_nvenc" "-preset p4 -cq 23"

# Intel QSV
benchmark_encode "QSV H.264" "h264_qsv" "-preset fast"
benchmark_encode "QSV H.265" "hevc_qsv" "-preset fast"

# AMD AMF
benchmark_encode "AMF H.264" "h264_amf" "-quality speed"
benchmark_encode "AMF H.265" "hevc_amf" "-quality speed"

# VAAPI
benchmark_encode "VAAPI H.264" "h264_vaapi" "" "-vaapi_device /dev/dri/renderD128 -vf 'format=nv12,hwupload'"
benchmark_encode "VAAPI H.265" "hevc_vaapi" "" "-vaapi_device /dev/dri/renderD128 -vf 'format=nv12,hwupload'"

echo "=== VVC (FFmpeg 8.0+) ==="
echo ""

benchmark_encode "VVC faster" "libvvenc" "-vvenc-params preset=faster" "-qp 28"
benchmark_encode "VVC medium" "libvvenc" "-vvenc-params preset=medium" "-qp 28"

# Summary
echo "=== Summary ==="
echo ""
echo "Encoder recommendations based on benchmark:"
echo ""
echo "For live streaming (real-time required):"
echo "  1. NVENC (if NVIDIA GPU available)"
echo "  2. QSV (if Intel GPU available)"
echo "  3. x264 ultrafast/veryfast"
echo ""
echo "For offline encoding (quality priority):"
echo "  1. x264 slow/veryslow"
echo "  2. x265 medium/slow"
echo "  3. AV1 (SVT-AV1) for best compression"
echo ""
echo "For cutting-edge compression (FFmpeg 8.0+):"
echo "  1. VVC/H.266 (slow but 25-50% better than HEVC)"
echo ""

# Cleanup
rm -f /tmp/ffmpeg_benchmark_source.mp4

echo "Done!"
