cmake_minimum_required (VERSION 2.6)

project(${SolverName})
# add the solver default implementation library
add_library(${SolverName} SHARED SolverDefaultImplementation.cpp SolverSettings.cpp Initialization.cpp )

install (TARGETS ${SolverName} DESTINATION lib/omc/${LIBINSTALLEXT})
install (FILES ${CMAKE_SOURCE_DIR}/Include/Core/Solver/IAlgLoopSolver.h 
DESTINATION include/omc/cpp/Core/Solver)
 








