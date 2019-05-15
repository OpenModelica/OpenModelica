/** @addtogroup solverNewton
 *
 *  @{
 */

#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#if defined(OMC_BUILD) && !defined(RUNTIME_STATIC_LINKING)

#include <Solver/Newton/Newton.h>
#include <Solver/Newton/NewtonSettings.h>

/* OMC factory */
using boost::extensions::factory;

BOOST_EXTENSION_TYPE_MAP_FUNCTION {
  types.get<std::map<std::string, factory<INonLinearAlgLoopSolver, INonLinSolverSettings*,shared_ptr<INonLinearAlgLoop> > > >()
    ["newton"].set<Newton>();
  types.get<std::map<std::string, factory<INonLinSolverSettings> > >()
    ["newtonSettings"].set<NewtonSettings>();
}

#elif defined(OMC_BUILD) && defined(RUNTIME_STATIC_LINKING)
#include <Solver/Newton/Newton.h>
#include <Solver/Newton/NewtonSettings.h>

shared_ptr<INonLinSolverSettings> createNewtonSettings()
{
  shared_ptr<INonLinSolverSettings> settings = shared_ptr<INonLinSolverSettings>(new NewtonSettings());
  return settings;
}

shared_ptr<INonLinearAlgLoopSolver> createNewtonSolver(shared_ptr<INonLinSolverSettings> solver_settings,shared_ptr<INonLinearAlgLoop> algloop)
{
  shared_ptr<INonLinearAlgLoopSolver> solver = shared_ptr<INonLinearAlgLoopSolver>(new Newton(solver_settings.get(),algloop));
  return solver;
}

#else
  error "operating system not supported"
#endif
/** @} */ // end of solverNewton
