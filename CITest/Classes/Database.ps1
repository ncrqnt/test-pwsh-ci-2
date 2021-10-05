#requires -modules SimplySql

class Database {
    [string]$database

    Database([string]$database) {
        $this.database = $database
        $this.Open($this.database)
    }

    Open([string]$database) {
        $this.database = $database
        Open-SQLiteConnection -DataSource $this.database

        $tables = $this.Query("SELECT name FROM sqlite_master WHERE type='table';")

        # create tables if they don't exist
        if ($tables.count -eq 0) {
            # table 'rule'
            $create = ' CREATE TABLE "person" (
                            "id"            INTEGER NOT NULL UNIQUE,
                            "first_name"    TEXT,
                            "last_name"     TEXT,
                            "dob"           TEXT,
                            "sex"           TEXT,
                            "is_enabled"    INTEGER NOT NULL DEFAULT 1,
                            "update_date"   TEXT NOT NULL,
                            CONSTRAINT "person_pk" PRIMARY KEY("id" AUTOINCREMENT)
                        );'
            $this.Update($create)
        }
    }

    Open() {
        $this.Open($this.database)
    }

    [array] Query([string]$query, [hashtable]$parameters) {
        $answer = Invoke-SqlQuery -Query $query -Parameters $parameters -ErrorAction Stop
        if ($null -eq $answer) {
            $result = @()
        }
        elseif ($answer.Count -eq 1) {
            $result = @($answer)
        }
        else {
            $result = $answer
        }
        return $result
    }

    [array] Query([string]$query) {
        return $this.Query($query, $null)
    }

    Update([string]$query, [hashtable]$parameters) {
        Invoke-SqlUpdate -Query $query -Parameters $parameters -ErrorAction Stop | Out-Null
    }

    Update([string]$query) {
        $this.Update($query, $null)
    }

    [bool] Test() {
        return Test-SqlConnection
    }

    Close() {
        Close-SqlConnection
    }
}