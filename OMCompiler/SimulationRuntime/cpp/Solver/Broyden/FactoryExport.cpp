/** @addtogroup solverBroyden
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#if defined(OMC_BUILD) && !defined(RUNTIME_STATIC_LINKING)

#include <Solver/Broyden/Broyden.h>
#include <Solver/Broyden/BroydenSettings.h>

    /* OMC factory */
    using boost::extensions::factory;

BOOST_EXTENSION_TYPE_MAP_FUNCTION {
  types.get<std::map<std::string, factory<INonLinearAlgLoopSolver, INonLinSolverSettings*,shared_ptr<INonLinearAlgLoop> > > >()
    ["broyden"].set<Broyden>();
  types.get<std::map<std::string, factory<INonLinSolverSettings> > >()
    ["broydenSettings"].set<BroydenSettings>();
 }
#elif defined(OMC_BUILD) && defined(RUNTIME_STATIC_LINKING)
#include <Solver/Broyden/Broyden.h>
#include <Solver/Broyden/BroydenSettings.h>
 shared_ptr<INonLinSolverSettings> createBroydenSettings()
 {
     shared_ptr<INonLinSolverSettings> settings = shared_ptr<INonLinSolverSettings>(new BroydenSettings());
      return settings;
 }
 shared_ptr<INonLinearAlgLoopSolver> createBroydenSolver(shared_ptr<INonLinSolverSettings> solver_settings,shared_ptr<INonLinearAlgLoop> algloop)
 {
     shared_ptr<INonLinearAlgLoopSolver> solver = shared_ptr<INonLinearAlgLoopSolver>(new Broyden(solver_settings.get(),algloop));
        return solver;
 }
#else
error "operating system not supported"
#endif
/** @} */ // end of solverBroyden



