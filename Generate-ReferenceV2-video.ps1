## Written By: Brandon Johns
## Date Version Created: 2026-09-19
## Date Last Edited: 2026-09-19
## Purpose: Encode and optimise a video for web
## Status: Complete

## Instructions
##    Set variable fileIn
##    Then call from project root directory

## Recommendations
##    Export videos from matlab at 60fps, especially if fast moving


$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest


################################################################################################
## Configuration
################################################
$Path_ffmpeg = "C:\Users\Brand\ffmpeg-n7.1-latest-win64-gpl-7.1\bin\ffmpeg.exe"

$ProjectRoot = $PSScriptRoot;
$fileIn = "$ProjectRoot/data/matlab_fig/doc/E18_FlyingFox_60fps.mp4"
$dirOut = "$ProjectRoot/doc/public_html/crane-dynamics-simulator/video/"

# There is no reason to turn this off if the GPU is available (av1 is extremely slow without gpu)
$useIntelGPU = $true


################################################################################################
## Automated
################################################
If( -not (Test-Path -LiteralPath $Path_ffmpeg -PathType Leaf)) { throw "ffmpeg not found" }
If( -not (Test-Path -LiteralPath $dirOut -PathType Container)) { throw "Output directory not found" }
If( -not (Test-Path -LiteralPath $fileIn -PathType Leaf))      { throw "Input file not found" }

$fileIn = Get-Item $fileIn

$dirOut = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($dirOut)
$fileOut_mp4  = Join-Path $dirOut ($fileIn.BaseName + ".mp4")
$fileOut_webm = Join-Path $dirOut ($fileIn.BaseName + ".webm")
$fileOut_webp = Join-Path $dirOut ($fileIn.BaseName + ".webp")


## Run these commands to read the encoder options and defaults for my specific GPU
#& $Path_ffmpeg -h encoder=h264_qsv
#& $Path_ffmpeg -h encoder=av1_qsv
#exit


# ffmpeg Flags
# -i  = input file
# -c  = codec
# -an = no audio
# -preset                  = quality vs encoding speed (slower gives better quality)
# -crf or --global_quality = quality vs file size      (lower number means better quality)
# -movflags +faststart     = place metadata at start of file
$args_h264_mp4 = @(
  "-c:v", ($useIntelGPU ? "h264_qsv" : "libx264"),
  "-preset", "veryslow",
  "-pix_fmt", ($useIntelGPU ? "nv12" : "yuv420p"), # nv12 and yuv420p both result in the same output px format. Leaky abstraction.
  "-movflags", "+faststart",
  "-an"
)
$args_av1_webm = @(
  "-c:v", ($useIntelGPU ? "av1_qsv" : "libaom-av1"),
  "-preset", ($useIntelGPU ? "veryslow" : "medium"),
  "-an"
)
if($useIntelGPU) {
	$args_h264_mp4 += @("-global_quality","21", "-look_ahead","1", "-look_ahead_depth","40")
	$args_av1_webm += @("-global_quality","28", "-extbrc","1",     "-look_ahead_depth","40")
}
else {
	$args_h264_mp4 += @("-crf", "23")
	$args_av1_webm += @("-crf", "32")
}

& $Path_ffmpeg -i $fileIn $args_h264_mp4 $fileOut_mp4 -y -hide_banner
& $Path_ffmpeg -i $fileIn $args_av1_webm $fileOut_webm -y -hide_banner

## Poser image
& $Path_ffmpeg -ss 0.3 -i $fileIn -frames:v 1 -c:v libwebp -quality 90 $fileOut_webp -y -hide_banner

