MSLCSOURCES=../../../libraries/Modelica\ 3.2.1/Modelica/Resources/C-Sources/
lib_LTLIBRARIES = libModelicaExternalC.la libModelicaStandardTables.la
libModelicaExternalC_la_SOURCES = $(MSLCSOURCES)/ModelicaInternal.c $(MSLCSOURCES)/ModelicaStrings.c $(MSLCSOURCES)/ModelicaStandardTables.c $(MSLCSOURCES)/ModelicaMatIO.c ModelicaTablesImpl.c tables.c
libModelicaStandardTables_la_SOURCES = 
libModelicaStandardTables_la_LIBADD = libModelicaExternalC.la
