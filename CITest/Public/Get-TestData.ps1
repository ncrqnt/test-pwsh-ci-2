<#
.SYNOPSIS
    Get the test data
.DESCRIPTION
    This function fetches the test data from the database. Either by using ID or every entry.

    This is used just as an example module in order to test GitHub's CI functionalities
.PARAMETER Id
    Unique ID of item in database
.PARAMETER Path
    Path to sqlite3 database file
.EXAMPLE
    PS C:\> Get-TestData -Id 1 -Path .\test.db

    Fetches the data from .\test.db with the ID 1
.INPUTS
    System.Int
    System.Path
.OUTPUTS
    $null
.NOTES
    Author:     ncrqnt
    Date:       28.09.2021
    PowerShell: 7.1.4

    Changelog:
    1.0.0   28.09.2021  ncrqnt      Initial creation
#>

function Get-TestData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$Id,
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Path to database file")]
        [ValidateScript({ if (Test-Path $_ -PathType Leaf) { $true } else { throw "$_ not found or not a file." } })]
        [string]$Path
    )

    begin {
        $db = New-Object -TypeName Database -ArgumentList $Path
    }

    process {
        if ($Id) {
            Write-Verbose "Id '$Id' passed"
            $select = $db.Query("SELECT * FROM person WHERE id = @id", @{ id = $Id })[0]

            if ($null -ne $select) {
                Get-PrivTestData -Id $Id
            }
            else {
                Write-Error "Person with ID '$Id' does not exist."
                return
            }
        }
        else {
            Write-Verbose "Get all entries"
            $select = $db.Query("SELECT * FROM person")

            if ($select.count -gt 0) {
                foreach ($person in $select) {
                    Get-PrivTestData -Id $person.id
                }
            }
            else {
                Write-Error "Database is empty."
                return
            }
        }
    }

    end {
        $db.Close()
    }
}