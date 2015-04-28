cmake_minimum_required (VERSION 2.8.6)

project(${NewtonName})

# add the solver default implementation library

IF(RUNTIME_STATIC_LINKING)
	include_directories(${SUNDIALS_INCLUDE_DIR}/cvodes ${SUNDIALS_INCLUDE_DIR}/nvector  ${SUNDIALS_INCLUDE_DIR}/sundials ${SUNDIALS_INCLUDE_DIR})
	add_library(${NewtonName}_static STATIC Newton.cpp NewtonSettings.cpp FactoryExport )
	install (TARGETS ${NewtonName}_static DESTINATION lib/omc/${LIBINSTALLEXT})
ELSE(RUNTIME_STATIC_LINKING)
	add_library(${NewtonName} SHARED Newton.cpp NewtonSettings.cpp FactoryExport )
	target_link_libraries( ${NewtonName} ${Boost_LIBRARIES} ${LAPACK_LIBRARIES})
	add_precompiled_header(${NewtonName} Include/Core/Modelica.h )
    install (TARGETS ${NewtonName} DESTINATION lib/omc/${LIBINSTALLEXT})
ENDIF(RUNTIME_STATIC_LINKING)

#install (FILES "../Interfaces/NewtonSettings.xml"
#  DESTINATION bin/config)

IF(RUNTIME_STATIC_LINKING)
  install (FILES  ${CMAKE_SOURCE_DIR}/Include/Solver/Newton/Newton.h
                  ${CMAKE_SOURCE_DIR}/Include/Solver/Newton/NewtonSettings.h
                  ${CMAKE_SOURCE_DIR}/Include/Solver/CVode/FactoryExport.h
           DESTINATION include/omc/cpp/Solver/Newton)
ENDIF(RUNTIME_STATIC_LINKING)
