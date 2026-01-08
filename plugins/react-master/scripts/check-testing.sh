#!/bin/bash
# React Testing Coverage Analyzer
# Analyzes test coverage and testing patterns in your React project
#
# Usage: ./check-testing.sh [project-path]
#
# This script checks:
# - Test file organization
# - Testing library usage
# - Component test coverage
# - Testing patterns

set -e

PROJECT_PATH="${1:-.}"
SRC_DIR="$PROJECT_PATH/src"

if [ ! -d "$SRC_DIR" ]; then
    SRC_DIR="$PROJECT_PATH"
fi

echo "=== React Testing Analysis ==="
echo "Scanning: $SRC_DIR"
echo ""

# Detect testing framework
echo "=== Testing Framework Detection ==="
echo ""

if grep -q "vitest" "$PROJECT_PATH/package.json" 2>/dev/null; then
    echo "✓ Vitest detected"
    FRAMEWORK="vitest"
elif grep -q "jest" "$PROJECT_PATH/package.json" 2>/dev/null; then
    echo "✓ Jest detected"
    FRAMEWORK="jest"
else
    echo "⚠️  No testing framework detected"
    echo "   Recommended: Vitest (modern) or Jest"
    FRAMEWORK="none"
fi

# Check for React Testing Library
if grep -q "@testing-library/react" "$PROJECT_PATH/package.json" 2>/dev/null; then
    echo "✓ React Testing Library detected"
else
    echo "⚠️  React Testing Library not found"
    echo "   Install: npm add -D @testing-library/react @testing-library/jest-dom"
fi

# Check for user-event
if grep -q "@testing-library/user-event" "$PROJECT_PATH/package.json" 2>/dev/null; then
    echo "✓ @testing-library/user-event detected"
else
    echo "⚠️  @testing-library/user-event not found"
    echo "   Install: npm add -D @testing-library/user-event"
fi

echo ""

# Count test files
echo "=== Test File Summary ==="
echo ""

TEST_FILES=$(find "$SRC_DIR" -name "*.test.tsx" -o -name "*.test.ts" -o -name "*.test.jsx" -o -name "*.test.js" -o -name "*.spec.tsx" -o -name "*.spec.ts" 2>/dev/null | grep -v node_modules | wc -l)
COMPONENT_FILES=$(find "$SRC_DIR" -name "*.tsx" -o -name "*.jsx" 2>/dev/null | grep -v node_modules | grep -v ".test\." | grep -v ".spec\." | wc -l)

echo "Test files:      $TEST_FILES"
echo "Component files: $COMPONENT_FILES"

if [ "$COMPONENT_FILES" -gt 0 ]; then
    COVERAGE_PCT=$((TEST_FILES * 100 / COMPONENT_FILES))
    echo "Test coverage:   ~${COVERAGE_PCT}% (by file count)"
fi
echo ""

# Test file locations
echo "=== Test Organization ==="
echo ""

# Co-located tests
COLOCATED=$(find "$SRC_DIR" -name "*.test.tsx" -o -name "*.test.ts" 2>/dev/null | grep -v __tests__ | grep -v node_modules | wc -l)
echo "Co-located tests: $COLOCATED"

# __tests__ directories
TESTS_DIR=$(find "$SRC_DIR" -type d -name "__tests__" 2>/dev/null | grep -v node_modules | wc -l)
echo "__tests__ dirs:   $TESTS_DIR"

echo ""

# Testing patterns used
echo "=== Testing Patterns Used ==="
echo ""

# render usage
RENDER_COUNT=$(grep -r "render(" "$SRC_DIR" --include="*.test.tsx" --include="*.test.ts" 2>/dev/null | grep -v node_modules | wc -l)
echo "render() calls:           $RENDER_COUNT"

# screen queries
SCREEN_COUNT=$(grep -r "screen\." "$SRC_DIR" --include="*.test.tsx" --include="*.test.ts" 2>/dev/null | grep -v node_modules | wc -l)
echo "screen.* queries:         $SCREEN_COUNT"

# userEvent
USER_EVENT=$(grep -r "userEvent\." "$SRC_DIR" --include="*.test.tsx" --include="*.test.ts" 2>/dev/null | grep -v node_modules | wc -l)
echo "userEvent interactions:   $USER_EVENT"

# waitFor
WAIT_FOR=$(grep -r "waitFor" "$SRC_DIR" --include="*.test.tsx" --include="*.test.ts" 2>/dev/null | grep -v node_modules | wc -l)
echo "waitFor async tests:      $WAIT_FOR"

# renderHook
RENDER_HOOK=$(grep -r "renderHook" "$SRC_DIR" --include="*.test.tsx" --include="*.test.ts" 2>/dev/null | grep -v node_modules | wc -l)
echo "renderHook calls:         $RENDER_HOOK"

echo ""

# Query types used
echo "=== Query Types (Best Practices) ==="
echo ""

echo "Accessibility queries (preferred):"
BY_ROLE=$(grep -ro "getByRole\|queryByRole\|findByRole" "$SRC_DIR" --include="*.test.tsx" --include="*.test.ts" 2>/dev/null | grep -v node_modules | wc -l)
echo "  ByRole:         $BY_ROLE"

BY_LABEL=$(grep -ro "getByLabelText\|queryByLabelText\|findByLabelText" "$SRC_DIR" --include="*.test.tsx" --include="*.test.ts" 2>/dev/null | grep -v node_modules | wc -l)
echo "  ByLabelText:    $BY_LABEL"

BY_TEXT=$(grep -ro "getByText\|queryByText\|findByText" "$SRC_DIR" --include="*.test.tsx" --include="*.test.ts" 2>/dev/null | grep -v node_modules | wc -l)
echo "  ByText:         $BY_TEXT"

echo ""
echo "Test IDs (last resort):"
BY_TESTID=$(grep -ro "getByTestId\|queryByTestId\|findByTestId" "$SRC_DIR" --include="*.test.tsx" --include="*.test.ts" 2>/dev/null | grep -v node_modules | wc -l)
echo "  ByTestId:       $BY_TESTID"

if [ "$BY_TESTID" -gt "$BY_ROLE" ]; then
    echo ""
    echo "⚠️  Consider using more accessibility queries (ByRole, ByLabelText)"
fi

echo ""

# Components without tests
echo "=== Components Without Tests ==="
echo ""
echo "Checking for untested components..."
echo ""

find "$SRC_DIR" -name "*.tsx" 2>/dev/null | grep -v node_modules | grep -v ".test\." | grep -v ".spec\." | while read component; do
    test_file="${component%.tsx}.test.tsx"
    spec_file="${component%.tsx}.spec.tsx"
    if [ ! -f "$test_file" ] && [ ! -f "$spec_file" ]; then
        # Check __tests__ directory
        basename=$(basename "$component" .tsx)
        dirname=$(dirname "$component")
        tests_dir="$dirname/__tests__"
        if [ ! -f "$tests_dir/$basename.test.tsx" ]; then
            echo "  No test: $component"
        fi
    fi
done | head -10

echo ""
echo "(showing first 10)"
echo ""

# Recommendations
echo "=== Recommendations ==="
echo ""
echo "1. Prefer ByRole > ByLabelText > ByText > ByTestId"
echo "2. Use userEvent.setup() for user interactions"
echo "3. Test behavior, not implementation details"
echo "4. Add custom render with providers for context"
echo "5. Use waitFor for async operations"
echo "6. Co-locate tests with components (Component.test.tsx)"
echo "7. Run tests with coverage: vitest run --coverage"
echo ""
