---
name: tf-state
description: Manage Terraform state (list, show, mv, rm, pull, push)
argument-hint: "<subcommand> [args]"
---

# Terraform State Command

Manage and manipulate Terraform state.

## Usage

```
/tf-state list                    # List all resources
/tf-state show aws_vpc.main      # Show resource details
/tf-state mv old.name new.name   # Move/rename resource
/tf-state rm aws_instance.temp   # Remove from state
/tf-state pull                   # Download state
```

## Subcommands

### list - List Resources
```bash
# List all resources
terraform state list

# Filter by type
terraform state list | grep aws_instance

# Filter by resource ID
terraform state list -id=i-1234567890abcdef0
```

### show - Show Resource Details
```bash
# Show specific resource
terraform state show aws_vpc.main

# Show module resource
terraform state show module.networking.aws_subnet.private[0]
```

### mv - Move/Rename Resources
```bash
# Rename resource
terraform state mv aws_instance.old aws_instance.new

# Move to module
terraform state mv aws_vpc.main module.networking.aws_vpc.main

# Move between modules
terraform state mv module.old.aws_vpc.main module.new.aws_vpc.main

# Count to for_each migration
terraform state mv 'aws_subnet.public[0]' 'aws_subnet.public["us-east-1a"]'
```

### rm - Remove from State
```bash
# Remove single resource (resource still exists!)
terraform state rm aws_instance.temp

# Remove multiple resources
terraform state rm aws_instance.temp aws_subnet.temp

# Remove module
terraform state rm module.legacy

# Remove all of type
terraform state list | grep aws_subnet | xargs -I{} terraform state rm {}
```

### pull - Download State
```bash
# Download state to stdout
terraform state pull

# Save to file
terraform state pull > backup.tfstate

# Query with jq
terraform state pull | jq '.resources[] | select(.type == "aws_instance")'
```

### push - Upload State
```bash
# Push state (DANGEROUS!)
terraform state push backup.tfstate

# Force push (VERY DANGEROUS!)
terraform state push -force backup.tfstate
```

## Common Use Cases

### Rename Resource
```bash
# 1. Move in state
terraform state mv aws_rg.old_name aws_rg.new_name

# 2. Update config to match
# 3. Verify
terraform plan  # Should show no changes
```

### Move to Module
```bash
# 1. Create module in config
# 2. Move state
terraform state mv aws_vpc.main module.networking.aws_vpc.main
terraform state mv aws_subnet.public module.networking.aws_subnet.public

# 3. Update references
# 4. Verify
terraform plan
```

### Split State
```bash
# Source state
terraform state rm aws_vpc.shared

# Target state (different directory)
cd ../networking
terraform import aws_vpc.shared vpc-12345678
```

### Recover from Disaster
```bash
# Restore from backup
terraform state pull > current_state.tfstate.backup
terraform state push previous_backup.tfstate
```

## Safety Tips

1. **ALWAYS backup** before state operations
   ```bash
   terraform state pull > backup-$(date +%Y%m%d).tfstate
   ```

2. **Test in non-prod first**

3. **Verify with plan** after operations
   ```bash
   terraform plan  # Should show no changes
   ```

4. **Never manually edit** state JSON

5. **Use -dry-run** when available
   ```bash
   terraform state mv -dry-run old new
   ```

## Troubleshooting

### State Lock Error
```bash
# Check who holds lock
terraform state list  # Shows lock error with info

# Force unlock (last resort)
terraform force-unlock LOCK_ID
```

### Resource Not Found
```bash
# Check exact address
terraform state list | grep -i resource_name

# Check modules
terraform state list | grep module
```
