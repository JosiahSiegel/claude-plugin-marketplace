#!/bin/bash
# Analyze Python dependencies and check for issues

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=== Python Dependency Analysis ==="
echo ""

# Check for pyproject.toml
if [ -f "pyproject.toml" ]; then
    echo -e "${GREEN}Found pyproject.toml${NC}"

    # Extract project info
    PROJECT_NAME=$(grep -E "^name = " pyproject.toml | head -1 | sed 's/name = "\(.*\)"/\1/')
    PROJECT_VERSION=$(grep -E "^version = " pyproject.toml | head -1 | sed 's/version = "\(.*\)"/\1/')
    PYTHON_REQ=$(grep -E "^requires-python" pyproject.toml | sed 's/requires-python = "\(.*\)"/\1/')

    echo "  Project: $PROJECT_NAME"
    echo "  Version: $PROJECT_VERSION"
    echo "  Python: $PYTHON_REQ"
    echo ""
elif [ -f "setup.py" ]; then
    echo -e "${YELLOW}Found setup.py (consider migrating to pyproject.toml)${NC}"
    echo ""
elif [ -f "requirements.txt" ]; then
    echo -e "${YELLOW}Found requirements.txt (consider migrating to pyproject.toml)${NC}"
    echo ""
else
    echo -e "${RED}No Python project configuration found${NC}"
    exit 1
fi

# Check package manager
echo "=== Package Manager ==="
echo ""

if [ -f "uv.lock" ]; then
    echo -e "${GREEN}Using uv (recommended)${NC}"

    # Count dependencies
    DEP_COUNT=$(grep -c "^\[\[package\]\]" uv.lock 2>/dev/null || echo "0")
    echo "  Total packages: $DEP_COUNT"
elif [ -f "poetry.lock" ]; then
    echo -e "${BLUE}Using Poetry${NC}"

    DEP_COUNT=$(grep -c "^\[\[package\]\]" poetry.lock 2>/dev/null || echo "0")
    echo "  Total packages: $DEP_COUNT"
elif [ -f "Pipfile.lock" ]; then
    echo -e "${BLUE}Using Pipenv${NC}"
elif [ -f "requirements.txt" ]; then
    echo "Using pip with requirements.txt"
    DEP_COUNT=$(grep -v "^#" requirements.txt | grep -v "^$" | wc -l)
    echo "  Direct dependencies: $DEP_COUNT"
fi

echo ""

# Check for security vulnerabilities (if pip-audit is available)
echo "=== Security Check ==="
echo ""

if command -v uv &> /dev/null; then
    if uv run pip-audit --version &> /dev/null 2>&1; then
        echo "Running pip-audit..."
        if uv run pip-audit 2>&1; then
            echo -e "${GREEN}No known vulnerabilities found${NC}"
        else
            echo -e "${RED}Vulnerabilities detected! See above for details.${NC}"
        fi
    else
        echo -e "${YELLOW}pip-audit not installed. Install with: uv add --dev pip-audit${NC}"
    fi
elif command -v pip-audit &> /dev/null; then
    echo "Running pip-audit..."
    if pip-audit 2>&1; then
        echo -e "${GREEN}No known vulnerabilities found${NC}"
    else
        echo -e "${RED}Vulnerabilities detected! See above for details.${NC}"
    fi
else
    echo -e "${YELLOW}pip-audit not available. Install with: pip install pip-audit${NC}"
fi

echo ""

# Check for outdated packages
echo "=== Outdated Packages ==="
echo ""

if command -v uv &> /dev/null; then
    echo "Checking for outdated packages..."
    uv pip list --outdated 2>/dev/null || echo "Could not check outdated packages"
elif [ -f ".venv/bin/pip" ]; then
    .venv/bin/pip list --outdated 2>/dev/null || echo "Could not check outdated packages"
else
    pip list --outdated 2>/dev/null || echo "Could not check outdated packages"
fi

echo ""

# Analyze imports
echo "=== Import Analysis ==="
echo ""

if [ -d "src" ]; then
    SRC_DIR="src"
elif [ -d "app" ]; then
    SRC_DIR="app"
else
    SRC_DIR="."
fi

# Find all third-party imports
echo "Third-party packages used in code:"
grep -rh "^import \|^from " "$SRC_DIR" --include="*.py" 2>/dev/null | \
    sed 's/^import \([a-zA-Z_][a-zA-Z0-9_]*\).*/\1/' | \
    sed 's/^from \([a-zA-Z_][a-zA-Z0-9_]*\).*/\1/' | \
    sort | uniq -c | sort -rn | head -20 || echo "No imports found"

echo ""
echo "Done!"
