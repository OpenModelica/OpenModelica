cmake_minimum_required(VERSION 3.5)

project(${NewtonName})

add_library(${NewtonName}
  Newton.cpp
  NewtonSettings.cpp
  FactoryExport.cpp)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${NewtonName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")
endif(NOT BUILD_SHARED_LIBS)

target_link_libraries(${NewtonName}
  ${SolverName}
  ${ExtensionUtilitiesName}
  ${Boost_LIBRARIES}
  ${LAPACK_LIBRARIES}
  ${ModelicaName})
add_precompiled_header(${NewtonName} Core/Modelica.h)

install(FILES $<TARGET_PDB_FILE:${NewtonName}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)

install(TARGETS ${NewtonName} DESTINATION ${LIBINSTALLEXT})
install(FILES
  ${CMAKE_SOURCE_DIR}/Solver/Newton/Newton.h
  ${CMAKE_SOURCE_DIR}/Solver/Newton/NewtonSettings.h
  ${CMAKE_SOURCE_DIR}/Solver/CVode/FactoryExport.h
  DESTINATION include/omc/cpp/Solver/Newton)
