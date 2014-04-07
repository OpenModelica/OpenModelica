cmake_minimum_required (VERSION 2.6)

project(${HybrjName})
# add the solver default implementation library
IF(ANALYZATION_MODE)
	add_library(${HybrjName} STATIC Hybrj.cpp HybrjSettings.cpp FactoryExport.cpp )
	include_directories(${SUNDIALS_INCLUDE_DIR}/cvodes ${SUNDIALS_INCLUDE_DIR}/nvector  ${SUNDIALS_INCLUDE_DIR}/sundials ${SUNDIALS_INCLUDE_DIR})
ELSE(ANALYZATION_MODE)
	add_library(${HybrjName} SHARED Hybrj.cpp HybrjSettings.cpp FactoryExport.cpp )
ENDIF(ANALYZATION_MODE)
target_link_libraries( ${HybrjName} ${Boost_LIBRARIES})
target_link_libraries( ${HybrjName} ${LAPACK_LIBRARIES} ${CMINPACK_LIBRARY})
message(STATUS ${CMINPACK_LIBRARY})

install (TARGETS ${HybrjName} DESTINATION lib/omc/${LIBINSTALLEXT})
#install (FILES "../Interfaces/NewtonSettings.xml" 
#  DESTINATION bin/config)


 


  
  
 
