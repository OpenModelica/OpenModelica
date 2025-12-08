cmake_minimum_required(VERSION 3.14)

# Define sources with a recursive glob
file(GLOB_RECURSE OMC_SIMRT_OPTIMIZATION_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/*.c)
file(GLOB_RECURSE OMC_SIMRT_OPTIMIZATION_HEADERS ${CMAKE_CURRENT_SOURCE_DIR}/*.h)

add_library(OpenModelicaRuntimeCOptimization OBJECT ${OMC_SIMRT_OPTIMIZATION_SOURCES})
add_library(omc::simrt::simruntime::optimization ALIAS OpenModelicaRuntimeCOptimization)

target_include_directories(OpenModelicaRuntimeCOptimization
  PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/c/optimization>
)

target_link_libraries(OpenModelicaRuntimeCOptimization
  PUBLIC
    omc::config
    omc::simrt::runtime::headers
    omc::3rd::ipopt
)

target_compile_definitions(OpenModelicaRuntimeCOptimization PUBLIC OMC_HAVE_IPOPT)

# Install headers
install(
  FILES ${OMC_SIMRT_OPTIMIZATION_HEADERS}
  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/c/optimization)
