# Quellen und Header
SET(util_sources  base_array.c boolean_array.c omc_error.c division.c index_spec.c
 				  integer_array.c java_interface.c list.c memory_pool.c modelica_string.c
				  read_write.c read_matlab4.c real_array.c ringbuffer.c
				  rtclock.c simulation_options.c string_array.c utility.c varinfo.c omc_msvc.c OldModelicaTables.c)


SET(util_headers  base_array.h boolean_array.h division.h omc_error.h index_spec.h integer_array.h
                  java_interface.h jni.h jni_md.h jni_md_solaris.h jni_md_windows.h list.h memory_pool.h
				  modelica.h modelica_string.h read_write.h read_matlab4.h real_array.h
				  ringbuffer.h rtclock.h simulation_options.h string_array.h utility.h varinfo.h)

if(MSVC)
    INCLUDE_DIRECTORIES(${OMCTRUNCHOME}/3rdParty/regex-0.12)
    SET(util_sources ${util_sources} ${OMCTRUNCHOME}/3rdParty/regex-0.12/regex.c)
    SET(util_headers ${util_headers} ${OMCTRUNCHOME}/3rdParty/regex-0.12/regex.h)
endif(MSVC)

# Library util
ADD_LIBRARY(util ${util_sources} ${util_headers})
#TARGET_LINK_LIBRARIES(util)

# Install
INSTALL(TARGETS util
		ARCHIVE DESTINATION lib/omc)

#INSTALL(FILES ${util_headers} DESTINATION include)
