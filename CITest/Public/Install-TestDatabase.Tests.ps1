BeforeAll {
    #region Reloading SUT
    # Ensuring that we are testing this version of module and not any other version that could be in memory
    $modulePath = "$PSScriptRoot\..\CITest.psm1"
    $moduleName = (($modulePath | Split-Path -Leaf) -replace '.psm1')
    @(Get-Module -Name $moduleName).where({ $_.version -ne '0.0' }) | Remove-Module # Removing all module versions from the current context if there are any
    Import-Module -Name $modulePath -Force -ErrorAction Stop # Loading module explicitly by path and not via the manifest
    #endregion
}

Describe "Install-TestDatabase" {
    Context "Non-existing path" {
        It "should create a database" {
            "TestDrive:\test.db" | Should -Not -Exist
            Install-TestDatabase -Path "TestDrive:\test.db"
            "TestDrive:\test.db" | Should -Exist
        }
    }
}