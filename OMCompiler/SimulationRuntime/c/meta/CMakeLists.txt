cmake_minimum_required(VERSION 3.14)

set(OMC_MMC_SOURCES
  "meta_modelica_builtin.c"
  "meta_modelica_catch.c"
  "meta_modelica_segv.c"
  "meta_modelica.c"
  "java_interface.c"
  "meta_modelica_string_lit.c"
  "realString.c"
)
set(OMC_MMC_HEADERS
  "java_interface.h"
  "meta_modelica_string_lit.h"
  "meta_modelica_string.h"
  "meta_modelica_builtin_boxptr.h"
  "meta_modelica_builtin_boxvar.h"
  "meta_modelica_builtin.h"
  "meta_modelica_data.h"
  "meta_modelica_mk_box.h"
  "meta_modelica_segv.h"
  "meta_modelica.h"
)

# Shared, so a MetaModelica function library dlopened into omc uses omc's
# globals (the error buffer, the assert handlers).
add_library(OpenModelicaRuntimeMMC SHARED ${OMC_MMC_SOURCES}
  $<TARGET_OBJECTS:OpenModelicaRuntimeCUtilMMC>
  $<TARGET_OBJECTS:OpenModelicaRuntimeCGCMMC>)
add_library(omc::mmc::runtime ALIAS OpenModelicaRuntimeMMC)

if(MINGW)
  target_link_libraries(OpenModelicaRuntimeMMC PUBLIC dbghelp)
  target_link_options(OpenModelicaRuntimeMMC PRIVATE -Wl,--export-all-symbols)
elseif(MSVC)
  set_target_properties(OpenModelicaRuntimeMMC PROPERTIES WINDOWS_EXPORT_ALL_SYMBOLS true)
endif()

target_compile_definitions(OpenModelicaRuntimeMMC PUBLIC OMC_METAMODELICA_RUNTIME=1)

target_include_directories(OpenModelicaRuntimeMMC
  PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/../util
  PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/c/meta>
)

target_link_libraries(OpenModelicaRuntimeMMC
  PUBLIC
    omc::3rd::omcgc
    OMCPThreads::OMCPThreads
    omc::simrt::runtime::headers
    omc::3rd::ryu
)

# The parent's add_link_options(--coverage) does not reach whoever links these
# instrumented objects (bomc, omc), so hand it on.
if(OM_ENABLE_COVERAGE)
  target_link_options(OpenModelicaRuntimeMMC PUBLIC --coverage)
endif()

install(TARGETS OpenModelicaRuntimeMMC
  COMPONENT omc)

# Install headers
install(
  FILES ${OMC_MMC_HEADERS}
  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/c/meta)
