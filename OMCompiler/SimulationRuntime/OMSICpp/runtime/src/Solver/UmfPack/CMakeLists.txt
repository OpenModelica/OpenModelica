CMAKE_MINIMUM_REQUIRED(VERSION 3.5)

project(${UmfPackName})

add_library(${UmfPackName} UmfPack.cpp UmfPackSettings.cpp FactoryExport)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${UmfPackName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")
else(NOT BUILD_SHARED_LIBS)
IF(MSVC)
 install(FILES $<TARGET_PDB_FILE:${UmfPackName}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)
ENDIF(MSVC)
endif(NOT BUILD_SHARED_LIBS)

target_link_libraries(${UmfPackName}  ${SolverName}  ${MathName} ${SUITESPARSE_LIBRARIES} ${Boost_LIBRARIES} ${LAPACK_LIBRARIES} ${UMFPACK_LIB})



install(TARGETS ${UmfPackName} DESTINATION ${LIBINSTALLEXT})
install(FILES
  ${CMAKE_SOURCE_DIR}/runtime/include/Solver/UmfPack/UmfPack.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Solver/UmfPack/UmfPackSettings.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Solver/UmfPack/FactoryExport.h
  DESTINATION include/omc/omsicpp/Solver/UmfPack)
