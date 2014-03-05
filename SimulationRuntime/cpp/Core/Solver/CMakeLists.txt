cmake_minimum_required (VERSION 2.6)

project(${SolverName})
# add the solver default implementation library
add_library(${SolverName} SHARED SolverDefaultImplementation.cpp SolverSettings.cpp SystemStateSelection.cpp FactoryExport.cpp )
target_link_libraries (${SolverName} ${MathName} ${Boost_LIBRARIES}  )
install (TARGETS ${SolverName} DESTINATION lib/omc/${LIBINSTALLEXT})
install (FILES
         ${CMAKE_SOURCE_DIR}/Include/Core/Solver/IAlgLoopSolver.h 
         ${CMAKE_SOURCE_DIR}/Include/Core/Solver/INonLinSolverSettings.h
		 ${CMAKE_SOURCE_DIR}/Include/Core/Solver/ISolver.h
		   ${CMAKE_SOURCE_DIR}/Include/Core/Solver/ISolverSettings.h
DESTINATION include/omc/cpp/Core/Solver)
 
