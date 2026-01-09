#!/bin/bash
# Validate a Modal application before deployment

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=== Modal App Validator ==="
echo ""

# Check for file argument
if [ -z "$1" ]; then
    echo "Usage: $0 <modal_app.py> [function_name]"
    echo ""
    echo "Examples:"
    echo "  $0 app.py"
    echo "  $0 app.py::my_function"
    exit 1
fi

APP_FILE="$1"
FUNCTION_NAME="${2:-}"

if [ ! -f "$APP_FILE" ]; then
    echo -e "${RED}Error: File not found: $APP_FILE${NC}"
    exit 1
fi

echo "Validating: $APP_FILE"
echo ""

# Check Modal CLI
if ! command -v modal &> /dev/null; then
    echo -e "${RED}✗ Modal CLI not installed${NC}"
    echo "Install with: pip install modal"
    exit 1
fi
echo -e "${GREEN}✓ Modal CLI installed${NC}"

# Check authentication
if ! modal token info &> /dev/null 2>&1; then
    echo -e "${RED}✗ Not authenticated with Modal${NC}"
    echo "Run: modal setup"
    exit 1
fi
echo -e "${GREEN}✓ Modal authentication valid${NC}"

# Validate Python syntax
echo ""
echo "=== Syntax Validation ==="
if python -m py_compile "$APP_FILE" 2>/dev/null; then
    echo -e "${GREEN}✓ Python syntax valid${NC}"
else
    echo -e "${RED}✗ Python syntax error${NC}"
    python -m py_compile "$APP_FILE"
    exit 1
fi

# Check for Modal imports
echo ""
echo "=== Import Validation ==="
if grep -q "import modal" "$APP_FILE"; then
    echo -e "${GREEN}✓ Modal import found${NC}"
else
    echo -e "${YELLOW}⚠ No 'import modal' found${NC}"
fi

# Check for app definition
if grep -qE "app\s*=\s*modal\.App" "$APP_FILE"; then
    APP_NAME=$(grep -oE 'modal\.App\(["\x27]([^"\x27]+)["\x27]\)' "$APP_FILE" | head -1 | sed -E 's/modal\.App\(["\x27]([^"\x27]+)["\x27]\)/\1/')
    echo -e "${GREEN}✓ Modal App defined: $APP_NAME${NC}"
else
    echo -e "${YELLOW}⚠ No Modal App definition found${NC}"
fi

# Check for decorated functions
echo ""
echo "=== Function Analysis ==="

FUNCTION_COUNT=$(grep -c "@app\.function\|@app\.cls" "$APP_FILE" || echo "0")
echo "Functions/Classes: $FUNCTION_COUNT"

# Check for GPU usage
if grep -qE "gpu\s*=" "$APP_FILE"; then
    GPU_TYPES=$(grep -oE 'gpu\s*=\s*["\x27]?[A-Z0-9-]+["\x27]?' "$APP_FILE" | head -3)
    echo -e "${BLUE}GPU configuration found:${NC}"
    echo "$GPU_TYPES" | sed 's/^/  /'
fi

# Check for secrets
if grep -q "Secret.from_name" "$APP_FILE"; then
    SECRETS=$(grep -oE 'Secret\.from_name\(["\x27]([^"\x27]+)["\x27]\)' "$APP_FILE" | sed -E 's/Secret\.from_name\(["\x27]([^"\x27]+)["\x27]\)/\1/' | sort -u)
    echo -e "${BLUE}Secrets required:${NC}"
    for secret in $SECRETS; do
        # Check if secret exists
        if modal secret list 2>/dev/null | grep -q "$secret"; then
            echo -e "  ${GREEN}✓ $secret${NC}"
        else
            echo -e "  ${RED}✗ $secret (not found)${NC}"
        fi
    done
fi

# Check for volumes
if grep -q "Volume.from_name" "$APP_FILE"; then
    VOLUMES=$(grep -oE 'Volume\.from_name\(["\x27]([^"\x27]+)["\x27]' "$APP_FILE" | sed -E 's/Volume\.from_name\(["\x27]([^"\x27]+)["\x27]/\1/' | sort -u)
    echo -e "${BLUE}Volumes required:${NC}"
    for vol in $VOLUMES; do
        if modal volume list 2>/dev/null | grep -q "$vol"; then
            echo -e "  ${GREEN}✓ $vol${NC}"
        else
            # Check if create_if_missing is used
            if grep -q "create_if_missing=True" "$APP_FILE"; then
                echo -e "  ${YELLOW}○ $vol (will be created)${NC}"
            else
                echo -e "  ${RED}✗ $vol (not found)${NC}"
            fi
        fi
    done
fi

# Check for web endpoints
echo ""
echo "=== Endpoint Analysis ==="
if grep -qE "@modal\.(asgi_app|wsgi_app|fastapi_endpoint|web_server)" "$APP_FILE"; then
    echo -e "${GREEN}Web endpoint detected${NC}"

    if grep -q "asgi_app" "$APP_FILE"; then
        echo "  Type: ASGI (FastAPI/Starlette)"
    elif grep -q "wsgi_app" "$APP_FILE"; then
        echo "  Type: WSGI (Flask/Django)"
    elif grep -q "fastapi_endpoint" "$APP_FILE"; then
        echo "  Type: FastAPI Endpoint"
    elif grep -q "web_server" "$APP_FILE"; then
        echo "  Type: Custom Web Server"
    fi

    if grep -q "custom_domains" "$APP_FILE"; then
        DOMAINS=$(grep -oE 'custom_domains\s*=\s*\[[^\]]+\]' "$APP_FILE")
        echo "  Custom domains: $DOMAINS"
    fi
else
    echo "No web endpoints found"
fi

# Check for scheduling
if grep -qE "modal\.(Cron|Period)" "$APP_FILE"; then
    echo ""
    echo "=== Schedule Analysis ==="
    echo -e "${GREEN}Scheduled functions detected${NC}"
    grep -oE 'modal\.(Cron|Period)\([^)]+\)' "$APP_FILE" | head -5 | sed 's/^/  /'
    echo ""
    echo -e "${YELLOW}Note: Scheduled functions only run with 'modal deploy'${NC}"
fi

# Dry run test
echo ""
echo "=== Dry Run Test ==="
echo "Attempting to load the app..."

if [ -n "$FUNCTION_NAME" ]; then
    TARGET="$APP_FILE::$FUNCTION_NAME"
else
    TARGET="$APP_FILE"
fi

# Try to import and validate
python -c "
import sys
sys.path.insert(0, '.')
import importlib.util
spec = importlib.util.spec_from_file_location('app', '$APP_FILE')
module = importlib.util.module_from_spec(spec)
try:
    spec.loader.exec_module(module)
    print('Module loaded successfully')
except Exception as e:
    print(f'Load error: {e}')
    sys.exit(1)
" 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ App loads successfully${NC}"
else
    echo -e "${RED}✗ App failed to load${NC}"
    exit 1
fi

echo ""
echo "=== Summary ==="
echo ""
echo -e "${GREEN}Validation complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Test locally:  modal run $APP_FILE"
echo "  2. Dev server:    modal serve $APP_FILE"
echo "  3. Deploy:        modal deploy $APP_FILE"
echo ""
