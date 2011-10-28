cmake_minimum_required (VERSION 2.6)

project(Newton)
# add the solver default implementation library
add_library(Newton SHARED Newton.cpp NewtonSettings.cpp )
target_link_libraries( Newton ${Boost_LIBRARIES})
target_link_libraries( Newton ${LAPACK_LIBRARIES})


install (TARGETS Newton DESTINATION bin)
#install (FILES "../Interfaces/NewtonSettings.xml" 
#  DESTINATION bin/config)


 


  
  
 
