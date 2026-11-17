<#
.SYNOPSIS
    Clears stuck print jobs by stopping the Print Spooler, emptying the spool folder and starting it again.

.DESCRIPTION
    The standard fix when documents are stuck in the print queue and cannot
    be cancelled (see KB-012):

      1. Stop the Print Spooler service
      2. Delete the spool files (*.SHD / *.SPL) in the spool folder
      3. Start the Print Spooler service and confirm it is running

    All pending print jobs on this computer are deleted, so tell the user to
    print again afterwards. Supports -WhatIf and -Confirm. Requires an
    elevated (administrator) session, except with -WhatIf.

.PARAMETER SpoolPath
    Folder with the spool files. Default: %SystemRoot%\System32\spool\PRINTERS.

.PARAMETER ServiceName
    Name of the spooler service. Default: Spooler.

.PARAMETER TimeoutSeconds
    How long to wait for the service to stop or start. Default 30.

.EXAMPLE
    .\Reset-PrintSpooler.ps1 -WhatIf
    Shows what would be done and how many jobs would be deleted.

.EXAMPLE
    .\Reset-PrintSpooler.ps1 -Confirm:$false
    From an elevated prompt, resets the spooler without prompting.

.NOTES
    Works on Windows PowerShell 5.1 and PowerShell 7+.
    Related KB: KB-012 Printer Shows Offline or Jobs Are Stuck in the Queue.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
[OutputType([pscustomobject])]
param(
    [ValidateNotNullOrEmpty()]
    [string]$SpoolPath = (Join-Path $env:SystemRoot 'System32\spool\PRINTERS'),

    [ValidateNotNullOrEmpty()]
    [string]$ServiceName = 'Spooler',

    [ValidateRange(5, 300)]
    [int]$TimeoutSeconds = 30
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-IsAdministrator {
    <#
    .SYNOPSIS
        Returns $true when the current session is elevated.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    ([Security.Principal.WindowsPrincipal]$identity).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Wait-ServiceStatus {
    <#
    .SYNOPSIS
        Waits until a service reaches the given status or the timeout expires.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Status,
        [int]$TimeoutSeconds = 30
    )
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    do {
        if ([string](Get-Service -Name $Name).Status -eq $Status) { return $true }
        Start-Sleep -Milliseconds 500
    } while ((Get-Date) -lt $deadline)
    return $false
}

$service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if (-not $service) {
    throw "Service '$ServiceName' was not found on this computer."
}

$jobs = @(Get-ChildItem -LiteralPath $SpoolPath -File -ErrorAction SilentlyContinue)

if (-not $WhatIfPreference -and -not (Test-IsAdministrator)) {
    throw 'Reset-PrintSpooler must run in an elevated PowerShell session (Run as administrator).'
}

$result = [ordered]@{
    ServiceName   = $ServiceName
    StatusBefore  = [string]$service.Status
    JobsFound     = $jobs.Count
    FilesDeleted  = 0
    StatusAfter   = [string]$service.Status
    Success       = $false
}

if (-not $PSCmdlet.ShouldProcess("$ServiceName service and $($jobs.Count) spool file(s) in $SpoolPath", 'Stop spooler, delete pending print jobs, start spooler')) {
    Write-Host "WhatIf: would stop '$ServiceName', delete $($jobs.Count) spool file(s) and start the service again." -ForegroundColor Cyan
    return [pscustomobject]$result
}

try {
    if ($service.Status -ne 'Stopped') {
        Write-Verbose "Stopping $ServiceName..."
        Stop-Service -Name $ServiceName -Force
        if (-not (Wait-ServiceStatus -Name $ServiceName -Status 'Stopped' -TimeoutSeconds $TimeoutSeconds)) {
            throw "Service '$ServiceName' did not stop within $TimeoutSeconds seconds."
        }
    }

    foreach ($job in $jobs) {
        try {
            Remove-Item -LiteralPath $job.FullName -Force
            $result.FilesDeleted++
        } catch {
            Write-Warning "Could not delete $($job.Name): $($_.Exception.Message)"
        }
    }
} finally {
    # Always try to bring the spooler back, even if something above failed.
    Write-Verbose "Starting $ServiceName..."
    Start-Service -Name $ServiceName
    $running = Wait-ServiceStatus -Name $ServiceName -Status 'Running' -TimeoutSeconds $TimeoutSeconds
    $result.StatusAfter = [string](Get-Service -Name $ServiceName).Status
    $result.Success = $running
}

if ($result.Success) {
    Write-Host "Print Spooler reset: $($result.FilesDeleted) pending job file(s) deleted, service is running. Ask the user to print again." -ForegroundColor Green
} else {
    Write-Warning "Print Spooler did not return to Running (status: $($result.StatusAfter)). Escalate to L2 Desktop."
}
[pscustomobject]$result
