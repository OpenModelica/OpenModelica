/** @addtogroup solverKinsol
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>

#include <Solver/Kinsol/Kinsol.h>
#include <Solver/Kinsol/KinsolSettings.h>

using boost::extensions::factory;

#if defined(OMC_BUILD) && !defined(RUNTIME_STATIC_LINKING)
BOOST_EXTENSION_TYPE_MAP_FUNCTION {
  types.get<std::map<std::string, factory<INonLinearAlgLoopSolver, INonLinSolverSettings*,shared_ptr<INonLinearAlgLoop> > > >()
    ["kinsol"].set<Kinsol>();
  types.get<std::map<std::string, factory<INonLinSolverSettings> > >()
    ["kinsolSettings"].set<KinsolSettings>();
}
#elif defined(OMC_BUILD) && defined(RUNTIME_STATIC_LINKING)
  // Nothing
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
