#region import classes
$classes = Get-ChildItem -Path $PSScriptRoot\Classes\*.ps1 -ErrorAction SilentlyContinue

foreach ($class in $classes) {
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
$public = @(Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1" -Exclude "*.Tests.*" -ErrorAction SilentlyContinue)
$private = @(Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" -Exclude "*.Tests.*" -ErrorAction SilentlyContinue)
#endregion

#region source the files
foreach ($function in @($public + $private)) {
    $functionPath = $function.FullName
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
Export-ModuleMember -Function $public.BaseName
#endregion