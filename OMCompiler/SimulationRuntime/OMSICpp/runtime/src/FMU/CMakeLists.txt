cmake_minimum_required(VERSION 3.5)

project(${FMUName})

add_library(${FMUName} FMULogger.cpp)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${FMUName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")
else(NOT BUILD_SHARED_LIBS)
IF(MSVC)
  install(FILES $<TARGET_PDB_FILE:${FMUName}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)
ENDIF(MSVC)
endif(NOT BUILD_SHARED_LIBS)

target_link_libraries(${FMUName} ${ExtensionUtilitiesName}  ${ModelicaName})
add_precompiled_header(${FMUName} runtime/include/Core/Modelica.h)


install(TARGETS ${FMUName} DESTINATION ${LIBINSTALLEXT})
install(FILES
  ${CMAKE_SOURCE_DIR}/runtime/include/FMU/fmiModelFunctions.h
  ${CMAKE_SOURCE_DIR}/runtime/include/FMU/fmiModelTypes.h
  ${CMAKE_SOURCE_DIR}/runtime/include/FMU/FMUGlobalSettings.h
  ${CMAKE_SOURCE_DIR}/runtime/include/FMU/FMULogger.h
  ${CMAKE_SOURCE_DIR}/runtime/include/FMU/FMUWrapper.h
  ${CMAKE_SOURCE_DIR}/runtime/include/FMU/FMULibInterface.h
  ${CMAKE_SOURCE_DIR}/runtime/include/FMU/IFMUInterface.h
  ${CMAKE_SOURCE_DIR}/runtime/include/FMU/FactoryExport.h
  DESTINATION include/omc/omsicpp/FMU)
