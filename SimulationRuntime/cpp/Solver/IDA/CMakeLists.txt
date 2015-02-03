cmake_minimum_required (VERSION 2.6)

project(${IDAName})
include_directories(${SUNDIALS_INCLUDE_DIR}/ida ${SUNDIALS_INCLUDE_DIR}/nvector  ${SUNDIALS_INCLUDE_DIR}/sundials ${SUNDIALS_INCLUDE_DIR})

# add the solver default implementation library
IF(RUNTIME_STATIC_LINKING)
	add_library(${IDAName} STATIC IDA.cpp IDASettings.cpp FactoryExport.cpp  )
	target_link_libraries (${IDAName} ${SolverName} ${ExtensionUtilitiesName} ${Boost_LIBRARIES} ${SUNDIALS_LIBS} ${SolverName})
ELSE(RUNTIME_STATIC_LINKING)
	add_library(${IDAName} SHARED IDA.cpp IDASettings.cpp FactoryExport.cpp  )
	target_link_libraries (${IDAName} ${SolverName} ${ExtensionUtilitiesName} ${Boost_LIBRARIES} ${SUNDIALS_LIBS})
ENDIF(RUNTIME_STATIC_LINKING)
#target_link_libraries( Euler ${Boost_serialization_LIBRARY})

install (TARGETS ${IDAName} DESTINATION lib/omc/${LIBINSTALLEXT})
#install (FILES "../Interfaces/EulerSettings.xml"
 # DESTINATION bin/config)

IF(RUNTIME_STATIC_LINKING)
  install (FILES  ${CMAKE_SOURCE_DIR}/Include/Solver/IDA/IDA.h
                  ${CMAKE_SOURCE_DIR}/Include/Solver/IDA/FactoryExport.h
           DESTINATION include/omc/cpp/Solver/IDA)
ENDIF(RUNTIME_STATIC_LINKING)
