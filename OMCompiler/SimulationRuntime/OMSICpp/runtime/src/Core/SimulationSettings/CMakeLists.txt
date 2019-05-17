cmake_minimum_required(VERSION 2.8.9)

project(${SimulationSettings})

add_library(${SimulationSettings} GlobalSettings.cpp Factory.cpp FactoryExport.cpp)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${SimulationSettings} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")
else(NOT BUILD_SHARED_LIBS)
 install(FILES $<TARGET_PDB_FILE:${SimulationSettings}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)
endif(NOT BUILD_SHARED_LIBS)

target_link_libraries(${SimulationSettings} ${OMCFactoryName} ${Boost_LIBRARIES}  ${ModelicaName})
add_precompiled_header(${SimulationSettings} runtime/include/Core/Modelica.h)



install(TARGETS ${SimulationSettings} DESTINATION ${LIBINSTALLEXT})

install(FILES
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/SimulationSettings/IGlobalSettings.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/SimulationSettings/ISettingsFactory.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/SimulationSettings/ISimControllerSettings.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/SimulationSettings/Factory.h
  DESTINATION include/omc/omsicpp/Core/SimulationSettings)
