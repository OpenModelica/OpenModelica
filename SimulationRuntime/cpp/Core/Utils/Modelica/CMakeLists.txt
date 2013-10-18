cmake_minimum_required (VERSION 2.6)

project(${ModelicaUtilitiesName})
# add the solver default implementation library
add_library(${ModelicaUtilitiesName} STATIC ModelicaUtilities.cpp)
if (UNIX)
set_target_properties(${ModelicaUtilitiesName} PROPERTIES COMPILE_FLAGS -fPIC)
endif(UNIX)

install (TARGETS ${ModelicaUtilitiesName} DESTINATION lib/omc/${LIBINSTALLEXT})

install (FILES ${CMAKE_SOURCE_DIR}/Include/Core/Utils/Modelica/ModelicaUtilities.h
          DESTINATION include/omc/cpp/Core/Utils/Modelica)

