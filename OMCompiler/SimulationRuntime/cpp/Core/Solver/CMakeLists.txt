cmake_minimum_required(VERSION 3.5)

project(${SolverName})

add_library(${SolverName} SolverDefaultImplementation.cpp AlgLoopSolverDefaultImplementation.cpp SolverSettings.cpp SystemStateSelection.cpp FactoryExport.cpp SimulationMonitor.cpp)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${SolverName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING;ENABLE_SUNDIALS_STATIC")
endif(NOT BUILD_SHARED_LIBS)

target_link_libraries(${SolverName} ${MathName} ${Boost_LIBRARIES} ${ExtensionUtilitiesName})
add_precompiled_header(${SolverName} Core/Modelica.h)

install(FILES $<TARGET_PDB_FILE:${SolverName}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)

install(TARGETS ${SolverName} DESTINATION ${LIBINSTALLEXT})
install(FILES
  ${CMAKE_SOURCE_DIR}/Core/Solver/ILinearAlgLoopSolver.h
  ${CMAKE_SOURCE_DIR}/Core/Solver/INonLinearAlgLoopSolver.h
  ${CMAKE_SOURCE_DIR}/Core/Solver/ILinSolverSettings.h
  ${CMAKE_SOURCE_DIR}/Core/Solver/INonLinSolverSettings.h
  ${CMAKE_SOURCE_DIR}/Core/Solver/ISolver.h
  ${CMAKE_SOURCE_DIR}/Core/Solver/ISolverSettings.h
  ${CMAKE_SOURCE_DIR}/Core/Solver/SolverSettings.h
  ${CMAKE_SOURCE_DIR}/Core/Solver/SolverDefaultImplementation.h
  ${CMAKE_SOURCE_DIR}/Core/Solver/SystemStateSelection.h
  ${CMAKE_SOURCE_DIR}/Core/Solver/SimulationMonitor.h
  ${CMAKE_SOURCE_DIR}/Core/Solver/FactoryExport.h
  DESTINATION include/omc/cpp/Core/Solver)
