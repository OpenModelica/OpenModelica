CMAKE_MINIMUM_REQUIRED(VERSION 3.5)
SET(CMAKE_VERBOSE_MAKEFILE ON)
MESSAGE(STATUS "CMake version ${CMAKE_MAJOR_VERSION}.${CMAKE_MINOR_VERSION}.${CMAKE_PATCH_VERSION}")

PROJECT(OMSIBaseSimulationRuntime)

# enable warnings and use ANSI C compatible compiler
if(CMAKE_COMPILER_IS_GNUCXX)
    message(STATUS "GCC detected, adding compile flags")
    set(CMAKE_C_FLAGS  "${CMAKE_C_FLAGS} -Wall -Wextra -ansi -pedantic -g")
    IF(NOT WIN32)
        SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fPIC")
    ENDIF()
endif(CMAKE_COMPILER_IS_GNUCXX)
message(STATUS "Compiling with C flags: ${CMAKE_C_FLAGS}")



if(NOT PLATFORM OR PLATFORM STREQUAL "dynamic")
  set(BUILD_SHARED_LIBS ON)
elseif(PLATFORM STREQUAL "static")
  set(BUILD_SHARED_LIBS OFF)
else()
endif()



IF(BUILD_SHARED_LIBS)
  SET(LIBSUFFIX "")
ELSE(BUILD_SHARED_LIBS)
  SET(LIBSUFFIX "_static")
ENDIF(BUILD_SHARED_LIBS)



IF(MSVC)
  MESSAGE(STATUS "MSVC")
  IF(LIB_OMC)
    SET(LIBINSTALLEXT "${LIB_OMC}/omsi/msvc" CACHE STRING "library directory" FORCE)
  ELSE(LIB_OMC)
    SET(LIBINSTALLEXT "omsi/msvc" CACHE STRING "library directory" FORCE)
  ENDIF(LIB_OMC)
ELSE(MSVC)
  IF(LIB_OMC)
    SET(LIBINSTALLEXT "${LIB_OMC}/omsi" CACHE STRING "library directory" FORCE)
  ELSE(LIB_OMC)
    SET(LIBINSTALLEXT "omsi" CACHE STRING "library directory" FORCE)
  ENDIF(LIB_OMC)
ENDIF(MSVC)
message(STATUS "Libs will be installed in ${CMAKE_INSTALL_PREFIX}/${LIBINSTALLEXT}")

SET(OSUBaseName ${LIBPREFIX}OMSIBase${LIBSUFFIX})
SET(OMSISolverName ${LIBPREFIX}OMSISolver${LIBSUFFIX})

include_directories ("${CMAKE_SOURCE_DIR}/include")
# omsi base simulation runtime
ADD_SUBDIRECTORY(solver)
ADD_SUBDIRECTORY(base)


install(FILES
  ${CMAKE_SOURCE_DIR}/include/omsi.h
  ${CMAKE_SOURCE_DIR}/include/omsi_callbacks.h
  ${CMAKE_SOURCE_DIR}/include/omsi_api_functions.h
  DESTINATION include/omc/omsi)

install(FILES
  ${CMAKE_SOURCE_DIR}/include/fmi2/omsi_fmi2_cs.h
  ${CMAKE_SOURCE_DIR}/include/fmi2/omsi_fmi2_me.h
  ${CMAKE_SOURCE_DIR}/include/fmi2/omsi_fmi2_wrapper.h
  ${CMAKE_SOURCE_DIR}/include/fmi2/fmi2Functions.h
  ${CMAKE_SOURCE_DIR}/include/fmi2/fmi2FunctionTypes.h
  ${CMAKE_SOURCE_DIR}/include/fmi2/fmi2TypesPlatform.h
  DESTINATION include/omc/omsi/fmi2/)

# uninstall target
if(NOT TARGET uninstall)
    configure_file(
        "${CMAKE_CURRENT_SOURCE_DIR}/cmake_uninstall.cmake.in"
        "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake"
        IMMEDIATE @ONLY)

    add_custom_target(uninstall
        COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake)
endif()
