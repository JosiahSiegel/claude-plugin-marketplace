---
name: tf-plan
description: Generate and review Terraform execution plan
argument-hint: "[var-file] [-target=resource] [-out=planfile]"
---

# Terraform Plan Command

Generate an execution plan showing what Terraform will do.

## Usage

```
/tf-plan                          # Basic plan
/tf-plan prod.tfvars             # With var file
/tf-plan -target=module.vpc      # Target specific resource
/tf-plan -out=tfplan             # Save plan to file
```

## What This Command Does

1. Refreshes state (unless -refresh=false)
2. Compares desired state with actual state
3. Generates execution plan
4. Shows what will be created, changed, or destroyed
5. Optionally saves plan to file

## Execution Steps

### Step 1: Pre-Flight Checks
```bash
# Verify initialization
terraform validate

# Check formatting
terraform fmt -check
```

### Step 2: Run Plan
```bash
# Basic plan
terraform plan

# With var file
terraform plan -var-file="${ARGS}"

# With target
terraform plan -target="${TARGET}"

# Save plan
terraform plan -out=tfplan

# CI/CD optimized
terraform plan -no-color -out=tfplan -detailed-exitcode
```

### Step 3: Review Output
Plan output shows:
- `+` Resources to create
- `-` Resources to destroy
- `~` Resources to modify
- `+/-` Resources to replace

## Common Options

| Option | Description |
|--------|-------------|
| `-var-file=FILE` | Load variables from file |
| `-var='KEY=VALUE'` | Set individual variable |
| `-target=RESOURCE` | Plan specific resource |
| `-out=FILE` | Save plan to file |
| `-refresh=false` | Skip state refresh |
| `-detailed-exitcode` | Return 2 if changes |
| `-no-color` | Disable colored output |
| `-parallelism=N` | Limit parallel operations |

## Exit Codes (with -detailed-exitcode)

| Code | Meaning |
|------|---------|
| 0 | No changes |
| 1 | Error |
| 2 | Changes detected |

## Examples

### Basic Plan
```bash
terraform plan
```

### Plan with Variables
```bash
terraform plan -var-file="environments/prod.tfvars"
```

### Plan Specific Resource
```bash
terraform plan -target=aws_instance.web
terraform plan -target=module.networking
```

### CI/CD Plan
```bash
terraform plan \
  -no-color \
  -out=tfplan \
  -detailed-exitcode \
  -var-file="prod.tfvars"
```

## Best Practices

1. Always review plan before apply
2. Save plan to file in CI/CD
3. Use `-detailed-exitcode` for automation
4. Target cautiously (may miss dependencies)
