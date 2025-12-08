cmake_minimum_required(VERSION 3.14)

set(OMC_SIMRT_UTIL_SOURCES
  utility.c
  list.c
  read_matlab4.c
  doubleEndedList.c
  libcsv.c
  modelica_string_lit.c
  read_write.c
  ringbuffer.c
  write_csv.c
  varinfo.c
  omc_numbers.c
  parallel_helper.c
  omc_mmap.c
  context.c
  rational.c
  ModelicaUtilities.c
  read_csv.c
  simulation_options.c
  tinymt64.c
  base_array.c
  omc_msvc.c
  boolean_array.c
  rtclock.c
  omc_file.c
  index_spec.c
  java_interface.c
  omc_init.c
  string_array.c
  modelica_string.c
  write_matlab4.c
  generic_array.c
  division.c
  OldModelicaTables.c
  real_array.c
  integer_array.c
  omc_error.c
)

set(OMC_SIMRT_UTIL_HEADERS
  java_interface.h
  ModelicaUtilitiesExtra.h
  tinymt64.h
  varinfo.h
  write_matlab4.h
  parallel_helper.h
  division.h
  uthash.h
  omc_init.h
  boolean_array.h
  modelica.h
  jni_md_solaris.h
  read_matlab4.h
  read_write.h
  integer_array.h
  read_csv.h
  jni_md_windows.h
  real_array.h
  simulation_options.h
  omc_spinlock.h
  base_array.h
  rtclock.h
  omc_file.h
  context.h
  utility.h
  omc_error.h
  jni_md.h
  modelica_string.h
  string_array.h
  omc_mmap.h
  ringbuffer.h
  omc_msvc.h
  generic_array.h
  omc_numbers.h
  index_spec.h
  doubleEndedList.h
  rational.h
  jni.h
  libcsv.h
  list.h
  write_csv.h
  modelica_string_lit.h
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
