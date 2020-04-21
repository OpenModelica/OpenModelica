
CMAKE_MINIMUM_REQUIRED(VERSION 2.8.9)
#OpenModelica Simulation Interface solver
PROJECT(OMSISolver)
SET(CMAKE_VERBOSE_MAKEFILE ON)

# Global Variables
IF(NOT OMCTRUNCHOME)
  SET(OMCTRUNCHOME ${CMAKE_CURRENT_SOURCE_DIR}/../../../..)
ENDIF (NOT OMCTRUNCHOME)

############################
# Find BLAS and LAPACK
############################
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
MESSAGE(STATUS "Lapack Libraries: ${LAPACK_LIBRARIES} ${BLAS_LIBRARIES}")

IF(MSVC)
  #workaround  because cmake does not find the lapack libraries for Visual Studio 10
  SET(LAPACK_MSVC_10  $ENV{OMDEV}/lib/3rdParty/Lapack/Lib/lapack_win32.lib )
  SET(BLAS_MSVC_10 $ENV{OMDEV}/lib/3rdParty/Lapack/Lib/blas_win32.lib )
  SET(LAPACK_LIBRARIES  ${LAPACK_MSVC_10}  )
  SET(BLAS_LIBRARIES    ${BLAS_MSVC_10} )
  MESSAGE(STATUS "Using manual set Lapack Libraries: ${LAPACK_LIBRARIES}")
ENDIF(MSVC)


############################
# Find SUNDIALS  libraries #
############################
IF(MSVC)
  SET(SUNDIALS_PATH "${OMCTRUNCHOME}/OMCompiler/3rdParty/sundials/build_msvc")
ELSE(MSVC)
  SET(SUNDIALS_PATH "${OMCTRUNCHOME}/OMCompiler/3rdParty/sundials/build")
ENDIF(MSVC)

MESSAGE(STATUS "Sundials path:")
MESSAGE(STATUS "${SUNDIALS_PATH}")

# SUNDIALS Header
FIND_PATH(SUNDIALS_INCLUDE_DIR "sundials/sundials_config.h" ${SUNDIALS_PATH}/include NO_DEFAULT_PATH)
IF (NOT SUNDIALS_INCLUDE_DIR)
  MESSAGE(FATAL_ERROR "Could not find Sundials; compile omc first")
ENDIF(NOT SUNDIALS_INCLUDE_DIR)

MESSAGE(STATUS "Sundials include:")
MESSAGE(STATUS "${SUNDIALS_INCLUDE_DIR}")
INCLUDE_DIRECTORIES(${SUNDIALS_INCLUDE_DIR})

# SUNDIALS Libraires
FIND_LIBRARY(SUNDIALS_LIBRARY_NVEC    NAMES sundials_nvecserial    PATHS ${SUNDIALS_PATH}/lib NO_DEFAULT_PATH)
FIND_LIBRARY(SUNDIALS_KINSOL          NAMES sundials_kinsol        PATHS ${SUNDIALS_PATH}/lib NO_DEFAULT_PATH)

# Check if all libraries found
IF(NOT SUNDIALS_LIBRARY_NVEC)
  MESSAGE(FATAL_ERROR "Could not find libsundials_nvecserial!")
ENDIF()
IF(NOT SUNDIALS_KINSOL)
  MESSAGE(FATAL_ERROR "Could not find libsundials_kinsol!")
ENDIF()

SET(SUNDIALS_LIBRARIES ${SUNDIALS_LIBRARY_NVEC} ${SUNDIALS_KINSOL})
MESSAGE(STATUS "Used Sundials libraries: ${SUNDIALS_LIBRARIES}")

# Extract the version number from sundials_config.h
FIND_PATH(SUNDIALS_CONFIG_FILE "sundials_config.h" "${SUNDIALS_INCLUDE_DIR}" "${SUNDIALS_INCLUDE_DIR}/sundials")
IF(NOT SUNDIALS_CONFIG_FILE)
  MESSAGE(WARNING "Could not find sundials_config.h")
  MESSAGE(WARNING "Could not determine sundials version")
ENDIF(NOT SUNDIALS_CONFIG_FILE)

SET(SUNDIALS_CONFIG_FILE "${SUNDIALS_CONFIG_FILE}/sundials_config.h")
IF(NOT EXISTS "${SUNDIALS_CONFIG_FILE}")
  MESSAGE(FATAL_ERROR "Could not find sundials_config.h")
ENDIF()
FILE(READ "${SUNDIALS_CONFIG_FILE}" SUNDIALS_CONFIG_FILE_CONTENT)
STRING(REGEX MATCH "#define SUNDIALS_VERSION .([0-9]+)\\.([0-9]+)\\.([0-9]+)." _ ${SUNDIALS_CONFIG_FILE_CONTENT})

IF(DEFINED CMAKE_MATCH_1 AND DEFINED CMAKE_MATCH_2 AND DEFINED CMAKE_MATCH_3)
  SET(SUNDIALS_MAJOR_VERSION "${CMAKE_MATCH_1}")
  SET(SUNDIALS_MINOR_VERSION "${CMAKE_MATCH_2}")
  SET(SUNDIALS_PATCH_VERSION "${CMAKE_MATCH_3}")

  ADD_DEFINITIONS("-DSUNDIALS_MAJOR_VERSION=${SUNDIALS_MAJOR_VERSION}")
  ADD_DEFINITIONS("-DSUNDIALS_MINOR_VERSION=${SUNDIALS_MINOR_VERSION}")
ELSE()
  MESSAGE(FATAL_ERROR "Could not determine sundials version")
ENDIF()
MESSAGE(STATUS "Using sundials ${SUNDIALS_MAJOR_VERSION}.${SUNDIALS_MINOR_VERSION}.${SUNDIALS_PATCH_VERSION}")


####################################
# OMSISolver includes
####################################
include_directories ("${CMAKE_SOURCE_DIR}/solver/include" ${SUNDIALS_INCLUDE_DIR})

add_library(${OMSISolverName}
  src/solver_api.c
  src/solver_helper.c
  src/solver_kinsol.c
  src/solver_lapack.c
)

set(CMAKE_MACOSX_RPATH 1)   # Handle rpath on mac in makefiles
target_link_libraries(${OMSISolverName} ${CMAKE_DL_LIBS} ${LAPACK_LIBRARIES} ${BLAS_LIBRARIES} ${SUNDIALS_LIBRARIES})

install(TARGETS ${OMSISolverName} DESTINATION ${LIBINSTALLEXT})

install(FILES
  ${CMAKE_SOURCE_DIR}/solver/include/omsi_solver.h
  ${CMAKE_SOURCE_DIR}/solver/include/solver_api.h
  ${CMAKE_SOURCE_DIR}/solver/include/solver_helper.h
DESTINATION include/omc/omsi/solver)

