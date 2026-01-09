#!/bin/bash
# List available fal.ai models and their capabilities

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

print_usage() {
    echo "Usage: $0 [category]"
    echo ""
    echo "Categories:"
    echo "  image    - Image generation models"
    echo "  video    - Video generation models"
    echo "  audio    - Audio/music generation models"
    echo "  vision   - Vision/understanding models"
    echo "  all      - All models (default)"
    echo ""
}

CATEGORY="${1:-all}"

echo "=== fal.ai Model Catalog (2025) ==="
echo ""

print_image_models() {
    echo -e "${CYAN}=== IMAGE GENERATION ===${NC}"
    echo ""
    printf "%-30s %-15s %-40s\n" "Endpoint" "Price" "Description"
    printf "%-30s %-15s %-40s\n" "--------" "-----" "-----------"
    echo ""

    echo -e "${GREEN}FLUX Models (Black Forest Labs)${NC}"
    printf "%-30s %-15s %-40s\n" "fal-ai/flux/schnell" "\$0.003/img" "Fast 4-step generation"
    printf "%-30s %-15s %-40s\n" "fal-ai/flux/dev" "\$0.025/MP" "High quality 12B model"
    printf "%-30s %-15s %-40s\n" "fal-ai/flux-pro/v1.1" "\$0.05/MP" "Production quality"
    printf "%-30s %-15s %-40s\n" "fal-ai/flux-pro/v1.1-ultra" "\$0.06/MP" "Highest resolution"
    printf "%-30s %-15s %-40s\n" "fal-ai/flux.2-pro" "\$0.05/MP" "Latest FLUX 2.0"
    printf "%-30s %-15s %-40s\n" "fal-ai/flux-kontext" "\$0.03/edit" "Instruction-based editing"
    printf "%-30s %-15s %-40s\n" "fal-ai/flux-lora" "\$0.025/MP" "LoRA fine-tuning support"
    printf "%-30s %-15s %-40s\n" "fal-ai/flux/dev/image-to-image" "\$0.025/MP" "Image-to-image"
    printf "%-30s %-15s %-40s\n" "fal-ai/flux/dev/inpainting" "\$0.025/MP" "Inpainting"
    printf "%-30s %-15s %-40s\n" "fal-ai/flux/dev/controlnet" "\$0.03/MP" "ControlNet support"
    echo ""

    echo -e "${GREEN}OpenAI Models${NC}"
    printf "%-30s %-15s %-40s\n" "fal-ai/gpt-image-1" "\$0.03/img" "GPT-Image 1"
    printf "%-30s %-15s %-40s\n" "fal-ai/gpt-image-1.5" "\$0.04/img" "GPT-Image 1.5 (latest)"
    echo ""

    echo -e "${GREEN}Other Models${NC}"
    printf "%-30s %-15s %-40s\n" "fal-ai/recraft-v3" "\$0.04/img" "Design assets, vector style"
    printf "%-30s %-15s %-40s\n" "fal-ai/stable-diffusion-3" "\$0.035/img" "Stability AI SD3"
    printf "%-30s %-15s %-40s\n" "fal-ai/fast-sdxl" "\$0.01/img" "Fast SDXL inference"
    printf "%-30s %-15s %-40s\n" "fal-ai/aura-flow" "\$0.02/img" "Aura Flow"
    printf "%-30s %-15s %-40s\n" "fal-ai/ideogram-v2" "\$0.04/img" "Ideogram v2"
    echo ""
}

print_video_models() {
    echo -e "${MAGENTA}=== VIDEO GENERATION ===${NC}"
    echo ""
    printf "%-40s %-12s %-10s %-30s\n" "Endpoint" "Price/sec" "Max Dur" "Features"
    printf "%-40s %-12s %-10s %-30s\n" "--------" "---------" "-------" "--------"
    echo ""

    echo -e "${GREEN}Premium Models${NC}"
    printf "%-40s %-12s %-10s %-30s\n" "fal-ai/veo-3" "\$0.40" "8s" "Native audio"
    printf "%-40s %-12s %-10s %-30s\n" "fal-ai/veo-3.1" "\$0.45" "8s" "Native audio, higher quality"
    printf "%-40s %-12s %-10s %-30s\n" "fal-ai/sora-2" "\$0.35" "20s" "Long-form video"
    printf "%-40s %-12s %-10s %-30s\n" "fal-ai/sora-2-pro" "\$0.40" "20s" "Professional quality"
    echo ""

    echo -e "${GREEN}Production Models${NC}"
    printf "%-40s %-12s %-10s %-30s\n" "fal-ai/kling-video/v2.6/pro" "\$0.15" "10s" "Cinematic, native audio"
    printf "%-40s %-12s %-10s %-30s\n" "fal-ai/kling-video/o1" "\$0.20" "5s" "Video editing"
    printf "%-40s %-12s %-10s %-30s\n" "fal-ai/runway/gen3/turbo" "\$0.12" "10s" "Fast iteration"
    printf "%-40s %-12s %-10s %-30s\n" "fal-ai/minimax/video-01" "\$0.10" "6s" "Image-to-video"
    echo ""

    echo -e "${GREEN}Budget Models${NC}"
    printf "%-40s %-12s %-10s %-30s\n" "fal-ai/ltx-video-2-pro" "\$0.07" "5s" "Audio support, cost-effective"
    printf "%-40s %-12s %-10s %-30s\n" "fal-ai/luma-dream-machine" "\$0.08" "5s" "Creative generation"
    printf "%-40s %-12s %-10s %-30s\n" "fal-ai/cogvideox" "\$0.08" "6s" "Open source"
    printf "%-40s %-12s %-10s %-30s\n" "fal-ai/cogvideox-5b" "\$0.07" "6s" "Open source 5B"
    echo ""

    echo -e "${GREEN}Image-to-Video Endpoints${NC}"
    printf "%-40s %-12s %-10s %-30s\n" "fal-ai/kling-video/v2.6/pro/image-to-video" "\$0.15" "10s" "Animate images"
    printf "%-40s %-12s %-10s %-30s\n" "fal-ai/minimax/video-01/image-to-video" "\$0.10" "6s" "Image animation"
    printf "%-40s %-12s %-10s %-30s\n" "fal-ai/luma-dream-machine/image-to-video" "\$0.08" "5s" "Image animation"
    echo ""
}

print_audio_models() {
    echo -e "${YELLOW}=== AUDIO/MUSIC GENERATION ===${NC}"
    echo ""
    printf "%-35s %-15s %-40s\n" "Endpoint" "Price" "Description"
    printf "%-35s %-15s %-40s\n" "--------" "-----" "-----------"
    echo ""

    printf "%-35s %-15s %-40s\n" "fal-ai/stable-audio" "\$0.02/sec" "Music/audio generation"
    printf "%-35s %-15s %-40s\n" "fal-ai/audiogen" "\$0.01/sec" "Audio effects"
    printf "%-35s %-15s %-40s\n" "fal-ai/musicgen-large" "\$0.01/sec" "Music generation"
    printf "%-35s %-15s %-40s\n" "fal-ai/whisper" "\$0.0001/sec" "Speech-to-text"
    printf "%-35s %-15s %-40s\n" "fal-ai/tortoise-tts" "\$0.01/sec" "Text-to-speech"
    echo ""
}

print_vision_models() {
    echo -e "${BLUE}=== VISION/UNDERSTANDING ===${NC}"
    echo ""
    printf "%-35s %-15s %-40s\n" "Endpoint" "Price" "Description"
    printf "%-35s %-15s %-40s\n" "--------" "-----" "-----------"
    echo ""

    printf "%-35s %-15s %-40s\n" "fal-ai/llava-next" "\$0.001/query" "Vision-language model"
    printf "%-35s %-15s %-40s\n" "fal-ai/moondream" "\$0.0005/query" "Lightweight vision model"
    printf "%-35s %-15s %-40s\n" "fal-ai/face-to-sticker" "\$0.01/img" "Face to sticker"
    printf "%-35s %-15s %-40s\n" "fal-ai/remove-background" "\$0.005/img" "Background removal"
    printf "%-35s %-15s %-40s\n" "fal-ai/imageutils/depth" "\$0.005/img" "Depth estimation"
    printf "%-35s %-15s %-40s\n" "fal-ai/image-to-3d" "\$0.10/model" "Image to 3D model"
    echo ""
}

case $CATEGORY in
    image)
        print_image_models
        ;;
    video)
        print_video_models
        ;;
    audio)
        print_audio_models
        ;;
    vision)
        print_vision_models
        ;;
    all)
        print_image_models
        print_video_models
        print_audio_models
        print_vision_models
        ;;
    -h|--help)
        print_usage
        exit 0
        ;;
    *)
        echo "Unknown category: $CATEGORY"
        print_usage
        exit 1
        ;;
esac

echo "=== Notes ==="
echo ""
echo "• Prices are approximate and may vary. Check fal.ai/pricing for current rates"
echo "• MP = megapixel (1024x1024 = 1.05MP)"
echo "• Most models support subscribe() for queue-based execution"
echo "• Premium models may have limited availability"
echo ""
echo "Model Explorer: https://fal.ai/models"
echo "Documentation: https://docs.fal.ai"
echo ""
