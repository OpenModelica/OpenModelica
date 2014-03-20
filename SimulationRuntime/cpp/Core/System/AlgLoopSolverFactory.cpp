
#include "stdafx.h"
#include <System/AlgLoopSolverFactory.h>

#ifdef ANALYZATION_MODE
AlgLoopSolverFactory::AlgLoopSolverFactory(IGlobalSettings* global_settings,PATH library_path,PATH modelicasystem_path)
     :StaticNonLinSolverOMCFactory<OMCFactory>(library_path,modelicasystem_path,library_path)
     ,_global_settings(global_settings)
{
}
#else
AlgLoopSolverFactory::AlgLoopSolverFactory(IGlobalSettings* global_settings,PATH library_path,PATH modelicasystem_path)
     :NonLinSolverPolicy(library_path,modelicasystem_path,library_path)
     ,_global_settings(global_settings)
{
}
#endif

AlgLoopSolverFactory::~AlgLoopSolverFactory()
{

}

/// Creates a solver according to given system of equations of type algebraic loop
boost::shared_ptr<IAlgLoopSolver> AlgLoopSolverFactory::createAlgLoopSolver(IAlgLoop* algLoop)
{
   
    if(algLoop->getDimReal() > 0)
    {
       
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
        throw   std::invalid_argument("Nonlinear solver is not available");
    }
}

