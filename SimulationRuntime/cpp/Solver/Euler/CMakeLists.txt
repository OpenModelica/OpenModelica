cmake_minimum_required (VERSION 2.6)

project(${EulerName})
# add the solver default implementation library
add_library(${EulerName} SHARED Euler.cpp EulerSettings.cpp  )
target_link_libraries (${EulerName} ${SolverName} ${Boost_LIBRARIES} ${LAPACK_LIBRARIES} )
#target_link_libraries( Euler ${Boost_serialization_LIBRARY})
#target_link_libraries( Euler ${Boost_LIBRARIES})
#target_link_libraries( Euler ${LAPACK_LIBRARIES})



install (TARGETS ${EulerName} DESTINATION lib/omc/${LIBINSTALLEXT})
install (FILES "config/EulerSettings.xml"
  DESTINATION share/omc/runtime/cpp/config)





