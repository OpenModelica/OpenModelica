#pragma once
/** @addtogroup simcorefactoriesPolicies
 *
 *  @{
 */
#include <SimCoreFactory/ObjectFactory.h>
shared_ptr<ILinSolverSettings> createLinearSolverSettings();
shared_ptr<IAlgLoopSolver> createLinearSolver(ILinearAlgLoop* algLoop, shared_ptr<ILinSolverSettings> solver_settings);
shared_ptr<ILinSolverSettings> createDgesvSolverSettings();
shared_ptr<IAlgLoopSolver> createDgesvSolver(ILinearAlgLoop* algLoop, shared_ptr<ILinSolverSettings> solver_settings);
template<class CreationPolicy>
struct StaticLinSolverOMCFactory : virtual public ObjectFactory<CreationPolicy>{

public:
  StaticLinSolverOMCFactory(PATH library_path, PATH modelicasystem_path,PATH config_path)
   :ObjectFactory<CreationPolicy>(library_path,modelicasystem_path,config_path)
    ,_last_selected_solver("empty")
   {
   }

  virtual ~StaticLinSolverOMCFactory() {};

  virtual shared_ptr<ILinSolverSettings> createLinSolverSettings(string lin_solver)
  {
      if(lin_solver.compare("linearSolver")==0)
      {
          throw ModelicaSimulationError(MODEL_FACTORY,"Selected lin solver is not supported for static Linking. Use DGESV instead.");
      }
      else if(lin_solver.compare("dgesvSolver")==0)
      {
           shared_ptr<ILinSolverSettings> settings = createDgesvSolverSettings();
           return settings;
      }
      else
        throw ModelicaSimulationError(MODEL_FACTORY,"Selected lin solver is not available");
  }
  virtual shared_ptr<IAlgLoopSolver> createLinSolver(ILinearAlgLoop* algLoop, string solver_name, shared_ptr<ILinSolverSettings> solver_settings)
  {

       if(solver_name.compare("linearSolver")==0)
       {
          throw ModelicaSimulationError(MODEL_FACTORY,"Selected lin solver is not supported for static Linking. Use DGESV instead.");
       }
       else if(solver_name.compare("dgesvSolver")==0)
       {
           shared_ptr<IAlgLoopSolver> solver =createDgesvSolver(algLoop,solver_settings);
           return solver;
       }
       else
          throw ModelicaSimulationError(MODEL_FACTORY,"Selected lin solver is not available");
   }

protected:
     string _last_selected_solver;
private:
    type_map _linsolver_type_map;
};
/** @} */ // end of simcorefactoriesPolicies
