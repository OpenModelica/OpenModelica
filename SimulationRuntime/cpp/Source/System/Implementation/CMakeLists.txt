cmake_minimum_required (VERSION 2.6)

project(${SystemName})
# add the solver default implementation library
add_library(${SystemName} SHARED AlgLoopDefaultImplementation AlgLoopSolverFactory.cpp EventHandling.cpp SystemDefaultImplementation.cpp )
target_link_libraries (${SystemName} ${Boost_LIBRARIES} ${LAPACK_LIBRARIES} )

install (TARGETS ${SystemName} DESTINATION lib/omc)
install (FILES SystemDefaultImplementation.h AlgLoopDefaultImplementation.h EventHandling.h DESTINATION include/omc/cpp/System/Implementation)
install (FILES ../Interfaces/IAlgLoop.h 
        ../Interfaces/IAlgLoopSolver.h 
        ../Interfaces/IAlgLoopSolverFactory.h 
        ../Interfaces/IContinous.h
        ../Interfaces/IDAESystem.h
        ../Interfaces/IDataExchange.h 
        ../Interfaces/IEvent.h
        ../Interfaces/ISystemProperties.h
        ../Interfaces/ISystemInitialization.h
      DESTINATION include/omc/cpp/System/Interfaces)


  
  
 
