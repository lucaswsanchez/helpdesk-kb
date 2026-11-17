<#
.SYNOPSIS
    Safely deletes old temporary files and reports how much space was freed.

.DESCRIPTION
    Removes files older than a given number of days from the user's temp
    folder (and optionally the Windows temp folder). Files that are in use
    are skipped, not forced. Empty sub-folders left behind are removed.

    Supports -WhatIf to preview exactly what would be deleted and -Confirm
    to approve each deletion. Returns a summary object with the number of
    files found, deleted and skipped, and the space freed.

.PARAMETER Path
    One or more folders to clean. Defaults to the current user's temp folder ($env:TEMP).

.PARAMETER OlderThanDays
    Only files last modified more than this many days ago are deleted. Default 7.
    Use 0 to include all files.

.PARAMETER IncludeWindowsTemp
    Also clean C:\Windows\Temp (requires an elevated session).

.EXAMPLE
    .\Clear-TempFiles.ps1 -WhatIf
    Shows which files would be deleted and how much space would be freed, without deleting anything.

.EXAMPLE
    .\Clear-TempFiles.ps1 -OlderThanDays 14
    Deletes user temp files not modified in the last 14 days.

.EXAMPLE
    .\Clear-TempFiles.ps1 -IncludeWindowsTemp -Confirm:$false
    From an elevated prompt, cleans both temp folders without prompting.

.NOTES
    Works on Windows PowerShell 5.1 and PowerShell 7+.
    Related KB: KB-013 Computer Is Running Slow, KB-017 Windows Update Fails to Install.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
[OutputType([pscustomobject])]
param(
    [ValidateNotNullOrEmpty()]
    [string[]]$Path = @($env:TEMP),

    [ValidateRange(0, 3650)]
    [int]$OlderThanDays = 7,

    [switch]$IncludeWindowsTemp
)

Set-StrictMode -Version Latest

function Format-ByteSize {
    <#
    .SYNOPSIS
        Formats a byte count as a human-readable string (KB, MB, GB).
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param([Parameter(Mandatory)][long]$Bytes)
    if ($Bytes -ge 1GB) { return '{0:N2} GB' -f ($Bytes / 1GB) }
    if ($Bytes -ge 1MB) { return '{0:N1} MB' -f ($Bytes / 1MB) }
    if ($Bytes -ge 1KB) { return '{0:N0} KB' -f ($Bytes / 1KB) }
    return "$Bytes bytes"
}

$targets = New-Object System.Collections.Generic.List[string]
$Path | ForEach-Object { $targets.Add($_) }
if ($IncludeWindowsTemp) {
    $targets.Add((Join-Path $env:SystemRoot 'Temp'))
}

$cutoff = (Get-Date).AddDays(-$OlderThanDays)
$found = 0
$deleted = 0
$skipped = 0
$bytesFreed = [long]0
$bytesFound = [long]0

foreach ($folder in $targets) {
    if (-not (Test-Path -LiteralPath $folder -PathType Container)) {
        Write-Warning "Folder '$folder' does not exist. Skipping."
        continue
    }

    $files = @(Get-ChildItem -LiteralPath $folder -File -Recurse -Force -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTime -lt $cutoff })

    foreach ($file in $files) {
        $found++
        $bytesFound += $file.Length
        if ($PSCmdlet.ShouldProcess($file.FullName, 'Delete temporary file')) {
            try {
                Remove-Item -LiteralPath $file.FullName -Force -ErrorAction Stop
                $deleted++
                $bytesFreed += $file.Length
            } catch {
                $skipped++
                Write-Verbose "Skipped (in use or access denied): $($file.FullName)"
            }
        }
    }

    # Remove empty sub-folders, deepest first. The root folder itself is kept.
    $dirs = @(Get-ChildItem -LiteralPath $folder -Directory -Recurse -Force -ErrorAction SilentlyContinue |
            Sort-Object { $_.FullName.Length } -Descending)
    foreach ($dir in $dirs) {
        $isEmpty = -not (Get-ChildItem -LiteralPath $dir.FullName -Force -ErrorAction SilentlyContinue | Select-Object -First 1)
        if ($isEmpty -and $PSCmdlet.ShouldProcess($dir.FullName, 'Remove empty folder')) {
            Remove-Item -LiteralPath $dir.FullName -Force -ErrorAction SilentlyContinue
        }
    }
}

$whatIf = [bool]$WhatIfPreference
$summary = [pscustomobject]@{
    Folders       = $targets.ToArray()
    OlderThanDays = $OlderThanDays
    FilesFound    = $found
    FilesDeleted  = $deleted
    FilesSkipped  = $skipped
    BytesFound    = $bytesFound
    BytesFreed    = $bytesFreed
    WhatIf        = $whatIf
}

if ($whatIf) {
    Write-Host "WhatIf: $found file(s) older than $OlderThanDays day(s) would be deleted, freeing about $(Format-ByteSize $bytesFound)." -ForegroundColor Cyan
} else {
    Write-Host "Deleted $deleted of $found file(s), freed $(Format-ByteSize $bytesFreed). Skipped $skipped file(s) in use." -ForegroundColor Green
}

$summary
