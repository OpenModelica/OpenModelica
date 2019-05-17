CMAKE_MINIMUM_REQUIRED(VERSION 2.8.9)



# Needs to be included before Core/Modelica othwise environment variables are not set.
IF(USE_DGESV)
  ADD_SUBDIRECTORY(Solver/Dgesv)

  GET_TARGET_PROPERTY(libDgesv ${DgesvName} LOCATION)
  GET_FILENAME_COMPONENT(libDgesvName ${libDgesv} NAME)
ENDIF(USE_DGESV)

# adrpo: make sure this is first for the precompiled headers!
if(NOT FMU_TARGET)
  # add projects for generating a simulator
  add_subdirectory(Core/Modelica)
endif(NOT FMU_TARGET)

# add system default implemention project
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
  #add_subdirectory(ModelicaCompiler)
endif(NOT FMU_TARGET)

# add Newton solver
add_subdirectory(Solver/Newton)

IF(USE_SUNDIALS)
  #add  Cvode solver project
  ADD_SUBDIRECTORY (Solver/CVode)
  #add_subdirectory (Solver/ARKode)
  ADD_SUBDIRECTORY(Solver/IDA)
  ADD_SUBDIRECTORY(Solver/Kinsol)
ENDIF(USE_SUNDIALS)

if(NOT FMU_TARGET)

  # add more algebraic loop solvers
  add_subdirectory(Solver/Broyden)
  add_subdirectory(Solver/Hybrj)
  add_subdirectory(Solver/UmfPack)
  add_subdirectory(Solver/Peer)
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
  ##add_subdirectory(Solver/RTRK)
endif(NOT FMU_TARGET)

add_subdirectory(FMU)





