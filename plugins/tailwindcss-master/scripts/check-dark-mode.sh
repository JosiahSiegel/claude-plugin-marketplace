#!/bin/bash
# Analyze dark mode implementation and coverage

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=== Tailwind CSS Dark Mode Analysis ==="
echo ""

# Determine source directory
if [ -d "src" ]; then
    SRC_DIR="src"
elif [ -d "app" ]; then
    SRC_DIR="app"
elif [ -d "components" ]; then
    SRC_DIR="components"
else
    SRC_DIR="."
fi

echo "Analyzing directory: $SRC_DIR"
echo ""

# Check dark mode configuration
echo "=== Configuration Check ==="
echo ""

# Check for @custom-variant in CSS
DARK_VARIANT=$(find . -name "*.css" ! -path "./node_modules/*" -exec grep -l "@custom-variant dark" {} \; 2>/dev/null | head -1)
if [ -n "$DARK_VARIANT" ]; then
    echo -e "${GREEN}Dark mode variant configured in: $DARK_VARIANT${NC}"
    grep "@custom-variant dark" "$DARK_VARIANT" 2>/dev/null
else
    echo -e "${YELLOW}No @custom-variant dark found in CSS files${NC}"
    echo "  Add to your CSS: @custom-variant dark (&:where(.dark, .dark *));"
fi

echo ""

# Check for dark class on html element (in layout files)
echo "=== HTML Dark Class Implementation ==="
LAYOUT_FILES=$(find "$SRC_DIR" -name "layout.tsx" -o -name "layout.jsx" -o -name "_app.tsx" -o -name "_app.jsx" -o -name "Layout.astro" -o -name "+layout.svelte" 2>/dev/null)
if [ -n "$LAYOUT_FILES" ]; then
    for file in $LAYOUT_FILES; do
        if grep -q "dark" "$file" 2>/dev/null; then
            echo -e "${GREEN}Dark mode class handling found in: $file${NC}"
        fi
    done
fi

echo ""

# Check for theme toggle implementation
echo "=== Theme Toggle Implementation ==="
THEME_TOGGLE=$(grep -r "dark\|theme\|color-scheme" "$SRC_DIR" --include="*.tsx" --include="*.jsx" --include="*.ts" --include="*.js" 2>/dev/null | grep -E "toggle|switch|setTheme|setDark" | head -5)
if [ -n "$THEME_TOGGLE" ]; then
    echo -e "${GREEN}Theme toggle logic found:${NC}"
    echo "$THEME_TOGGLE"
else
    echo -e "${YELLOW}No theme toggle implementation detected${NC}"
fi

echo ""

# Check for next-themes or similar
NEXT_THEMES=$(grep -r "next-themes\|ThemeProvider" "$SRC_DIR" --include="*.tsx" --include="*.jsx" --include="*.ts" --include="*.js" 2>/dev/null | head -3)
if [ -n "$NEXT_THEMES" ]; then
    echo -e "${GREEN}Using theme library (next-themes or similar)${NC}"
fi

echo ""

# Analyze dark mode class coverage
echo "=== Dark Mode Class Coverage ==="
echo ""

# Count elements with background colors
BG_CLASSES=$(grep -roE "bg-[a-zA-Z]+-[0-9]+" "$SRC_DIR" --include="*.tsx" --include="*.jsx" --include="*.vue" --include="*.svelte" --include="*.html" 2>/dev/null | wc -l)
DARK_BG_CLASSES=$(grep -roE "dark:bg-[a-zA-Z]+-[0-9]+" "$SRC_DIR" --include="*.tsx" --include="*.jsx" --include="*.vue" --include="*.svelte" --include="*.html" 2>/dev/null | wc -l)

echo "Background colors: $BG_CLASSES"
echo "Dark background colors: $DARK_BG_CLASSES"

if [ "$BG_CLASSES" -gt 0 ]; then
    COVERAGE=$((DARK_BG_CLASSES * 100 / BG_CLASSES))
    echo "Dark mode background coverage: ${COVERAGE}%"
fi

echo ""

# Count text colors
TEXT_CLASSES=$(grep -roE "text-[a-zA-Z]+-[0-9]+" "$SRC_DIR" --include="*.tsx" --include="*.jsx" --include="*.vue" --include="*.svelte" --include="*.html" 2>/dev/null | wc -l)
DARK_TEXT_CLASSES=$(grep -roE "dark:text-[a-zA-Z]+-[0-9]+" "$SRC_DIR" --include="*.tsx" --include="*.jsx" --include="*.vue" --include="*.svelte" --include="*.html" 2>/dev/null | wc -l)

echo "Text colors: $TEXT_CLASSES"
echo "Dark text colors: $DARK_TEXT_CLASSES"

if [ "$TEXT_CLASSES" -gt 0 ]; then
    COVERAGE=$((DARK_TEXT_CLASSES * 100 / TEXT_CLASSES))
    echo "Dark mode text coverage: ${COVERAGE}%"
fi

echo ""

# Count border colors
BORDER_CLASSES=$(grep -roE "border-[a-zA-Z]+-[0-9]+" "$SRC_DIR" --include="*.tsx" --include="*.jsx" --include="*.vue" --include="*.svelte" --include="*.html" 2>/dev/null | wc -l)
DARK_BORDER_CLASSES=$(grep -roE "dark:border-[a-zA-Z]+-[0-9]+" "$SRC_DIR" --include="*.tsx" --include="*.jsx" --include="*.vue" --include="*.svelte" --include="*.html" 2>/dev/null | wc -l)

echo "Border colors: $BORDER_CLASSES"
echo "Dark border colors: $DARK_BORDER_CLASSES"

if [ "$BORDER_CLASSES" -gt 0 ]; then
    COVERAGE=$((DARK_BORDER_CLASSES * 100 / BORDER_CLASSES))
    echo "Dark mode border coverage: ${COVERAGE}%"
fi

echo ""

# Find elements that might need dark mode
echo "=== Potential Missing Dark Mode ==="
echo ""

# Find bg-white without dark variant
BG_WHITE_MISSING=$(grep -rn "bg-white" "$SRC_DIR" --include="*.tsx" --include="*.jsx" --include="*.vue" --include="*.svelte" --include="*.html" 2>/dev/null | grep -v "dark:bg" | head -5)
if [ -n "$BG_WHITE_MISSING" ]; then
    echo -e "${YELLOW}bg-white without dark variant:${NC}"
    echo "$BG_WHITE_MISSING" | while read line; do
        echo "  $line"
    done
fi

# Find text-gray-900 without dark variant
TEXT_DARK_MISSING=$(grep -rn "text-gray-900\|text-black" "$SRC_DIR" --include="*.tsx" --include="*.jsx" --include="*.vue" --include="*.svelte" --include="*.html" 2>/dev/null | grep -v "dark:text" | head -5)
if [ -n "$TEXT_DARK_MISSING" ]; then
    echo ""
    echo -e "${YELLOW}Dark text without dark variant:${NC}"
    echo "$TEXT_DARK_MISSING" | while read line; do
        echo "  $line"
    done
fi

echo ""

# Summary
echo "=== Summary ==="
echo ""

TOTAL_DARK_CLASSES=$((DARK_BG_CLASSES + DARK_TEXT_CLASSES + DARK_BORDER_CLASSES))
TOTAL_COLOR_CLASSES=$((BG_CLASSES + TEXT_CLASSES + BORDER_CLASSES))

if [ "$TOTAL_COLOR_CLASSES" -gt 0 ]; then
    OVERALL_COVERAGE=$((TOTAL_DARK_CLASSES * 100 / TOTAL_COLOR_CLASSES))

    if [ "$OVERALL_COVERAGE" -gt 80 ]; then
        echo -e "${GREEN}Excellent dark mode coverage: ${OVERALL_COVERAGE}%${NC}"
    elif [ "$OVERALL_COVERAGE" -gt 50 ]; then
        echo -e "${YELLOW}Good dark mode coverage: ${OVERALL_COVERAGE}%${NC}"
        echo "  Consider adding dark variants to more elements"
    else
        echo -e "${RED}Low dark mode coverage: ${OVERALL_COVERAGE}%${NC}"
        echo "  Many elements may look broken in dark mode"
    fi
else
    echo "No color classes found to analyze"
fi

echo ""
echo "Done!"
