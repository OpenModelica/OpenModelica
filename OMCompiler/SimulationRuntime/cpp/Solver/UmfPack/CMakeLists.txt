CMAKE_MINIMUM_REQUIRED(VERSION 3.5)

project(${UmfPackName})

add_library(${UmfPackName} UmfPack.cpp UmfPackSettings.cpp FactoryExport)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${UmfPackName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")
endif(NOT BUILD_SHARED_LIBS)

target_link_libraries(${UmfPackName}  ${SolverName}  ${MathName} ${SUITESPARSE_LIBRARIES} ${Boost_LIBRARIES} ${LAPACK_LIBRARIES} ${UMFPACK_LIB})

install(FILES $<TARGET_PDB_FILE:${UmfPackName}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)

install(TARGETS ${UmfPackName} DESTINATION ${LIBINSTALLEXT})
install(FILES
  ${CMAKE_SOURCE_DIR}/Solver/UmfPack/UmfPack.h
  ${CMAKE_SOURCE_DIR}/Solver/UmfPack/UmfPackSettings.h
  ${CMAKE_SOURCE_DIR}/Solver/UmfPack/FactoryExport.h
  DESTINATION include/omc/cpp/Solver/UmfPack)
