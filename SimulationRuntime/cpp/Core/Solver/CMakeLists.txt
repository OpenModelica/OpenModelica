cmake_minimum_required(VERSION 2.8.9)

project(${SolverName})

add_library(${SolverName} SolverDefaultImplementation.cpp SolverSettings.cpp SystemStateSelection.cpp FactoryExport.cpp SimulationMonitor.cpp)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${SolverName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING;ENABLE_SUNDIALS_STATIC")
endif(NOT BUILD_SHARED_LIBS)

target_link_libraries(${SolverName} ${MathName} ${Boost_LIBRARIES} ${ExtensionUtilitiesName})
add_precompiled_header(${SolverName} Include/Core/Modelica.h)

install(TARGETS ${SolverName} DESTINATION ${LIBINSTALLEXT})
install(FILES
  ${CMAKE_SOURCE_DIR}/Include/Core/Solver/IAlgLoopSolver.h
  ${CMAKE_SOURCE_DIR}/Include/Core/Solver/ILinSolverSettings.h
  ${CMAKE_SOURCE_DIR}/Include/Core/Solver/INonLinSolverSettings.h
  ${CMAKE_SOURCE_DIR}/Include/Core/Solver/ISolver.h
  ${CMAKE_SOURCE_DIR}/Include/Core/Solver/ISolverSettings.h
  ${CMAKE_SOURCE_DIR}/Include/Core/Solver/SolverSettings.h
  ${CMAKE_SOURCE_DIR}/Include/Core/Solver/SolverDefaultImplementation.h
  ${CMAKE_SOURCE_DIR}/Include/Core/Solver/SystemStateSelection.h
  ${CMAKE_SOURCE_DIR}/Include/Core/Solver/SimulationMonitor.h
  ${CMAKE_SOURCE_DIR}/Include/Core/Solver/FactoryExport.h
  DESTINATION include/omc/cpp/Core/Solver)
 
