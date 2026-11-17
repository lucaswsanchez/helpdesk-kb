# Shared helpers for Pester tests.

function Get-ScriptFunctionDefinition {
    <#
    .SYNOPSIS
        Returns the source text of every top-level function defined in a script.
    .DESCRIPTION
        Lets tests dot-source a script's helper functions for unit testing
        without running the script body (which may have mandatory parameters
        or side effects).
    .PARAMETER Path
        Path to the .ps1 file.
    .EXAMPLE
        Get-ScriptFunctionDefinition -Path .\scripts\Test-Connectivity.ps1 |
            ForEach-Object { . ([scriptblock]::Create($_)) }
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $tokens = $null
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$errors)
    $ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false) |
        ForEach-Object { $_.Extent.Text }
}
