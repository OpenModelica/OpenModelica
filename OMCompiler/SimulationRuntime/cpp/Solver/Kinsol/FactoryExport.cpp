/** @addtogroup solverKinsol
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>

#if defined(OMC_BUILD)  && !defined(RUNTIME_STATIC_LINKING)
#include <nvector/nvector_serial.h>
#include <kinsol/kinsol.h>
#ifdef USE_SUNDIALS_LAPACK
  #include <kinsol/kinsol_lapack.h>
#else
  #include <kinsol/kinsol_spgmr.h>
  #include <kinsol/kinsol_dense.h>
#endif //USE_SUNDIALS_LAPACK
#include <kinsol/kinsol_spbcgs.h>
#include <kinsol/kinsol_sptfqmr.h>
//#include <kinsol/kinsol_klu.h>
#include <kinsol/kinsol_direct.h>
#include <sundials/sundials_dense.h>
#include <kinsol/kinsol_impl.h>
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
#include <nvector/nvector_serial.h>
#include <kinsol/kinsol.h>
#ifdef USE_SUNDIALS_LAPACK
  #include <kinsol/kinsol_lapack.h>
#else
  #include <kinsol/kinsol_spgmr.h>
  #include <kinsol/kinsol_dense.h>
#endif //USE_SUNDIALS_LAPACK
#include <kinsol/kinsol_spbcgs.h>
#include <kinsol/kinsol_sptfqmr.h>
//#include <kinsol/kinsol_klu.h>
#include <kinsol/kinsol_direct.h>
#include <sundials/sundials_dense.h>
#include <kinsol/kinsol_impl.h>
#include <Solver/Kinsol/Kinsol.h>
#include <Solver/Kinsol/KinsolSettings.h>
#else
error "operating system not supported"
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
