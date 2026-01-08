#!/bin/bash
# Analyze Python test coverage and identify untested code

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=== Python Test Coverage Analysis ==="
echo ""

# Determine source directory
if [ -d "src" ]; then
    SRC_DIR="src"
elif [ -d "app" ]; then
    SRC_DIR="app"
else
    SRC_DIR="."
fi

# Determine package manager
if command -v uv &> /dev/null; then
    RUN_CMD="uv run"
elif [ -f ".venv/bin/activate" ]; then
    RUN_CMD=""
    source .venv/bin/activate
else
    RUN_CMD=""
fi

# Check if pytest-cov is available
if ! $RUN_CMD python -c "import pytest_cov" 2>/dev/null; then
    echo -e "${YELLOW}pytest-cov not installed${NC}"
    echo "Install with: uv add --dev pytest-cov"
    echo ""
    echo "Running tests without coverage..."
    $RUN_CMD pytest -v
    exit 0
fi

# Run tests with coverage
echo "Running tests with coverage..."
echo ""

$RUN_CMD pytest --cov="$SRC_DIR" --cov-report=term-missing --cov-report=html -v 2>&1 || true

echo ""
echo "=== Coverage Summary ==="
echo ""

# Parse coverage data if available
if [ -f ".coverage" ]; then
    # Show files with low coverage
    echo "Files with low coverage (<80%):"
    echo ""

    $RUN_CMD coverage report --fail-under=0 2>/dev/null | \
        grep -E "^[a-zA-Z_/].*[0-9]+%" | \
        while read line; do
            coverage=$(echo "$line" | grep -oE "[0-9]+%" | tail -1 | tr -d '%')
            if [ -n "$coverage" ] && [ "$coverage" -lt 80 ]; then
                echo -e "${YELLOW}$line${NC}"
            fi
        done || echo "Could not parse coverage data"

    echo ""

    # Show totally uncovered files
    echo "Completely uncovered files (0%):"
    $RUN_CMD coverage report --fail-under=0 2>/dev/null | \
        grep -E "^[a-zA-Z_/].*0%" | \
        while read line; do
            echo -e "${RED}$line${NC}"
        done || echo "None found"
fi

echo ""

# Check test to code ratio
echo "=== Test Analysis ==="
echo ""

TEST_FILES=$(find tests -name "test_*.py" 2>/dev/null | wc -l)
TEST_FUNCS=$(grep -r "def test_" tests --include="*.py" 2>/dev/null | wc -l)
SRC_FILES=$(find "$SRC_DIR" -name "*.py" ! -name "__init__.py" 2>/dev/null | wc -l)
SRC_FUNCS=$(grep -r "def " "$SRC_DIR" --include="*.py" 2>/dev/null | grep -v "def __" | wc -l)

echo "Test files: $TEST_FILES"
echo "Test functions: $TEST_FUNCS"
echo "Source files: $SRC_FILES"
echo "Source functions: $SRC_FUNCS"

if [ "$SRC_FUNCS" -gt 0 ]; then
    RATIO=$(echo "scale=2; $TEST_FUNCS / $SRC_FUNCS" | bc 2>/dev/null || echo "N/A")
    echo "Test to function ratio: $RATIO"
fi

echo ""

# Check for missing test files
echo "=== Missing Tests ==="
echo ""

echo "Source files without corresponding test files:"
for src_file in $(find "$SRC_DIR" -name "*.py" ! -name "__init__.py" 2>/dev/null); do
    base_name=$(basename "$src_file" .py)
    if [ "$base_name" != "__init__" ]; then
        test_file="tests/test_${base_name}.py"
        if [ ! -f "$test_file" ]; then
            echo -e "${YELLOW}  Missing: $test_file (for $src_file)${NC}"
        fi
    fi
done

echo ""

# HTML report location
if [ -d "htmlcov" ]; then
    echo -e "${GREEN}HTML coverage report generated: htmlcov/index.html${NC}"
fi

echo ""
echo "Done!"
