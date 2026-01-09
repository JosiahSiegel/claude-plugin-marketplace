#!/bin/bash
# List and analyze Terraform resources in state

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

print_usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --by-type       Group resources by type"
    echo "  --by-module     Group resources by module"
    echo "  --count         Show count only"
    echo "  --filter TYPE   Filter by resource type"
    echo "  --help          Show this help"
    echo ""
}

# Check for Terraform or OpenTofu
if command -v terraform &> /dev/null; then
    TF_CMD="terraform"
elif command -v tofu &> /dev/null; then
    TF_CMD="tofu"
else
    echo -e "${RED}Error: Neither terraform nor tofu found${NC}"
    exit 1
fi

BY_TYPE=false
BY_MODULE=false
COUNT_ONLY=false
FILTER=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --by-type)
            BY_TYPE=true
            shift
            ;;
        --by-module)
            BY_MODULE=true
            shift
            ;;
        --count)
            COUNT_ONLY=true
            shift
            ;;
        --filter)
            FILTER="$2"
            shift 2
            ;;
        --help|-h)
            print_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
done

echo "=== Terraform State Resources ==="
echo ""

# Check if initialized
if [ ! -d ".terraform" ]; then
    echo -e "${YELLOW}⚠ Not initialized. Run 'terraform init' first.${NC}"
    exit 1
fi

# Get all resources
RESOURCES=$($TF_CMD state list 2>/dev/null)

if [ -z "$RESOURCES" ]; then
    echo -e "${YELLOW}No resources in state${NC}"
    exit 0
fi

# Apply filter if specified
if [ -n "$FILTER" ]; then
    RESOURCES=$(echo "$RESOURCES" | grep -i "$FILTER" || echo "")
    if [ -z "$RESOURCES" ]; then
        echo -e "${YELLOW}No resources matching filter: $FILTER${NC}"
        exit 0
    fi
fi

TOTAL=$(echo "$RESOURCES" | wc -l)

if [ "$COUNT_ONLY" = true ]; then
    echo "Total resources: $TOTAL"
    exit 0
fi

if [ "$BY_TYPE" = true ]; then
    echo "=== Resources by Type ==="
    echo ""

    # Extract and count types
    TYPES=$(echo "$RESOURCES" | sed 's/\[.*$//' | sed 's/module\.[^.]*\.//' | sort | uniq -c | sort -rn)

    echo "$TYPES" | while read COUNT TYPE; do
        # Color by provider
        if [[ "$TYPE" == aws_* ]]; then
            echo -e "${YELLOW}$TYPE${NC}: $COUNT"
        elif [[ "$TYPE" == azurerm_* ]]; then
            echo -e "${BLUE}$TYPE${NC}: $COUNT"
        elif [[ "$TYPE" == google_* ]]; then
            echo -e "${RED}$TYPE${NC}: $COUNT"
        else
            echo -e "${CYAN}$TYPE${NC}: $COUNT"
        fi
    done

    echo ""
    echo -e "Total: ${GREEN}$TOTAL${NC} resources"

elif [ "$BY_MODULE" = true ]; then
    echo "=== Resources by Module ==="
    echo ""

    # Root module
    ROOT_COUNT=$(echo "$RESOURCES" | grep -v "^module\." | wc -l)
    if [ "$ROOT_COUNT" -gt 0 ]; then
        echo -e "${MAGENTA}root${NC}: $ROOT_COUNT resources"
        echo "$RESOURCES" | grep -v "^module\." | sed 's/^/  /'
        echo ""
    fi

    # Child modules
    MODULES=$(echo "$RESOURCES" | grep "^module\." | sed 's/^module\.\([^.]*\)\..*/\1/' | sort -u)

    for MODULE in $MODULES; do
        MOD_COUNT=$(echo "$RESOURCES" | grep "^module\.$MODULE\." | wc -l)
        echo -e "${CYAN}module.$MODULE${NC}: $MOD_COUNT resources"
        echo "$RESOURCES" | grep "^module\.$MODULE\." | sed 's/^/  /'
        echo ""
    done

    echo -e "Total: ${GREEN}$TOTAL${NC} resources"

else
    # Default: list all
    echo "$RESOURCES" | while read RESOURCE; do
        # Color by provider
        if [[ "$RESOURCE" == *aws_* ]]; then
            echo -e "${YELLOW}$RESOURCE${NC}"
        elif [[ "$RESOURCE" == *azurerm_* ]]; then
            echo -e "${BLUE}$RESOURCE${NC}"
        elif [[ "$RESOURCE" == *google_* ]]; then
            echo -e "${RED}$RESOURCE${NC}"
        elif [[ "$RESOURCE" == module.* ]]; then
            echo -e "${CYAN}$RESOURCE${NC}"
        else
            echo "$RESOURCE"
        fi
    done

    echo ""
    echo -e "Total: ${GREEN}$TOTAL${NC} resources"
fi

echo ""

# Show state size warning
STATE_SIZE=$(ls -l terraform.tfstate 2>/dev/null | awk '{print $5}' || echo "0")
if [ "$STATE_SIZE" -gt 10485760 ]; then  # 10MB
    echo -e "${YELLOW}⚠ State file is large ($(numfmt --to=iec $STATE_SIZE))${NC}"
    echo "  Consider splitting into multiple states"
fi

if [ "$TOTAL" -gt 200 ]; then
    echo -e "${YELLOW}⚠ Large number of resources ($TOTAL)${NC}"
    echo "  Consider:"
    echo "  - Splitting state by environment/component"
    echo "  - Using workspaces or separate directories"
    echo "  - Increasing parallelism for faster operations"
fi
