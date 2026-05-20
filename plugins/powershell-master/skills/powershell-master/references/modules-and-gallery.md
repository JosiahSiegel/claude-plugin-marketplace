# PowerShell Module Management and Popular Modules

Reference for PSResourceGet, PSGallery, and key PowerShell modules in 2025-2026.

## PSResourceGet - Modern Package Manager (2025)

PSResourceGet is 2x faster than PowerShellGet and actively maintained:

```powershell
# PSResourceGet ships with PowerShell 7.4+ (or install manually)
Install-Module -Name Microsoft.PowerShell.PSResourceGet -Force

# Modern commands (PSResourceGet)
Install-PSResource -Name Az -Scope CurrentUser        # 2x faster
Find-PSResource -Name "*Azure*"                       # Faster search
Update-PSResource -Name Az                            # Batch updates
Get-InstalledPSResource                               # List installed
Uninstall-PSResource -Name OldModule                  # Clean uninstall

# Compatibility: Your old Install-Module commands still work
# They automatically call PSResourceGet internally
Install-Module -Name Az -Scope CurrentUser            # Works, uses PSResourceGet
```

## Finding Modules

```powershell
# PSResourceGet (Modern)
Find-PSResource -Name "*Azure*"
Find-PSResource -Tag "Security"
Find-PSResource -Name Az | Select-Object Name, Version, PublishedDate

# Legacy PowerShellGet (still works)
Find-Module -Name "*Azure*"
Find-Command -Name Get-AzVM
```

## Installing Modules

```powershell
# RECOMMENDED: PSResourceGet (2x faster)
Install-PSResource -Name Az -Scope CurrentUser -TrustRepository
Install-PSResource -Name Microsoft.Graph -Version 2.32.0

# Legacy: PowerShellGet (slower, but still works)
Install-Module -Name Az -Scope CurrentUser -Force
Install-Module -Name Pester -Scope AllUsers  # Requires elevation
```

## Managing Installed Modules

```powershell
# List installed (PSResourceGet)
Get-InstalledPSResource
Get-InstalledPSResource -Name Az

# Update modules (PSResourceGet)
Update-PSResource -Name Az
Update-PSResource                              # Updates all

# Uninstall (PSResourceGet)
Uninstall-PSResource -Name OldModule -AllVersions

# Import module
Import-Module -Name Az.Accounts
```

## Offline Installation

```powershell
# Save module (works with both)
Save-PSResource -Name Az -Path C:\OfflineModules
# Or: Save-Module -Name Az -Path C:\OfflineModules

# Install from saved location
Install-PSResource -Name Az -Path C:\OfflineModules
```

## Popular PowerShell Modules

### Azure (Az Module 14.5.0)

**Latest:** Az 14.5.0 (October 2025) with zone redundancy and symbolic links.

```powershell
# Install Azure module 14.5.0
Install-PSResource -Name Az -Scope CurrentUser
# Or: Install-Module -Name Az -Scope CurrentUser -Force

# Connect to Azure
Connect-AzAccount

# Common operations
Get-AzVM
Get-AzResourceGroup
New-AzResourceGroup -Name "MyRG" -Location "EastUS"

# NEW in Az 14.5: Zone redundancy for storage
New-AzStorageAccount -ResourceGroupName "MyRG" -Name "storage123" `
    -Location "EastUS" -SkuName "Standard_LRS" -EnableZoneRedundancy

# NEW in Az 14.5: Symbolic links in NFS File Share
New-AzStorageFileSymbolicLink -Context $ctx -ShareName "nfsshare" `
    -Path "symlink" -Target "/target/path"
```

**Key Submodules:**
- `Az.Accounts` - Authentication (MFA required Sep 2025+)
- `Az.Compute` - VMs, scale sets
- `Az.Storage` - Storage accounts (zone redundancy support)
- `Az.Network` - Virtual networks, NSGs
- `Az.KeyVault` - Key Vault operations
- `Az.Resources` - Resource groups, deployments

### Microsoft Graph (Microsoft.Graph 2.32.0)

**CRITICAL:** MSOnline and AzureAD modules retired (March-May 2025). Use Microsoft.Graph instead.

```powershell
# Install Microsoft Graph 2.32.0 (October 2025)
Install-PSResource -Name Microsoft.Graph -Scope CurrentUser
# Or: Install-Module -Name Microsoft.Graph -Scope CurrentUser

# Connect with required scopes
Connect-MgGraph -Scopes "User.Read.All", "Group.ReadWrite.All"

# Common operations
Get-MgUser
Get-MgGroup
New-MgUser -DisplayName "John Doe" -UserPrincipalName "john@domain.com" -MailNickname "john"
Get-MgTeam

# Migration from AzureAD/MSOnline
# OLD: Connect-AzureAD / Connect-MsolService
# NEW: Connect-MgGraph
# OLD: Get-AzureADUser / Get-MsolUser
# NEW: Get-MgUser
```

### PnP PowerShell (SharePoint/Teams)

```powershell
# Install PnP PowerShell
Install-Module -Name PnP.PowerShell -Scope CurrentUser

# Connect to SharePoint Online
Connect-PnPOnline -Url "https://tenant.sharepoint.com/sites/site" -Interactive

# Common operations
Get-PnPList
Get-PnPFile -Url "/sites/site/Shared Documents/file.docx"
Add-PnPListItem -List "Tasks" -Values @{"Title"="New Task"}
```

### AWS Tools for PowerShell

```powershell
# Install AWS Tools
Install-Module -Name AWS.Tools.Installer -Force
Install-AWSToolsModule AWS.Tools.EC2,AWS.Tools.S3

# Configure credentials
Set-AWSCredential -AccessKey $accessKey -SecretKey $secretKey -StoreAs default

# Common operations
Get-EC2Instance
Get-S3Bucket
New-S3Bucket -BucketName "my-bucket"
```

### Other Popular Modules

```powershell
# Pester (Testing framework)
Install-Module -Name Pester -Force

# PSScriptAnalyzer (Code analysis)
Install-Module -Name PSScriptAnalyzer

# ImportExcel (Excel manipulation without Excel)
Install-Module -Name ImportExcel

# PowerShellGet 3.x (Modern package management)
Install-Module -Name Microsoft.PowerShell.PSResourceGet
```

## Module Discovery

```powershell
# Find modules by keyword
Find-Module -Tag "Azure"
Find-Module -Tag "Security"

# Explore commands in a module
Get-Command -Module Az.Compute
Get-Command -Verb Get -Noun *VM*

# Get command help
Get-Help Get-AzVM -Full
Get-Help Get-AzVM -Examples
Get-Help Get-AzVM -Online
```

## Update Help System

```powershell
# Update help files (requires internet)
Update-Help -Force -ErrorAction SilentlyContinue

# Update help for specific modules
Update-Help -Module Az -Force
```

## Common Pitfall: Module Import Failures

```powershell
# Solution: Check module availability and install
if (-not (Get-Module -ListAvailable -Name Az)) {
    Install-Module -Name Az -Force -Scope CurrentUser
}
Import-Module -Name Az
```
