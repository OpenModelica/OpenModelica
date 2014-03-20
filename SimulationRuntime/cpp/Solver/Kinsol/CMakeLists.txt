cmake_minimum_required (VERSION 2.6)

project(${KinsolName})
include_directories(${SUNDIALS_INCLUDE_DIR}/kinsol ${SUNDIALS_INCLUDE_DIR}/nvector  ${SUNDIALS_INCLUDE_DIR}/sundials ${SUNDIALS_INCLUDE_DIR})
# add the solver default implementation library
IF(ANALYZATION_MODE)
	add_library(${KinsolName} STATIC Kinsol.cpp KinsolSettings.cpp FactoryExport.cpp)
	include_directories(${SUNDIALS_INCLUDE_DIR}/cvodes ${SUNDIALS_INCLUDE_DIR}/nvector  ${SUNDIALS_INCLUDE_DIR}/sundials ${SUNDIALS_INCLUDE_DIR})
ELSE(ANALYZATION_MODE)
	add_library(${KinsolName} SHARED Kinsol.cpp KinsolSettings.cpp FactoryExport.cpp)
ENDIF(ANALYZATION_MODE)
target_link_libraries( ${KinsolName} ${Boost_LIBRARIES}  ${SUNDIALS_LIBS}  ${LAPACK_LIBRARIES})



install (TARGETS ${KinsolName} DESTINATION lib/omc/${LIBINSTALLEXT})
#install (FILES "../Interfaces/NewtonSettings.xml"
#  DESTINATION bin/config)








