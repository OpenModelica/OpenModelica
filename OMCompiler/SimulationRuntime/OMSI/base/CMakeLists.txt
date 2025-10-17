CMAKE_MINIMUM_REQUIRED(VERSION 3.14)
SET(CMAKE_VERBOSE_MAKEFILE ON)

#OMSI base simulation runtime
PROJECT(OMSIBASE)

IF(NOT TARGET omc::3rd::FMIL::expat)
  # Set exapat lib for visual studio compiler
  # TODO: This relies on the static expat libexpat.a on MSVC but it's only build for mingw target!
  IF(MSVC)
    INCLUDE_DIRECTORIES($ENV{OMDEV}/lib/expat-win32-msvc)
    FIND_LIBRARY(LIB_EXPAT NAMES expat libexpat PATHS ${OMBUILDDIR}/lib/omc ${OMBUILDDIR}/lib/omc/msvc ${CMAKE_CURRENT_SOURCE_DIR}/../../3rdParty/FMIL/build/ExpatEx/ $ENV{OMDEV}/lib/expat-win32-msvc $ENV{OMDEV}/lib/lapack-win32-msvc)
  ELSE(MSVC)
    FIND_LIBRARY(LIB_EXPAT NAMES expat libexpat PATHS ${OMBUILDDIR}/lib/omc ${CMAKE_CURRENT_SOURCE_DIR}/../../3rdParty/FMIL/build/ExpatEx/)
  ENDIF(MSVC)
  IF(NOT LIB_EXPAT)
    MESSAGE(FATAL_ERROR "Could not find static expat library!\nSearched in:\n${OMBUILDDIR}/lib/omc ${OMBUILDDIR}/lib/omc/msvc ${CMAKE_CURRENT_SOURCE_DIR}/../../3rdParty/FMIL/build/ExpatEx/ $ENV{OMDEV}/lib/expat-win32-msvc $ENV{OMDEV}/lib/lapack-win32-msvc")
  ENDIF(NOT LIB_EXPAT)
  MESSAGE(STATUS "Using expat library ${LIB_EXPAT}")
ENDIF(NOT TARGET omc::3rd::FMIL::expat)

add_library(${OSUBaseName}
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

target_include_directories(${OSUBaseName} PUBLIC include)

# Set RPATH for mac to use lib from build tree and install location
SET(CMAKE_SKIP_BUILD_RPATH  FALSE)
SET(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)
SET(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib")
SET(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
LIST(FIND CMAKE_PLATFORM_IMPLICIT_LINK_DIRECTORIES "${CMAKE_INSTALL_PREFIX}/lib" isSystemDir)
IF("${isSystemDir}" STREQUAL "-1")
   SET(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib")
ENDIF("${isSystemDir}" STREQUAL "-1")

target_link_libraries(${OSUBaseName} PUBLIC OMSIBaseSimulationRuntime)
target_link_libraries(${OSUBaseName} PUBLIC ${OMSISolverName})
target_link_libraries(${OSUBaseName} PUBLIC ${CMAKE_DL_LIBS})
IF(TARGET omc::3rd::FMIL::expat)
  target_link_libraries(${OSUBaseName} PUBLIC omc::3rd::FMIL::expat)
ELSE(TARGET omc::3rd::FMIL::expat)
  target_link_libraries(${OSUBaseName} PUBLIC ${LIB_EXPAT})
ENDIF(TARGET omc::3rd::FMIL::expat)

IF(WIN32)
  target_link_libraries(${OSUBaseName} PRIVATE wsock32)
  target_link_libraries(${OSUBaseName} PRIVATE ws2_32)
ENDIF(WIN32)

install(TARGETS ${OSUBaseName} DESTINATION ${LIBINSTALLEXT})

IF(NOT TARGET omc::3rd::FMIL::expat)
  install(FILES ../../../3rdParty/FMIL/build/ThirdParty/Expat/expat-2.1.0/libexpat.a DESTINATION ${LIBINSTALLEXT})
ENDIF(NOT TARGET omc::3rd::FMIL::expat)

install(FILES
  include/omsi_event_helper.h
  include/omsi_getters_and_setters.h
  include/omsi_global.h
  include/omsi_initialization.h
  include/omsi_input_json.h
  include/omsi_input_model_variables.h
  include/omsi_input_sim_data.h
  include/omsi_input_xml.h
  include/omsi_mmap.h
  include/omsi_posix_func.h
  include/omsi_solve_alg_system.h
  include/omsi_utils.h
  include/uthash.h
  DESTINATION include/omc/omsi/base)
