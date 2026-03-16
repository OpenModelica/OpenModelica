cmake_minimum_required(VERSION 3.5)

project(${SystemName})
set(BASE_LIB "" CACHE INTERNAL "" )

#IF (NOT ((${CMAKE_SYSTEM_NAME} MATCHES "Darwin") OR  MSVC))
#add_library(${BasiLibName} STATIC tpl.cpp )
#set_target_properties(${BasiLibName} PROPERTIES COMPILE_FLAGS -fPIC)
#set(BASE_LIB -l${BasiLibName} CACHE INTERNAL "" )
#ENDIF (NOT ((${CMAKE_SYSTEM_NAME} MATCHES "Darwin") OR  MSVC))

# add the system default implementation library
add_library(${SystemName} LinearAlgLoopDefaultImplementation.cpp NonLinearAlgLoopDefaultImplementation.cpp AlgLoopSolverFactory.cpp EventHandling.cpp DiscreteEvents.cpp ContinuousEvents.cpp SystemDefaultImplementation.cpp SimVars.cpp FactoryExport.cpp)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${SystemName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING;ENABLE_SUNDIALS_STATIC")
endif(NOT BUILD_SHARED_LIBS)

target_link_libraries(${SystemName} ${Boost_LIBRARIES} ${LAPACK_LIBRARIES} ${OMCFactoryName} ${SimulationSettings} ${ExtensionUtilitiesName})
add_precompiled_header(${SystemName} Core/Modelica.h)

install(FILES $<TARGET_PDB_FILE:${SystemName}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)

install(TARGETS ${SystemName} DESTINATION ${LIBINSTALLEXT})

#IF (NOT ((${CMAKE_SYSTEM_NAME} MATCHES "Darwin") OR  MSVC))
#install (TARGETS ${BasiLibName} DESTINATION ${LIBINSTALLEXT})
#ENDIF (NOT ((${CMAKE_SYSTEM_NAME} MATCHES "Darwin") OR  MSVC))
install(FILES
  ${CMAKE_SOURCE_DIR}/Core/System/SystemDefaultImplementation.h
  ${CMAKE_SOURCE_DIR}/Core/System/LinearAlgLoopDefaultImplementation.h
  ${CMAKE_SOURCE_DIR}/Core/System/NonLinearAlgLoopDefaultImplementation.h
  ${CMAKE_SOURCE_DIR}/Core/System/EventHandling.h
  ${CMAKE_SOURCE_DIR}/Core/System/DiscreteEvents.h
  ${CMAKE_SOURCE_DIR}/Core/System/ContinuousEvents.h
  ${CMAKE_SOURCE_DIR}/Core/System/SimVars.h
  ${CMAKE_SOURCE_DIR}/Core/System/FactoryExport.h
  ${CMAKE_SOURCE_DIR}/Core/System/ILinearAlgLoop.h
  ${CMAKE_SOURCE_DIR}/Core/System/INonLinearAlgLoop.h
  ${CMAKE_SOURCE_DIR}/Core/System/IAlgLoopSolverFactory.h
  ${CMAKE_SOURCE_DIR}/Core/System/AlgLoopSolverFactory.h
  ${CMAKE_SOURCE_DIR}/Core/System/IContinuous.h
  ${CMAKE_SOURCE_DIR}/Core/System/IMixedSystem.h
  ${CMAKE_SOURCE_DIR}/Core/System/IEvent.h
  ${CMAKE_SOURCE_DIR}/Core/System/ITime.h
  ${CMAKE_SOURCE_DIR}/Core/System/ISystemProperties.h
  ${CMAKE_SOURCE_DIR}/Core/System/ISystemInitialization.h
  ${CMAKE_SOURCE_DIR}/Core/System/IStepEvent.h
  ${CMAKE_SOURCE_DIR}/Core/System/IWriteOutput.h
  ${CMAKE_SOURCE_DIR}/Core/System/ISystemTypes.h
  ${CMAKE_SOURCE_DIR}/Core/System/IStateSelection.h
  ${CMAKE_SOURCE_DIR}/Core/System/ISimVars.h
  DESTINATION include/omc/cpp/Core/System)
