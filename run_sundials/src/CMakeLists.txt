# CMakeList.txt : Top-level CMake project file
#	Global configuration and include sub-projects
cmake_minimum_required (VERSION 3.10)
project ("CDS_sundials")

# Written by:		Brandon Johns
# Version created:	2022-02-19
# Last edited:		2022-02-22
# Purpose:			For project "CDS"

####################################################################################
# Configure: Key locations
##########################################
# Git project
set(CDS_PROJECT_DIR       "${CMAKE_CURRENT_LIST_DIR}/../.."            CACHE PATH "dir CDS Project Root")
set(CDS_SUN_GENERATED_DIR "${CDS_PROJECT_DIR}/data/sundials_generated" CACHE PATH "dir Root of Matlab generated equations")
#set(CDS_SUN_RESULTS_DIR   "${CDS_PROJECT_DIR}/data/sundials_results"   CACHE PATH "dir Root of results for import into Matlab")

# This CMake project
set(PROJECT_DIR         "${CMAKE_CURRENT_LIST_DIR}/.." CACHE PATH "dir This CMake Project")
set(PROJECT_DIR_RUNTIME "${PROJECT_DIR}/bin"           CACHE PATH "dir to output exe into")


####################################################################################
# General options
##########################################
set(CMAKE_CXX_STANDARD 20)

# Compiler flags
#	More compiler warnings: -Wall -Wextra
#	Add debugging symbols to executable: -g
#	Opimise: -O3
#	Disable assertions: -DNDEBUG
#	Special warning flag: -Wabi-tag
#		If this triggers warnings, try set -D_GLIBCXX_USE_CXX11_ABI=0
IF(NOT WIN32)
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -g")
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wabi-tag")
endif()

# For VSCode extention "clangd"
#	CMAKE_EXPORT_COMPILE_COMMANDS generates the "compile_commands.json" file in the build dir
#	Reload the "clangd" extension to make it find the file
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

####################################################################################
# Host machine dependent
##########################################
# Identify the current computer by checking the hostname
# 	Should be unique in most cases
#	Otherwise, try check "if(WIN32)" or something else unique about the setup
#	Good variables to check:
#		https://cmake.org/cmake/help/latest/command/cmake_host_system_information.html

cmake_host_system_information(RESULT HOSTNAME_THIS_PC QUERY HOSTNAME)
message("CDS: hostname for this comuter: ${HOSTNAME_THIS_PC}")

# Windows: All windows installs should look the same
if(WIN32)
	# Paths to: Libraries, Includes (library header files), Packages
	set(CDS_LIB_DIR "${CDS_PROJECT_DIR}/lib_windows/install" CACHE PATH "dir lib root")
	# SUNDIALS
	set(SUNDIALS_INC_DIR "${CDS_LIB_DIR}/sundials/include" CACHE PATH "dir SUNDIALS h")
	set(SUNDIALS_LIB_DIR "${CDS_LIB_DIR}/sundials/lib" CACHE PATH "dir SUNDIALS lib")
	# Armadillo
	set(ARMADILLO_INC_DIR "${CDS_LIB_DIR}/armadillo/include" CACHE PATH "dir Armadillo h")
	set(ARMADILLO_LIB_DIR "" CACHE PATH "dir Armadillo lib") # Not for Windows
	# OpenBLAS
	set(OPENBLAS_INC_DIR "" CACHE PATH "dir OpenBLAS h") # Not for Windows
	set(OPENBLAS_LIB_DIR "${CDS_LIB_DIR}/armadillo/lib_win64" CACHE PATH "dir OpenBLAS lib")

##########################################
# MonARCH
elseif(EXISTS "/mnt/lustre/projects")
	# C++ Compiler
	#	Flag "-lm" for math.h library 
	set(CMAKE_CXX_COMPILER "/usr/local/gcc/8.1.0/bin/gcc")
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -D_GLIBCXX_USE_CXX11_ABI=0")
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -lm -lstdc++ -I/usr/local/gcc/8.1.0/include")
	
	# Paths to: Libraries, Includes (library header files), Packages
	set(CDS_LIB_DIR "${CDS_PROJECT_DIR}/lib_ubuntu/install" CACHE PATH "dir lib root")
	# SUNDIALS
	set(SUNDIALS_INC_DIR "${CDS_LIB_DIR}/sundials/include" CACHE PATH "dir SUNDIALS h")
	set(SUNDIALS_LIB_DIR "${CDS_LIB_DIR}/sundials/lib" CACHE PATH "dir SUNDIALS lib")
	# Armadillo
	set(ARMADILLO_INC_DIR "/usr/local/armadillo/9.200-rc1/include" CACHE PATH "dir Armadillo h")
	set(ARMADILLO_LIB_DIR "/usr/local/armadillo/9.200-rc1/lib64" CACHE PATH "dir Armadillo lib")
	# OpenBLAS
	set(OPENBLAS_INC_DIR "/usr/local/openblas/0.2.20/include" CACHE PATH "dirs OpenBLAS h")
	set(OPENBLAS_LIB_DIR "/usr/local/openblas/0.2.20/lib" CACHE PATH "dir OpenBLAS lib")

##########################################
# Ubuntu standard install (Really counting on arma to install to the right location here)
else()
	# Paths to: Libraries, Includes (library header files), Packages
	set(CDS_LIB_DIR "${CDS_PROJECT_DIR}/lib_ubuntu/install" CACHE PATH "dir lib root")
	# SUNDIALS
	set(SUNDIALS_INC_DIR "${CDS_LIB_DIR}/sundials/include" CACHE PATH "dir SUNDIALS h")
	set(SUNDIALS_LIB_DIR "${CDS_LIB_DIR}/sundials/lib" CACHE PATH "dir SUNDIALS lib")
	# Armadillo
	set(ARMADILLO_INC_DIR "/usr/local/include/" CACHE PATH "dir Armadillo h")
	set(ARMADILLO_LIB_DIR "/usr/local/lib/x86_64-linux-gnu" CACHE PATH "dir Armadillo lib")
	# OpenBLAS
	set(OPENBLAS_INC_DIR "" CACHE PATH "dir OpenBLAS h") # Not used I think?
	set(OPENBLAS_LIB_DIR "" CACHE PATH "dir OpenBLAS lib") # Hope it can find itself
endif()

# Path for output exe
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${PROJECT_DIR_RUNTIME}")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_DEBUG "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}") # For Windows
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_RELEASE "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}") # For Windows

####################################################################################
# Find all libraries
##########################################
# Settings for find_library()
#	This setting assumes that for a library "x"
#		Windows filename: x.lib
#		Windows filename: x.dll (shared library)
#		Linux filename: libx.a
#		Linux filename: libx.so (shared library)
#	Well, apparrently the person who compiled OpenBLAS on Windows decided to do their own thing T_T
if(WIN32)
	set(CMAKE_FIND_LIBRARY_PREFIXES ""  CACHE PATH "CMAKE_FIND_LIBRARY_PREFIXES")
	set(CMAKE_FIND_LIBRARY_SUFFIXES ".lib" CACHE PATH "CMAKE_FIND_LIBRARY_SUFFIXES")
else() # Ubuntu
	set(CMAKE_FIND_LIBRARY_PREFIXES "lib"  CACHE PATH "CMAKE_FIND_LIBRARY_PREFIXES")
	set(CMAKE_FIND_LIBRARY_SUFFIXES ".so;.a" CACHE PATH "CMAKE_FIND_LIBRARY_SUFFIXES")
endif()

# Find libraries (<varName> <fileName> <filePath> DOC <docstring>)
find_library(SUNDIALS_SOLVER_LIB sundials_cvode ${SUNDIALS_LIB_DIR} DOC "sundials_cvode lib")
find_library(SUNDIALS_NVEC_LIB sundials_nvecserial ${SUNDIALS_LIB_DIR} DOC "sundials_nvecserial lib")
find_library(SUNDIALS_MANYVEC_LIB sundials_nvecmanyvector ${SUNDIALS_LIB_DIR} DOC "sundials_nvecmanyvector lib")

if(NOT WIN32)
	# Windows version uses header files only
	find_library(ARMADILLO_LIB armadillo ${ARMADILLO_LIB_DIR} DOC "armadillo lib")
endif()

find_library(OPENBLAS_LIB openblas ${OPENBLAS_LIB_DIR} DOC "openblas lib")

####################################################################################
# Projects to build
##########################################
add_subdirectory("test_armadillo")
add_subdirectory("test_sundials")
add_subdirectory("SimC3")


