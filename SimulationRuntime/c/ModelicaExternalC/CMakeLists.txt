# Sources and Headers
set(ModelicaExternalC_sources ModelicaInternal.c
                              ModelicaStrings.c 
							  ModelicaTablesImpl.c
							  ModelicaUtilities.c
							  tables.c)
							  #win32_dirent.c)

SET(ModelicaExternalC_headers ModelicaTables.h
                              ModelicaUtilities.h
							  tables.h) 

# Library ModelicaExternalC
add_library(ModelicaExternalC  ${ModelicaExternalC_sources} ${ModelicaExternalC_headers})

# Install
INSTALL(TARGETS ModelicaExternalC
		ARCHIVE DESTINATION lib)
INSTALL(FILES f2c.h DESTINATION include)
		
