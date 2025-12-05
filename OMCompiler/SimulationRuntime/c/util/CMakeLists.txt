cmake_minimum_required(VERSION 3.14)

# Define sources with a local glob
file(GLOB OMC_SIMRT_UTIL_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/*.c)
file(GLOB OMC_SIMRT_UTIL_HEADERS ${CMAKE_CURRENT_SOURCE_DIR}/*.h)

add_library(OpenModelicaRuntimeCUtil OBJECT ${OMC_SIMRT_UTIL_SOURCES})
add_library(omc::simrt::runtime::util ALIAS OpenModelicaRuntimeCUtil)

target_include_directories(OpenModelicaRuntimeCUtil
  PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
)

target_link_libraries(OpenModelicaRuntimeCUtil
  PUBLIC omc::simrt::runtime::headers
)

if(MINGW)
  target_link_libraries(OpenModelicaRuntimeCUtil PUBLIC regex)
elseif(MSVC)
  target_link_libraries(OpenModelicaRuntimeCUtil PUBLIC omc::3rd::regex)
endif()

# Install headers
install(
  FILES ${OMC_SIMRT_UTIL_HEADERS}
  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/SimulationRuntime/c/util)
