#Requires -Version 7.0
<#
.SYNOPSIS
    Initialize SecretManagement vault for secure credential storage.

.DESCRIPTION
    Sets up Microsoft.PowerShell.SecretManagement with SecretStore vault.
    Optionally configures Azure Key Vault integration.

.PARAMETER VaultName
    Name for the local secret vault. Default: "LocalVault"

.PARAMETER PasswordTimeout
    How long (in seconds) before vault password is required again. Default: 3600 (1 hour)

.PARAMETER NoPassword
    Configure vault without password protection (less secure, for automation).

.PARAMETER AzureKeyVault
    Name of Azure Key Vault to register (requires Az.KeyVault module).

.EXAMPLE
    ./Initialize-SecretVault.ps1
    Set up default local vault with password protection.

.EXAMPLE
    ./Initialize-SecretVault.ps1 -VaultName "DevSecrets" -PasswordTimeout 7200
    Set up vault with custom name and 2-hour timeout.

.EXAMPLE
    ./Initialize-SecretVault.ps1 -AzureKeyVault "my-keyvault" -SubscriptionId "guid"
    Register Azure Key Vault for production use.
#>

[CmdletBinding()]
param(
    [string]$VaultName = "LocalVault",
    [int]$PasswordTimeout = 3600,
    [switch]$NoPassword,
    [string]$AzureKeyVault,
    [string]$SubscriptionId
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "`n>> $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "   [OK] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "   [WARN] $Message" -ForegroundColor Yellow
}

# Check PowerShell version
Write-Step "Checking PowerShell version..."
if ($PSVersionTable.PSVersion.Major -lt 7) {
    throw "PowerShell 7.0 or higher is required. Current version: $($PSVersionTable.PSVersion)"
}
Write-Success "PowerShell $($PSVersionTable.PSVersion)"

# Install SecretManagement if not present
Write-Step "Checking SecretManagement module..."
if (-not (Get-Module -Name Microsoft.PowerShell.SecretManagement -ListAvailable)) {
    Write-Host "   Installing Microsoft.PowerShell.SecretManagement..."
    Install-PSResource -Name Microsoft.PowerShell.SecretManagement -Scope CurrentUser -TrustRepository
}
Write-Success "SecretManagement module available"

# Install SecretStore if not present
Write-Step "Checking SecretStore module..."
if (-not (Get-Module -Name Microsoft.PowerShell.SecretStore -ListAvailable)) {
    Write-Host "   Installing Microsoft.PowerShell.SecretStore..."
    Install-PSResource -Name Microsoft.PowerShell.SecretStore -Scope CurrentUser -TrustRepository
}
Write-Success "SecretStore module available"

Import-Module Microsoft.PowerShell.SecretManagement
Import-Module Microsoft.PowerShell.SecretStore

# Check if vault already exists
Write-Step "Configuring local vault '$VaultName'..."
$existingVault = Get-SecretVault -Name $VaultName -ErrorAction SilentlyContinue

if ($existingVault) {
    Write-Warning "Vault '$VaultName' already exists"
    $confirm = Read-Host "   Reconfigure existing vault? (y/N)"
    if ($confirm -ne 'y') {
        Write-Host "   Skipping vault configuration"
    } else {
        Unregister-SecretVault -Name $VaultName
        $existingVault = $null
    }
}

if (-not $existingVault) {
    # Configure SecretStore
    $storeConfig = @{
        Scope = 'CurrentUser'
        PasswordTimeout = $PasswordTimeout
    }

    if ($NoPassword) {
        $storeConfig.Authentication = 'None'
        Write-Warning "Vault will not be password protected (less secure)"
    } else {
        $storeConfig.Authentication = 'Password'
        $storeConfig.Interaction = 'Prompt'
    }

    Set-SecretStoreConfiguration @storeConfig -Confirm:$false

    # Register the vault
    Register-SecretVault -Name $VaultName -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault
    Write-Success "Local vault '$VaultName' registered as default"
}

# Azure Key Vault setup
if ($AzureKeyVault) {
    Write-Step "Configuring Azure Key Vault '$AzureKeyVault'..."

    # Check for Az.KeyVault module
    if (-not (Get-Module -Name Az.KeyVault -ListAvailable)) {
        Write-Host "   Installing Az.KeyVault module..."
        Install-PSResource -Name Az.KeyVault -Scope CurrentUser -TrustRepository
    }

    # Check for SecretManagement Azure extension
    $azExtension = "Microsoft.PowerShell.SecretManagement.Azure.KeyVault"
    if (-not (Get-Module -Name $azExtension -ListAvailable)) {
        Write-Host "   Installing Azure Key Vault extension..."
        Install-PSResource -Name $azExtension -Scope CurrentUser -TrustRepository
    }

    # Register Azure Key Vault
    $vaultParams = @{
        AZKVaultName = $AzureKeyVault
    }
    if ($SubscriptionId) {
        $vaultParams.SubscriptionId = $SubscriptionId
    }

    Register-SecretVault -Name "AzureKV-$AzureKeyVault" `
        -ModuleName $azExtension `
        -VaultParameters $vaultParams

    Write-Success "Azure Key Vault '$AzureKeyVault' registered"
}

# Verification
Write-Step "Verification..."
$vaults = Get-SecretVault
Write-Host "   Registered vaults:"
$vaults | Format-Table Name, ModuleName, IsDefaultVault -AutoSize

# Usage examples
Write-Host "`n=== Usage Examples ===" -ForegroundColor Yellow
Write-Host @"

# Store a secret
Set-Secret -Name "ApiKey" -Secret "your-api-key"

# Store a credential
`$cred = Get-Credential -Message "Enter credentials"
Set-Secret -Name "ServiceAccount" -Secret `$cred

# Retrieve secrets
`$apiKey = Get-Secret -Name "ApiKey" -AsPlainText
`$cred = Get-Secret -Name "ServiceAccount"

# List secrets
Get-SecretInfo

# Remove a secret
Remove-Secret -Name "ApiKey"

"@

Write-Host "=== Setup Complete ===" -ForegroundColor Green
