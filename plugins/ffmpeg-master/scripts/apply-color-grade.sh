#!/bin/bash
# FFmpeg Color Grading Utility
# Apply various color grading presets and effects
# Usage: ./apply-color-grade.sh <preset> <input> <output> [intensity]
#
# Presets: cinematic, vintage, noir, warm, cool, bleach, instagram
# Intensity: 1-10 (default: 5)

set -e

PRESET="${1:-help}"
INPUT="$2"
OUTPUT="$3"
INTENSITY="${4:-5}"

# Validate intensity range
if [[ "$INTENSITY" -lt 1 ]] || [[ "$INTENSITY" -gt 10 ]]; then
    echo "Error: Intensity must be between 1 and 10"
    exit 1
fi

show_help() {
    echo "FFmpeg Color Grading Utility"
    echo ""
    echo "Usage: $0 <preset> <input> <output> [intensity]"
    echo ""
    echo "Presets:"
    echo "  cinematic  - Teal and orange blockbuster look"
    echo "  vintage    - Faded film with warm tones"
    echo "  noir       - High contrast black & white"
    echo "  warm       - Golden hour / warm sunset"
    echo "  cool       - Moonlight / blue tones"
    echo "  bleach     - Bleach bypass / desaturated contrast"
    echo "  instagram  - Bright, lifted shadows"
    echo "  matrix     - Green tinted cyberpunk"
    echo ""
    echo "Intensity: 1-10 (default: 5)"
    echo ""
    echo "Examples:"
    echo "  $0 cinematic input.mp4 output.mp4"
    echo "  $0 vintage clip.mp4 retro.mp4 8"
    echo "  $0 noir scene.mp4 bw.mp4 10"
}

apply_cinematic() {
    local sat=$(echo "scale=2; 1.0 + ($INTENSITY * 0.04)" | bc)
    local contrast=$(echo "scale=2; 1.0 + ($INTENSITY * 0.02)" | bc)
    echo "Applying cinematic teal & orange (intensity: $INTENSITY)..."
    ffmpeg -i "$INPUT" \
        -vf "curves=b='0/0.1 0.5/0.4 1/0.8':r='0/0 0.5/0.6 1/1',eq=saturation=${sat}:contrast=${contrast}" \
        -c:v libx264 -crf 18 -preset medium \
        -c:a copy "$OUTPUT"
}

apply_vintage() {
    local sat=$(echo "scale=2; 1.0 - ($INTENSITY * 0.03)" | bc)
    local brightness=$(echo "scale=2; $INTENSITY * 0.005" | bc)
    echo "Applying vintage film look (intensity: $INTENSITY)..."
    ffmpeg -i "$INPUT" \
        -vf "curves=preset=vintage,eq=saturation=${sat}:brightness=${brightness},\
colorbalance=rs=0.1:gs=0.05:bs=-0.05" \
        -c:v libx264 -crf 18 -preset medium \
        -c:a copy "$OUTPUT"
}

apply_noir() {
    local contrast=$(echo "scale=2; 1.2 + ($INTENSITY * 0.05)" | bc)
    local brightness=$(echo "scale=2; -0.05 - ($INTENSITY * 0.01)" | bc)
    echo "Applying noir high contrast B&W (intensity: $INTENSITY)..."
    ffmpeg -i "$INPUT" \
        -vf "eq=contrast=${contrast}:brightness=${brightness}:saturation=0,\
curves=all='0/0 0.15/0.05 0.5/0.5 0.85/0.95 1/1'" \
        -c:v libx264 -crf 18 -preset medium \
        -c:a copy "$OUTPUT"
}

apply_warm() {
    local rs=$(echo "scale=2; $INTENSITY * 0.02" | bc)
    local gs=$(echo "scale=2; $INTENSITY * 0.01" | bc)
    local bs=$(echo "scale=2; -$INTENSITY * 0.015" | bc)
    echo "Applying warm golden tones (intensity: $INTENSITY)..."
    ffmpeg -i "$INPUT" \
        -vf "colorbalance=rs=${rs}:gs=${gs}:bs=${bs}:rm=${rs}:gm=${gs}:bm=${bs}" \
        -c:v libx264 -crf 18 -preset medium \
        -c:a copy "$OUTPUT"
}

apply_cool() {
    local bs=$(echo "scale=2; $INTENSITY * 0.025" | bc)
    local rs=$(echo "scale=2; -$INTENSITY * 0.015" | bc)
    local brightness=$(echo "scale=2; -$INTENSITY * 0.01" | bc)
    echo "Applying cool moonlight tones (intensity: $INTENSITY)..."
    ffmpeg -i "$INPUT" \
        -vf "colorbalance=rs=${rs}:bs=${bs}:rm=${rs}:bm=${bs},eq=brightness=${brightness}" \
        -c:v libx264 -crf 18 -preset medium \
        -c:a copy "$OUTPUT"
}

apply_bleach() {
    local sat=$(echo "scale=2; 1.0 - ($INTENSITY * 0.06)" | bc)
    local contrast=$(echo "scale=2; 1.0 + ($INTENSITY * 0.04)" | bc)
    echo "Applying bleach bypass (intensity: $INTENSITY)..."
    ffmpeg -i "$INPUT" \
        -vf "eq=saturation=${sat}:contrast=${contrast},curves=all='0/0 0.2/0.15 0.5/0.5 0.8/0.85 1/1'" \
        -c:v libx264 -crf 18 -preset medium \
        -c:a copy "$OUTPUT"
}

apply_instagram() {
    local sat=$(echo "scale=2; 1.0 + ($INTENSITY * 0.03)" | bc)
    local brightness=$(echo "scale=2; $INTENSITY * 0.01" | bc)
    echo "Applying instagram bright look (intensity: $INTENSITY)..."
    ffmpeg -i "$INPUT" \
        -vf "eq=saturation=${sat}:brightness=${brightness}:contrast=1.05,\
curves=all='0/0.05 0.25/0.3 0.5/0.55 0.75/0.8 1/1'" \
        -c:v libx264 -crf 18 -preset medium \
        -c:a copy "$OUTPUT"
}

apply_matrix() {
    local gs=$(echo "scale=2; $INTENSITY * 0.03" | bc)
    local rs=$(echo "scale=2; -$INTENSITY * 0.02" | bc)
    local contrast=$(echo "scale=2; 1.0 + ($INTENSITY * 0.02)" | bc)
    echo "Applying matrix green tint (intensity: $INTENSITY)..."
    ffmpeg -i "$INPUT" \
        -vf "colorbalance=rs=${rs}:gs=${gs}:rm=${rs}:gm=${gs}:rh=${rs}:gh=${gs},\
eq=contrast=${contrast}:brightness=-0.05" \
        -c:v libx264 -crf 18 -preset medium \
        -c:a copy "$OUTPUT"
}

# Main execution
case "$PRESET" in
    help|--help|-h)
        show_help
        exit 0
        ;;
    cinematic)
        [[ -z "$INPUT" || -z "$OUTPUT" ]] && { show_help; exit 1; }
        apply_cinematic
        ;;
    vintage)
        [[ -z "$INPUT" || -z "$OUTPUT" ]] && { show_help; exit 1; }
        apply_vintage
        ;;
    noir)
        [[ -z "$INPUT" || -z "$OUTPUT" ]] && { show_help; exit 1; }
        apply_noir
        ;;
    warm)
        [[ -z "$INPUT" || -z "$OUTPUT" ]] && { show_help; exit 1; }
        apply_warm
        ;;
    cool)
        [[ -z "$INPUT" || -z "$OUTPUT" ]] && { show_help; exit 1; }
        apply_cool
        ;;
    bleach)
        [[ -z "$INPUT" || -z "$OUTPUT" ]] && { show_help; exit 1; }
        apply_bleach
        ;;
    instagram)
        [[ -z "$INPUT" || -z "$OUTPUT" ]] && { show_help; exit 1; }
        apply_instagram
        ;;
    matrix)
        [[ -z "$INPUT" || -z "$OUTPUT" ]] && { show_help; exit 1; }
        apply_matrix
        ;;
    *)
        echo "Unknown preset: $PRESET"
        show_help
        exit 1
        ;;
esac

echo "Done! Output saved to: $OUTPUT"
