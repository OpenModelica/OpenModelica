cmake_minimum_required(VERSION 2.8.9)
project(${ModelicaExternalName})
ADD_DEFINITIONS(-DDUMMY_FUNCTION_USERTAB)
include_directories (${MODELICAEXTERNALCDIR})
# include_directories (${USERTABDIR})

add_library(${ModelicaExternalName} STATIC ${MODELICAEXTERNALCDIR}/ModelicaStandardTables.c  ${MODELICAEXTERNALCDIR}/ModelicaMatIO.c ${MODELICAEXTERNALCDIR}/ModelicaInternal.c ${MODELICAEXTERNALCDIR}/ModelicaStrings.c) #  ${USERTABDIR}/usertab.c
add_library(${ModelicaTablesName} STATIC ${MODELICAEXTERNALCDIR}/ModelicaStandardTables.c  ${MODELICAEXTERNALCDIR}/ModelicaMatIO.c) #  ${USERTABDIR}/usertab.c

install (TARGETS ${ModelicaExternalName} DESTINATION  ${LIBINSTALLEXT})
install (TARGETS ${ModelicaTablesName} DESTINATION  ${LIBINSTALLEXT})
#lib/omc/cpp
