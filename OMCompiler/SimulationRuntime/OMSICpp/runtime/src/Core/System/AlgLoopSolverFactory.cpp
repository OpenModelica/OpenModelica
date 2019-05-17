/** @addtogroup coreSystem
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>

#include <Core/System/AlgLoopSolverFactory.h>

AlgLoopSolverFactory::AlgLoopSolverFactory(shared_ptr<IGlobalSettings> global_settings,PATH library_path,PATH modelicasystem_path)
  : IAlgLoopSolverFactory(), ObjectFactory<BaseFactory>(library_path,modelicasystem_path,library_path)
  , NonLinSolverPolicy(library_path,modelicasystem_path,library_path)
  , LinSolverPolicy(library_path,modelicasystem_path,library_path)
  , _global_settings(global_settings)
{
}
/*#endif*/

AlgLoopSolverFactory::~AlgLoopSolverFactory()
{
}

shared_ptr<ILinearAlgLoopSolver> AlgLoopSolverFactory::createLinearAlgLoopSolver(shared_ptr<ILinearAlgLoop> algLoop)
{
      try
      {
        string linsolver_name = _global_settings->getSelectedLinSolver();
		shared_ptr<ILinSolverSettings> algsolversetting= createLinSolverSettings(linsolver_name);
		_linalgsolversettings.push_back(algsolversetting);
        shared_ptr<ILinearAlgLoopSolver> algsolver= createLinSolver(linsolver_name,algsolversetting,algLoop);
        _linear_algsolvers.push_back(algsolver);
        return algsolver;
      }
      catch(std::exception &arg)
      {
        throw ModelicaSimulationError(MODEL_FACTORY,"Linear AlgLoop solver is not available");
      }

}

/// Creates a nonlinear solver according to given system of equations of type algebraic loop
shared_ptr<INonLinearAlgLoopSolver> AlgLoopSolverFactory::createNonLinearAlgLoopSolver(shared_ptr<INonLinearAlgLoop> algLoop)
{
	try
    {
		string nonlinsolver_name = _global_settings->getSelectedNonLinSolver();
		shared_ptr<INonLinSolverSettings> algsolversetting= createNonLinSolverSettings(nonlinsolver_name);
		algsolversetting->setContinueOnError(_global_settings->getNonLinearSolverContinueOnError());
		_algsolversettings.push_back(algsolversetting);

		shared_ptr<INonLinearAlgLoopSolver> algsolver= createNonLinSolver(nonlinsolver_name,algsolversetting,algLoop);
		_non_linear_algsolvers.push_back(algsolver);
		return algsolver;
	}
    catch(std::exception &arg)
    {
      throw ModelicaSimulationError(MODEL_FACTORY,"Linear AlgLoop solver is not available");
    }

}
/** @} */ // end of coreSystem
