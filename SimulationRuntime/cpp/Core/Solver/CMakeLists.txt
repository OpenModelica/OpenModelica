cmake_minimum_required (VERSION 2.8.6)

project(${SolverName})

include_directories(${SUNDIALS_INCLUDE_DIR}/cvodes ${SUNDIALS_INCLUDE_DIR}/nvector  ${SUNDIALS_INCLUDE_DIR}/sundials ${SUNDIALS_INCLUDE_DIR})
add_library(${SolverName}_static STATIC SolverDefaultImplementation.cpp SolverSettings.cpp SystemStateSelection.cpp FactoryExport.cpp SimulationMonitor.cpp )
add_precompiled_header(${SolverName}_static Include/Core/Modelica.h)
install (TARGETS ${SolverName}_static DESTINATION ${LIBINSTALLEXT})

add_library(${SolverName} SHARED SolverDefaultImplementation.cpp SolverSettings.cpp SystemStateSelection.cpp FactoryExport.cpp SimulationMonitor.cpp)
target_link_libraries (${SolverName} ${MathName} ${Boost_LIBRARIES} ${ExtensionUtilitiesName})
add_precompiled_header(${SolverName} Include/Core/Modelica.h)
install (TARGETS ${SolverName} DESTINATION ${LIBINSTALLEXT})

if (UNIX)
	set_target_properties(${SolverName}_static PROPERTIES COMPILE_FLAGS -fPIC)
	set_target_properties(${SolverName} PROPERTIES COMPILE_FLAGS -fPIC)
endif(UNIX)

install (FILES
         ${CMAKE_SOURCE_DIR}/Include/Core/Solver/IAlgLoopSolver.h 
         ${CMAKE_SOURCE_DIR}/Include/Core/Solver/ILinSolverSettings.h
         ${CMAKE_SOURCE_DIR}/Include/Core/Solver/INonLinSolverSettings.h
         ${CMAKE_SOURCE_DIR}/Include/Core/Solver/ISolver.h
         ${CMAKE_SOURCE_DIR}/Include/Core/Solver/ISolverSettings.h
         ${CMAKE_SOURCE_DIR}/Include/Core/Solver/SolverSettings.h 
         ${CMAKE_SOURCE_DIR}/Include/Core/Solver/SolverDefaultImplementation.h 
         ${CMAKE_SOURCE_DIR}/Include/Core/Solver/SystemStateSelection.h 
         ${CMAKE_SOURCE_DIR}/Include/Core/Solver/SimulationMonitor.h 
  DESTINATION include/omc/cpp/Core/Solver)
 
