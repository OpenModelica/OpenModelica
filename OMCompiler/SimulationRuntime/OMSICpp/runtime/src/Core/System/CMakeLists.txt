cmake_minimum_required(VERSION 2.8.9)
include_directories ("../../../../../OMSI/include")
project(${SystemName})
set(BASE_LIB "" CACHE INTERNAL "" )

#IF (NOT ((${CMAKE_SYSTEM_NAME} MATCHES "Darwin") OR  MSVC))
#add_library(${BasiLibName} STATIC tpl.cpp )
#set_target_properties(${BasiLibName} PROPERTIES COMPILE_FLAGS -fPIC)
#set(BASE_LIB -l${BasiLibName} CACHE INTERNAL "" )
#ENDIF (NOT ((${CMAKE_SYSTEM_NAME} MATCHES "Darwin") OR  MSVC))

# add the system default implementation library
if(USE_FMILIB)
add_library(${SystemName} LinearAlgLoopDefaultImplementation.cpp NonLinearAlgLoopDefaultImplementation.cpp AlgLoopSolverFactory.cpp EventHandling.cpp DiscreteEvents.cpp ContinuousEvents.cpp SystemDefaultImplementation.cpp SimObjects.cpp SimVars.cpp OSUSystem.cpp FactoryExport.cpp)
target_link_libraries(${SystemName} ${Boost_LIBRARIES} ${LAPACK_LIBRARIES} ${OMCFactoryName} ${SimulationSettings} ${FMILIB_LIB}  ${ExtensionUtilitiesName})
else(USE_FMILIB)
add_library(${SystemName} LinearAlgLoopDefaultImplementation.cpp NonLinearAlgLoopDefaultImplementation.cpp AlgLoopSolverFactory.cpp EventHandling.cpp DiscreteEvents.cpp ContinuousEvents.cpp SystemDefaultImplementation.cpp SimObjects.cpp SimVars.cpp  FactoryExport.cpp)
target_link_libraries(${SystemName} ${Boost_LIBRARIES} ${LAPACK_LIBRARIES} ${OMCFactoryName} ${SimulationSettings} ${ExtensionUtilitiesName})
endif(USE_FMILIB)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${SystemName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING;ENABLE_SUNDIALS_STATIC")
else(NOT BUILD_SHARED_LIBS)
  install(FILES $<TARGET_PDB_FILE:${SystemName}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)
endif(NOT BUILD_SHARED_LIBS)



add_precompiled_header(${SystemName} runtime/include/Core/Modelica.h)


install(TARGETS ${SystemName} DESTINATION ${LIBINSTALLEXT})

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
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/System/IOMSI.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/System/OSUSystem.h
  DESTINATION include/omc/omsicpp/Core/System)
