<#
.SYNOPSIS
    Runs layered network connectivity checks: gateway, internet, DNS and TCP ports.

.DESCRIPTION
    Follows the same bottom-up method as KB-010:

      1. Default gateway reachable (ping)
      2. Internet reachable by IP (ping, no DNS involved)
      3. DNS resolution of the given names
      4. TCP connection to the given host:port endpoints (for example
         Microsoft 365, VPN gateway, file server on 445)

    Each check returns an object with Test, Target, Result (Pass / Fail /
    Skipped), Detail and DurationMs, so results can be filtered, exported
    or attached to a ticket. A colored summary is printed at the end.
    The script only reads network state; it changes nothing.

.PARAMETER DnsName
    Host names to resolve. Defaults to common Microsoft 365 endpoints.

.PARAMETER TcpEndpoint
    Endpoints to test as "host:port". Defaults to Microsoft 365 HTTPS endpoints.

.PARAMETER InternetIP
    Public IP address pinged to test internet access without DNS. Default 1.1.1.1.

.PARAMETER TimeoutMs
    Timeout for each ping and TCP connection, in milliseconds. Default 2000.

.PARAMETER SkipGateway
    Skip the default gateway check (for example on networks that block ICMP).

.PARAMETER OutputPath
    Optional path of a CSV file to export the results to.

.EXAMPLE
    .\Test-Connectivity.ps1
    Runs all checks with the default Microsoft 365 targets.

.EXAMPLE
    .\Test-Connectivity.ps1 -DnsName intranet.acme.example -TcpEndpoint 'fileserver01.acme.example:445','vpn.acme.example:443'
    Tests internal name resolution and access to the file server and VPN gateway.

.EXAMPLE
    .\Test-Connectivity.ps1 -OutputPath .\connectivity.csv | Where-Object Result -eq 'Fail'
    Exports all results to CSV and shows only failures.

.NOTES
    Works on Windows PowerShell 5.1 and PowerShell 7+. No admin rights needed.
    Related KB: KB-009 VPN Does Not Connect, KB-010 Wi-Fi Connected but No Internet.
#>
[CmdletBinding()]
[OutputType([pscustomobject])]
param(
    [ValidateNotNullOrEmpty()]
    [string[]]$DnsName = @('www.microsoft.com', 'login.microsoftonline.com', 'outlook.office365.com'),

    [ValidateNotNullOrEmpty()]
    [string[]]$TcpEndpoint = @('login.microsoftonline.com:443', 'outlook.office365.com:443'),

    [ValidateNotNullOrEmpty()]
    [string]$InternetIP = '1.1.1.1',

    [ValidateRange(100, 30000)]
    [int]$TimeoutMs = 2000,

    [switch]$SkipGateway,

    [string]$OutputPath
)

Set-StrictMode -Version Latest

function New-CheckResult {
    <#
    .SYNOPSIS
        Builds a uniform result object for one connectivity check.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Only creates an in-memory object.')]
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [string]$Test, [string]$Target, [ValidateSet('Pass', 'Fail', 'Skipped')][string]$Result,
        [string]$Detail, [long]$DurationMs = 0
    )
    [pscustomobject]@{
        Test       = $Test
        Target     = $Target
        Result     = $Result
        Detail     = $Detail
        DurationMs = $DurationMs
    }
}

function ConvertTo-Endpoint {
    <#
    .SYNOPSIS
        Parses "host:port" into an object with Host and Port. Throws on invalid input.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$Endpoint
    )
    if ($Endpoint -notmatch '^(?<host>[A-Za-z0-9.\-]+):(?<port>\d{1,5})$') {
        throw "Invalid endpoint '$Endpoint'. Use the format host:port, for example outlook.office365.com:443."
    }
    $port = [int]$Matches['port']
    if ($port -lt 1 -or $port -gt 65535) {
        throw "Invalid port $port in '$Endpoint'. Ports must be between 1 and 65535."
    }
    [pscustomobject]@{ Host = $Matches['host']; Port = $port }
}

function Test-PingTarget {
    <#
    .SYNOPSIS
        Sends one ICMP echo and returns a check result.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][string]$Test,
        [Parameter(Mandatory)][string]$Target,
        [int]$TimeoutMs = 2000
    )
    $ping = New-Object System.Net.NetworkInformation.Ping
    try {
        $reply = $ping.Send($Target, $TimeoutMs)
        if ($reply.Status -eq 'Success') {
            New-CheckResult -Test $Test -Target $Target -Result Pass -Detail "Reply in $($reply.RoundtripTime) ms" -DurationMs $reply.RoundtripTime
        } else {
            New-CheckResult -Test $Test -Target $Target -Result Fail -Detail "No reply ($($reply.Status))" -DurationMs $TimeoutMs
        }
    } catch {
        New-CheckResult -Test $Test -Target $Target -Result Fail -Detail $_.Exception.GetBaseException().Message
    } finally {
        $ping.Dispose()
    }
}

function Test-DnsName {
    <#
    .SYNOPSIS
        Resolves a host name with the system resolver and returns a check result.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][string]$Name
    )
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $addresses = [System.Net.Dns]::GetHostAddresses($Name) | ForEach-Object { $_.IPAddressToString }
        $sw.Stop()
        New-CheckResult -Test 'DNS' -Target $Name -Result Pass -Detail (($addresses | Select-Object -First 3) -join ', ') -DurationMs $sw.ElapsedMilliseconds
    } catch {
        $sw.Stop()
        New-CheckResult -Test 'DNS' -Target $Name -Result Fail -Detail $_.Exception.GetBaseException().Message -DurationMs $sw.ElapsedMilliseconds
    }
}

function Test-TcpPort {
    <#
    .SYNOPSIS
        Opens a TCP connection with a timeout and returns a check result.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][string]$HostName,
        [Parameter(Mandatory)][int]$Port,
        [int]$TimeoutMs = 2000
    )
    $target = "${HostName}:$Port"
    $client = New-Object System.Net.Sockets.TcpClient
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $task = $client.ConnectAsync($HostName, $Port)
        $completed = $task.Wait($TimeoutMs)
        $sw.Stop()
        if ($completed -and $client.Connected) {
            New-CheckResult -Test 'TCP' -Target $target -Result Pass -Detail 'Port open' -DurationMs $sw.ElapsedMilliseconds
        } else {
            New-CheckResult -Test 'TCP' -Target $target -Result Fail -Detail "Timed out after $TimeoutMs ms" -DurationMs $sw.ElapsedMilliseconds
        }
    } catch {
        $sw.Stop()
        New-CheckResult -Test 'TCP' -Target $target -Result Fail -Detail $_.Exception.GetBaseException().Message -DurationMs $sw.ElapsedMilliseconds
    } finally {
        $client.Dispose()
    }
}

function Get-DefaultGateway {
    <#
    .SYNOPSIS
        Returns the IPv4 default gateways of IP-enabled adapters.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()
    Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -Filter 'IPEnabled=True' |
        ForEach-Object { $_.DefaultIPGateway } |
        Where-Object { $_ -match '^\d{1,3}(\.\d{1,3}){3}$' } |
        Select-Object -Unique
}

# ---- Main ----
# Validate endpoints up front so typos fail fast.
$endpoints = foreach ($e in $TcpEndpoint) { ConvertTo-Endpoint -Endpoint $e }

$results = New-Object System.Collections.Generic.List[object]

if ($SkipGateway) {
    $results.Add((New-CheckResult -Test 'Gateway' -Target '-' -Result Skipped -Detail 'Skipped by parameter'))
} else {
    $gateways = @(Get-DefaultGateway)
    if ($gateways.Count -eq 0) {
        $results.Add((New-CheckResult -Test 'Gateway' -Target '-' -Result Fail -Detail 'No default gateway configured (no network or no DHCP lease)'))
    } else {
        foreach ($gw in $gateways) {
            $results.Add((Test-PingTarget -Test 'Gateway' -Target $gw -TimeoutMs $TimeoutMs))
        }
    }
}

$results.Add((Test-PingTarget -Test 'Internet (ICMP)' -Target $InternetIP -TimeoutMs $TimeoutMs))

foreach ($name in $DnsName) {
    $results.Add((Test-DnsName -Name $name))
}

foreach ($ep in $endpoints) {
    $results.Add((Test-TcpPort -HostName $ep.Host -Port $ep.Port -TimeoutMs $TimeoutMs))
}

if ($OutputPath) {
    $results | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
    Write-Verbose "Results exported to $OutputPath"
}

foreach ($r in $results) {
    $color = switch ($r.Result) { 'Pass' { 'Green' } 'Fail' { 'Red' } default { 'DarkGray' } }
    Write-Host ('[{0,-4}] {1,-16} {2,-40} {3}' -f $r.Result.ToUpper(), $r.Test, $r.Target, $r.Detail) -ForegroundColor $color
}
$failed = @($results | Where-Object Result -EQ 'Fail').Count
if ($failed -gt 0) {
    Write-Host "$failed check(s) failed. Fix the lowest failing layer first (gateway > internet > DNS > ports)." -ForegroundColor Yellow
} else {
    Write-Host 'All checks passed.' -ForegroundColor Green
}

$results
