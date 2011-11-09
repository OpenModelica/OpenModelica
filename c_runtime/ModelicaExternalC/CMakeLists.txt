# Sources and Headers
set(ModelicaExternalC_sources ModelicaInternal.c 
                              ModelicaStrings.c 
							  ModelicaTablesImpl.c)

SET(ModelicaExternalC_headers ModelicaTables.h) 

# Library ModelicaExternalC
add_library(ModelicaExternalC  ${ModelicaExternalC_sources} ${ModelicaExternalC_headers})

# Install
INSTALL(TARGETS ModelicaExternalC
		ARCHIVE DESTINATION lib)
INSTALL(FILES f2c.h DESTINATION include)
		
