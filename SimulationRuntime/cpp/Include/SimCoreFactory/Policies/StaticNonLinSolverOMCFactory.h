#pragma once

#include <Policies/NonLinSolverOMCFactory.h>
#include <Solver/Newton/Newton.h>

template<class T>
struct ObjectFactory;

template <class CreationPolicy> 
class StaticNonLinSolverOMCFactory : public  NonLinSolverOMCFactory<CreationPolicy>
{

public:
    StaticNonLinSolverOMCFactory(PATH library_path,PATH modelicasystem_path,PATH config_path)
        :NonLinSolverOMCFactory<CreationPolicy>(library_path,modelicasystem_path,config_path)
    {
    }
  
    virtual ~StaticNonLinSolverOMCFactory()
    {
    }

   virtual boost::shared_ptr<INonLinSolverSettings> createNonLinSolverSettings(string nonlin_solver)
   {
    string nonlin_solver_key;
      
    if(nonlin_solver.compare("newton")==0)
    {
      boost::shared_ptr<INonLinSolverSettings> settings = boost::shared_ptr<INonLinSolverSettings>(new NewtonSettings());
      return settings;
    }
        else
      return NonLinSolverOMCFactory<CreationPolicy>::createNonLinSolverSettings(nonlin_solver);
   }

   virtual boost::shared_ptr<IAlgLoopSolver> createNonLinSolver(IAlgLoop* algLoop, string solver_name, boost::shared_ptr<INonLinSolverSettings>  solver_settings)
   {
       boost::shared_ptr<IAlgLoopSolver> solver = boost::shared_ptr<IAlgLoopSolver>(new Newton(algLoop,solver_settings.get()));
       return solver;
   }
};
