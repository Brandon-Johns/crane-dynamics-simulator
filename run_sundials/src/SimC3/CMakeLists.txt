# Mid/Low-level CMake project file
#	Project specific logic: include source and define output
cmake_minimum_required (VERSION 3.10)

####################################################################################
# All dependancies
##########################################
set(LIBRARIES
	${SUNDIALS_SOLVER_LIB}
	${SUNDIALS_NVEC_LIB}
	${SUNDIALS_MANYVEC_LIB}
	${ARMADILLO_LIB} # OS dependent: Win="", Linux = path to libarmadillo.so
	${OPENBLAS_LIB} # Required for some armadillo functions
)

set(LIBRARIES_DIR
	${SUNDIALS_LIB_DIR}
	${OPENBLAS_LIB_DIR}
)

set(INCLUDES_DIR
	${SUNDIALS_INC_DIR}
	${ARMADILLO_INC_DIR}
	${OPENBLAS_INC_DIR}
)

set(INCLUDES_LOCAL_DIR 
	#${CMAKE_CURRENT_LIST_DIR}
)

####################################################################################
# Build
##########################################
# Source file containing main()
# Dependencies not including main()
set(Source "C3_main")
set(Dependencies )


# Files directly included with #include
#	set(SunGenerated_Includes <exe1> [exe2] ...)
set(SunGenerated_Includes
	"SimC3/Motion2_1P_G1"
	"expMulti/Exp2021-11-29_Motion2_PL_Exp2P_Sim1P2D"
	"expMulti/Exp2021-11-29_Motion1_PL_Exp2P_Sim2P"
	"expMulti/Exp2021-11-29_Motion1_PL_Exp2P_Sim3P"
)

foreach(SunGenerated_Include ${SunGenerated_Includes})
	# Choose Output filename (REPLACE <match-string> <replace-string> <out-var> <input>)
	string(REPLACE "/" "-" ExeName "${SunGenerated_Include}")

	# Libraries to link against - Directories
	if(NOT WIN32)
		link_directories(${LIBRARIES_DIR})
	endif()

	# Link source files to output file (<exeName> <source1.c> [source2.c|.h] ...)
	add_executable(${ExeName} ${Source}.cpp ${Dependencies})

	# Directories to include
	target_include_directories(${ExeName} PRIVATE
		${INCLUDES_DIR}
		${INCLUDES_LOCAL_DIR}
		"${CDS_SUN_GENERATED_DIR}/${SunGenerated_Include}" # (crane_head.cpp, crane_ode.cpp, crane_x.cpp, ...)
	)

	# Libraries to link against - Libraries
	target_link_libraries(${ExeName} PUBLIC ${LIBRARIES})
endforeach()
