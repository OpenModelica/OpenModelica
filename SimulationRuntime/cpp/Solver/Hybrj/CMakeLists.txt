cmake_minimum_required (VERSION 2.8.6)

project(${HybrjName})
# add the solver default implementation library
IF(RUNTIME_STATIC_LINKING)
	add_library(${HybrjName} STATIC Hybrj.cpp HybrjSettings.cpp FactoryExport.cpp )
	include_directories(${SUNDIALS_INCLUDE_DIR}/cvodes ${SUNDIALS_INCLUDE_DIR}/nvector  ${SUNDIALS_INCLUDE_DIR}/sundials ${SUNDIALS_INCLUDE_DIR})
ELSE(RUNTIME_STATIC_LINKING)
	add_library(${HybrjName} SHARED Hybrj.cpp HybrjSettings.cpp FactoryExport.cpp )
    add_precompiled_header(${HybrjName} Include/Core/Modelica.h )
ENDIF(RUNTIME_STATIC_LINKING)
target_link_libraries( ${HybrjName} ${Boost_LIBRARIES})
target_link_libraries( ${HybrjName} ${LAPACK_LIBRARIES} ${CMINPACK_LIBRARY})
message(STATUS ${CMINPACK_LIBRARY})

install (TARGETS ${HybrjName} DESTINATION ${LIBINSTALLEXT})
#install (FILES "../Interfaces/NewtonSettings.xml" 
#  DESTINATION bin/config)


 


  
  
 
