cmake_minimum_required (VERSION 2.6)

project(${UmfPackName})

# add the solver default implementation library


IF(ANALYZATION_MODE)
	message(STATUS "Building UmfPack for analyzation")
	add_library(${UmfPackName} STATIC UmfPack.cpp UmfPackSettings.cpp FactoryExport )
	target_link_libraries( ${UmfPackName} ${MathName} ${Boost_LIBRARIES} ${LAPACK_LIBRARIES})
ELSE(ANALYZATION_MODE)
	add_library(${UmfPackName} SHARED UmfPack.cpp UmfPackSettings.cpp FactoryExport)
	target_link_libraries( ${UmfPackName} ${UmfPack_LIBRARY} ${MathName} ${Boost_LIBRARIES} ${LAPACK_LIBRARIES})
ENDIF(ANALYZATION_MODE)

install (TARGETS ${UmfPackName} DESTINATION lib/omc/${LIBINSTALLEXT})
