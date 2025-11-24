CMAKE_MINIMUM_REQUIRED(VERSION 3.5)
include_directories ("../../../../../OMSI/include")
project(${SystemOMSIName})


MESSAGE(STATUS "Build omsi library with fmilib:")
MESSAGE(STATUS "${FMILIB_LIB}")

add_library(${SystemOMSIName} OMSUSystem.cpp FactoryExport.cpp)
target_link_libraries(${SystemOMSIName} ${ExtendedSystemName} ${SystemBaseName} ${Boost_LIBRARIES} ${OMCFactoryName} ${SimulationSettings} ${FMILIB_LIB} ${FMILIB_LIB_EXTRA} ${LibZName})


if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${SystemOMSIName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING;ENABLE_SUNDIALS_STATIC")
else(NOT BUILD_SHARED_LIBS)
IF(MSVC)
  install(FILES $<TARGET_PDB_FILE:${SystemOMSIName}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)
ENDIF(MSVC)
endif(NOT BUILD_SHARED_LIBS)



add_precompiled_header(${SystemOMSIName} runtime/include/Core/Modelica.h)


install(TARGETS ${SystemOMSIName} DESTINATION ${LIBINSTALLEXT})

#IF (NOT ((${CMAKE_SYSTEM_NAME} MATCHES "Darwin") OR  MSVC))
#install (TARGETS ${BasiLibName} DESTINATION ${LIBINSTALLEXT})
#ENDIF (NOT ((${CMAKE_SYSTEM_NAME} MATCHES "Darwin") OR  MSVC))
install(FILES
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/System/IOMSI.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/System/OMSUSystem.h
  DESTINATION include/omc/omsicpp/Core/System)
