cmake_minimum_required (VERSION 2.8.6)

project(${KinsolName})
include_directories(${SUNDIALS_INCLUDE_DIR}/kinsol ${SUNDIALS_INCLUDE_DIR}/nvector  ${SUNDIALS_INCLUDE_DIR}/sundials ${SUNDIALS_INCLUDE_DIR})
# add the solver default implementation library
IF(RUNTIME_STATIC_LINKING)
	add_library(${KinsolName}_static STATIC Kinsol.cpp KinsolSettings.cpp FactoryExport.cpp)
	include_directories(${SUNDIALS_INCLUDE_DIR}/cvodes ${SUNDIALS_INCLUDE_DIR}/nvector  ${SUNDIALS_INCLUDE_DIR}/sundials ${SUNDIALS_INCLUDE_DIR})
	install (TARGETS ${KinsolName}_static DESTINATION lib/omc/${LIBINSTALLEXT})
ELSE(RUNTIME_STATIC_LINKING)
	add_library(${KinsolName} SHARED Kinsol.cpp KinsolSettings.cpp FactoryExport.cpp)
	install (TARGETS ${KinsolName} DESTINATION lib/omc/${LIBINSTALLEXT})
	add_precompiled_header(${KinsolName} Include/Core/Modelica.h )
    target_link_libraries(${KinsolName} ${Boost_LIBRARIES} ${SUNDIALS_LIBRARIES} ${LAPACK_LIBRARIES})
ENDIF(RUNTIME_STATIC_LINKING)

#install (FILES "../Interfaces/NewtonSettings.xml"
#  DESTINATION bin/config)

IF(RUNTIME_STATIC_LINKING)
  install (FILES  ${CMAKE_SOURCE_DIR}/Include/Solver/Kinsol/Kinsol.h
                  ${CMAKE_SOURCE_DIR}/Include/Solver/Kinsol/KinsolSettings.h
                  ${CMAKE_SOURCE_DIR}/Include/Solver/Kinsol/FactoryExport.h
           DESTINATION include/omc/cpp/Solver/Kinsol)
ENDIF(RUNTIME_STATIC_LINKING)








