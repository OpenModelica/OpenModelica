cmake_minimum_required (VERSION 2.8.6)

project(${ModelicaUtilitiesName})
# add the solver default implementation library

IF(RUNTIME_STATIC_LINKING)
	add_library(${ModelicaUtilitiesName} STATIC ModelicaUtilities.cpp ModelicaSimulationError.cpp)
ELSE(RUNTIME_STATIC_LINKING)
	add_library(${ModelicaUtilitiesName} SHARED ModelicaUtilities.cpp ModelicaSimulationError.cpp)
    add_precompiled_header(${ModelicaUtilitiesName} Include/Core/Modelica.h )
ENDIF(RUNTIME_STATIC_LINKING)

if (UNIX)
set_target_properties(${ModelicaUtilitiesName} PROPERTIES COMPILE_FLAGS -fPIC)
endif(UNIX)
target_link_libraries (${ModelicaUtilitiesName} ${Boost_LIBRARIES})
install (TARGETS ${ModelicaUtilitiesName} DESTINATION ${LIBINSTALLEXT})

install (FILES ${CMAKE_SOURCE_DIR}/Include/Core/Utils/Modelica/ModelicaUtilities.h ${CMAKE_SOURCE_DIR}/Include/Core/Utils/Modelica/FactoryExport.h ${CMAKE_SOURCE_DIR}/Include/Core/Utils/Modelica/ModelicaSimulationError.h  DESTINATION include/omc/cpp/Core/Utils/Modelica)