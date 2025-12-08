cmake_minimum_required(VERSION 3.14)

# Define sources with a local glob
file(GLOB OMC_SIMRT_GC_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/*.c)
file(GLOB OMC_SIMRT_GC_HEADERS ${CMAKE_CURRENT_SOURCE_DIR}/*.h)

add_library(OpenModelicaRuntimeCGC OBJECT ${OMC_SIMRT_GC_SOURCES})
add_library(omc::simrt::runtime::gc ALIAS OpenModelicaRuntimeCGC)

target_include_directories(OpenModelicaRuntimeCGC
  PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/c/gc>
)

target_link_libraries(OpenModelicaRuntimeCGC
  PUBLIC
    omc::3rd::omcgc
)

# Install headers
install(
  FILES ${OMC_SIMRT_GC_HEADERS}
  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/c/gc)
