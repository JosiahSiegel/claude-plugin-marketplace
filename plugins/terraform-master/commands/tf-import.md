---
name: tf-import
description: Import existing infrastructure into Terraform state
argument-hint: "<resource_address> <resource_id>"
---

# Terraform Import Command

Import existing infrastructure resources into Terraform management.

## Usage

```
/tf-import aws_vpc.main vpc-12345678
/tf-import azurerm_resource_group.main /subscriptions/.../resourceGroups/my-rg
/tf-import --generate-config        # Generate config for imports (1.5+)
```

## What This Command Does

1. Identifies existing resource in cloud
2. Creates state entry for resource
3. Associates resource with Terraform configuration
4. Does NOT generate configuration (traditional import)
5. CAN generate configuration (1.5+ import blocks)

## Import Methods

### Method 1: Traditional Import (All Versions)
```bash
# Requires existing resource block in config
terraform import aws_instance.web i-1234567890abcdef0
```

### Method 2: Import Blocks (Terraform 1.5+)
```hcl
# imports.tf
import {
  to = aws_instance.web
  id = "i-1234567890abcdef0"
}

# Generate configuration
terraform plan -generate-config-out=generated.tf
terraform apply
```

## Common Resource IDs

### AWS
```bash
# EC2 Instance
terraform import aws_instance.web i-1234567890abcdef0

# VPC
terraform import aws_vpc.main vpc-12345678

# S3 Bucket
terraform import aws_s3_bucket.main my-bucket-name

# Security Group
terraform import aws_security_group.main sg-12345678

# IAM Role
terraform import aws_iam_role.main role-name
```

### Azure
```bash
# Resource Group
terraform import azurerm_resource_group.main /subscriptions/SUB_ID/resourceGroups/my-rg

# Storage Account
terraform import azurerm_storage_account.main /subscriptions/SUB_ID/resourceGroups/my-rg/providers/Microsoft.Storage/storageAccounts/mystorageaccount

# Virtual Network
terraform import azurerm_virtual_network.main /subscriptions/SUB_ID/resourceGroups/my-rg/providers/Microsoft.Network/virtualNetworks/my-vnet
```

### GCP
```bash
# Compute Instance
terraform import google_compute_instance.main projects/my-project/zones/us-central1-a/instances/my-instance

# VPC Network
terraform import google_compute_network.main projects/my-project/global/networks/my-network

# GCS Bucket
terraform import google_storage_bucket.main my-bucket-name
```

## Import Block Examples (1.5+)

```hcl
# Single import
import {
  to = aws_vpc.main
  id = "vpc-12345678"
}

# Multiple imports
import {
  to = aws_subnet.public[0]
  id = "subnet-aaaa1111"
}

import {
  to = aws_subnet.public[1]
  id = "subnet-bbbb2222"
}

# OpenTofu 1.7+: Looped imports
import {
  for_each = local.subnets
  to       = aws_subnet.imported[each.key]
  id       = each.value
}
```

## Workflow

### Step 1: Create Resource Block
```hcl
# main.tf
resource "aws_vpc" "main" {
  # Configuration will be filled after import
}
```

### Step 2: Import
```bash
terraform import aws_vpc.main vpc-12345678
```

### Step 3: Update Configuration
```bash
# Show imported state
terraform state show aws_vpc.main

# Update config to match
```

### Step 4: Verify
```bash
# Should show no changes
terraform plan
```

## Best Practices

1. Always backup state before importing
2. Import dependencies first (VPC before subnet)
3. Use import blocks for Terraform 1.5+
4. Verify with `terraform plan` showing no changes
5. Document imported resources
