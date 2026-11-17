#Requires -Modules Pester

BeforeAll {
    . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
    $script:ScriptPath = Join-Path $PSScriptRoot '..\scripts\Get-InactiveAccount.ps1'
    $script:SampleCsv = Join-Path $PSScriptRoot '..\scripts\samples\ad-users.csv'
    $script:RefDate = [datetime]'2026-11-17'
    Get-ScriptFunctionDefinition -Path $script:ScriptPath | ForEach-Object { . ([scriptblock]::Create($_)) }
}

Describe 'ConvertTo-NullableDate' {
    It 'parses ISO dates regardless of culture' {
        ConvertTo-NullableDate '2026-05-02' | Should -Be ([datetime]'2026-05-02')
    }

    It 'returns $null for empty or invalid values' {
        ConvertTo-NullableDate '' | Should -BeNullOrEmpty
        ConvertTo-NullableDate $null | Should -BeNullOrEmpty
        ConvertTo-NullableDate 'not a date' | Should -BeNullOrEmpty
    }

    It 'passes DateTime values through' {
        $d = Get-Date
        ConvertTo-NullableDate $d | Should -Be $d
    }
}

Describe 'Get-InactivityReport' {
    BeforeAll {
        $script:Accounts = @(
            [pscustomobject]@{ SamAccountName = 'active'; Name = 'Active'; Enabled = 'True'; LastLogonDate = '2026-11-10'; WhenCreated = '2020-01-01' }
            [pscustomobject]@{ SamAccountName = 'stale'; Name = 'Stale'; Enabled = 'True'; LastLogonDate = '2026-07-01'; WhenCreated = '2020-01-01' }
            [pscustomobject]@{ SamAccountName = 'never-old'; Name = 'Never Old'; Enabled = 'True'; LastLogonDate = ''; WhenCreated = '2025-01-01' }
            [pscustomobject]@{ SamAccountName = 'never-new'; Name = 'Never New'; Enabled = 'True'; LastLogonDate = ''; WhenCreated = '2026-11-01' }
            [pscustomobject]@{ SamAccountName = 'disabled'; Name = 'Disabled'; Enabled = 'False'; LastLogonDate = '2026-01-01'; WhenCreated = '2020-01-01' }
        )
    }

    It 'returns only enabled accounts inactive for at least the threshold' {
        $r = @(Get-InactivityReport -Account $script:Accounts -Days 90 -ReferenceDate $script:RefDate)
        $r.SamAccountName | Should -Be @('stale', 'never-old')
    }

    It 'calculates days inactive from the reference date' {
        $r = Get-InactivityReport -Account $script:Accounts -Days 90 -ReferenceDate $script:RefDate | Where-Object SamAccountName -EQ 'stale'
        $r.DaysInactive | Should -Be 139
        $r.LastLogonDate | Should -Be '2026-07-01'
    }

    It 'does not flag brand-new accounts that never signed in' {
        $r = Get-InactivityReport -Account $script:Accounts -Days 30 -ReferenceDate $script:RefDate
        $r.SamAccountName | Should -Not -Contain 'never-new'
    }

    It 'marks never-used accounts and recommends a review' {
        $r = Get-InactivityReport -Account $script:Accounts -Days 90 -ReferenceDate $script:RefDate | Where-Object SamAccountName -EQ 'never-old'
        $r.LastLogonDate | Should -Be 'Never'
        $r.Recommendation | Should -Match 'Never signed in'
    }

    It 'includes disabled accounts only with -IncludeDisabled' {
        $r = Get-InactivityReport -Account $script:Accounts -Days 90 -ReferenceDate $script:RefDate -IncludeDisabled
        ($r | Where-Object SamAccountName -EQ 'disabled').Recommendation | Should -Match 'Already disabled'
    }
}

Describe 'Get-InactiveAccount.ps1 with the sample CSV' {
    It 'reports the expected accounts, most inactive first, and exports CSV' {
        $out = Join-Path $TestDrive 'inactive.csv'
        $r = @(& $script:ScriptPath -InputCsv $script:SampleCsv -ReferenceDate $script:RefDate -OutputPath $out 6>$null)

        $r.SamAccountName | Should -Be @('test.user', 'kiosk.lobby', 'old.contractor', 'peter.white')
        $r[0].DaysInactive | Should -Be 534
        (Import-Csv $out).Count | Should -Be 4
    }

    It 'honors -DaysInactive' {
        $r = @(& $script:ScriptPath -InputCsv $script:SampleCsv -ReferenceDate $script:RefDate -DaysInactive 180 6>$null)
        $r.SamAccountName | Should -Be @('test.user', 'kiosk.lobby', 'old.contractor')
    }

    It 'explains how to proceed when no AD module and no CSV are available' {
        Mock Get-Module { $null } -ParameterFilter { $Name -eq 'ActiveDirectory' }
        { & $script:ScriptPath 6>$null } | Should -Throw '*-InputCsv*'
    }
}
