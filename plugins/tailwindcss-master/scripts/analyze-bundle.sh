#!/bin/bash
# Analyze Tailwind CSS bundle size and optimization opportunities

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=== Tailwind CSS Bundle Analysis ==="
echo ""

# Find CSS output files
find_css_files() {
    local dirs=("dist" "build" ".next/static/css" "out" "public")
    for dir in "${dirs[@]}"; do
        if [ -d "$dir" ]; then
            find "$dir" -name "*.css" 2>/dev/null
        fi
    done
}

CSS_FILES=$(find_css_files)

if [ -z "$CSS_FILES" ]; then
    echo -e "${YELLOW}No compiled CSS files found in common output directories${NC}"
    echo "Run your build command first: npm run build"
    echo ""
    echo "Checking for development CSS..."

    # Try to find any CSS with Tailwind classes
    DEV_CSS=$(find . -name "*.css" -type f ! -path "./node_modules/*" 2>/dev/null | head -5)
    if [ -n "$DEV_CSS" ]; then
        echo "Found CSS files:"
        echo "$DEV_CSS"
    fi
    exit 0
fi

echo "=== CSS File Sizes ==="
echo ""

for file in $CSS_FILES; do
    if [ -f "$file" ]; then
        SIZE=$(ls -lh "$file" | awk '{print $5}')
        LINES=$(wc -l < "$file")
        echo -e "${GREEN}$file${NC}"
        echo "  Raw size: $SIZE"
        echo "  Lines: $LINES"

        # Calculate gzipped size
        GZIP_SIZE=$(gzip -c "$file" 2>/dev/null | wc -c)
        GZIP_SIZE_KB=$((GZIP_SIZE / 1024))
        echo "  Gzipped: ${GZIP_SIZE_KB}KB"

        # Calculate brotli size if available
        if command -v brotli &> /dev/null; then
            BROTLI_SIZE=$(brotli -c "$file" 2>/dev/null | wc -c)
            BROTLI_SIZE_KB=$((BROTLI_SIZE / 1024))
            echo "  Brotli: ${BROTLI_SIZE_KB}KB"
        fi

        echo ""
    fi
done

# Analyze selectors in CSS
echo "=== Selector Analysis ==="
echo ""

for file in $CSS_FILES; do
    if [ -f "$file" ]; then
        echo "File: $file"

        # Count unique selectors
        SELECTOR_COUNT=$(grep -oE '\.[a-zA-Z_-][a-zA-Z0-9_-]*' "$file" 2>/dev/null | sort -u | wc -l)
        echo "  Unique class selectors: $SELECTOR_COUNT"

        # Count media queries
        MEDIA_QUERIES=$(grep -c "@media" "$file" 2>/dev/null || echo "0")
        echo "  Media queries: $MEDIA_QUERIES"

        # Count keyframes
        KEYFRAMES=$(grep -c "@keyframes" "$file" 2>/dev/null || echo "0")
        echo "  Keyframe animations: $KEYFRAMES"

        # Count CSS variables
        CSS_VARS=$(grep -oE '--[a-zA-Z0-9_-]+' "$file" 2>/dev/null | sort -u | wc -l)
        echo "  CSS custom properties: $CSS_VARS"

        echo ""
    fi
done

# Size recommendations
echo "=== Size Recommendations ==="
echo ""

TOTAL_GZIP=0
for file in $CSS_FILES; do
    if [ -f "$file" ]; then
        GZIP_SIZE=$(gzip -c "$file" 2>/dev/null | wc -c)
        TOTAL_GZIP=$((TOTAL_GZIP + GZIP_SIZE))
    fi
done

TOTAL_GZIP_KB=$((TOTAL_GZIP / 1024))

if [ "$TOTAL_GZIP_KB" -lt 15 ]; then
    echo -e "${GREEN}Excellent! Total gzipped CSS is under 15KB ($TOTAL_GZIP_KB KB)${NC}"
elif [ "$TOTAL_GZIP_KB" -lt 30 ]; then
    echo -e "${GREEN}Good! Total gzipped CSS is under 30KB ($TOTAL_GZIP_KB KB)${NC}"
elif [ "$TOTAL_GZIP_KB" -lt 50 ]; then
    echo -e "${YELLOW}Acceptable. Total gzipped CSS is under 50KB ($TOTAL_GZIP_KB KB)${NC}"
    echo "  Consider reviewing unused utilities"
else
    echo -e "${RED}Large bundle! Total gzipped CSS is $TOTAL_GZIP_KB KB${NC}"
    echo "  Recommendations:"
    echo "  - Check for dynamic class name patterns"
    echo "  - Review @source paths for over-broad patterns"
    echo "  - Consider limiting color palette in @theme"
    echo "  - Remove unused plugins"
fi

echo ""

# Check for common optimization opportunities
echo "=== Optimization Opportunities ==="
echo ""

# Check for transition-all usage
TRANSITION_ALL=$(grep -r "transition-all" . --include="*.tsx" --include="*.jsx" --include="*.vue" --include="*.svelte" --include="*.html" 2>/dev/null | wc -l)
if [ "$TRANSITION_ALL" -gt 5 ]; then
    echo -e "${YELLOW}Found $TRANSITION_ALL uses of transition-all${NC}"
    echo "  Consider using specific transition classes (transition-colors, transition-transform)"
fi

# Check for theme customization
if [ -f "tailwind.config.js" ] || [ -f "tailwind.config.ts" ]; then
    echo -e "${YELLOW}Found v3-style config file${NC}"
    echo "  Consider migrating to v4 CSS-first configuration"
fi

# Check for @theme usage
THEME_USAGE=$(find . -name "*.css" ! -path "./node_modules/*" -exec grep -l "@theme" {} \; 2>/dev/null | wc -l)
if [ "$THEME_USAGE" -gt 0 ]; then
    echo -e "${GREEN}Using v4 @theme directive ($THEME_USAGE files)${NC}"
fi

echo ""
echo "Done!"
