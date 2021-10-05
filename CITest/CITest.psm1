#region import classes
$Classes = Get-ChildItem -Path $PSScriptRoot\Classes\*.ps1 -ErrorAction SilentlyContinue

foreach ($class in $Classes) {
    try {
        . $class.FullName
    }
    catch {
        Write-Error -Message "Failed to import class at '$($class.FullName)': $_"
        exit
    }
}
#endregion

#region get public and private function definition files.
$Public  = @(
    Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue
)
$Private = @(
    Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue
)
#endregion

#region source the files
foreach ($function in @($Public + $Private)) {
    $functionPath = $function.fullname
    try {
        . $functionPath # dot source function
    }
    catch {
        Write-Error -Message "Failed to import function at '$functionPath': $_"
        exit
    }
}
#endregion

#region read in or create an initial config file and variable

#endregion

#region set variables visible to the module and its functions only

#endregion

#region export Public functions ($Public.BaseName) for WIP modules
Export-ModuleMember -Function $Public.Basename
#endregion