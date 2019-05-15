# Build default ModelicaExternalC libs (without extra flags like HAVE_HDF5).
# Note: zlib is only here because it is referred to from MSL Tables and
# thus passed to the linker. It is not used by default ModelicaMatIO though.

cmake_minimum_required(VERSION 2.8.9)
project(${ModelicaExternalName})

include_directories(${MODELICAEXTERNALCDIR})
add_definitions(-DDUMMY_FUNCTION_USERTAB) # yet an extra flag

add_library(${ModelicaExternalName} STATIC ${MODELICAEXTERNALCDIR}/ModelicaFFT.c ${MODELICAEXTERNALCDIR}/ModelicaInternal.c ${MODELICAEXTERNALCDIR}/ModelicaRandom.c ${MODELICAEXTERNALCDIR}/ModelicaStrings.c)
add_library(${ModelicaTablesName} STATIC ${MODELICAEXTERNALCDIR}/ModelicaStandardTables.c)
add_library(${ModelicaIOName} STATIC ${MODELICAEXTERNALCDIR}/ModelicaIO.c)
add_library(${ModelicaMatIOName} STATIC ${MODELICAEXTERNALCDIR}/ModelicaMatIO.c)
add_library(${LibZName} STATIC ${MODELICAEXTERNALCDIR}/zlib/adler32.c ${MODELICAEXTERNALCDIR}/zlib/compress.c ${MODELICAEXTERNALCDIR}/zlib/crc32.c ${MODELICAEXTERNALCDIR}/zlib/deflate.c ${MODELICAEXTERNALCDIR}/zlib/gzclose.c ${MODELICAEXTERNALCDIR}/zlib/gzlib.c ${MODELICAEXTERNALCDIR}/zlib/gzread.c ${MODELICAEXTERNALCDIR}/zlib/gzwrite.c ${MODELICAEXTERNALCDIR}/zlib/infback.c ${MODELICAEXTERNALCDIR}/zlib/inffast.c ${MODELICAEXTERNALCDIR}/zlib/inflate.c ${MODELICAEXTERNALCDIR}/zlib/inftrees.c ${MODELICAEXTERNALCDIR}/zlib/trees.c ${MODELICAEXTERNALCDIR}/zlib/uncompr.c ${MODELICAEXTERNALCDIR}/zlib/zutil.c)

install(TARGETS ${ModelicaExternalName} DESTINATION ${LIBINSTALLEXT})
install(TARGETS ${ModelicaTablesName} DESTINATION ${LIBINSTALLEXT})
install(TARGETS ${ModelicaIOName} DESTINATION ${LIBINSTALLEXT})
install(TARGETS ${ModelicaMatIOName} DESTINATION ${LIBINSTALLEXT})
install(TARGETS ${LibZName} DESTINATION ${LIBINSTALLEXT})
