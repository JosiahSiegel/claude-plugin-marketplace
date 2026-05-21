# PowerShell Security Best Practices (2025 Standards)

Reference for JEA, WDAC, Constrained Language Mode, Script Block Logging, credentials, validation, and code signing.

## Modern Security Framework (JEA + WDAC + Logging)

**2025 Security Requirements:**
1. **JEA** - Just Enough Administration for role-based access
2. **WDAC** - Windows Defender Application Control for script approval
3. **Constrained Language Mode** - For non-admin users
4. **Script Block Logging** - For audit trails

## Just Enough Administration (JEA)

Required for production environments in 2025:

```powershell
# Create JEA session configuration file
New-PSSessionConfigurationFile -SessionType RestrictedRemoteServer `
    -Path "C:\JEA\HelpDesk.pssc" `
    -VisibleCmdlets @{
        Name = 'Restart-Service'
        Parameters = @{ Name = 'Name'; ValidateSet = 'Spooler', 'Wuauserv' }
    }, @{
        Name = 'Get-Service'
    } `
    -LanguageMode NoLanguage `
    -ExecutionPolicy RemoteSigned

# Register JEA endpoint
Register-PSSessionConfiguration -Name HelpDesk `
    -Path "C:\JEA\HelpDesk.pssc" `
    -Force

# Connect with limited privileges
Enter-PSSession -ComputerName Server01 -ConfigurationName HelpDesk
```

## Windows Defender Application Control (WDAC)

Replaces AppLocker for PowerShell script control:

```powershell
# Create WDAC policy for approved scripts
New-CIPolicy -FilePath "C:\WDAC\PowerShellPolicy.xml" `
    -ScanPath "C:\ApprovedScripts" `
    -Level FilePublisher `
    -Fallback Hash

# Convert to binary
ConvertFrom-CIPolicy -XmlFilePath "C:\WDAC\PowerShellPolicy.xml" `
    -BinaryFilePath "C:\Windows\System32\CodeIntegrity\SIPolicy.p7b"

# Deploy via Group Policy or MDM
```

## Constrained Language Mode

Recommended for all non-admin users:

```powershell
# Check current language mode
$ExecutionContext.SessionState.LanguageMode
# Output: FullLanguage (admin) or ConstrainedLanguage (standard user)

# Enable system-wide via environment variable
[Environment]::SetEnvironmentVariable(
    "__PSLockdownPolicy",
    "4",
    [System.EnvironmentVariableTarget]::Machine
)
```

## Script Block Logging

Enable for security auditing:

```powershell
# Enable via Group Policy or Registry
# HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging
# EnableScriptBlockLogging = 1
# EnableScriptBlockInvocationLogging = 1

# Check logs
Get-WinEvent -LogName "Microsoft-Windows-PowerShell/Operational" |
    Where-Object Id -eq 4104 |  # Script Block Logging
    Select-Object TimeCreated, Message -First 10
```

## Execution Policy

```powershell
# Check current execution policy
Get-ExecutionPolicy

# Set for current user (no admin needed)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Bypass for single session (use sparingly)
pwsh -ExecutionPolicy Bypass -File script.ps1
```

## Credential Management

```powershell
# NEVER hardcode credentials
# BAD: $password = "MyP@ssw0rd"

# Use SecretManagement module (modern approach)
Install-PSResource -Name Microsoft.PowerShell.SecretManagement
Install-PSResource -Name SecretManagement.KeyVault

Register-SecretVault -Name AzureKeyVault -ModuleName SecretManagement.KeyVault
$secret = Get-Secret -Name "DatabasePassword" -Vault AzureKeyVault

# Legacy: Get-Credential for interactive
$cred = Get-Credential

# Azure Key Vault for production
$vaultName = "MyKeyVault"
$secret = Get-AzKeyVaultSecret -VaultName $vaultName -Name "DatabasePassword"
$secret.SecretValue
```

## Input Validation

```powershell
function Do-Something {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter()]
        [ValidateRange(1, 100)]
        [int]$Count,

        [Parameter()]
        [ValidateSet("Option1", "Option2", "Option3")]
        [string]$Option,

        [Parameter()]
        [ValidatePattern('^\d{3}-\d{3}-\d{4}$')]
        [string]$PhoneNumber
    )
}
```

## Code Signing (Production)

```powershell
# Get code signing certificate
$cert = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert

# Sign script
Set-AuthenticodeSignature -FilePath script.ps1 -Certificate $cert
```
