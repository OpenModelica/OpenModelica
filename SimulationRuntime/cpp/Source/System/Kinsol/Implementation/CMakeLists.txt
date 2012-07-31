cmake_minimum_required (VERSION 2.6)

project(${KinsolName})
# add the solver default implementation library
add_library(${KinsolName} SHARED KinsolCall.cpp KinsolCallSettings.cpp )
target_link_libraries( ${KinsolName} ${Boost_LIBRARIES})



install (TARGETS ${KinsolName} DESTINATION lib/omc)
#install (FILES "../Interfaces/NewtonSettings.xml" 
#  DESTINATION bin/config)


 


  
  
 
