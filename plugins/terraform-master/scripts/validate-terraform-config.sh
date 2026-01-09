#!/bin/bash
# Comprehensive Terraform configuration validation

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=== Terraform Configuration Validation ==="
echo ""

# Check for Terraform or OpenTofu
if command -v terraform &> /dev/null; then
    TF_CMD="terraform"
elif command -v tofu &> /dev/null; then
    TF_CMD="tofu"
else
    echo -e "${RED}Error: Neither terraform nor tofu found${NC}"
    exit 1
fi

ERRORS=0
WARNINGS=0

# Step 1: Check for .tf files
echo "=== Checking Configuration Files ==="
echo ""

TF_FILES=$(find . -maxdepth 1 -name "*.tf" -type f 2>/dev/null | wc -l)
if [ "$TF_FILES" -eq 0 ]; then
    echo -e "${RED}✗ No .tf files found in current directory${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} Found $TF_FILES .tf files"

# Check for required files
if [ -f "versions.tf" ] || grep -l "required_version" *.tf &>/dev/null; then
    echo -e "${GREEN}✓${NC} Version constraints found"
else
    echo -e "${YELLOW}⚠${NC} No version constraints (versions.tf or required_version)"
    WARNINGS=$((WARNINGS + 1))
fi

if [ -f "variables.tf" ] || grep -l "^variable" *.tf &>/dev/null; then
    echo -e "${GREEN}✓${NC} Variables defined"
else
    echo -e "${YELLOW}○${NC} No variables defined"
fi

if [ -f "outputs.tf" ] || grep -l "^output" *.tf &>/dev/null; then
    echo -e "${GREEN}✓${NC} Outputs defined"
else
    echo -e "${YELLOW}○${NC} No outputs defined"
fi

echo ""

# Step 2: Format check
echo "=== Format Check ==="
echo ""

if $TF_CMD fmt -check -recursive &>/dev/null; then
    echo -e "${GREEN}✓${NC} All files properly formatted"
else
    echo -e "${YELLOW}⚠${NC} Some files need formatting"
    $TF_CMD fmt -check -recursive -diff 2>/dev/null | head -20
    WARNINGS=$((WARNINGS + 1))
fi

echo ""

# Step 3: Initialize check
echo "=== Initialization Check ==="
echo ""

if [ -d ".terraform" ]; then
    echo -e "${GREEN}✓${NC} Already initialized"
else
    echo -e "${BLUE}→${NC} Initializing..."
    if $TF_CMD init -backend=false &>/dev/null; then
        echo -e "${GREEN}✓${NC} Initialization successful"
    else
        echo -e "${RED}✗${NC} Initialization failed"
        ERRORS=$((ERRORS + 1))
    fi
fi

echo ""

# Step 4: Validate
echo "=== Validation ==="
echo ""

if $TF_CMD validate &>/dev/null; then
    echo -e "${GREEN}✓${NC} Configuration is valid"
else
    echo -e "${RED}✗${NC} Validation failed"
    $TF_CMD validate
    ERRORS=$((ERRORS + 1))
fi

echo ""

# Step 5: Security check (if trivy available)
echo "=== Security Check ==="
echo ""

if command -v trivy &> /dev/null; then
    echo "Running Trivy security scan..."
    if trivy config . --severity HIGH,CRITICAL --exit-code 0 2>/dev/null; then
        HIGH_COUNT=$(trivy config . --severity HIGH,CRITICAL --format json 2>/dev/null | grep -c '"Severity": "HIGH"' || echo 0)
        CRITICAL_COUNT=$(trivy config . --severity CRITICAL --format json 2>/dev/null | grep -c '"Severity": "CRITICAL"' || echo 0)

        if [ "$CRITICAL_COUNT" -gt 0 ]; then
            echo -e "${RED}✗ $CRITICAL_COUNT CRITICAL issues found${NC}"
            ERRORS=$((ERRORS + CRITICAL_COUNT))
        fi

        if [ "$HIGH_COUNT" -gt 0 ]; then
            echo -e "${YELLOW}⚠ $HIGH_COUNT HIGH severity issues found${NC}"
            WARNINGS=$((WARNINGS + HIGH_COUNT))
        fi

        if [ "$CRITICAL_COUNT" -eq 0 ] && [ "$HIGH_COUNT" -eq 0 ]; then
            echo -e "${GREEN}✓${NC} No HIGH or CRITICAL issues"
        fi
    else
        echo -e "${YELLOW}⚠${NC} Trivy scan had issues"
    fi
elif command -v checkov &> /dev/null; then
    echo "Running Checkov scan..."
    checkov -d . --framework terraform --quiet 2>/dev/null | head -20 || true
else
    echo -e "${YELLOW}○${NC} No security scanner available (install trivy or checkov)"
fi

echo ""

# Step 6: Best practices check
echo "=== Best Practices Check ==="
echo ""

# Check for hardcoded secrets
if grep -rE "(password|secret|key)\s*=\s*\"[^\"]+\"" *.tf 2>/dev/null | grep -v "key_vault\|kms_key\|secret_id" | head -5; then
    echo -e "${RED}✗ Potential hardcoded secrets found${NC}"
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}✓${NC} No obvious hardcoded secrets"
fi

# Check for missing descriptions
VARS_WITHOUT_DESC=$(grep -l "^variable" *.tf 2>/dev/null | xargs grep -L "description" 2>/dev/null | wc -l || echo 0)
if [ "$VARS_WITHOUT_DESC" -gt 0 ]; then
    echo -e "${YELLOW}⚠${NC} $VARS_WITHOUT_DESC variables missing descriptions"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${GREEN}✓${NC} All variables have descriptions"
fi

# Check for missing tags
if grep -q "resource \"aws_\|resource \"azurerm_\|resource \"google_" *.tf 2>/dev/null; then
    if ! grep -q "tags\s*=" *.tf 2>/dev/null; then
        echo -e "${YELLOW}⚠${NC} Resources may be missing tags"
        WARNINGS=$((WARNINGS + 1))
    else
        echo -e "${GREEN}✓${NC} Tags found in configuration"
    fi
fi

echo ""

# Summary
echo "=== Summary ==="
echo ""
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ $WARNINGS warnings found${NC}"
else
    echo -e "${RED}✗ $ERRORS errors, $WARNINGS warnings${NC}"
fi

echo ""
exit $ERRORS
