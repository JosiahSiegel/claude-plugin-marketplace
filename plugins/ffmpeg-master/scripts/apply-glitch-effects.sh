#!/bin/bash
# FFmpeg Glitch Effects Utility
# Apply various glitch/distortion effects to video
# Usage: ./apply-glitch-effects.sh <effect> <input> <output> [intensity]
#
# Effects: datamosh, vhs, chromatic, trails, wave, pixelate
# Intensity: 1-10 (default: 5)

set -e

EFFECT="${1:-help}"
INPUT="$2"
OUTPUT="$3"
INTENSITY="${4:-5}"

# Validate intensity range
if [[ "$INTENSITY" -lt 1 ]] || [[ "$INTENSITY" -gt 10 ]]; then
    echo "Error: Intensity must be between 1 and 10"
    exit 1
fi

show_help() {
    echo "FFmpeg Glitch Effects Utility"
    echo ""
    echo "Usage: $0 <effect> <input> <output> [intensity]"
    echo ""
    echo "Effects:"
    echo "  datamosh   - Motion interpolation glitch (pixel bleeding)"
    echo "  vhs        - VHS tape simulation (noise, tracking, color shift)"
    echo "  chromatic  - Chromatic aberration (RGB color separation)"
    echo "  trails     - Motion trails / ghosting effect"
    echo "  wave       - Wave distortion effect"
    echo "  pixelate   - Dynamic pixelation effect"
    echo "  combined   - Combined glitch effect (datamosh + chromatic + noise)"
    echo ""
    echo "Intensity: 1-10 (default: 5)"
    echo ""
    echo "Examples:"
    echo "  $0 datamosh input.mp4 output.mp4"
    echo "  $0 vhs input.mp4 retro.mp4 8"
    echo "  $0 chromatic clip.mp4 glitch.mp4 3"
}

apply_datamosh() {
    local scd_threshold=$(echo "scale=2; 0.5 - ($INTENSITY * 0.04)" | bc)
    echo "Applying datamosh effect (intensity: $INTENSITY)..."
    ffmpeg -i "$INPUT" \
        -vf "minterpolate='mi_mode=mci:mc_mode=aobmc:me_mode=bidir:vsbmc=1:scd=none'" \
        -c:v libx264 -crf 18 -preset medium \
        -c:a copy "$OUTPUT"
}

apply_vhs() {
    local noise_strength=$((INTENSITY * 3))
    local chroma_shift=$((INTENSITY / 2 + 1))
    echo "Applying VHS effect (intensity: $INTENSITY)..."
    ffmpeg -i "$INPUT" \
        -vf "noise=c0s=${noise_strength}:c0f=t:c1s=$((noise_strength/2)):c1f=t,\
eq=saturation=1.3:contrast=1.1:brightness=-0.02,\
chromashift=cbh=${chroma_shift}:crh=-${chroma_shift},\
rgbashift=rh=$((chroma_shift/2)):bh=-$((chroma_shift/2)),\
curves=preset=vintage" \
        -c:v libx264 -crf 20 -preset medium \
        -c:a copy "$OUTPUT"
}

apply_chromatic() {
    local shift=$((INTENSITY + 2))
    echo "Applying chromatic aberration (intensity: $INTENSITY)..."
    ffmpeg -i "$INPUT" \
        -vf "rgbashift=rh=-${shift}:bh=${shift}:rv=$((shift/2)):bv=-$((shift/2))" \
        -c:v libx264 -crf 18 -preset medium \
        -c:a copy "$OUTPUT"
}

apply_trails() {
    local decay=$(echo "scale=2; 0.85 + ($INTENSITY * 0.012)" | bc)
    echo "Applying motion trails (intensity: $INTENSITY, decay: $decay)..."
    ffmpeg -i "$INPUT" \
        -vf "lagfun=decay=${decay}" \
        -c:v libx264 -crf 18 -preset medium \
        -c:a copy "$OUTPUT"
}

apply_wave() {
    local amplitude=$((INTENSITY * 2 + 5))
    local frequency=$((20 - INTENSITY))
    echo "Applying wave distortion (intensity: $INTENSITY)..."
    ffmpeg -i "$INPUT" \
        -vf "geq=lum='lum(X+${amplitude}*sin(Y/${frequency}+T*5),Y)':cb='cb(X+${amplitude}*sin(Y/${frequency}+T*5),Y)':cr='cr(X+${amplitude}*sin(Y/${frequency}+T*5),Y)'" \
        -c:v libx264 -crf 18 -preset medium \
        -c:a copy "$OUTPUT"
}

apply_pixelate() {
    local scale_factor=$((12 - INTENSITY))
    [[ "$scale_factor" -lt 2 ]] && scale_factor=2
    echo "Applying pixelation (intensity: $INTENSITY, scale: 1/${scale_factor})..."
    ffmpeg -i "$INPUT" \
        -vf "scale=iw/${scale_factor}:ih/${scale_factor}:flags=neighbor,scale=iw*${scale_factor}:ih*${scale_factor}:flags=neighbor" \
        -c:v libx264 -crf 18 -preset medium \
        -c:a copy "$OUTPUT"
}

apply_combined() {
    local noise_strength=$((INTENSITY * 2))
    local shift=$((INTENSITY / 2 + 1))
    echo "Applying combined glitch effect (intensity: $INTENSITY)..."
    ffmpeg -i "$INPUT" \
        -vf "minterpolate='mi_mode=mci:mc_mode=aobmc':enable='lt(mod(t,3),0.2)',\
rgbashift=rh='${shift}*sin(t*10)':bh='-${shift}*sin(t*10)',\
noise=c0s=${noise_strength}:c0f=t:enable='lt(mod(t,2),0.1)'" \
        -c:v libx264 -crf 18 -preset medium \
        -c:a copy "$OUTPUT"
}

# Main execution
case "$EFFECT" in
    help|--help|-h)
        show_help
        exit 0
        ;;
    datamosh)
        [[ -z "$INPUT" || -z "$OUTPUT" ]] && { show_help; exit 1; }
        apply_datamosh
        ;;
    vhs)
        [[ -z "$INPUT" || -z "$OUTPUT" ]] && { show_help; exit 1; }
        apply_vhs
        ;;
    chromatic)
        [[ -z "$INPUT" || -z "$OUTPUT" ]] && { show_help; exit 1; }
        apply_chromatic
        ;;
    trails)
        [[ -z "$INPUT" || -z "$OUTPUT" ]] && { show_help; exit 1; }
        apply_trails
        ;;
    wave)
        [[ -z "$INPUT" || -z "$OUTPUT" ]] && { show_help; exit 1; }
        apply_wave
        ;;
    pixelate)
        [[ -z "$INPUT" || -z "$OUTPUT" ]] && { show_help; exit 1; }
        apply_pixelate
        ;;
    combined)
        [[ -z "$INPUT" || -z "$OUTPUT" ]] && { show_help; exit 1; }
        apply_combined
        ;;
    *)
        echo "Unknown effect: $EFFECT"
        show_help
        exit 1
        ;;
esac

echo "Done! Output saved to: $OUTPUT"
