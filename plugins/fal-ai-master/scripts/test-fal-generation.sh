#!/bin/bash
# Test fal.ai image/video generation endpoints

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "=== fal.ai Generation Test ==="
echo ""

# Check authentication
if [ -z "$FAL_KEY" ]; then
    echo -e "${RED}Error: FAL_KEY environment variable not set${NC}"
    echo "Set it with: export FAL_KEY='your-api-key'"
    exit 1
fi

print_usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --model <endpoint>     Model endpoint (default: fal-ai/flux/schnell)"
    echo "  --prompt <text>        Generation prompt"
    echo "  --output <file>        Save result URL to file"
    echo "  --download             Download the generated file"
    echo "  --type <image|video>   Content type (default: image)"
    echo ""
    echo "Examples:"
    echo "  $0 --prompt 'A sunset over mountains'"
    echo "  $0 --model fal-ai/flux/dev --prompt 'Abstract art'"
    echo "  $0 --type video --model fal-ai/kling-video/v2.6/pro --prompt 'Ocean waves'"
    echo ""
}

# Defaults
MODEL="fal-ai/flux/schnell"
PROMPT="A beautiful sunset over mountains, photorealistic"
OUTPUT=""
DOWNLOAD=false
TYPE="image"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --model)
            MODEL="$2"
            shift 2
            ;;
        --prompt)
            PROMPT="$2"
            shift 2
            ;;
        --output)
            OUTPUT="$2"
            shift 2
            ;;
        --download)
            DOWNLOAD=true
            shift
            ;;
        --type)
            TYPE="$2"
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

echo "Model: $MODEL"
echo "Prompt: $PROMPT"
echo "Type: $TYPE"
echo ""

# Build request payload
if [ "$TYPE" = "image" ]; then
    PAYLOAD=$(cat <<EOF
{
    "prompt": "$PROMPT",
    "image_size": "landscape_16_9",
    "num_inference_steps": 4,
    "num_images": 1
}
EOF
)
else
    PAYLOAD=$(cat <<EOF
{
    "prompt": "$PROMPT",
    "duration": 5,
    "aspect_ratio": "16:9"
}
EOF
)
fi

echo "=== Sending Request ==="
echo ""

# Submit to queue
echo "Submitting to queue..."
SUBMIT_RESPONSE=$(curl -s -X POST \
    "https://queue.fal.run/$MODEL" \
    -H "Authorization: Key $FAL_KEY" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD")

REQUEST_ID=$(echo "$SUBMIT_RESPONSE" | grep -o '"request_id":"[^"]*"' | cut -d'"' -f4)

if [ -z "$REQUEST_ID" ]; then
    echo -e "${RED}Failed to submit request${NC}"
    echo "Response: $SUBMIT_RESPONSE"
    exit 1
fi

echo "Request ID: $REQUEST_ID"
echo ""

# Poll for status
echo "=== Waiting for Result ==="
echo ""

MAX_WAIT=300  # 5 minutes
WAITED=0
POLL_INTERVAL=2

while [ $WAITED -lt $MAX_WAIT ]; do
    STATUS_RESPONSE=$(curl -s \
        "https://queue.fal.run/$MODEL/requests/$REQUEST_ID/status" \
        -H "Authorization: Key $FAL_KEY")

    STATUS=$(echo "$STATUS_RESPONSE" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)

    case $STATUS in
        COMPLETED)
            echo -e "${GREEN}✓ Generation completed!${NC}"
            break
            ;;
        FAILED)
            echo -e "${RED}✗ Generation failed${NC}"
            echo "Response: $STATUS_RESPONSE"
            exit 1
            ;;
        IN_QUEUE)
            echo -ne "\rStatus: In queue... (${WAITED}s)"
            ;;
        IN_PROGRESS)
            echo -ne "\rStatus: Generating... (${WAITED}s)"
            ;;
        *)
            echo -ne "\rStatus: $STATUS (${WAITED}s)"
            ;;
    esac

    sleep $POLL_INTERVAL
    WAITED=$((WAITED + POLL_INTERVAL))
done

if [ $WAITED -ge $MAX_WAIT ]; then
    echo -e "${RED}Timeout waiting for generation${NC}"
    exit 1
fi

echo ""
echo ""

# Get result
echo "=== Fetching Result ==="
echo ""

RESULT_RESPONSE=$(curl -s \
    "https://queue.fal.run/$MODEL/requests/$REQUEST_ID" \
    -H "Authorization: Key $FAL_KEY")

if [ "$TYPE" = "image" ]; then
    RESULT_URL=$(echo "$RESULT_RESPONSE" | grep -o '"url":"[^"]*"' | head -1 | cut -d'"' -f4)
else
    RESULT_URL=$(echo "$RESULT_RESPONSE" | grep -o '"url":"[^"]*"' | head -1 | cut -d'"' -f4)
fi

if [ -z "$RESULT_URL" ]; then
    echo -e "${YELLOW}Could not extract URL from response${NC}"
    echo "Full response:"
    echo "$RESULT_RESPONSE"
else
    echo -e "${GREEN}Result URL:${NC}"
    echo "$RESULT_URL"
    echo ""

    # Save to file if requested
    if [ -n "$OUTPUT" ]; then
        echo "$RESULT_URL" > "$OUTPUT"
        echo "URL saved to: $OUTPUT"
    fi

    # Download if requested
    if [ "$DOWNLOAD" = true ]; then
        if [ "$TYPE" = "image" ]; then
            EXT="png"
        else
            EXT="mp4"
        fi
        FILENAME="fal_output_$(date +%s).$EXT"
        echo "Downloading to $FILENAME..."
        curl -s -o "$FILENAME" "$RESULT_URL"
        echo -e "${GREEN}✓ Downloaded: $FILENAME${NC}"
    fi
fi

echo ""
echo "=== Test Complete ==="
echo ""
