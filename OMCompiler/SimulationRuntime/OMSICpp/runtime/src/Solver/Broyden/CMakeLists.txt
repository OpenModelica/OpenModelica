cmake_minimum_required(VERSION 2.8.9)

project(${BroydenName})

add_library(${BroydenName} Broyden.cpp BroydenSettings.cpp FactoryExport.cpp )

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${BroydenName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")
else(NOT BUILD_SHARED_LIBS)
 install(FILES $<TARGET_PDB_FILE:${BroydenName}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)
endif(NOT BUILD_SHARED_LIBS)

target_link_libraries(${BroydenName} ${SolverName} ${ExtensionUtilitiesName} ${Boost_LIBRARIES} ${LAPACK_LIBRARIES}  ${ModelicaName})
add_precompiled_header(${BroydenName} runtime/include/Solver/Modelica.h)




install(TARGETS ${BroydenName} DESTINATION ${LIBINSTALLEXT})
install(FILES
  ${CMAKE_SOURCE_DIR}/runtime/include/Solver/Broyden/Broyden.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Solver/Broyden/BroydenSettings.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Solver/Broyden/FactoryExport.h
  DESTINATION include/omc/omsicpp/Solver/Broyden)
