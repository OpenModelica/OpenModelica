CMAKE_MINIMUM_REQUIRED(VERSION 2.8.9)
#OpenModelica Simulation Unit C Runtime
PROJECT(OMSU)
SET(CMAKE_VERBOSE_MAKEFILE ON)

#set OMSIBase lib
if(NOT PLATFORM OR PLATFORM STREQUAL "dynamic")
  set (libOMSIBase ${CMAKE_INSTALL_PREFIX}/${LIBINSTALLEXT}/libOMSIBase${SHREXT})
elseif(PLATFORM STREQUAL "static")
  set (libOMSIBase ${CMAKE_INSTALL_PREFIX}/${LIBINSTALLEXT}/libOMSIBase${LIBSUFFIX}.a)
else()
endif()
MESSAGE(STATUS "OMSI Base Library: ${libOMSIBase}")


include_directories ("${CMAKE_SOURCE_DIR}/include")
include_directories ("${CMAKE_SOURCE_DIR}/include/solver")
include_directories ("${CMAKE_SOURCE_DIR}/include/omsu")
include_directories ("${CMAKE_SOURCE_DIR}/include/fmi2")
include_directories ("${OMSI_SOURCE_DIR}/base/include")

add_library(${OMSICName} STATIC omsu_helper.c omsu_initialization.c omsu_getters_and_setters.c omsu_event_simulation.c omsu_continuous_simulation.c ../fmi2/omsi_fmi2_wrapper.c)

target_link_libraries(${OMSICName} ${CMAKE_DL_LIBS} ${libOMSIBase})

install(TARGETS ${OMSICName} DESTINATION ${LIBINSTALLEXT})
