cmake_minimum_required (VERSION 2.6)

project(${UmfPackName})

# add the solver default implementation library


IF(ANALYZATION_MODE)
	message(STATUS "Building UmfPack for analyzation")
	add_library(${UmfPackName} STATIC UmfPack.cpp UmfPackSettings.cpp FactoryExport )
	target_link_libraries( ${UmfPackName} ${MathName} ${Boost_LIBRARIES} ${LAPACK_LIBRARIES})
ELSE(ANALYZATION_MODE)
	add_library(${UmfPackName} SHARED UmfPack.cpp UmfPackSettings.cpp FactoryExport)
	target_link_libraries( ${UmfPackName}  ${MathName}  ${SUITESPARSE_LIBRARIES} ${Boost_LIBRARIES} ${LAPACK_LIBRARIES} $ENV{UMFPACK_RT})
ENDIF(ANALYZATION_MODE)

install (TARGETS ${UmfPackName} DESTINATION lib/omc/${LIBINSTALLEXT})

IF(ANALYZATION_MODE)
  install (FILES  ${CMAKE_SOURCE_DIR}/Include/Solver/UmfPack/UmfPack.h
                  ${CMAKE_SOURCE_DIR}/Include/Solver/UmfPack/UmfPackSettings.h
                  ${CMAKE_SOURCE_DIR}/Include/Solver/UmfPack/FactoryExport.h
           DESTINATION include/omc/cpp/Solver/UmfPack)
ENDIF(ANALYZATION_MODE)
