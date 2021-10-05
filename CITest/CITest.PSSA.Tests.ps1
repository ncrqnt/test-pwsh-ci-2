Set-StrictMode -Version latest

BeforeDiscovery {
    #region Running the tests for each function
    $functionPaths = @()
    if (Test-Path "$PSScriptRoot\Private\*.ps1") {
        Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" -Exclude "*.Tests.*" | ForEach-Object { $functionPaths += @{Name = $_.BaseName; FullName = $_.FullName } }
    }
    if (Test-Path "$PSScriptRoot\Public\*.ps1") {
        Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1" -Exclude "*.Tests.*" | ForEach-Object { $functionPaths += @{Name = $_.BaseName; FullName = $_.FullName } }
    }
    #endregion

    #region Define Script Analyzer rules
    [System.Collections.ArrayList]$scriptAnalyzerRules = (Get-ScriptAnalyzerRule).RuleName

    # Exclude rules
    $exlucdeRules = @(
        'PSAvoidUsingWriteHost'
    )
    $exlucdeRules | ForEach-Object { $scriptAnalyzerRules.Remove($_) }
    #endregion
}

BeforeAll {
    $script:modulePath = "$($PSCommandPath -replace '.PSSA.Tests.ps1$', '').psm1"
    $script:moduleName = (($modulePath | Split-Path -Leaf) -replace '.psm1')
}

Describe "<moduleName>" {
    Context 'PS Script Analyzer Standard Rules' {

        # Perform analysis against each rule
        It "should pass rule '<_>'" -TestCases $scriptAnalyzerRules {
            Invoke-ScriptAnalyzer -Path $modulePath -IncludeRule $_ | Should -BeNullOrEmpty
        }
    }
}

Describe "<Name>" -ForEach $functionPaths {
    Context 'PS Script Analyzer Standard Rules' {
        # Perform analysis against each rule
        It "should pass rule '<_>'" -TestCases $scriptAnalyzerRules {
            Invoke-ScriptAnalyzer -Path $FullName -IncludeRule $_ | Should -BeNullOrEmpty
        }
    }
}