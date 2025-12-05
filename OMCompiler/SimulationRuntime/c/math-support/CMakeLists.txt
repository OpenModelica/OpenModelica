cmake_minimum_required(VERSION 3.14)

# Define sources
set(OMC_SIMRT_MATH_SUPPORT_SOURCES
  pivot.c)

add_library(OpenModelicaRuntimeCMathSupport OBJECT ${OMC_SIMRT_MATH_SUPPORT_SOURCES})
add_library(omc::simrt::simruntime::math-support ALIAS OpenModelicaRuntimeCMathSupport)

target_include_directories(OpenModelicaRuntimeCMathSupport
  PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
)

target_link_libraries(OpenModelicaRuntimeCMathSupport
  PUBLIC
    omc::simrt::runtime::headers
)
