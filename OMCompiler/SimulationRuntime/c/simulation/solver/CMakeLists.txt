# Jens Frenkel, Jens.Frenkel@tu-dresden.de, 2011-10-11
# CMakefile for compilation of OMC

ADD_SUBDIRECTORY(initialization)

INCLUDE_DIRECTORIES(
  "${OMCTRUNCHOME}/OMCompiler/Compiler/runtime/"
  "${OMCTRUNCHOME}/build/include/omc/c"
  "${OMCTRUNCHOME}/build/include/omc/msvc"
  "${OMCTRUNCHOME}/build/include/omc/msvc/suitesparse")

# Sources
SET(solver_sources  ../../../../3rdParty/Cdaskr/solver/daux.c
                    ../../../../3rdParty/Cdaskr/solver/ddaskr.c
                    ../../../../3rdParty/Cdaskr/solver/dlinpk.c
                    dassl.c
                    delay.c
                    events.c
                    gbode_conf.c
                    gbode_ctrl.c
                    gbode_events.c
                    gbode_main.c
                    gbode_nls.c
                    gbode_internal_nls.c
                    gbode_sparse.c
                    gbode_step.c
                    gbode_tableau.c
                    gbode_util.c
                    external_input.c
                    jacobian_analysis.c
                    kinsol_b.c
                    kinsolSolver.c
                    linearSolverLapack.c
                    linearSolverLis.c
                    linearSolverTotalPivot.c
                    linearSolverUmfpack.c
                    linearSystem.c
                    mixedSearchSolver.c
                    mixedSystem.c
                    model_help.c
                    newtonIteration.c
                    newton_diagnostics.c
                    nonlinearSolverHomotopy.c
                    nonlinearSolverHybrd.c
                    nonlinearSolverNewton.c
                    nonlinearSystem.c
                    omc_math.c
                    solver_main.c
                    spatialDistribution.c
                    stateset.c
                    sundials_error.c
                    sym_solver_ssc.c)

# Headers
SET(solver_headers  ../../../../3rdParty/Cdaskr/solver/ddaskr_types.h
                    dassl.h
                    delay.h
                    epsilon.h
                    gbode_conf.h
                    gbode_ctrl.h
                    gbode_events.h
                    gbode_main.h
                    gbode_nls.h
                    gbode_internal_nls.h
                    gbode_sparse.h
                    gbode_step.h
                    gbode_tableau.h
                    gbode_util.h
                    events.h
                    external_input.h
                    jacobian_analysis.h
                    kinsol_b.h
                    kinsolSolver.h
                    linearSolverLapack.h
                    linearSolverLis.h
                    linearSolverTotalPivot.h
                    linearSolverUmfpack.h
                    linearSystem.h
                    mixedSearchSolver.h
                    mixedSystem.h
                    model_help.h
                    newton_diagnostics.h
                    newtonIteration.h
                    nonlinearSolverHomotopy.h
                    nonlinearSolverHybrd.h
                    nonlinearSolverNewton.h
                    nonlinearSystem.h
                    omc_math.h
                    solver_main.h
                    spatialDistribution.h
                    stateset.h
                    sundials_error.h
                    sym_solver_ssc.h)

# Library util
ADD_LIBRARY(solver ${solver_sources} ${solver_headers})
#TARGET_LINK_LIBRARIES(util)

# Install
INSTALL(TARGETS solver
		ARCHIVE DESTINATION lib/omc)

#INSTALL(FILES ${solver_headers} DESTINATION include)
