cmake_minimum_required (VERSION 2.6)

project(${ModelicaExternalName})
include_directories (${MODELICAEXTERNALCDIR})
include_directories (${USERTABDIR})
add_library(${ModelicaExternalName}    ${MODELICAEXTERNALCDIR}/ModelicaStandardTables.c  ${MODELICAEXTERNALCDIR}/ModelicaMatIO.c ${MODELICAEXTERNALCDIR}/ModelicaInternal.c ${MODELICAEXTERNALCDIR}/ModelicaStrings.c ${USERTABDIR}/usertab.c)

install (TARGETS ${ModelicaExternalName} DESTINATION  lib/omc/${LIBINSTALLEXT})

#lib/omc/cpp
