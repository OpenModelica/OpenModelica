cmake_minimum_required(VERSION 2.8.9)

project(${SolverName})

add_library(${SolverName} SolverDefaultImplementation.cpp AlgLoopSolverDefaultImplementation.cpp SolverSettings.cpp SystemStateSelection.cpp FactoryExport.cpp SimulationMonitor.cpp)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${SolverName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING;ENABLE_SUNDIALS_STATIC")
else(NOT BUILD_SHARED_LIBS)
 install(FILES $<TARGET_PDB_FILE:${SolverName}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)
endif(NOT BUILD_SHARED_LIBS)

target_link_libraries(${SolverName} ${MathName} ${Boost_LIBRARIES} ${ExtensionUtilitiesName})
add_precompiled_header(${SolverName} runtime/include/Core/Modelica.h)



install(TARGETS ${SolverName} DESTINATION ${LIBINSTALLEXT})
install(FILES
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/Solver/ILinearAlgLoopSolver.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/Solver/INonLinearAlgLoopSolver.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/Solver/ILinSolverSettings.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/Solver/INonLinSolverSettings.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/Solver/ISolver.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/Solver/ISolverSettings.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/Solver/SolverSettings.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/Solver/SolverDefaultImplementation.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/Solver/SystemStateSelection.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/Solver/SimulationMonitor.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/Solver/FactoryExport.h
  DESTINATION include/omc/omsicpp/Core/Solver)

