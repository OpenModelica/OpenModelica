cmake_minimum_required(VERSION 2.8.9)

project(${SimulationSettings})

add_library(${SimulationSettings} GlobalSettings.cpp Factory.cpp FactoryExport.cpp)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${SimulationSettings} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")
endif(NOT BUILD_SHARED_LIBS)

target_link_libraries(${SimulationSettings} ${OMCFactoryName} ${Boost_LIBRARIES})
add_precompiled_header(${SimulationSettings} Include/Core/Modelica.h)

install(TARGETS ${SimulationSettings} DESTINATION ${LIBINSTALLEXT})
install(FILES "config/GlobalSettings.xml" DESTINATION share/omc/runtime/cpp/config)
install(FILES
  ${CMAKE_SOURCE_DIR}/Include/Core/SimulationSettings/IGlobalSettings.h
  ${CMAKE_SOURCE_DIR}/Include/Core/SimulationSettings/ISettingsFactory.h
  ${CMAKE_SOURCE_DIR}/Include/Core/SimulationSettings/ISimControllerSettings.h
  ${CMAKE_SOURCE_DIR}/Include/Core/SimulationSettings/Factory.h
  DESTINATION include/omc/cpp/Core/SimulationSettings)
