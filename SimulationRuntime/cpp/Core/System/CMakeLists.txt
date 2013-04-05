cmake_minimum_required (VERSION 2.6)

project(${SystemName})
# add the system default implementation library
add_library(${SystemName} SHARED AlgLoopDefaultImplementation.cpp AlgLoopSolverFactory.cpp EventHandling.cpp SystemDefaultImplementation.cpp OMCppSystemTypeMap.cpp)
target_link_libraries (${SystemName} ${Boost_LIBRARIES} ${LAPACK_LIBRARIES} )

# add a static library with the system default implementation for generating c++ fmu targets
add_library(${SystemName}_static STATIC ${Boost_LIBRARIES} ${LAPACK_LIBRARIES} AlgLoopDefaultImplementation.cpp AlgLoopSolverFactory.cpp EventHandling.cpp SystemDefaultImplementation.cpp )
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
        ${CMAKE_SOURCE_DIR}/Include/Core/System/IContinuous.h
        ${CMAKE_SOURCE_DIR}/Include/Core/System/IMixedSystem.h
        ${CMAKE_SOURCE_DIR}/Include/Core/System/IEvent.h
        ${CMAKE_SOURCE_DIR}/Include/Core/System/ISystemProperties.h
        ${CMAKE_SOURCE_DIR}/Include/Core/System/ISystemInitialization.h
        ${CMAKE_SOURCE_DIR}/Include/Core/System/IStepEvent.h
      DESTINATION include/omc/cpp/Core/System)





