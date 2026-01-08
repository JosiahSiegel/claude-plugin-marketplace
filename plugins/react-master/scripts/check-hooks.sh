#!/bin/bash
# React Hooks Usage Analyzer
# Scans your React project for hooks usage patterns and potential issues
#
# Usage: ./check-hooks.sh [project-path]
#
# This script analyzes:
# - Hook usage patterns
# - Missing dependency arrays
# - Potential rules of hooks violations
# - Custom hooks organization

set -e

PROJECT_PATH="${1:-.}"
SRC_DIR="$PROJECT_PATH/src"

if [ ! -d "$SRC_DIR" ]; then
    SRC_DIR="$PROJECT_PATH"
fi

echo "=== React Hooks Usage Analysis ==="
echo "Scanning: $SRC_DIR"
echo ""

# Function to count occurrences
count_hook() {
    local hook="$1"
    local count=$(grep -r "$hook(" "$SRC_DIR" --include="*.tsx" --include="*.ts" --include="*.jsx" --include="*.js" 2>/dev/null | grep -v node_modules | grep -v ".test." | wc -l)
    echo "$count"
}

echo "=== Hook Usage Summary ==="
echo ""

# Core hooks
echo "Core Hooks:"
printf "  useState:         %s\n" "$(count_hook 'useState')"
printf "  useEffect:        %s\n" "$(count_hook 'useEffect')"
printf "  useContext:       %s\n" "$(count_hook 'useContext')"
printf "  useReducer:       %s\n" "$(count_hook 'useReducer')"
printf "  useRef:           %s\n" "$(count_hook 'useRef')"
echo ""

# Performance hooks
echo "Performance Hooks:"
printf "  useMemo:          %s\n" "$(count_hook 'useMemo')"
printf "  useCallback:      %s\n" "$(count_hook 'useCallback')"
echo ""

# React 18+ hooks
echo "React 18+ Hooks:"
printf "  useTransition:    %s\n" "$(count_hook 'useTransition')"
printf "  useDeferredValue: %s\n" "$(count_hook 'useDeferredValue')"
printf "  useId:            %s\n" "$(count_hook 'useId')"
printf "  useSyncExtStore:  %s\n" "$(count_hook 'useSyncExternalStore')"
echo ""

# React 19 hooks
echo "React 19 Hooks:"
printf "  useActionState:   %s\n" "$(count_hook 'useActionState')"
printf "  useOptimistic:    %s\n" "$(count_hook 'useOptimistic')"
printf "  useFormStatus:    %s\n" "$(count_hook 'useFormStatus')"
printf "  use():            %s\n" "$(count_hook 'use(')"
echo ""

# Other hooks
echo "Other Hooks:"
printf "  useLayoutEffect:  %s\n" "$(count_hook 'useLayoutEffect')"
printf "  useImperativeHandle: %s\n" "$(count_hook 'useImperativeHandle')"
printf "  useDebugValue:    %s\n" "$(count_hook 'useDebugValue')"
echo ""

# Custom hooks
echo "=== Custom Hooks Found ==="
echo ""
grep -r "export.*function use[A-Z]" "$SRC_DIR" --include="*.tsx" --include="*.ts" 2>/dev/null | grep -v node_modules | head -20 || echo "No custom hooks found"
echo ""

# Check for hooks directory
echo "=== Hooks Organization ==="
if [ -d "$SRC_DIR/hooks" ]; then
    echo "✓ hooks/ directory exists"
    echo "  Files:"
    ls -la "$SRC_DIR/hooks" 2>/dev/null | grep -E "\.tsx?$|\.jsx?$" | awk '{print "    " $NF}'
else
    echo "⚠️  No hooks/ directory found"
    echo "   Consider creating src/hooks/ for custom hooks"
fi
echo ""

# Check for potential issues
echo "=== Potential Issues ==="
echo ""

# Empty dependency arrays with variables
echo "Checking for useEffect with empty deps that reference variables..."
grep -rn "useEffect.*\[\]" "$SRC_DIR" --include="*.tsx" --include="*.ts" 2>/dev/null | grep -v node_modules | head -5 || echo "  None found"
echo ""

# useEffect without dependency array
echo "Checking for useEffect without dependency array..."
grep -rn "useEffect([^,]*)" "$SRC_DIR" --include="*.tsx" --include="*.ts" 2>/dev/null | grep -v "\[" | grep -v node_modules | head -5 || echo "  None found"
echo ""

# useState with object initialization
echo "Checking for useState with inline object (potential re-render issue)..."
grep -rn "useState({" "$SRC_DIR" --include="*.tsx" --include="*.ts" 2>/dev/null | grep -v node_modules | head -5 || echo "  None found (good!)"
echo ""

echo "=== Recommendations ==="
echo ""
echo "1. Ensure all useEffect have proper dependency arrays"
echo "2. Use useCallback for functions passed to child components"
echo "3. Use useMemo for expensive computations"
echo "4. Consider React 19's useActionState for form handling"
echo "5. Place custom hooks in src/hooks/ directory"
echo "6. Run eslint-plugin-react-hooks for comprehensive checking"
echo ""
