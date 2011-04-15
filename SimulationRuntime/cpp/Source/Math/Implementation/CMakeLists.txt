cmake_minimum_required (VERSION 2.6)

project(Math)
# add the solver default implementation library
add_library(Math SHARED ArrayOperations.cpp  )


install (TARGETS Math DESTINATION bin)

 


  
  
 
