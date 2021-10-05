BeforeDiscovery {
    #region Reloading SUT
    # Ensuring that we are testing this version of module and not any other version that could be in memory
    $modulePath = "$PSScriptRoot\..\CITest.psm1"
    $moduleName = (($modulePath | Split-Path -Leaf) -replace '.psm1')
    Remove-Module $moduleName -ErrorAction SilentlyContinue # Removing all module versions from the current context if there are any
    Import-Module -Name $modulePath -Force -ErrorAction Stop # Loading module explicitly by path and not via the manifest
    #endregion
}

InModuleScope CITest {
    Describe "Get-PrivTestData" {
        Context "Lookup existing ID" {
            BeforeAll {
                Install-TestDatabase -Path "TestDrive:\test.db"

                $db = [Database]::New("TestDrive:\test.db")
                $db.Open()
            }

            It "should show item with ID <_>" -TestCases @(1,2) {
                $data = Get-PrivTestData -Id $_
                $data | Should -ExpectedType [System.Data.DataRow]
                $data.Count | Should -Be 1
                $data.id | Should -Be $_
            }

            AfterAll {
                $db.Close()
            }
        }
        Context "Lookup non-existing ID" {
            BeforeAll {
                Install-TestDatabase -Path "TestDrive:\test.db"
                . "$PSScriptRoot\..\Classes\Database.ps1"

                $db = [Database]::New("TestDrive:\test.db")
                $db.Open()
            }

            It "should be null/empty or throw with id '<_>'" -TestCases @(3, 4, 'a', '+') {
                if ($_ -is [int]) {
                    Get-PrivTestData -Id $_ | Should -BeNullOrEmpty
                }
                else {
                    { Get-PrivTestData -Id $_ -ErrorAction Stop } | Should -Throw
                }
            }

            AfterAll {
                $db.Close()
            }
        }
    }
}