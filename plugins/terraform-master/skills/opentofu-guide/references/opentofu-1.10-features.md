# OpenTofu 1.10 Features Reference

## OCI Registry Support

Install modules from OCI (Open Container Initiative) registries:

```hcl
module "networking" {
  source  = "oci://ghcr.io/myorg/terraform-modules/networking"
  version = "1.0.0"
}
```

### Registry Configuration
```hcl
# terraform.tf
terraform {
  required_providers {
    # OCI registry for providers
    custom = {
      source = "oci://registry.example.com/providers/custom"
    }
  }
}
```

## Native S3 Locking (No DynamoDB!)

OpenTofu 1.10+ uses native S3 locking features - no DynamoDB table required:

```hcl
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "terraform.tfstate"
    region = "us-east-1"

    # Native S3 locking - no dynamodb_table needed!
    use_lockfile = true
  }
}
```

### Migration from DynamoDB Locking
```bash
# 1. Backup current state
tofu state pull > backup.tfstate

# 2. Update backend config (remove dynamodb_table)
# 3. Migrate state
tofu init -migrate-state
```

## Deprecation Warnings

Declare variables and outputs as deprecated:

```hcl
variable "old_name" {
  type        = string
  description = "Use 'new_name' instead"
  deprecated  = "This variable is deprecated. Use 'new_name' variable instead."
}

output "old_output" {
  value       = local.some_value
  deprecated  = "Use 'new_output' instead. Will be removed in v2.0."
}
```

## OpenTelemetry Tracing

Local observability for debugging and performance analysis:

```bash
# Enable OpenTelemetry
export OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:4317"
export OTEL_SERVICE_NAME="opentofu"

# Run with tracing
tofu plan
```

### Trace Configuration
```hcl
# opentofu.config
telemetry {
  enabled = true
  exporter = "otlp"
  endpoint = "http://localhost:4317"
}
```

## Enhanced Planning Options

### Target File
```bash
# Specify targets from file
echo "module.networking" > targets.txt
echo "aws_instance.web" >> targets.txt

tofu plan -target-file=targets.txt
```

### Exclude File
```bash
# Exclude resources from plan
echo "aws_instance.bastion" > exclude.txt

tofu plan -exclude-file=exclude.txt
```

## Global Provider Cache

Safe for concurrent use with file locking:

```bash
# Enable global cache
export TF_PLUGIN_CACHE_DIR="$HOME/.tofu/plugin-cache"

# Initialize multiple workspaces concurrently
tofu -chdir=project1 init &
tofu -chdir=project2 init &
wait
```

## State Encryption Enhancements

### External Key Provider
```hcl
encryption {
  state {
    method = "external"
    keys {
      name    = "vault_key"
      command = "/usr/local/bin/vault-key-provider"
      args    = ["--key-id", "terraform-state"]
    }
  }
}
```

### PBKDF2 Key Derivation
```hcl
encryption {
  state {
    method = "aes_gcm"
    keys {
      name       = "derived_key"
      passphrase = env.TOFU_PASSPHRASE

      # Key derivation settings
      pbkdf2 {
        iterations = 600000
        hash       = "sha256"
        salt       = env.TOFU_SALT
      }
    }
  }
}
```

## Compatibility

OpenTofu 1.10 maintains compatibility with:
- Terraform 1.5.x configurations
- All existing providers
- Standard module sources (registry, git, local)
- Existing state files (automatic migration)

## Upgrade Path

```bash
# Check current version
tofu version

# Download 1.10
curl -fsSL https://get.opentofu.org/install-opentofu.sh | sh -s -- --version 1.10.6

# Verify
tofu version  # Should show 1.10.6
```
