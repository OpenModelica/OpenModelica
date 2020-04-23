/** @addtogroup solverKinsol
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>

#if defined(OMC_BUILD)  && !defined(RUNTIME_STATIC_LINKING)
#include <kinsol/kinsol.h>
#include <nvector/nvector_serial.h>

/* Will be used with new sundials version */
//#include <sunlinsol/sunlinsol_klu.h>         /* Linear solver KLU */
#ifdef USE_SUNDIALS_LAPACK
  #include <sunlinsol/sunlinsol_klu.h>         /* Linear solver KLU */
#else
  #include <sunlinsol/sunlinsol_spgmr.h>
  #include <sunlinsol/sunlinsol_dense.h>       /* Default dense linear solver */
#endif //USE_SUNDIALS_LAPACK
#include <sunlinsol/sunlinsol_spbcgs.h>
#include <sunlinsol/sunlinsol_sptfqmr.h>

#include <Solver/Kinsol/Kinsol.h>
#include <Solver/Kinsol/KinsolSettings.h>

using boost::extensions::factory;

BOOST_EXTENSION_TYPE_MAP_FUNCTION {
  types.get<std::map<std::string, factory<INonLinearAlgLoopSolver, INonLinSolverSettings*,shared_ptr<INonLinearAlgLoop> > > >()
    ["kinsol"].set<Kinsol>();
  types.get<std::map<std::string, factory<INonLinSolverSettings> > >()
    ["kinsolSettings"].set<KinsolSettings>();
}
#elif defined(OMC_BUILD) && defined(RUNTIME_STATIC_LINKING)
#include <kinsol/kinsol.h>
#include <nvector/nvector_serial.h>

/* Will be used with new sundials version */
//#include <sunlinsol/sunlinsol_klu.h>         /* Linear solver KLU */
#ifdef USE_SUNDIALS_LAPACK
  #include <sunlinsol/sunlinsol_klu.h>         /* Linear solver KLU */
#else
  #include <sunlinsol/sunlinsol_spgmr.h>
  #include <sunlinsol/sunlinsol_dense.h>       /* Default dense linear solver */
#endif //USE_SUNDIALS_LAPACK
#include <sunlinsol/sunlinsol_spbcgs.h>
#include <sunlinsol/sunlinsol_sptfqmr.h>
#include <Solver/Kinsol/Kinsol.h>
#include <Solver/Kinsol/KinsolSettings.h>
#else
error
"operating system not supported"
#endif

#if defined(OMC_BUILD)  && defined(RUNTIME_STATIC_LINKING)
#if defined(ENABLE_SUNDIALS_STATIC)
   shared_ptr<INonLinSolverSettings> createKinsolSettings()
   {
       shared_ptr<INonLinSolverSettings> settings = shared_ptr<INonLinSolverSettings>(new KinsolSettings());
        return settings;
   }
    shared_ptr<INonLinearAlgLoopSolver> createKinsolSolver(shared_ptr<INonLinSolverSettings> solver_settings,shared_ptr<INonLinearAlgLoop> algLoop)
   {
       shared_ptr<INonLinearAlgLoopSolver> solver = shared_ptr<INonLinearAlgLoopSolver>(new Kinsol(solver_settings.get(),algLoop));
          return solver;
   }
#else
   shared_ptr<INonLinSolverSettings> createKinsolSettings()
   {
     throw ModelicaSimulationError(ALGLOOP_SOLVER,"Kinsol was disabled during build");
   }
   shared_ptr<INonLinearAlgLoopSolver> createKinsolSolver(shared_ptr<INonLinSolverSettings> solver_settings,shared_ptr<INonLinearAlgLoop> algLoop)
   {
     throw ModelicaSimulationError(ALGLOOP_SOLVER,"Kinsol was disabled during build");
   }
#endif //ENABLE_SUNDIALS_STATIC
#endif
/** @} */ // end of solverKinsol
