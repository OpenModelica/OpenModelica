if(OPENMODELICA_NEW_CMAKE_BUILD)
  include(cmake_3.14.cmake)
else(OPENMODELICA_NEW_CMAKE_BUILD)

cmake_minimum_required(VERSION 3.5)

project(${FMUName})

add_library(${FMUName} FMULogger.cpp)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${FMUName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")
endif(NOT BUILD_SHARED_LIBS)

target_link_libraries(${FMUName} ${ExtensionUtilitiesName}  ${ModelicaName})
add_precompiled_header(${FMUName} Core/Modelica.h)

install(FILES $<TARGET_PDB_FILE:${FMUName}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)

install(TARGETS ${FMUName} DESTINATION ${LIBINSTALLEXT})
install(FILES
  ${CMAKE_SOURCE_DIR}/FMU/fmiModelFunctions.h
  ${CMAKE_SOURCE_DIR}/FMU/fmiModelTypes.h
  ${CMAKE_SOURCE_DIR}/FMU/FMUGlobalSettings.h
  ${CMAKE_SOURCE_DIR}/FMU/FMULogger.h
  ${CMAKE_SOURCE_DIR}/FMU/FMUWrapper.h
  ${CMAKE_SOURCE_DIR}/FMU/FMULibInterface.h
  ${CMAKE_SOURCE_DIR}/FMU/IFMUInterface.h
  ${CMAKE_SOURCE_DIR}/FMU/FactoryExport.h
  DESTINATION include/omc/cpp/FMU)

  endif(OPENMODELICA_NEW_CMAKE_BUILD)
