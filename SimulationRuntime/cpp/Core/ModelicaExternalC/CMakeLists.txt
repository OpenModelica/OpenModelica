cmake_minimum_required (VERSION 2.8.6)
project(${ModelicaExternalName})
ADD_DEFINITIONS(-DDUMMY_FUNCTION_USERTAB)
include_directories (${MODELICAEXTERNALCDIR})
# include_directories (${USERTABDIR})
add_library(${ModelicaExternalName}    ${MODELICAEXTERNALCDIR}/ModelicaStandardTables.c  ${MODELICAEXTERNALCDIR}/ModelicaMatIO.c ${MODELICAEXTERNALCDIR}/ModelicaInternal.c ${MODELICAEXTERNALCDIR}/ModelicaStrings.c) #  ${USERTABDIR}/usertab.c
add_library(${ModelicaTablesName}    ${MODELICAEXTERNALCDIR}/ModelicaStandardTables.c  ${MODELICAEXTERNALCDIR}/ModelicaMatIO.c) #  ${USERTABDIR}/usertab.c
if (UNIX)
set_target_properties(${ModelicaExternalName} PROPERTIES COMPILE_FLAGS -fPIC)
set_target_properties(${ModelicaTablesName} PROPERTIES COMPILE_FLAGS -fPIC)
endif(UNIX)
install (TARGETS ${ModelicaExternalName} DESTINATION  ${LIBINSTALLEXT})
install (TARGETS ${ModelicaTablesName} DESTINATION  ${LIBINSTALLEXT})
#lib/omc/cpp
