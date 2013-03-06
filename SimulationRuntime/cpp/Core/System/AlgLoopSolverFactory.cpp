#include "stdafx.h"
#include "AlgLoopSolverFactory.h"
#include <LibrariesConfig.h>

AlgLoopSolverFactory::AlgLoopSolverFactory(IGlobalSettings& global_settings)
:_libraries_path(global_settings.getRuntimeLibrarypath())
,_global_settings(global_settings)
{
}

AlgLoopSolverFactory::~AlgLoopSolverFactory()
{

}

/// Creates a solver according to given system of equations of type algebraic loop
 boost::shared_ptr<IAlgLoopSolver> AlgLoopSolverFactory::createAlgLoopSolver(IAlgLoop* algLoop)
{
    if(algLoop->getDimVars() > 0)
    {
        string nonlin_solver_dll;
   string nonlinsolver = _global_settings.getSelectedNonLinSolver();
    string nonlinsolversettings = _global_settings.getSelectedNonLinSolver().append("Settings");
  if(_global_settings.getSelectedNonLinSolver().compare("Newton")==0)
    nonlin_solver_dll.assign(NEWTON_LIB);
  else if(_global_settings.getSelectedNonLinSolver().compare("Kinsol")==0)
    nonlin_solver_dll.assign(KINSOL_LIB);
  else
    throw std::invalid_argument("Selected nonlinear solver is not available");
  fs::path solver_name(nonlin_solver_dll);
  fs::path solver_path = _libraries_path;
  solver_path/=solver_name;
  type_map types;
  if(!load_single_library(types,solver_path.string()))
    throw std::invalid_argument(" Nonlinear solver library could not be loaded");
   std::map<std::string, factory<IAlgLoopSolver,IAlgLoop*, INonLinSolverSettings*> >::iterator iter;
   std::map<std::string, factory<IAlgLoopSolver,IAlgLoop*, INonLinSolverSettings*> >& nonlinSolverFactory(types.get());
   std::map<std::string, factory<INonLinSolverSettings> >::iterator iter2;
   std::map<std::string, factory<INonLinSolverSettings> >& nonLinSolversettingsfactory(types.get());
   iter2 = nonLinSolversettingsfactory.find(nonlinsolversettings);
      if (iter2 ==nonLinSolversettingsfactory.end())
        {
            throw std::invalid_argument("No such nonlinear solver Settings");
        }
    boost::shared_ptr<INonLinSolverSettings> algsolversetting= boost::shared_ptr<INonLinSolverSettings>(iter2->second.create());
    _algsolversettings.push_back(algsolversetting);
    iter = nonlinSolverFactory.find(nonlinsolver);
    if (iter ==nonlinSolverFactory.end())
    {
       throw std::invalid_argument("No such non linear Solver");
   }

    boost::shared_ptr<IAlgLoopSolver> algsolver= boost::shared_ptr<IAlgLoopSolver>(iter->second.create(algLoop,algsolversetting.get()));
    _algsolvers.push_back(algsolver);
    return algsolver;
  }
  else
  {
    // TODO: Throw an error message here.
    throw   std::invalid_argument("Algloop system is not of tpye real");
  }
}
