# Lang: Powershell
# Written by:		Brandon Johns
# Version created:	2022-02-19
# Last edited:		2022-02-19

# Purpose: Find DLLs and run binary

# Sample use:
#	./runExe.ps1 "test_arma"

################################################################
# Script input
################################
param (
	[Parameter(Mandatory=$true,ValueFromPipeline=$false)][string]$exeName
)
# INPUT:
#	exeName = path to / name of exe
#		absolute path
#		relative path
#		name (if in "/bin")


################################################################
# Script Config
################################
# Path to project root
$CDS_Root = Resolve-Path( Join-Path $PSScriptRoot ".." )


################################################################
# Automated
################################
# Locations
$CDS_LibRoot   = (Join-Path $CDS_Root "lib_windows/install")

# Find exe
if ( -not $exeName.EndsWith(".exe") ) { $exeName += ".exe" }

if    ( Test-Path $exeName                   -PathType "Leaf" ) { $exePath = $exeName }
elseif( Test-Path (Join-Path "bin" $exeName) -PathType "Leaf" ) { $exePath = (Join-Path "bin" $exeName) }
else { throw "input file not found" }

# DLLs: Temporarily add to path
#	https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_environment_variables?view=powershell-5.1
#		When you change environment variables in PowerShell, the change affects only the current session
$DLL_Directories = (Get-ChildItem $CDS_LibRoot *.dll -Recurse).DirectoryName | Get-Unique
$DLL_Directories | ForEach-Object {
	# Don't add if already on path (from multiple runs of this script)
	if(-not ( $env:PATH.Contains($_) )) { $env:PATH  += ";" + $_ }
}

# Run exe
#	NOTE: "Start-Process $exePath -NoNewWindow -Wait" is no good because the process is detached => hard to capture output
& $exePath


