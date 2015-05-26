cmake_minimum_required (VERSION 2.8.6)

project(${ModelicaExternalName})
include_directories (${MODELICAEXTERNALCDIR})
include_directories (${USERTABDIR})
add_library(${ModelicaExternalName}    ${MODELICAEXTERNALCDIR}/ModelicaStandardTables.c  ${MODELICAEXTERNALCDIR}/ModelicaMatIO.c ${MODELICAEXTERNALCDIR}/ModelicaInternal.c ${MODELICAEXTERNALCDIR}/ModelicaStrings.c )
# Note: usertab.c cannot be gotten from OMLibraries, since they are not included in OMCompiler.git
#   usertab.c is not a part of ModelicaStandardTables, etc anyway
#   usertab.c is also a dummy implementation that the user is supposed to provide in some cases. It is not supposed to be compiled.
add_library(${ModelicaTablesName}    ${MODELICAEXTERNALCDIR}/ModelicaStandardTables.c  ${MODELICAEXTERNALCDIR}/ModelicaMatIO.c )
if (UNIX)
set_target_properties(${ModelicaExternalName} PROPERTIES COMPILE_FLAGS -fPIC)
set_target_properties(${ModelicaTablesName} PROPERTIES COMPILE_FLAGS -fPIC)
endif(UNIX)
install (TARGETS ${ModelicaExternalName} DESTINATION  ${LIBINSTALLEXT})
install (TARGETS ${ModelicaTablesName} DESTINATION  ${LIBINSTALLEXT})
#lib/omc/cpp
