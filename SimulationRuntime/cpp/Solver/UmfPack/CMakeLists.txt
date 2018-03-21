cmake_minimum_required(VERSION 2.8.9)

project(${UmfPackName})

add_library(${UmfPackName} UmfPack.cpp UmfPackSettings.cpp FactoryExport)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${UmfPackName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")
endif(NOT BUILD_SHARED_LIBS)

target_link_libraries(${UmfPackName} ${MathName} ${SUITESPARSE_LIBRARIES} ${Boost_LIBRARIES} ${LAPACK_LIBRARIES} ${UMFPACK_LIB})

install(FILES $<TARGET_PDB_FILE:${UmfPackName}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)

install(TARGETS ${UmfPackName} DESTINATION ${LIBINSTALLEXT})
install(FILES
  ${CMAKE_SOURCE_DIR}/Include/Solver/UmfPack/UmfPack.h
  ${CMAKE_SOURCE_DIR}/Include/Solver/UmfPack/UmfPackSettings.h
  ${CMAKE_SOURCE_DIR}/Include/Solver/UmfPack/FactoryExport.h
  DESTINATION include/omc/cpp/Solver/UmfPack)
