cmake_minimum_required(VERSION 3.14)

set(OMC_SIMRT_GC_SOURCES
  "omc_alloc.c"
  "omc_rc.c"
  "omc_gc.c"
)
set(OMC_SIMRT_GC_HEADERS
  "omc_alloc.h"
  "omc_rc.h"
  "omc_gc.h"
)

add_library(OpenModelicaRuntimeCGC OBJECT ${OMC_SIMRT_GC_SOURCES})
add_library(omc::simrt::runtime::gc ALIAS OpenModelicaRuntimeCGC)

target_include_directories(OpenModelicaRuntimeCGC
  PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/c/gc>
    # omc_gc.h pulls "omc_dll.h" + "omc_inline.h" + "util/omc_msvc.h" (all
    # under c/) on _MSC_VER.
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/..>
)

target_link_libraries(OpenModelicaRuntimeCGC
  PUBLIC
    omc::simrt::runtime::headers
)

# Install headers
install(
  FILES ${OMC_SIMRT_GC_HEADERS}
  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/c/gc)

# The same sources for the MetaModelica runtime, on Boehm.
add_library(OpenModelicaRuntimeCGCMMC OBJECT ${OMC_SIMRT_GC_SOURCES})
add_library(omc::mmc::gc ALIAS OpenModelicaRuntimeCGCMMC)
target_compile_definitions(OpenModelicaRuntimeCGCMMC PUBLIC OMC_METAMODELICA_RUNTIME=1)
set_target_properties(OpenModelicaRuntimeCGCMMC PROPERTIES POSITION_INDEPENDENT_CODE ON)
target_include_directories(OpenModelicaRuntimeCGCMMC PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/..>)
target_link_libraries(OpenModelicaRuntimeCGCMMC PUBLIC omc::3rd::omcgc OMCPThreads::OMCPThreads)
