<#
.SYNOPSIS
Add required DLLs to the path and run the built executable

.DESCRIPTION
Crane Dynamics Simulator
Helper for solving equations exported to C++ with solveMode="sundials"

PARAMETERS
-ExeName <string>
	The name of an executable file in 'run_sundials/bin/'
	Specify either with or without the file extension
	Alternatively, the absolute or relative path may be specified

EXAMPLE
	./runExe.ps1 "test_arma"

EXAMPLE
	# The solution is printed to the standard out
	# To save the results to a file, redirect standard out as follows
	./runExe.ps1 "myModels-myPendulum" > "./data/sundials_results/myResults/myModels-myPendulum.txt"
#>

# Written by:      Brandon Johns
# Version created: 2022-02-19
# Last edited:     2026-09-13


################################################################
# Script input
################################
param (
	[Parameter(Mandatory=$true)][string]$ExeName
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest


################################################################
# Script Config
################################
# Path to project root
$CDS_Root = Resolve-Path( Join-Path $PSScriptRoot ".." )

# Path to this CMake project
$Project_Root = (Join-Path $CDS_Root "run_sundials")


################################################################
# Automated
################################
# Locations
$CDS_LibRoot = (Join-Path $CDS_Root "lib_windows/install")
$Project_bin = (Join-Path $Project_Root "bin") # Path to output generated exe

# Find exe
if ( -not $ExeName.EndsWith(".exe") ) { $ExeName += ".exe" }

if    ( Test-Path $ExeName                          -PathType "Leaf" ) { $exePath = $ExeName }
elseif( Test-Path (Join-Path $Project_bin $ExeName) -PathType "Leaf" ) { $exePath = (Join-Path $Project_bin $ExeName) }
else { throw "Input file not found" }

# Temporarily add DLLs to path
#	Changing $env:PATH only effects the current session. That is, the currently open powershell the window
#	See powershell docs: "about_environment_variables"
$DLL_Directories = Get-ChildItem $CDS_LibRoot *.dll -Recurse | ForEach-Object { $_.DirectoryName } | Sort-Object -Unique
foreach($dir in $DLL_Directories) {
	# Don't add if already on path (from multiple runs of this script)
	if($dir -notin ( $env:PATH -split [IO.Path]::PathSeparator)) {
		$env:PATH += ([IO.Path]::PathSeparator + $dir)
	}
}

# Run exe
& $exePath

