cmake_minimum_required (VERSION 2.8.6)

project(${RTEulerName})
# add the solver default implementation library
IF(RUNTIME_STATIC_LINKING)
	add_library(${RTEulerName} STATIC RTEuler.cpp RTEulerSettings.cpp FactoryExport.cpp )
	include_directories(${SUNDIALS_INCLUDE_DIR}/cvodes ${SUNDIALS_INCLUDE_DIR}/nvector  ${SUNDIALS_INCLUDE_DIR}/sundials ${SUNDIALS_INCLUDE_DIR})
ELSE(RUNTIME_STATIC_LINKING)
	add_library(${RTEulerName} SHARED RTEuler.cpp RTEulerSettings.cpp FactoryExport.cpp )
ENDIF(RUNTIME_STATIC_LINKING)
target_link_libraries (${RTEulerName} ${SolverName} ${Boost_LIBRARIES} ${LAPACK_LIBRARIES} )
install (TARGETS ${RTEulerName} DESTINATION lib/omc/${LIBINSTALLEXT})




