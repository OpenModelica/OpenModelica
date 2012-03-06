# Quellen und Header
SET(util_sources  base_array.c boolean_array.c division.c error.c index_spec.c
                  integer_array.c java_interface.c list.c memory_pool.c modelica_string.c
				  modelinfo.c read_write.c real_array.c ringbuffer.c rtclock.c
				  string_array.c utility.c varinfo.c read_matlab4.c)

SET(util_headers  base_array.h boolean_array.h division.h index_spec.h error.h
				  index_spec.h integer_array.h java_interface.h jni.h jni_md.h 
				  jni_md_solaris.h jni_md_windows.h list.h memory_pool.h 
				  modelica.h modelica_string.h modelinfo.h read_write.h real_array.h
				  rtclock.h string_array.h utility.h varinfo.h read_matlab4.h)				 
						 
# Library util
ADD_LIBRARY(util ${util_sources} ${util_headers})
#TARGET_LINK_LIBRARIES(util)

# Install
INSTALL(TARGETS util
		ARCHIVE DESTINATION lib)
		
INSTALL(FILES ${util_headers} DESTINATION include)
