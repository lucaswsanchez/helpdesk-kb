@{
    # Run every default rule plus the formatting rules below.
    Severity     = @('Error', 'Warning', 'Information')
    ExcludeRules = @(
        # Scripts are interactive support tools; Write-Host is used intentionally
        # for colored, human-readable console output alongside pipeline objects.
        'PSAvoidUsingWriteHost'
    )
    Rules        = @{
        PSPlaceOpenBrace           = @{ Enable = $true; OnSameLine = $true; NewLineAfter = $true }
        PSPlaceCloseBrace          = @{ Enable = $true; NewLineAfter = $false }
        PSUseConsistentIndentation = @{ Enable = $true; IndentationSize = 4; Kind = 'space' }
        PSUseConsistentWhitespace  = @{ Enable = $true; CheckOpenBrace = $true; CheckOperator = $false; CheckSeparator = $true }
        PSAlignAssignmentStatement = @{ Enable = $false }
        PSUseCompatibleSyntax      = @{ Enable = $true; TargetVersions = @('5.1', '7.4') }
    }
}
