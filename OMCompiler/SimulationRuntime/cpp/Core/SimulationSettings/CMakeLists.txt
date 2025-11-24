CMAKE_MINIMUM_REQUIRED(VERSION 3.5)

project(${SimulationSettings})

add_library(${SimulationSettings} GlobalSettings.cpp Factory.cpp FactoryExport.cpp)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${SimulationSettings} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")
endif(NOT BUILD_SHARED_LIBS)

target_link_libraries(${SimulationSettings} ${OMCFactoryName} ${Boost_LIBRARIES}  ${ModelicaName})
add_precompiled_header(${SimulationSettings} Core/Modelica.h)

install(FILES $<TARGET_PDB_FILE:${SimulationSettings}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)

install(TARGETS ${SimulationSettings} DESTINATION ${LIBINSTALLEXT})
install(FILES "config/GlobalSettings.xml" DESTINATION share/omc/runtime/cpp/config)
install(FILES
  ${CMAKE_SOURCE_DIR}/Core/SimulationSettings/IGlobalSettings.h
  ${CMAKE_SOURCE_DIR}/Core/SimulationSettings/ISettingsFactory.h
  ${CMAKE_SOURCE_DIR}/Core/SimulationSettings/Factory.h
  DESTINATION include/omc/cpp/Core/SimulationSettings)
