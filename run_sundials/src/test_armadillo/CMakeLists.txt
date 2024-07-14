# Mid/Low-level CMake project file
#	Project specific logic: include source and define output
cmake_minimum_required (VERSION 3.10)

####################################################################################
# All dependancies
##########################################
set(LIBRARIES
	${ARMADILLO_LIB} # OS dependent: Win="", Linux = path to libarmadillo.so
	${OPENBLAS_LIB} # Required for some armadillo functions
)

set(LIBRARIES_DIR
	${OPENBLAS_LIB_DIR}
)

set(INCLUDES_DIR
	${ARMADILLO_INC_DIR}
	${OPENBLAS_INC_DIR}
)

set(INCLUDES_LOCAL_DIR 
	#${CMAKE_CURRENT_LIST_DIR}
)

####################################################################################
# Build
##########################################
# Source files containing main()
#	set(Sources <exe1> [exe2] ...)
# Dependencies not including main()
set(Sources "test_arma")
set(Dependencies )

foreach(Source ${Sources})
	# Choose Output filename
	set(ExeName "${Source}")

	# Libraries to link against - Directories
	if(NOT WIN32)
		link_directories(${LIBRARIES_DIR})
	endif()

	# Link source files to output file (<exeName> <source1.c> [source2.c|.h] ...)
	add_executable(${ExeName} ${Source}.cpp ${Dependencies})

	# Directories to include
	target_include_directories(${ExeName} PRIVATE ${INCLUDES_DIR} ${INCLUDES_LOCAL_DIR})

	# Libraries to link against - Libraries
	target_link_libraries(${ExeName} PUBLIC ${LIBRARIES})
endforeach()
