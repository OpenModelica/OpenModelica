#pragma once
/*includes removed for static linking not needed any more
#include <SimCoreFactory/Policies/NonLinSolverOMCFactory.h>
#include <Solver/Newton/Newton.h>
#include <Solver/Kinsol/Kinsol.h>
#include <Solver/Kinsol/KinsolSettings.h>
#include <Core/Solver/IAlgLoopSolver.h>
*/
template<class T>
struct ObjectFactory;

template <class CreationPolicy> 
class StaticNonLinSolverOMCFactory : public NonLinSolverOMCFactory<CreationPolicy>
{

public:
    StaticNonLinSolverOMCFactory(PATH library_path,PATH modelicasystem_path,PATH config_path)
        :ObjectFactory<CreationPolicy>(library_path,modelicasystem_path,config_path),
        NonLinSolverOMCFactory<CreationPolicy>(library_path,modelicasystem_path,config_path)
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
    else if(nonlin_solver.compare("kinsol")==0)
    {
        boost::shared_ptr<INonLinSolverSettings> settings = boost::shared_ptr<INonLinSolverSettings>(new KinsolSettings());
        return settings;
    }
    else
      return NonLinSolverOMCFactory<CreationPolicy>::createNonLinSolverSettings(nonlin_solver);
   }

   virtual boost::shared_ptr<IAlgLoopSolver> createNonLinSolver(IAlgLoop* algLoop, string solver_name, boost::shared_ptr<INonLinSolverSettings> solver_settings)
   {
     if(solver_name.compare("newton")==0)
     {
       boost::shared_ptr<IAlgLoopSolver> solver = boost::shared_ptr<IAlgLoopSolver>(new Newton(algLoop,solver_settings.get()));
       return solver;
     }
     else if(solver_name.compare("kinsol")==0)
     {
         boost::shared_ptr<IAlgLoopSolver> settings = boost::shared_ptr<IAlgLoopSolver>(new Kinsol(algLoop,solver_settings.get()));
         return settings;
     }
     else
       return NonLinSolverOMCFactory<CreationPolicy>::createNonLinSolver(algLoop, solver_name, solver_settings);

   }
};
