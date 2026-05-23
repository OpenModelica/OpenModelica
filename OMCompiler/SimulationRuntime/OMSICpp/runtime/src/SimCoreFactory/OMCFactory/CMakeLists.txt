cmake_minimum_required(VERSION 3.5...4.3)

project(${OMCFactoryName})

add_library(${OMCFactoryName} STATIC OMCFactory.cpp)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${OMCFactoryName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING;ENABLE_SUNDIALS_STATIC")
else(NOT BUILD_SHARED_LIBS)
  install(TARGETS ${OMCFactoryName} DESTINATION ${LIBINSTALLEXT})
endif(NOT BUILD_SHARED_LIBS)

if(WIN32)
  target_link_libraries(${OMCFactoryName} ${Boost_LIBRARIES} ${CMAKE_DL_LIBS} ${ExtensionUtilitiesName} wsock32 ws2_32)
else(WIN32)
  target_link_libraries(${OMCFactoryName} ${Boost_LIBRARIES} ${CMAKE_DL_LIBS} ${ExtensionUtilitiesName} ${CPPTHREADS_LIBRARY})
endif(WIN32)
add_precompiled_header(${OMCFactoryName} runtime/include/Core/Modelica.h)


install(FILES
  ${OMSICPP_SOURCE_DIR}/runtime/include/SimCoreFactory/Policies/FactoryConfig.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/SimCoreFactory/Policies/FactoryPolicy.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/SimCoreFactory/Policies/SolverOMCFactory.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/SimCoreFactory/Policies/LinSolverOMCFactory.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/SimCoreFactory/Policies/NonLinSolverOMCFactory.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/SimCoreFactory/Policies/SystemOMCFactory.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/SimCoreFactory/Policies/SolverSettingsOMCFactory.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/SimCoreFactory/Policies/StaticSolverOMCFactory.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/SimCoreFactory/Policies/StaticLinSolverOMCFactory.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/SimCoreFactory/Policies/StaticNonLinSolverOMCFactory.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/SimCoreFactory/Policies/StaticSystemOMCFactory.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/SimCoreFactory/Policies/StaticSolverSettingsOMCFactory.h

  ${OMSICPP_SOURCE_DIR}/runtime/include/SimCoreFactory/Policies/SolverVxWorksFactory.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/SimCoreFactory/Policies/LinSolverVxWorksFactory.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/SimCoreFactory/Policies/NonLinSolverVxWorksFactory.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/SimCoreFactory/Policies/SystemVxWorksFactory.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/SimCoreFactory/Policies/SolverSettingsVxWorksFactory.h
  DESTINATION include/omc/omsicpp/SimCoreFactory/Policies)

install(FILES
  ${OMSICPP_SOURCE_DIR}/runtime/include/SimCoreFactory/OMCFactory/StaticOMCFactory.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/SimCoreFactory/OMCFactory/OMCFactory.h
  DESTINATION include/omc/omsicpp/SimCoreFactory/OMCFactory/)
install(FILES
  ${OMSICPP_SOURCE_DIR}/runtime/include/SimCoreFactory/VxWorksFactory/VxWorksFactory.h
  DESTINATION include/omc/omsicpp/SimCoreFactory/VxWorksFactory/)
install(FILES
  ${OMSICPP_SOURCE_DIR}/runtime/include/SimCoreFactory/ObjectFactory.h
  DESTINATION include/omc/omsicpp/SimCoreFactory)
