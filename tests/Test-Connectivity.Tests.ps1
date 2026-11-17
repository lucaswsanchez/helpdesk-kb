#Requires -Modules Pester

BeforeAll {
    . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
    $script:ScriptPath = Join-Path $PSScriptRoot '..\scripts\Test-Connectivity.ps1'
    Get-ScriptFunctionDefinition -Path $script:ScriptPath | ForEach-Object { . ([scriptblock]::Create($_)) }
}

Describe 'ConvertTo-Endpoint' {
    It 'parses host:port' {
        $ep = ConvertTo-Endpoint -Endpoint 'outlook.office365.com:443'
        $ep.Host | Should -Be 'outlook.office365.com'
        $ep.Port | Should -Be 443
    }

    It 'rejects a missing port' {
        { ConvertTo-Endpoint -Endpoint 'outlook.office365.com' } | Should -Throw '*host:port*'
    }

    It 'rejects an out-of-range port' {
        { ConvertTo-Endpoint -Endpoint 'server:70000' } | Should -Throw '*between 1 and 65535*'
    }
}

Describe 'Test-TcpPort' {
    BeforeAll {
        # A real listener on loopback makes this test deterministic and offline.
        $script:Listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 0)
        $script:Listener.Start()
        $script:OpenPort = $script:Listener.LocalEndpoint.Port
    }
    AfterAll {
        $script:Listener.Stop()
    }

    It 'passes for an open port' {
        $r = Test-TcpPort -HostName '127.0.0.1' -Port $script:OpenPort -TimeoutMs 2000
        $r.Result | Should -Be 'Pass'
        $r.Test | Should -Be 'TCP'
        $r.Target | Should -Be "127.0.0.1:$($script:OpenPort)"
    }

    It 'fails for a closed port without throwing' {
        # Grab a free port, then close it so nothing is listening.
        $tmp = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 0)
        $tmp.Start(); $closedPort = $tmp.LocalEndpoint.Port; $tmp.Stop()

        $r = Test-TcpPort -HostName '127.0.0.1' -Port $closedPort -TimeoutMs 1000
        $r.Result | Should -Be 'Fail'
    }
}

Describe 'Test-DnsName' {
    It 'resolves localhost' {
        (Test-DnsName -Name 'localhost').Result | Should -Be 'Pass'
    }

    It 'fails for a reserved invalid domain' {
        (Test-DnsName -Name 'does-not-exist.invalid').Result | Should -Be 'Fail'
    }
}

Describe 'Test-PingTarget' {
    It 'passes for loopback' {
        (Test-PingTarget -Test 'Loopback' -Target '127.0.0.1' -TimeoutMs 1000).Result | Should -Be 'Pass'
    }
}

Describe 'Test-Connectivity.ps1 (integration, offline targets)' {
    It 'returns one result per check and exports CSV' {
        $csv = Join-Path $TestDrive 'results.csv'
        $results = & $script:ScriptPath -SkipGateway -InternetIP '127.0.0.1' -DnsName 'localhost' `
            -TcpEndpoint 'localhost:1' -TimeoutMs 500 -OutputPath $csv 6>$null

        @($results).Count | Should -Be 4
        ($results | Where-Object Test -EQ 'Gateway').Result | Should -Be 'Skipped'
        ($results | Where-Object Test -EQ 'DNS').Result | Should -Be 'Pass'
        (Import-Csv $csv).Count | Should -Be 4
    }

    It 'fails fast on an invalid endpoint' {
        { & $script:ScriptPath -SkipGateway -TcpEndpoint 'bad-endpoint' 6>$null } | Should -Throw '*host:port*'
    }
}
