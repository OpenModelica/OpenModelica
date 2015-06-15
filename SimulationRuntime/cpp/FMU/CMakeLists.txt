cmake_minimum_required (VERSION 2.8.6)

project(${FMUName})

add_library(${FMUName} SHARED FMULogger.cpp)
add_library(${FMUName}_static STATIC FMULogger.cpp)

set_target_properties(${FMUName}_static PROPERTIES COMPILE_DEFINITIONS "DRUNTIME_STATIC_LINKING")

add_precompiled_header(${FMUName} Include/Core/Modelica.h)
add_precompiled_header(${FMUName}_static Include/Core/Modelica.h)

if (UNIX)
	set_target_properties(${FMUName} PROPERTIES COMPILE_FLAGS -fPIC)
	set_target_properties(${FMUName}_static PROPERTIES COMPILE_FLAGS -fPIC)
endif(UNIX)

target_link_libraries (${FMUName} ${ExtensionUtilitiesName})

install (TARGETS ${FMUName} DESTINATION ${LIBINSTALLEXT})
install (TARGETS ${FMUName}_static DESTINATION ${LIBINSTALLEXT})

install (FILES  ${CMAKE_SOURCE_DIR}/Include/FMU/fmiModelFunctions.h
				${CMAKE_SOURCE_DIR}/Include/FMU/fmiModelTypes.h
				${CMAKE_SOURCE_DIR}/Include/FMU/FMUGlobalSettings.h
				${CMAKE_SOURCE_DIR}/Include/FMU/FMULogger.h
				${CMAKE_SOURCE_DIR}/Include/FMU/FMUWrapper.h
				${CMAKE_SOURCE_DIR}/Include/FMU/FMULibInterface.h
				${CMAKE_SOURCE_DIR}/Include/FMU/IFMUInterface.h
  DESTINATION include/omc/cpp/FMU)






