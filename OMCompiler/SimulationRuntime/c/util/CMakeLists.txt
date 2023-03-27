# Sources and headers
SET(util_sources ../gc/memory_pool.c
                  base_array.c
                  boolean_array.c
                  context.c
                  division.c
                  doubleEndedList.c
                  index_spec.c
                  integer_array.c
                  java_interface.c
                  libcsv.c
                  list.c
                  modelica_string_lit.c
                  modelica_string.c
                  ModelicaUtilities.c
                  OldModelicaTables.c
                  omc_error.c
                  omc_file.c
                  omc_init.c
                  omc_mmap.c
                  omc_msvc.c
                  parallel_helper.c
                  rational.c
                  read_csv.c
                  read_matlab4.c
                  read_write.c
                  real_array.c
                  ringbuffer.c
                  rtclock.c
                  simulation_options.c
                  string_array.c
                  utility.c
                  varinfo.c
                  write_csv.c)


SET(util_headers ../gc/memory_pool.h
                 ../ModelicaUtilities.h
                 base_array.h
                 boolean_array.h
                 context.h
                 division.h
                 doubleEndedList.h
                 index_spec.h
                 integer_array.h
                 java_interface.h
                 jni_md_solaris.h
                 jni_md_windows.h
                 jni_md.h
                 jni.h
                 list.h
                 modelica_string_lit.h
                 modelica_string.h
                 modelica.h
                 omc_error.h
                 omc_file.h
                 omc_init.h write_csv.h
                 omc_mmap.h
                 parallel_helper.h
                 rational.h
                 read_matlab4.h
                 read_write.h
                 real_array.h
                 ringbuffer.h
                 rtclock.h
                 simulation_options.h
                 string_array.h
                 utility.h
                 varinfo.h)

if(MSVC)
    INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/OMCompiler/3rdParty/regex-0.12)
    SET(util_sources ${util_sources} ${OMCTRUNCHOME}/OMCompiler/3rdParty/regex-0.12/regex.c)
    SET(util_headers ${util_headers} ${OMCTRUNCHOME}/OMCompiler/3rdParty/regex-0.12/regex.h)
endif(MSVC)

# Library util
ADD_LIBRARY(util ${util_sources} ${util_headers})
#TARGET_LINK_LIBRARIES(util)

# Install
INSTALL(TARGETS util
    ARCHIVE DESTINATION lib/omc)

#INSTALL(FILES ${util_headers} DESTINATION include)
