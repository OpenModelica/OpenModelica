#pragma once
/** @addtogroup simcorefactoriesPolicies
 *
 *  @{
 */

#include <SimCoreFactory/ObjectFactory.h>

shared_ptr<INonLinSolverSettings> createNewtonSettings();
 shared_ptr<INonLinSolverSettings> createKinsolSettings();
 shared_ptr<IAlgLoopSolver> createNewtonSolver(INonLinearAlgLoop* algLoop, shared_ptr<INonLinSolverSettings> solver_settings);
 shared_ptr<IAlgLoopSolver> createKinsolSolver(INonLinearAlgLoop* algLoop, shared_ptr<INonLinSolverSettings> solver_settings);
template <class CreationPolicy>
class StaticNonLinSolverOMCFactory : virtual public ObjectFactory<CreationPolicy>
{

public:
    StaticNonLinSolverOMCFactory(PATH library_path,PATH modelicasystem_path,PATH config_path)
    :ObjectFactory<CreationPolicy>(library_path,modelicasystem_path,config_path)
      {
      };
    virtual ~StaticNonLinSolverOMCFactory(){};

   virtual shared_ptr<INonLinSolverSettings> createNonLinSolverSettings(string nonlin_solver)
   {
      string nonlin_solver_key;

      if(nonlin_solver.compare("newton")==0)
      {
        shared_ptr<INonLinSolverSettings> settings = createNewtonSettings();
        return settings;
      }

      #ifdef ENABLE_SUNDIALS_STATIC
      if(nonlin_solver.compare("kinsol")==0)
      {
          shared_ptr<INonLinSolverSettings> settings = createKinsolSettings();
          return settings;
      }
      #endif //ENABLE_SUNDIALS_STATIC
      throw ModelicaSimulationError(MODEL_FACTORY,"Selected nonlin solver is not available");
      //return NonLinSolverOMCFactory<CreationPolicy>::createNonLinSolverSettings(nonlin_solver);
   }
   virtual shared_ptr<IAlgLoopSolver> createNonLinSolver(INonLinearAlgLoop* algLoop, string solver_name, shared_ptr<INonLinSolverSettings> solver_settings)
   {
      if(solver_name.compare("newton")==0)
      {
        shared_ptr<IAlgLoopSolver> newton = createNewtonSolver(algLoop,solver_settings);
        return newton;
      }

      #ifdef ENABLE_SUNDIALS_STATIC
      if(solver_name.compare("kinsol")==0)
      {
        shared_ptr<IAlgLoopSolver> kinsol = createKinsolSolver(algLoop,solver_settings);
        return kinsol;
      }
      #endif //ENABLE_SUNDIALS_STATIC
      throw ModelicaSimulationError(MODEL_FACTORY,"Selected nonlin solver is not available");
      //return NonLinSolverOMCFactory<CreationPolicy>::createNonLinSolver(algLoop, solver_name, solver_settings);
    }
};
/** @} */ // end of simcorefactoriesPolicies
