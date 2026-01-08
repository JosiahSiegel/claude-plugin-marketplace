#!/bin/bash
# Validate Claude Code skill structure
# Usage: ./validate-skill.sh <skill-directory>

set -e

SKILL_DIR="$1"

if [[ -z "$SKILL_DIR" ]]; then
    echo "Usage: ./validate-skill.sh <skill-directory>"
    exit 1
fi

if [[ ! -d "$SKILL_DIR" ]]; then
    echo "ERROR: Directory not found: $SKILL_DIR"
    exit 1
fi

SKILL_FILE="$SKILL_DIR/SKILL.md"

if [[ ! -f "$SKILL_FILE" ]]; then
    echo "ERROR: SKILL.md not found in $SKILL_DIR"
    exit 1
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

error() {
    echo -e "${RED}ERROR:${NC} $1"
    ((ERRORS++))
}

warning() {
    echo -e "${YELLOW}WARNING:${NC} $1"
    ((WARNINGS++))
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

echo "Validating skill: $SKILL_DIR"
echo "================================"

# Check frontmatter exists
if ! head -1 "$SKILL_FILE" | grep -q "^---"; then
    error "Missing YAML frontmatter (must start with ---)"
    exit 1
fi

success "Has YAML frontmatter"

# Extract frontmatter
FRONTMATTER=$(sed -n '/^---$/,/^---$/p' "$SKILL_FILE" | sed '1d;$d')

# Check name field
NAME=$(echo "$FRONTMATTER" | grep -E "^name:" | sed 's/name:[[:space:]]*//')
if [[ -z "$NAME" ]]; then
    warning "Missing 'name' field (recommended)"
else
    success "Name: $NAME"
fi

# Check description field
if echo "$FRONTMATTER" | grep -qE "^description:"; then
    success "Has description field"

    # Check description quality
    DESC=$(echo "$FRONTMATTER" | sed -n '/^description:/,/^[a-z]*:/p' | head -n -1)
    if echo "$DESC" | grep -qE "\([0-9]\)"; then
        success "Description has numbered use cases"
    else
        warning "Consider adding numbered use cases to description"
    fi
else
    error "Missing required 'description' field"
fi

# Check SKILL.md content
CONTENT=$(cat "$SKILL_FILE")
LINE_COUNT=$(wc -l < "$SKILL_FILE")
CHAR_COUNT=${#CONTENT}

success "SKILL.md: $LINE_COUNT lines, $CHAR_COUNT characters"

if [[ $LINE_COUNT -gt 500 ]]; then
    warning "SKILL.md has $LINE_COUNT lines - consider using progressive disclosure"
fi

# Check for quick reference
if echo "$CONTENT" | grep -qi "quick reference"; then
    success "Has Quick Reference section"
else
    warning "Consider adding a Quick Reference section with tables"
fi

# Check for references to subdirectories
if echo "$CONTENT" | grep -qE "references/|examples/"; then
    success "References progressive disclosure files"
fi

# Check directory structure
echo ""
echo "Directory Structure:"
echo "-------------------"

# Check for references/
if [[ -d "$SKILL_DIR/references" ]]; then
    REF_COUNT=$(find "$SKILL_DIR/references" -name "*.md" 2>/dev/null | wc -l)
    success "references/ directory: $REF_COUNT file(s)"
else
    if [[ $LINE_COUNT -gt 300 ]]; then
        warning "Consider adding references/ directory for detailed content"
    fi
fi

# Check for examples/
if [[ -d "$SKILL_DIR/examples" ]]; then
    EX_COUNT=$(find "$SKILL_DIR/examples" -name "*.md" 2>/dev/null | wc -l)
    success "examples/ directory: $EX_COUNT file(s)"
fi

# Check for scripts/
if [[ -d "$SKILL_DIR/scripts" ]]; then
    SCRIPT_COUNT=$(find "$SKILL_DIR/scripts" -type f 2>/dev/null | wc -l)
    success "scripts/ directory: $SCRIPT_COUNT file(s)"

    # Check scripts are executable
    for script in "$SKILL_DIR"/scripts/*.sh; do
        [[ ! -f "$script" ]] && continue
        if [[ ! -x "$script" ]]; then
            warning "Script not executable: $(basename "$script")"
        fi
    done
fi

echo ""
echo "================================"
echo "Validation Summary"
echo "================================"
echo -e "Errors:   ${RED}$ERRORS${NC}"
echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"

if [[ $ERRORS -gt 0 ]]; then
    echo -e "\n${RED}Skill validation FAILED${NC}"
    exit 1
else
    echo -e "\n${GREEN}Skill validation PASSED${NC}"
    exit 0
fi
