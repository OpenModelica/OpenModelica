CMAKE_MINIMUM_REQUIRED(VERSION 3.5)

project(${ModelicaUtilitiesName})

add_library(${ModelicaUtilitiesName} ModelicaUtilities.cpp ModelicaSimulationError.cpp)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${ModelicaUtilitiesName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")
else(NOT BUILD_SHARED_LIBS)
IF(MSVC)
 install(FILES $<TARGET_PDB_FILE:${ModelicaUtilitiesName}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)
ENDIF(MSVC)
endif(NOT BUILD_SHARED_LIBS)

target_link_libraries (${ModelicaUtilitiesName} ${Boost_LIBRARIES}  ${ModelicaName})
add_precompiled_header(${ModelicaUtilitiesName} runtime/include/Core/Modelica.h )


install(TARGETS ${ModelicaUtilitiesName} DESTINATION ${LIBINSTALLEXT})
install(FILES
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/Utils/Modelica/FactoryExport.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/Utils/Modelica/ModelicaSimulationError.h
  DESTINATION include/omc/omsicpp/Core/Utils/Modelica)
install(FILES
  ${CMAKE_SOURCE_DIR}/runtime/include/ModelicaUtilities.h
  DESTINATION include/omc/omsicpp)
