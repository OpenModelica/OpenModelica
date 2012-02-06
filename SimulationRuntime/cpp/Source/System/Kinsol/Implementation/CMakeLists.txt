cmake_minimum_required (VERSION 2.6)

project(Kinsol)
# add the solver default implementation library
add_library(Kinsol SHARED KinsolCall.cpp KinsolCallSettings.cpp )
target_link_libraries( Kinsol ${Boost_LIBRARIES})



install (TARGETS Kinsol DESTINATION bin)
#install (FILES "../Interfaces/NewtonSettings.xml" 
#  DESTINATION bin/config)


 


  
  
 
