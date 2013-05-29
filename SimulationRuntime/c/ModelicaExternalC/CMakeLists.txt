# Sources and Headers
set(ModelicaExternalC_sources ./../../../libraries/Modelica\ 3.2.1/Modelica/Resources/C-Sources/ModelicaInternal.c
                              ./../../../libraries/Modelica\ 3.2.1/Modelica/Resources/C-Sources/ModelicaStrings.c
							  ./../../../libraries/Modelica\ 3.2.1/Modelica/Resources/C-Sources/ModelicaMatIO.c
							  ./../../../libraries/Modelica\ 3.2.1/Modelica/Resources/C-Sources/ModelicaStandardTables.c
							  ./../../../libraries/Modelica\ 3.2.1/Modelica/Resources/C-Sources/win32_dirent.c
							  ModelicaTablesImpl.c
							  ../util/ModelicaUtilities.c
							  tables.c)

SET(ModelicaExternalC_headers ModelicaTables.h
                              ../util/ModelicaUtilities.h
							  tables.h)

# Library ModelicaExternalC
add_library(ModelicaExternalC  ${ModelicaExternalC_sources} ${ModelicaExternalC_headers})

# Install
INSTALL(TARGETS ModelicaExternalC
		ARCHIVE DESTINATION lib/omc)
#INSTALL(FILES ${ModelicaExternalC_headers} DESTINATION include)

