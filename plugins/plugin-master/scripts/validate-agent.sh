#!/bin/bash
# Validate Claude Code agent file structure
# Usage: ./validate-agent.sh <agent-file.md>

set -e

AGENT_FILE="$1"

if [[ -z "$AGENT_FILE" ]]; then
    echo "Usage: ./validate-agent.sh <agent-file.md>"
    exit 1
fi

if [[ ! -f "$AGENT_FILE" ]]; then
    echo "ERROR: File not found: $AGENT_FILE"
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

echo "Validating agent: $AGENT_FILE"
echo "================================"

# Check frontmatter exists
if ! head -1 "$AGENT_FILE" | grep -q "^---"; then
    error "Missing YAML frontmatter (must start with ---)"
    exit 1
fi

success "Has YAML frontmatter"

# Extract frontmatter
FRONTMATTER=$(sed -n '/^---$/,/^---$/p' "$AGENT_FILE" | sed '1d;$d')

# Check name field
NAME=$(echo "$FRONTMATTER" | grep -E "^name:" | sed 's/name:[[:space:]]*//')
if [[ -z "$NAME" ]]; then
    error "Missing required 'name' field"
else
    success "Name: $NAME"

    # Validate name format
    if [[ ${#NAME} -lt 3 ]]; then
        error "Name too short (minimum 3 characters)"
    elif [[ ${#NAME} -gt 50 ]]; then
        error "Name too long (maximum 50 characters)"
    fi

    if [[ ! "$NAME" =~ ^[a-z][a-z0-9-]*[a-z0-9]$ ]]; then
        warning "Name should be lowercase with hyphens only"
    fi
fi

# Check description field
if echo "$FRONTMATTER" | grep -qE "^description:"; then
    success "Has description field"

    # Check for examples in description
    CONTENT=$(cat "$AGENT_FILE")
    if echo "$CONTENT" | grep -q "<example>"; then
        EXAMPLE_COUNT=$(echo "$CONTENT" | grep -c "<example>" || true)
        if [[ $EXAMPLE_COUNT -ge 2 ]]; then
            success "Has $EXAMPLE_COUNT example blocks (recommended: 2-4)"
        else
            warning "Only $EXAMPLE_COUNT example block (recommended: 2-4)"
        fi
    else
        warning "No <example> blocks in description (recommended for better triggering)"
    fi
else
    error "Missing required 'description' field"
fi

# Check model field
MODEL=$(echo "$FRONTMATTER" | grep -E "^model:" | sed 's/model:[[:space:]]*//')
if [[ -z "$MODEL" ]]; then
    error "Missing required 'model' field"
else
    case "$MODEL" in
        inherit|sonnet|opus|haiku)
            success "Model: $MODEL (valid)"
            ;;
        *)
            error "Invalid model: $MODEL (must be inherit, sonnet, opus, or haiku)"
            ;;
    esac
fi

# Check color field
COLOR=$(echo "$FRONTMATTER" | grep -E "^color:" | sed 's/color:[[:space:]]*//')
if [[ -z "$COLOR" ]]; then
    error "Missing required 'color' field"
else
    case "$COLOR" in
        blue|cyan|green|yellow|magenta|red)
            success "Color: $COLOR (valid)"
            ;;
        *)
            error "Invalid color: $COLOR (must be blue, cyan, green, yellow, magenta, or red)"
            ;;
    esac
fi

# Check system prompt (body content)
BODY=$(sed -n '/^---$/,/^---$/d;p' "$AGENT_FILE" | tail -n +2)
BODY_LENGTH=${#BODY}

if [[ $BODY_LENGTH -lt 100 ]]; then
    warning "System prompt is very short ($BODY_LENGTH chars) - consider adding more detail"
elif [[ $BODY_LENGTH -gt 10000 ]]; then
    warning "System prompt is very long ($BODY_LENGTH chars) - consider splitting into skill"
else
    success "System prompt length: $BODY_LENGTH characters"
fi

# Check for common system prompt sections
if echo "$BODY" | grep -qiE "responsibilities|process|steps"; then
    success "Has structured sections"
else
    warning "Consider adding structured sections (Responsibilities, Process, etc.)"
fi

echo ""
echo "================================"
echo "Validation Summary"
echo "================================"
echo -e "Errors:   ${RED}$ERRORS${NC}"
echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"

if [[ $ERRORS -gt 0 ]]; then
    echo -e "\n${RED}Agent validation FAILED${NC}"
    exit 1
else
    echo -e "\n${GREEN}Agent validation PASSED${NC}"
    exit 0
fi
