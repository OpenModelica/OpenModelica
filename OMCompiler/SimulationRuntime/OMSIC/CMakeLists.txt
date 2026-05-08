cmake_minimum_required(VERSION 3.14)
set(CMAKE_VERBOSE_MAKEFILE ON)

project(OMSICSimulationRuntime)

# enable warnings
if(CMAKE_C_COMPILER_ID STREQUAL "GNU")
  message(STATUS "GCC detected, adding compile flags")
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -Wextra -pedantic")
  if(NOT WIN32)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fPIC")
  endif()
endif()
message(STATUS "Compiling with C flags: ${CMAKE_C_FLAGS}")

if(NOT PLATFORM OR PLATFORM STREQUAL "dynamic")
  set(BUILD_SHARED_LIBS ON)
elseif(PLATFORM STREQUAL "static")
  set(BUILD_SHARED_LIBS OFF)
endif()

if(BUILD_SHARED_LIBS)
  set(LIBSUFFIX "")
else()
  set(LIBSUFFIX "_static")
endif()
set(OMSICName ${LIBPREFIX}OMSIC${LIBSUFFIX})
set(OSUBaseName ${LIBPREFIX}OMSIBase${LIBSUFFIX})

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

if(TARGET OMSIBaseSimulationRuntime)
  target_link_libraries(${OMSICName}
    PRIVATE ${CMAKE_DL_LIBS}
    PUBLIC ${OSUBaseName})
else()
  # Standalone makefile build: OSUBaseName is not a CMake target, so link by full path
  set(OSUBaseLib "${CMAKE_INSTALL_PREFIX}/${LIBINSTALLEXT}/${OSUBaseName}")
  target_link_libraries(${OMSICName} PRIVATE ${CMAKE_DL_LIBS} PUBLIC ${OSUBaseLib})
endif()

install(TARGETS ${OMSICName}
  RUNTIME DESTINATION bin
  LIBRARY DESTINATION ${LIBINSTALLEXT}
  ARCHIVE DESTINATION ${LIBINSTALLEXT})

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
