# Sources and Headers
SET(META_SRC 	meta_modelica.c
				meta_modelica_builtin.c
				meta_modelica_catch.c
				meta_modelica_gc.c
				meta_modelica_gc_list.c
				meta_modelica_gc_pages.c
				meta_modelica_gc_roots.c
				meta_modelica_gc_settings.c
				meta_modelica_gc_stack.c
				meta_modelica_gc_stats.c
				meta_modelica_string_lit.c)

SET(META_SRC_CPP meta_modelica_real.cpp)

SET(META_HFILES meta_modelica.h
				meta_modelica_builtin.h
				meta_modelica_builtin_boxptr.h
				meta_modelica_gc.h
				meta_modelica_gc_list.h
				meta_modelica_gc_pages.h
				meta_modelica_gc_roots.h
				meta_modelica_gc_settings.h
				meta_modelica_gc_stack.h
				meta_modelica_gc_stats.h
				meta_modelica_string_lit.h
				meta_modelica_real.h
				rml_compatibility.h) 


# Library meta
add_library(meta_cpp  ${META_SRC_CPP} ${META_HFILES})
add_library(meta  ${META_SRC} ${META_HFILES})
TARGET_LINK_LIBRARIES(meta meta_cpp)
#set_property(TARGET f2c PROPERTY PREFIX lib)

# Install
INSTALL(TARGETS meta meta_cpp
		ARCHIVE DESTINATION meta)
INSTALL(FILES ${META_HFILES} DESTINATION include/meta)
		
