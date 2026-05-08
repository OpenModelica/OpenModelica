cmake_minimum_required(VERSION 3.14)
SET(CMAKE_VERBOSE_MAKEFILE ON)

PROJECT(OMSIBaseSimulationRuntime)
include(GNUInstallDirs)

# enable warnings
if(CMAKE_C_COMPILER_ID STREQUAL "GNU")
    message(STATUS "GCC detected, adding compile flags")
    set(CMAKE_C_FLAGS  "${CMAKE_C_FLAGS} -Wall -Wextra -pedantic")
    IF(NOT WIN32)
        SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fPIC")
    ENDIF()
endif(CMAKE_COMPILER_IS_GNUCXX)
message(STATUS "Compiling with C flags: ${CMAKE_C_FLAGS}")

if(NOT PLATFORM OR PLATFORM STREQUAL "dynamic")
  set(BUILD_SHARED_LIBS ON)
elseif(PLATFORM STREQUAL "static")
  set(BUILD_SHARED_LIBS OFF)
endif()

IF(BUILD_SHARED_LIBS)
  SET(LIBSUFFIX "")
ELSE(BUILD_SHARED_LIBS)
  SET(LIBSUFFIX "_static")
ENDIF(BUILD_SHARED_LIBS)

if(MSVC)
  set(LIBINSTALLEXT "${CMAKE_INSTALL_LIBDIR}/omsi/msvc")
else()
  set(LIBINSTALLEXT "${CMAKE_INSTALL_LIBDIR}/omsi")
endif()
message(STATUS "Libs will be installed in ${CMAKE_INSTALL_PREFIX}/${LIBINSTALLEXT}")


# OMSIBaseSimulationRuntime interface library
add_library(OMSIBaseSimulationRuntime INTERFACE)
target_include_directories(OMSIBaseSimulationRuntime INTERFACE
    "${CMAKE_CURRENT_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/include/fmi2"
    "${CMAKE_CURRENT_SOURCE_DIR}/solver/include"
)

SET(OSUBaseName ${LIBPREFIX}OMSIBase${LIBSUFFIX})
SET(OMSISolverName ${LIBPREFIX}OMSISolver${LIBSUFFIX})

# omsi base simulation runtime
ADD_SUBDIRECTORY(solver)
ADD_SUBDIRECTORY(base)

install(FILES
  include/omsi.h
  include/omsi_callbacks.h
  include/omsi_api_functions.h
  DESTINATION include/omc/omsi)

install(FILES
  include/fmi2/omsi_fmi2_cs.h
  include/fmi2/omsi_fmi2_me.h
  include/fmi2/omsi_fmi2_wrapper.h
  include/fmi2/fmi2Functions.h
  include/fmi2/fmi2FunctionTypes.h
  include/fmi2/fmi2TypesPlatform.h
  DESTINATION include/omc/omsi/fmi2/)

# uninstall target for makefile build
# TODO: Remove when switching to CMake build
if(NOT TARGET uninstall)
  configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake_uninstall.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake"
    IMMEDIATE @ONLY)

  add_custom_target(uninstall
    COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake)
endif()
