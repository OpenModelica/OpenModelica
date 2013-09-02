# Jens Frenkel, Jens.Frenkel@tu-dresden.de, 2011-10-11
# CMakefile for compilation of OMC

ADD_SUBDIRECTORY(initialization)

# Quellen und Header
SET(solver_sources  dassl.c
                    delay.c
                    events.c
                    model_help.c
                    mixedSystem.c
                    mixedSearchSolver.c
                    kinsolSolver.c
                    linearSystem.c
                    linearSolverLapack.c
                    linearSolverLis.c
                    nonlinearSystem.c
                    nonlinearSolverHybrd.c
                    nonlinearSolverNewton.c
                    radau.c
                    solver_main.c
                    stateset.c)

SET(solver_headers  dassl.h
                    delay.h
                    events.h
                    mixedSystem.h
                    mixedSearchSolver.h
                    kinsolSolver.h
                    linearSystem.h
                    linearSolverLapack.h
                    linearSolverLis.h
                    model_help.h
                    nonlinearSolverHybrd.h
                    nonlinearSolverNewton.h
                    nonlinearSystem.h
                    radau.h
                    solver_main.h
                    stateset.h)

# Library util
ADD_LIBRARY(solver ${solver_sources} ${solver_headers})
#TARGET_LINK_LIBRARIES(util)

# Install
INSTALL(TARGETS solver
		ARCHIVE DESTINATION lib/omc)

#INSTALL(FILES ${solver_headers} DESTINATION include)

