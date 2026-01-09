# OpenTofu State Encryption Reference

## Overview

OpenTofu provides built-in state encryption at no cost - a feature that requires HCP Terraform (paid) in Terraform.

## Basic Configuration

### AES-GCM Encryption
```hcl
# encryption.tf or .tofu file
encryption {
  state {
    method = "aes_gcm"
    keys {
      name       = "primary_key"
      passphrase = env.TOFU_ENCRYPTION_KEY
    }
  }

  plan {
    method = "aes_gcm"
    keys {
      name       = "primary_key"
      passphrase = env.TOFU_ENCRYPTION_KEY
    }
  }
}
```

### Generate Strong Key
```bash
# Generate 256-bit key
openssl rand -base64 32
# Output: K8x/4Xq2pR7mN1bL5tYz9wA3eI6uO0sC=

# Set environment variable
export TOFU_ENCRYPTION_KEY="K8x/4Xq2pR7mN1bL5tYz9wA3eI6uO0sC="
```

## Cloud KMS Integration

### AWS KMS
```hcl
encryption {
  state {
    method = "aws_kms"
    keys {
      name       = "aws_key"
      kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
    }
  }
}
```

### Azure Key Vault
```hcl
encryption {
  state {
    method = "azurerm_key_vault"
    keys {
      name             = "azure_key"
      key_vault_key_id = "https://myvault.vault.azure.net/keys/tofu-state-key/version123"
    }
  }
}
```

### GCP KMS
```hcl
encryption {
  state {
    method = "gcp_kms"
    keys {
      name           = "gcp_key"
      kms_crypto_key = "projects/my-project/locations/global/keyRings/tofu/cryptoKeys/state-key"
    }
  }
}
```

### HashiCorp Vault
```hcl
encryption {
  state {
    method = "vault"
    keys {
      name       = "vault_key"
      vault_path = "transit/keys/tofu-state"
    }
  }
}
```

## Key Rotation

### Manual Rotation
```hcl
encryption {
  state {
    method = "aes_gcm"
    keys {
      # New key for encryption
      name       = "key_v2"
      passphrase = env.TOFU_KEY_V2

      # Old key for decryption fallback
      fallback {
        name       = "key_v1"
        passphrase = env.TOFU_KEY_V1
      }
    }
  }
}
```

```bash
# Set both keys
export TOFU_KEY_V1="old-key-value"
export TOFU_KEY_V2="new-key-value"

# Migrate state to new key
tofu init -migrate-state

# After successful migration, remove old key from config
```

### Automated Rotation (KMS)
```hcl
# KMS handles rotation automatically
encryption {
  state {
    method = "aws_kms"
    keys {
      name       = "aws_key"
      kms_key_id = "alias/tofu-state"  # Use alias, AWS rotates underlying key
    }
  }
}
```

## Migration Scenarios

### Enable Encryption on Existing State
```bash
# 1. Backup unencrypted state
tofu state pull > backup-$(date +%Y%m%d).tfstate

# 2. Add encryption config
cat >> encryption.tf <<EOF
encryption {
  state {
    method = "aes_gcm"
    keys {
      name       = "primary"
      passphrase = env.TOFU_ENCRYPTION_KEY
    }
  }
}
EOF

# 3. Set key
export TOFU_ENCRYPTION_KEY="$(openssl rand -base64 32)"

# 4. Migrate
tofu init -migrate-state

# 5. Verify
tofu state pull  # Should work
cat terraform.tfstate  # Should be encrypted if local
```

### Disable Encryption
```bash
# 1. Remove encryption block from config
# 2. Migrate state
tofu init -migrate-state
```

### Change Encryption Method
```bash
# 1. Keep old method as fallback
encryption {
  state {
    method = "aws_kms"  # New method
    keys {
      name       = "new_key"
      kms_key_id = "arn:aws:kms:..."

      fallback {
        method = "aes_gcm"  # Old method
        name   = "old_key"
        passphrase = env.TOFU_OLD_KEY
      }
    }
  }
}

# 2. Migrate
tofu init -migrate-state
```

## CI/CD Integration

### GitHub Actions
```yaml
- name: OpenTofu Apply
  env:
    TOFU_ENCRYPTION_KEY: ${{ secrets.TOFU_ENCRYPTION_KEY }}
    AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
    AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
  run: |
    tofu init
    tofu apply -auto-approve
```

### Azure DevOps
```yaml
- task: Bash@3
  displayName: 'OpenTofu Apply'
  env:
    TOFU_ENCRYPTION_KEY: $(TOFU_ENCRYPTION_KEY)
  inputs:
    targetType: 'inline'
    script: |
      tofu init
      tofu apply -auto-approve
```

### GitLab CI
```yaml
apply:
  image: ghcr.io/opentofu/opentofu:1.10
  variables:
    TOFU_ENCRYPTION_KEY: ${TOFU_ENCRYPTION_KEY}
  script:
    - tofu init
    - tofu apply -auto-approve
```

## Best Practices

1. **Never commit keys**: Use environment variables or secrets management
2. **Backup keys securely**: Store in password manager or secrets vault
3. **Use KMS in production**: Cloud KMS provides automatic rotation
4. **Test key rotation**: Practice rotation in non-production first
5. **Encrypt both state and plan**: Sensitive data in both
6. **Document key storage**: Team should know where keys are stored

## Troubleshooting

### "Unable to decrypt state"
```bash
# Check key is set
echo $TOFU_ENCRYPTION_KEY

# Check key matches
# (compare hash if you stored it)
echo -n "$TOFU_ENCRYPTION_KEY" | sha256sum
```

### "State encrypted with unknown method"
```bash
# Add fallback for old method
encryption {
  state {
    method = "new_method"
    keys {
      fallback {
        method = "old_method"
        # ...
      }
    }
  }
}
```

## Comparison: OpenTofu vs Terraform

| Feature | OpenTofu | Terraform |
|---------|----------|-----------|
| Built-in encryption | ✅ Free | ❌ HCP Terraform only |
| AES-GCM | ✅ | ✅ (HCP) |
| AWS KMS | ✅ | ✅ (HCP) |
| Azure Key Vault | ✅ | ✅ (HCP) |
| GCP KMS | ✅ | ✅ (HCP) |
| Key rotation | ✅ | ✅ (HCP) |
| Cost | Free | HCP pricing |
