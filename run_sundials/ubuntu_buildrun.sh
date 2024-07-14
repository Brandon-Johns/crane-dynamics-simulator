#!/bin/bash
## Written By: Brandon Johns
## Date Version Created: 2022-02-22
## Date Last Edited: 2022-02-24
## Purpose: Compile my code, which uses Sundials & Armadillo, on Ubuntu
## Status: Complete

## HELP:
##	./ubuntu_buildrun.sh -h

## EXAMPLE (1):
## Run these sequentially
## 1) Rebuild cache
## 2) List targets
## 3) Build and execute specific target
##	./ubuntu_buildrun.sh -c
##	./ubuntu_buildrun.sh -h
##	./ubuntu_buildrun.sh -be -r MyResultsFolder -t MyTarget1 -t MyTarget2 -t MyTarget3

## EXAMPLE (2):
## 1) Cache, build all, run all
##	./ubuntu_buildrun.sh -cbe -r MyResultsFolder


## Error action (exit!=0 or unbound var) -> terminate script
set -euo pipefail


################################################################
# Script Config
################################
## Path to project root
CDS_Root="$HOME/git/CDS"

## Path to this CMake project
Project_Root="${CDS_Root}/run_sundials"

## Directory name for archiving the exe in
DateNow=$(date +"%Y-%m-%d_%H_%M_%S")
exeArchiveDir="${DateNow}"


####################################################################################
## Automated - Read Input
##########################################
flagCache=''
flagBuild=''
flagExecute=''
resultsFolder='tmp'
declare -a targetNames=()
flagHelp=''
while getopts 'hcber:t:' flag; do
  case "${flag}" in
	h) flagHelp='true' ;;
    c) flagCache='true' ;;
    b) flagBuild='true' ;;
    e) flagExecute='true' ;;
    r) resultsFolder="${OPTARG}" ;;
    t) targetNames+=("${OPTARG}") ;;
    *) error "Unexpected option ${flag}"; exit 1 ;;
  esac
done
## If no options input -> set help flag
if [ $OPTIND -eq 1 ]; then flagHelp='true'; fi

## If no targets input -> set all
targetAll=''
if [[ "${#targetNames[@]}" = 0 ]]; then targetAll='true' ; fi

## Print options
if [[ "${flagCache}"   ]]; then echo "FLAG: Rebuild Cache" ; fi
if [[ "${flagBuild}"   ]]; then echo "FLAG: Build" ; fi
if [[ "${flagExecute}" ]]; then echo "FLAG: Execute" ; fi
if [[ "${targetAll}"   ]]; then echo "Targets: (All)" ; fi

for ExeName in "${targetNames[@]}"; do
  echo "Targets: ${ExeName}"
done

################################################################
# Automated - Setup
################################
## Locations
CDS_LibRoot="${CDS_Root}/lib_ubuntu/install"
CDS_sunResultsPath="${CDS_Root}/data/sundials_results/${resultsFolder}"
Project_src="${Project_Root}/src" ## Path to my source
Project_build="${Project_Root}/build" ## Path to cache
Project_bin="${Project_Root}/bin" ## Path to output generated exe

if [[ "${flagExecute}" ]]; then echo "Results @ ${CDS_sunResultsPath}"; fi

## Validate location of CMakeLists.txt
if [[ ! -f "${Project_src}/CMakeLists.txt" ]]; then echo "CDS_ERROR: CMakeLists.txt not found"; exit 1 ; fi

if [[ "${flagHelp}" ]]
then
	echo "HELP"
	echo "COMMANDS"
	echo "    -h = print this help"
	echo "    -c = Rebuild Cache"
	echo "    -b = build"
	echo "    -e = execute (all build targets will be executed)"
	echo "    -r = name of folder to place results in (not a path, just 1 folder name)"
	echo "    -t <targetName> = names of targets to build (unspecified = all)"
	echo "TARGETS IN CACHE"
	make help -C "${Project_build}"
	exit 0
fi

## Add libraries to path
##	Temporarily allow using unset variables (no the +&- are not reversed...)
set +u ; export LD_LIBRARY_PATH=$CDS_LibRoot:$LD_LIBRARY_PATH ; set -u


################################################################
# Automated - Main Section
################################
## Create build directories
if [[ ! -d "$Project_build" ]]; then mkdir -p "$Project_build"; fi
if [[ ! -d "$Project_bin" ]]; then mkdir -p "$Project_bin"; fi

if [[ "${flagCache}" ]]
then
	## Validate location of CMakeCache.txt (because running delete is dangerous)
	## Then Empty /build (but don't delete the dir itself)
	if [[ -f "${Project_build}/CMakeCache.txt" ]]; then find "${Project_build}" -mindepth 1 -delete ; fi

	## Generate cache
	echo "CDS_INFO: start cmake"
	date -Iseconds
	cmake -S "${Project_src}" -B "${Project_build}"
fi

if [[ "${flagBuild}" ]]
then
	## Build my code
	echo "CDS_INFO: start make"
	date -Iseconds
	cd "${Project_build}"
	if [[ "${targetAll}" ]]
	then
		cmake --build "${Project_build}"
	else
		cmake --build "${Project_build}" --target "${targetNames[@]}"
	fi
fi

if [[ "${flagExecute}" ]];
then
	## Create resutls & archive directories
	exeArchivePath="${Project_bin}/${exeArchiveDir}"
	if [[ ! -d "$CDS_sunResultsPath" ]]; then mkdir -p "$CDS_sunResultsPath"; fi
	if [[ ! -d "$exeArchivePath" ]]; then mkdir -p "$exeArchivePath"; fi

	## Run all files in bin
	##	Using non-recursive 'for'
	cd "${Project_bin}"
	for exePath in "${Project_bin}/"*
	do
		## Only run on files
		if [[ -f "${exePath}" ]]
		then
			exeFilename=$(basename $exePath)
			resultsFile="${CDS_sunResultsPath}/${exeFilename}.txt"
			## Run exe and output to txt file of same name
			echo "CDS_INFO: running ${exeFilename}"
			date -Iseconds

			## Run, then archive the exe
			set +e ## Allow Errors (START)
			./${exeFilename} > "${resultsFile}"
			mv -b "${exePath}" "${exeArchivePath}"
			set -e ## Allow Errors (END)
		fi
	done
fi

echo "CDS_INFO: end"
date -Iseconds
