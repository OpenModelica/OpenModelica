cmake_minimum_required(VERSION 2.8.9)

project(${DgesvName})

IF(DGESV_FOUND)
  MESSAGE(STATUS "DGESV enabled")
  include_directories (${DGESV_INCLUDE_DIR})
  add_library(${DgesvName}_static STATIC ${DGESV_SRCS})
  install(TARGETS ${DgesvName}_static DESTINATION ${LIBINSTALLEXT})
  install(FILES ${DGESV_HEADERS} DESTINATION include/omc/cpp/Solver/Dgesv)
  GET_TARGET_PROPERTY(libDgesvLocation ${DgesvName}_static LOCATION)
  GET_FILENAME_COMPONENT(libDgesvExt ${libDgesvLocation} EXT CACHE)
ELSE()
  MESSAGE(STATUS "DGESV disabled")
ENDIF(DGESV_FOUND)

