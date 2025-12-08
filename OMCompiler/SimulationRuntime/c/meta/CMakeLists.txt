cmake_minimum_required(VERSION 3.14)

set(OMC_SIMRT_META_SOURCES
  realString.c
  meta_modelica_segv.c
  meta_modelica.c
  meta_modelica_catch.c
  meta_modelica_builtin.c
)
set(OMC_SIMRT_META_HEADERS
  meta_modelica.h
  meta_modelica_segv.h
  meta_modelica_data.h
  meta_modelica_builtin_boxptr.h
  meta_modelica_builtin.h
  meta_modelica_builtin_boxvar.h
  meta_modelica_mk_box.h
)

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
