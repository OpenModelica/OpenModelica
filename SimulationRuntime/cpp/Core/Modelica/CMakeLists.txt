cmake_minimum_required (VERSION 2.6)

project(${ModelicaName})

IF(RUNTIME_STATIC_LINKING)
	add_library(${ModelicaName} STATIC Modelica.cpp ModelicaSystem.cpp  )
	include_directories(${SUNDIALS_INCLUDE_DIR}/cvodes ${SUNDIALS_INCLUDE_DIR}/nvector  ${SUNDIALS_INCLUDE_DIR}/sundials ${SUNDIALS_INCLUDE_DIR})
ELSE(RUNTIME_STATIC_LINKING)
	add_library(${ModelicaName} SHARED Modelica.cpp ModelicaSystem.cpp   )
ENDIF(RUNTIME_STATIC_LINKING)

target_link_libraries (${ModelicaName} ${ModelicaExternalCName}  ${SystemName} ${BaseName}  )


GET_TARGET_PROPERTY(libModelicaSystem ${ModelicaName} LOCATION)
GET_FILENAME_COMPONENT(libModelicaSystemNameExt ${libModelicaSystem} EXT)

IF(MSVC)
	SET(LINKER_LIB_PREFIX "")
ELSE(MSVC)
	SET(LINKER_LIB_PREFIX "-l")
ENDIF(MSVC)

if(${CMAKE_SYSTEM_NAME} MATCHES "Linux")
  include(CheckTypeSize)
  check_type_size("void*" SIZEOF_VOID_P BUILTIN_TYPES_ONLY)
  set(LINUX_LIB_DL "-ldl")
  set(FPIC "-fPIC")
  if(${SIZEOF_VOID_P} MATCHES 8)
    set(FMI_ARCH_DIR "linux64")
  else(${SIZEOF_VOID_P} MATCHES 8)
    set(FMI_ARCH_DIR "linux32")
  endif(${SIZEOF_VOID_P} MATCHES 8)
endif(${CMAKE_SYSTEM_NAME} MATCHES "Linux")

if(${CMAKE_SYSTEM_NAME} MATCHES "Windows")
  set(LINUX_LIB_DL "")
  set(FMI_ARCH_DIR "win32")
endif(${CMAKE_SYSTEM_NAME} MATCHES "Windows")

#GET_TARGET_PROPERTY(libboostSystem ${Boost_SYSTEM_LIBRARY} LOCATION)
#GET_FILENAME_COMPONENT(libboostSystemNAME ${libboostSystem} NAME)
#set(Boost_SYSTEM_LIBRARY_NAME ${libboostSystemNAME})

set (BOOST_INCLUDE ${Boost_INCLUDE_DIRS})
set (BOOST_LIBS ${Boost_LIBRARY_DIRS})
set (MODELICA_SYSTEM_LIB_EXT ${libModelicaSystemNameExt})

#Fix to enable debugging for gcc
#Problem: The ModelicaConfig.inc file contains something like "optimized;<lib>;debug;<lib>" if the debug or relwithdebinfo -flag is set. The gcc is not able to handle this after the linker-flag (-L).
#Quick Fix: Pick the debug libraries out of the list if the debug or relwithdebinfo -flag is set.
#Maybe someone with more cmake-experience can write a better solution for the issue.
#mwalther

list(GET Boost_SERIALIZATION_LIBRARY -1 Boost_SERIALIZATION_LIBRARY)
string(STRIP Boost_SERIALIZATION_LIBRARY ${Boost_SERIALIZATION_LIBRARY})
list(GET Boost_FILESYSTEM_LIBRARY -1 Boost_FILESYSTEM_LIBRARY)
string(STRIP Boost_FILESYSTEM_LIBRARY ${Boost_FILESYSTEM_LIBRARY})
list(GET Boost_SERIALIZATION_LIB -1 Boost_SERIALIZATION_LIB)
string(STRIP Boost_SERIALIZATION_LIB ${Boost_SERIALIZATION_LIB})
list(GET Boost_SYSTEM_LIBRARY -1 Boost_SYSTEM_LIBRARY)
string(STRIP Boost_SYSTEM_LIBRARY ${Boost_SYSTEM_LIBRARY})

IF(Boost_THREAD_LIBRARY)
list(GET Boost_THREAD_LIBRARY -1 Boost_THREAD_LIBRARY)
string(STRIP Boost_THREAD_LIBRARY ${Boost_THREAD_LIBRARY})
ENDIF(Boost_THREAD_LIBRARY)

list(GET Boost_PROGRAM_OPTIONS_LIBRARY -1 Boost_PROGRAM_OPTIONS_LIBRARY)
string(STRIP Boost_PROGRAM_OPTIONS_LIBRARY ${Boost_PROGRAM_OPTIONS_LIBRARY})

IF(Boost_LOG_LIBRARY)
list(GET Boost_LOG_LIBRARY -1 Boost_LOG_LIBRARY)
string(STRIP Boost_LOG_LIBRARY ${Boost_LOG_LIBRARY})
ENDIF(Boost_LOG_LIBRARY)

IF(CMAKE_BUILD_TYPE)
	string(TOUPPER ${CMAKE_BUILD_TYPE} CMAKE_BUILD_TYPE)
	set (Boost_LIBRARIES_NEW "")
	set (SKIP_ENTRY FALSE)

	IF((CMAKE_BUILD_TYPE MATCHES DEBUG) OR (CMAKE_BUILD_TYPE MATCHES RELWITHDEBINFO))
		foreach(f ${Boost_LIBRARIES})
			IF(SKIP_ENTRY MATCHES FALSE)
				IF(${f} MATCHES "optimized")
					SET(${SKIP_ENTRY} TRUE)
				ELSEIF(${f} MATCHES "debug")
				
				ELSE(${f} MATCHES "optimized")
					LIST(APPEND Boost_LIBRARIES_NEW ${f})
				ENDIF(${f} MATCHES "optimized")
			ELSE(SKIP_ENTRY MATCHES FALSE)
				SET(${SKIP_ENTRY} FALSE)
			ENDIF(SKIP_ENTRY MATCHES FALSE)
		endforeach(f ${Boost_LIBRARIES})
	ELSE()
		foreach(f ${Boost_LIBRARIES})
			IF(SKIP_ENTRY MATCHES FALSE)
				IF(${f} MATCHES "debug")
					SET(${SKIP_ENTRY} TRUE)
				ELSEIF(${f} MATCHES "optimized")
				
				ELSE(${f} MATCHES "optimized")
					LIST(APPEND Boost_LIBRARIES_NEW ${f})
				ENDIF(${f} MATCHES "debug")
			ELSE(SKIP_ENTRY MATCHES FALSE)
				SET(${SKIP_ENTRY} FALSE)
			ENDIF(SKIP_ENTRY MATCHES FALSE)
		endforeach(f ${Boost_LIBRARIES})
	ENDIF()

	SET(Boost_LIBRARIES ${Boost_LIBRARIES_NEW})
ENDIF(CMAKE_BUILD_TYPE)

IF(WIN32)
	SET(Boost_LIBS_ "$(OMHOME)/bin")
	SET(Boost_INCLUDE_ "$(OMHOME)/include/omc/cpp")
	SET(SUNDIALS_LIBS_ "$(OMHOME)/bin")
	SET(SUNDIALS_INCLUDE_DIR_ "$(OMHOME)/include/omc/cpp")
	SET(LAPACK_LIBS_ "$(OMHOME)/bin")
ELSE(WIN32)
	SET(Boost_LIBS_ ${Boost_LIBS})
	SET(Boost_INCLUDE_ ${Boost_INCLUDE_DIR})
	SET(SUNDIALS_LIBS_ ${SUNDIALS_LIBS})
	SET(SUNDIALS_INCLUDE_DIR_ ${SUNDIALS_INCLUDE_DIR})
	SET(LAPACK_LIBS_ ${LAPACK_LIBS})
ENDIF(WIN32)

SET(Boost_LIBRARIES_NEW)
FOREACH(lib ${Boost_LIBRARIES})
  GET_FILENAME_COMPONENT(libNew "${lib}" NAME_WE)
  STRING(REGEX REPLACE "^lib" "" libNew ${libNew})
  SET(Boost_LIBRARIES_NEW "${Boost_LIBRARIES_NEW} ${LINKER_LIB_PREFIX}${libNew}")
ENDFOREACH()
SET(Boost_LIBRARIES ${Boost_LIBRARIES_NEW})

SET(SUNDIALS_LIBARIES_ "")
FOREACH(lib ${SUNDIALS_LIBRARIES})
	GET_FILENAME_COMPONENT(libNew "${lib}" NAME_WE)
	STRING(REGEX REPLACE "^lib" "" libNew ${libNew})
	SET(SUNDIALS_LIBRARIES_ "${SUNDIALS_LIBRARIES_} ${LINKER_LIB_PREFIX}${libNew}")
ENDFOREACH(lib ${SUNDIALS_LIBRARIES})

SET(LAPACK_LIBRARIES_ "")
FOREACH(lib ${LAPACK_LIBRARIES})
	GET_FILENAME_COMPONENT(libNew "${lib}" NAME_WE)
	STRING(REGEX REPLACE "^lib" "" libNew ${libNew})
	SET(LAPACK_LIBRARIES_ "${LAPACK_LIBRARIES_} ${LINKER_LIB_PREFIX}${libNew}")
ENDFOREACH(lib ${LAPACK_LIBRARIES})

SET(INTEL_TBB_LIBS "")
foreach(lib ${TBB_LIBRARIES})
	set(INTEL_TBB_LIBS "${INTEL_TBB_LIBS} ${lib}")
endforeach(lib ${TBB_LIBRARIES})

SET(UMFPACK_LIBS "")
foreach(lib ${SUITESPARSE_UMFPACK_LIBRARIES_OMC})
	set(UMFPACK_LIBS "${UMFPACK_LIBS} ${lib}")
endforeach(lib ${SUITESPARSE_UMFPACK_LIBRARIES_OMC})
#end Fix

add_precompiled_header(${ModelicaName} Include/Core/Modelica.h )

 configure_file (
  "ModelicaConfig.inc.in"
  "${PROJECT_BINARY_DIR}/ModelicaConfig.inc"
  )

configure_file (
 "ModelicaLibraryConfig.inc.in"
 "${PROJECT_BINARY_DIR}/ModelicaLibraryConfig.inc"
 )
 
install (FILES
				${PROJECT_BINARY_DIR}/ModelicaConfig.inc
				${PROJECT_BINARY_DIR}/ModelicaLibraryConfig.inc
				DESTINATION include/omc/cpp)


install (FILES  ${CMAKE_SOURCE_DIR}/Include/Core/HistoryImpl.h  ${CMAKE_SOURCE_DIR}/Include/Core/Modelica.h ${CMAKE_SOURCE_DIR}/Include/Core/ModelicaDefine.h DESTINATION include/omc/cpp/Core)
install (FILES  ${CMAKE_SOURCE_DIR}/Include/Core/DataExchange/Policies/TextfileWriter.h DESTINATION include/omc/cpp/Core/DataExchange/Policies)
install (FILES  ${CMAKE_SOURCE_DIR}/Include/Core/DataExchange/Policies/MatfileWriter.h DESTINATION include/omc/cpp/Core/DataExchange/Policies)
install (FILES  ${CMAKE_SOURCE_DIR}/Include/Core/DataExchange/Policies/BufferReaderWriter.h DESTINATION include/omc/cpp/Core/DataExchange/Policies)
#if(REDUCE_DAE)
#install (FILES Policies/BufferReaderWriter.h DESTINATION include/omc/cpp/policies)
#endif()



