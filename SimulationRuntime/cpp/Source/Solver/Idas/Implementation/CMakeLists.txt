cmake_minimum_required (VERSION 2.6)

project(Idas)
include_directories(${SUNDIALS_INCLUDE_DIR}/Idas ${SUNDIALS_INCLUDE_DIR}/nvector  ${SUNDIALS_INCLUDE_DIR}/sundials ${SUNDIALS_INCLUDE_DIR}) 
# add the solver default implementation library
add_library(Idas SHARED Idas.cpp IdasSettings.cpp  )
target_link_libraries (Idas  Solver ${Boost_LIBRARIES}  ${SUNDIALS_LIBS} )

install (TARGETS Idas DESTINATION bin)


  
  
 
