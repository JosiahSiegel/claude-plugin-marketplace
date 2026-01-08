#!/bin/bash
# Validate Claude Code plugin structure and configuration
# Usage: ./validate-plugin.sh [plugin-path]

set -e

PLUGIN_PATH="${1:-.}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

echo "Validating plugin at: $PLUGIN_PATH"
echo "=================================="

# Check plugin.json exists
MANIFEST="$PLUGIN_PATH/.claude-plugin/plugin.json"
if [[ ! -f "$MANIFEST" ]]; then
    error "plugin.json not found at .claude-plugin/plugin.json"
    echo "Plugin validation FAILED"
    exit 1
fi

success "plugin.json found"

# Validate JSON syntax
if ! python -c "import json; json.load(open('$MANIFEST'))" 2>/dev/null; then
    if ! node -e "require('$MANIFEST')" 2>/dev/null; then
        error "plugin.json has invalid JSON syntax"
    fi
else
    success "Valid JSON syntax"
fi

# Check required fields
NAME=$(python -c "import json; print(json.load(open('$MANIFEST')).get('name', ''))" 2>/dev/null)
if [[ -z "$NAME" ]]; then
    error "Missing required 'name' field"
else
    success "Name: $NAME"

    # Validate name format
    if [[ ! "$NAME" =~ ^[a-z][a-z0-9-]*[a-z0-9]$ ]]; then
        warning "Name should be kebab-case (lowercase, hyphens)"
    fi
fi

# Check author format
AUTHOR_TYPE=$(python -c "import json; a=json.load(open('$MANIFEST')).get('author'); print(type(a).__name__)" 2>/dev/null)
if [[ "$AUTHOR_TYPE" == "str" ]]; then
    error "author must be an object { \"name\": \"...\" }, not a string"
elif [[ "$AUTHOR_TYPE" == "dict" ]]; then
    success "Author is correctly formatted as object"
else
    warning "Missing author field"
fi

# Check version format
VERSION=$(python -c "import json; print(json.load(open('$MANIFEST')).get('version', ''))" 2>/dev/null)
if [[ -n "$VERSION" ]]; then
    if [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        success "Version: $VERSION (valid semver)"
    else
        warning "Version '$VERSION' is not valid semver (X.Y.Z)"
    fi
else
    warning "Missing version field"
fi

# Check keywords format
KEYWORDS_TYPE=$(python -c "import json; k=json.load(open('$MANIFEST')).get('keywords'); print(type(k).__name__ if k else 'none')" 2>/dev/null)
if [[ "$KEYWORDS_TYPE" == "list" ]]; then
    success "Keywords is correctly formatted as array"
elif [[ "$KEYWORDS_TYPE" == "str" ]]; then
    error "keywords must be an array [\"word1\", \"word2\"], not a string"
fi

# Check for deprecated fields
HAS_AGENTS=$(python -c "import json; print('agents' in json.load(open('$MANIFEST')))" 2>/dev/null)
HAS_SKILLS=$(python -c "import json; print('skills' in json.load(open('$MANIFEST')))" 2>/dev/null)
if [[ "$HAS_AGENTS" == "True" ]]; then
    warning "Remove 'agents' field - agents are auto-discovered"
fi
if [[ "$HAS_SKILLS" == "True" ]]; then
    warning "Remove 'skills' field - skills are auto-discovered"
fi

echo ""
echo "Checking components..."
echo "======================"

# Check agents
if [[ -d "$PLUGIN_PATH/agents" ]]; then
    AGENT_COUNT=$(find "$PLUGIN_PATH/agents" -name "*.md" 2>/dev/null | wc -l)
    success "Found $AGENT_COUNT agent(s)"

    # Check each agent has frontmatter
    for agent in "$PLUGIN_PATH"/agents/*.md; do
        [[ ! -f "$agent" ]] && continue
        if ! head -1 "$agent" | grep -q "^---"; then
            error "Agent $(basename "$agent") missing YAML frontmatter"
        fi
    done
fi

# Check commands
if [[ -d "$PLUGIN_PATH/commands" ]]; then
    CMD_COUNT=$(find "$PLUGIN_PATH/commands" -name "*.md" 2>/dev/null | wc -l)
    success "Found $CMD_COUNT command(s)"

    # Check each command has frontmatter
    for cmd in "$PLUGIN_PATH"/commands/*.md; do
        [[ ! -f "$cmd" ]] && continue
        if ! head -1 "$cmd" | grep -q "^---"; then
            error "Command $(basename "$cmd") missing YAML frontmatter"
        fi
    done
fi

# Check skills
if [[ -d "$PLUGIN_PATH/skills" ]]; then
    SKILL_COUNT=$(find "$PLUGIN_PATH/skills" -name "SKILL.md" 2>/dev/null | wc -l)
    success "Found $SKILL_COUNT skill(s)"

    # Check each skill has frontmatter
    for skill in "$PLUGIN_PATH"/skills/*/SKILL.md; do
        [[ ! -f "$skill" ]] && continue
        if ! head -1 "$skill" | grep -q "^---"; then
            error "Skill $(dirname "$skill" | xargs basename) missing YAML frontmatter"
        fi
    done
fi

# Check hooks
if [[ -f "$PLUGIN_PATH/hooks/hooks.json" ]]; then
    if python -c "import json; json.load(open('$PLUGIN_PATH/hooks/hooks.json'))" 2>/dev/null; then
        success "hooks.json has valid syntax"
    else
        error "hooks.json has invalid JSON syntax"
    fi
fi

echo ""
echo "=================================="
echo "Validation Summary"
echo "=================================="
echo -e "Errors:   ${RED}$ERRORS${NC}"
echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"

if [[ $ERRORS -gt 0 ]]; then
    echo -e "\n${RED}Plugin validation FAILED${NC}"
    exit 1
else
    echo -e "\n${GREEN}Plugin validation PASSED${NC}"
    exit 0
fi
