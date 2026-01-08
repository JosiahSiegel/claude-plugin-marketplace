#!/bin/bash
# Check Python type hints with mypy or pyright

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=== Python Type Checking ==="
echo ""

# Determine package manager
if command -v uv &> /dev/null; then
    RUN_CMD="uv run"
    echo "Using uv for package management"
elif [ -f ".venv/bin/activate" ]; then
    RUN_CMD=""
    source .venv/bin/activate
    echo "Using virtual environment"
else
    RUN_CMD=""
    echo "Using system Python"
fi

# Find source directory
if [ -d "src" ]; then
    SRC_DIR="src"
elif [ -d "app" ]; then
    SRC_DIR="app"
else
    SRC_DIR="."
fi

echo "Checking directory: $SRC_DIR"
echo ""

# Try mypy first
if $RUN_CMD python -c "import mypy" 2>/dev/null; then
    echo "Running mypy..."
    echo ""

    if $RUN_CMD mypy "$SRC_DIR" --ignore-missing-imports 2>&1; then
        echo ""
        echo -e "${GREEN}No type errors found!${NC}"
    else
        echo ""
        echo -e "${RED}Type errors detected. See above for details.${NC}"
        exit 1
    fi

# Try pyright as fallback
elif command -v pyright &> /dev/null; then
    echo "Running pyright..."
    echo ""

    if pyright "$SRC_DIR" 2>&1; then
        echo ""
        echo -e "${GREEN}No type errors found!${NC}"
    else
        echo ""
        echo -e "${RED}Type errors detected. See above for details.${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}Neither mypy nor pyright found.${NC}"
    echo ""
    echo "Install with:"
    echo "  uv add --dev mypy"
    echo "  # or"
    echo "  pip install mypy"
    exit 1
fi

# Count typed vs untyped functions
echo ""
echo "=== Type Coverage Summary ==="
echo ""

TOTAL_FUNCS=$(grep -r "def " "$SRC_DIR" --include="*.py" 2>/dev/null | wc -l)
TYPED_FUNCS=$(grep -r "def .*->.*:" "$SRC_DIR" --include="*.py" 2>/dev/null | wc -l)

if [ "$TOTAL_FUNCS" -gt 0 ]; then
    COVERAGE=$((TYPED_FUNCS * 100 / TOTAL_FUNCS))
    echo "Functions with return type hints: $TYPED_FUNCS / $TOTAL_FUNCS ($COVERAGE%)"
else
    echo "No functions found to analyze"
fi

# Check for common typing issues
echo ""
echo "=== Typing Best Practices Check ==="
echo ""

# Check for typing imports that could use built-in types
OLD_TYPING=$(grep -r "from typing import.*List\|from typing import.*Dict\|from typing import.*Set\|from typing import.*Tuple" "$SRC_DIR" --include="*.py" 2>/dev/null | wc -l)
if [ "$OLD_TYPING" -gt 0 ]; then
    echo -e "${YELLOW}Found $OLD_TYPING file(s) using deprecated typing.List/Dict/Set/Tuple${NC}"
    echo "  Consider using built-in generics: list[str], dict[str, int], set[int], tuple[int, ...]"
else
    echo -e "${GREEN}Using modern type syntax (no deprecated typing imports)${NC}"
fi

# Check for Optional usage vs union
OPTIONAL_COUNT=$(grep -r "Optional\[" "$SRC_DIR" --include="*.py" 2>/dev/null | wc -l)
if [ "$OPTIONAL_COUNT" -gt 0 ]; then
    echo -e "${YELLOW}Found $OPTIONAL_COUNT Optional[X] usages${NC}"
    echo "  Consider using X | None syntax (Python 3.10+)"
else
    echo -e "${GREEN}Using modern union syntax (X | None)${NC}"
fi

echo ""
echo "Done!"
