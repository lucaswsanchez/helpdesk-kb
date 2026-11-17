<#
.SYNOPSIS
    Runs the same lint and test steps as the CI pipeline.

.DESCRIPTION
    1. Lints every PowerShell file with PSScriptAnalyzer using the repo settings.
    2. Runs all Pester tests under ./tests and writes NUnit XML results.
    Exits with a non-zero code if either step fails.

.PARAMETER Task
    Which step to run: Lint, Test or All (default).

.EXAMPLE
    ./tools/Invoke-CI.ps1
    Runs lint and tests.

.EXAMPLE
    ./tools/Invoke-CI.ps1 -Task Lint
    Runs only PSScriptAnalyzer.
#>
[CmdletBinding()]
param(
    [ValidateSet('Lint', 'Test', 'All')]
    [string]$Task = 'All'
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$failed = $false

if ($Task -in 'Lint', 'All') {
    Write-Host '==> PSScriptAnalyzer' -ForegroundColor Cyan
    Import-Module PSScriptAnalyzer
    $settings = Join-Path $repoRoot 'PSScriptAnalyzerSettings.psd1'
    $files = Get-ChildItem -Path $repoRoot -Include *.ps1, *.psm1, *.psd1 -Recurse |
        Where-Object { $_.FullName -notmatch '[\\/](\.venv|site|out)[\\/]' }
    $findings = foreach ($file in $files) {
        $result = Invoke-ScriptAnalyzer -Path $file.FullName -Settings $settings
        if ($file.Name -like '*.Tests.ps1') {
            # Pester BeforeAll/It scopes trigger false positives for this rule.
            $result = $result | Where-Object RuleName -NE 'PSUseDeclaredVarsMoreThanAssignments'
        }
        $result
    }
    if ($findings) {
        $findings | Format-Table -AutoSize RuleName, Severity, ScriptName, Line, Message | Out-String -Width 200 | Write-Host
        Write-Host "PSScriptAnalyzer found $(@($findings).Count) issue(s)." -ForegroundColor Red
        $failed = $true
    } else {
        Write-Host "PSScriptAnalyzer: $(@($files).Count) file(s), no issues." -ForegroundColor Green
    }
}

if ($Task -in 'Test', 'All') {
    Write-Host '==> Pester' -ForegroundColor Cyan
    Import-Module Pester -MinimumVersion 5.5
    $config = New-PesterConfiguration
    $config.Run.Path = Join-Path $repoRoot 'tests'
    $config.Run.PassThru = $true
    $config.Output.Verbosity = 'Detailed'
    $config.TestResult.Enabled = $true
    $config.TestResult.OutputFormat = 'NUnitXml'
    $config.TestResult.OutputPath = Join-Path $repoRoot 'testResults.xml'
    $result = Invoke-Pester -Configuration $config
    if ($result.FailedCount -gt 0 -or $result.Result -ne 'Passed') {
        $failed = $true
    }
}

if ($failed) {
    exit 1
}
