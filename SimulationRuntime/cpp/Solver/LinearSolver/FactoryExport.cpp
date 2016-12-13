/** @addtogroup solverNewton
 *
 *  @{
 */

#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#if defined(__vxworks)
#include <Solver/LinearSolver/LinearSolver.h>

extern "C" IAlgLoopSolver* createLinearSolver(ILinearAlgLoop* algLoop,ILinSolverSettings*)
{
  return new LinearSolver(algLoop);
}



#elif defined(OMC_BUILD) && !defined(RUNTIME_STATIC_LINKING)

#include <Solver/LinearSolver/LinearSolver.h>
#include <Solver/LinearSolver/LinearSolverSettings.h>

/* OMC factory */
using boost::extensions::factory;

BOOST_EXTENSION_TYPE_MAP_FUNCTION {
types.get<std::map<std::string, factory<IAlgLoopSolver,ILinearAlgLoop*,ILinSolverSettings*> > >()
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
shared_ptr<IAlgLoopSolver> createLinearSolver(ILinearAlgLoop* algLoop,shared_ptr<ILinSolverSettings> solver_settings)
{
  shared_ptr<IAlgLoopSolver> solver = shared_ptr<IAlgLoopSolver>(new LinearSolver(algLoop,solver_settings.get()));
  return solver;
}

#else
  error "operating system not supported"
#endif
