#Requires -Modules Pester
# Repository-wide quality gates that apply to every script in ./scripts.

BeforeDiscovery {
    $scriptFiles = @(Get-ChildItem -Path (Join-Path $PSScriptRoot '..\scripts') -Filter *.ps1 -ErrorAction SilentlyContinue |
            ForEach-Object { @{ Name = $_.Name; Path = $_.FullName } })
}

Describe 'Repository conventions' {
    It 'has a PSScriptAnalyzer settings file that parses' {
        $settings = Join-Path $PSScriptRoot '..\PSScriptAnalyzerSettings.psd1'
        { Import-PowerShellDataFile -Path $settings } | Should -Not -Throw
    }
}

Describe 'Script <Name>' -ForEach $scriptFiles -AllowNullOrEmptyForEach {
    BeforeAll {
        $help = Get-Help -Name $Path -Full
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$errors)
    }

    It 'has no syntax errors' {
        $errors | Should -BeNullOrEmpty
    }

    It 'uses [CmdletBinding()]' {
        $ast.ParamBlock.Attributes.TypeName.Name | Should -Contain 'CmdletBinding'
    }

    It 'has a synopsis and description' {
        $help.Synopsis | Should -Not -BeNullOrEmpty
        $help.Synopsis | Should -Not -Match '^\s*\S+\.ps1'
        $help.Description | Should -Not -BeNullOrEmpty
    }

    It 'has at least one example' {
        @($help.Examples.Example).Count | Should -BeGreaterThan 0
    }

    It 'documents every parameter' {
        foreach ($param in $ast.ParamBlock.Parameters) {
            $name = $param.Name.VariablePath.UserPath
            $doc = $help.Parameters.Parameter | Where-Object Name -EQ $name
            ($doc.Description | Out-String).Trim() | Should -Not -BeNullOrEmpty -Because "parameter -$name needs help text"
        }
    }
}
