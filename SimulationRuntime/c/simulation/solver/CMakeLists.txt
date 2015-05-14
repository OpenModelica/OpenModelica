# Jens Frenkel, Jens.Frenkel@tu-dresden.de, 2011-10-11
# CMakefile for compilation of OMC

ADD_SUBDIRECTORY(initialization)

INCLUDE_DIRECTORIES("${OMCTRUNCHOME}/OMCompiler/Compiler/runtime/" "${OMCTRUNCHOME}/build/include/omc/c" "${OMCTRUNCHOME}/build/include/omc/msvc")

# Quellen und Header
SET(solver_sources
../../../../3rdParty/Cdaskr/solver/ddaskr.c
../../../../3rdParty/Cdaskr/solver/daux.c
../../../../3rdParty/Cdaskr/solver/dlinpk.c
dassl.c           kinsolSolver.c            linearSystem.c             nonlinearSolverHybrd.c   radau.c
delay.c           linearSolverLapack.c      mixedSearchSolver.c        nonlinearSolverNewton.c  solver_main.c
linearSolverLis.c         mixedSystem.c              nonlinearSystem.c        stateset.c
events.c          linearSolverTotalPivot.c  model_help.c               omc_math.c
external_input.c  linearSolverUmfpack.c     nonlinearSolverHomotopy.c)

SET(solver_headers ../../../../3rdParty/Cdaskr/solver/ddaskr_types.h
dassl.h    external_input.h          linearSolverUmfpack.h  nonlinearSolverHomotopy.h  radau.h
delay.h    kinsolSolver.h            linearSystem.h         nonlinearSolverHybrd.h     solver_main.h
linearSolverLapack.h      mixedSearchSolver.h    nonlinearSolverNewton.h    stateset.h
epsilon.h  linearSolverLis.h         mixedSystem.h          nonlinearSystem.h
events.h   linearSolverTotalPivot.h  model_help.h           omc_math.h)

# Library util
ADD_LIBRARY(solver ${solver_sources} ${solver_headers})
#TARGET_LINK_LIBRARIES(util)

# Install
INSTALL(TARGETS solver
		ARCHIVE DESTINATION lib/omc)

#INSTALL(FILES ${solver_headers} DESTINATION include)

