#Requires -Modules Pester

BeforeAll {
    . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
    $script:ScriptPath = Join-Path $PSScriptRoot '..\scripts\Clear-TempFiles.ps1'
    Get-ScriptFunctionDefinition -Path $script:ScriptPath | ForEach-Object { . ([scriptblock]::Create($_)) }
}

Describe 'Format-ByteSize' {
    It 'formats <Bytes> as <Expected>' -ForEach @(
        @{ Bytes = 512; Expected = '512 bytes' }
        @{ Bytes = 2048; Expected = '2 KB' }
        @{ Bytes = 5MB; Expected = '5.0 MB' }
        @{ Bytes = 3GB; Expected = '3.00 GB' }
    ) {
        # Normalize decimal separator so the test passes on any culture.
        (Format-ByteSize -Bytes $Bytes) -replace ',', '.' | Should -Be $Expected
    }
}

Describe 'Clear-TempFiles.ps1' {
    BeforeEach {
        $script:Root = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path (Join-Path $script:Root 'sub\deeper') -Force | Out-Null

        $script:OldFile = Join-Path $script:Root 'old.tmp'
        $script:OldNested = Join-Path $script:Root 'sub\deeper\old-nested.log'
        $script:NewFile = Join-Path $script:Root 'new.tmp'
        foreach ($f in $script:OldFile, $script:OldNested, $script:NewFile) {
            Set-Content -LiteralPath $f -Value ('x' * 1024)
        }
        $old = (Get-Date).AddDays(-30)
        (Get-Item $script:OldFile).LastWriteTime = $old
        (Get-Item $script:OldNested).LastWriteTime = $old
    }

    It 'deletes nothing with -WhatIf but reports what it would delete' {
        $r = & $script:ScriptPath -Path $script:Root -OlderThanDays 7 -WhatIf 6>$null
        $r.WhatIf | Should -BeTrue
        $r.FilesFound | Should -Be 2
        $r.FilesDeleted | Should -Be 0
        $r.BytesFound | Should -BeGreaterThan 0
        Test-Path $script:OldFile | Should -BeTrue
        Test-Path $script:OldNested | Should -BeTrue
    }

    It 'deletes only files older than the threshold and removes empty folders' {
        $r = & $script:ScriptPath -Path $script:Root -OlderThanDays 7 -Confirm:$false 6>$null
        $r.FilesDeleted | Should -Be 2
        $r.BytesFreed | Should -BeGreaterThan 0
        Test-Path $script:OldFile | Should -BeFalse
        Test-Path $script:NewFile | Should -BeTrue
        Test-Path (Join-Path $script:Root 'sub') | Should -BeFalse
        Test-Path $script:Root | Should -BeTrue
    }

    It 'skips files that are in use instead of failing' {
        $stream = [System.IO.File]::Open($script:OldFile, 'Open', 'Read', 'None')
        try {
            $r = & $script:ScriptPath -Path $script:Root -OlderThanDays 7 -Confirm:$false 6>$null
        } finally {
            $stream.Dispose()
        }
        $r.FilesSkipped | Should -Be 1
        $r.FilesDeleted | Should -Be 1
        Test-Path $script:OldFile | Should -BeTrue
    }

    It 'warns and continues when a folder does not exist' {
        $r = & $script:ScriptPath -Path (Join-Path $TestDrive 'nope'), $script:Root -Confirm:$false -WarningVariable warn 3>$null 6>$null
        $warn | Should -Match 'does not exist'
        $r.FilesDeleted | Should -Be 2
    }
}
