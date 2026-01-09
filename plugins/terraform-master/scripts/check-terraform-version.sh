#!/bin/bash
# Check Terraform/OpenTofu version and provider versions

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=== Terraform/OpenTofu Version Check ==="
echo ""

# Check for Terraform or OpenTofu
if command -v terraform &> /dev/null; then
    TF_CMD="terraform"
    TF_NAME="Terraform"
elif command -v tofu &> /dev/null; then
    TF_CMD="tofu"
    TF_NAME="OpenTofu"
else
    echo -e "${RED}Error: Neither terraform nor tofu found in PATH${NC}"
    exit 1
fi

# Get version
VERSION=$($TF_CMD version -json 2>/dev/null || $TF_CMD version | head -1)
if echo "$VERSION" | grep -q "terraform_version"; then
    # JSON output available
    TF_VERSION=$(echo "$VERSION" | grep -o '"terraform_version":"[^"]*"' | cut -d'"' -f4)
else
    # Plain text output
    TF_VERSION=$(echo "$VERSION" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
fi

echo -e "${GREEN}$TF_NAME Version:${NC} $TF_VERSION"
echo ""

# Version feature matrix
echo "=== Feature Availability ==="
echo ""

check_version() {
    local required=$1
    local current=$TF_VERSION

    # Compare versions
    if [ "$(printf '%s\n' "$required" "$current" | sort -V | head -1)" = "$required" ]; then
        return 0
    else
        return 1
    fi
}

# Check features
if check_version "1.5.0"; then
    echo -e "${GREEN}✓${NC} Import blocks"
    echo -e "${GREEN}✓${NC} Check blocks in tests"
else
    echo -e "${RED}✗${NC} Import blocks (requires 1.5+)"
fi

if check_version "1.6.0"; then
    echo -e "${GREEN}✓${NC} terraform test framework"
else
    echo -e "${YELLOW}○${NC} terraform test (requires 1.6+)"
fi

if check_version "1.7.0"; then
    echo -e "${GREEN}✓${NC} removed block"
    echo -e "${GREEN}✓${NC} Provider-defined functions"
else
    echo -e "${YELLOW}○${NC} removed block (requires 1.7+)"
fi

if check_version "1.10.0"; then
    echo -e "${GREEN}✓${NC} Ephemeral values"
else
    echo -e "${YELLOW}○${NC} Ephemeral values (requires 1.10+)"
fi

if check_version "1.11.0"; then
    echo -e "${GREEN}✓${NC} Write-only arguments"
else
    echo -e "${YELLOW}○${NC} Write-only arguments (requires 1.11+)"
fi

# OpenTofu specific features
if [ "$TF_NAME" = "OpenTofu" ]; then
    echo ""
    echo "=== OpenTofu Specific Features ==="
    echo ""

    if check_version "1.7.0"; then
        echo -e "${GREEN}✓${NC} State encryption"
        echo -e "${GREEN}✓${NC} Loop-able import blocks"
    fi

    if check_version "1.10.0"; then
        echo -e "${GREEN}✓${NC} OCI registry support"
        echo -e "${GREEN}✓${NC} Native S3 locking (no DynamoDB)"
    fi

    if check_version "1.11.0"; then
        echo -e "${GREEN}✓${NC} enabled meta-argument"
    fi
fi

echo ""

# Check for version file
if [ -f ".terraform-version" ]; then
    REQUIRED_VERSION=$(cat .terraform-version)
    echo "=== Project Version Requirement ==="
    echo ""
    echo -e "Required: ${BLUE}$REQUIRED_VERSION${NC}"
    echo -e "Current:  ${BLUE}$TF_VERSION${NC}"

    if [ "$REQUIRED_VERSION" = "$TF_VERSION" ]; then
        echo -e "${GREEN}✓ Version matches${NC}"
    else
        echo -e "${YELLOW}⚠ Version mismatch${NC}"
    fi
    echo ""
fi

# Check providers if initialized
if [ -d ".terraform" ]; then
    echo "=== Provider Versions ==="
    echo ""
    $TF_CMD providers 2>/dev/null || echo "Run 'terraform init' to see provider versions"
    echo ""
fi

# Check for lock file
if [ -f ".terraform.lock.hcl" ]; then
    echo "=== Lock File Providers ==="
    echo ""
    grep -E 'provider|version' .terraform.lock.hcl | head -20
    echo ""
fi

echo "=== Recommendations ==="
echo ""

if ! check_version "1.5.0"; then
    echo -e "${YELLOW}• Upgrade to 1.5+ for import blocks${NC}"
fi

if ! check_version "1.6.0"; then
    echo -e "${YELLOW}• Upgrade to 1.6+ for terraform test${NC}"
fi

if ! check_version "1.10.0"; then
    echo -e "${YELLOW}• Upgrade to 1.10+ for ephemeral values${NC}"
fi

if [ "$TF_NAME" = "Terraform" ]; then
    echo -e "${BLUE}• Consider OpenTofu for free state encryption${NC}"
fi

echo ""
