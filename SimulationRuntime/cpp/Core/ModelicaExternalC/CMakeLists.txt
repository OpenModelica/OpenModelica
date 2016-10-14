cmake_minimum_required(VERSION 2.8.9)

project(${ModelicaExternalName})

add_library(${ModelicaExternalName} STATIC ${MODELICAEXTERNALCDIR}/ModelicaStandardTables.c ${MODELICAEXTERNALCDIR}/ModelicaMatIO.c ${MODELICAEXTERNALCDIR}/ModelicaInternal.c ${MODELICAEXTERNALCDIR}/ModelicaStrings.c) #  ${USERTABDIR}/usertab.c

add_library(${ModelicaTablesName} STATIC ${MODELICAEXTERNALCDIR}/ModelicaStandardTables.c ${MODELICAEXTERNALCDIR}/ModelicaMatIO.c) #  ${USERTABDIR}/usertab.c

add_library(${ModelicaMatIOName} STATIC ${MODELICAEXTERNALCDIR}/ModelicaIO.c ) #
add_library(${LibZName} STATIC ${MODELICAEXTERNALCDIR}/zlib/adler32.c ${MODELICAEXTERNALCDIR}/zlib/compress.c ${MODELICAEXTERNALCDIR}/zlib/crc32.c ${MODELICAEXTERNALCDIR}/zlib/deflate.c ${MODELICAEXTERNALCDIR}/zlib/gzclose.c ${MODELICAEXTERNALCDIR}/zlib/gzlib.c ${MODELICAEXTERNALCDIR}/zlib/gzread.c ${MODELICAEXTERNALCDIR}/zlib/gzwrite.c ${MODELICAEXTERNALCDIR}/zlib/infback.c ${MODELICAEXTERNALCDIR}/zlib/inffast.c ${MODELICAEXTERNALCDIR}/zlib/inflate.c ${MODELICAEXTERNALCDIR}/zlib/inftrees.c ${MODELICAEXTERNALCDIR}/zlib/trees.c ${MODELICAEXTERNALCDIR}/zlib/uncompr.c ${MODELICAEXTERNALCDIR}/zlib/zutil.c ) #

add_definitions(-DDUMMY_FUNCTION_USERTAB)
include_directories(${MODELICAEXTERNALCDIR})
# include_directories (${USERTABDIR})

install(TARGETS ${ModelicaExternalName} DESTINATION ${LIBINSTALLEXT})
install(TARGETS ${ModelicaTablesName} DESTINATION ${LIBINSTALLEXT})
install(TARGETS ${ModelicaMatIOName} DESTINATION ${LIBINSTALLEXT})
install(TARGETS ${LibZName} DESTINATION ${LIBINSTALLEXT})
#lib/omc/cpp
