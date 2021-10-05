<#
.SYNOPSIS
    Installs the test database
.DESCRIPTION
    This function installs the test database to the specified folder (or current folder)
    with a predefined test set.

    This is used just as an example module in order to test GitHub's CI functionalities
.EXAMPLE
    PS C:\> Install-TestDatabase -Path .\test.db

    Creates database and inserts test data to the specified file path.
.INPUTS
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

function Install-TestDatabase {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Path to database file")]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
    )

    begin {
        $folder = Split-Path $Path
        if (-not (Test-Path $folder)) {
            New-Item -Path $folder -ItemType Directory -Force | Out-Null
        }

        $db = New-Object -TypeName Database -ArgumentList $Path
    }

    process {
        Write-Verbose "Define test data"
        $dataset = @(
            @{
                id = $null
                firstname = 'Max'
                lastname = 'Mustermann'
                dob = '01.01.1970'
                sex = 'm'
                isEnabled = 1
                updateDate = (Get-Date -Format 'o')
            }
            @{
                id = $null
                firstname = 'Jane'
                lastname = 'Doe'
                dob = '01.01.1990'
                sex = 'f'
                isEnabled = 0
                updateDate = (Get-Date -Format 'o')
            }
        )

        Write-Verbose "Insert test data to database"
        foreach ($data in $dataset) {
            $query = "INSERT INTO person
                      VALUES (@id, @firstname, @lastname, @dob, @sex, @isEnabled, @updateDate)"
            $db.Update($query, $data)
        }
    }

    end {
        $db.Close()
    }
}