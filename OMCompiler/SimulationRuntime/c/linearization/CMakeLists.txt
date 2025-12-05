cmake_minimum_required(VERSION 3.14)

# Define sources with a local glob
file(GLOB OMC_SIMRT_LINEARIZATION_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/*.cpp)
file(GLOB OMC_SIMRT_LINEARIZATION_HEADERS ${CMAKE_CURRENT_SOURCE_DIR}/*.h)

add_library(OpenModelicaRuntimeCLinearization OBJECT ${OMC_SIMRT_LINEARIZATION_SOURCES})
add_library(omc::simrt::simruntime::linearization ALIAS OpenModelicaRuntimeCLinearization)

target_include_directories(OpenModelicaRuntimeCLinearization
  PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
)

target_link_libraries(OpenModelicaRuntimeCLinearization
  PUBLIC
    omc::simrt::runtime::headers
)

# Install headers
install(
  FILES ${OMC_SIMRT_LINEARIZATION_HEADERS}
  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/SimulationRuntime/c/linearization)
