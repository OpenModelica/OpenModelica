cmake_minimum_required (VERSION 2.6)

project(${NewtonName})

# add the solver default implementation library

IF(RUNTIME_STATIC_LINKING)
	message(STATUS "Building Newton for analyzation")
	include_directories(${SUNDIALS_INCLUDE_DIR}/cvodes ${SUNDIALS_INCLUDE_DIR}/nvector  ${SUNDIALS_INCLUDE_DIR}/sundials ${SUNDIALS_INCLUDE_DIR})
	add_library(${NewtonName} STATIC Newton.cpp NewtonSettings.cpp FactoryExport )
	target_link_libraries( ${NewtonName} ${MathName} ${Boost_LIBRARIES} ${LAPACK_LIBRARIES})
ELSE(RUNTIME_STATIC_LINKING)
	add_library(${NewtonName} SHARED Newton.cpp NewtonSettings.cpp FactoryExport )
	target_link_libraries( ${NewtonName} ${Boost_LIBRARIES} ${LAPACK_LIBRARIES})
ENDIF(RUNTIME_STATIC_LINKING)


install (TARGETS ${NewtonName} DESTINATION lib/omc/${LIBINSTALLEXT})
#install (FILES "../Interfaces/NewtonSettings.xml"
#  DESTINATION bin/config)

IF(RUNTIME_STATIC_LINKING)
  install (FILES  ${CMAKE_SOURCE_DIR}/Include/Solver/Newton/Newton.h
                  ${CMAKE_SOURCE_DIR}/Include/Solver/Newton/NewtonSettings.h
                  ${CMAKE_SOURCE_DIR}/Include/Solver/CVode/FactoryExport.h
           DESTINATION include/omc/cpp/Solver/Newton)
ENDIF(RUNTIME_STATIC_LINKING)
