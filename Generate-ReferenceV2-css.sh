#!/bin/bash
## Written By: Brandon Johns
## Date Version Created: 2026-09-18
## Date Last Edited: 2026-09-19
## Purpose: Transform css with postcss
## Status: Complete

## Error action (exit!=0 or unbound var) -> terminate script
set -euo pipefail



################################################################
# Script Config
################################
scriptRoot="$(cd -- "$(dirname -- "$0")" && pwd)"

configMappedDir="$scriptRoot/doc/web-src/docker-postcss/"
htmlRootMappedDir="$scriptRoot/doc/public_html/crane-dynamics-simulator/"

# Relative to mapped root
inFile="assets/app.css"
outFile="assets/app-compiled.css"

imageName="cds-postcss"
forceRebuildImage=false
allowBuildImage=true

####################################################################################
## Automated
##########################################
## Test if Docker is running
if ! docker info > /dev/null 2>&1 ; then
	echo "CDS: Docker is not running."
	exit 1
fi

## Test if image has been built
if ! docker image inspect "$imageName" > /dev/null 2>&1 || [[ "$forceRebuildImage" = "true" ]] ; then
	echo "CDS: Docker image not found: $imageName"

	if [[ "$allowBuildImage" = "true" ]]; then
		echo "CDS: Building docker image: $imageName"
		docker build --tag "$imageName" "$configMappedDir"
	else
		exit 1
	fi
fi

echo "CDS: Starting run"
docker run --rm --volume \
	"$configMappedDir:/CDS_config:ro" \
	--volume "$htmlRootMappedDir:/CDS_run" \
	--workdir "/CDS_run" \
	"$imageName" \
	postcss --config "/CDS_config/postcss.config.js" "$inFile" -o "$outFile"

echo "CDS: Done"

