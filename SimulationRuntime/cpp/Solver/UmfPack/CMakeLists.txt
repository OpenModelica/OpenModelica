cmake_minimum_required (VERSION 2.6)

project(${UmfPackName})

# add the solver default implementation library


IF(RUNTIME_STATIC_LINKING)
	message(STATUS "Building UmfPack for analyzation")
	add_library(${UmfPackName}_static STATIC UmfPack.cpp UmfPackSettings.cpp FactoryExport )
	install (TARGETS ${UmfPackName}_static DESTINATION lib/omc/${LIBINSTALLEXT})
ELSE(RUNTIME_STATIC_LINKING)
	add_library(${UmfPackName} SHARED UmfPack.cpp UmfPackSettings.cpp FactoryExport)
	target_link_libraries( ${UmfPackName} ${MathName} ${SUITESPARSE_LIBRARIES} ${Boost_LIBRARIES} ${LAPACK_LIBRARIES} ${UMFPACK_LIB})
	install (TARGETS ${UmfPackName} DESTINATION lib/omc/${LIBINSTALLEXT})
ENDIF(RUNTIME_STATIC_LINKING)

IF(RUNTIME_STATIC_LINKING)
  install (FILES  ${CMAKE_SOURCE_DIR}/Include/Solver/UmfPack/UmfPack.h
                  ${CMAKE_SOURCE_DIR}/Include/Solver/UmfPack/UmfPackSettings.h
                  ${CMAKE_SOURCE_DIR}/Include/Solver/UmfPack/FactoryExport.h
           DESTINATION include/omc/cpp/Solver/UmfPack)
ENDIF(RUNTIME_STATIC_LINKING)
