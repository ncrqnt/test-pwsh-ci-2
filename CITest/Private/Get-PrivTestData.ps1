<#
.SYNOPSIS
    Get the test data (private function)
.DESCRIPTION
    This function fetches the test data from the database. Either by using ID or every entry.

    This is used just as an example module in order to test GitHub's CI functionalities
.EXAMPLE
    PS C:\> Get-PrivTestData -Id 1 -Path .\test.db

    Fetches the data from .\test.db with the ID 1
.INPUTS
    -Id: Optionally ID
    -Path: Path to database location
.OUTPUTS
    Nonr
.NOTES
    Author:     ncrqnt
    Date:       28.09.2021
    PowerShell: 7.1.4

    Changelog:
    1.0.0   28.09.2021  ncrqnt      Initial creation
#>

function Get-PrivTestData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [int]$Id
    )

    begin {
        # nothing to do
    }

    process {
        Write-Verbose "Fetch data and output"
        $select = $db.Query("SELECT * FROM person WHERE id = @id", @{ id = $Id })[0]

        return $select
    }

    end {
        # nothing to do
    }
}