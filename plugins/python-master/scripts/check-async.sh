#!/bin/bash
# Analyze async patterns and detect common async/await issues

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=== Python Async Pattern Analysis ==="
echo ""

# Determine source directory
if [ -d "src" ]; then
    SRC_DIR="src"
elif [ -d "app" ]; then
    SRC_DIR="app"
else
    SRC_DIR="."
fi

echo "Analyzing directory: $SRC_DIR"
echo ""

# Count async functions
ASYNC_FUNCS=$(grep -r "async def " "$SRC_DIR" --include="*.py" 2>/dev/null | wc -l)
SYNC_FUNCS=$(grep -r "^def \|^    def " "$SRC_DIR" --include="*.py" 2>/dev/null | grep -v "async def" | wc -l)

echo "=== Function Statistics ==="
echo "Async functions: $ASYNC_FUNCS"
echo "Sync functions: $SYNC_FUNCS"
echo ""

# Check for common async issues
echo "=== Potential Issues ==="
echo ""

# 1. Blocking calls in async code
echo "Checking for blocking calls in async functions..."

BLOCKING_PATTERNS=(
    "time.sleep"
    "requests\."
    "urllib\."
    "open("
)

for pattern in "${BLOCKING_PATTERNS[@]}"; do
    matches=$(grep -rn "async def" "$SRC_DIR" --include="*.py" -A 20 2>/dev/null | grep -E "$pattern" || true)
    if [ -n "$matches" ]; then
        echo -e "${YELLOW}Potential blocking call: $pattern${NC}"
        echo "$matches" | head -5
        echo ""
    fi
done

# 2. Missing await
echo "Checking for potentially missing await..."

# Find async function calls without await
ASYNC_CALLS=$(grep -rn "= [a-zA-Z_]*(" "$SRC_DIR" --include="*.py" 2>/dev/null | \
    grep -v "await" | \
    grep -v "def " | \
    grep -v "class " | \
    grep -v "lambda" | \
    grep -v "# " || true)

# This is a heuristic check - not all will be actual issues
echo -e "${BLUE}Note: Review these lines for potentially missing await:${NC}"
echo "$ASYNC_CALLS" | head -10
echo ""

# 3. Check for create_task without await
echo "Checking for untracked tasks..."
UNTRACKED_TASKS=$(grep -rn "asyncio.create_task" "$SRC_DIR" --include="*.py" 2>/dev/null | \
    grep -v "await" | \
    grep -v "task =" | \
    grep -v "tasks" || true)

if [ -n "$UNTRACKED_TASKS" ]; then
    echo -e "${YELLOW}Potentially untracked tasks (fire-and-forget):${NC}"
    echo "$UNTRACKED_TASKS"
    echo ""
else
    echo -e "${GREEN}No untracked tasks found${NC}"
fi
echo ""

# 4. Check for asyncio.gather usage
echo "=== Async Patterns Used ==="
echo ""

GATHER_COUNT=$(grep -r "asyncio.gather" "$SRC_DIR" --include="*.py" 2>/dev/null | wc -l)
TASKGROUP_COUNT=$(grep -r "asyncio.TaskGroup" "$SRC_DIR" --include="*.py" 2>/dev/null | wc -l)
SEMAPHORE_COUNT=$(grep -r "asyncio.Semaphore" "$SRC_DIR" --include="*.py" 2>/dev/null | wc -l)
TIMEOUT_COUNT=$(grep -r "asyncio.timeout\|asyncio.wait_for" "$SRC_DIR" --include="*.py" 2>/dev/null | wc -l)
QUEUE_COUNT=$(grep -r "asyncio.Queue" "$SRC_DIR" --include="*.py" 2>/dev/null | wc -l)

echo "asyncio.gather usage: $GATHER_COUNT"
echo "asyncio.TaskGroup usage: $TASKGROUP_COUNT"
echo "asyncio.Semaphore usage: $SEMAPHORE_COUNT"
echo "Timeout handling: $TIMEOUT_COUNT"
echo "asyncio.Queue usage: $QUEUE_COUNT"
echo ""

# Recommendations
echo "=== Recommendations ==="
echo ""

if [ "$ASYNC_FUNCS" -gt 0 ] && [ "$TASKGROUP_COUNT" -eq 0 ]; then
    echo -e "${BLUE}Consider using TaskGroup (Python 3.11+) for structured concurrency${NC}"
fi

if [ "$ASYNC_FUNCS" -gt 5 ] && [ "$SEMAPHORE_COUNT" -eq 0 ]; then
    echo -e "${BLUE}Consider using Semaphores for rate limiting concurrent operations${NC}"
fi

if [ "$TIMEOUT_COUNT" -eq 0 ] && [ "$ASYNC_FUNCS" -gt 0 ]; then
    echo -e "${YELLOW}No timeout handling found - consider adding asyncio.timeout()${NC}"
fi

# Check for async HTTP client usage
HTTPX_COUNT=$(grep -r "httpx" "$SRC_DIR" --include="*.py" 2>/dev/null | wc -l)
AIOHTTP_COUNT=$(grep -r "aiohttp" "$SRC_DIR" --include="*.py" 2>/dev/null | wc -l)
REQUESTS_COUNT=$(grep -r "import requests\|from requests" "$SRC_DIR" --include="*.py" 2>/dev/null | wc -l)

if [ "$REQUESTS_COUNT" -gt 0 ] && [ "$ASYNC_FUNCS" -gt 0 ]; then
    echo -e "${YELLOW}Using sync 'requests' library with async code - consider httpx or aiohttp${NC}"
fi

echo ""
echo "Done!"
