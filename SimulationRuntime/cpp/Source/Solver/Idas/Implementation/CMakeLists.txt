cmake_minimum_required (VERSION 2.6)

project(${IdasName})
include_directories(${SUNDIALS_INCLUDE_DIR}/idas ${SUNDIALS_INCLUDE_DIR}/nvector  ${SUNDIALS_INCLUDE_DIR}/sundials ${SUNDIALS_INCLUDE_DIR}) 
# add the solver default implementation library
add_library(${IdasName} SHARED Idas.cpp IdasSettings.cpp  )
target_link_libraries (${IdasName}  ${SolverName} ${Boost_LIBRARIES}  ${SUNDIALS_LIBS} )

install (TARGETS ${IdasName} DESTINATION lib/omc)


  
  
 
