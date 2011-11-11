# Quellen und Header
SET(util_sources  boolean_array.c index_spec.c integer_array.c memory_pool.c
                  base_array.c real_array.c string_array.c utility.c
				  modelica_string.c division.c
				  java_interface.c rtclock.c error.c)

SET(util_headers  base_array.h boolean_array.h division.h index_spec.h
				  integer_array.h java_interface.h jni.h jni_md.h 
				  jni_md_solaris.h jni_md_windows.h memory_pool.h 
				  modelica.h modelica_string.h real_array.h rtclock.h 
				  string_array.h utility.h error.h)				 
						 
# Library util
ADD_LIBRARY(util ${util_sources} ${util_headers})
#TARGET_LINK_LIBRARIES(util)

# Install
INSTALL(TARGETS util
		ARCHIVE DESTINATION lib)
		
INSTALL(FILES ${util_headers} DESTINATION include)
