cmake_minimum_required (VERSION 2.6)

project(System)
# add the solver default implementation library
add_library(System SHARED AlgLoopDefaultImplementation AlgLoopSolverFactory.cpp EventHandling.cpp SystemDefaultImplementation.cpp )


install (TARGETS System DESTINATION bin)
install (FILES SystemDefaultImplementation.h AlgloopDefaultImplementation.h EventHandling.h DESTINATION include/omc/cpp/System/Implementation)
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


  
  
 
