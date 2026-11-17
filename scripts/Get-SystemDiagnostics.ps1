<#
.SYNOPSIS
    Collects a health snapshot of the local Windows computer and exports it as an HTML report.

.DESCRIPTION
    Gathers the information an L1 technician usually needs at the start of a
    ticket: operating system and build, uptime, CPU, memory usage, fixed disks
    with free space, and network adapters (IP, gateway, DNS, DHCP).

    Simple health rules flag common problems (high uptime, low disk space,
    high memory usage, APIPA address) so the technician knows where to look.

    The report is a single self-contained HTML file that can be attached to a
    ticket. The script only reads information; it changes nothing.

.PARAMETER OutputPath
    Folder where the HTML report is written. Defaults to the current folder.
    The file name is Diagnostics_<COMPUTER>_<yyyyMMdd-HHmmss>.html.

.PARAMETER PassThru
    Also return the collected data as an object (useful for scripting).

.EXAMPLE
    .\Get-SystemDiagnostics.ps1
    Creates the HTML report in the current folder and prints a summary.

.EXAMPLE
    .\Get-SystemDiagnostics.ps1 -OutputPath "$env:USERPROFILE\Desktop" -PassThru
    Writes the report to the Desktop and returns the data object.

.NOTES
    Works on Windows PowerShell 5.1 and PowerShell 7+. No admin rights needed.
    Related KB: KB-013 Computer Is Running Slow.
#>
[CmdletBinding()]
[OutputType([System.IO.FileInfo], [pscustomobject])]
param(
    [ValidateNotNullOrEmpty()]
    [string]$OutputPath = (Get-Location).Path,

    [switch]$PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-HealthWarning {
    <#
    .SYNOPSIS
        Applies simple health rules to diagnostics data and returns warnings.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [double]$UptimeDays,

        [Parameter(Mandatory)]
        [double]$MemoryUsedPercent,

        [AllowEmptyCollection()]
        [object[]]$Disk = @(),

        [AllowEmptyCollection()]
        [object[]]$Network = @()
    )

    if ($UptimeDays -ge 7) {
        "Uptime is $([math]::Round($UptimeDays, 1)) days. Restart the computer to apply updates and free resources."
    }
    if ($MemoryUsedPercent -ge 90) {
        "Memory usage is $MemoryUsedPercent%. Close unused applications or check for a memory-heavy process."
    }
    foreach ($d in $Disk) {
        if ($d.FreePercent -lt 10) {
            "Drive $($d.Drive) has only $($d.FreePercent)% free. Free disk space (see Clear-TempFiles.ps1)."
        } elseif ($d.FreePercent -lt 15) {
            "Drive $($d.Drive) is getting full ($($d.FreePercent)% free)."
        }
    }
    foreach ($n in $Network) {
        if (@($n.IPv4) -match '^169\.254\.') {
            "Adapter '$($n.Adapter)' has an APIPA address (169.254.x.x): DHCP did not respond."
        }
    }
}

function Get-DiagnosticData {
    <#
    .SYNOPSIS
        Collects OS, CPU, memory, disk and network information via CIM.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $cs = Get-CimInstance -ClassName Win32_ComputerSystem
    $cpu = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1

    $uptime = (Get-Date) - $os.LastBootUpTime
    $totalMemGb = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
    $freeMemGb = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
    $memUsedPct = if ($os.TotalVisibleMemorySize -gt 0) {
        [math]::Round(100 * (1 - ($os.FreePhysicalMemory / $os.TotalVisibleMemorySize)), 0)
    } else { 0 }

    $disks = @(Get-CimInstance -ClassName Win32_LogicalDisk -Filter 'DriveType=3' | ForEach-Object {
            $freePct = if ($_.Size -gt 0) { [math]::Round(100 * $_.FreeSpace / $_.Size, 0) } else { 0 }
            [pscustomobject]@{
                Drive       = $_.DeviceID
                Label       = $_.VolumeName
                SizeGB      = [math]::Round($_.Size / 1GB, 1)
                FreeGB      = [math]::Round($_.FreeSpace / 1GB, 1)
                FreePercent = $freePct
            }
        })

    $network = @(Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -Filter 'IPEnabled=True' | ForEach-Object {
            [pscustomobject]@{
                Adapter = $_.Description
                IPv4    = @($_.IPAddress | Where-Object { $_ -match '^\d{1,3}(\.\d{1,3}){3}$' })
                Gateway = @($_.DefaultIPGateway)
                DNS     = @($_.DNSServerSearchOrder)
                DHCP    = [bool]$_.DHCPEnabled
                MAC     = $_.MACAddress
            }
        })

    $warnings = @(Get-HealthWarning -UptimeDays $uptime.TotalDays -MemoryUsedPercent $memUsedPct -Disk $disks -Network $network)

    [pscustomobject]@{
        ComputerName      = $env:COMPUTERNAME
        UserName          = $env:USERNAME
        CollectedAt       = Get-Date
        OS                = $os.Caption
        OSVersion         = $os.Version
        OSBuild           = $os.BuildNumber
        Manufacturer      = $cs.Manufacturer
        Model             = $cs.Model
        CPU               = ($cpu.Name -replace '\s+', ' ').Trim()
        LastBoot          = $os.LastBootUpTime
        UptimeDays        = [math]::Round($uptime.TotalDays, 1)
        MemoryTotalGB     = $totalMemGb
        MemoryFreeGB      = $freeMemGb
        MemoryUsedPercent = $memUsedPct
        Disks             = $disks
        Network           = $network
        Warnings          = $warnings
    }
}

function ConvertTo-DiagnosticHtml {
    <#
    .SYNOPSIS
        Renders diagnostics data as a self-contained, HTML-encoded report.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Data
    )

    function Format-Cell([object]$Value) {
        [System.Net.WebUtility]::HtmlEncode((@($Value) -join ', '))
    }

    $summaryRows = @(
        @('Computer', $Data.ComputerName), @('User', $Data.UserName),
        @('Operating system', "$($Data.OS) ($($Data.OSVersion), build $($Data.OSBuild))"),
        @('Hardware', "$($Data.Manufacturer) $($Data.Model)"), @('CPU', $Data.CPU),
        @('Last boot', $Data.LastBoot), @('Uptime (days)', $Data.UptimeDays),
        @('Memory', "$($Data.MemoryTotalGB) GB total, $($Data.MemoryFreeGB) GB free ($($Data.MemoryUsedPercent)% used)")
    ) | ForEach-Object { "<tr><th scope='row'>$(Format-Cell $_[0])</th><td>$(Format-Cell $_[1])</td></tr>" }

    $diskRows = $Data.Disks | ForEach-Object {
        $class = if ($_.FreePercent -lt 10) { 'bad' } elseif ($_.FreePercent -lt 15) { 'warn' } else { 'ok' }
        "<tr class='$class'><td>$(Format-Cell $_.Drive)</td><td>$(Format-Cell $_.Label)</td><td>$($_.SizeGB)</td><td>$($_.FreeGB)</td><td>$($_.FreePercent)%</td></tr>"
    }

    $netRows = $Data.Network | ForEach-Object {
        "<tr><td>$(Format-Cell $_.Adapter)</td><td>$(Format-Cell $_.IPv4)</td><td>$(Format-Cell $_.Gateway)</td><td>$(Format-Cell $_.DNS)</td><td>$(if ($_.DHCP) { 'Yes' } else { 'No' })</td></tr>"
    }

    $warningBlock = if (@($Data.Warnings).Count -gt 0) {
        '<ul class="warnings">' + (($Data.Warnings | ForEach-Object { "<li>$(Format-Cell $_)</li>" }) -join '') + '</ul>'
    } else {
        '<p class="allgood">No issues detected by the basic health rules.</p>'
    }

    $title = "System diagnostics - $(Format-Cell $Data.ComputerName)"
    @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$title</title>
<style>
 body{font-family:Segoe UI,system-ui,sans-serif;margin:2rem;color:#1f2933;background:#f7f9fb}
 h1{color:#0f4c81;margin-bottom:.2rem} h2{color:#0f4c81;margin-top:2rem}
 .meta{color:#52606d;margin-top:0}
 table{border-collapse:collapse;width:100%;background:#fff;box-shadow:0 1px 3px rgba(0,0,0,.08)}
 th,td{border:1px solid #d9e2ec;padding:.45rem .7rem;text-align:left;vertical-align:top}
 thead th{background:#0f4c81;color:#fff} th[scope=row]{width:14rem;background:#f0f4f8}
 tr.warn td{background:#fff7e6} tr.bad td{background:#fde8e8}
 .warnings li{color:#8a2c0d;margin:.3rem 0} .allgood{color:#1d6b35}
</style>
</head>
<body>
<h1>$title</h1>
<p class="meta">Collected $(Format-Cell ($Data.CollectedAt.ToString('yyyy-MM-dd HH:mm:ss'))) by Get-SystemDiagnostics.ps1</p>
<h2>Health check</h2>
$warningBlock
<h2>Summary</h2>
<table>$($summaryRows -join "`n")</table>
<h2>Disks</h2>
<table><thead><tr><th>Drive</th><th>Label</th><th>Size (GB)</th><th>Free (GB)</th><th>Free</th></tr></thead><tbody>$($diskRows -join "`n")</tbody></table>
<h2>Network adapters</h2>
<table><thead><tr><th>Adapter</th><th>IPv4</th><th>Gateway</th><th>DNS servers</th><th>DHCP</th></tr></thead><tbody>$($netRows -join "`n")</tbody></table>
</body>
</html>
"@
}

# ---- Main ----
try {
    if (-not (Test-Path -Path $OutputPath -PathType Container)) {
        throw "Output folder '$OutputPath' does not exist."
    }

    Write-Verbose 'Collecting diagnostics data...'
    $data = Get-DiagnosticData
    $html = ConvertTo-DiagnosticHtml -Data $data

    $fileName = 'Diagnostics_{0}_{1}.html' -f $data.ComputerName, $data.CollectedAt.ToString('yyyyMMdd-HHmmss')
    $reportPath = Join-Path -Path (Resolve-Path $OutputPath).Path -ChildPath $fileName
    [System.IO.File]::WriteAllText($reportPath, $html, [System.Text.UTF8Encoding]::new($false))

    Write-Host "Diagnostics for $($data.ComputerName): $($data.OS), uptime $($data.UptimeDays) days, memory $($data.MemoryUsedPercent)% used." -ForegroundColor Cyan
    if (@($data.Warnings).Count -gt 0) {
        $data.Warnings | ForEach-Object { Write-Host "  [!] $_" -ForegroundColor Yellow }
    } else {
        Write-Host '  No issues detected by the basic health rules.' -ForegroundColor Green
    }
    Write-Host "Report saved to $reportPath"

    Get-Item -Path $reportPath
    if ($PassThru) {
        $data
    }
} catch {
    Write-Error -Message "Get-SystemDiagnostics failed: $($_.Exception.Message)" -ErrorAction Continue
    exit 1
}
