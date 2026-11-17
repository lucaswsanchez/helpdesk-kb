#Requires -Modules Pester

BeforeDiscovery {
    # -Skip is evaluated during discovery, so elevation must be known here.
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $isElevated = ([Security.Principal.WindowsPrincipal]$identity).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

BeforeAll {
    . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
    $script:ScriptPath = Join-Path $PSScriptRoot '..\scripts\Reset-PrintSpooler.ps1'
    Get-ScriptFunctionDefinition -Path $script:ScriptPath | ForEach-Object { . ([scriptblock]::Create($_)) }

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $script:IsAdmin = ([Security.Principal.WindowsPrincipal]$identity).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

Describe 'Test-IsAdministrator' {
    It 'returns a boolean that matches the current session' {
        Test-IsAdministrator | Should -Be $script:IsAdmin
    }
}

Describe 'Reset-PrintSpooler.ps1' {
    AfterAll {
        Remove-Variable -Name SpoolerTestState -Scope Global -ErrorAction SilentlyContinue
    }
    BeforeEach {
        # A fake spool folder with two stuck jobs; the real spooler is never touched.
        $script:Spool = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $script:Spool | Out-Null
        'job' | Set-Content (Join-Path $script:Spool '00012.SPL')
        'job' | Set-Content (Join-Path $script:Spool '00012.SHD')

        $global:SpoolerTestState = @{ Status = 'Running' }
        Mock Get-Service { [pscustomobject]@{ Name = 'Spooler'; Status = $global:SpoolerTestState.Status } }
        Mock Stop-Service { $global:SpoolerTestState.Status = 'Stopped' }
        Mock Start-Service { $global:SpoolerTestState.Status = 'Running' }
        Mock Start-Sleep { }
    }

    It 'with -WhatIf reports pending jobs and changes nothing (no admin needed)' {
        $r = & $script:ScriptPath -SpoolPath $script:Spool -WhatIf 6>$null
        $r.JobsFound | Should -Be 2
        $r.FilesDeleted | Should -Be 0
        Should -Invoke Stop-Service -Times 0 -Exactly
        Should -Invoke Start-Service -Times 0 -Exactly
        @(Get-ChildItem $script:Spool).Count | Should -Be 2
    }

    It 'throws a clear error when the service does not exist' {
        Mock Get-Service { $null }
        { & $script:ScriptPath -SpoolPath $script:Spool -ServiceName 'NoSuchService' -WhatIf 6>$null } | Should -Throw "*was not found*"
    }

    It 'requires an elevated session when not using -WhatIf' -Skip:$isElevated {
        { & $script:ScriptPath -SpoolPath $script:Spool -Confirm:$false 6>$null } | Should -Throw '*Run as administrator*'
        Should -Invoke Stop-Service -Times 0 -Exactly
    }

    It 'stops the service, clears the queue and starts it again (elevated)' -Skip:(-not $isElevated) {
        $r = & $script:ScriptPath -SpoolPath $script:Spool -Confirm:$false 6>$null
        $r.Success | Should -BeTrue
        $r.FilesDeleted | Should -Be 2
        $r.StatusAfter | Should -Be 'Running'
        Should -Invoke Stop-Service -Times 1 -Exactly
        Should -Invoke Start-Service -Times 1 -Exactly
        @(Get-ChildItem $script:Spool).Count | Should -Be 0
    }

    It 'starts the service again even if stopping times out (elevated)' -Skip:(-not $isElevated) {
        Mock Stop-Service { }   # status stays Running, so the wait times out
        { & $script:ScriptPath -SpoolPath $script:Spool -TimeoutSeconds 5 -Confirm:$false 6>$null } | Should -Throw '*did not stop*'
        Should -Invoke Start-Service -Times 1 -Exactly
    }
}
