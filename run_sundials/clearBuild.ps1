<#
.SYNOPSIS
Delete CMake build cache and/or built executable files

.DESCRIPTION
Crane Dynamics Simulator
Helper for solving equations exported to C++ with solveMode="sundials".

PARAMETERS
-Build : Delete all files in 'run_sundials/build/'
-Bin   : Delete all executable and debug files in 'run_sundials/bin/'

EXAMPLE
	./clearBuild.ps1 -Build -Bin
#>

# Written by:      Brandon Johns
# Version created: 2022-02-19
# Last edited:     2026-09-13


################################################################
# Script input
################################
param (
	[Switch]$Build,
	[Switch]$Bin
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if(-not ($Build -or $Bin)) {
	Write-Warning "`n    AT LEAST ONE INPUT IS REQUIRED`n    DISPLAYING HELP"
	Get-Help $PSCommandPath
	exit
}


################################################################
# Script Config
################################
# Path to this CMake project
$Project_Root = $PSScriptRoot


################################################################
# Automated
################################
# Locations
$Project_build = (Join-Path $Project_Root "build") # Path to cache
$Project_bin   = (Join-Path $Project_Root "bin")   # Path to output generated exe

# Validate script is in the correct directory
if(-not (Test-Path (Join-Path $Project_Root "src/CMakeLists.txt")) ) {
	throw "CMake file not found"
}

# Empty /build
if($Build) {
	if(Test-Path (Join-Path $Project_build "CMakeCache.txt")) {
		Get-ChildItem $Project_build | Remove-Item -Recurse
		Write-Host "Build Cleared"
	}
	elseif(Test-Path $Project_build) {
		Write-Warning "Build files not found (build directory might already be empty)"
	}
	else {
		Write-Warning "Build directory not found"
	}
}

# Empty only the files in the top level of /bin
if($Bin) {
	if(Test-Path $Project_bin) {
		Get-ChildItem "$Project_bin/*" -File -Include ("*.exe","*.pdb","*.ilk","*.exp") | Remove-Item
		Write-Host "Bin Cleared"
	}
	else {
		Write-Warning "Bin directory not found"
	}
}

