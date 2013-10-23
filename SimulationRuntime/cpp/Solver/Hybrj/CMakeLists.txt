cmake_minimum_required (VERSION 2.6)

project(${HybrjName})
# add the solver default implementation library
add_library(${HybrjName} SHARED Hybrj.cpp HybrjSettings.cpp FactoryExport.cpp )
target_link_libraries( ${HybrjName} ${Boost_LIBRARIES})
target_link_libraries( ${HybrjName} ${LAPACK_LIBRARIES} ${MINPACK_LIBRARIES})


install (TARGETS ${HybrjName} DESTINATION lib/omc/${LIBINSTALLEXT})
#install (FILES "../Interfaces/NewtonSettings.xml" 
#  DESTINATION bin/config)


 


  
  
 
