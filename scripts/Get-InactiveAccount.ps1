<#
.SYNOPSIS
    Reports user accounts that have not signed in for a given number of days.

.DESCRIPTION
    Inactive accounts (leavers never deprovisioned, test accounts, old
    contractors) are a common security finding. This script lists accounts
    whose last logon is older than -DaysInactive, or that never signed in,
    with a recommended action for the monthly review.

    Data sources:
      - Active Directory (default): uses Get-ADUser with LastLogonDate.
        Requires the ActiveDirectory (RSAT) module.
      - CSV (-InputCsv): an export with SamAccountName, Name, Enabled,
        LastLogonDate and optional Department/WhenCreated columns. Use the
        sample file to try the script without a domain.

    The script only reads data; it never disables or deletes accounts.

.PARAMETER DaysInactive
    Number of days without sign-in to consider an account inactive. Default 90.

.PARAMETER InputCsv
    Read accounts from a CSV file instead of Active Directory.

.PARAMETER SearchBase
    In AD mode, the OU distinguished name to search. Default: whole domain.

.PARAMETER IncludeDisabled
    Also report accounts that are already disabled.

.PARAMETER ReferenceDate
    Date to measure inactivity from. Default: now. Useful for reproducible reports and tests.

.PARAMETER OutputPath
    Optional path of a CSV file to export the report.

.EXAMPLE
    .\Get-InactiveAccount.ps1 -InputCsv .\samples\ad-users.csv
    Runs against the sample data (no domain needed).

.EXAMPLE
    .\Get-InactiveAccount.ps1 -DaysInactive 60 -SearchBase 'OU=Users,OU=Acme,DC=acme,DC=example' -OutputPath .\inactive.csv
    Lists accounts in the Users OU inactive for 60+ days and exports the report.

.NOTES
    LastLogonDate (lastLogonTimestamp) replicates with a delay of up to 14
    days by design, so it is accurate enough for 30+ day reviews.
    Works on Windows PowerShell 5.1 and PowerShell 7+.
    Related KB: KB-021 Employee Offboarding.
#>
[CmdletBinding()]
[OutputType([pscustomobject])]
param(
    [ValidateRange(1, 3650)]
    [int]$DaysInactive = 90,

    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$InputCsv,

    [string]$SearchBase,

    [switch]$IncludeDisabled,

    [datetime]$ReferenceDate = (Get-Date),

    [string]$OutputPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function ConvertTo-NullableDate {
    <#
    .SYNOPSIS
        Converts a value (DateTime or ISO/invariant string) to DateTime, or $null when empty/invalid.
    #>
    [CmdletBinding()]
    [OutputType([datetime])]
    param([AllowNull()][object]$Value)
    if ($null -eq $Value) { return $null }
    if ($Value -is [datetime]) { return $Value }
    $text = [string]$Value
    if ([string]::IsNullOrWhiteSpace($text)) { return $null }
    $parsed = [datetime]::MinValue
    $formats = [string[]]@('yyyy-MM-dd', 'yyyy-MM-dd HH:mm', 'yyyy-MM-dd HH:mm:ss', 'yyyy-MM-ddTHH:mm:ss', 'o')
    if ([datetime]::TryParseExact($text, $formats, [Globalization.CultureInfo]::InvariantCulture, 'None', [ref]$parsed)) {
        return $parsed
    }
    if ([datetime]::TryParse($text, [Globalization.CultureInfo]::InvariantCulture, 'None', [ref]$parsed)) {
        return $parsed
    }
    return $null
}

function Get-InactivityReport {
    <#
    .SYNOPSIS
        Filters account objects to those inactive for at least -Days and adds a recommendation.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Account,
        [Parameter(Mandatory)][int]$Days,
        [Parameter(Mandatory)][datetime]$ReferenceDate,
        [switch]$IncludeDisabled
    )

    foreach ($a in $Account) {
        $enabled = [string]$a.Enabled -in 'True', '1', 'Yes'
        if (-not $enabled -and -not $IncludeDisabled) { continue }

        $last = ConvertTo-NullableDate $a.LastLogonDate
        $created = $null
        if ($a.PSObject.Properties['WhenCreated']) { $created = ConvertTo-NullableDate $a.WhenCreated }

        if ($last) {
            $inactiveDays = [int][math]::Floor(($ReferenceDate - $last).TotalDays)
        } elseif ($created) {
            # Never signed in: measure from creation so brand-new accounts are not flagged.
            $inactiveDays = [int][math]::Floor(($ReferenceDate - $created).TotalDays)
        } else {
            $inactiveDays = [int]::MaxValue
        }
        if ($inactiveDays -lt $Days) { continue }

        $recommendation = if (-not $enabled) {
            'Already disabled: confirm with HR and delete per retention policy'
        } elseif (-not $last) {
            'Never signed in: confirm with manager, then disable'
        } else {
            'Confirm with manager/HR, then disable'
        }

        [pscustomobject]@{
            SamAccountName = $a.SamAccountName
            Name           = $a.Name
            Department     = if ($a.PSObject.Properties['Department']) { $a.Department } else { $null }
            Enabled        = $enabled
            LastLogonDate  = if ($last) { $last.ToString('yyyy-MM-dd') } else { 'Never' }
            DaysInactive   = if ($inactiveDays -eq [int]::MaxValue) { $null } else { $inactiveDays }
            Recommendation = $recommendation
        }
    }
}

# ---- Main ----
if ($InputCsv) {
    Write-Verbose "Reading accounts from $InputCsv"
    $accounts = @(Import-Csv -LiteralPath $InputCsv -Encoding UTF8)
    $missing = @('SamAccountName', 'Name', 'Enabled', 'LastLogonDate') | Where-Object { $_ -notin $accounts[0].PSObject.Properties.Name }
    if ($accounts.Count -gt 0 -and $missing) {
        throw "CSV is missing required column(s): $($missing -join ', ')"
    }
} else {
    if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
        throw 'The ActiveDirectory module is not installed. Install RSAT, or try the script with -InputCsv .\samples\ad-users.csv'
    }
    Import-Module ActiveDirectory
    $adParams = @{ Filter = '*'; Properties = 'LastLogonDate', 'Enabled', 'Department', 'WhenCreated' }
    if ($SearchBase) { $adParams.SearchBase = $SearchBase }
    $accounts = @(Get-ADUser @adParams)
}

$report = @(Get-InactivityReport -Account $accounts -Days $DaysInactive -ReferenceDate $ReferenceDate -IncludeDisabled:$IncludeDisabled |
        Sort-Object @{ Expression = { if ($null -eq $_.DaysInactive) { [int]::MaxValue } else { $_.DaysInactive } }; Descending = $true }, SamAccountName)

if ($OutputPath) {
    $report | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
}

Write-Host "$($report.Count) of $($accounts.Count) account(s) inactive for $DaysInactive+ days (reference date $($ReferenceDate.ToString('yyyy-MM-dd')))." -ForegroundColor Cyan
$report
