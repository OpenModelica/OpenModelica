# Sources and Headers
set(ModelicaExternalC_sources ModelicaInternal.c
                              ModelicaStrings.c
							  ModelicaTablesImpl.c
							  ../util/ModelicaUtilities.c
							  tables.c)
							  #win32_dirent.c)

SET(ModelicaExternalC_headers ModelicaTables.h
                              ../util/ModelicaUtilities.h
							  tables.h)

# Library ModelicaExternalC
add_library(ModelicaExternalC  ${ModelicaExternalC_sources} ${ModelicaExternalC_headers})

# Install
INSTALL(TARGETS ModelicaExternalC
		ARCHIVE DESTINATION lib/omc)
#INSTALL(FILES ${ModelicaExternalC_headers} DESTINATION include)

