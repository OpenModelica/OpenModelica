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

set_target_properties(${OMSICName} PROPERTIES MACOSX_RPATH ON)

target_link_libraries(${OMSICName}
    PRIVATE ${CMAKE_DL_LIBS}
    PUBLIC ${OSUBaseName})

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
