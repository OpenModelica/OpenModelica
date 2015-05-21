/** @addtogroup coreSystem
 *  
 *  @{
 */
#include <Core/ModelicaDefine.h>
 #include <Core/Modelica.h>

//#include <SimCoreFactory/OMCFactory/OMCFactory.h>
#include <Core/System/AlgLoopSolverFactory.h>
/*removed for static linking not needed any more
#ifdef RUNTIME_STATIC_LINKING
AlgLoopSolverFactory::AlgLoopSolverFactory(IGlobalSettings* global_settings,PATH library_path,PATH modelicasystem_path)
  :ObjectFactory<OMCFactory>(library_path,modelicasystem_path,library_path)
  ,StaticNonLinSolverOMCFactory<OMCFactory>(library_path,modelicasystem_path,library_path)
  ,StaticLinSolverOMCFactory<OMCFactory>(library_path,modelicasystem_path,library_path)
  ,_global_settings(global_settings)
{
}
#elif defined(__vxworks) || defined(__TRICORE__)
AlgLoopSolverFactory::AlgLoopSolverFactory(IGlobalSettings* global_settings,PATH library_path,PATH modelicasystem_path)
  : NonLinSolverPolicy(library_path,modelicasystem_path,library_path)
  , LinSolverPolicy(library_path,modelicasystem_path,library_path)
  , _global_settings(global_settings)
{
}
#else
*/
AlgLoopSolverFactory::AlgLoopSolverFactory(IGlobalSettings* global_settings,PATH library_path,PATH modelicasystem_path)
  : ObjectFactory<BaseFactory>(library_path,modelicasystem_path,library_path)
  , NonLinSolverPolicy(library_path,modelicasystem_path,library_path)
  , LinSolverPolicy(library_path,modelicasystem_path,library_path)
  , _global_settings(global_settings)
{
}
/*#endif*/

AlgLoopSolverFactory::~AlgLoopSolverFactory()
{
}

/// Creates a solver according to given system of equations of type algebraic loop
boost::shared_ptr<IAlgLoopSolver> AlgLoopSolverFactory::createAlgLoopSolver(IAlgLoop* algLoop)
{
  if(algLoop->getDimReal() > 0)
  {
    if(algLoop->isLinear())
    {
      try
      {
        string linsolver_name = _global_settings->getSelectedLinSolver();
        boost::shared_ptr<ILinSolverSettings> algsolversetting= createLinSolverSettings(linsolver_name);
        _linalgsolversettings.push_back(algsolversetting);


        boost::shared_ptr<IAlgLoopSolver> algsolver= createLinSolver(algLoop,linsolver_name,algsolversetting);
        _algsolvers.push_back(algsolver);
        return algsolver;
      }
      catch(std::exception &arg)
      {
        //the linear solver was not found -> take the nonlinear solver
      }
    }

    string nonlinsolver_name = _global_settings->getSelectedNonLinSolver();
    boost::shared_ptr<INonLinSolverSettings> algsolversetting= createNonLinSolverSettings(nonlinsolver_name);
    _algsolversettings.push_back(algsolversetting);

    boost::shared_ptr<IAlgLoopSolver> algsolver= createNonLinSolver(algLoop,nonlinsolver_name,algsolversetting);
    _algsolvers.push_back(algsolver);
    return algsolver;
  }
  else
  {
    // TODO: Throw an error message here.
    throw ModelicaSimulationError(MODEL_FACTORY,"AlgLoop solver is not available");
  }
}
/** @} */ // end of coreSystem
