cmake_minimum_required(VERSION 3.5)

project(${SystemBaseName})
set(BASE_LIB "" CACHE INTERNAL "" )


add_library(${SystemBaseName} LinearAlgLoopDefaultImplementation.cpp NonLinearAlgLoopDefaultImplementation.cpp AlgLoopSolverFactory.cpp EventHandling.cpp DiscreteEvents.cpp ContinuousEvents.cpp SystemDefaultImplementation.cpp SimObjects.cpp SimVars.cpp FactoryExport.cpp)
target_link_libraries(${SystemBaseName} ${Boost_LIBRARIES} ${LAPACK_LIBRARIES} ${OMCFactoryName} ${SimulationSettings}   ${ExtensionUtilitiesName})


if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${SystemBaseName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING;ENABLE_SUNDIALS_STATIC")
else(NOT BUILD_SHARED_LIBS)
  if(MSVC)
    install(FILES $<TARGET_PDB_FILE:${SystemBaseName}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)
  endif(MSVC)
endif(NOT BUILD_SHARED_LIBS)



add_precompiled_header(${SystemBaseName} runtime/include/Core/Modelica.h)


install(TARGETS ${SystemBaseName} DESTINATION ${LIBINSTALLEXT})

#IF (NOT ((${CMAKE_SYSTEM_NAME} MATCHES "Darwin") OR  MSVC))
#install (TARGETS ${BasiLibName} DESTINATION ${LIBINSTALLEXT})
#ENDIF (NOT ((${CMAKE_SYSTEM_NAME} MATCHES "Darwin") OR  MSVC))
install(FILES
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/System/SystemDefaultImplementation.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/System/LinearAlgLoopDefaultImplementation.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/System/NonLinearAlgLoopDefaultImplementation.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/System/EventHandling.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/System/DiscreteEvents.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/System/ContinuousEvents.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/System/SimVars.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/System/FactoryExport.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/System/ILinearAlgLoop.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/System/INonLinearAlgLoop.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/System/IAlgLoopSolverFactory.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/System/AlgLoopSolverFactory.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/System/IContinuous.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/System/IMixedSystem.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/System/IEvent.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/System/ITime.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/System/ISystemProperties.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/System/ISystemInitialization.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/System/IStepEvent.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/System/IWriteOutput.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/System/ISystemTypes.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/System/IStateSelection.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/System/ISimVars.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/System/ISimObjects.h
  DESTINATION include/omc/omsicpp/Core/System)
