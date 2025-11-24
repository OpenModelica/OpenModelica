CMAKE_MINIMUM_REQUIRED(VERSION 3.5)

project(${SystemBaseName})
set(BASE_LIB "" CACHE INTERNAL "" )


add_library(${SystemBaseName} LinearAlgLoopDefaultImplementation.cpp NonLinearAlgLoopDefaultImplementation.cpp AlgLoopSolverFactory.cpp EventHandling.cpp DiscreteEvents.cpp ContinuousEvents.cpp SystemDefaultImplementation.cpp SimObjects.cpp SimVars.cpp FactoryExport.cpp)
target_link_libraries(${SystemBaseName} ${Boost_LIBRARIES} ${LAPACK_LIBRARIES} ${OMCFactoryName} ${SimulationSettings}   ${ExtensionUtilitiesName})


if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${SystemBaseName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING;ENABLE_SUNDIALS_STATIC")
else(NOT BUILD_SHARED_LIBS)
IF(MSVC)
  install(FILES $<TARGET_PDB_FILE:${SystemBaseName}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)
ENDIF(MSVC)
endif(NOT BUILD_SHARED_LIBS)



add_precompiled_header(${SystemBaseName} runtime/include/Core/Modelica.h)


install(TARGETS ${SystemBaseName} DESTINATION ${LIBINSTALLEXT})

#IF (NOT ((${CMAKE_SYSTEM_NAME} MATCHES "Darwin") OR  MSVC))
#install (TARGETS ${BasiLibName} DESTINATION ${LIBINSTALLEXT})
#ENDIF (NOT ((${CMAKE_SYSTEM_NAME} MATCHES "Darwin") OR  MSVC))
install(FILES
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/System/SystemDefaultImplementation.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/System/LinearAlgLoopDefaultImplementation.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/System/NonLinearAlgLoopDefaultImplementation.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/System/EventHandling.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/System/DiscreteEvents.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/System/ContinuousEvents.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/System/SimVars.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/System/FactoryExport.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/System/ILinearAlgLoop.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/System/INonLinearAlgLoop.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/System/IAlgLoopSolverFactory.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/System/AlgLoopSolverFactory.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/System/IContinuous.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/System/IMixedSystem.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/System/IEvent.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/System/ITime.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/System/ISystemProperties.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/System/ISystemInitialization.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/System/IStepEvent.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/System/IWriteOutput.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/System/ISystemTypes.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/System/IStateSelection.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/System/ISimVars.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/System/ISimObjects.h
  DESTINATION include/omc/omsicpp/Core/System)
