cmake_minimum_required (VERSION 2.6)

project(${CVodeName})
include_directories(${SUNDIALS_INCLUDE_DIR}/cvodes ${SUNDIALS_INCLUDE_DIR}/nvector  ${SUNDIALS_INCLUDE_DIR}/sundials ${SUNDIALS_INCLUDE_DIR})

# add the solver default implementation library
IF(RUNTIME_STATIC_LINKING)
	add_library(${CVodeName} STATIC CVode.cpp CVodeSettings.cpp FactoryExport.cpp  )
	target_link_libraries (${CVodeName} ${SolverName} ${ExtensionUtilitiesName} ${Boost_LIBRARIES} ${SUNDIALS_LIBS} ${SolverName})
ELSE(RUNTIME_STATIC_LINKING)
	add_library(${CVodeName} SHARED CVode.cpp CVodeSettings.cpp FactoryExport.cpp  )
	target_link_libraries (${CVodeName} ${SolverName} ${ExtensionUtilitiesName} ${Boost_LIBRARIES} ${SUNDIALS_LIBS})
ENDIF(RUNTIME_STATIC_LINKING)
#target_link_libraries( Euler ${Boost_serialization_LIBRARY})

install (TARGETS ${CVodeName} DESTINATION lib/omc/${LIBINSTALLEXT})
#install (FILES "../Interfaces/EulerSettings.xml"
 # DESTINATION bin/config)

IF(RUNTIME_STATIC_LINKING)
  install (FILES  ${CMAKE_SOURCE_DIR}/Include/Solver/CVode/CVode.h
                  ${CMAKE_SOURCE_DIR}/Include/Solver/CVode/FactoryExport.h
           DESTINATION include/omc/cpp/Solver/CVode)
ENDIF(RUNTIME_STATIC_LINKING)
