<#
.SYNOPSIS
Build CMake project on Windows with Visual Studio 2022

.DESCRIPTION
Crane Dynamics Simulator
Helper for solving equations exported to C++ with solveMode="sundials".

SIDE EFFECTS
	Deletes all files in 'run_sundials/build/'
	Deletes all executable and debug files in 'run_sundials/bin/'

CONFIG
	This script contains a hard coded path to Visual Studio Community 2022
	If you are running any other version, then the script will fail and you will need to change the path
	Note from the future: Look into "vswhere.exe" to solve this problem

PARAMETERS
	(none)

EXAMPLE
	./rebuild.ps1
#>

# Written by:      Brandon Johns
# Version created: 2022-02-19
# Last edited:     2026-09-13


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
$CDS_LibRoot   = (Join-Path $CDS_Root "lib_windows/install")
$Project_src   = (Join-Path $Project_Root "src")   # Path to my source
$Project_build = (Join-Path $Project_Root "build") # Path to cache
$Project_bin   = (Join-Path $Project_Root "bin")   # Path to output generated exe

# Validate script is in the correct directory
if(-not (Test-Path (Join-Path $Project_src "CMakeLists.txt")) ) {
	throw "CMake file not found"
}

# Create build directories
if(-not (Test-Path $Project_build) ) { New-Item -ItemType "directory" -Path $Project_build }
if(-not (Test-Path $Project_bin) )   { New-Item -ItemType "directory" -Path $Project_bin }

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

# Empty /build
# Empty only the files in the top level of /bin
if( Test-Path (Join-Path $Project_build "CMakeCache.txt") ) { Get-ChildItem $Project_build | Remove-Item -Recurse }
Get-ChildItem "$Project_bin/*" -File -Include ("*.exe","*.pdb","*.ilk","*.exp") | Remove-Item


# Initiate build tools
#	https://docs.microsoft.com/en-us/visualstudio/ide/reference/command-prompt-powershell
#	Have fun getting it to use x64
# & 'C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\Common7\Tools\Launch-VsDevShell.ps1' -SkipAutomaticLocation
& "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\Launch-VsDevShell.ps1" -SkipAutomaticLocation

## Run cmake
Push-Location $Project_build
cmake -G "Visual Studio 17 2022" -A x64 $Project_src
cmake --build . --target ALL_BUILD
Pop-Location

