#Requires -Modules Pester

BeforeAll {
    . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
    $script:ScriptPath = Join-Path $PSScriptRoot '..\scripts\Get-SystemDiagnostics.ps1'
    Get-ScriptFunctionDefinition -Path $script:ScriptPath | ForEach-Object { . ([scriptblock]::Create($_)) }
}

Describe 'Get-HealthWarning' {
    It 'returns no warnings for a healthy computer' {
        $disk = [pscustomobject]@{ Drive = 'C:'; FreePercent = 55 }
        $net = [pscustomobject]@{ Adapter = 'Wi-Fi'; IPv4 = @('192.168.1.20') }
        Get-HealthWarning -UptimeDays 1 -MemoryUsedPercent 40 -Disk $disk -Network $net | Should -BeNullOrEmpty
    }

    It 'flags uptime of 7 days or more' {
        Get-HealthWarning -UptimeDays 12.4 -MemoryUsedPercent 10 | Should -Match 'Uptime is 12.4 days'
    }

    It 'flags memory usage of 90% or more' {
        Get-HealthWarning -UptimeDays 0 -MemoryUsedPercent 93 | Should -Match 'Memory usage is 93%'
    }

    It 'distinguishes critical (<10%) and low (<15%) disk space' {
        $disks = @(
            [pscustomobject]@{ Drive = 'C:'; FreePercent = 6 }
            [pscustomobject]@{ Drive = 'D:'; FreePercent = 12 }
        )
        $warnings = @(Get-HealthWarning -UptimeDays 0 -MemoryUsedPercent 0 -Disk $disks)
        $warnings.Count | Should -Be 2
        $warnings[0] | Should -Match 'C: has only 6% free'
        $warnings[1] | Should -Match 'D: is getting full'
    }

    It 'flags APIPA addresses (DHCP failure)' {
        $net = [pscustomobject]@{ Adapter = 'Ethernet'; IPv4 = @('169.254.10.5') }
        Get-HealthWarning -UptimeDays 0 -MemoryUsedPercent 0 -Network $net | Should -Match 'APIPA'
    }
}

Describe 'ConvertTo-DiagnosticHtml' {
    BeforeAll {
        $script:Data = [pscustomobject]@{
            ComputerName = 'PC-<script>'; UserName = 'jdoe'; CollectedAt = [datetime]'2026-11-17T10:00:00'
            OS = 'Windows 11 Pro'; OSVersion = '10.0.26100'; OSBuild = '26100'
            Manufacturer = 'Contoso'; Model = 'Laptop 14'; CPU = 'Test CPU'
            LastBoot = [datetime]'2026-11-16T08:00:00'; UptimeDays = 1.1
            MemoryTotalGB = 16; MemoryFreeGB = 8; MemoryUsedPercent = 50
            Disks = @([pscustomobject]@{ Drive = 'C:'; Label = 'OS'; SizeGB = 476; FreeGB = 30; FreePercent = 6 })
            Network = @([pscustomobject]@{ Adapter = 'Wi-Fi'; IPv4 = @('10.0.0.5'); Gateway = @('10.0.0.1'); DNS = @('10.0.0.2'); DHCP = $true })
            Warnings = @('Drive C: has only 6% free.')
        }
        $script:Html = ConvertTo-DiagnosticHtml -Data $script:Data
    }

    It 'produces a complete HTML document' {
        $script:Html | Should -Match '^<!DOCTYPE html>'
        $script:Html | Should -Match '</html>\s*$'
    }

    It 'HTML-encodes values to prevent markup injection' {
        $script:Html | Should -Not -Match '<script>'
        $script:Html | Should -Match 'PC-&lt;script&gt;'
    }

    It 'includes disks, network and warnings sections' {
        $script:Html | Should -Match '<h2>Disks</h2>'
        $script:Html | Should -Match '10\.0\.0\.5'
        $script:Html | Should -Match "<tr class='bad'>"
        $script:Html | Should -Match 'only 6% free'
    }
}

Describe 'Get-SystemDiagnostics.ps1 (integration)' {
    It 'writes an HTML report and returns data with -PassThru' {
        $out = & $script:ScriptPath -OutputPath $TestDrive -PassThru 6>$null
        $file = $out | Where-Object { $_ -is [System.IO.FileInfo] }
        $data = $out | Where-Object { $_ -isnot [System.IO.FileInfo] }

        $file | Should -Not -BeNullOrEmpty
        $file.Name | Should -Match "^Diagnostics_$($env:COMPUTERNAME)_\d{8}-\d{6}\.html$"
        Get-Content -LiteralPath $file.FullName -Raw | Should -Match $env:COMPUTERNAME
        $data.OS | Should -Not -BeNullOrEmpty
        $data.MemoryTotalGB | Should -BeGreaterThan 0
        @($data.Disks).Count | Should -BeGreaterThan 0
    }

    It 'fails with exit code 1 when the output folder does not exist' {
        & $script:ScriptPath -OutputPath (Join-Path $TestDrive 'missing') 2>$null 6>$null
        $LASTEXITCODE | Should -Be 1
    }
}
