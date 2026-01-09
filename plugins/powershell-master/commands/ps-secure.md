---
name: ps-secure
description: Set up SecretManagement vault and migrate hardcoded credentials
argument-hint: "<script.ps1 to migrate> or 'setup' for new vault"
allowed-tools:
  - Read
  - Edit
  - Write
  - Bash
  - Glob
  - Grep
---

# PowerShell SecretManagement Setup

Secure credential management using Microsoft.PowerShell.SecretManagement and SecretStore.

## Quick Setup

```powershell
# Install SecretManagement modules
Install-PSResource -Name Microsoft.PowerShell.SecretManagement -Scope CurrentUser
Install-PSResource -Name Microsoft.PowerShell.SecretStore -Scope CurrentUser

# Register the secret vault
Register-SecretVault -Name "LocalVault" -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault

# Configure vault (set password on first use)
Set-SecretStoreConfiguration -Scope CurrentUser -Authentication Password -PasswordTimeout 3600

# Store a secret
Set-Secret -Name "ApiKey" -Secret "your-api-key-here" -Vault "LocalVault"
Set-Secret -Name "DbConnection" -Secret "Server=...;Database=..." -Vault "LocalVault"

# Store a credential object
$cred = Get-Credential -Message "Enter service account credentials"
Set-Secret -Name "ServiceAccount" -Secret $cred -Vault "LocalVault"

# Retrieve secrets
$apiKey = Get-Secret -Name "ApiKey" -AsPlainText
$dbConn = Get-Secret -Name "DbConnection" -AsPlainText
$cred = Get-Secret -Name "ServiceAccount"  # Returns PSCredential
```

## Migration Patterns

### From Hardcoded Credentials

```powershell
# BEFORE (insecure)
$password = "MyP@ssw0rd!"
$username = "admin"
$cred = New-Object PSCredential($username, (ConvertTo-SecureString $password -AsPlainText -Force))

# AFTER (secure)
$cred = Get-Secret -Name "AdminCredential"
# Or if stored separately:
$username = Get-Secret -Name "AdminUsername" -AsPlainText
$password = Get-Secret -Name "AdminPassword"  # Returns SecureString
$cred = New-Object PSCredential($username, $password)
```

### From Environment Variables

```powershell
# BEFORE
$apiKey = $env:API_KEY

# AFTER (for scripts)
$apiKey = Get-Secret -Name "ApiKey" -AsPlainText

# For CI/CD, keep using env vars but load into vault at runtime
if ($env:CI) {
    Set-Secret -Name "ApiKey" -Secret $env:API_KEY -Vault "TempVault"
}
```

### From Config Files

```powershell
# BEFORE (config.json with secrets)
$config = Get-Content "config.json" | ConvertFrom-Json
$connectionString = $config.database.connectionString

# AFTER (config.json references vault)
$config = Get-Content "config.json" | ConvertFrom-Json
$connectionString = Get-Secret -Name $config.database.secretName -AsPlainText
```

## Azure Key Vault Integration

```powershell
# Install Azure Key Vault extension
Install-PSResource -Name Az.KeyVault
Install-PSResource -Name Microsoft.PowerShell.SecretManagement.Azure.KeyVault

# Register Azure Key Vault as a secret vault
Register-SecretVault -Name "AzureVault" `
    -ModuleName Microsoft.PowerShell.SecretManagement.Azure.KeyVault `
    -VaultParameters @{
        AZKVaultName = "my-keyvault"
        SubscriptionId = "subscription-guid"
    }

# Use secrets from Azure Key Vault
$secret = Get-Secret -Name "MySecret" -Vault "AzureVault" -AsPlainText
```

## Vault Types

| Vault Type | Use Case | Setup |
|------------|----------|-------|
| SecretStore | Local development | Built-in, password protected |
| Azure Key Vault | Production/Cloud | Requires Az.KeyVault module |
| HashiCorp Vault | Enterprise | Community extension |
| KeePass | Personal/Team | Community extension |
| LastPass | Personal | Community extension |

## Security Best Practices

1. **Never store secrets in source control**
2. **Use environment variables in CI/CD**, load into vault at runtime
3. **Set appropriate password timeout** for SecretStore
4. **Use different vaults** for dev/staging/production
5. **Audit secret access** using vault logging
6. **Rotate secrets regularly** and update vault

## Script Migration Checklist

- [ ] Identify all hardcoded credentials
- [ ] Identify all `ConvertTo-SecureString -AsPlainText` usage
- [ ] Check for connection strings with passwords
- [ ] Review config files for secrets
- [ ] Set up appropriate vault type
- [ ] Store all secrets in vault
- [ ] Update scripts to use `Get-Secret`
- [ ] Test scripts with vault-based secrets
- [ ] Remove hardcoded values from source control
- [ ] Update documentation
