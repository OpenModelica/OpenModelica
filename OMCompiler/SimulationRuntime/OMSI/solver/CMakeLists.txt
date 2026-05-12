cmake_minimum_required(VERSION 3.14)
set(CMAKE_VERBOSE_MAKEFILE ON)

# OpenModelica Simulation Interface solver
project(OMSISolver)

############################
# Find BLAS and LAPACK
############################

find_package(BLAS)
find_package(LAPACK)

if(NOT BLAS_FOUND)
  message(FATAL_ERROR "Error: Blas Libraries not found!")
endif()
if(NOT LAPACK_FOUND)
  message(FATAL_ERROR "Error: Lapack Libraries not found!")
endif()
message(STATUS "Lapack Libraries: ${LAPACK_LIBRARIES} ${BLAS_LIBRARIES}")

if(MSVC)
  # workaround because cmake does not find the lapack libraries for Visual Studio 10
  set(LAPACK_MSVC_10 $ENV{OMDEV}/lib/3rdParty/Lapack/Lib/lapack_win32.lib)
  set(BLAS_MSVC_10 $ENV{OMDEV}/lib/3rdParty/Lapack/Lib/blas_win32.lib)
  set(LAPACK_LIBRARIES ${LAPACK_MSVC_10})
  set(BLAS_LIBRARIES ${BLAS_MSVC_10})
  message(STATUS "Using manual set Lapack Libraries: ${LAPACK_LIBRARIES}")
endif()


############################
# Find SUNDIALS libraries  #
############################

# Fallback for "standalone" makefile build
# TODO: Remove when switching to CMake build
if(NOT TARGET omc::3rd::sundials::kinsol)
  # Fallback path for standalone builds
  if(MSVC)
    set(SUNDIALS_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../../../../OMCompiler/3rdParty/sundials-5.4.0/build_msvc")
  else()
    set(SUNDIALS_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../../../../OMCompiler/3rdParty/sundials-5.4.0/build")
  endif()
  get_filename_component(SUNDIALS_PATH "${SUNDIALS_PATH}" ABSOLUTE)
  message(STATUS "Sundials PATH:")
  message(STATUS "${SUNDIALS_PATH}")

  file(GLOB
    SUNDIALS_POTENTIAL_LIBS
    LIST_DIRECTORIES true
    ${SUNDIALS_PATH}/lib*/* ${SUNDIALS_PATH}/lib*
  )

  find_path(SUNDIALS_LIB_DIR
    NAMES sundials_nvecserial libsundials_nvecserial sundials_nvecserial.dll
          libsundials_nvecserial.so sundials_nvecserial.a libsundials_nvecserial.a
          sundials_nvecserial.lib
    PATHS ${SUNDIALS_POTENTIAL_LIBS})

  message(STATUS "Sundials libs:")
  message(STATUS "${SUNDIALS_LIB_DIR}")

  # SUNDIALS Header
  find_path(SUNDIALS_INCLUDE_DIR "sundials/sundials_config.h"
    ${SUNDIALS_PATH}/include/sundials NO_DEFAULT_PATH)

  message(STATUS "Sundials include:")
  message(STATUS "${SUNDIALS_INCLUDE_DIR}")

  # SUNDIALS Libraries
  find_library(SUNDIALS_LIBRARY_NVEC         NAMES sundials_nvecserial           PATHS ${SUNDIALS_LIB_DIR})
  find_library(SUNDIALS_KINSOL               NAMES sundials_kinsol               PATHS ${SUNDIALS_LIB_DIR})
  find_library(SUNDIALS_SUNLINSOLKLU         NAMES sundials_sunlinsolklu         PATHS ${SUNDIALS_LIB_DIR})
  find_library(SUNDIALS_SUNLINSOLLAPACKDENSE NAMES sundials_sunlinsollapackdense PATHS ${SUNDIALS_LIB_DIR})

  # Check if all libraries found
  if(NOT SUNDIALS_LIBRARY_NVEC)
    message(FATAL_ERROR "Could not find libsundials_nvecserial!")
  endif()
  if(NOT SUNDIALS_KINSOL)
    message(FATAL_ERROR "Could not find libsundials_kinsol!")
  endif()
  if(NOT SUNDIALS_SUNLINSOLKLU)
    message(FATAL_ERROR "Could not find sundials_sunlinsolklu!")
  endif()
  if(NOT SUNDIALS_SUNLINSOLLAPACKDENSE)
    message(FATAL_ERROR "Could not find sundials_sunlinsollapackdense!")
  endif()

  set(SUNDIALS_LIBRARIES
    ${SUNDIALS_LIBRARY_NVEC}
    ${SUNDIALS_KINSOL}
    ${SUNDIALS_SUNLINSOLKLU}
    ${SUNDIALS_SUNLINSOLLAPACKDENSE})
  message(STATUS "Used Sundials libraries: ${SUNDIALS_LIBRARIES}")
endif()

####################################
# OMSISolver
####################################

add_library(${OMSISolverName}
  src/solver_api.c
  src/solver_helper.c
  src/solver_kinsol.c
  src/solver_lapack.c)

target_include_directories(${OMSISolverName} PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/include")
if(NOT TARGET omc::3rd::sundials::kinsol)
  target_include_directories(${OMSISolverName} SYSTEM PUBLIC "${SUNDIALS_INCLUDE_DIR}")
  target_compile_definitions(${OMSISolverName} PRIVATE ${SUNDIALS_VERSION_DEFS})
endif()

set_target_properties(${OMSISolverName} PROPERTIES MACOSX_RPATH ON)

target_link_libraries(${OMSISolverName} PUBLIC ${CMAKE_DL_LIBS})
target_link_libraries(${OMSISolverName} PUBLIC ${LAPACK_LIBRARIES})
if(TARGET omc::3rd::sundials::kinsol)
  target_link_libraries(${OMSISolverName} PUBLIC omc::3rd::sundials::kinsol)
  target_link_libraries(${OMSISolverName} PUBLIC omc::3rd::sundials::sunlinsolklu)
  target_link_libraries(${OMSISolverName} PUBLIC omc::3rd::sundials::sunlinsollapackdense)
else()
  target_link_libraries(${OMSISolverName} PUBLIC ${SUNDIALS_LIBRARIES})
endif()

install(TARGETS ${OMSISolverName}
  RUNTIME DESTINATION bin
  LIBRARY DESTINATION ${LIBINSTALLEXT}
  ARCHIVE DESTINATION ${LIBINSTALLEXT})

install(FILES
  include/omsi_solver.h
  include/solver_api.h
  include/solver_helper.h
  DESTINATION include/omc/omsi/solver)
