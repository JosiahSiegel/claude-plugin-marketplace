---
name: tf-init
description: Initialize Terraform workspace with backend configuration
argument-hint: "[backend-config options]"
---

# Terraform Init Command

Initialize a Terraform working directory with proper backend configuration.

## Usage

```
/tf-init                          # Basic init with upgrade
/tf-init -reconfigure            # Reconfigure backend
/tf-init key=prod.tfstate        # Backend config override
```

## What This Command Does

1. Detects current working directory
2. Checks for existing .terraform directory
3. Runs `terraform init` with appropriate flags
4. Handles backend configuration
5. Reports initialization status

## Execution Steps

### Step 1: Check Environment
```bash
# Verify terraform is available
terraform version

# Check for existing config
ls -la *.tf 2>/dev/null || echo "No .tf files found"
```

### Step 2: Run Init
```bash
# Basic init with upgrade
terraform init -upgrade

# With backend config (if provided)
terraform init -upgrade -backend-config="key=${ARGS}"

# Reconfigure (if -reconfigure flag)
terraform init -reconfigure
```

### Step 3: Validate
```bash
# Verify initialization
terraform validate
```

## Common Options

| Option | Description |
|--------|-------------|
| `-upgrade` | Upgrade providers and modules |
| `-reconfigure` | Reconfigure backend, ignoring existing |
| `-migrate-state` | Migrate state to new backend |
| `-backend-config=KEY=VALUE` | Override backend config |
| `-backend=false` | Skip backend initialization |

## Examples

### Initialize New Project
```bash
terraform init -upgrade
```

### Change Backend Configuration
```bash
terraform init -reconfigure -backend-config="key=prod.tfstate"
```

### Migrate to New Backend
```bash
terraform init -migrate-state
```

## Troubleshooting

### Backend Configuration Error
```bash
# Remove existing backend config
rm -rf .terraform
terraform init
```

### Provider Download Failure
```bash
# Clear provider cache
rm -rf .terraform/providers
terraform init -upgrade
```
