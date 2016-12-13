/** @addtogroup solverNewton
 *
 *  @{
 */

#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#if defined(__vxworks)
#include <Solver/Dgesv/DgesvSolver.h>

extern "C" IAlgLoopSolver* createDgesvSolver(ILinearAlgLoop* algLoop,ILinSolverSettings*)
{
  return new DgesvSolver(algLoop);
}



#elif defined(OMC_BUILD) && !defined(RUNTIME_STATIC_LINKING)

//do not use for dynamic linking

#elif defined(OMC_BUILD) && defined(RUNTIME_STATIC_LINKING)
#include <Solver/Dgesv/DgesvSolver.h>
#include <Solver/Dgesv/DgesvSolverSettings.h>
shared_ptr<ILinSolverSettings> createDgesvSolverSettings()
   {
       shared_ptr<ILinSolverSettings> settings = shared_ptr<ILinSolverSettings>(new DgesvSolverSettings());
        return settings;
   }
shared_ptr<IAlgLoopSolver> createDgesvSolver(ILinearAlgLoop* algLoop,shared_ptr<ILinSolverSettings> solver_settings)
{
  shared_ptr<IAlgLoopSolver> solver = shared_ptr<IAlgLoopSolver>(new DgesvSolver(algLoop,solver_settings.get()));
  return solver;
}

#else
  error "operating system not supported"
#endif
