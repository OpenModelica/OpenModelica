cmake_minimum_required(VERSION 3.5)
include_directories ("../../../../../OMSI/include")
project(${ExtendedSystemName})
set(BASE_LIB "" CACHE INTERNAL "" )

#IF (NOT ((${CMAKE_SYSTEM_NAME} MATCHES "Darwin") OR  MSVC))
#add_library(${BasiLibName} STATIC tpl.cpp )
#set_target_properties(${BasiLibName} PROPERTIES COMPILE_FLAGS -fPIC)
#set(BASE_LIB -l${BasiLibName} CACHE INTERNAL "" )
#ENDIF (NOT ((${CMAKE_SYSTEM_NAME} MATCHES "Darwin") OR  MSVC))

add_library(${ExtendedSystemName} ExtendedSimObjects.cpp ExtendedSystem.cpp ExtendedSimVars.cpp FactoryExport.cpp)
target_link_libraries(${ExtendedSystemName} ${SystemBaseName}  ${Boost_LIBRARIES} ${LAPACK_LIBRARIES} ${OMCFactoryName} ${SimulationSettings} ${ExtensionUtilitiesName})


if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${ExtendedSystemName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING;ENABLE_SUNDIALS_STATIC")
else(NOT BUILD_SHARED_LIBS)
IF(MSVC)
  install(FILES $<TARGET_PDB_FILE:${ExtendedSystemName}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)
ENDIF(MSVC)
endif(NOT BUILD_SHARED_LIBS)



add_precompiled_header(${ExtendedSystemName} runtime/include/Core/Modelica.h)


install(TARGETS ${ExtendedSystemName} DESTINATION ${LIBINSTALLEXT})

#IF (NOT ((${CMAKE_SYSTEM_NAME} MATCHES "Darwin") OR  MSVC))
#install (TARGETS ${BasiLibName} DESTINATION ${LIBINSTALLEXT})
#ENDIF (NOT ((${CMAKE_SYSTEM_NAME} MATCHES "Darwin") OR  MSVC))
install(FILES
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/System/IExtendedSimObjects.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/System/ExtendedSimObjects.h
   ${CMAKE_SOURCE_DIR}/runtime/include/Core/System/ExtendedSystem.h
  DESTINATION include/omc/omsicpp/Core/System)
