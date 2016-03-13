cmake_minimum_required(VERSION 2.8.9)

project(${UmfPackName})

add_library(${UmfPackName}_static STATIC UmfPack.cpp UmfPackSettings.cpp FactoryExport )
set_target_properties(${UmfPackName}_static PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")

add_library(${UmfPackName} SHARED UmfPack.cpp UmfPackSettings.cpp FactoryExport)
target_link_libraries( ${UmfPackName} ${MathName} ${SUITESPARSE_LIBRARIES} ${Boost_LIBRARIES} ${LAPACK_LIBRARIES} ${UMFPACK_LIB})
	
install (TARGETS ${UmfPackName} ${UmfPackName}_static DESTINATION ${LIBINSTALLEXT})

install (FILES  ${CMAKE_SOURCE_DIR}/Include/Solver/UmfPack/UmfPack.h
                  ${CMAKE_SOURCE_DIR}/Include/Solver/UmfPack/UmfPackSettings.h
                  ${CMAKE_SOURCE_DIR}/Include/Solver/UmfPack/FactoryExport.h
DESTINATION include/omc/cpp/Solver/UmfPack)
