# PowerShell Cross-Platform Patterns

Reference for writing PowerShell that works on Windows, Linux, and macOS.

## Path Handling

DO:

```powershell
# Use Join-Path for cross-platform paths
$configPath = Join-Path -Path $PSScriptRoot -ChildPath "config.json"

# Use [System.IO.Path] for path manipulation
$fullPath = [System.IO.Path]::Combine($home, "documents", "file.txt")

# Forward slashes work on all platforms in PowerShell 7+
$path = "$PSScriptRoot/subfolder/file.txt"
```

DON'T:

```powershell
# Hardcoded backslashes (Windows-only)
$path = "C:\Users\Name\file.txt"

# Assume case-insensitive file systems
Get-ChildItem "MyFile.txt"  # Works on Windows, fails on Linux/macOS if casing is wrong
```

## Platform Detection

```powershell
# Use automatic variables
if ($IsWindows) {
    # Windows-specific code
    $env:Path -split ';'
}
elseif ($IsLinux) {
    # Linux-specific code
    $env:PATH -split ':'
}
elseif ($IsMacOS) {
    # macOS-specific code
    $env:PATH -split ':'
}

# Check PowerShell version
if ($PSVersionTable.PSVersion.Major -ge 7) {
    # PowerShell 7+ features
}
```

## Avoid Aliases in Scripts

```powershell
# DON'T use aliases (they may differ across platforms)
ls | ? {$_.Length -gt 1MB} | % {$_.Name}

# DO use full cmdlet names
Get-ChildItem | Where-Object {$_.Length -gt 1MB} | ForEach-Object {$_.Name}
```

On Linux/macOS, aliases might invoke native commands instead of PowerShell cmdlets, causing unexpected results.

## Text Encoding

```powershell
# PowerShell 7+ uses UTF-8 by default
"Hello" | Out-File -FilePath output.txt

# For PowerShell 5.1 compatibility, specify encoding
"Hello" | Out-File -FilePath output.txt -Encoding UTF8

# Best practice: Always specify encoding for cross-platform scripts
$content | Set-Content -Path $file -Encoding UTF8NoBOM
```

## Environment Variables (Cross-Platform)

```powershell
# BEST PRACTICE: Use .NET Environment class for cross-platform compatibility
[Environment]::UserName      # Works on all platforms
[Environment]::MachineName   # Works on all platforms
[IO.Path]::GetTempPath()     # Works on all platforms

# AVOID: These are platform-specific
$env:USERNAME                # Windows only
$env:USER                    # Linux/macOS only

# Environment variable names are CASE-SENSITIVE on Linux/macOS
$env:PATH    # Correct on Linux/macOS
$env:Path    # May not work on Linux/macOS
```

## Shell Detection (Windows: PowerShell vs Git Bash)

On Windows, distinguish between PowerShell and Git Bash/MSYS2 environments:

```powershell
# PowerShell detection (most reliable)
if ($env:PSModulePath -and ($env:PSModulePath -split ';').Count -ge 3) {
    Write-Host "Running in PowerShell"
}

# Platform-specific automatic variables (PowerShell 7+)
if ($IsWindows) {
    # Windows-specific code
}
elseif ($IsLinux) {
    # Linux-specific code
}
elseif ($IsMacOS) {
    # macOS-specific code
}
```

Git Bash/MSYS2 detection (from bash):

```bash
# Bash detection - check MSYSTEM environment variable
if [ -n "$MSYSTEM" ]; then
    echo "Running in Git Bash/MSYS2: $MSYSTEM"
    # MSYSTEM values: MINGW64, MINGW32, MSYS
fi
```

**When to Use Each Shell:**
- **PowerShell:** Windows automation, Azure/M365, PSGallery modules, object pipelines
- **Git Bash:** Git operations, Unix tools (sed/awk/grep), POSIX scripts, text processing

**Path Handling Differences:**
- **PowerShell:** `C:\Users\John` or `C:/Users/John` (both work in PS 7+)
- **Git Bash:** `/c/Users/John` (Unix-style, auto-converts to Windows when calling Windows tools)

See `powershell-shell-detection` skill for comprehensive cross-shell guidance.

## Line Endings

```powershell
# PowerShell handles line endings automatically
# But be explicit for git or cross-platform tools
git config core.autocrlf input  # Linux/macOS
git config core.autocrlf true   # Windows
```

## Common Pitfall: Case Sensitivity

```powershell
# Linux/macOS are case-sensitive
# This fails on Linux if file is "File.txt"
Get-Content "file.txt"

# Solution: Use exact casing or Test-Path first
if (Test-Path "file.txt") {
    Get-Content "file.txt"
}
```
