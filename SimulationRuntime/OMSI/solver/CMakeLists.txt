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

# Find SUNDIALS KINSOL libraries
FIND_LIBRARY(KINSOL_LIBRARIE sundials_kinsol
	PATHS ${CMAKE_INSTALL_PREFIX}/${LIB_OMC}
	NO_DEFAULT_PATH)
IF (NOT KINSOL_LIBRARIE)
  MESSAGE(FATAL_ERROR "Error: SUNDIALS KINSOL library not found!")
ENDIF()

FIND_LIBRARY(SUNDIALS_NVEC_LIBRARIE sundials_nvecserial
	PATHS ${CMAKE_INSTALL_PREFIX}/${LIB_OMC}
	NO_DEFAULT_PATH)
IF(NOT SUNDIALS_NVEC_LIBRARIE)
  MESSAGE(FATAL_ERROR "Error: sundials_nvec_serial library not found!")
ENDIF()

include_directories ("${CMAKE_INSTALL_PREFIX}/include/omc/c/sundials")
MESSAGE(STATUS "Location of SUNDIALS headers: ${CMAKE_INSTALL_PREFIX}/include/omc/c/sundials")

SET(SUNDIALS_LIBRARIES ${KINSOL_LIBRARIE} ${SUNDIALS_NVEC_LIBRARIE})
MESSAGE(STATUS "KINSOL Libraries: ${SUNDIALS_LIBRARIES}")

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
