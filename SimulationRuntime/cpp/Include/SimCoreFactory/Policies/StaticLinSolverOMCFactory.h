#pragma once
/** @addtogroup simcorefactoriesPolicies
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <SimCoreFactory/Policies/LinSolverOMCFactory.h>

template<class T>
struct ObjectFactory;

template<class CreationPolicy>
struct StaticLinSolverOMCFactory : public LinSolverOMCFactory<CreationPolicy> {

public:
  StaticLinSolverOMCFactory(PATH library_path, PATH modelicasystem_path,PATH config_path);
  virtual ~StaticLinSolverOMCFactory();

  virtual boost::shared_ptr<ILinSolverSettings> createLinSolverSettings(string lin_solver);
  virtual boost::shared_ptr<IAlgLoopSolver> createLinSolver(IAlgLoop* algLoop, string solver_name, boost::shared_ptr<ILinSolverSettings> solver_settings);

protected:
     string _last_selected_solver;
private:
    type_map _linsolver_type_map;
};
/** @} */ // end of simcorefactoriesPolicies
