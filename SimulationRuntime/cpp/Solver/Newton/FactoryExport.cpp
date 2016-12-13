/** @addtogroup solverNewton
 *
 *  @{
 */

#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#if defined(__vxworks)
#include <Solver/Newton/Newton.h>
#include <Solver/Newton/NewtonSettings.h>

extern "C" IAlgLoopSolver* createNewton(INonLinearAlgLoop* algLoop, INonLinSolverSettings* settings)
{
  return new Newton(algLoop, settings);
}

extern "C" INonLinSolverSettings* createNewtonSettings()
{
  return new NewtonSettings();
}

#elif defined(OMC_BUILD) && !defined(RUNTIME_STATIC_LINKING)

#include <Solver/Newton/Newton.h>
#include <Solver/Newton/NewtonSettings.h>

/* OMC factory */
using boost::extensions::factory;

BOOST_EXTENSION_TYPE_MAP_FUNCTION {
  types.get<std::map<std::string, factory<IAlgLoopSolver,INonLinearAlgLoop*, INonLinSolverSettings*> > >()
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

shared_ptr<IAlgLoopSolver> createNewtonSolver(INonLinearAlgLoop* algLoop, shared_ptr<INonLinSolverSettings> solver_settings)
{
  shared_ptr<IAlgLoopSolver> solver = shared_ptr<IAlgLoopSolver>(new Newton(algLoop,solver_settings.get()));
  return solver;
}

#else
  error "operating system not supported"
#endif
/** @} */ // end of solverNewton
