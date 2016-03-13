cmake_minimum_required(VERSION 2.8.9)

project(${SimulationSettings})

include_directories(${SUNDIALS_INCLUDE_DIR}/cvodes ${SUNDIALS_INCLUDE_DIR}/nvector  ${SUNDIALS_INCLUDE_DIR}/sundials ${SUNDIALS_INCLUDE_DIR})
add_library(${SimulationSettings}_static STATIC GlobalSettings.cpp Factory.cpp FactoryExport.cpp)
set_target_properties(${SimulationSettings}_static PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")
#precompiled header only working for one build type at the moment. Precompiled header are activated for dynamic linking
#add_precompiled_header(${SimulationSettings}_static Include/Core/Modelica.h)
install (TARGETS ${SimulationSettings}_static DESTINATION ${LIBINSTALLEXT})

add_library(${SimulationSettings} SHARED GlobalSettings.cpp Factory.cpp FactoryExport.cpp)
target_link_libraries( ${SimulationSettings} ${OMCFactoryName}_static ${Boost_LIBRARIES})
add_precompiled_header(${SimulationSettings} Include/Core/Modelica.h)
install (TARGETS ${SimulationSettings} DESTINATION ${LIBINSTALLEXT})

install (FILES "config/GlobalSettings.xml" DESTINATION share/omc/runtime/cpp/config)
install (FILES 	${CMAKE_SOURCE_DIR}/Include/Core/SimulationSettings/IGlobalSettings.h
		${CMAKE_SOURCE_DIR}/Include/Core/SimulationSettings/ISettingsFactory.h
               	${CMAKE_SOURCE_DIR}/Include/Core/SimulationSettings/ISimControllerSettings.h
DESTINATION include/omc/cpp/Core/SimulationSettings)

install (FILES ${CMAKE_SOURCE_DIR}/Include/Core/SimulationSettings/Factory.h
DESTINATION include/omc/cpp/Core/SimulationSettings)




