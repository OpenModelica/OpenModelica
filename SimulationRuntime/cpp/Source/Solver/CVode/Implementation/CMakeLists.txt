cmake_minimum_required (VERSION 2.6)

project(CVode)
include_directories(${SUNDIALS_INCLUDE_DIR}/Cvodes ${SUNDIALS_INCLUDE_DIR}/nvector  ${SUNDIALS_INCLUDE_DIR}/sundials ${SUNDIALS_INCLUDE_DIR}) 

# add the solver default implementation library
add_library(CVode SHARED CVode.cpp CVodeSettings.cpp  )
target_link_libraries (CVode  Solver ${Boost_LIBRARIES}  ${SUNDIALS_LIBS})
#target_link_libraries( Euler ${Boost_serialization_LIBRARY})






install (TARGETS CVode DESTINATION bin)
#install (FILES "../Interfaces/EulerSettings.xml" 
 # DESTINATION bin/config)


  
  
 
