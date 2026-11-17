<#
.SYNOPSIS
    Exports an inventory of installed software (name, version, publisher, install date) to CSV.

.DESCRIPTION
    Reads the Windows "Uninstall" registry keys, the same source used by
    "Apps & features", for 64-bit, 32-bit and per-user applications.
    System components and updates/patches are excluded, and duplicate
    entries are removed.

    Useful for license audits, checking whether an approved application is
    installed, or comparing two computers when "it works on my colleague's
    PC". The script only reads the registry; it changes nothing.

.PARAMETER OutputPath
    Path of the CSV file to create. Defaults to
    .\InstalledSoftware_<COMPUTER>_<yyyyMMdd>.csv in the current folder.

.PARAMETER RegistryPath
    Registry paths to read. Defaults to the standard machine (64/32-bit) and
    current-user Uninstall keys. Mainly useful for testing.

.PARAMETER NameFilter
    Optional wildcard filter on the application name, for example '*Office*'.

.PARAMETER PassThru
    Also return the inventory objects to the pipeline.

.EXAMPLE
    .\Export-InstalledSoftware.ps1
    Writes InstalledSoftware_<COMPUTER>_<date>.csv in the current folder.

.EXAMPLE
    .\Export-InstalledSoftware.ps1 -NameFilter '*Adobe*' -PassThru | Format-Table Name, Version
    Shows installed Adobe products and also writes the CSV.

.NOTES
    Works on Windows PowerShell 5.1 and PowerShell 7+. No admin rights needed.
    Related KB: KB-016 Install Approved Software from Company Portal.
#>
[CmdletBinding()]
[OutputType([System.IO.FileInfo], [pscustomobject])]
param(
    [string]$OutputPath,

    [ValidateNotNullOrEmpty()]
    [string[]]$RegistryPath = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
    ),

    [string]$NameFilter = '*',

    [switch]$PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-InstallScope {
    <#
    .SYNOPSIS
        Maps an Uninstall registry path to a readable scope label.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param([Parameter(Mandatory)][string]$Path)
    if ($Path -like 'HKCU:*' -or $Path -like 'HKEY_CURRENT_USER*') { return 'User' }
    if ($Path -match 'WOW6432Node') { return 'Machine (32-bit)' }
    return 'Machine'
}

function ConvertFrom-UninstallEntry {
    <#
    .SYNOPSIS
        Converts one Uninstall registry entry into an inventory object, or nothing if it should be excluded.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][object]$Entry,
        [Parameter(Mandatory)][string]$Scope
    )

    $props = $Entry.PSObject.Properties
    $get = { param($n) if ($props[$n]) { $props[$n].Value } else { $null } }

    $name = & $get 'DisplayName'
    if ([string]::IsNullOrWhiteSpace($name)) { return }
    if ((& $get 'SystemComponent') -eq 1) { return }
    if (& $get 'ParentKeyName') { return }          # updates / patches of another product
    if ((& $get 'ReleaseType') -in 'Update', 'Hotfix', 'Security Update') { return }

    $installDate = $null
    $rawDate = [string](& $get 'InstallDate')
    if ($rawDate -match '^\d{8}$') {
        $parsed = [datetime]::MinValue
        if ([datetime]::TryParseExact($rawDate, 'yyyyMMdd', [Globalization.CultureInfo]::InvariantCulture, 'None', [ref]$parsed)) {
            $installDate = $parsed.ToString('yyyy-MM-dd')
        }
    }

    [pscustomobject]@{
        Name        = $name.Trim()
        Version     = [string](& $get 'DisplayVersion')
        Publisher   = [string](& $get 'Publisher')
        InstallDate = $installDate
        Scope       = $Scope
    }
}

try {
    $inventory = foreach ($path in $RegistryPath) {
        if (-not (Test-Path -Path $path)) {
            Write-Verbose "Registry path not found, skipping: $path"
            continue
        }
        $scope = Get-InstallScope -Path $path
        Get-ChildItem -Path $path -ErrorAction SilentlyContinue | ForEach-Object {
            $entry = Get-ItemProperty -LiteralPath $_.PSPath -ErrorAction SilentlyContinue
            if ($entry) { ConvertFrom-UninstallEntry -Entry $entry -Scope $scope }
        }
    }

    $inventory = @($inventory |
            Where-Object { $_.Name -like $NameFilter } |
            Sort-Object Name, Version, Scope -Unique |
            Sort-Object Name)

    if (-not $OutputPath) {
        $OutputPath = Join-Path (Get-Location).Path ('InstalledSoftware_{0}_{1}.csv' -f $env:COMPUTERNAME, (Get-Date -Format 'yyyyMMdd'))
    }
    $inventory | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

    Write-Host "Found $($inventory.Count) application(s). Inventory saved to $OutputPath" -ForegroundColor Green
    Get-Item -LiteralPath $OutputPath
    if ($PassThru) { $inventory }
} catch {
    Write-Error -Message "Export-InstalledSoftware failed: $($_.Exception.Message)" -ErrorAction Continue
    exit 1
}
