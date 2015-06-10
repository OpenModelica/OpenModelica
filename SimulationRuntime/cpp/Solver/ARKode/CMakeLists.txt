cmake_minimum_required (VERSION 2.8.6)

project(${ARKodeName})
include_directories(${SUNDIALS_INCLUDE_DIR}/arkode ${SUNDIALS_INCLUDE_DIR}/nvector  ${SUNDIALS_INCLUDE_DIR}/sundials ${SUNDIALS_INCLUDE_DIR})

# add the solver default implementation library
IF(RUNTIME_STATIC_LINKING)
	add_library(${ARKodeName}_static STATIC ARKode.cpp ARKodeSettings.cpp FactoryExport.cpp)
	install (TARGETS ${ARKodeName}_static DESTINATION ${LIBINSTALLEXT})
ELSE(RUNTIME_STATIC_LINKING)
	add_library(${ARKodeName} SHARED ARKode.cpp ARKodeSettings.cpp FactoryExport.cpp  )
	target_link_libraries (${ARKodeName} ${SolverName} ${ExtensionUtilitiesName} ${Boost_LIBRARIES} ${SUNDIALS_LIBRARIES})
	add_precompiled_header(${ARKodeName} Include/Core/Modelica.h )
    install (TARGETS ${ARKodeName} DESTINATION ${LIBINSTALLEXT})
ENDIF(RUNTIME_STATIC_LINKING)
#target_link_libraries( Euler ${Boost_serialization_LIBRARY})


#install (FILES "../Interfaces/EulerSettings.xml"
 # DESTINATION bin/config)

IF(RUNTIME_STATIC_LINKING)
  install (FILES  ${CMAKE_SOURCE_DIR}/Include/Solver/ARKode/ARKode.h
                  ${CMAKE_SOURCE_DIR}/Include/Solver/ARKode/FactoryExport.h
           DESTINATION include/omc/cpp/Solver/ARKode)
ENDIF(RUNTIME_STATIC_LINKING)
