BeforeAll {
    #region Reloading SUT
    # Ensuring that we are testing this version of module and not any other version that could be in memory
    $modulePath = "$PSScriptRoot\..\CITest.psm1"
    $moduleName = (($modulePath | Split-Path -Leaf) -replace '.psm1')
    @(Get-Module -Name $moduleName).where({ $_.version -ne '0.0' }) | Remove-Module # Removing all module versions from the current context if there are any
    Import-Module -Name $modulePath -Force -ErrorAction Stop # Loading module explicitly by path and not via the manifest
    #endregion
}

Describe "Get-TestData" {
    Context "Lookup data with non-existant path" {
        It "should throw an error (without Id)" {
            "TestDrive:\test.db" | Should -Not -Exist
            { Get-TestData -Path "TestDrive:\test.db" -ErrorAction Stop } | Should -Throw
        }

        It "should throw an error (with Id)" {
            "TestDrive:\test.db" | Should -Not -Exist
            { Get-TestData -Id 1 -Path "TestDrive:\test.db" -ErrorAction Stop } | Should -Throw
        }
    }
    Context "Lookup data with existant path" {
        BeforeEach {
            Install-TestDatabase "TestDrive:\test.db"
        }
        It "should show all data (Count > 1)" {
            $data = Get-TestData -Path "TestDrive:\test.db"
            $data | Should -ExpectedType [System.Data.DataRow]
            $data.Count | Should -BeGreaterThan 1

        }

        It "should show single data (Count == 1)" {
            $data = Get-TestData -Id 1 -Path "TestDrive:\test.db"
            $data | Should -ExpectedType [System.Data.DataRow]
            $data.Count | Should -Be 1
        }
    }
    Context "Lookup data with non-existant Id" {
        BeforeEach {
            Install-TestDatabase "TestDrive:\test.db"
        }
        It "should throw an error on integer" {
            { Get-TestData -Id 3 -Path "TestDrive:\test.db" -ErrorAction Stop } | Should -Throw
        }

        It "should throw an error on non-integer" {
            { Get-TestData -Id 'a' -Path "TestDrive:\test.db" -ErrorAction Stop } | Should -Throw
        }
    }
}