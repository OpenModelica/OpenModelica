/** @addtogroup solverNewton
 *
 *  @{
 */

#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#if defined(OMC_BUILD) && !defined(RUNTIME_STATIC_LINKING)

#include <Solver/LinearSolver/LinearSolver.h>
#include <Solver/LinearSolver/LinearSolverSettings.h>

/* OMC factory */
using boost::extensions::factory;

BOOST_EXTENSION_TYPE_MAP_FUNCTION {
types.get<std::map<std::string, factory<ILinearAlgLoopSolver,ILinSolverSettings*,shared_ptr<ILinearAlgLoop> > > >()
    ["linearSolver"].set<LinearSolver>();
types.get<std::map<std::string, factory<ILinSolverSettings> > >()
    ["linearSolverSettings"].set<LinearSolverSettings>();
}

#elif defined(OMC_BUILD) && defined(RUNTIME_STATIC_LINKING)
#include <Solver/LinearSolver/LinearSolver.h>
#include <Solver/LinearSolver/LinearSolverSettings.h>
shared_ptr<ILinSolverSettings> createLinearSolverSettings()
   {
       shared_ptr<ILinSolverSettings> settings = shared_ptr<ILinSolverSettings>(new LinearSolverSettings());
        return settings;
   }
shared_ptr<ILinearAlgLoopSolver> createLinearSolver(shared_ptr<ILinSolverSettings> solver_settings,shared_ptr<ILinearAlgLoop> algLoop)
{
  shared_ptr<ILinearAlgLoopSolver> solver = shared_ptr<ILinearAlgLoopSolver>(new LinearSolver(solver_settings.get(),algLoop));
  return solver;
}

#else
  error "operating system not supported"
#endif
