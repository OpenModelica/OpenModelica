cmake_minimum_required(VERSION 3.14)
SET(CMAKE_VERBOSE_MAKEFILE ON)

PROJECT(OMSICSimulationRuntime)

# enable warnings
if(CMAKE_COMPILER_IS_GNUCXX)
    message(STATUS "GCC detected, adding compile flags")
    set(CMAKE_C_FLAGS  "${CMAKE_C_FLAGS} -Wall -Wextra -pedantic -g")
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
SET(OMSICName ${LIBPREFIX}OMSIC${LIBSUFFIX})
SET(OSUBaseName ${LIBPREFIX}OMSIBase${LIBSUFFIX})

if(MSVC)
  set(LIBINSTALLEXT "${CMAKE_INSTALL_LIBDIR}/omsi/msvc")
else()
  set(LIBINSTALLEXT "${CMAKE_INSTALL_LIBDIR}/omsi")
endif()
message(STATUS "Libs will be installed in ${CMAKE_INSTALL_PREFIX}/${LIBINSTALLEXT}")

add_library(${OMSICName}
  src/omsu/omsu_helper.c
  src/omsu/omsu_initialization.c
  src/omsu/omsu_getters_and_setters.c
  src/omsu/omsu_event_simulation.c
  src/omsu/omsu_continuous_simulation.c
  src/fmi2/omsi_fmi2_wrapper.c)

target_include_directories(${OMSICName} PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_include_directories(${OMSICName} PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/include/omsu")

# Fallback for "standalone" makefile build: OMSIBaseSimulationRuntime INTERFACE
# target is not available, so add OMSI includes explicitly.
# TODO: Remove when switching to CMake build
if(NOT TARGET OMSIBaseSimulationRuntime)
  set(OMSI_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../OMSI")
  target_include_directories(${OMSICName} PRIVATE
    "${OMSI_SOURCE_DIR}/include"
    "${OMSI_SOURCE_DIR}/include/fmi2"
    "${OMSI_SOURCE_DIR}/base/include"
    "${OMSI_SOURCE_DIR}/solver/include")
endif()

set_target_properties(${OMSICName} PROPERTIES MACOSX_RPATH ON)

if(TARGET OMSIBaseSimulationRuntime)
  target_link_libraries(${OMSICName}
      PRIVATE ${CMAKE_DL_LIBS}
      PUBLIC ${OSUBaseName})
else()
  # Standalone  makefile build: OSUBaseName is not a CMake target, so link by full path
  if(BUILD_SHARED_LIBS)
    set(OSUBaseLib "${CMAKE_INSTALL_PREFIX}/${LIBINSTALLEXT}/libOMSIBase${CMAKE_SHARED_LIBRARY_SUFFIX}")
  else()
    set(OSUBaseLib "${CMAKE_INSTALL_PREFIX}/${LIBINSTALLEXT}/libOMSIBase_static${CMAKE_STATIC_LIBRARY_SUFFIX}")
  endif()
  target_link_libraries(${OMSICName} PRIVATE ${CMAKE_DL_LIBS} PUBLIC ${OSUBaseLib})
endif()

install(TARGETS ${OMSICName} DESTINATION ${LIBINSTALLEXT})

install(FILES
  include/omsic.h
  DESTINATION include/omc/omsic)

install(FILES
  include/omsu/omsu_common.h
  include/omsu/omsu_continuous_simulation.h
  include/omsu/omsu_event_simulation.h
  include/omsu/omsu_getters_and_setters.h
  include/omsu/omsu_helper.h
  include/omsu/omsu_initialization.h
  DESTINATION include/omc/omsic/omsu)
