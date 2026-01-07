cmake_minimum_required(VERSION 3.14)

set(OMC_SIMRT_MOO_SOURCES
  "debug.cpp"
  "evaluations.cpp"
  "hessian_finite_diff.cpp"
  "info.cpp"
  "main_opt.cpp"
  "problem.cpp"
  "strategies.cpp"
  "streamlog.cpp"
)
set(OMC_SIMRT_MOO_HEADERS
  "debug.h"
  "evaluations.h"
  "hessian_finite_diff.h"
  "info.h"
  "problem.h"
  "strategies.h"
  "streamlog.h"
)

add_library(OpenModelicaRuntimeCMoo OBJECT ${OMC_SIMRT_MOO_SOURCES})
add_library(omc::simrt::simruntime::moo ALIAS OpenModelicaRuntimeCMoo)

target_include_directories(OpenModelicaRuntimeCMoo
  PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/c/moo>
)

target_link_libraries(OpenModelicaRuntimeCMoo
  PUBLIC
    omc::config
    omc::simrt::runtime::headers
    omc::3rd::moo
)

target_compile_definitions(OpenModelicaRuntimeCMoo PUBLIC OMC_HAVE_MOO)

# Install headers
install(
  FILES ${OMC_SIMRT_MOO_HEADERS}
  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/c/moo)
