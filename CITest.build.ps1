#requires -modules InvokeBuild

<#
.SYNOPSIS
    Build script (https://github.com/nightroman/Invoke-Build)
.DESCRIPTION
    This script contains the tasks for building the 'SampleModule' PowerShell module
#>

Param (
    [Parameter(Mandatory = $false)]
    [ValidateSet('Debug', 'Release')]
    [String]$Configuration = 'Debug',
    [Parameter(Mandatory = $false)]
    [int]$Major,
    [Parameter(Mandatory = $false)]
    [int]$Minor
)

Set-StrictMode -Version Latest

# Synopsis: Default task
task . Clean, Build


# Install build dependencies
Enter-Build {

    # Installing PSDepend for dependency management
    if (-not (Get-Module -Name PSDepend -ListAvailable)) {
        Install-Module PSDepend -Force
    }
    Import-Module PSDepend

    # Installing dependencies
    Invoke-PSDepend -Force

    # Setting build script variables
    $script:moduleName = 'CITest'
    $script:moduleSourcePath = Join-Path -Path $BuildRoot -ChildPath $moduleName
    $script:moduleManifestPath = Join-Path -Path $moduleSourcePath -ChildPath "$moduleName.psd1"
    #$script:nuspecPath = Join-Path -Path $moduleSourcePath -ChildPath "$moduleName.nuspec"
    $script:buildOutputPath = Join-Path -Path $BuildRoot -ChildPath 'build'

    # Setting base module version and using it if building locally
    $script:newModuleVersion = New-Object -TypeName 'System.Version' -ArgumentList (0, 0, 1)

    # Setting the list of functions ot be exported by module
    $script:functionsToExport = (Test-ModuleManifest $moduleManifestPath).ExportedFunctions
}

# Synopsis: Analyze the project with PSScriptAnalyzer
task Analyze {
    # Get-ChildItem parameters
    $params = @{
        Path    = $moduleSourcePath
        Recurse = $true
        Include = "*.PSSA.Tests.*"
    }

    $files = @()
    $files += Get-ChildItem @params

    if (-not (Test-Path -Path $buildOutputPath -ErrorAction SilentlyContinue)) {
        New-Item -Path $buildOutputPath -ItemType Directory | Out-Null
    }

    # Pester parameters
    $pesterConfig = New-PesterConfiguration
    $pesterConfig.Run.Path = $files
    $pesterConfig.Run.PassThru = $true
    $pesterConfig.Run.Exit = $true
    $pesterConfig.TestResult.Enabled = $true
    $pesterConfig.TestResult.OutputFormat = "NUnitXml"
    $pesterConfig.TestResult.OutputPath = "$buildOutputPath\AnalyzerResults.xml"
    $pesterConfig.Output.Verbosity = 'None'

    # Invoke all tests
    $result = Invoke-Pester -Configuration $pesterConfig
    if ($result.Result -ne 'Passed') {
        $result | Format-List
        throw "One or more PSScriptAnalyzer rules have been violated. Build cannot continue!"
    }
}

# Synopsis: Test the project with Pester tests
task Test {

    # Get-ChildItem parameters
    $params = @{
        Path    = $moduleSourcePath
        Recurse = $true
        Include = "*.Tests.*"
        Exclude = "*.PSSA.*"
    }

    $files = Get-ChildItem @params

    if (-not (Test-Path -Path $buildOutputPath -ErrorAction SilentlyContinue)) {
        New-Item -Path $buildOutputPath -ItemType Directory | Out-Null
    }

    # Pester parameters
    $pesterConfig = New-PesterConfiguration
    $pesterConfig.Run.Path = $files
    $pesterConfig.Run.PassThru = $true
    $pesterConfig.Run.Exit = $true
    $pesterConfig.TestResult.Enabled = $true
    $pesterConfig.TestResult.OutputFormat = "NUnitXml"
    $pesterConfig.TestResult.OutputPath = "$buildOutputPath\PesterResults.xml"
    $pesterConfig.CodeCoverage.Enabled = $true
    $pesterConfig.CodeCoverage.OutputPath = "$buildOutputPath\CodeCoverage.xml"
    $pesterConfig.CodeCoverage.CoveragePercentTarget = 75
    $pesterConfig.Output.Verbosity = 'Normal'

    # Invoke all tests
    $result = Invoke-Pester -Configuration $pesterConfig
    if ($result.Result -ne 'Passed') {
        $result | Format-List
        throw "One or more Pester tests have failed. Build cannot continue!"
    }

    if ($result.CodeCoverage.CoveragePercent -lt $result.CodeCoverage.CoveragePercentTarget) {
        $result.CodeCoverage.CoverageReport | Format-List
        throw "Code Coverage does not meet expectations. Build cannot continue!"
    }
}

# Synopsis: Generate a new module version if creating a release build
task GenerateNewModuleVersion {

    # Define variable for existing package
    $existingPackage = $null

    try {
        # Look for the module package in the repository
        $existingPackage = Find-Module -Name $moduleName -ErrorAction SilentlyContinue
    }
    # In no existing module package was found, the base module version defined in the script will be used
    catch {
        Write-Warning "No existing package for '$moduleName' module was found in PSGallery!"
    }

    # If existing module package was found, try to install the module
    if ($existingPackage) {
        # Get the largest module version
        # $currentModuleVersion = (Get-Module -Name $moduleName -ListAvailable | Measure-Object -Property 'Version' -Maximum).Maximum
        $currentModuleVersion = New-Object -TypeName 'System.Version' -ArgumentList ($existingPackage.Version)

        # Set module version base numbers
        [int]$majorVer = $currentModuleVersion.Major
        [int]$minorVer = $currentModuleVersion.Minor
        [int]$buildVer = $currentModuleVersion.Build

        try {
            # Install the existing module from the repository
            Install-Module -Name $moduleName -RequiredVersion $existingPackage.Version
        }
        catch {
            throw "Cannot import module '$moduleName'!"
        }

        # Get the count of exported module functions
        $existingFunctionsCount = (Get-Command -Module $moduleName | Where-Object -Property Version -EQ $existingPackage.Version | Measure-Object).Count
        # Check if new public functions were added in the current build
        [int]$sourceFunctionsCount = (Get-ChildItem -Path "$moduleSourcePath\Public\*.ps1" -Exclude "*.Tests.*" | Measure-Object).Count
        [int]$newFunctionsCount = [System.Math]::Abs($sourceFunctionsCount - $existingFunctionsCount)

        # Increase the minor number if any new public functions have been added
        if ($newFunctionsCount -gt 0) {
            [int]$minorVer = $minorVer + 1
            [int]$buildVer = 0
        }
        # If not, just increase the build number
        else {
            [int]$buildVer = $buildVer + 1
        }

    }
    else {
        Remove-Module -Name $moduleName -Force -ErrorAction SilentlyContinue
        Import-Module -Name $moduleManifestPath -Force

        $module = Get-Module -Name $moduleName
        $currentModuleVersion = New-Object -TypeName 'System.Version' -ArgumentList ($module.Version)

        # Set module version base numbers
        [int]$majorVer = $currentModuleVersion.Major
        [int]$minorVer = $currentModuleVersion.Minor
        [int]$buildVer = $currentModuleVersion.Build

        if ($Major) {
            $majorVer = $Major
        }

        if ($Minor) {
            $minorVer = $Minor
        }

        if (-not $Major -and -not $Minor) {
            $buildVer++
        }
    }

    # Update the module version object
    $Script:newModuleVersion = New-Object -TypeName 'System.Version' -ArgumentList ($majorVer, $minorVer, $buildVer)
}

# Synopsis: Generate list of functions to be exported by module
task GenerateListOfFunctionsToExport {
    # Set exported functions by finding functions exported by *.psm1 file via Export-ModuleMember
    $params = @{
        Force    = $true
        Passthru = $true
        Name     = (Resolve-Path (Get-ChildItem -Path $moduleSourcePath -Filter '*.psm1')).Path
    }
    $PowerShell = [Powershell]::Create()
    [void]$PowerShell.AddScript(
        {
            Param ($Force, $Passthru, $Name)
            $module = Import-Module -Name $Name -PassThru:$Passthru -Force:$Force
            $module | Where-Object { $_.Path -notin $module.Scripts }
        }
    ).AddParameters($Params)
    $module = $PowerShell.Invoke()
    $Script:functionsToExport = $module.ExportedFunctions.Keys
}

# Synopsis: Update the module manifest with module version and functions to export
task UpdateModuleManifest GenerateNewModuleVersion, GenerateListOfFunctionsToExport, {
    # Update-ModuleManifest parameters
    $Params = @{
        Path              = $moduleManifestPath
        ModuleVersion     = $newModuleVersion
        FunctionsToExport = $functionsToExport
    }

    # Update the manifest file
    Update-ModuleManifest @Params
}

# Synopsis: Build the project
task Build UpdateModuleManifest, {
    # Warning on local builds
    if ($Configuration -eq 'Debug') {
        Write-Warning "Creating a debug build. Use it for test purpose only!"
    }

    # Create versioned output folder
    $moduleOutputPath = Join-Path -Path $buildOutputPath -ChildPath $moduleName -AdditionalChildPath $newModuleVersion
    if (-not (Test-Path $moduleOutputPath)) {
        New-Item -Path $moduleOutputPath -ItemType Directory | Out-Null
    }

    # Copy-Item parameters
    $Params = @{
        Path        = "$moduleSourcePath\*"
        Destination = $moduleOutputPath
        Exclude     = "*.Tests.*"
        Recurse     = $true
        Force       = $true
    }

    # Copy module files to the target build folder
    Copy-Item @Params
}

# Synopsis: Clean up the target build directory
task Clean {
    Remove-Module -Name $moduleName -Force -ErrorAction SilentlyContinue
    if (Test-Path $buildOutputPath) {
        Remove-Item –Path $buildOutputPath –Recurse
    }
}