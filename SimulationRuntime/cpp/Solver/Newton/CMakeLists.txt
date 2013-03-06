cmake_minimum_required (VERSION 2.6)

project(${NewtonName})
# add the solver default implementation library
add_library(${NewtonName} SHARED Newton.cpp NewtonSettings.cpp )
target_link_libraries( ${NewtonName} ${Boost_LIBRARIES})
target_link_libraries( ${NewtonName} ${LAPACK_LIBRARIES})


install (TARGETS ${NewtonName} DESTINATION lib/omc/${LIBINSTALLEXT})
#install (FILES "../Interfaces/NewtonSettings.xml"
#  DESTINATION bin/config)








