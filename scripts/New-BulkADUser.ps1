<#
.SYNOPSIS
    Creates Active Directory user accounts in bulk from a CSV file, with -WhatIf and a simulation mode.

.DESCRIPTION
    Reads new hires from a CSV (FirstName, LastName, Department, Title and
    optional Manager, Office) and, for each valid row:

      - builds a SamAccountName as firstname.lastname (accents removed,
        lowercase, max 20 characters; long names shorten the first name
        first, so the last name always keeps at least 9 characters) and
        makes it unique, adding a number if the name is already taken in
        the CSV or in Active Directory
      - builds the UPN and display name
      - creates the account (disabled by default until the start date)
        with a random password and "change password at next logon"

    The generated password is never written to the output or to disk:
    deliver credentials with a Temporary Access Pass or a supervised reset
    at handover (see KB-020).

    Modes:
      - AD mode: the ActiveDirectory (RSAT) module is available. Supports
        -WhatIf and -Confirm through ShouldProcess.
      - Simulation mode: -Simulate is used, or the ActiveDirectory module is
        not installed. Nothing is created; the output shows what would happen.
        This lets you validate a CSV from any workstation.

    Every row produces a result object (Row, SamAccountName, UPN, Status,
    Message) that can be exported as an audit log.

.PARAMETER CsvPath
    Path to the CSV file. Required columns: FirstName, LastName, Department, Title.
    Optional: Manager (SamAccountName), Office.

.PARAMETER UpnSuffix
    Domain used for the UserPrincipalName. Default: acme.example.

.PARAMETER OrganizationalUnit
    Distinguished name of the OU where accounts are created.

.PARAMETER Simulate
    Force simulation mode even if the ActiveDirectory module is available.

.PARAMETER Enabled
    Create the accounts enabled. By default accounts are created disabled
    and enabled on the start date.

.PARAMETER LogPath
    Optional path of a CSV file to write the results (audit log).

.EXAMPLE
    .\New-BulkADUser.ps1 -CsvPath .\samples\new-hires.csv -Simulate
    Validates the CSV and shows the accounts that would be created.

.EXAMPLE
    .\New-BulkADUser.ps1 -CsvPath .\new-hires.csv -WhatIf
    In AD mode, shows each New-ADUser operation without creating anything.

.EXAMPLE
    .\New-BulkADUser.ps1 -CsvPath .\new-hires.csv -LogPath .\onboarding-log.csv
    Creates the accounts and writes an audit log.

.NOTES
    Requires the ActiveDirectory module and rights to create users for AD mode.
    Works on Windows PowerShell 5.1 and PowerShell 7+.
    Related KB: KB-020 New Employee Onboarding.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
[OutputType([pscustomobject])]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$CsvPath,

    [ValidatePattern('^[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$')]
    [string]$UpnSuffix = 'acme.example',

    [ValidateNotNullOrEmpty()]
    [string]$OrganizationalUnit = 'OU=Users,OU=Acme,DC=acme,DC=example',

    [switch]$Simulate,

    [switch]$Enabled,

    [string]$LogPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function ConvertTo-SamAccountName {
    <#
    .SYNOPSIS
        Builds a valid sAMAccountName (firstname.lastname) from a person's name.
    .DESCRIPTION
        Removes accents, spaces and symbols, lowercases, and fits the result
        into 20 characters, the sAMAccountName limit, by shortening the first
        name first: the last name keeps at least 9 characters (all of it if
        shorter).
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)][string]$FirstName,
        [Parameter(Mandatory)][string]$LastName
    )

    $clean = {
        param([string]$Value)
        $normalized = $Value.Normalize([Text.NormalizationForm]::FormD)
        $chars = $normalized.ToCharArray() | Where-Object {
            [Globalization.CharUnicodeInfo]::GetUnicodeCategory($_) -ne [Globalization.UnicodeCategory]::NonSpacingMark
        }
        ((-join $chars).ToLowerInvariant() -replace '[^a-z0-9\-]', '').Trim('-')
    }

    $first = & $clean $FirstName
    $last = & $clean $LastName
    if (-not $first -or -not $last) {
        throw "Cannot build an account name from '$FirstName $LastName'."
    }
    # 20 characters minus the dot. When the name does not fit, shorten the
    # first name first so the last name always keeps at least 9 characters.
    $budget = 19
    if ($first.Length + $last.Length -gt $budget) {
        $minLast = [math]::Min($last.Length, 9)
        $first = $first.Substring(0, [math]::Min($first.Length, $budget - $minLast)).TrimEnd('-')
        $last = $last.Substring(0, [math]::Min($last.Length, $budget - $first.Length)).TrimEnd('-')
    }
    "$first.$last"
}

function Get-UniqueSamAccountName {
    <#
    .SYNOPSIS
        Appends a number to a SamAccountName until it is not in the taken set (respecting the 20-char limit by shortening the first name).
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)][string]$BaseName,
        [Parameter(Mandatory)][AllowEmptyCollection()][System.Collections.Generic.HashSet[string]]$Taken,
        [scriptblock]$ExistsInDirectory = { $false }
    )
    $candidate = $BaseName
    $i = 1
    while ($Taken.Contains($candidate) -or (& $ExistsInDirectory $candidate)) {
        $i++
        $suffix = [string]$i
        $over = $BaseName.Length + $suffix.Length - 20
        $dot = $BaseName.IndexOf('.')
        if ($over -le 0) {
            $candidate = $BaseName + $suffix
        } elseif ($dot -gt $over) {
            # Make room by shortening the first name, so the surname stays intact.
            $candidate = $BaseName.Substring(0, $dot - $over).TrimEnd('-') + $BaseName.Substring($dot) + $suffix
        } else {
            $candidate = $BaseName.Substring(0, 20 - $suffix.Length).TrimEnd('.', '-') + $suffix
        }
    }
    $candidate
}

function Test-UserRow {
    <#
    .SYNOPSIS
        Validates one CSV row and returns a list of problems (empty when valid).
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param([Parameter(Mandatory)][object]$Row)
    foreach ($col in 'FirstName', 'LastName', 'Department', 'Title') {
        if ([string]::IsNullOrWhiteSpace([string]$Row.$col)) { "$col is empty" }
    }
    foreach ($col in 'FirstName', 'LastName') {
        $value = [string]$Row.$col
        if ($value -and $value -notmatch "^[\p{L}][\p{L} '\-]*$") { "$col '$value' contains invalid characters" }
    }
}

function Get-RandomPassword {
    <#
    .SYNOPSIS
        Generates a random password as a SecureString (never as plain text output).
    #>
    [CmdletBinding()]
    [OutputType([securestring])]
    param([ValidateRange(14, 128)][int]$Length = 20)

    $sets = @('ABCDEFGHJKLMNPQRSTUVWXYZ', 'abcdefghijkmnopqrstuvwxyz', '23456789', '!@#$%*-_=+?')
    $all = -join $sets
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try {
        $pick = {
            param([string]$From)
            $bytes = New-Object byte[] 4
            $rng.GetBytes($bytes)
            $From[[BitConverter]::ToUInt32($bytes, 0) % $From.Length]
        }
        # One character from each set guarantees complexity; the rest are random.
        $chars = New-Object System.Collections.Generic.List[char]
        foreach ($s in $sets) { $chars.Add((& $pick $s)) }
        while ($chars.Count -lt $Length) { $chars.Add((& $pick $all)) }
        # Shuffle (Fisher-Yates) so the guaranteed characters are not always first.
        for ($i = $chars.Count - 1; $i -gt 0; $i--) {
            $bytes = New-Object byte[] 4
            $rng.GetBytes($bytes)
            $j = [BitConverter]::ToUInt32($bytes, 0) % ($i + 1)
            $tmp = $chars[$i]; $chars[$i] = $chars[$j]; $chars[$j] = $tmp
        }
        $secure = New-Object System.Security.SecureString
        foreach ($c in $chars) { $secure.AppendChar($c) }
        $secure.MakeReadOnly()
        $secure
    } finally {
        $rng.Dispose()
    }
}

# ---- Main ----
$rows = @(Import-Csv -LiteralPath $CsvPath -Encoding UTF8)
if ($rows.Count -eq 0) {
    throw "CSV '$CsvPath' has no rows."
}
$columns = $rows[0].PSObject.Properties.Name
$missing = @('FirstName', 'LastName', 'Department', 'Title') | Where-Object { $_ -notin $columns }
if ($missing) {
    throw "CSV is missing required column(s): $($missing -join ', ')"
}

$adAvailable = [bool](Get-Module -ListAvailable -Name ActiveDirectory)
$simulation = $Simulate -or -not $adAvailable
if ($simulation) {
    if (-not $Simulate) {
        Write-Warning 'ActiveDirectory module not found: running in SIMULATION mode. No accounts will be created.'
    } else {
        Write-Host 'SIMULATION mode: no accounts will be created.' -ForegroundColor Cyan
    }
    $existsInAd = { $false }
} else {
    Import-Module ActiveDirectory
    $existsInAd = { param($n) [bool](Get-ADUser -Filter "SamAccountName -eq '$n'" -ErrorAction SilentlyContinue) }
}

$taken = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
$results = New-Object System.Collections.Generic.List[object]
$rowNumber = 1

foreach ($row in $rows) {
    $rowNumber++   # row 1 is the CSV header
    $result = [ordered]@{
        Row = $rowNumber; SamAccountName = $null; UserPrincipalName = $null
        DisplayName = "$($row.FirstName) $($row.LastName)".Trim(); Department = $row.Department
        Status = $null; Message = $null
    }

    $problems = @(Test-UserRow -Row $row)
    if ($problems.Count -gt 0) {
        $result.Status = 'Skipped'
        $result.Message = $problems -join '; '
        $results.Add([pscustomobject]$result)
        continue
    }

    try {
        $first = ([string]$row.FirstName).Trim()
        $last = ([string]$row.LastName).Trim()
        $base = ConvertTo-SamAccountName -FirstName $first -LastName $last
        $sam = Get-UniqueSamAccountName -BaseName $base -Taken $taken -ExistsInDirectory $existsInAd
        [void]$taken.Add($sam)

        $result.SamAccountName = $sam
        $result.UserPrincipalName = "$sam@$UpnSuffix"
        $result.DisplayName = "$first $last"
        $note = if ($sam -ne $base) { " (name '$base' was taken)" } else { '' }

        if ($simulation) {
            $result.Status = 'Simulated'
            $result.Message = "Would create in $OrganizationalUnit$note"
        } elseif ($PSCmdlet.ShouldProcess("$sam ($first $last) in $OrganizationalUnit", 'Create AD user')) {
            $params = @{
                Name                  = "$first $last"
                GivenName             = $first
                Surname               = $last
                DisplayName           = "$first $last"
                SamAccountName        = $sam
                UserPrincipalName     = "$sam@$UpnSuffix"
                Department            = $row.Department
                Title                 = $row.Title
                Path                  = $OrganizationalUnit
                AccountPassword       = Get-RandomPassword
                ChangePasswordAtLogon = $true
                Enabled               = [bool]$Enabled
            }
            if ($row.PSObject.Properties['Office'] -and $row.Office) { $params.Office = $row.Office }
            if ($row.PSObject.Properties['Manager'] -and $row.Manager) { $params.Manager = $row.Manager }
            New-ADUser @params
            $result.Status = 'Created'
            $result.Message = "Created ($(if ($Enabled) { 'enabled' } else { 'disabled until start date' }))$note"
        } else {
            $result.Status = 'WhatIf'
            $result.Message = "Not created (WhatIf/declined)$note"
        }
    } catch {
        $result.Status = 'Failed'
        $result.Message = $_.Exception.Message
    }
    $results.Add([pscustomobject]$result)
}

if ($LogPath) {
    $results | Export-Csv -Path $LogPath -NoTypeInformation -Encoding UTF8
}

$summary = $results | Group-Object Status | ForEach-Object { "$($_.Name): $($_.Count)" }
Write-Host "Processed $($results.Count) row(s). $($summary -join ', ')" -ForegroundColor Green

$results
