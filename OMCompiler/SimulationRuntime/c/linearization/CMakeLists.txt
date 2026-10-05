cmake_minimum_required(VERSION 3.14)

set(OMC_SIMRT_LINEARIZATION_SOURCES
  "linearize.cpp"
)
set(OMC_SIMRT_LINEARIZATION_HEADERS
  "linearize.h"
)

# Install headers
install(
  FILES ${OMC_SIMRT_LINEARIZATION_HEADERS}
  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/c/linearization)

if(NOT OM_OMC_ENABLE_C_OLD_RUNTIME)
  return()
endif()

add_library(OpenModelicaRuntimeCLinearization OBJECT ${OMC_SIMRT_LINEARIZATION_SOURCES})
add_library(omc::simrt::simruntime::linearization ALIAS OpenModelicaRuntimeCLinearization)

target_include_directories(OpenModelicaRuntimeCLinearization
  PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/c/linearization>
)

target_link_libraries(OpenModelicaRuntimeCLinearization
  PUBLIC
    omc::simrt::runtime::headers
)
