#Requires -Modules Pester

BeforeAll {
    . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
    $script:ScriptPath = Join-Path $PSScriptRoot '..\scripts\Export-InstalledSoftware.ps1'
    Get-ScriptFunctionDefinition -Path $script:ScriptPath | ForEach-Object { . ([scriptblock]::Create($_)) }
}

Describe 'Get-InstallScope' {
    It 'maps <Path> to <Expected>' -ForEach @(
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'; Expected = 'Machine' }
        @{ Path = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'; Expected = 'Machine (32-bit)' }
        @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'; Expected = 'User' }
    ) {
        Get-InstallScope -Path $Path | Should -Be $Expected
    }
}

Describe 'ConvertFrom-UninstallEntry' {
    It 'converts a normal entry and formats the install date' {
        $entry = [pscustomobject]@{ DisplayName = ' 7-Zip 24.08 '; DisplayVersion = '24.08'; Publisher = 'Igor Pavlov'; InstallDate = '20260310' }
        $r = ConvertFrom-UninstallEntry -Entry $entry -Scope 'Machine'
        $r.Name | Should -Be '7-Zip 24.08'
        $r.Version | Should -Be '24.08'
        $r.InstallDate | Should -Be '2026-03-10'
        $r.Scope | Should -Be 'Machine'
    }

    It 'leaves an invalid install date empty' {
        $entry = [pscustomobject]@{ DisplayName = 'App'; InstallDate = '20261399' }
        (ConvertFrom-UninstallEntry -Entry $entry -Scope 'User').InstallDate | Should -BeNullOrEmpty
    }

    It 'excludes <Case>' -ForEach @(
        @{ Case = 'entries without a name'; Entry = [pscustomobject]@{ DisplayVersion = '1.0' } }
        @{ Case = 'system components'; Entry = [pscustomobject]@{ DisplayName = 'Driver'; SystemComponent = 1 } }
        @{ Case = 'updates of another product'; Entry = [pscustomobject]@{ DisplayName = 'Update for X'; ParentKeyName = 'X' } }
        @{ Case = 'hotfixes'; Entry = [pscustomobject]@{ DisplayName = 'KB123'; ReleaseType = 'Hotfix' } }
    ) {
        ConvertFrom-UninstallEntry -Entry $Entry -Scope 'Machine' | Should -BeNullOrEmpty
    }
}

Describe 'Export-InstalledSoftware.ps1 (integration with a test registry key)' {
    BeforeAll {
        $script:RegRoot = 'HKCU:\Software\HelpdeskKbTests\Uninstall'
        Remove-Item -Path 'HKCU:\Software\HelpdeskKbTests' -Recurse -Force -ErrorAction SilentlyContinue
        New-Item -Path $script:RegRoot -Force | Out-Null

        $apps = @(
            @{ Key = 'AppA'; Props = @{ DisplayName = 'Contoso Reader'; DisplayVersion = '2.1'; Publisher = 'Contoso'; InstallDate = '20260115' } }
            @{ Key = 'AppB'; Props = @{ DisplayName = 'Fabrikam VPN'; DisplayVersion = '5.0'; Publisher = 'Fabrikam' } }
            @{ Key = 'AppBdup'; Props = @{ DisplayName = 'Fabrikam VPN'; DisplayVersion = '5.0'; Publisher = 'Fabrikam' } }
            @{ Key = 'Hidden'; Props = @{ DisplayName = 'Hidden Driver'; SystemComponent = 1 } }
            @{ Key = 'Patch'; Props = @{ DisplayName = 'Contoso Reader Patch'; ParentKeyName = 'AppA' } }
        )
        foreach ($app in $apps) {
            $key = New-Item -Path (Join-Path $script:RegRoot $app.Key) -Force
            foreach ($p in $app.Props.GetEnumerator()) {
                $type = if ($p.Value -is [int]) { 'DWord' } else { 'String' }
                New-ItemProperty -Path $key.PSPath -Name $p.Key -Value $p.Value -PropertyType $type -Force | Out-Null
            }
        }
    }
    AfterAll {
        Remove-Item -Path 'HKCU:\Software\HelpdeskKbTests' -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'exports visible, de-duplicated applications to CSV' {
        $csv = Join-Path $TestDrive 'inventory.csv'
        $out = & $script:ScriptPath -RegistryPath $script:RegRoot -OutputPath $csv -PassThru 6>$null
        $items = @($out | Where-Object { $_ -isnot [System.IO.FileInfo] })

        $items.Count | Should -Be 2
        $items.Name | Should -Be @('Contoso Reader', 'Fabrikam VPN')
        $rows = @(Import-Csv $csv)
        $rows.Count | Should -Be 2
        ($rows | Where-Object Name -EQ 'Contoso Reader').InstallDate | Should -Be '2026-01-15'
    }

    It 'applies -NameFilter' {
        $csv = Join-Path $TestDrive 'filtered.csv'
        $out = & $script:ScriptPath -RegistryPath $script:RegRoot -OutputPath $csv -NameFilter '*VPN*' -PassThru 6>$null
        @($out | Where-Object { $_ -isnot [System.IO.FileInfo] }).Name | Should -Be 'Fabrikam VPN'
    }

    It 'skips registry paths that do not exist' {
        $csv = Join-Path $TestDrive 'missing.csv'
        $out = & $script:ScriptPath -RegistryPath 'HKCU:\Software\DoesNotExist12345', $script:RegRoot -OutputPath $csv -PassThru 6>$null
        @($out | Where-Object { $_ -isnot [System.IO.FileInfo] }).Count | Should -Be 2
    }

    It 'reads the real registry of the test machine' {
        $csv = Join-Path $TestDrive 'real.csv'
        & $script:ScriptPath -OutputPath $csv 6>$null | Out-Null
        Test-Path $csv | Should -BeTrue
    }
}
