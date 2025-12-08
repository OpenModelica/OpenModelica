cmake_minimum_required(VERSION 3.14)

# Define sources with a local glob
file(GLOB OMC_SIMRT_META_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/*.c)
file(GLOB OMC_SIMRT_META_HEADERS ${CMAKE_CURRENT_SOURCE_DIR}/*.h)

add_library(OpenModelicaRuntimeCMeta OBJECT ${OMC_SIMRT_META_SOURCES})
add_library(omc::simrt::runtime::meta ALIAS OpenModelicaRuntimeCMeta)

target_include_directories(OpenModelicaRuntimeCMeta
  PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/c/meta>
)

target_link_libraries(OpenModelicaRuntimeCMeta
  PUBLIC
    omc::simrt::runtime::headers
    omc::3rd::ryu
)

# Install headers
install(
  FILES ${OMC_SIMRT_META_HEADERS}
  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/c/meta)
