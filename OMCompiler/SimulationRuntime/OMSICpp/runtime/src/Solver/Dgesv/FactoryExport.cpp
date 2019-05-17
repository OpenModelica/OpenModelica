/** @addtogroup solverNewton
 *
 *  @{
 */

#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#if defined(OMC_BUILD) && !defined(RUNTIME_STATIC_LINKING)

//do not use for dynamic linking

#elif defined(OMC_BUILD) && defined(RUNTIME_STATIC_LINKING)
#include <Solver/Dgesv/DgesvSolver.h>
#include <Solver/Dgesv/DgesvSolverSettings.h>
shared_ptr<ILinSolverSettings> createDgesvSolverSettings()
   {
       shared_ptr<ILinSolverSettings> settings = shared_ptr<ILinSolverSettings>(new DgesvSolverSettings());
        return settings;
   }
shared_ptr<ILinearAlgLoopSolver> createDgesvSolver(shared_ptr<ILinSolverSettings> solver_settings,shared_ptr<ILinearAlgLoop> algLoop)
{
  shared_ptr<ILinearAlgLoopSolver> solver = shared_ptr<ILinearAlgLoopSolver>(new DgesvSolver(solver_settings.get(),algLoop));
  return solver;
}

#else
  error "operating system not supported"
#endif
