#!/bin/bash
# React Component Structure Analyzer
# Analyzes your React components for patterns and potential improvements
#
# Usage: ./check-components.sh [project-path]
#
# This script checks:
# - Component organization
# - Client vs Server Components (Next.js/React 19)
# - Props patterns
# - Component size and complexity

set -e

PROJECT_PATH="${1:-.}"
SRC_DIR="$PROJECT_PATH/src"

if [ ! -d "$SRC_DIR" ]; then
    SRC_DIR="$PROJECT_PATH"
fi

echo "=== React Component Analysis ==="
echo "Scanning: $SRC_DIR"
echo ""

# Count components
echo "=== Component Summary ==="
echo ""

# Function components
FUNC_COMPONENTS=$(grep -r "export.*function [A-Z]" "$SRC_DIR" --include="*.tsx" --include="*.jsx" 2>/dev/null | grep -v node_modules | wc -l)
ARROW_COMPONENTS=$(grep -r "export const [A-Z].*=.*=>" "$SRC_DIR" --include="*.tsx" --include="*.jsx" 2>/dev/null | grep -v node_modules | wc -l)

echo "Function components:       $FUNC_COMPONENTS"
echo "Arrow function components: $ARROW_COMPONENTS"
echo ""

# Client components
CLIENT_COMPONENTS=$(grep -rl "'use client'" "$SRC_DIR" --include="*.tsx" --include="*.jsx" 2>/dev/null | grep -v node_modules | wc -l)
echo "Client Components ('use client'): $CLIENT_COMPONENTS"

# Server actions
SERVER_ACTIONS=$(grep -rl "'use server'" "$SRC_DIR" --include="*.tsx" --include="*.ts" 2>/dev/null | grep -v node_modules | wc -l)
echo "Server Actions ('use server'):    $SERVER_ACTIONS"
echo ""

# Component directories
echo "=== Component Organization ==="
echo ""

COMPONENT_DIRS=("components" "ui" "features" "pages" "app" "layouts" "views")
for dir in "${COMPONENT_DIRS[@]}"; do
    if [ -d "$SRC_DIR/$dir" ]; then
        count=$(find "$SRC_DIR/$dir" -name "*.tsx" -o -name "*.jsx" 2>/dev/null | grep -v node_modules | wc -l)
        echo "✓ $dir/: $count files"
    fi
done
echo ""

# Check for React.memo usage
echo "=== Performance Patterns ==="
echo ""

MEMO_USAGE=$(grep -r "React.memo\|memo(" "$SRC_DIR" --include="*.tsx" --include="*.jsx" 2>/dev/null | grep -v node_modules | wc -l)
echo "React.memo usage: $MEMO_USAGE components"

FORWARD_REF=$(grep -r "forwardRef" "$SRC_DIR" --include="*.tsx" --include="*.jsx" 2>/dev/null | grep -v node_modules | wc -l)
echo "forwardRef usage: $FORWARD_REF components"

LAZY_COMPONENTS=$(grep -r "lazy(" "$SRC_DIR" --include="*.tsx" --include="*.jsx" --include="*.ts" --include="*.js" 2>/dev/null | grep -v node_modules | wc -l)
echo "Lazy loaded:      $LAZY_COMPONENTS components"
echo ""

# Check for large components
echo "=== Component Complexity Check ==="
echo ""
echo "Large components (>200 lines):"

find "$SRC_DIR" \( -name "*.tsx" -o -name "*.jsx" \) 2>/dev/null | grep -v node_modules | while read file; do
    lines=$(wc -l < "$file")
    if [ "$lines" -gt 200 ]; then
        echo "  ⚠️  $file: $lines lines"
    fi
done

echo ""
echo "Consider splitting components >200 lines into smaller pieces"
echo ""

# Props patterns
echo "=== Props Patterns ==="
echo ""

# Interface props
INTERFACE_PROPS=$(grep -r "interface.*Props" "$SRC_DIR" --include="*.tsx" 2>/dev/null | grep -v node_modules | wc -l)
echo "TypeScript interface props: $INTERFACE_PROPS"

# Type props
TYPE_PROPS=$(grep -r "type.*Props" "$SRC_DIR" --include="*.tsx" 2>/dev/null | grep -v node_modules | wc -l)
echo "TypeScript type props:      $TYPE_PROPS"

# PropTypes (legacy)
PROPTYPES=$(grep -r "PropTypes" "$SRC_DIR" --include="*.tsx" --include="*.jsx" --include="*.js" 2>/dev/null | grep -v node_modules | wc -l)
if [ "$PROPTYPES" -gt 0 ]; then
    echo "⚠️  PropTypes (legacy):       $PROPTYPES"
    echo "   Consider migrating to TypeScript"
fi
echo ""

# Check for common patterns
echo "=== Common Patterns Detected ==="
echo ""

# Compound components
if grep -rq "\.Provider\|\.Consumer\|createContext" "$SRC_DIR" --include="*.tsx" 2>/dev/null | grep -v node_modules; then
    echo "✓ Context/Provider pattern detected"
fi

# Render props
if grep -rq "render={" "$SRC_DIR" --include="*.tsx" --include="*.jsx" 2>/dev/null | grep -v node_modules; then
    echo "✓ Render props pattern detected"
fi

# Children as function
if grep -rq "children(" "$SRC_DIR" --include="*.tsx" --include="*.jsx" 2>/dev/null | grep -v node_modules; then
    echo "✓ Children as function pattern detected"
fi

echo ""

# Recommendations
echo "=== Recommendations ==="
echo ""
echo "1. Use TypeScript interfaces for all component props"
echo "2. Split large components (>200 lines) into smaller pieces"
echo "3. Use React.memo for components that render frequently with same props"
echo "4. Consider lazy loading for route-level components"
echo "5. Organize by feature rather than type for larger apps"
echo "6. Use 'use client' only when needed (hooks, events, browser APIs)"
echo ""
