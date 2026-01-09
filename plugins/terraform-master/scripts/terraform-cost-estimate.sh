#!/bin/bash
# Estimate infrastructure costs using Infracost

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=== Terraform Cost Estimation ==="
echo ""

# Check for infracost
if ! command -v infracost &> /dev/null; then
    echo -e "${YELLOW}Infracost not installed${NC}"
    echo ""
    echo "Install Infracost:"
    echo ""
    echo "  macOS/Linux:"
    echo "    brew install infracost"
    echo ""
    echo "  Windows:"
    echo "    choco install infracost"
    echo ""
    echo "  Or download from: https://www.infracost.io/docs/"
    echo ""
    echo "Then register for free API key:"
    echo "  infracost auth login"
    echo ""
    exit 1
fi

# Check authentication
if ! infracost configure get api_key &>/dev/null; then
    echo -e "${YELLOW}Infracost not authenticated${NC}"
    echo ""
    echo "Run: infracost auth login"
    echo ""
    exit 1
fi

# Check for .tf files
if ! ls *.tf &>/dev/null; then
    echo -e "${RED}No .tf files found in current directory${NC}"
    exit 1
fi

# Parse arguments
OUTPUT_FORMAT="table"
SHOW_DIFF=false
USAGE_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --json)
            OUTPUT_FORMAT="json"
            shift
            ;;
        --diff)
            SHOW_DIFF=true
            shift
            ;;
        --usage-file)
            USAGE_FILE="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --json         Output in JSON format"
            echo "  --diff         Show cost difference from previous"
            echo "  --usage-file   Path to usage file for accurate estimates"
            echo "  --help         Show this help"
            echo ""
            exit 0
            ;;
        *)
            shift
            ;;
    esac
done

echo "Analyzing infrastructure costs..."
echo ""

# Build command
CMD="infracost breakdown --path . --format $OUTPUT_FORMAT"

if [ -n "$USAGE_FILE" ]; then
    CMD="$CMD --usage-file $USAGE_FILE"
fi

# Run estimate
if [ "$SHOW_DIFF" = true ]; then
    # Generate baseline
    echo "Generating baseline..."
    infracost breakdown --path . --format json --out-file /tmp/infracost-base.json 2>/dev/null

    echo "Run your changes, then use:"
    echo "  infracost diff --path . --compare-to /tmp/infracost-base.json"
    echo ""
else
    echo "=== Monthly Cost Estimate ==="
    echo ""
    $CMD
fi

echo ""
echo -e "${BLUE}Note:${NC} Costs are estimates. Actual costs may vary based on:"
echo "  - Usage patterns"
echo "  - Data transfer"
echo "  - Reserved instances"
echo "  - Spot instances"
echo ""

# Provide usage file hint
if [ -z "$USAGE_FILE" ]; then
    echo -e "${YELLOW}Tip:${NC} For more accurate estimates, create a usage file:"
    echo ""
    echo "  # infracost-usage.yml"
    echo "  version: 0.1"
    echo "  resource_usage:"
    echo "    aws_lambda_function.main:"
    echo "      monthly_requests: 1000000"
    echo "      request_duration_ms: 250"
    echo "    aws_s3_bucket.data:"
    echo "      storage_gb: 100"
    echo "      monthly_tier_1_requests: 50000"
    echo ""
    echo "Then run: $0 --usage-file infracost-usage.yml"
fi
