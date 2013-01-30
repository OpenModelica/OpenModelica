# Jens Frenkel, Jens.Frenkel@tu-dresden.de, 2011-10-11
# CMakefile for compilation of OMC 

ADD_SUBDIRECTORY(initialization)

# Quellen und Header
SET(solver_sources  dassl.c
                    delay.c
                    events.c
                    model_help.c
                    nonlinearSystem.c
                    nonlinearSolverHybrd.c
                    nonlinearSolverNewton.c
                    kinsolSolver.c
                    solver_main.c
					stateset.c)

SET(solver_headers  dassl.h
                    delay.h 
                    events.h
                    model_help.h 
                    nonlinearSolverHybrd.h
                    nonlinearSolverNewton.h
                    kinsolSolver.h
                    nonlinearSystem.h
                    solver_main.h
					stateset.h)				 
						 
# Library util
ADD_LIBRARY(solver ${solver_sources} ${solver_headers})
#TARGET_LINK_LIBRARIES(util)

# Install
INSTALL(TARGETS solver
		ARCHIVE DESTINATION lib/omc)
		
#INSTALL(FILES ${solver_headers} DESTINATION include)

