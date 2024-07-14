#!/bin/bash
## Written By: Brandon Johns
## Date Version Created: 2022-02-22
## Date Last Edited: 2022-02-22
## Purpose: Compile & install sundials on Ubuntu
## Status: Complete

## INSTRUCTIONS: See Install_Instructions_Ubuntu.txt
##	Download CDS
##	Download SUNDIALS zip
##	Bash:
##		./<this script>


################################################################
## Script Config
################################
## Path to project root
CDS_Root="$HOME/git/CDS"

## Path to sundials zip file & filename
sunZip="${CDS_Root}/lib_ubuntu/src/cvode-6.1.1.tar.gz"

## Path (internal to the zip file) from root of zip file to the dir containing the CMakeLists.txt
sunZip_internalProjectPath="cvode-6.1.1"


################################################################
## Automated
################################
## Error action -> terminate script
set -e

## Locations
CDS_LibRoot="${CDS_Root}/lib_ubuntu"
CDS_Lib_src="${CDS_LibRoot}/src"
Sun_src="${CDS_Lib_src}/${sunZip_internalProjectPath}"
Sun_build="${CDS_LibRoot}/build/sundials"
Sun_install="${CDS_LibRoot}/install/sundials"

## Create build directories
if [[ ! -d "$CDS_Lib_src" ]]; then mkdir -p "$CDS_Lib_src"; fi
if [[ ! -d "$Sun_build" ]]; then mkdir -p "$Sun_build"; fi
if [[ ! -d "$Sun_install" ]]; then mkdir -p "$Sun_install"; fi

cd "${Sun_build}"
tar xzf "${sunZip}" --directory "${CDS_Lib_src}"

## Install sundials
cd "${Sun_build}"
cmake -DCMAKE_INSTALL_PREFIX="$Sun_install" \
	-DEXAMPLES_INSTALL_PATH="$Sun_install/examples" \
	"${Sun_src}"
make
make install
