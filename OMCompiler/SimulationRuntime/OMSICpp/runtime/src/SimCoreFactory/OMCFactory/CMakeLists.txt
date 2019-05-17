cmake_minimum_required(VERSION 2.8.9)

project(${OMCFactoryName})

add_library(${OMCFactoryName} STATIC OMCFactory.cpp)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${OMCFactoryName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING;ENABLE_SUNDIALS_STATIC")
else(NOT BUILD_SHARED_LIBS)
  install(TARGETS ${OMCFactoryName} DESTINATION ${LIBINSTALLEXT})
endif(NOT BUILD_SHARED_LIBS)

IF(WIN32)
target_link_libraries(${OMCFactoryName} ${Boost_LIBRARIES} ${CMAKE_DL_LIBS} ${ExtensionUtilitiesName} wsock32 ws2_32)
ELSE(WIN32)
target_link_libraries(${OMCFactoryName} ${Boost_LIBRARIES} ${CMAKE_DL_LIBS} ${ExtensionUtilitiesName})
ENDIF(WIN32)
add_precompiled_header(${OMCFactoryName} runtime/include/Core/Modelica.h)


install(FILES
  ${CMAKE_SOURCE_DIR}/runtime/include/SimCoreFactory/Policies/FactoryConfig.h
  ${CMAKE_SOURCE_DIR}/runtime/include/SimCoreFactory/Policies/FactoryPolicy.h
  ${CMAKE_SOURCE_DIR}/runtime/include/SimCoreFactory/Policies/SolverOMCFactory.h
  ${CMAKE_SOURCE_DIR}/runtime/include/SimCoreFactory/Policies/LinSolverOMCFactory.h
  ${CMAKE_SOURCE_DIR}/runtime/include/SimCoreFactory/Policies/NonLinSolverOMCFactory.h
  ${CMAKE_SOURCE_DIR}/runtime/include/SimCoreFactory/Policies/SystemOMCFactory.h
  ${CMAKE_SOURCE_DIR}/runtime/include/SimCoreFactory/Policies/SolverSettingsOMCFactory.h
  ${CMAKE_SOURCE_DIR}/runtime/include/SimCoreFactory/Policies/StaticSolverOMCFactory.h
  ${CMAKE_SOURCE_DIR}/runtime/include/SimCoreFactory/Policies/StaticLinSolverOMCFactory.h
  ${CMAKE_SOURCE_DIR}/runtime/include/SimCoreFactory/Policies/StaticNonLinSolverOMCFactory.h
  ${CMAKE_SOURCE_DIR}/runtime/include/SimCoreFactory/Policies/StaticSystemOMCFactory.h
  ${CMAKE_SOURCE_DIR}/runtime/include/SimCoreFactory/Policies/StaticSolverSettingsOMCFactory.h

  ${CMAKE_SOURCE_DIR}/runtime/include/SimCoreFactory/Policies/SolverVxWorksFactory.h
  ${CMAKE_SOURCE_DIR}/runtime/include/SimCoreFactory/Policies/LinSolverVxWorksFactory.h
  ${CMAKE_SOURCE_DIR}/runtime/include/SimCoreFactory/Policies/NonLinSolverVxWorksFactory.h
  ${CMAKE_SOURCE_DIR}/runtime/include/SimCoreFactory/Policies/SystemVxWorksFactory.h
  ${CMAKE_SOURCE_DIR}/runtime/include/SimCoreFactory/Policies/SolverSettingsVxWorksFactory.h
  DESTINATION include/omc/omsicpp/SimCoreFactory/Policies)

install(FILES
  ${CMAKE_SOURCE_DIR}/runtime/include/SimCoreFactory/OMCFactory/StaticOMCFactory.h
  ${CMAKE_SOURCE_DIR}/runtime/include/SimCoreFactory/OMCFactory/OMCFactory.h
  DESTINATION include/omc/omsicpp/SimCoreFactory/OMCFactory/)
install(FILES
  ${CMAKE_SOURCE_DIR}/runtime/include/SimCoreFactory/VxWorksFactory/VxWorksFactory.h
  DESTINATION include/omc/omsicpp/SimCoreFactory/VxWorksFactory/)
install(FILES
  ${CMAKE_SOURCE_DIR}/runtime/include/SimCoreFactory/ObjectFactory.h
  DESTINATION include/omc/omsicpp/SimCoreFactory)
