cmake_minimum_required(VERSION 2.8.9)

project(${FMUName})

add_library(${FMUName} FMULogger.cpp)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${FMUName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")
endif(NOT BUILD_SHARED_LIBS)

target_link_libraries(${FMUName} ${ExtensionUtilitiesName}  ${ModelicaName})
add_precompiled_header(${FMUName} Include/Core/Modelica.h)

install(TARGETS ${FMUName} DESTINATION ${LIBINSTALLEXT})
install(FILES
  ${CMAKE_SOURCE_DIR}/Include/FMU/fmiModelFunctions.h
  ${CMAKE_SOURCE_DIR}/Include/FMU/fmiModelTypes.h
  ${CMAKE_SOURCE_DIR}/Include/FMU/FMUGlobalSettings.h
  ${CMAKE_SOURCE_DIR}/Include/FMU/FMULogger.h
  ${CMAKE_SOURCE_DIR}/Include/FMU/FMUWrapper.h
  ${CMAKE_SOURCE_DIR}/Include/FMU/FMULibInterface.h
  ${CMAKE_SOURCE_DIR}/Include/FMU/IFMUInterface.h
  ${CMAKE_SOURCE_DIR}/Include/FMU/FactoryExport.h
  DESTINATION include/omc/cpp/FMU)
