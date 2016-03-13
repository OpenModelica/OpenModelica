cmake_minimum_required(VERSION 2.8.9)

project(${ModelicaUtilitiesName})
# add the solver default implementation library

add_library(${ModelicaUtilitiesName}_static STATIC ModelicaUtilities.cpp ModelicaSimulationError.cpp)
set_target_properties(${ModelicaUtilitiesName}_static PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")
add_library(${ModelicaUtilitiesName} SHARED ModelicaUtilities.cpp ModelicaSimulationError.cpp)
add_precompiled_header(${ModelicaUtilitiesName} Include/Core/Modelica.h )

target_link_libraries (${ModelicaUtilitiesName} ${Boost_LIBRARIES})
install (TARGETS ${ModelicaUtilitiesName}_static DESTINATION ${LIBINSTALLEXT})
install (TARGETS ${ModelicaUtilitiesName} DESTINATION ${LIBINSTALLEXT})

install (FILES ${CMAKE_SOURCE_DIR}/Include/Core/Utils/Modelica/ModelicaUtilities.h ${CMAKE_SOURCE_DIR}/Include/Core/Utils/Modelica/FactoryExport.h ${CMAKE_SOURCE_DIR}/Include/Core/Utils/Modelica/ModelicaSimulationError.h  DESTINATION include/omc/cpp/Core/Utils/Modelica)
