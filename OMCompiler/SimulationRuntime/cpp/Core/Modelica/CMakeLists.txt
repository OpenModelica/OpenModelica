cmake_minimum_required (VERSION 2.8.9)

project(${ModelicaName})

# this library is only for the precompiled header
add_library( ${ModelicaName}  STATIC Modelica.cpp)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${ModelicaName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")

endif(NOT BUILD_SHARED_LIBS)

target_link_libraries(${ModelicaName} ${Boost_LIBRARIES})

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

set (BOOST_INCLUDE ${Boost_INCLUDE_DIRS})

set (MODELICA_SYSTEM_LIB_EXT ${libModelicaSystemNameExt})

#Fix to enable debugging for gcc
#Problem: The ModelicaConfig.inc file contains something like "optimized;<lib>;debug;<lib>" if the debug or relwithdebinfo -flag is set. The gcc is not able to handle this after the linker-flag (-L).
#Quick Fix: Pick the debug libraries out of the list if the debug or relwithdebinfo -flag is set.
#Maybe someone with more cmake-experience can write a better solution for the issue.
#mwalther

STRING(TOUPPER ${CMAKE_BUILD_TYPE} CMAKE_BUILD_TYPE)

FUNCTION(prepareBoostVar targetVar releaseVar debugVar)
	IF(CMAKE_BUILD_TYPE MATCHES "RELEASE")
		SET(targetVar_ ${releaseVar})
	ELSE()
		SET(targetVar_ ${debugVar})
	ENDIF(CMAKE_BUILD_TYPE MATCHES "RELEASE")
	GET_FILENAME_COMPONENT(${targetVar_} "${${targetVar_}}" NAME_WE)
	STRING(REGEX REPLACE "^lib" "" "${targetVar_}" "${${targetVar_}}")
	SET(${targetVar} ${${targetVar_}} PARENT_SCOPE)
ENDFUNCTION()

prepareBoostVar(Boost_FILESYSTEM_LIBRARY Boost_FILESYSTEM_LIBRARY_RELEASE Boost_FILESYSTEM_LIBRARY_DEBUG)
prepareBoostVar(Boost_SERIALIZATION_LIBRARY Boost_SERIALIZATION_LIBRARY_RELEASE Boost_SERIALIZATION_LIBRARY_DEBUG)
prepareBoostVar(Boost_THREAD_LIBRARY Boost_THREAD_LIBRARY_RELEASE Boost_THREAD_LIBRARY_DEBUG)
prepareBoostVar(Boost_PROGRAM_OPTIONS_LIBRARY Boost_PROGRAM_OPTIONS_LIBRARY_RELEASE Boost_PROGRAM_OPTIONS_LIBRARY_DEBUG)
prepareBoostVar(Boost_LOG_LIBRARY Boost_LOG_LIBRARY_RELEASE Boost_LOG_LIBRARY_DEBUG)

IF(CMAKE_BUILD_TYPE)
	set (Boost_LIBRARIES_NEW "")
	set (SKIP_ENTRY OFF)
	IF((CMAKE_BUILD_TYPE MATCHES "DEBUG") OR (CMAKE_BUILD_TYPE MATCHES "RELWITHDEBINFO"))
		foreach(f ${Boost_LIBRARIES})
			IF(NOT SKIP_ENTRY)
				IF(${f} MATCHES "optimized")
					SET(SKIP_ENTRY ON)
				ELSEIF(${f} MATCHES "debug")

				ELSE(${f} MATCHES "optimized")
					LIST(APPEND Boost_LIBRARIES_NEW ${f})
				ENDIF(${f} MATCHES "optimized")
			ELSE(NOT SKIP_ENTRY)
				IF(${f} MATCHES "debug")
					SET(SKIP_ENTRY OFF)
				ENDIF(${f} MATCHES "debug")
			ENDIF(NOT SKIP_ENTRY)
		endforeach(f ${Boost_LIBRARIES})
	ELSE()
		foreach(f ${Boost_LIBRARIES})
			IF(NOT SKIP_ENTRY)
				IF(${f} MATCHES "debug")
					SET(SKIP_ENTRY ON)
				ELSEIF(${f} MATCHES "optimized")

				ELSE(${f} MATCHES "debug")
					LIST(APPEND Boost_LIBRARIES_NEW ${f})
				ENDIF(${f} MATCHES "debug")
			ELSE(NOT SKIP_ENTRY)
				IF(${f} MATCHES "optimized")
					SET(SKIP_ENTRY OFF)
				ENDIF(${f} MATCHES "optimized")
			ENDIF(NOT SKIP_ENTRY)
		endforeach(f ${Boost_LIBRARIES})
	ENDIF()
	SET(Boost_LIBRARIES_ ${Boost_LIBRARIES_NEW})
ENDIF(CMAKE_BUILD_TYPE)

IF(WIN32)
	SET(Boost_LIBS_ "$(OMHOME)/bin")
	if(NOT DEFINED ENV{MSYSTEM_PREFIX})
		message(FATAL_ERROR "Environment variable \"MSYSTEM_PREFIX\" is not set.")
	endif()
	string(REPLACE "\\" "/" MSYSTEM_PREFIX_ESCAPED "$ENV{MSYSTEM_PREFIX}")
	IF(MSVC)
		SET(Boost_INCLUDE_ "$(OMHOME)/include/omc/omsicpp/3rdParty/boost/msvc/")
	ELSE(MSVC)
		SET(Boost_INCLUDE_ "${MSYSTEM_PREFIX_ESCAPED}/include/")
	ENDIF(MSVC)

	SET(SUNDIALS_LIBS_ "$(OMHOME)/bin")
	SET(SUNDIALS_INCLUDE_DIR_ "$(OMHOME)/include/omc/cpp/sundials")
	SET(LAPACK_LIBS_ "$(OMHOME)/bin")
ELSE(WIN32)
	IF("${Boost_LIBRARY_DIRS}" STREQUAL "")
		SET(Boost_LIBS_ ".")
	ELSE()
		SET(Boost_LIBS_ ${Boost_Library_folder})
	ENDIF()
	IF("${Boost_INCLUDE_DIR}" STREQUAL "" OR
	   "${Boost_INCLUDE_DIR}" STREQUAL "/usr/include")
		# standard /usr/include collides with cross compilation
		SET(Boost_INCLUDE_ ".")
	ELSE()
		SET(Boost_INCLUDE_ ${Boost_INCLUDE_DIR})
	ENDIF()
	IF("${SUNDIALS_LIBS}" STREQUAL "")
		SET(SUNDIALS_LIBS_ ".")
	ELSE()
		SET(SUNDIALS_LIBS_ ${SUNDIALS_LIBS})
	ENDIF()
	IF("${SUNDIALS_INCLUDE_DIR}" STREQUAL "" OR
	   "${SUNDIALS_INCLUDE_DIR}" STREQUAL "/usr/include")
		# standard /usr/include collides with cross compilation
		SET(SUNDIALS_INCLUDE_DIR_ ".")
	ELSE()
		SET(SUNDIALS_INCLUDE_DIR_ ${SUNDIALS_INCLUDE_DIR})
	ENDIF()
	IF("${LAPACK_LIBS}" STREQUAL "")
		SET(LAPACK_LIBS_ ".")
	ELSE()
		SET(LAPACK_LIBS_ ${LAPACK_LIBS})
	ENDIF()
ENDIF(WIN32)

SET(UMFPACK_LIBS_ "${SUITESPARSE_UMFPACK_LIBS}")

IF("${TBB_INCLUDE_DIR}" STREQUAL "")
	SET(TBB_INCLUDE_DIR_ ".")
ELSE()
	SET(TBB_INCLUDE_DIR_ ${TBB_INCLUDE_DIR})
ENDIF()

IF("${PUGIXML_INCLUDE_DIR}" STREQUAL "")
	SET(PUGIXML_INCLUDE_DIR_ ".")
ELSE()
	SET(PUGIXML_INCLUDE_DIR_ ${PUGIXML_INCLUDE_DIR})
ENDIF()

IF("${SUITESPARSE_UMFPACK_INCLUDE_DIR_OMC}" STREQUAL "")
	SET(UMFPACK_INCLUDE_ ".")
ELSE()
	SET(UMFPACK_INCLUDE_ "${SUITESPARSE_UMFPACK_INCLUDE_DIR_OMC}")
ENDIF()

SET(Boost_LIBRARIES_NEW)
FOREACH(lib ${Boost_LIBRARIES_})
  # Convert "Boost:SomeCrazyLib" to "-lboost_SomeCrazyLib" for ModelicaConfig_gcc.inc
  IF (${CMAKE_VERSION} VERSION_GREATER "3.16.0") # support newer cmake >= 3.16
    GET_TARGET_PROPERTY(libNew "${lib}" LOCATION)
    IF ("${libNew}" STREQUAL "libNew-NOTFOUND") # could not find it
      SET(libNew ${lib})
    ENDIF("${libNew}" STREQUAL "libNew-NOTFOUND")
    GET_FILENAME_COMPONENT(libNew "${libNew}" NAME_WE)
  ELSE(${CMAKE_VERSION} VERSION_GREATER "3.16.0") # support older cmake <= 3.16
  GET_FILENAME_COMPONENT(libNew "${lib}" NAME_WE)
  ENDIF(${CMAKE_VERSION} VERSION_GREATER "3.16.0")
  STRING(REGEX REPLACE "^lib" "" libNew ${libNew})
  SET(Boost_LIBRARIES_NEW "${Boost_LIBRARIES_NEW} ${LINKER_LIB_PREFIX}${libNew}")
ENDFOREACH()
SET(Boost_LIBRARIES_ ${Boost_LIBRARIES_NEW})

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
FOREACH(lib ${TBB_LIBRARIES})
	GET_FILENAME_COMPONENT(libNew "${lib}" NAME_WE)
	STRING(REGEX REPLACE "^lib" "" libNew ${libNew})
	set(INTEL_TBB_LIBS "${INTEL_TBB_LIBS} ${LINKER_LIB_PREFIX}${libNew}")
ENDFOREACH(lib ${TBB_LIBRARIES})

SET(UMFPACK_LIBS "")
FOREACH(lib ${SUITESPARSE_UMFPACK_LIBRARIES_OMC})
	GET_FILENAME_COMPONENT(libNew "${lib}" NAME_WE)
	STRING(REGEX REPLACE "^lib" "" libNew ${libNew})
	SET(UMFPACK_LIBRARIES_ "${UMFPACK_LIBRARIES_} ${LINKER_LIB_PREFIX}${libNew}")
ENDFOREACH(lib ${SUITESPARSE_UMFPACK_LIBRARIES_OMC})
#end Fix

MESSAGE(STATUS " ")
MESSAGE(STATUS "Values for *.inc files:")
MESSAGE(STATUS "--BOOST_LIBS = ${Boost_LIBS_} " - " ${Boost_Library_folder}")
MESSAGE(STATUS "--BOOST_INCLUDE = ${Boost_INCLUDE_}")
MESSAGE(STATUS "--BOOST_LIBRARIES = ${Boost_LIBRARIES_}")
MESSAGE(STATUS "--SUNDIALS_LIBS = ${SUNDIALS_LIBS_}")
MESSAGE(STATUS "--SUNDIALS_INCLUDE = ${SUNDIALS_INCLUDE_DIR_}")
MESSAGE(STATUS "--SUNDIALS_LIBRARIES = ${SUNDIALS_LIBRARIES_}")
MESSAGE(STATUS "--LAPACK_LIBS = ${LAPACK_LIBS_}")
MESSAGE(STATUS "--LAPACK_LIBRARIES = ${LAPACK_LIBRARIES_}")
MESSAGE(STATUS "--UMFPACK_LIBS = ${SUITESPARSE_UMFPACK_LIBS}")
MESSAGE(STATUS "--UMFPACK_INCLUDE = ${UMFPACK_INCLUDE_}")
MESSAGE(STATUS "--UMFPACK_LIBRARIES = ${UMFPACK_LIBRARIES_}")
MESSAGE(STATUS "--CPPTHREADS_LIBRARY = ${CPPTHREADS_LIBRARY} ${CPPTHREADS_LIBRARY_FLAG}")

MESSAGE(STATUS " ")

if(BUILD_SHARED_LIBS)
  # tweak SYSTEM_CFLAGS for precompiled headers
  create_precompiled_header(${ModelicaName} Core/Modelica.h)
else(BUILD_SHARED_LIBS)
  # set SYSTEM_CFLAGS from cmake variables
  STRING(TOUPPER "CMAKE_CXX_FLAGS_${CMAKE_BUILD_TYPE}" _flags_var_name)
  SET(_compiler_flags ${${_flags_var_name}})
  IF(${CMAKE_SYSTEM_NAME} MATCHES "Linux")
    set(_compiler_flags "${_compiler_flags} -fPIC ")
  ENDIF(${CMAKE_SYSTEM_NAME} MATCHES "Linux")
  GET_DIRECTORY_PROPERTY(_directory_flags DEFINITIONS)
  SET(SYSTEM_CFLAGS "${_compiler_flags} ${_directory_flags}")
endif(BUILD_SHARED_LIBS)

IF(MSVC)
 GET_TARGET_PROPERTY(libModelica ${ModelicaName} LOCATION)
 GET_FILENAME_COMPONENT(libModelicaName ${libModelica} NAME)
 set(PCH_LIB ${libModelicaName})
 configure_file (
  "ModelicaConfig_msvc.inc.in"
  "${PROJECT_BINARY_DIR}/ModelicaConfig_msvc.inc"
  )
  install (FILES
				${PROJECT_BINARY_DIR}/ModelicaConfig_msvc.inc
				DESTINATION include/omc/cpp)

  configure_file (
   "ModelicaLibraryConfig_msvc.inc.in"
   "${PROJECT_BINARY_DIR}/ModelicaLibraryConfig_msvc.inc"
   )
  install (FILES
  				${PROJECT_BINARY_DIR}/ModelicaLibraryConfig_msvc.inc
  				DESTINATION include/omc/cpp)
ENDIF(MSVC)

IF("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU" OR "${CMAKE_CXX_COMPILER_ID}" STREQUAL "Intel" OR "${CMAKE_CXX_COMPILER_ID}" MATCHES "Clang")
configure_file (
  "ModelicaConfig_gcc.inc.in"
  "${PROJECT_BINARY_DIR}/ModelicaConfig_gcc.inc"
  )
install (FILES
				${PROJECT_BINARY_DIR}/ModelicaConfig_gcc.inc
				DESTINATION include/omc/cpp)

  configure_file (
   "ModelicaLibraryConfig_gcc.inc.in"
   "${PROJECT_BINARY_DIR}/ModelicaLibraryConfig_gcc.inc"
   )
  install (FILES
  				${PROJECT_BINARY_DIR}/ModelicaLibraryConfig_gcc.inc
  				DESTINATION include/omc/cpp)
ENDIF("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU" OR "${CMAKE_CXX_COMPILER_ID}" STREQUAL "Intel" OR "${CMAKE_CXX_COMPILER_ID}" MATCHES "Clang")



install(TARGETS ${ModelicaName} DESTINATION ${LIBINSTALLEXT})
install (FILES  ${CMAKE_SOURCE_DIR}/Core/Modelica.h ${CMAKE_SOURCE_DIR}/Core/ModelicaDefine.h DESTINATION include/omc/cpp/Core)
install (FILES  ${CMAKE_SOURCE_DIR}/Core/DataExchange/Policies/TextfileWriter.h DESTINATION include/omc/cpp/Core/DataExchange/Policies)
install (FILES  ${CMAKE_SOURCE_DIR}/Core/DataExchange/Policies/MatfileWriter.h DESTINATION include/omc/cpp/Core/DataExchange/Policies)
install (FILES  ${CMAKE_SOURCE_DIR}/Core/DataExchange/Policies/BufferReaderWriter.h DESTINATION include/omc/cpp/Core/DataExchange/Policies)
#if(REDUCE_DAE)
#install (FILES Policies/BufferReaderWriter.h DESTINATION include/omc/cpp/policies)
#endif()



