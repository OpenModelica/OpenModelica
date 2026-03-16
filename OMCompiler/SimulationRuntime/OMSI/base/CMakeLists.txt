cmake_minimum_required(VERSION 3.5)
#OMSI base simulation runtime
PROJECT(OMSIBASE)
SET(CMAKE_VERBOSE_MAKEFILE ON)

# Set exapat lib for visual studio compiler
# TODO: This relies on the static expat libexpat.a on MSVC but it's only build for mingw target!
IF(MSVC)
  INCLUDE_DIRECTORIES($ENV{OMDEV}/lib/expat-win32-msvc)
  FIND_LIBRARY(LIB_EXPAT NAMES expat libexpat PATHS ${OMBUILDDIR}/lib/omc ${OMBUILDDIR}/lib/omc/msvc ${CMAKE_SOURCE_DIR}/../../3rdParty/FMIL/build/ExpatEx/ $ENV{OMDEV}/lib/expat-win32-msvc $ENV{OMDEV}/lib/lapack-win32-msvc)
ELSE(MSVC)
  FIND_LIBRARY(LIB_EXPAT NAMES expat libexpat PATHS ${OMBUILDDIR}/lib/omc ${CMAKE_SOURCE_DIR}/../../3rdParty/FMIL/build/ExpatEx/)
ENDIF(MSVC)
IF(NOT LIB_EXPAT)
  MESSAGE(FATAL_ERROR "Could not find static expat library!\nSearched in:\n${OMBUILDDIR}/lib/omc ${OMBUILDDIR}/lib/omc/msvc ${CMAKE_SOURCE_DIR}/../../3rdParty/FMIL/build/ExpatEx/ $ENV{OMDEV}/lib/expat-win32-msvc $ENV{OMDEV}/lib/lapack-win32-msvc")
ENDIF(NOT LIB_EXPAT)
MESSAGE(STATUS "Using expat library ${LIB_EXPAT}")

include_directories ("${CMAKE_SOURCE_DIR}/base/include" "${CMAKE_SOURCE_DIR}/solver/include")
add_library( ${OSUBaseName}
  src/omsi_event_helper.c
  src/omsi_getters_and_setters.c
  src/omsi_initialization.c
  src/omsi_input_json.c
  src/omsi_input_model_variables.c
  src/omsi_input_sim_data.c
  src/omsi_input_xml.c
  src/omsi_mmap.c
  src/omsi_posix_func.c
  src/omsi_solve_alg_system.c
  src/omsi_utils.c)

include_directories ("${OMSI_SOURCE_DIR}/solver/include")

# Set RPATH for mac to use lib from build tree and install location
SET(CMAKE_SKIP_BUILD_RPATH  FALSE)
SET(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)
SET(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib")
SET(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
LIST(FIND CMAKE_PLATFORM_IMPLICIT_LINK_DIRECTORIES "${CMAKE_INSTALL_PREFIX}/lib" isSystemDir)
IF("${isSystemDir}" STREQUAL "-1")
   SET(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib")
ENDIF("${isSystemDir}" STREQUAL "-1")

IF(WIN32)
  target_link_libraries(${OSUBaseName} ${OMSISolverName} ${CMAKE_DL_LIBS} wsock32 ws2_32 ${LIB_EXPAT})
ELSE(WIN32)
  target_link_libraries(${OSUBaseName} ${OMSISolverName} ${CMAKE_DL_LIBS} ${LIB_EXPAT})
ENDIF(WIN32)


install(TARGETS ${OSUBaseName} DESTINATION ${LIBINSTALLEXT})

install(FILES ${CMAKE_SOURCE_DIR}/../../3rdParty/FMIL/build/ThirdParty/Expat/expat-2.1.0/libexpat.a DESTINATION ${LIBINSTALLEXT})

install(FILES
  ${CMAKE_SOURCE_DIR}/base/include/omsi_event_helper.h
  ${CMAKE_SOURCE_DIR}/base/include/omsi_getters_and_setters.h
  ${CMAKE_SOURCE_DIR}/base/include/omsi_global.h
  ${CMAKE_SOURCE_DIR}/base/include/omsi_initialization.h
  ${CMAKE_SOURCE_DIR}/base/include/omsi_input_json.h
  ${CMAKE_SOURCE_DIR}/base/include/omsi_input_model_variables.h
  ${CMAKE_SOURCE_DIR}/base/include/omsi_input_sim_data.h
  ${CMAKE_SOURCE_DIR}/base/include/omsi_input_xml.h
  ${CMAKE_SOURCE_DIR}/base/include/omsi_mmap.h
  ${CMAKE_SOURCE_DIR}/base/include/omsi_posix_func.h
  ${CMAKE_SOURCE_DIR}/base/include/omsi_solve_alg_system.h
  ${CMAKE_SOURCE_DIR}/base/include/omsi_utils.h
  ${CMAKE_SOURCE_DIR}/base/include/uthash.h
  DESTINATION include/omc/omsi/base)
