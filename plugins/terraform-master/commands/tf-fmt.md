---
name: tf-fmt
description: Format Terraform configuration files
argument-hint: "[-check] [-recursive] [-diff]"
---

# Terraform Format Command

Format Terraform configuration files to canonical style.

## Usage

```
/tf-fmt                   # Format current directory
/tf-fmt -check           # Check without changing
/tf-fmt -recursive       # Format all subdirectories
/tf-fmt -diff            # Show what would change
```

## What This Command Does

1. Reads .tf files
2. Applies canonical formatting
3. Rewrites files (unless -check)
4. Handles indentation, alignment, spacing
5. Processes subdirectories (with -recursive)

## Execution Steps

### Step 1: Check Format
```bash
# Check without changes
terraform fmt -check

# Check with diff output
terraform fmt -check -diff
```

### Step 2: Format Files
```bash
# Format current directory
terraform fmt

# Format recursively
terraform fmt -recursive

# Format specific file
terraform fmt main.tf
```

## Common Options

| Option | Description |
|--------|-------------|
| `-check` | Check only, don't modify |
| `-diff` | Show formatting changes |
| `-recursive` | Process subdirectories |
| `-write=false` | Don't write changes |
| `-list=false` | Don't list formatted files |

## CI/CD Integration

### GitHub Actions
```yaml
- name: Terraform Format Check
  id: fmt
  run: terraform fmt -check -recursive
  continue-on-error: true

- name: Format Status
  if: steps.fmt.outcome == 'failure'
  run: |
    echo "Terraform files are not formatted!"
    terraform fmt -recursive -diff
    exit 1
```

### Pre-Commit Hook
```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.83.5
    hooks:
      - id: terraform_fmt
```

### Git Pre-Commit (Manual)
```bash
#!/bin/sh
# .git/hooks/pre-commit

# Check Terraform formatting
if ! terraform fmt -check -recursive; then
    echo "Terraform files are not formatted. Run 'terraform fmt -recursive'"
    exit 1
fi
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All files formatted (or no changes needed) |
| 1 | Formatting errors found (with -check) |
| 2 | Command error |

## Examples

### Check All Files
```bash
terraform fmt -check -recursive
```

### Show What Would Change
```bash
terraform fmt -diff -recursive
```

### Format and List Changed Files
```bash
terraform fmt -recursive
# Output: main.tf
#         modules/vpc/main.tf
```

### Format Without Listing
```bash
terraform fmt -recursive -list=false
```

## Formatting Rules Applied

- 2-space indentation
- Aligned `=` signs in blocks
- Consistent spacing
- Sorted block attributes
- Standardized quotes

### Before
```hcl
resource "aws_instance" "web" {
ami = "ami-12345678"
  instance_type="t3.micro"
tags={Name="web"}
}
```

### After
```hcl
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"
  tags = {
    Name = "web"
  }
}
```

## Best Practices

1. Always format before commit
2. Use pre-commit hooks
3. Check in CI/CD (fail on unformatted)
4. Format recursively for full projects
5. Team should use same Terraform version
