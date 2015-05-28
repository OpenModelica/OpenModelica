#pragma once
/** @addtogroup simcorefactoriesPolicies
 *  
 *  @{
 */
/*includes removed for static linking not needed any more
#include <SimCoreFactory/Policies/LinSolverOMCFactory.h>
#include <Solver/UmfPack/UmfPack.h>
#include <Solver/UmfPack/UmfPackSettings.h>
#include <Core/Solver/IAlgLoopSolver.h>
*/
template<class T>
struct ObjectFactory;

template<class CreationPolicy>
struct StaticLinSolverOMCFactory : public LinSolverOMCFactory<CreationPolicy> {

public:
  StaticLinSolverOMCFactory(PATH library_path, PATH modelicasystem_path,PATH config_path)
  :ObjectFactory<CreationPolicy>(library_path,modelicasystem_path,config_path)
   ,LinSolverOMCFactory<CreationPolicy>(library_path,modelicasystem_path,config_path)
   ,_last_selected_solver("empty")
  {

  }
  virtual ~StaticLinSolverOMCFactory()
  {

  }

  virtual boost::shared_ptr<ILinSolverSettings> createLinSolverSettings(string lin_solver)
    {
        if(lin_solver.compare("umfpack")==0)
        {
     boost::shared_ptr<ILinSolverSettings> settings = boost::shared_ptr<ILinSolverSettings>(new UmfPackSettings());
     return settings;
        }
        else
           return LinSolverOMCFactory<CreationPolicy>::createLinSolverSettings(lin_solver);
   }

   virtual boost::shared_ptr<IAlgLoopSolver> createLinSolver(IAlgLoop* algLoop, string solver_name, boost::shared_ptr<ILinSolverSettings> solver_settings)
   {
       if(solver_name.compare("umfpack")==0)
       {
           boost::shared_ptr<IAlgLoopSolver> solver = boost::shared_ptr<IAlgLoopSolver>(new UmfPack(algLoop,solver_settings.get()));
           return solver;
       }
       else
           return LinSolverOMCFactory<CreationPolicy>::createLinSolver(algLoop, solver_name, solver_settings);
   }
protected:
     string _last_selected_solver;
private:
    type_map _linsolver_type_map;
};
/** @} */ // end of simcorefactoriesPolicies
