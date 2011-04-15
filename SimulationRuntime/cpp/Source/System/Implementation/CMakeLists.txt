cmake_minimum_required (VERSION 2.6)

project(System)
# add the solver default implementation library
add_library(System SHARED AlgLoopDefaultImplementation AlgLoopSolverFactory.cpp EventHandling.cpp SystemDefaultImplementation.cpp )


install (TARGETS System DESTINATION bin)

 


  
  
 
