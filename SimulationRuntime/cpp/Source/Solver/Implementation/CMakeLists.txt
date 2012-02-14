cmake_minimum_required (VERSION 2.6)

project(Solver)
# add the solver default implementation library
add_library(Solver SHARED SolverDefaultImplementation.cpp SolverSettings.cpp Initialization.cpp )

install (TARGETS Solver DESTINATION bin)



 


  
  
 
