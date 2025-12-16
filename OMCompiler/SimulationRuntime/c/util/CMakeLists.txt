cmake_minimum_required(VERSION 3.14)

set(OMC_SIMRT_UTIL_SOURCES
  "base_array.c"
  "boolean_array.c"
  "context.c"
  "division.c"
  "doubleEndedList.c"
  "generic_array.c"
  "index_spec.c"
  "integer_array.c"
  "java_interface.c"
  "libcsv.c"
  "list.c"
  "modelica_string_lit.c"
  "modelica_string.c"
  "ModelicaUtilities.c"
  "OldModelicaTables.c"
  "omc_error.c"
  "omc_file.c"
  "omc_init.c"
  "omc_mmap.c"
  "omc_msvc.c"
  "omc_numbers.c"
  "parallel_helper.c"
  "rational.c"
  "read_csv.c"
  "read_matlab4.c"
  "read_write.c"
  "real_array.c"
  "ringbuffer.c"
  "rtclock.c"
  "simulation_options.c"
  "string_array.c"
  "tinymt64.c"
  "utility.c"
  "varinfo.c"
  "write_csv.c"
  "write_matlab4.c"
)

set(OMC_SIMRT_UTIL_HEADERS
  "base_array.h"
  "boolean_array.h"
  "context.h"
  "division.h"
  "doubleEndedList.h"
  "generic_array.h"
  "index_spec.h"
  "integer_array.h"
  "java_interface.h"
  "jni_md_solaris.h"
  "jni_md_windows.h"
  "jni_md.h"
  "jni.h"
  "libcsv.h"
  "list.h"
  "modelica_string_lit.h"
  "modelica_string.h"
  "modelica.h"
  "ModelicaUtilitiesExtra.h"
  "omc_error.h"
  "omc_file.h"
  "omc_init.h"
  "omc_mmap.h"
  "omc_msvc.h"
  "omc_numbers.h"
  "omc_spinlock.h"
  "parallel_helper.h"
  "rational.h"
  "read_csv.h"
  "read_matlab4.h"
  "read_write.h"
  "real_array.h"
  "ringbuffer.h"
  "rtclock.h"
  "simulation_options.h"
  "string_array.h"
  "tinymt64.h"
  "uthash.h"
  "utility.h"
  "varinfo.h"
  "write_csv.h"
  "write_matlab4.h"
)

add_library(OpenModelicaRuntimeCUtil OBJECT ${OMC_SIMRT_UTIL_SOURCES})
add_library(omc::simrt::runtime::util ALIAS OpenModelicaRuntimeCUtil)

target_include_directories(OpenModelicaRuntimeCUtil
  PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/c/util>
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
  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/c/util)
