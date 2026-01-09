---
name: tf-validate
description: Validate Terraform configuration syntax and consistency
argument-hint: "[-json]"
---

# Terraform Validate Command

Validate configuration files for syntax and internal consistency.

## Usage

```
/tf-validate              # Basic validation
/tf-validate -json       # JSON output for CI/CD
```

## What This Command Does

1. Checks HCL syntax
2. Validates resource configurations
3. Checks provider requirements
4. Validates variable types
5. Checks module configurations
6. Does NOT access remote state or APIs

## Execution Steps

### Step 1: Initialize (Required)
```bash
# Must init first
terraform init
```

### Step 2: Validate
```bash
# Basic validation
terraform validate

# JSON output (CI/CD)
terraform validate -json

# No color (CI/CD)
terraform validate -no-color
```

### Step 3: Fix Issues
Common validation errors:
- Missing required arguments
- Invalid argument names
- Type mismatches
- Circular references
- Missing providers

## Output

### Success
```
Success! The configuration is valid.
```

### JSON Success
```json
{
  "valid": true,
  "error_count": 0,
  "warning_count": 0,
  "diagnostics": []
}
```

### Failure Example
```
Error: Missing required argument

  on main.tf line 5, in resource "aws_instance" "web":
   5: resource "aws_instance" "web" {

The argument "ami" is required, but no definition was found.
```

## CI/CD Integration

### GitHub Actions
```yaml
- name: Terraform Validate
  id: validate
  run: terraform validate -no-color
```

### With JSON Parsing
```yaml
- name: Terraform Validate
  id: validate
  run: |
    terraform validate -json > validation.json
    if [ $(jq '.valid' validation.json) != "true" ]; then
      jq '.diagnostics' validation.json
      exit 1
    fi
```

## Pre-Commit Hook

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.83.5
    hooks:
      - id: terraform_validate
```

## Common Errors

### Missing Provider
```
Error: Missing required provider

This configuration requires provider "aws", but no such provider
is configured. Please add a provider block.
```
**Fix:** Add provider configuration or required_providers block.

### Invalid Argument
```
Error: Unsupported argument

  on main.tf line 10, in resource "aws_instance" "web":
  10:   invalid_arg = "value"

An argument named "invalid_arg" is not expected here.
```
**Fix:** Check provider documentation for valid arguments.

### Type Mismatch
```
Error: Invalid value for input variable

The given value is not valid for variable "count": a number is required.
```
**Fix:** Ensure variable values match declared types.

## Best Practices

1. Run validate after every change
2. Include in CI/CD pipeline
3. Use as pre-commit hook
4. Check JSON output in automation
5. Always init before validate
