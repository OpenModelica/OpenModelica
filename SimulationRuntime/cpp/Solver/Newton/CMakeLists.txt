cmake_minimum_required (VERSION 2.6)

project(${NewtonName})

# add the solver default implementation library

IF(ANALYZATION_MODE)
	message(STATUS "Building Newton for analyzation")
	include_directories(${SUNDIALS_INCLUDE_DIR}/cvodes ${SUNDIALS_INCLUDE_DIR}/nvector  ${SUNDIALS_INCLUDE_DIR}/sundials ${SUNDIALS_INCLUDE_DIR})
	add_library(${NewtonName} STATIC Newton.cpp NewtonSettings.cpp FactoryExport )
	target_link_libraries( ${NewtonName} ${MathName} ${Boost_LIBRARIES} ${LAPACK_LIBRARIES})
ELSE(ANALYZATION_MODE)
	add_library(${NewtonName} SHARED Newton.cpp NewtonSettings.cpp FactoryExport )
	target_link_libraries( ${NewtonName} ${Boost_LIBRARIES} ${LAPACK_LIBRARIES})
ENDIF(ANALYZATION_MODE)


install (TARGETS ${NewtonName} DESTINATION lib/omc/${LIBINSTALLEXT})
#install (FILES "../Interfaces/NewtonSettings.xml"
#  DESTINATION bin/config)

IF(ANALYZATION_MODE)
  install (FILES  ${CMAKE_SOURCE_DIR}/Solver/Newton/Newton.h
                  ${CMAKE_SOURCE_DIR}/Solver/Newton/NewtonSettings.h
                  ${CMAKE_SOURCE_DIR}/Solver/CVode/FactoryExport.h
           DESTINATION include/omc/cpp/Newton)
ENDIF(ANALYZATION_MODE)