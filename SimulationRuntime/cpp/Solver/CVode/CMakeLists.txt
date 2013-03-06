cmake_minimum_required (VERSION 2.6)

project(${CVodeName})
include_directories(${SUNDIALS_INCLUDE_DIR}/cvodes ${SUNDIALS_INCLUDE_DIR}/nvector  ${SUNDIALS_INCLUDE_DIR}/sundials ${SUNDIALS_INCLUDE_DIR})

# add the solver default implementation library
add_library(${CVodeName} SHARED CVode.cpp CVodeSettings.cpp  )
target_link_libraries (${CVodeName}  ${SolverName} ${Boost_LIBRARIES}  ${SUNDIALS_LIBS})
#target_link_libraries( Euler ${Boost_serialization_LIBRARY})






install (TARGETS ${CVodeName} DESTINATION lib/omc/${LIBINSTALLEXT})
#install (FILES "../Interfaces/EulerSettings.xml"
 # DESTINATION bin/config)





