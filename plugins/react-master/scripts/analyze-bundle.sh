#!/bin/bash
# React Bundle Size Analyzer
# Analyzes your React project's bundle size to identify optimization opportunities
#
# Usage: ./analyze-bundle.sh [project-path]
#
# This script:
# - Checks for bundle analyzer tools
# - Runs production build with analysis
# - Reports large dependencies
# - Suggests code splitting opportunities

set -e

PROJECT_PATH="${1:-.}"
cd "$PROJECT_PATH"

echo "=== React Bundle Size Analysis ==="
echo ""

# Detect package manager
if [ -f "pnpm-lock.yaml" ]; then
    PM="pnpm"
elif [ -f "yarn.lock" ]; then
    PM="yarn"
elif [ -f "bun.lockb" ]; then
    PM="bun"
else
    PM="npm"
fi

echo "Package manager detected: $PM"
echo ""

# Check for Vite or webpack
BUILD_TOOL="unknown"
if [ -f "vite.config.ts" ] || [ -f "vite.config.js" ]; then
    BUILD_TOOL="vite"
elif [ -f "next.config.js" ] || [ -f "next.config.mjs" ] || [ -f "next.config.ts" ]; then
    BUILD_TOOL="next"
elif [ -f "webpack.config.js" ]; then
    BUILD_TOOL="webpack"
fi

echo "Build tool detected: $BUILD_TOOL"
echo ""

# Check for bundle analyzer
HAS_ANALYZER=false
if grep -q "rollup-plugin-visualizer\|webpack-bundle-analyzer\|@next/bundle-analyzer" package.json 2>/dev/null; then
    HAS_ANALYZER=true
fi

if [ "$HAS_ANALYZER" = false ]; then
    echo "Bundle analyzer not found. Consider installing:"
    case "$BUILD_TOOL" in
        vite)
            echo "  $PM add -D rollup-plugin-visualizer"
            ;;
        next)
            echo "  $PM add -D @next/bundle-analyzer"
            ;;
        webpack)
            echo "  $PM add -D webpack-bundle-analyzer"
            ;;
        *)
            echo "  $PM add -D source-map-explorer"
            ;;
    esac
    echo ""
fi

# Analyze package.json for large dependencies
echo "=== Checking for commonly large dependencies ==="
echo ""

LARGE_DEPS=(
    "moment:Consider date-fns or dayjs (smaller)"
    "lodash:Use lodash-es with tree shaking or individual imports"
    "antd:Use tree shaking or import specific components"
    "@mui/material:Import specific components"
    "chart.js:Consider lighter alternatives for simple charts"
    "three:Consider lazy loading for 3D"
    "pdf-lib:Lazy load PDF functionality"
    "xlsx:Lazy load spreadsheet functionality"
)

for dep_info in "${LARGE_DEPS[@]}"; do
    dep="${dep_info%%:*}"
    suggestion="${dep_info#*:}"
    if grep -q "\"$dep\"" package.json 2>/dev/null; then
        echo "⚠️  Found: $dep"
        echo "   Suggestion: $suggestion"
        echo ""
    fi
done

# Check for code splitting opportunities
echo "=== Code Splitting Opportunities ==="
echo ""

# Look for route components that could be lazy loaded
if [ -d "src/pages" ] || [ -d "app" ] || [ -d "src/routes" ]; then
    echo "Route-based code splitting:"
    echo "  Routes directory found - ensure routes are lazy loaded"
    echo ""
    echo "  Example:"
    echo "    const Dashboard = lazy(() => import('./pages/Dashboard'));"
    echo ""
fi

# Check for heavy component patterns
echo "Heavy component patterns to check:"
echo "  - Modal/Dialog components"
echo "  - Admin panels"
echo "  - Rich text editors"
echo "  - Chart/Graph components"
echo "  - PDF viewers"
echo ""
echo "Consider lazy loading these with React.lazy() and Suspense"
echo ""

# Run build if requested
if [ "$2" = "--build" ]; then
    echo "=== Running Production Build ==="
    case "$BUILD_TOOL" in
        vite)
            $PM run build
            echo ""
            echo "Build output in dist/ directory"
            if [ -d "dist/assets" ]; then
                echo ""
                echo "=== Bundle Sizes ==="
                ls -lh dist/assets/*.js 2>/dev/null | awk '{print $9, $5}'
            fi
            ;;
        next)
            $PM run build
            ;;
        *)
            $PM run build
            ;;
    esac
fi

echo ""
echo "=== Recommendations ==="
echo "1. Use dynamic imports for routes and heavy components"
echo "2. Enable tree shaking (use ES modules)"
echo "3. Check for unused dependencies: npx depcheck"
echo "4. Consider lighter alternatives for large libraries"
echo "5. Use production builds of React (automatic in modern tooling)"
echo ""
