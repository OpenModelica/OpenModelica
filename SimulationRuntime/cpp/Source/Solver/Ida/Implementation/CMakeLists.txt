cmake_minimum_required (VERSION 2.6)

project(Ida)
include_directories(${SUNDIALS_INCLUDE_DIR}/ida ${SUNDIALS_INCLUDE_DIR}/nvector  ${SUNDIALS_INCLUDE_DIR}/sundials ${SUNDIALS_INCLUDE_DIR}) 
# add the solver default implementation library
add_library(Ida SHARED Ida.cpp IdaSettings.cpp  )
target_link_libraries (Ida  Solver ${Boost_LIBRARIES}  ${SUNDIALS_LIBS} )

install (TARGETS Ida DESTINATION bin)


  
  
 
