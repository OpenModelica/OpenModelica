cmake_minimum_required(VERSION 2.8.9)

project(${SimControllerName})

add_library(${SimControllerName} Configuration.cpp  FactoryExport.cpp Initialization.cpp SimController.cpp SimManager.cpp SimObjects.cpp)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${SimControllerName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING;ENABLE_SUNDIALS_STATIC")
endif(NOT BUILD_SHARED_LIBS)

include_directories(${SUNDIALS_INCLUDE_DIR}/cvodes ${SUNDIALS_INCLUDE_DIR}/nvector ${SUNDIALS_INCLUDE_DIR}/sundials ${SUNDIALS_INCLUDE_DIR}/kinsol ${SUNDIALS_INCLUDE_DIR})
target_link_libraries(${SimControllerName} ${OMCFactoryName}_static ${ExtensionUtilitiesName} ${ModelicaUtilitiesName} ${Boost_LIBRARIES} ${CMAKE_DL_LIBS})
add_precompiled_header(${SimControllerName} Include/Core/Modelica.h)

install (TARGETS ${SimControllerName} DESTINATION ${LIBINSTALLEXT})
install (FILES
  ${CMAKE_SOURCE_DIR}/Include/Core/SimController/ISimData.h
  ${CMAKE_SOURCE_DIR}/Include/Core/SimController/ISimObjects.h
  ${CMAKE_SOURCE_DIR}/Include/Core/SimController/ISimController.h
  ${CMAKE_SOURCE_DIR}/Include/Core/SimController/SimController.h
  ${CMAKE_SOURCE_DIR}/Include/Core/SimController/SimManager.h
  ${CMAKE_SOURCE_DIR}/Include/Core/SimController/SimController.h
  ${CMAKE_SOURCE_DIR}/Include/Core/SimController/SimManager.h
  ${CMAKE_SOURCE_DIR}/Include/Core/SimController/Configuration.h
  ${CMAKE_SOURCE_DIR}/Include/Core/SimController/Initialization.h
  DESTINATION include/omc/cpp/Core/SimController)
