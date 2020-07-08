# Macro for setting up precompiled headers. Usage:
#
# create_precompiled_header(target header.h [FORCEINCLUDE])
#
# MSVC: A source file with the same name as the header must exist and
# be included in the target (E.g. header.cpp).
#
# MSVC: Add FORCEINCLUDE to automatically include the precompiled
# header file from every source file.
#
# GCC: The precompiled header is always automatically included from
# every header file.
#
# Copyright (C) 2009-2013 Lars Christensen <larsch@belunktum.dk>
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation files
# (the ‘Software’), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED ‘AS IS’, WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# niklwors: adapted for OpenModelica cpp runtime build 5/2014

MACRO(CREATE_PRECOMPILED_HEADER _targetName _input )
MESSAGE(STATUS "Compiler for precompiled header: ${CMAKE_CXX_COMPILER_ID}")

GET_FILENAME_COMPONENT(_inputWe ${_input} NAME_WE)
SET(pch_source ${_inputWe}.cpp)

FOREACH(arg ${ARGN})
	IF(arg STREQUAL FORCEINCLUDE)
		SET(FORCEINCLUDE ON)
	ELSE(arg STREQUAL FORCEINCLUDE)
		SET(FORCEINCLUDE OFF)
	ENDIF(arg STREQUAL FORCEINCLUDE)
ENDFOREACH(arg)

IF(MSVC)
	MESSAGE(STATUS "create pch for msvc with compile flags: ${CMAKE_CXX_FLAGS}" )
	GET_FILENAME_COMPONENT(_name ${_input} NAME)
	GET_TARGET_PROPERTY(sources ${_targetName} SOURCES)
	SET(_sourceFound FALSE)
	#set extra compiler flags
	STRING (REPLACE "/Zm1000" " " CMAKE_CXX_FLAGS ${CMAKE_CXX_FLAGS})
	STRING(TOUPPER "CMAKE_CXX_FLAGS_${CMAKE_BUILD_TYPE}" _flags_var_name)
	SET(_compiler_FLAGS ${${_flags_var_name}})
	SET(_compiler_FLAGS "/EHa /fp:except   /W4  /MP ${_compiler_FLAGS}")
	#disable optimization
	STRING(REGEX REPLACE "/O[1-9]*[b,d,g,i,s,t,x]*[1-9]* " "" _compiler_FLAGS ${_compiler_FLAGS} )
	SET(_compiler_FLAGS "/Od ${_compiler_FLAGS}")
	SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${_compiler_FLAGS}")
	#only generate precompiled header in relase mode in debug mode precompiled header can not generated because of different pdb files
	IF(CMAKE_BUILD_TYPE MATCHES RELEASE)
		SET(PrecompiledBinary "${CMAKE_BINARY_DIR}/Core/Modelica.pch")
		FOREACH(_source ${sources})
			SET(PCH_COMPILE_FLAGS "")
			IF(_source MATCHES \\.\(cc|cxx|cpp\)$)
				GET_FILENAME_COMPONENT(_sourceWe ${_source} NAME_WE)
				IF(_sourceWe STREQUAL ${_inputWe})
					#SET(PCH_COMPILE_FLAGS "${PCH_COMPILE_FLAGS} /Yc ")
					SET(PCH_COMPILE_FLAGS "${PCH_COMPILE_FLAGS}  /Fp\"${PrecompiledBinary}\" /Yc")
					SET(_sourceFound TRUE)
					MESSAGE(STATUS "create pch: ${PCH_COMPILE_FLAGS}" )
				ELSE(_sourceWe STREQUAL ${_inputWe})
					SET(PCH_COMPILE_FLAGS "${PCH_COMPILE_FLAGS}  /Fp\"${PrecompiledBinary}\"  /YuCore/${_name}")
					MESSAGE(STATUS "use pch: /FPCore/${_inputWe}.pch  /Yu${_name}" )
					IF(FORCEINCLUDE)
						SET(PCH_COMPILE_FLAGS "${PCH_COMPILE_FLAGS} /FI${_name}")
					ENDIF(FORCEINCLUDE)
				ENDIF(_sourceWe STREQUAL ${_inputWe})
				SET_SOURCE_FILES_PROPERTIES(${_source} PROPERTIES COMPILE_FLAGS "${PCH_COMPILE_FLAGS} ${CMAKE_CXX_FLAGS}")
                MESSAGE(STATUS "set source file properties for: ${_source} ${PCH_COMPILE_FLAGS} ${CMAKE_CXX_FLAGS}" )
			ENDIF(_source MATCHES \\.\(cc|cxx|cpp\)$)
		ENDFOREACH()
		IF(NOT _sourceFound)
			MESSAGE(FATAL_ERROR "A source file for ${_inputWe} was not found. Required for MSVC builds.")
		ENDIF(NOT _sourceFound)
		#copy pre compiled header file in installation directory
		MESSAGE(STATUS "install pch: ${CMAKE_BINARY_DIR}/${_inputWe}.pch" )
		INSTALL (FILES "${CMAKE_BINARY_DIR}/Core/${_inputWe}.pch" DESTINATION include/omc/cpp/Core)
		SET(PCH_FILE "${_inputWe}.pch")
		SET(H_FILE "${_name}")
	ENDIF(CMAKE_BUILD_TYPE MATCHES RELEASE)
	GET_DIRECTORY_PROPERTY(_directory_flags DEFINITIONS)
	#LIST(APPEND _compiler_FLAGS ${_directory_flags})
	SET(_compiler_FLAGS "${CMAKE_CXX_FLAGS} ${_directory_flags}")
	SET(SYSTEM_CFLAGS ${_compiler_FLAGS})
	MESSAGE(STATUS "SYSTEM_CFLAGS: ${CMAKE_CXX_FLAGS}" )
ENDIF(MSVC)

IF("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU"  OR "${CMAKE_CXX_COMPILER_ID}" STREQUAL "Intel")
	GET_FILENAME_COMPONENT(_name ${_input} NAME)
	SET(_source "${CMAKE_SOURCE_DIR}/${_input}")
	SET(_outdir "${CMAKE_BINARY_DIR}/Core/${_name}.gch")
	MAKE_DIRECTORY(${_outdir})
	#SET(_output "${_outdir}/.c++")
	#changed output so that gcc automaticly finds pre compiled header for Modelica system
	SET(_output "${_outdir}/${_name}.gch")
	STRING(TOUPPER "CMAKE_CXX_FLAGS_${CMAKE_BUILD_TYPE}" _flags_var_name)
	SET(_compiler_FLAGS ${${_flags_var_name}})
	#remove compiler flag for optimization becaus Modelica system is compiled without optimization
	STRING(REGEX REPLACE "O[1-9]" "O0" _compiler_FLAGS "${_compiler_FLAGS}" )
	#STRING(REGEX REPLACE "-g" "" _compiler_FLAGS ${_compiler_FLAGS} )
	IF(${CMAKE_SYSTEM_NAME} MATCHES "Linux")
		SET(_compiler_FLAGS "${_compiler_FLAGS} -fPIC ")
	ENDIF(${CMAKE_SYSTEM_NAME} MATCHES "Linux")
	IF(${COMPILER_SUPPORTS_CXX11})
		SET(_compiler_FLAGS "${_compiler_FLAGS} ${CXX11_FLAGS}")
	ENDIF(${COMPILER_SUPPORTS_CXX11})
	IF(NOT BOOST_STATIC_LINKING)
		SET(_compiler_FLAGS "${_compiler_FLAGS} -DBOOST_ALL_DYN_LINK ")
	ENDIF(NOT BOOST_STATIC_LINKING)
	#SYSTEM_FLAGS variable for configuration file to set used compiler flags
	GET_DIRECTORY_PROPERTY(_directory_flags DEFINITIONS)
	#LIST(APPEND _compiler_FLAGS ${_directory_flags})
	SET(_compiler_FLAGS "${_compiler_FLAGS} ${_directory_flags}")
	SET(SYSTEM_CFLAGS ${_compiler_FLAGS})
	GET_DIRECTORY_PROPERTY(_directory_flags INCLUDE_DIRECTORIES)

	FOREACH(item ${_directory_flags})
		LIST(APPEND _compiler_FLAGS "-I${item}")
	ENDFOREACH(item)

	SEPARATE_ARGUMENTS(_compiler_FLAGS)
	MESSAGE(STATUS "${CMAKE_CXX_COMPILER} -DPCHCOMPILE ${_compiler_FLAGS} -x c++-header -o ${_output} ${_source}")
	STRING(REPLACE "(" "\\(" _compiler_FLAGS_STR "${_compiler_FLAGS}")
	STRING(REPLACE ")" "\\)" _compiler_FLAGS_STR "${_compiler_FLAGS_STR}")
	MESSAGE(STATUS "${CMAKE_CXX_COMPILER} -DPCHCOMPILE ${_compiler_FLAGS_STR} -x c++-header -o ${_output} ${_source}")

	IF(USE_SCOREP)
		ADD_CUSTOM_COMMAND(
			OUTPUT ${_output}
			COMMAND g++ ${_compiler_FLAGS_STR} -x c++-header -o ${_output} ${_source}
			DEPENDS ${_source} )
	ELSE(USE_SCOREP)
		ADD_CUSTOM_COMMAND(
			OUTPUT ${_output}
			COMMAND ${CMAKE_CXX_COMPILER} ${_compiler_FLAGS_STR} -x c++-header -o ${_output} ${_source}
			DEPENDS ${_source} )
	ENDIF(USE_SCOREP)
	ADD_CUSTOM_TARGET(${_targetName}_gch DEPENDS ${_output})
	ADD_DEPENDENCIES(${_targetName} ${_targetName}_gch)
	SET_TARGET_PROPERTIES(${_targetName} PROPERTIES COMPILE_FLAGS "-include Core/${_name} -Winvalid-pch")
	#copy pre compiled header file in installation directory
	INSTALL(FILES "${_output}" DESTINATION include/omc/cpp/Core)
	SET(PCH_FILE "${_name}.gch")
	SET(H_FILE "${_name}")
ENDIF("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU"  OR "${CMAKE_CXX_COMPILER_ID}" STREQUAL "Intel")


IF("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
	GET_FILENAME_COMPONENT(_name ${_input} NAME)

	SET(_source "${CMAKE_SOURCE_DIR}/${_input}")
	SET(_outdir "${CMAKE_BINARY_DIR}/${_name}.gch")
	MAKE_DIRECTORY(${_outdir})
	#SET(_output "${_outdir}/.c++")
	#changed output so that gcc automaticly finds pre compiled header for Modelica system
	SET(_output "${_outdir}/${_name}.pch")
	STRING(TOUPPER "CMAKE_CXX_FLAGS_${CMAKE_BUILD_TYPE}" _flags_var_name)
	SET(_compiler_FLAGS ${${_flags_var_name}})
	#remove compiler flag for optimization becaus Modelica system is compiled without optimization
	STRING(REGEX REPLACE "O[1-9]" "O0" _compiler_FLAGS ${_compiler_FLAGS} )
	#string(REGEX REPLACE "-g" "" _compiler_FLAGS ${_compiler_FLAGS} )

	IF(${CMAKE_SYSTEM_NAME} MATCHES "Linux")
		set(_compiler_FLAGS "${_compiler_FLAGS} -fPIC ")
	ENDIF(${CMAKE_SYSTEM_NAME} MATCHES "Linux")
	IF(${COMPILER_SUPPORTS_CXX11})
		SET(_compiler_FLAGS "${_compiler_FLAGS} ${CXX11_FLAGS}")
	ENDIF(${COMPILER_SUPPORTS_CXX11})

	IF(NOT BOOST_STATIC_LINKING)
		SET(_compiler_FLAGS "${_compiler_FLAGS} -DBOOST_ALL_DYN_LINK ")
	ENDIF(NOT BOOST_STATIC_LINKING)
	#SYSTEM_FLAGS variable for configuration file to set used compiler flags
	GET_DIRECTORY_PROPERTY(_directory_flags DEFINITIONS)
	#LIST(APPEND _compiler_FLAGS ${_directory_flags})
	SET(_compiler_FLAGS "${_compiler_FLAGS} ${_directory_flags}")
	SET(SYSTEM_CFLAGS ${_compiler_FLAGS})
	GET_DIRECTORY_PROPERTY(_directory_flags INCLUDE_DIRECTORIES)

	FOREACH(item ${_directory_flags})
		LIST(APPEND _compiler_FLAGS "-I${item}")
	ENDFOREACH(item)

	#SEPARATE_ARGUMENTS(_compiler_FLAGS)
	#MESSAGE(STATUS "${CMAKE_CXX_COMPILER} -DPCHCOMPILE ${_compiler_FLAGS} -emit-pch -o ${_output} ${_source}")

	#ADD_CUSTOM_COMMAND(
	#OUTPUT ${_output}
	#COMMAND ${CMAKE_CXX_COMPILER} ${_compiler_FLAGS} -emit-pch -o ${_output} ${_source}
	#DEPENDS ${_source} )
	#ADD_CUSTOM_TARGET(${_targetName}_gch DEPENDS ${_output})
	#ADD_DEPENDENCIES(${_targetName} ${_targetName}_gch)
	#SET_TARGET_PROPERTIES(${_targetName} PROPERTIES COMPILE_FLAGS "-include ${_name} -Winvalid-pch")

	#copy pre compiled header file in installation directory
	#INSTALL (FILES "${_output}" DESTINATION include/omc/cpp/Core)
	#SET(PCH_FILE "${_name}")
ENDIF("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")

ENDMACRO()


MACRO(ADD_PRECOMPILED_HEADER _targetName _input )


GET_FILENAME_COMPONENT(_inputWe ${_input} NAME_WE)
SET(pch_source ${_inputWe}.cpp)

FOREACH(arg ${ARGN})
	IF(arg STREQUAL FORCEINCLUDE)
		SET(FORCEINCLUDE ON)
	ELSE(arg STREQUAL FORCEINCLUDE)
		SET(FORCEINCLUDE OFF)
	ENDIF(arg STREQUAL FORCEINCLUDE)
ENDFOREACH(arg)

IF(MSVC)
	GET_FILENAME_COMPONENT(_name ${_input} NAME)
	GET_TARGET_PROPERTY(sources ${_targetName} SOURCES)
	SET(_sourceFound FALSE)
	MESSAGE(STATUS "add precompiled header to ${_targetName} for ${sources} " )

	#only use precompiled header in relase mode in debug mode precompiled header can not generated because of different pdb files
	IF(CMAKE_BUILD_TYPE MATCHES "Release" AND PLATFORM MATCHES "dynamic")
		MESSAGE(STATUS "use precompiled header for build tpye ${CMAKE_BUILD_TYPE}" )
        SET(PrecompiledBinary "${CMAKE_BINARY_DIR}/Core/Modelica.pch")
		FOREACH(_source ${sources})
			MESSAGE(STATUS "set source file properties for: ${_source}" )
            SET(PCH_COMPILE_FLAGS "")
			IF(_source MATCHES \\.\(cc|cxx|cpp\)$)
				GET_FILENAME_COMPONENT(_sourceWe ${_source} NAME_WE)
				    SET(PCH_COMPILE_FLAGS "${PCH_COMPILE_FLAGS}  /Fp\"${PrecompiledBinary}\"  /YuCore/${_name}")
					IF(FORCEINCLUDE)
						SET(PCH_COMPILE_FLAGS "${PCH_COMPILE_FLAGS} /FI${_name}")
					ENDIF(FORCEINCLUDE)
				SET_SOURCE_FILES_PROPERTIES(${_source} PROPERTIES COMPILE_FLAGS "${PCH_COMPILE_FLAGS} ${CMAKE_CXX_FLAGS}")
                MESSAGE(STATUS "using cflags: ${_source} ${PCH_COMPILE_FLAGS} " )
			ENDIF(_source MATCHES \\.\(cc|cxx|cpp\)$)
		ENDFOREACH()

    ENDIF(CMAKE_BUILD_TYPE MATCHES "Release" AND PLATFORM MATCHES "dynamic")

ENDIF(MSVC)

ENDMACRO()


