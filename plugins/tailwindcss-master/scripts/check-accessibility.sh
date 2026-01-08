#!/bin/bash
# Analyze Tailwind CSS accessibility patterns

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=== Tailwind CSS Accessibility Analysis ==="
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

# Check focus states
echo "=== Focus State Analysis ==="
echo ""

# Count focus classes
FOCUS_VISIBLE=$(grep -roE "focus-visible:[a-zA-Z0-9_-]+" "$SRC_DIR" --include="*.tsx" --include="*.jsx" --include="*.vue" --include="*.svelte" --include="*.html" 2>/dev/null | wc -l)
FOCUS_REGULAR=$(grep -roE "focus:[a-zA-Z0-9_-]+" "$SRC_DIR" --include="*.tsx" --include="*.jsx" --include="*.vue" --include="*.svelte" --include="*.html" 2>/dev/null | wc -l)
FOCUS_WITHIN=$(grep -roE "focus-within:[a-zA-Z0-9_-]+" "$SRC_DIR" --include="*.tsx" --include="*.jsx" --include="*.vue" --include="*.svelte" --include="*.html" 2>/dev/null | wc -l)

echo "focus-visible: classes: $FOCUS_VISIBLE"
echo "focus: classes: $FOCUS_REGULAR"
echo "focus-within: classes: $FOCUS_WITHIN"

if [ "$FOCUS_VISIBLE" -gt "$FOCUS_REGULAR" ]; then
    echo -e "${GREEN}Good! Using focus-visible for better keyboard navigation${NC}"
else
    echo -e "${YELLOW}Consider using focus-visible: instead of focus: for keyboard-only focus styles${NC}"
fi

echo ""

# Count ring utilities
RING_CLASSES=$(grep -roE "ring-[a-zA-Z0-9_-]*" "$SRC_DIR" --include="*.tsx" --include="*.jsx" --include="*.vue" --include="*.svelte" --include="*.html" 2>/dev/null | wc -l)
echo "Focus ring utilities: $RING_CLASSES"

# Check outline usage
OUTLINE_NONE=$(grep -rn "outline-none" "$SRC_DIR" --include="*.tsx" --include="*.jsx" --include="*.vue" --include="*.svelte" --include="*.html" 2>/dev/null | wc -l)
OUTLINE_NONE_WITH_RING=$(grep -n "outline-none" "$SRC_DIR" --include="*.tsx" --include="*.jsx" --include="*.vue" --include="*.svelte" --include="*.html" -r 2>/dev/null | grep -E "ring|focus" | wc -l)

echo ""
echo "outline-none usage: $OUTLINE_NONE"
if [ "$OUTLINE_NONE" -gt 0 ]; then
    if [ "$OUTLINE_NONE_WITH_RING" -lt "$OUTLINE_NONE" ]; then
        echo -e "${RED}Warning: Found outline-none without replacement focus indicator${NC}"
        echo "  Always provide an alternative focus state (ring, border, etc.)"
    else
        echo -e "${GREEN}outline-none properly paired with focus indicators${NC}"
    fi
fi

echo ""

# Check reduced motion
echo "=== Reduced Motion Analysis ==="
echo ""

MOTION_SAFE=$(grep -roE "motion-safe:[a-zA-Z0-9_-]+" "$SRC_DIR" --include="*.tsx" --include="*.jsx" --include="*.vue" --include="*.svelte" --include="*.html" 2>/dev/null | wc -l)
MOTION_REDUCE=$(grep -roE "motion-reduce:[a-zA-Z0-9_-]+" "$SRC_DIR" --include="*.tsx" --include="*.jsx" --include="*.vue" --include="*.svelte" --include="*.html" 2>/dev/null | wc -l)

echo "motion-safe: classes: $MOTION_SAFE"
echo "motion-reduce: classes: $MOTION_REDUCE"

# Count animations/transitions
ANIMATE_CLASSES=$(grep -roE "animate-[a-zA-Z0-9_-]+" "$SRC_DIR" --include="*.tsx" --include="*.jsx" --include="*.vue" --include="*.svelte" --include="*.html" 2>/dev/null | wc -l)
TRANSITION_CLASSES=$(grep -roE "transition[a-zA-Z0-9_-]*" "$SRC_DIR" --include="*.tsx" --include="*.jsx" --include="*.vue" --include="*.svelte" --include="*.html" 2>/dev/null | wc -l)

echo ""
echo "Animation classes: $ANIMATE_CLASSES"
echo "Transition classes: $TRANSITION_CLASSES"

TOTAL_MOTION=$((ANIMATE_CLASSES + TRANSITION_CLASSES))
MOTION_RESPECT=$((MOTION_SAFE + MOTION_REDUCE))

if [ "$TOTAL_MOTION" -gt 10 ] && [ "$MOTION_RESPECT" -lt 5 ]; then
    echo -e "${YELLOW}Consider adding motion-safe: or motion-reduce: for accessibility${NC}"
else
    echo -e "${GREEN}Motion preferences being respected${NC}"
fi

echo ""

# Check screen reader utilities
echo "=== Screen Reader Utilities ==="
echo ""

SR_ONLY=$(grep -roE "sr-only" "$SRC_DIR" --include="*.tsx" --include="*.jsx" --include="*.vue" --include="*.svelte" --include="*.html" 2>/dev/null | wc -l)
NOT_SR_ONLY=$(grep -roE "not-sr-only" "$SRC_DIR" --include="*.tsx" --include="*.jsx" --include="*.vue" --include="*.svelte" --include="*.html" 2>/dev/null | wc -l)

echo "sr-only classes: $SR_ONLY"
echo "not-sr-only classes: $NOT_SR_ONLY"

if [ "$SR_ONLY" -gt 0 ]; then
    echo -e "${GREEN}Good! Using sr-only for screen reader text${NC}"
fi

echo ""

# Check for ARIA attributes
echo "=== ARIA Usage ==="
echo ""

ARIA_ATTRS=$(grep -roE "aria-[a-zA-Z]+=" "$SRC_DIR" --include="*.tsx" --include="*.jsx" --include="*.vue" --include="*.svelte" --include="*.html" 2>/dev/null | wc -l)
ROLE_ATTRS=$(grep -roE "role=" "$SRC_DIR" --include="*.tsx" --include="*.jsx" --include="*.vue" --include="*.svelte" --include="*.html" 2>/dev/null | wc -l)

echo "ARIA attributes: $ARIA_ATTRS"
echo "Role attributes: $ROLE_ATTRS"

echo ""

# Check interactive elements
echo "=== Interactive Element Analysis ==="
echo ""

# Buttons without focus states
BUTTONS=$(grep -rn "<button" "$SRC_DIR" --include="*.tsx" --include="*.jsx" --include="*.vue" --include="*.svelte" --include="*.html" 2>/dev/null | wc -l)
BUTTONS_WITH_FOCUS=$(grep -n "<button" "$SRC_DIR" --include="*.tsx" --include="*.jsx" --include="*.vue" --include="*.svelte" --include="*.html" -r 2>/dev/null | grep -E "focus" | wc -l)

echo "Total buttons: $BUTTONS"
echo "Buttons with focus styles: $BUTTONS_WITH_FOCUS"

if [ "$BUTTONS" -gt 0 ]; then
    BUTTON_COVERAGE=$((BUTTONS_WITH_FOCUS * 100 / BUTTONS))
    if [ "$BUTTON_COVERAGE" -lt 80 ]; then
        echo -e "${YELLOW}Only ${BUTTON_COVERAGE}% of buttons have focus styles${NC}"
    else
        echo -e "${GREEN}Good focus state coverage on buttons${NC}"
    fi
fi

echo ""

# Links
LINKS=$(grep -rn "<a " "$SRC_DIR" --include="*.tsx" --include="*.jsx" --include="*.vue" --include="*.svelte" --include="*.html" 2>/dev/null | wc -l)
LINKS_WITH_FOCUS=$(grep -n "<a " "$SRC_DIR" --include="*.tsx" --include="*.jsx" --include="*.vue" --include="*.svelte" --include="*.html" -r 2>/dev/null | grep -E "focus" | wc -l)

echo "Total links: $LINKS"
echo "Links with focus styles: $LINKS_WITH_FOCUS"

echo ""

# Check for touch target sizes
echo "=== Touch Target Analysis ==="
echo ""

SMALL_BUTTONS=$(grep -rn "p-1\|p-0\|py-0\|py-1\|px-1\|px-2" "$SRC_DIR" --include="*.tsx" --include="*.jsx" --include="*.vue" --include="*.svelte" --include="*.html" 2>/dev/null | grep -iE "button|click" | wc -l)

if [ "$SMALL_BUTTONS" -gt 0 ]; then
    echo -e "${YELLOW}Found $SMALL_BUTTONS potentially small touch targets${NC}"
    echo "  Minimum recommended touch target: 44x44px (p-3 or larger)"
else
    echo -e "${GREEN}No obviously small touch targets detected${NC}"
fi

echo ""

# Summary
echo "=== Accessibility Summary ==="
echo ""

SCORE=0
MAX_SCORE=5

[ "$FOCUS_VISIBLE" -gt 0 ] && SCORE=$((SCORE + 1))
[ "$MOTION_RESPECT" -gt 0 ] && SCORE=$((SCORE + 1))
[ "$SR_ONLY" -gt 0 ] && SCORE=$((SCORE + 1))
[ "$ARIA_ATTRS" -gt 0 ] && SCORE=$((SCORE + 1))
[ "$RING_CLASSES" -gt 0 ] && SCORE=$((SCORE + 1))

echo "Accessibility Score: $SCORE/$MAX_SCORE"

if [ "$SCORE" -eq 5 ]; then
    echo -e "${GREEN}Excellent! Following accessibility best practices${NC}"
elif [ "$SCORE" -ge 3 ]; then
    echo -e "${YELLOW}Good foundation, but room for improvement${NC}"
else
    echo -e "${RED}Consider improving accessibility coverage${NC}"
fi

echo ""
echo "Done!"
