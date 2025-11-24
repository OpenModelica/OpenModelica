CMAKE_MINIMUM_REQUIRED(VERSION 3.5)

project(${IDAName})

add_library(${IDAName} IDA.cpp IDASettings.cpp FactoryExport.cpp)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${IDAName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING;ENABLE_SUNDIALS_STATIC")
else(NOT BUILD_SHARED_LIBS)
IF(MSVC)
 install(FILES $<TARGET_PDB_FILE:${IDAName}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)
ENDIF(MSVC)
endif(NOT BUILD_SHARED_LIBS)

target_link_libraries(${IDAName} ${SolverName} ${ExtensionUtilitiesName} ${Boost_LIBRARIES} ${SUNDIALS_LIBRARIES})
add_precompiled_header(${IDAName} runtime/include/Core/Modelica.h )



install(TARGETS ${IDAName} DESTINATION ${LIBINSTALLEXT})
install(FILES
  ${CMAKE_SOURCE_DIR}/runtime/include/Solver/IDA/IDA.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Solver/IDA/FactoryExport.h
  DESTINATION include/omc/omsicpp/Solver/IDA)
