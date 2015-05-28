cmake_minimum_required (VERSION 2.8.6)

project(${CVodeName})
#include_directories(${SUNDIALS_INCLUDE_DIR}/cvodes ${SUNDIALS_INCLUDE_DIR}/nvector  ${SUNDIALS_INCLUDE_DIR}/sundials ${SUNDIALS_INCLUDE_DIR})

# add the solver default implementation library
IF(RUNTIME_STATIC_LINKING)
	add_library(${CVodeName}_static STATIC CVode.cpp CVodeSettings.cpp FactoryExport.cpp)
	install (TARGETS ${CVodeName}_static DESTINATION ${LIBINSTALLEXT})
ELSE(RUNTIME_STATIC_LINKING)
	add_library(${CVodeName} SHARED CVode.cpp CVodeSettings.cpp FactoryExport.cpp  )
	target_link_libraries (${CVodeName} ${SolverName} ${ExtensionUtilitiesName} ${Boost_LIBRARIES} ${SUNDIALS_LIBRARIES})
	add_precompiled_header(${CVodeName} Include/Core/Modelica.h )
    install (TARGETS ${CVodeName} DESTINATION ${LIBINSTALLEXT})
ENDIF(RUNTIME_STATIC_LINKING)
#target_link_libraries( Euler ${Boost_serialization_LIBRARY})


#install (FILES "../Interfaces/EulerSettings.xml"
 # DESTINATION bin/config)

IF(RUNTIME_STATIC_LINKING)
  install (FILES  ${CMAKE_SOURCE_DIR}/Include/Solver/CVode/CVode.h
                  ${CMAKE_SOURCE_DIR}/Include/Solver/CVode/FactoryExport.h
           DESTINATION include/omc/cpp/Solver/CVode)
ENDIF(RUNTIME_STATIC_LINKING)
