CMAKE_MINIMUM_REQUIRED(VERSION 2.8.9)
#OpenModelica Simulation Interface solver
PROJECT(OMSISolver)
SET(CMAKE_VERBOSE_MAKEFILE ON)

# Find blas and lapack
IF(IS_MINGW32)
  SET(LAPACK_MINGW  $ENV{OMDEV}/tools/msys/mingw32/bin/libopenblas.dll)
  SET(LAPACK_LIBRARIES  ${LAPACK_MINGW})
ELSEIF(IS_MINGW64)
  SET(LAPACK_MINGW  $ENV{OMDEV}/tools/msys/mingw64/bin/libopenblas.dll)
  SET(LAPACK_LIBRARIES  ${LAPACK_MINGW})
ELSE()
  FIND_PACKAGE(BLAS)
  FIND_PACKAGE(LAPACK)
ENDIF()

IF (BLAS_FOUND STREQUAL "NOTFOUND")
  MESSAGE(FATAL_ERROR "Error: Blas Libraries not found!")
ENDIF()
IF (LAPACK_FOUND STREQUAL "NOTFOUND")
  MESSAGE(FATAL_ERROR "Error: Lapack Libraries not found!")
ENDIF()
MESSAGE(STATUS "Lapack Libraries: ${LAPACK_LIBRARIES}")

IF(MSVC)
  #workaround  because cmake does not find the lapack libraries for Visual Studio 10
  SET(LAPACK_MSVC_10  $ENV{OMDEV}/lib/3rdParty/Lapack/Lib/lapack_win32.lib )
  SET(BLAS_MSVC_10 $ENV{OMDEV}/lib/3rdParty/Lapack/Lib/blas_win32.lib )
  SET(LAPACK_LIBRARIES  ${LAPACK_MSVC_10}   ${BLAS_MSVC_10} )
  MESSAGE(STATUS "Using manual set Lapack Libraries: ${LAPACK_LIBRARIES}")
ENDIF(MSVC)

############################
# Find SUNDIALS  libraries #
############################
  #set sundials solvers include and library directories
  IF(MSVC)

    SET(SUNDIALS_INLCUDE_HOME  "${CMAKE_SOURCE_DIR}/../../3rdParty/sundials/build_msvc/include/")
    SET(SUNDIALS_LIBRARY_RELEASE_HOME "${CMAKE_SOURCE_DIR}/../../3rdParty/sundials/build_msvc/lib/")
  ELSE(MSVC)
    SET(SUNDIALS_INLCUDE_HOME  ${CMAKE_INSTALL_PREFIX}/include/omc/c/sundials)
    SET(SUNDIALS_LIBRARY_RELEASE_HOME   ${CMAKE_INSTALL_PREFIX}/${LIBINSTALLEXT}/..)
  ENDIF(MSVC)

  MESSAGE(STATUS "Sundials include:")
  MESSAGE(STATUS "${SUNDIALS_INLCUDE_HOME}")
  MESSAGE(STATUS "Sundials library for omsi/solver:")
  MESSAGE(STATUS "${SUNDIALS_LIBRARY_RELEASE_HOME}")
  MESSAGE(STATUS "${SUNDIALS_ROOT} , ${CMAKE_INSTALL_PREFIX}")

  FIND_PATH(SUNDIALS_INCLUDE_DIR cvode/cvode.h PATHS ${SUNDIALS_INLCUDE_HOME})
  IF (NOT SUNDIALS_INCLUDE_DIR)
    MESSAGE(FATAL_ERROR "Could not find Sundials; compile omc first")
  ELSE(NOT SUNDIALS_INCLUDE_DIR)
    INCLUDE_DIRECTORIES(${SUNDIALS_INCLUDE_DIR})
    # Extract the version number from sundials_config.h
    FIND_PATH(SUNDIALS_CONFIG_FILE "sundials_config.h" ${SUNDIALS_INCLUDE_DIR} "${SUNDIALS_INCLUDE_DIR}/sundials")
    SET(SUNDIALS_CONFIG_FILE "${SUNDIALS_CONFIG_FILE}/sundials_config.h")
    FILE(READ "${SUNDIALS_CONFIG_FILE}" SUNDIALS_CONFIG_FILE_CONTENT)
    STRING(REGEX MATCH "#define SUNDIALS_PACKAGE_VERSION .([0-9]+)\\.([0-9]+)\\.([0-9]+)." SUNDIALS_CONFIG_FILE_CONTENT ${SUNDIALS_CONFIG_FILE_CONTENT})
    STRING(REGEX REPLACE "#define SUNDIALS_PACKAGE_VERSION .([0-9]+)\\.([0-9]+)\\.([0-9]+)." "\\1;\\2;\\3" SUNDIALS_CONFIG_FILE_VERSION ${SUNDIALS_CONFIG_FILE_CONTENT})
    LIST(GET SUNDIALS_CONFIG_FILE_VERSION 0 SUNDIALS_MAJOR_VERSION)
    IF(SUNDIALS_MAJOR_VERSION)
      ADD_DEFINITIONS("-DSUNDIALS_MAJOR_VERSION=${SUNDIALS_MAJOR_VERSION}")
    ELSE()
      MESSAGE(FATAL_ERROR "Could not determine sundials version")
    ENDIF()
    LIST(GET SUNDIALS_CONFIG_FILE_VERSION 1 SUNDIALS_MINOR_VERSION)
    IF(SUNDIALS_MINOR_VERSION)
      ADD_DEFINITIONS("-DSUNDIALS_MINOR_VERSION=${SUNDIALS_MINOR_VERSION}")
    ELSE()
      MESSAGE(FATAL_ERROR "Could not determine sundials version")
    ENDIF()
    LIST(GET SUNDIALS_CONFIG_FILE_VERSION 2 SUNDIALS_PATCH_VERSION)
    MESSAGE(STATUS "Using sundials ${SUNDIALS_MAJOR_VERSION}.${SUNDIALS_MINOR_VERSION}.${SUNDIALS_PATCH_VERSION}")
  ENDIF()

# Set hint for sundials library on unix
  IF(NOT WIN32)
	  SET(Sundials_nvecserial_Path "${CMAKE_INSTALL_PREFIX}/${LIB_OMC}")
  ENDIF()

  FIND_LIBRARY(SUNDIALS_NVECSERIAL_LIB "sundials_nvecserial" HINTS ${Sundials_nvecserial_Path} PATHS ${SUNDIALS_LIBRARY_RELEASE_HOME} $ENV{SUNDIALS_ROOT}/lib)
  IF(NOT SUNDIALS_NVECSERIAL_LIB)
    MESSAGE(FATAL_ERROR "Could not find libsundials_nvecserial!")
  ENDIF()
  GET_FILENAME_COMPONENT(SUNDIALS_LIBS "${SUNDIALS_NVECSERIAL_LIB}" PATH)

  FIND_LIBRARY(SUNDIALS_CVODES_LIB "sundials_cvodes" HINTS ${Sundials_nvecserial_Path} PATHS ${SUNDIALS_LIBRARY_RELEASE_HOME}  $ENV{SUNDIALS_ROOT}/lib)
  IF(NOT SUNDIALS_CVODES_LIB)
    MESSAGE(FATAL_ERROR "Could not find libsundials_cvodes!")
  ENDIF()

  FIND_LIBRARY(SUNDIALS_CVODE_LIB "sundials_cvode" HINTS ${Sundials_nvecserial_Path} PATHS ${SUNDIALS_LIBRARY_RELEASE_HOME}  $ENV{SUNDIALS_ROOT}/lib)
  IF(NOT SUNDIALS_CVODES_LIB)
    MESSAGE(FATAL_ERROR "Could not find libsundials_cvodes!")
  ENDIF()

  FIND_LIBRARY(SUNDIALS_IDA_LIB "sundials_idas" HINTS ${Sundials_nvecserial_Path} PATHS ${SUNDIALS_LIBRARY_RELEASE_HOME}  $ENV{SUNDIALS_ROOT}/lib)
  IF(NOT SUNDIALS_IDA_LIB)
    MESSAGE(FATAL_ERROR "Could not find libsundials_ida!")
  ENDIF()

  FIND_LIBRARY(SUNDIALS_KINSOL_LIB "sundials_kinsol" HINTS ${Sundials_nvecserial_Path} PATHS ${SUNDIALS_LIBRARY_RELEASE_HOME} $ENV{SUNDIALS_ROOT}/lib)
  IF(NOT SUNDIALS_KINSOL_LIB)
    MESSAGE(FATAL_ERROR "Could not find libsundials_kinsol!")
  ENDIF()
  SET(SUNDIALS_LIBRARIES ${SUNDIALS_NVECSERIAL_LIB} ${SUNDIALS_CVODE_LIB} ${SUNDIALS_CVODES_LIB} ${SUNDIALS_IDA_LIB} ${SUNDIALS_KINSOL_LIB} ${SUNDIALS_ARKODE_LIB})

  MESSAGE(STATUS "Sundials Libraries for omsi/solver:")
  MESSAGE(STATUS "${SUNDIALS_LIBRARIES}")
  ADD_DEFINITIONS(-DPMC_USE_SUNDIALS)

####################################
# End of find SUNDIALS  libraries  #
####################################



# OMSISolver includes
include_directories ("${CMAKE_SOURCE_DIR}/solver/include")

add_library(${OMSISolverName}
  src/solver_api.c
  src/solver_helper.c
  src/solver_kinsol.c
  src/solver_lapack.c
)


target_link_libraries(${OMSISolverName} ${CMAKE_DL_LIBS} ${LAPACK_LIBRARIES} ${SUNDIALS_LIBRARIES})

install(TARGETS ${OMSISolverName} DESTINATION ${LIBINSTALLEXT})

install(FILES
  ${CMAKE_SOURCE_DIR}/solver/include/omsi_solver.h
  ${CMAKE_SOURCE_DIR}/solver/include/solver_api.h
  ${CMAKE_SOURCE_DIR}/solver/include/solver_helper.h
DESTINATION include/omc/omsi/solver)
