---
name: tf-apply
description: Apply Terraform changes to infrastructure
argument-hint: "[planfile] [-auto-approve] [-target=resource]"
---

# Terraform Apply Command

Apply changes to reach the desired infrastructure state.

## Usage

```
/tf-apply                         # Interactive apply
/tf-apply tfplan                  # Apply saved plan
/tf-apply -auto-approve          # Non-interactive apply
/tf-apply -target=aws_instance.web  # Target specific resource
```

## What This Command Does

1. Reads plan (generates if not provided)
2. Confirms changes with user (unless -auto-approve)
3. Applies changes to infrastructure
4. Updates state file
5. Reports results

## Execution Steps

### Step 1: Pre-Flight Checks
```bash
# Verify initialization
terraform validate

# Review plan first
terraform plan
```

### Step 2: Run Apply
```bash
# Interactive (prompts for confirmation)
terraform apply

# Apply saved plan
terraform apply tfplan

# Non-interactive (CI/CD)
terraform apply -auto-approve

# With var file
terraform apply -var-file="prod.tfvars"
```

### Step 3: Verify
```bash
# Check outputs
terraform output

# Verify state
terraform state list
```

## Common Options

| Option | Description |
|--------|-------------|
| `planfile` | Apply saved plan file |
| `-auto-approve` | Skip confirmation |
| `-var-file=FILE` | Load variables |
| `-var='KEY=VALUE'` | Set variable |
| `-target=RESOURCE` | Apply to specific resource |
| `-parallelism=N` | Limit parallel operations |
| `-lock-timeout=DURATION` | State lock timeout |
| `-refresh=false` | Skip state refresh |

## Safety Guidelines

### Production Apply
```bash
# 1. Always plan first
terraform plan -out=tfplan

# 2. Review the plan carefully
# 3. Apply with timeout protection
terraform apply -lock-timeout=30m tfplan
```

### Never Do This
```bash
# Don't auto-approve without review
terraform apply -auto-approve  # Dangerous without prior plan review!

# Don't skip the plan step
terraform apply  # Always plan first
```

## Examples

### Standard Workflow
```bash
# 1. Plan and save
terraform plan -out=tfplan

# 2. Apply saved plan
terraform apply tfplan
```

### CI/CD Apply
```bash
# Apply with timeout and no color
terraform apply \
  -auto-approve \
  -lock-timeout=30m \
  -no-color \
  tfplan
```

### Target Specific Resource
```bash
terraform apply -target=aws_instance.web -auto-approve
```

## Troubleshooting

### State Lock Error
```bash
# Wait for lock or force unlock
terraform apply -lock-timeout=10m
# Or (dangerous): terraform force-unlock LOCK_ID
```

### Partial Apply Failure
```bash
# Don't panic - state reflects actual changes
# Fix the issue and re-run
terraform apply
```
