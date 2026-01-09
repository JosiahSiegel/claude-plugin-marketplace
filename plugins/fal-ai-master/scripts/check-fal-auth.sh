#!/bin/bash
# Check fal.ai authentication and API key status

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=== fal.ai Authentication Check ==="
echo ""

# Check if FAL_KEY is set
if [ -z "$FAL_KEY" ]; then
    echo -e "${RED}✗ FAL_KEY environment variable is not set${NC}"
    echo ""
    echo "To set your API key:"
    echo "  export FAL_KEY='your-api-key'"
    echo ""
    echo "Get your API key at: https://fal.ai/dashboard/keys"
    exit 1
fi

echo -e "${GREEN}✓ FAL_KEY environment variable is set${NC}"

# Check key format
KEY_PREFIX="${FAL_KEY:0:4}"
if [ "$KEY_PREFIX" != "fal_" ]; then
    echo -e "${YELLOW}⚠ API key doesn't start with 'fal_' - verify it's correct${NC}"
else
    echo -e "${GREEN}✓ API key format looks valid${NC}"
fi

echo ""
echo "=== Testing API Connection ==="
echo ""

# Test with a minimal API call
echo "Testing connection to fal.ai..."

RESPONSE=$(curl -s -w "\n%{http_code}" \
    -H "Authorization: Key $FAL_KEY" \
    -H "Content-Type: application/json" \
    "https://fal.run/fal-ai/flux/schnell" \
    -d '{"prompt":"test","image_size":"square","num_inference_steps":1}' \
    2>/dev/null || echo "000")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | head -n -1)

case $HTTP_CODE in
    200)
        echo -e "${GREEN}✓ API connection successful${NC}"
        echo -e "${GREEN}✓ Authentication verified${NC}"
        echo ""
        echo "Your API key is working correctly!"
        ;;
    401)
        echo -e "${RED}✗ Authentication failed (401)${NC}"
        echo ""
        echo "Your API key is invalid or expired."
        echo "Get a new key at: https://fal.ai/dashboard/keys"
        exit 1
        ;;
    402)
        echo -e "${YELLOW}⚠ Payment required (402)${NC}"
        echo ""
        echo "Your API key is valid but you may need to add credits."
        echo "Check your balance at: https://fal.ai/dashboard/billing"
        ;;
    403)
        echo -e "${RED}✗ Access forbidden (403)${NC}"
        echo ""
        echo "Your API key doesn't have access to this resource."
        echo "Check your API key permissions."
        exit 1
        ;;
    429)
        echo -e "${YELLOW}⚠ Rate limited (429)${NC}"
        echo ""
        echo "API key is valid but you're being rate limited."
        echo "Wait a moment and try again."
        ;;
    000)
        echo -e "${RED}✗ Connection failed${NC}"
        echo ""
        echo "Could not connect to fal.ai. Check your internet connection."
        exit 1
        ;;
    *)
        echo -e "${YELLOW}⚠ Unexpected response: $HTTP_CODE${NC}"
        echo "Response: $BODY"
        ;;
esac

echo ""
echo "=== SDK Check ==="
echo ""

# Check JavaScript SDK
if command -v npm &> /dev/null; then
    if npm list @fal-ai/client 2>/dev/null | grep -q "@fal-ai/client"; then
        FAL_VERSION=$(npm list @fal-ai/client 2>/dev/null | grep "@fal-ai/client" | head -1 | sed 's/.*@fal-ai\/client@//')
        echo -e "${GREEN}✓ @fal-ai/client installed: $FAL_VERSION${NC}"
    else
        echo -e "${YELLOW}○ @fal-ai/client not installed${NC}"
        echo "  Install with: npm install @fal-ai/client"
    fi
else
    echo "○ npm not found, skipping JS SDK check"
fi

# Check Python SDK
if command -v pip &> /dev/null; then
    if pip show fal-client &> /dev/null; then
        FAL_PY_VERSION=$(pip show fal-client 2>/dev/null | grep "Version:" | cut -d' ' -f2)
        echo -e "${GREEN}✓ fal-client (Python) installed: $FAL_PY_VERSION${NC}"
    else
        echo -e "${YELLOW}○ fal-client (Python) not installed${NC}"
        echo "  Install with: pip install fal-client"
    fi
else
    echo "○ pip not found, skipping Python SDK check"
fi

# Check fal CLI
if command -v fal &> /dev/null; then
    echo -e "${GREEN}✓ fal CLI installed${NC}"
else
    echo -e "${YELLOW}○ fal CLI not installed${NC}"
    echo "  Install with: pip install fal"
fi

echo ""
echo "=== Quick Start ==="
echo ""
echo "JavaScript:"
echo '  import { fal } from "@fal-ai/client";'
echo '  fal.config({ credentials: process.env.FAL_KEY });'
echo ""
echo "Python:"
echo '  import fal_client'
echo '  # Uses FAL_KEY from environment automatically'
echo ""
echo "cURL:"
echo '  curl -H "Authorization: Key $FAL_KEY" https://fal.run/fal-ai/flux/schnell'
echo ""
