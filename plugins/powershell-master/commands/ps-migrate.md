---
name: ps-migrate
description: Migrate PowerShell scripts for 2025 changes - MSOnline to Graph, AzureAD to Graph, WMIC replacement
argument-hint: "<script.ps1 or 'MSOnline'|'AzureAD'|'WMIC'>"
allowed-tools:
  - Read
  - Edit
  - Glob
  - Grep
  - WebSearch
  - Task
---

# PowerShell 2025 Migration Assistant

Migrate scripts affected by 2025 breaking changes:

## Migration Targets

### 1. MSOnline to Microsoft Graph PowerShell (Retired March 2025)
```powershell
# OLD: MSOnline
Connect-MsolService
Get-MsolUser -All
Set-MsolUser -UserPrincipalName $upn -DisplayName $name

# NEW: Microsoft Graph PowerShell
Connect-MgGraph -Scopes "User.Read.All", "User.ReadWrite.All"
Get-MgUser -All
Update-MgUser -UserId $userId -DisplayName $name
```

### 2. AzureAD to Microsoft Graph PowerShell (Retired May 2025)
```powershell
# OLD: AzureAD
Connect-AzureAD
Get-AzureADUser -All $true
Get-AzureADGroup -ObjectId $groupId
New-AzureADUser -DisplayName $name -UserPrincipalName $upn

# NEW: Microsoft Graph PowerShell
Connect-MgGraph -Scopes "User.Read.All", "Group.Read.All"
Get-MgUser -All
Get-MgGroup -GroupId $groupId
New-MgUser -DisplayName $name -UserPrincipalName $upn -PasswordProfile $pwdProfile
```

### 3. WMIC to PowerShell Native (Removed in Windows 11 24H2)
```powershell
# OLD: WMIC
wmic os get caption
wmic cpu get name
wmic process list brief
wmic product get name,version

# NEW: PowerShell
Get-CimInstance Win32_OperatingSystem | Select-Object Caption
Get-CimInstance Win32_Processor | Select-Object Name
Get-CimInstance Win32_Process | Select-Object Handle, Name, ProcessId
Get-CimInstance Win32_Product | Select-Object Name, Version
# Or for software: Get-Package (faster, doesn't use WMI)
```

## Migration Process

1. **Scan** - Identify all occurrences of deprecated modules/commands
2. **Map** - Create mapping of old commands to new equivalents
3. **Update** - Replace commands with modern alternatives
4. **Test** - Verify functionality after migration
5. **Document** - Update any related documentation

## Common Cmdlet Mappings

| MSOnline | Graph PowerShell |
|----------|-----------------|
| `Connect-MsolService` | `Connect-MgGraph` |
| `Get-MsolUser` | `Get-MgUser` |
| `Set-MsolUser` | `Update-MgUser` |
| `Get-MsolGroup` | `Get-MgGroup` |
| `Add-MsolGroupMember` | `New-MgGroupMember` |

| AzureAD | Graph PowerShell |
|---------|-----------------|
| `Connect-AzureAD` | `Connect-MgGraph` |
| `Get-AzureADUser` | `Get-MgUser` |
| `New-AzureADUser` | `New-MgUser` |
| `Get-AzureADGroup` | `Get-MgGroup` |
| `Get-AzureADApplication` | `Get-MgApplication` |

| WMIC | PowerShell |
|------|------------|
| `wmic os get` | `Get-CimInstance Win32_OperatingSystem` |
| `wmic cpu get` | `Get-CimInstance Win32_Processor` |
| `wmic memorychip get` | `Get-CimInstance Win32_PhysicalMemory` |
| `wmic diskdrive get` | `Get-CimInstance Win32_DiskDrive` |
| `wmic process` | `Get-CimInstance Win32_Process` |

## Prerequisites for Migration

```powershell
# Install Microsoft Graph PowerShell SDK
Install-PSResource -Name Microsoft.Graph -Scope CurrentUser

# Or install specific submodules
Install-PSResource -Name Microsoft.Graph.Users
Install-PSResource -Name Microsoft.Graph.Groups
Install-PSResource -Name Microsoft.Graph.Authentication
```
