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


####################################
# OMSISolver
####################################

add_library(${OMSISolverName}
  src/solver_api.c
  src/solver_helper.c
  src/solver_kinsol.c
  src/solver_lapack.c)

target_include_directories(${OMSISolverName} PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/include")

set_target_properties(${OMSISolverName} PROPERTIES MACOSX_RPATH ON)

target_link_libraries(${OMSISolverName} PUBLIC ${CMAKE_DL_LIBS})
target_link_libraries(${OMSISolverName} PUBLIC ${LAPACK_LIBRARIES})
target_link_libraries(${OMSISolverName} PUBLIC omc::3rd::sundials::kinsol)
target_link_libraries(${OMSISolverName} PUBLIC omc::3rd::sundials::sunlinsollapackdense)

install(TARGETS ${OMSISolverName}
  RUNTIME DESTINATION bin
  LIBRARY DESTINATION ${LIBINSTALLEXT}
  ARCHIVE DESTINATION ${LIBINSTALLEXT})

install(FILES
  include/omsi_solver.h
  include/solver_api.h
  include/solver_helper.h
  DESTINATION include/omc/omsi/solver)
