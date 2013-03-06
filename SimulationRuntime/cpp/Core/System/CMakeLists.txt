cmake_minimum_required (VERSION 2.6)

project(${SystemName})
# add the solver default implementation library
add_library(${SystemName} SHARED AlgLoopDefaultImplementation AlgLoopSolverFactory.cpp EventHandling.cpp SystemDefaultImplementation.cpp )
target_link_libraries (${SystemName} ${Boost_LIBRARIES} ${LAPACK_LIBRARIES} )

install (TARGETS ${SystemName} DESTINATION lib/omc/${LIBINSTALLEXT})
install (FILES ${CMAKE_SOURCE_DIR}/Include/Core/System/SystemDefaultImplementation.h ${CMAKE_SOURCE_DIR}/Include/Core/System/AlgLoopDefaultImplementation.h
        ${CMAKE_SOURCE_DIR}/Include/Core/System/EventHandling.h DESTINATION include/omc/cpp/Core/System)
install (FILES ${CMAKE_SOURCE_DIR}/Include/Core/System/IAlgLoop.h
        ${CMAKE_SOURCE_DIR}/Include/Core/System/IAlgLoopSolver.h
        ${CMAKE_SOURCE_DIR}/Include/Core/System/IAlgLoopSolverFactory.h
        ${CMAKE_SOURCE_DIR}/Include/Core/System/IContinuous.h
        ${CMAKE_SOURCE_DIR}/Include/Core/System/IMixedSystem.h
        ${CMAKE_SOURCE_DIR}/Include/Core/System/IEvent.h
        ${CMAKE_SOURCE_DIR}/Include/Core/System/ISystemProperties.h
        ${CMAKE_SOURCE_DIR}/Include/Core/System/ISystemInitialization.h
      DESTINATION include/omc/cpp/Core/System)





