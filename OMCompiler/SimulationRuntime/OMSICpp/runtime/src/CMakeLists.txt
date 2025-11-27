CMAKE_MINIMUM_REQUIRED(VERSION 3.5)


# Needs to be included before Core/Modelica othwise environment variables are not set.
IF(USE_DGESV)
  ADD_SUBDIRECTORY(Solver/Dgesv)
ENDIF(USE_DGESV)

# adrpo: make sure this is first for the precompiled headers!
if(NOT FMU_TARGET)
  # add projects for generating a simulator
  add_subdirectory(Core/Modelica)
endif(NOT FMU_TARGET)

# add system default implemention project
if(USE_FMILIB)
    add_subdirectory(Core/ModelicaExternalC)
endif(USE_FMILIB)

add_subdirectory(Core/System)
# add solver default implemention project
add_subdirectory(Core/Solver)

add_subdirectory(Core/Math)
add_subdirectory(Core/Utils/Modelica)
add_subdirectory(Core/Utils/extension)


if(NOT FMU_TARGET)
  # add projects for generating a simulator
  add_subdirectory(SimCoreFactory/OMCFactory)
  add_subdirectory(Core/DataExchange)
  add_subdirectory(Core/SimulationSettings)
  add_subdirectory(Core/SimController)
  if(REDUCE_DAE)
    add_subdirectory(Core/ReduceDAE)
  endif()
endif(NOT FMU_TARGET)

# add Newton solver
add_subdirectory(Solver/Newton)

IF(USE_SUNDIALS)
  #add  Cvode solver project
  ADD_SUBDIRECTORY (Solver/CVode)
  ADD_SUBDIRECTORY(Solver/IDA)
  ADD_SUBDIRECTORY(Solver/Kinsol)
ENDIF(USE_SUNDIALS)

if(NOT FMU_TARGET)

  # add more algebraic loop solvers
  if(BUILD_BROYDEN)
     add_subdirectory(Solver/Broyden)
  endif(BUILD_BROYDEN)
  if(USE_MINPACK)
    add_subdirectory(Solver/Hybrj)
  endif(USE_MINPACK)
  add_subdirectory(Solver/UmfPack)
  if(BUILD_PEER)
    add_subdirectory(Solver/Peer)
  endif(BUILD_PEER)
  add_subdirectory(Solver/LinearSolver)
  # add simulation solvers
  add_subdirectory(Solver/Euler)
  add_subdirectory(Solver/RK12)
  add_subdirectory(Solver/RTEuler)
  if(OPENMP_FOUND)
    if(SUITESPARSE_UMFPACK_FOUND)
      message(STATUS "CppDassl enabled")
      add_subdirectory (Solver/CppDASSL)
    else(SUITESPARSE_UMFPACK_FOUND)
      message(STATUS "CppDassl disabled, because of missing UMFPACK support")
    endif(SUITESPARSE_UMFPACK_FOUND)
  else(OPENMP_FOUND)
    message(STATUS "CppDassl disabled, because of missing OpenMP support")
  endif(OPENMP_FOUND)
endif(NOT FMU_TARGET)

add_subdirectory(FMU)
