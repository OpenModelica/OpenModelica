cmake_minimum_required(VERSION 2.8.9)

project(${SimControllerName})

include_directories(${SUNDIALS_INCLUDE_DIR}/cvodes ${SUNDIALS_INCLUDE_DIR}/nvector  ${SUNDIALS_INCLUDE_DIR}/sundials ${SUNDIALS_INCLUDE_DIR}/kinsol ${SUNDIALS_INCLUDE_DIR})
add_library(${SimControllerName}_static STATIC Configuration.cpp  FactoryExport.cpp Initialization.cpp SimController.cpp SimManager.cpp SimObjects.cpp)
set_target_properties(${SimControllerName}_static PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING;ENABLE_SUNDIALS_STATIC")
install (TARGETS ${SimControllerName}_static DESTINATION ${LIBINSTALLEXT})

add_library(${SimControllerName} SHARED Configuration.cpp  FactoryExport.cpp Initialization.cpp SimController.cpp SimManager.cpp SimObjects.cpp)
target_link_libraries( ${SimControllerName} ${OMCFactoryName}_static ${ExtensionUtilitiesName} ${ModelicaUtilitiesName} ${Boost_LIBRARIES} ${CMAKE_DL_LIBS})
add_precompiled_header(${SimControllerName} Include/Core/Modelica.h)
install (TARGETS ${SimControllerName} DESTINATION ${LIBINSTALLEXT})

install (FILES  ${CMAKE_SOURCE_DIR}/Include/Core/SimController/ISimData.h
                ${CMAKE_SOURCE_DIR}/Include/Core/SimController/ISimObjects.h
                ${CMAKE_SOURCE_DIR}/Include/Core/SimController/ISimController.h
                ${CMAKE_SOURCE_DIR}/Include/Core/SimController/SimController.h
                ${CMAKE_SOURCE_DIR}/Include/Core/SimController/SimManager.h
                ${CMAKE_SOURCE_DIR}/Include/Core/SimController/SimController.h
                ${CMAKE_SOURCE_DIR}/Include/Core/SimController/SimManager.h
                ${CMAKE_SOURCE_DIR}/Include/Core/SimController/Configuration.h
                ${CMAKE_SOURCE_DIR}/Include/Core/SimController/Initialization.h
DESTINATION include/omc/cpp/Core/SimController)