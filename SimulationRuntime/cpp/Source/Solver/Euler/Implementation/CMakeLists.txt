cmake_minimum_required (VERSION 2.6)

project(Euler)
# add the solver default implementation library
add_library(Euler SHARED Euler.cpp EulerSettings.cpp  )
target_link_libraries (Euler Solver )
#target_link_libraries( Euler ${Boost_serialization_LIBRARY})
#target_link_libraries( Euler ${Boost_LIBRARIES})
#target_link_libraries( Euler ${LAPACK_LIBRARIES})



install (TARGETS Euler DESTINATION bin)
install (FILES "../Interfaces/EulerSettings.xml" 
  DESTINATION bin/config)


  
  
 
