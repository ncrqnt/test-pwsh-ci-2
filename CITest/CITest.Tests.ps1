# Set-StrictMode -Version latest

BeforeDiscovery {
    #region Get functionsPaths
    $functionPaths = @()
    if (Test-Path "$PSScriptRoot\Private\*.ps1") {
        $functionPaths += Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" -Exclude "*.Tests.*"
    }
    if (Test-Path "$PSScriptRoot\Public\*.ps1") {
        $functionPaths += Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1" -Exclude "*.Tests.*"
    }
    #endregion

    #region Get functions data
    $functions = @()
    foreach ($function in $functionPaths) {
        $abstractSyntaxTree = [System.Management.Automation.Language.Parser]::ParseInput((Get-Content -Raw $function.FullName), [ref]$null, [ref]$null)
        $astSearchDelegate = { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }
        $parsedFunction = $abstractSyntaxTree.FindAll($astSearchDelegate, $true) | Where-Object Name -eq $function.BaseName

        $functions += @{
            Name = $function.BaseName
            Path = $function.FullName
            HelpContent = $parsedFunction.GetHelpContent()
            Parameters = $parsedFunction.Body.ParamBlock.Parameters.Name.VariablePath.UserPath
        }
    }
}

BeforeAll {
    # Current location
    $script:here = $PSScriptRoot

    #region Reloading SUT
    # Ensuring that we are testing this version of module and not any other version that could be in memory
    $modulePath = "$($PSCommandPath -replace '.Tests.ps1$', '').psm1"
    $moduleName = (($modulePath | Split-Path -Leaf) -replace '.psm1')
    @(Get-Module -Name $moduleName).where({ $_.version -ne '0.0' }) | Remove-Module # Removing all module versions from the current context if there are any
    Import-Module -Name $modulePath -Force -ErrorAction Stop # Loading module explicitly by path and not via the manifest
    #endregion
}

# Running tests for the module
Describe "<moduleName>" {
    Context 'Module Setup' {
        It "should have a root module" {
            Test-Path $modulePath | Should -Be $true
        }

        It "should have an associated manifest" {
            Test-Path "$here\$moduleName.psd1" | Should -Be $true
        }

        It "should have public functions" {
            Test-Path "$here\Public\*.ps1" | Should -Be $true
        }

        It "should be a valid PowerShell code" {
            $psFile = Get-Content -Path $modulePath -ErrorAction Stop
            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize($psFile, [ref]$errors)
            $errors.Count | Should -Be 0
        }
    }

    Context "Module Control" {
        It "should import without errors" {
            { Import-Module -Name $modulePath -Force -ErrorAction Stop } | Should -Not -Throw
            Get-Module -Name $moduleName | Should -Not -BeNullOrEmpty
        }

        It 'should remove without errors' {
            { Remove-Module -Name $moduleName -ErrorAction Stop } | Should -Not -Throw
            Get-Module -Name $moduleName | Should -BeNullOrEmpty
        }
    }
}

Describe "<Name>" -ForEach $functions {
    Context 'Function Code Style Tests' {
        It "should be an advanced function" {
            $Path | Should -FileContentMatch 'Function'
            $Path | Should -FileContentMatch 'CmdletBinding'
            $Path | Should -FileContentMatch 'Param'
        }

        It "should contain Write-Verbose blocks" {
            $Path | Should -FileContentMatch 'Write-Verbose'
        }

        It "should be a valid PowerShell code" {
            $psFile = Get-Content -Path $Path -ErrorAction Stop
            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize($psFile, [ref]$errors)
            $errors.Count | Should -Be 0
        }

        It "should have tests" {
            $testFile = ($Path -replace ".ps1", ".Tests.ps1")
            Test-Path $testFile | Should -Be $true
            $testFile | Should -FileContentMatch ('Describe .*' + $Name + '.*')
        }
    }

    Context "Function Help Quality Tests" {
        It "should have a SYNOPSIS" {
            $HelpContent.Synopsis | Should -Not -BeNullOrEmpty
        }

        It "should have a DESCRIPTION with length > 40 symbols" {
            $HelpContent.Description.Length | Should -BeGreaterThan 40
        }

        It "should have at least one EXAMPLE" {
            $HelpContent.Examples.Count | Should -BeGreaterThan 0
            $HelpContent.Examples[0] | Should -Match ([regex]::Escape($Name))
            $HelpContent.Examples[0] | Should -BeGreaterThan ($Name.Length + 10)
        }

        It "should have descriptive help for '<_>' parameter" -TestCases $Parameters {
            $HelpContent.Parameters.($_.ToUpper()) | Should -Not -BeNullOrEmpty
            $HelpContent.Parameters.($_.ToUpper()).Length | Should -BeGreaterThan 25
        }
    }
}