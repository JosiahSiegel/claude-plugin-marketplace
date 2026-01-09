#!/bin/bash
# Estimate fal.ai costs for image/video generation workloads

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "=== fal.ai Cost Estimator ==="
echo ""

# Image model pricing ($ per megapixel or per image) - 2025 rates
declare -A IMAGE_PRICES
IMAGE_PRICES[flux-schnell]="0.003"      # Per image
IMAGE_PRICES[flux-dev]="0.025"          # Per megapixel
IMAGE_PRICES[flux-pro]="0.05"           # Per megapixel
IMAGE_PRICES[flux-2-pro]="0.05"         # Per megapixel
IMAGE_PRICES[flux-kontext]="0.03"       # Per edit
IMAGE_PRICES[gpt-image-1]="0.03"        # Per image
IMAGE_PRICES[gpt-image-1.5]="0.04"      # Per image
IMAGE_PRICES[recraft-v3]="0.04"         # Per image
IMAGE_PRICES[sdxl]="0.01"               # Per image
IMAGE_PRICES[sd-3]="0.035"              # Per image

# Video model pricing ($ per second) - 2025 rates
declare -A VIDEO_PRICES
VIDEO_PRICES[veo-3]="0.40"
VIDEO_PRICES[veo-3.1]="0.45"
VIDEO_PRICES[sora-2]="0.35"
VIDEO_PRICES[sora-2-pro]="0.40"
VIDEO_PRICES[kling-2.6-pro]="0.15"
VIDEO_PRICES[kling-o1]="0.20"
VIDEO_PRICES[ltx-video-2]="0.07"
VIDEO_PRICES[minimax-hailuo]="0.10"
VIDEO_PRICES[runway-gen3]="0.12"
VIDEO_PRICES[luma-dream]="0.08"
VIDEO_PRICES[cogvideox]="0.08"

print_usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --type <image|video>   Generation type"
    echo "  --model <name>         Model name"
    echo "  --count <n>            Number of generations per day"
    echo "  --duration <sec>       Video duration in seconds (for video)"
    echo "  --resolution <preset>  Image resolution (square_hd, landscape_16_9, etc.)"
    echo ""
    echo "Image Models: flux-schnell, flux-dev, flux-pro, flux-2-pro, flux-kontext,"
    echo "              gpt-image-1, gpt-image-1.5, recraft-v3, sdxl, sd-3"
    echo ""
    echo "Video Models: veo-3, veo-3.1, sora-2, sora-2-pro, kling-2.6-pro, kling-o1,"
    echo "              ltx-video-2, minimax-hailuo, runway-gen3, luma-dream, cogvideox"
    echo ""
    echo "Examples:"
    echo "  $0 --type image --model flux-pro --count 1000 --resolution landscape_16_9"
    echo "  $0 --type video --model kling-2.6-pro --count 100 --duration 5"
    echo ""
}

# Default values
TYPE=""
MODEL=""
COUNT=0
DURATION=5
RESOLUTION="square_hd"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --type)
            TYPE="$2"
            shift 2
            ;;
        --model)
            MODEL="$2"
            shift 2
            ;;
        --count)
            COUNT="$2"
            shift 2
            ;;
        --duration)
            DURATION="$2"
            shift 2
            ;;
        --resolution)
            RESOLUTION="$2"
            shift 2
            ;;
        --help|-h)
            print_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
done

# Interactive mode if required params missing
if [ -z "$TYPE" ] || [ -z "$MODEL" ] || [ "$COUNT" -eq 0 ]; then
    echo -e "${YELLOW}Interactive mode: Enter workload details${NC}"
    echo ""

    echo "Generation type (image/video):"
    read TYPE

    if [ "$TYPE" = "image" ]; then
        echo ""
        echo "Available image models:"
        echo "  flux-schnell, flux-dev, flux-pro, flux-2-pro, flux-kontext"
        echo "  gpt-image-1, gpt-image-1.5, recraft-v3, sdxl, sd-3"
        echo ""
        echo "Model name:"
        read MODEL

        echo ""
        echo "Resolution (square, square_hd, landscape_16_9, portrait_16_9):"
        read RESOLUTION
        RESOLUTION=${RESOLUTION:-square_hd}
    else
        echo ""
        echo "Available video models:"
        echo "  veo-3, veo-3.1, sora-2, sora-2-pro, kling-2.6-pro, kling-o1"
        echo "  ltx-video-2, minimax-hailuo, runway-gen3, luma-dream, cogvideox"
        echo ""
        echo "Model name:"
        read MODEL

        echo ""
        echo "Video duration in seconds (default: 5):"
        read DURATION
        DURATION=${DURATION:-5}
    fi

    echo ""
    echo "Number of generations per day:"
    read COUNT
fi

echo ""
echo "=== Workload Configuration ==="
echo ""
echo "Type: $TYPE"
echo "Model: $MODEL"
if [ "$TYPE" = "image" ]; then
    echo "Resolution: $RESOLUTION"
else
    echo "Duration: ${DURATION}s"
fi
echo "Daily generations: $COUNT"
echo ""

# Calculate megapixels for resolution
calculate_megapixels() {
    case $1 in
        square)
            echo "0.262144"  # 512x512
            ;;
        square_hd)
            echo "1.048576"  # 1024x1024
            ;;
        landscape_4_3)
            echo "0.786432"  # 1024x768
            ;;
        landscape_16_9)
            echo "0.589824"  # 1024x576
            ;;
        portrait_4_3)
            echo "0.786432"  # 768x1024
            ;;
        portrait_16_9)
            echo "0.589824"  # 576x1024
            ;;
        *)
            echo "1.048576"  # Default to 1MP
            ;;
    esac
}

echo "=== Cost Breakdown ==="
echo ""

if [ "$TYPE" = "image" ]; then
    PRICE=${IMAGE_PRICES[$MODEL]}
    if [ -z "$PRICE" ]; then
        echo -e "${RED}Unknown image model: $MODEL${NC}"
        exit 1
    fi

    # Some models charge per megapixel
    if [ "$MODEL" = "flux-dev" ] || [ "$MODEL" = "flux-pro" ] || [ "$MODEL" = "flux-2-pro" ]; then
        MP=$(calculate_megapixels "$RESOLUTION")
        COST_PER=$(echo "$PRICE * $MP" | bc -l)
        printf "Cost per image (%s): \$%.4f\n" "$RESOLUTION" "$COST_PER"
    else
        COST_PER=$PRICE
        printf "Cost per image: \$%.4f\n" "$COST_PER"
    fi

    DAILY_COST=$(echo "$COST_PER * $COUNT" | bc -l)
else
    PRICE=${VIDEO_PRICES[$MODEL]}
    if [ -z "$PRICE" ]; then
        echo -e "${RED}Unknown video model: $MODEL${NC}"
        exit 1
    fi

    COST_PER=$(echo "$PRICE * $DURATION" | bc -l)
    printf "Cost per video (%ds): \$%.4f\n" "$DURATION" "$COST_PER"

    DAILY_COST=$(echo "$COST_PER * $COUNT" | bc -l)
fi

MONTHLY_COST=$(echo "$DAILY_COST * 30" | bc -l)
YEARLY_COST=$(echo "$DAILY_COST * 365" | bc -l)

echo ""
echo "=== Total Estimated Costs ==="
echo ""
printf "Daily:     \$%.2f\n" "$DAILY_COST"
printf "Monthly:   \$%.2f\n" "$MONTHLY_COST"
printf "Yearly:    \$%.2f\n" "$YEARLY_COST"

if [ "$COUNT" -gt 0 ]; then
    COST_PER_GEN=$(echo "$DAILY_COST / $COUNT" | bc -l)
    echo ""
    printf "Cost per generation: \$%.6f\n" "$COST_PER_GEN"
fi

echo ""
echo "=== Cost Optimization Tips ==="
echo ""

if [ "$TYPE" = "image" ]; then
    if [ "$MODEL" = "flux-pro" ] || [ "$MODEL" = "flux-2-pro" ]; then
        echo "• Use flux-schnell for prototyping (\$0.003/image vs \$0.05/MP)"
    fi
    if [ "$MODEL" = "gpt-image-1.5" ]; then
        echo "• GPT-Image 1 is slightly cheaper if you don't need latest features"
    fi
    echo "• Smaller resolutions (square vs square_hd) reduce megapixel costs"
    echo "• Use flux-schnell for fast iterations, upgrade for final renders"
else
    if [ "$MODEL" = "veo-3" ] || [ "$MODEL" = "veo-3.1" ] || [ "$MODEL" = "sora-2-pro" ]; then
        echo "• Use ltx-video-2 or kling-2.6-pro for prototyping (10-20x cheaper)"
    fi
    echo "• Shorter durations (5s vs 10s) halve costs"
    echo "• Generate images first with FLUX, then animate - often cheaper"
    echo "• Use cheaper models (ltx-video-2) for testing, premium for finals"
fi

echo ""
echo -e "${YELLOW}Note: Actual costs may vary. Check fal.ai/pricing for current rates.${NC}"
echo ""
