cmake_minimum_required (VERSION 2.6)

project(${SystemName})
# add the system default implementation library
IF(ANALYZATION_MODE)
	add_library(${SystemName} STATIC AlgLoopDefaultImplementation.cpp AlgLoopSolverFactory.cpp EventHandling.cpp SystemDefaultImplementation.cpp FactoryExport.cpp)
	include_directories(${SUNDIALS_INCLUDE_DIR}/cvodes ${SUNDIALS_INCLUDE_DIR}/nvector  ${SUNDIALS_INCLUDE_DIR}/sundials ${SUNDIALS_INCLUDE_DIR})
	target_link_libraries (${SystemName} ${Boost_LIBRARIES} ${LAPACK_LIBRARIES} ${OMCFactoryName} )
ELSE(ANALYZATION_MODE)
	add_library(${SystemName} SHARED AlgLoopDefaultImplementation.cpp AlgLoopSolverFactory.cpp EventHandling.cpp SystemDefaultImplementation.cpp FactoryExport.cpp)
	target_link_libraries (${SystemName} ${Boost_LIBRARIES} ${LAPACK_LIBRARIES} ${OMCFactoryName} )
ENDIF(ANALYZATION_MODE)

# add a static library with the system default implementation for generating c++ fmu targets
add_library(${SystemName}_static STATIC AlgLoopDefaultImplementation.cpp AlgLoopSolverFactory.cpp EventHandling.cpp SystemDefaultImplementation.cpp )
target_link_libraries (${SystemName}_static ${Boost_LIBRARIES} ${LAPACK_LIBRARIES})
if (UNIX)
set_target_properties(${SystemName}_static PROPERTIES COMPILE_FLAGS -fPIC)
endif(UNIX)

install (TARGETS ${SystemName} DESTINATION lib/omc/${LIBINSTALLEXT})

install (TARGETS ${SystemName}_static DESTINATION lib/omc/${LIBINSTALLEXT})
install (FILES
	${CMAKE_SOURCE_DIR}/Include/Core/System/SystemDefaultImplementation.h
	${CMAKE_SOURCE_DIR}/Include/Core/System/AlgLoopDefaultImplementation.h
        ${CMAKE_SOURCE_DIR}/Include/Core/System/EventHandling.h
	DESTINATION include/omc/cpp/Core/System)
install (FILES
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
      DESTINATION include/omc/cpp/Core/System)





