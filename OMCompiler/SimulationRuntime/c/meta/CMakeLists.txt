# Sources and Headers
SET(META_SRC 	meta_modelica_builtin.c
				realString.c
				meta_modelica_catch.c
				meta_modelica.c
				meta_modelica_segv.c
				../gc/omc_gc.c)

SET(META_HFILES meta_modelica_builtin.h
				meta_modelica_builtin_boxptr.h
				meta_modelica_segv.h
				meta_modelica.h
				meta_modelica_data.h
				meta_modelica_mk_box.h
				meta_modelica_segv.h
				../gc/omc_gc.h)


# Library meta
add_library(meta  ${META_SRC} ${META_HFILES})
#set_property(TARGET f2c PROPERTY PREFIX lib)

# Install
INSTALL(TARGETS meta
		ARCHIVE DESTINATION lib/omc)
#INSTALL(FILES ${META_HFILES} DESTINATION include/meta)

