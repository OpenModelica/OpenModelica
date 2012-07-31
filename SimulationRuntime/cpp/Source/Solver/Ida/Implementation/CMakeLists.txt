cmake_minimum_required (VERSION 2.6)

project(${IdaName})
include_directories(${SUNDIALS_INCLUDE_DIR}/ida ${SUNDIALS_INCLUDE_DIR}/nvector  ${SUNDIALS_INCLUDE_DIR}/sundials ${SUNDIALS_INCLUDE_DIR}) 
# add the solver default implementation library
add_library(${IdaName} SHARED Ida.cpp IdaSettings.cpp  )
target_link_libraries (${IdaName}  ${SolverName} ${Boost_LIBRARIES}  ${SUNDIALS_LIBS} )

install (TARGETS ${IdaName} DESTINATION lib/omc)


  
  
 
