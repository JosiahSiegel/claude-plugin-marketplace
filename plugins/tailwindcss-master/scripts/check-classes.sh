#!/bin/bash
# Analyze Tailwind CSS class usage patterns in the project

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=== Tailwind CSS Class Analysis ==="
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

# File extensions to search
EXTENSIONS="*.tsx,*.jsx,*.ts,*.js,*.vue,*.svelte,*.astro,*.html"

echo "=== Class Usage Statistics ==="
echo ""

# Count total class attributes
TOTAL_CLASS_ATTRS=$(grep -rE "class(Name)?=" "$SRC_DIR" --include="*.tsx" --include="*.jsx" --include="*.vue" --include="*.svelte" --include="*.html" --include="*.astro" 2>/dev/null | wc -l)
echo "Total class attributes found: $TOTAL_CLASS_ATTRS"

# Count responsive classes
SM_CLASSES=$(grep -roE "sm:[a-zA-Z0-9_-]+" "$SRC_DIR" --include="*.tsx" --include="*.jsx" --include="*.vue" --include="*.svelte" --include="*.html" 2>/dev/null | wc -l)
MD_CLASSES=$(grep -roE "md:[a-zA-Z0-9_-]+" "$SRC_DIR" --include="*.tsx" --include="*.jsx" --include="*.vue" --include="*.svelte" --include="*.html" 2>/dev/null | wc -l)
LG_CLASSES=$(grep -roE "lg:[a-zA-Z0-9_-]+" "$SRC_DIR" --include="*.tsx" --include="*.jsx" --include="*.vue" --include="*.svelte" --include="*.html" 2>/dev/null | wc -l)
XL_CLASSES=$(grep -roE "xl:[a-zA-Z0-9_-]+" "$SRC_DIR" --include="*.tsx" --include="*.jsx" --include="*.vue" --include="*.svelte" --include="*.html" 2>/dev/null | wc -l)

echo ""
echo "=== Responsive Class Usage ==="
echo "sm: prefixed classes: $SM_CLASSES"
echo "md: prefixed classes: $MD_CLASSES"
echo "lg: prefixed classes: $LG_CLASSES"
echo "xl: prefixed classes: $XL_CLASSES"

# Count dark mode classes
DARK_CLASSES=$(grep -roE "dark:[a-zA-Z0-9_-]+" "$SRC_DIR" --include="*.tsx" --include="*.jsx" --include="*.vue" --include="*.svelte" --include="*.html" 2>/dev/null | wc -l)
echo ""
echo "=== Dark Mode Usage ==="
echo "dark: prefixed classes: $DARK_CLASSES"

# Check for hover/focus states
HOVER_CLASSES=$(grep -roE "hover:[a-zA-Z0-9_-]+" "$SRC_DIR" --include="*.tsx" --include="*.jsx" --include="*.vue" --include="*.svelte" --include="*.html" 2>/dev/null | wc -l)
FOCUS_CLASSES=$(grep -roE "focus:[a-zA-Z0-9_-]+" "$SRC_DIR" --include="*.tsx" --include="*.jsx" --include="*.vue" --include="*.svelte" --include="*.html" 2>/dev/null | wc -l)
echo ""
echo "=== State Variant Usage ==="
echo "hover: prefixed classes: $HOVER_CLASSES"
echo "focus: prefixed classes: $FOCUS_CLASSES"

# Check for potential issues
echo ""
echo "=== Potential Issues ==="
echo ""

# Check for dynamic class names (potential purging issues)
DYNAMIC_CLASSES=$(grep -rnE "\`[^\`]*\\\$\{[^\}]+\}[^\`]*\`" "$SRC_DIR" --include="*.tsx" --include="*.jsx" --include="*.vue" --include="*.svelte" 2>/dev/null | grep -E "class|className" | head -10 || true)

if [ -n "$DYNAMIC_CLASSES" ]; then
    echo -e "${YELLOW}Dynamic class patterns found (may not be detected by Tailwind):${NC}"
    echo "$DYNAMIC_CLASSES"
    echo ""
else
    echo -e "${GREEN}No dynamic class name patterns detected${NC}"
fi

# Check for very long class strings (might need extraction)
echo ""
echo "=== Long Class Strings ==="
LONG_CLASSES=$(grep -roE 'class(Name)?="[^"]{200,}"' "$SRC_DIR" --include="*.tsx" --include="*.jsx" --include="*.vue" --include="*.svelte" --include="*.html" 2>/dev/null | head -5 || true)

if [ -n "$LONG_CLASSES" ]; then
    echo -e "${YELLOW}Very long class strings found (consider component extraction):${NC}"
    echo "$LONG_CLASSES" | while read line; do
        echo "  $(echo $line | cut -c1-100)..."
    done
else
    echo -e "${GREEN}No excessively long class strings found${NC}"
fi

# Most used utility patterns
echo ""
echo "=== Most Used Class Patterns ==="
grep -roE "[a-z]+-[a-z0-9]+" "$SRC_DIR" --include="*.tsx" --include="*.jsx" --include="*.vue" --include="*.svelte" --include="*.html" 2>/dev/null | \
    sort | uniq -c | sort -rn | head -15 || echo "Could not analyze patterns"

# Check for clsx/cn usage
echo ""
echo "=== Utility Library Usage ==="
CLSX_USAGE=$(grep -r "clsx\|cn(" "$SRC_DIR" --include="*.tsx" --include="*.jsx" --include="*.ts" --include="*.js" 2>/dev/null | wc -l)
TWMERGE_USAGE=$(grep -r "twMerge\|tailwind-merge" "$SRC_DIR" --include="*.tsx" --include="*.jsx" --include="*.ts" --include="*.js" 2>/dev/null | wc -l)

echo "clsx/cn usage: $CLSX_USAGE instances"
echo "tailwind-merge usage: $TWMERGE_USAGE instances"

if [ "$CLSX_USAGE" -eq 0 ] && [ "$TOTAL_CLASS_ATTRS" -gt 50 ]; then
    echo -e "${BLUE}Recommendation: Consider using clsx for conditional classes${NC}"
fi

echo ""
echo "Done!"
