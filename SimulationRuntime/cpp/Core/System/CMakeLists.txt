cmake_minimum_required (VERSION 2.8.6)

project(${SystemName})
set(BASE_LIB "" CACHE INTERNAL "" )

#IF (NOT ((${CMAKE_SYSTEM_NAME} MATCHES "Darwin") OR  MSVC))
#add_library(${BasiLibName} STATIC tpl.cpp )
#set_target_properties(${BasiLibName} PROPERTIES COMPILE_FLAGS -fPIC)
#set(BASE_LIB -l${BasiLibName} CACHE INTERNAL "" )
#ENDIF (NOT ((${CMAKE_SYSTEM_NAME} MATCHES "Darwin") OR  MSVC))


# add the system default implementation library
# add a static library with the system default implementation for generating c++ fmu targets
add_library(${SystemName}_static STATIC AlgLoopDefaultImplementation.cpp AlgLoopSolverFactory.cpp EventHandling.cpp DiscreteEvents.cpp ContinuousEvents.cpp SystemDefaultImplementation.cpp SimVars.cpp)
set_target_properties(${SystemName}_static PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")
include_directories(${SUNDIALS_INCLUDE_DIR}/cvodes ${SUNDIALS_INCLUDE_DIR}/nvector  ${SUNDIALS_INCLUDE_DIR}/sundials ${SUNDIALS_INCLUDE_DIR}/kinsol ${SUNDIALS_INCLUDE_DIR})

if (UNIX)
	set_target_properties(${SystemName}_static PROPERTIES COMPILE_FLAGS -fPIC)
endif(UNIX)

install (TARGETS ${SystemName}_static DESTINATION ${LIBINSTALLEXT})

add_library(${SystemName} SHARED AlgLoopDefaultImplementation.cpp AlgLoopSolverFactory.cpp EventHandling.cpp DiscreteEvents.cpp ContinuousEvents.cpp SystemDefaultImplementation.cpp SimVars.cpp FactoryExport.cpp)

target_link_libraries (${SystemName} ${Boost_LIBRARIES} ${LAPACK_LIBRARIES} ${OMCFactoryName}_static)
add_precompiled_header(${SystemName} Include/Core/Modelica.h)
install (TARGETS ${SystemName} DESTINATION ${LIBINSTALLEXT})

#IF (NOT ((${CMAKE_SYSTEM_NAME} MATCHES "Darwin") OR  MSVC))
#install (TARGETS ${BasiLibName} DESTINATION ${LIBINSTALLEXT})
#ENDIF (NOT ((${CMAKE_SYSTEM_NAME} MATCHES "Darwin") OR  MSVC))
install (FILES
	${CMAKE_SOURCE_DIR}/Include/Core/System/SystemDefaultImplementation.h
	${CMAKE_SOURCE_DIR}/Include/Core/System/AlgLoopDefaultImplementation.h
        ${CMAKE_SOURCE_DIR}/Include/Core/System/EventHandling.h
        ${CMAKE_SOURCE_DIR}/Include/Core/System/PreVariables.h
        ${CMAKE_SOURCE_DIR}/Include/Core/System/DiscreteEvents.h
        ${CMAKE_SOURCE_DIR}/Include/Core/System/ContinuousEvents.h
        ${CMAKE_SOURCE_DIR}/Include/Core/System/SimVars.h
        ${CMAKE_SOURCE_DIR}/Include/Core/System/FactoryExport.h
	${CMAKE_SOURCE_DIR}/Include/Core/System/IAlgLoop.h
        ${CMAKE_SOURCE_DIR}/Include/Core/System/IAlgLoopSolverFactory.h
        ${CMAKE_SOURCE_DIR}/Include/Core/System/AlgLoopSolverFactory.h
        ${CMAKE_SOURCE_DIR}/Include/Core/System/IContinuous.h
        ${CMAKE_SOURCE_DIR}/Include/Core/System/IMixedSystem.h
        ${CMAKE_SOURCE_DIR}/Include/Core/System/IEvent.h
	${CMAKE_SOURCE_DIR}/Include/Core/System/ITime.h
        ${CMAKE_SOURCE_DIR}/Include/Core/System/ISystemProperties.h
        ${CMAKE_SOURCE_DIR}/Include/Core/System/ISystemInitialization.h
        ${CMAKE_SOURCE_DIR}/Include/Core/System/IStepEvent.h
	${CMAKE_SOURCE_DIR}/Include/Core/System/IWriteOutput.h
	${CMAKE_SOURCE_DIR}/Include/Core/System/IStateSelection.h
        ${CMAKE_SOURCE_DIR}/Include/Core/System/ISimVars.h
DESTINATION include/omc/cpp/Core/System)





