#Requires -Modules Pester

BeforeAll {
    . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
    $script:ScriptPath = Join-Path $PSScriptRoot '..\scripts\New-BulkADUser.ps1'
    $script:SampleCsv = Join-Path $PSScriptRoot '..\scripts\samples\new-hires.csv'
    Get-ScriptFunctionDefinition -Path $script:ScriptPath | ForEach-Object { . ([scriptblock]::Create($_)) }

    function New-TestCsv {
        param([string]$Content)
        $path = Join-Path $TestDrive ("{0}.csv" -f [guid]::NewGuid().ToString('N'))
        [System.IO.File]::WriteAllText($path, $Content, [System.Text.UTF8Encoding]::new($false))
        $path
    }
}

Describe 'ConvertTo-SamAccountName' {
    It 'builds firstname.lastname in lowercase' {
        ConvertTo-SamAccountName -FirstName 'John' -LastName 'Smith' | Should -Be 'john.smith'
    }

    It 'removes accents' {
        # "Jose Fernandez" with accents, written with char codes to keep this file ASCII.
        $first = "Jos$([char]0x00E9)"
        $last = "Fern$([char]0x00E1)ndez"
        ConvertTo-SamAccountName -FirstName $first -LastName $last | Should -Be 'jose.fernandez'
    }

    It 'removes spaces and apostrophes but keeps hyphens' {
        ConvertTo-SamAccountName -FirstName 'Mary Ann' -LastName "O'Brien-Lee" | Should -Be 'maryann.obrien-lee'
    }

    It 'truncates to the 20-character sAMAccountName limit' {
        $sam = ConvertTo-SamAccountName -FirstName 'Alexandria' -LastName 'Montgomery-Wellington'
        $sam.Length | Should -BeLessOrEqual 20
        $sam | Should -Be 'alexandria.montgomer'
    }

    It 'keeps the last name when the first name alone is 20+ characters' {
        $sam = ConvertTo-SamAccountName -FirstName 'Alexandria-Catherine' -LastName 'Montgomery-Wellington'
        $sam | Should -Be 'alexandria.montgomer'
        $sam.Length | Should -BeLessOrEqual 20
    }

    It 'keeps a short last name whole' {
        ConvertTo-SamAccountName -FirstName 'Maximilianalexander' -LastName 'Li' | Should -Be 'maximilianalexand.li'
    }

    It 'throws when nothing usable remains' {
        { ConvertTo-SamAccountName -FirstName '!!!' -LastName 'Smith' } | Should -Throw
    }
}

Describe 'Get-UniqueSamAccountName' {
    It 'returns the base name when free' {
        $taken = [System.Collections.Generic.HashSet[string]]::new()
        Get-UniqueSamAccountName -BaseName 'john.smith' -Taken $taken | Should -Be 'john.smith'
    }

    It 'appends a number when taken in the batch or in the directory' {
        $taken = [System.Collections.Generic.HashSet[string]]::new([string[]]@('john.smith'))
        $inDirectory = { param($n) $n -eq 'john.smith2' }
        Get-UniqueSamAccountName -BaseName 'john.smith' -Taken $taken -ExistsInDirectory $inDirectory | Should -Be 'john.smith3'
    }

    It 'keeps the result within 20 characters' {
        $taken = [System.Collections.Generic.HashSet[string]]::new([string[]]@('alexandria.montgomer'))
        $r = Get-UniqueSamAccountName -BaseName 'alexandria.montgomer' -Taken $taken
        $r | Should -Be 'alexandri.montgomer2'
        $r.Length | Should -Be 20
    }

    It 'shortens the first name, not the surname, to fit the number' {
        $taken = [System.Collections.Generic.HashSet[string]]::new([string[]]@('maximilianalexand.li'))
        Get-UniqueSamAccountName -BaseName 'maximilianalexand.li' -Taken $taken | Should -Be 'maximilianalexan.li2'
    }
}

Describe 'Test-UserRow' {
    It 'accepts a valid row' {
        Test-UserRow -Row ([pscustomobject]@{ FirstName = 'Ana'; LastName = 'Lopez'; Department = 'HR'; Title = 'Recruiter' }) | Should -BeNullOrEmpty
    }

    It 'reports empty required fields and invalid characters' {
        $problems = @(Test-UserRow -Row ([pscustomobject]@{ FirstName = ''; LastName = 'T4bles'; Department = 'IT'; Title = '' }))
        $problems | Should -Contain 'FirstName is empty'
        $problems | Should -Contain 'Title is empty'
        $problems -join ' ' | Should -Match "LastName 'T4bles' contains invalid characters"
    }
}

Describe 'Get-RandomPassword' {
    It 'returns a read-only SecureString of the requested length' {
        $pw = Get-RandomPassword -Length 24
        $pw | Should -BeOfType [securestring]
        $pw.Length | Should -Be 24
        $pw.IsReadOnly() | Should -BeTrue
    }

    It 'includes upper, lower, digit and symbol characters' {
        $plain = [System.Net.NetworkCredential]::new('', (Get-RandomPassword)).Password
        $plain | Should -MatchExactly '[A-Z]'
        $plain | Should -MatchExactly '[a-z]'
        $plain | Should -Match '\d'
        $plain | Should -Match '[^A-Za-z0-9]'
    }
}

Describe 'New-BulkADUser.ps1 in simulation mode' {
    It 'processes the sample CSV: valid rows simulated, invalid rows skipped, duplicates numbered' {
        $log = Join-Path $TestDrive 'log.csv'
        $r = @(& $script:ScriptPath -CsvPath $script:SampleCsv -Simulate -LogPath $log 6>$null)

        $r.Count | Should -Be 7
        @($r | Where-Object Status -EQ 'Simulated').Count | Should -Be 5
        @($r | Where-Object Status -EQ 'Skipped').Count | Should -Be 2
        ($r | Where-Object Row -EQ 2).SamAccountName | Should -Be 'mariajose.fernandez'
        ($r | Where-Object Row -EQ 3).SamAccountName | Should -Be 'john.smith'
        ($r | Where-Object Row -EQ 4).SamAccountName | Should -Be 'john.smith2'
        ($r | Where-Object Row -EQ 5).UserPrincipalName | Should -Be 'sean.obrien@acme.example'
        (Import-Csv $log).Count | Should -Be 7
    }

    It 'never outputs a password' {
        $r = & $script:ScriptPath -CsvPath $script:SampleCsv -Simulate 6>$null
        $r[0].PSObject.Properties.Name | Should -Not -Contain 'Password'
        $r[0].PSObject.Properties.Name | Should -Not -Contain 'AccountPassword'
    }

    It 'uses a custom UPN suffix' {
        $csv = New-TestCsv "FirstName,LastName,Department,Title`nAna,Lopez,HR,Recruiter"
        (& $script:ScriptPath -CsvPath $csv -Simulate -UpnSuffix 'contoso.com' 6>$null).UserPrincipalName | Should -Be 'ana.lopez@contoso.com'
    }

    It 'fails when required columns are missing' {
        $csv = New-TestCsv "First,Last`nAna,Lopez"
        { & $script:ScriptPath -CsvPath $csv -Simulate 6>$null } | Should -Throw '*missing required column*'
    }

    It 'rejects a CSV path that does not exist' {
        { & $script:ScriptPath -CsvPath (Join-Path $TestDrive 'nope.csv') -Simulate } | Should -Throw
    }
}

Describe 'New-BulkADUser.ps1 in AD mode (ActiveDirectory cmdlets stubbed)' {
    BeforeAll {
        # Stub the AD module so the AD code path can be tested on any machine.
        function global:New-ADUser {
            [CmdletBinding()]
            param($Name, $GivenName, $Surname, $DisplayName, $SamAccountName, $UserPrincipalName, $Department,
                $Title, $Path, $AccountPassword, $ChangePasswordAtLogon, $Enabled, $Office, $Manager)
        }
        function global:Get-ADUser { [CmdletBinding()] param($Filter) }
        $script:Csv = New-TestCsv "FirstName,LastName,Department,Title,Manager,Office`nAna,Lopez,HR,Recruiter,laura.gomez,Corrientes HQ`nJohn,Smith,Sales,AE,,"
    }
    AfterAll {
        Remove-Item function:global:New-ADUser, function:global:Get-ADUser -ErrorAction SilentlyContinue
    }
    BeforeEach {
        Mock Get-Module { [pscustomobject]@{ Name = 'ActiveDirectory' } } -ParameterFilter { $Name -eq 'ActiveDirectory' }
        Mock Import-Module { } -ParameterFilter { $Name -eq 'ActiveDirectory' }
        Mock Get-ADUser { if ($Filter -match "'john\.smith'") { [pscustomobject]@{ SamAccountName = 'john.smith' } } }
        Mock New-ADUser { }
    }

    It 'creates users with the expected parameters and avoids existing names' {
        $r = @(& $script:ScriptPath -CsvPath $script:Csv -Confirm:$false 6>$null)

        $r.Status | Should -Be @('Created', 'Created')
        ($r | Where-Object Row -EQ 3).SamAccountName | Should -Be 'john.smith2'
        Should -Invoke New-ADUser -Times 2 -Exactly
        Should -Invoke New-ADUser -Times 1 -Exactly -ParameterFilter {
            $SamAccountName -eq 'ana.lopez' -and $UserPrincipalName -eq 'ana.lopez@acme.example' -and
            $Manager -eq 'laura.gomez' -and $Office -eq 'Corrientes HQ' -and $Enabled -eq $false -and
            $ChangePasswordAtLogon -eq $true -and $AccountPassword -is [securestring]
        }
    }

    It 'does not call New-ADUser with -WhatIf' {
        $r = @(& $script:ScriptPath -CsvPath $script:Csv -WhatIf 6>$null)
        $r.Status | Should -Be @('WhatIf', 'WhatIf')
        Should -Invoke New-ADUser -Times 0 -Exactly
    }

    It 'reports a failed row and continues with the next one' {
        Mock New-ADUser { throw 'The specified account already exists' } -ParameterFilter { $SamAccountName -eq 'ana.lopez' }
        $r = @(& $script:ScriptPath -CsvPath $script:Csv -Confirm:$false 6>$null)
        ($r | Where-Object Row -EQ 2).Status | Should -Be 'Failed'
        ($r | Where-Object Row -EQ 2).Message | Should -Match 'already exists'
        ($r | Where-Object Row -EQ 3).Status | Should -Be 'Created'
    }
}
