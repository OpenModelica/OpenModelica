CMAKE_MINIMUM_REQUIRED(VERSION 3.5)

project(${BroydenName})

add_library(${BroydenName} Broyden.cpp BroydenSettings.cpp FactoryExport.cpp )

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${BroydenName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")
endif(NOT BUILD_SHARED_LIBS)

target_link_libraries(${BroydenName} ${SolverName} ${ExtensionUtilitiesName} ${Boost_LIBRARIES} ${LAPACK_LIBRARIES}  ${ModelicaName})
add_precompiled_header(${BroydenName} Core/Modelica.h)

install(FILES $<TARGET_PDB_FILE:${BroydenName}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)


install(TARGETS ${BroydenName} DESTINATION ${LIBINSTALLEXT})
install(FILES
  ${CMAKE_SOURCE_DIR}/Solver/Broyden/Broyden.h
  ${CMAKE_SOURCE_DIR}/Solver/Broyden/BroydenSettings.h
  ${CMAKE_SOURCE_DIR}/Solver/Broyden/FactoryExport.h
  DESTINATION include/omc/cpp/Solver/Broyden)
