#Requires -Version 5.1
<#
.SYNOPSIS
    Convert WMIC commands to Get-CimInstance equivalents.

.DESCRIPTION
    Helper script that converts legacy WMIC commands to modern Get-CimInstance
    PowerShell commands. WMIC was removed in Windows 11 24H2.

.PARAMETER WmicCommand
    The WMIC command to convert (e.g., "wmic os get caption")

.PARAMETER ScanPath
    Path to scan for WMIC usage in scripts.

.EXAMPLE
    ./Convert-WmicToGetCimInstance.ps1 -WmicCommand "wmic os get caption"
    Get-CimInstance Win32_OperatingSystem | Select-Object Caption

.EXAMPLE
    ./Convert-WmicToGetCimInstance.ps1 -ScanPath "C:\Scripts"
    Scan directory for WMIC usage and suggest replacements.
#>

[CmdletBinding(DefaultParameterSetName = 'Convert')]
param(
    [Parameter(ParameterSetName = 'Convert', Position = 0)]
    [string]$WmicCommand,

    [Parameter(ParameterSetName = 'Scan')]
    [string]$ScanPath
)

# WMIC to CIM class mappings
$WmicMappings = @{
    'os' = 'Win32_OperatingSystem'
    'cpu' = 'Win32_Processor'
    'memorychip' = 'Win32_PhysicalMemory'
    'diskdrive' = 'Win32_DiskDrive'
    'logicaldisk' = 'Win32_LogicalDisk'
    'nic' = 'Win32_NetworkAdapterConfiguration'
    'nicconfig' = 'Win32_NetworkAdapterConfiguration'
    'process' = 'Win32_Process'
    'service' = 'Win32_Service'
    'bios' = 'Win32_BIOS'
    'computersystem' = 'Win32_ComputerSystem'
    'product' = 'Win32_Product'
    'useraccount' = 'Win32_UserAccount'
    'group' = 'Win32_Group'
    'startup' = 'Win32_StartupCommand'
    'qfe' = 'Win32_QuickFixEngineering'
    'printer' = 'Win32_Printer'
    'share' = 'Win32_Share'
    'timezone' = 'Win32_TimeZone'
    'volume' = 'Win32_Volume'
    'partition' = 'Win32_DiskPartition'
    'baseboard' = 'Win32_BaseBoard'
    'environment' = 'Win32_Environment'
}

# Common property mappings
$PropertyMappings = @{
    'caption' = 'Caption'
    'name' = 'Name'
    'status' = 'Status'
    'state' = 'State'
    'size' = 'Size'
    'freespace' = 'FreeSpace'
    'serialnumber' = 'SerialNumber'
    'version' = 'Version'
    'manufacturer' = 'Manufacturer'
    'model' = 'Model'
    'processid' = 'ProcessId'
    'handle' = 'Handle'
    'description' = 'Description'
}

function Convert-WmicCommand {
    param([string]$Command)

    # Parse WMIC command
    # Format: wmic [alias] [get|list|where] [properties|filters]

    $parts = $Command -split '\s+' | Where-Object { $_ }

    if ($parts[0] -ne 'wmic') {
        return @{
            Success = $false
            Error = "Command must start with 'wmic'"
        }
    }

    if ($parts.Count -lt 2) {
        return @{
            Success = $false
            Error = "WMIC command too short"
        }
    }

    $alias = $parts[1].ToLower()
    $className = $WmicMappings[$alias]

    if (-not $className) {
        return @{
            Success = $false
            Error = "Unknown WMIC alias: $alias"
            Suggestion = "Available aliases: $($WmicMappings.Keys -join ', ')"
        }
    }

    # Build PowerShell command
    $psCommand = "Get-CimInstance $className"
    $selectProperties = @()

    for ($i = 2; $i -lt $parts.Count; $i++) {
        $part = $parts[$i].ToLower()

        switch ($part) {
            'get' {
                # Next parts are properties
                $i++
                while ($i -lt $parts.Count -and $parts[$i] -notmatch '^(where|list|\/\w+)') {
                    $props = $parts[$i] -split ','
                    foreach ($prop in $props) {
                        $mappedProp = $PropertyMappings[$prop.ToLower()]
                        if ($mappedProp) {
                            $selectProperties += $mappedProp
                        } else {
                            # Use original property name with PascalCase guess
                            $selectProperties += (Get-Culture).TextInfo.ToTitleCase($prop.ToLower())
                        }
                    }
                    $i++
                }
                $i--  # Back up one since for loop will increment
            }
            'list' {
                $i++
                if ($i -lt $parts.Count -and $parts[$i] -eq 'brief') {
                    # List brief - select common properties
                    $selectProperties = @('Name', 'Status')
                }
            }
            'where' {
                $i++
                if ($i -lt $parts.Count) {
                    $filter = $parts[$i]
                    # Convert WMIC where syntax to CIM filter
                    $psCommand += " -Filter `"$filter`""
                }
            }
            { $_ -match '^/node:' } {
                $computer = $part -replace '/node:', ''
                $psCommand += " -ComputerName $computer"
            }
        }
    }

    if ($selectProperties.Count -gt 0) {
        $psCommand += " | Select-Object $($selectProperties -join ', ')"
    }

    return @{
        Success = $true
        OriginalCommand = $Command
        PowerShellCommand = $psCommand
        CimClass = $className
        Properties = $selectProperties
    }
}

function Find-WmicInScripts {
    param([string]$Path)

    $results = @()

    $files = Get-ChildItem -Path $Path -Include "*.ps1", "*.psm1", "*.bat", "*.cmd" -Recurse -ErrorAction SilentlyContinue

    foreach ($file in $files) {
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        if ($content -match 'wmic\s+\w+') {
            $matches = [regex]::Matches($content, 'wmic\s+[^\r\n|&]+')
            foreach ($match in $matches) {
                $conversion = Convert-WmicCommand -Command $match.Value.Trim()
                $results += [PSCustomObject]@{
                    File = $file.FullName
                    LineNumber = ($content.Substring(0, $match.Index) -split "`n").Count
                    WmicCommand = $match.Value.Trim()
                    PowerShellCommand = if ($conversion.Success) { $conversion.PowerShellCommand } else { "Manual review needed: $($conversion.Error)" }
                    Success = $conversion.Success
                }
            }
        }
    }

    $results
}

# Main execution
if ($ScanPath) {
    Write-Host "`n=== Scanning for WMIC Usage ===" -ForegroundColor Cyan
    Write-Host "Path: $ScanPath`n"

    $results = Find-WmicInScripts -Path $ScanPath

    if ($results.Count -eq 0) {
        Write-Host "No WMIC commands found." -ForegroundColor Green
    } else {
        Write-Host "Found $($results.Count) WMIC command(s):`n" -ForegroundColor Yellow

        foreach ($result in $results) {
            Write-Host "File: $($result.File):$($result.LineNumber)" -ForegroundColor White
            Write-Host "  WMIC: $($result.WmicCommand)" -ForegroundColor Red
            Write-Host "  CIM:  $($result.PowerShellCommand)" -ForegroundColor Green
            Write-Host ""
        }

        # Export to CSV
        $csvPath = Join-Path (Get-Location) "wmic-conversion-report.csv"
        $results | Export-Csv -Path $csvPath -NoTypeInformation
        Write-Host "Report saved to: $csvPath" -ForegroundColor Cyan
    }
}
elseif ($WmicCommand) {
    $result = Convert-WmicCommand -Command $WmicCommand

    if ($result.Success) {
        Write-Host "`n=== WMIC to PowerShell Conversion ===" -ForegroundColor Cyan
        Write-Host "Original:   $($result.OriginalCommand)" -ForegroundColor Yellow
        Write-Host "PowerShell: $($result.PowerShellCommand)" -ForegroundColor Green
        Write-Host "CIM Class:  $($result.CimClass)" -ForegroundColor Gray

        # Copy to clipboard if available
        if (Get-Command Set-Clipboard -ErrorAction SilentlyContinue) {
            $result.PowerShellCommand | Set-Clipboard
            Write-Host "`n(Copied to clipboard)" -ForegroundColor DarkGray
        }
    } else {
        Write-Host "Conversion failed: $($result.Error)" -ForegroundColor Red
        if ($result.Suggestion) {
            Write-Host $result.Suggestion -ForegroundColor Yellow
        }
    }
}
else {
    Write-Host @"

=== WMIC to Get-CimInstance Converter ===

WMIC has been removed from Windows 11 24H2. Use this script to convert
legacy WMIC commands to modern Get-CimInstance equivalents.

Usage:
  ./Convert-WmicToGetCimInstance.ps1 -WmicCommand "wmic os get caption"
  ./Convert-WmicToGetCimInstance.ps1 -ScanPath "C:\Scripts"

Common Conversions:
  wmic os get caption             -> Get-CimInstance Win32_OperatingSystem | Select-Object Caption
  wmic cpu get name               -> Get-CimInstance Win32_Processor | Select-Object Name
  wmic memorychip get capacity    -> Get-CimInstance Win32_PhysicalMemory | Select-Object Capacity
  wmic diskdrive get model,size   -> Get-CimInstance Win32_DiskDrive | Select-Object Model, Size
  wmic process list brief         -> Get-CimInstance Win32_Process | Select-Object Name, Status
  wmic service get name,state     -> Get-CimInstance Win32_Service | Select-Object Name, State

"@
}
